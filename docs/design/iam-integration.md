# IAM Integration

The Workspace Building Block (BB) combines three access layers:

- Keycloak identities, clients, groups, and client roles.
- Workspace-api authorization based on token claims.
- Storage credentials and bucket policies owned by each workspace.

The important boundary is that authentication happens before requests reach workspace-api. A gateway such as APISIX validates OpenID Connect tokens and forwards only authenticated requests. Workspace-api then reads the forwarded token claims and converts them into explicit workspace permissions.

## End-to-End Flow

1. A workspace is created through workspace-api or another Kubernetes-native workflow.
2. The Workspace pipeline creates provider-storage and provider-datalab resources.
3. Provider-datalab reconciles the `Datalab` and creates the workspace-local Keycloak resources.
4. Human users authenticate through the platform OAuth2/OIDC flow. In shared Workspace UI and Datalab session ingress deployments, the gateway uses the central `workspace-api` client for browser login, and the resulting token carries workspace roles in `resource_access`.
5. Workspace-local automation can request a client-credentials token from the generated confidential workspace client.
6. Externally exposed services that belong to one workspace can use the generated workspace client and roles as their local access boundary.
7. The gateway and its attached policy layers validate token policy, including signature, issuer, expiration, and audience, then forward the request.
8. Workspace-api maps `resource_access` roles to internal permissions.

## Keycloak Resources

Provider-datalab creates these Keycloak objects for each workspace-backed `Datalab`.

| Object | Example | Purpose |
| --- | --- | --- |
| Confidential OAuth2 client | `ws-alice` | Represents the workspace as a role namespace in `resource_access` and supports client-credentials automation. It is not the shared browser ingress client in central gateway deployments. |
| User group | `ws-alice` | Grants regular workspace access to human members. |
| Admin group | `ws-alice-admin` | Grants workspace administration to selected human members. |
| Client roles | `ws_access`, `ws_admin`, `ws_api` | Express workspace-local authority in OAuth2 `resource_access`. |
| Runtime OAuth2 Secret | `ws-alice-oauth2-client` | Publishes generated client credentials to runtime consumers with `client_id` and `client_secret` keys. |
| Service-account role binding | `ws_api` | Gives the generated client service account only machine/API authority. |

The generated workspace client is intentionally configured as a confidential client:

- `accessType: CONFIDENTIAL`
- `serviceAccountsEnabled: true`
- `fullScopeAllowed: false`
- `standardFlowEnabled: true`
- `implicitFlowEnabled: false`
- `directAccessGrantsEnabled: false`
- `oauth2DeviceAuthorizationGrantEnabled: false`

The generated client secret is a workspace machine credential. Provider-datalab reads the provider-keycloak connection Secret in the `Datalab` claim namespace and projects the supported runtime contract as `<datalab>-oauth2-client` in the runtime workshop namespace. Readers of that runtime Secret can mint client-credentials tokens for the workspace, so access to the Secret must follow the same trust boundary as other workspace automation credentials. Shared browser ingress should use the central Workspace client instead of this runtime Secret, otherwise browser tokens are issued for the workspace client and policy must explicitly accept that different `azp`.

## Why Each Workspace Has Its Own Client

The generated `ws-*` client is the workspace's machine identity and role namespace. It is separate from the central Workspace browser client on purpose:

- A central client such as `workspace-api` is a good fit for shared browser entry points because users log in once and can receive roles for several workspaces in one token.
- A generated workspace client such as `ws-bob` is a good fit for machine-to-machine traffic because its service account represents exactly one workspace.
- The client id is also the `resource_access` namespace for workspace-local roles, so policies can decide on `resource_access.ws-bob.roles` without discovering Keycloak resources at request time.
- The runtime `<datalab>-oauth2-client` Secret gives workloads a scoped credential. Anyone who can read it can mint a token as the workspace service account, so its permissions must stay narrower than human workspace access.

In the current Workspace API permission map, this machine token is intentionally limited: `ws_api` can view workspace bucket credentials, but it cannot manage members, buckets, stores, sessions, or act as an interactive browser user. This lets a Datalab workload retrieve the workspace details it needs without turning the runtime Secret into a human or administrator credential.

The same client can also be reused by workspace-owned services that are exposed outside the runtime namespace, for example through an Ingress, Gateway API route, or TLSRoute. In that pattern, the service belongs to `ws-bob`, so the edge policy can require a token for the `ws-bob` client or roles under `resource_access.ws-bob`. That is a different use case from the shared Workspace UI and session ingress, where a central browser client plus `ws_access` / `ws_admin` checks is usually the cleaner contract.

## Role Model

Workspace roles are deliberately separated by principal type.

| Role | Assigned to | Workspace-api permissions | Intended use |
| --- | --- | --- | --- |
| `ws_access` | Workspace user group | `VIEW_BUCKET_CREDENTIALS`, `VIEW_MEMBERS`, `VIEW_BUCKETS`, `VIEW_STORES`, `VIEW_SESSIONS` | Human read and session visibility. |
| `ws_admin` | Workspace admin group | All `ws_access` permissions plus `MANAGE_MEMBERS`, `MANAGE_BUCKETS`, `MANAGE_STORES`, `MANAGE_SESSIONS` | Human workspace administration. |
| `ws_api` | Generated client service account | `VIEW_BUCKET_CREDENTIALS` only | Workspace-local machine/API access from client-credentials tokens. |
| `admin` on `workspace-api` | Platform operator | Wildcard workspace administration | Platform-wide Workspace API administration. |

The generated client service account receives only `ws_api`. It is not assigned `ws_access` or `ws_admin`. Human groups receive `ws_access` or `ws_admin`; they should not receive `ws_api` unless an environment intentionally wants human browser tokens to carry machine/API authority.

Role scope mappings are an allowlist, not an assignment. Provider-datalab adds explicit role mappers because `fullScopeAllowed` is disabled, but a token still contains only the roles assigned to the requesting user or service account.

## Workspace API Token Contract

Workspace-api does not discover Keycloak clients directly. It receives the already validated bearer token from the gateway and derives workspace permissions from claims:

- `aud` must contain the Workspace API audience expected by the backend, by default `workspace-api`.
- `preferred_username` identifies the caller for request context.
- `resource_access` maps client ids to roles.
- `workspace-api:admin` grants platform-wide administration.
- each non-`workspace-api` `resource_access` key is interpreted as a workspace name.

A human user token issued for the central Workspace client can contain workspace roles for every workspace the user may access:

```json
{
  "aud": ["workspace-api"],
  "azp": "workspace-api",
  "preferred_username": "alice",
  "resource_access": {
    "ws-alice": {
      "roles": ["ws_access"]
    },
    "ws-bob": {
      "roles": ["ws_admin"]
    }
  }
}
```

A client-credentials token uses the same workspace client id but represents the generated Keycloak service-account user, not a human workspace member:

```json
{
  "aud": ["workspace-api"],
  "azp": "ws-alice",
  "sub": "<keycloak-service-account-user-id>",
  "preferred_username": "service-account-ws-alice",
  "resource_access": {
    "ws-alice": {
      "roles": ["ws_api"]
    }
  }
}
```

The token audience is a deployment contract. When workspace-local client-credentials tokens must call Workspace API, configure the generated workspace client to emit the Workspace API audience, for example with provider-datalab `EnvironmentConfig.data.iam.extraAudiences`, and configure the central Workspace API OAuth client and gateway with the same audience policy. A token intended only for the workspace runtime must not be accepted by the Workspace API gateway.

Policies must not treat client-credentials tokens as browser logins. UI and interactive Datalab routes should require `ws_access` or `ws_admin`. Automation routes can require `ws_api` where machine access is intended.

## Storage-Level IAM Entities

A dedicated **storage principal** is created in the configured storage backend:

- This principal defines the workspace’s identity at the storage layer.  
- Buckets are created under this principal, with IAM policies applied automatically.  
- The credentials (access key, secret key) are propagated to the workspace through Kubernetes Secrets and mounted directly into Datalabs and workloads.  

All workspace members use these same credentials, inheriting the principal’s permissions — enabling uniform access while isolating each workspace’s data from others.  

**Shared Buckets:**  
When a bucket is shared between workspaces:

- Storage policies in the backend (MinIO, AWS S3, or OBS) are updated automatically to grant or revoke the defined access (`readOnly`, `readWrite`, `writeOnly`).  
- These policies are linked to the workspace principal of the respective workspaces.  

## Ingress Protection and Authorization

Access to workspace endpoints is enforced at the ingress layer, not inside the application. `auth.type: delegated` means authentication and authorization are attached by the surrounding platform; it is not an unauthenticated mode.

For shared Workspace UI and Datalab session ingress, use the central browser client and authorize concrete workspace access from `resource_access.<workspace>.roles`. Browser routes should require human `ws_access` or `ws_admin`; `ws_api` is for machine/API access and should not grant interactive access.

Per-workspace OIDC clients are still useful for services that intentionally belong to one workspace. In that pattern, an exposed service owned by `ws-bob` can require the `ws-bob` client or roles under `resource_access.ws-bob`, using the generated runtime credential and role model as its local boundary.

## Egress Policy Model

Egress is handled as a layered set of Kubernetes `NetworkPolicy` resources. This is not a replacement for the cluster network plugin: the cluster still needs a CNI that enforces NetworkPolicy, such as Cilium or Calico.

The generated policy set is additive:

- start with `deny-egress`
- always add `allow-namespace-egress`
- add `allow-internal-egress` when `network.internalEgress` lists operator-whitelisted services in other namespaces
- add `allow-dns-egress` and `allow-external-egress` when `defaults.security.externalEgress` is enabled

Those final DNS and external-egress policies read their CIDR allowlist and blacklist from the central `EnvironmentConfig`, so operators define the general whitelist and optional blacklist once per environment. The `network.internalEgress` list defines the namespace, Pod selector, and ports for each cross-namespace exception; when the list is empty, the internal policy is omitted.

This keeps the policy intent simple: cross-namespace traffic is blocked by default, platform operators explicitly whitelist the few services that should remain reachable, and broad external egress is only opened when the environment config says so. For the exact generated network-policy semantics, see the provider-datalab [installation guide](https://provider-datalab.versioneer.at/latest/how-to-guides/installation/) and [sandbox security measures](https://provider-datalab.versioneer.at/latest/security/sandbox-controls/).

## Credentials Management and Future Enhancements

- **Automatic Credential Injection:**  
  Storage credentials are securely mounted into all Datalab sessions and workloads via Kubernetes Secrets.  
  Users and services can immediately access workspace buckets without manually handling access keys.

- **Workspace Client Secret:**
  The confidential workspace OAuth2 client secret is projected into the runtime workshop namespace as `<datalab>-oauth2-client` with `client_id` and `client_secret` keys. It is intentionally available as a workspace machine credential for client-credentials automation. Rotate it when workspace trust changes, and keep `ws_api` narrowly scoped so leaked or copied credentials do not imply human or admin authority.

- **Credential Rollover (Planned):**  
  Future releases will support periodic credential rotation and lifecycle management to improve security and compliance.

- **Vended (Time-Limited) Credentials (Planned):**  
  Short-lived credentials will be supported to grant temporary access to shared resources — providing secure, time-bound data sharing and external system integration.
