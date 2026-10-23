# IAM integration

Workspace access is assigned through Keycloak client roles.

## Login and workspace clients

Use a central OAuth client, such as `workspace-api`, for shared Workspace UI and Datalab session routes. A user logs in through that client and receives a token with roles for the workspaces they can access.

Provider Datalab creates a confidential client for each workspace. Its ID matches the Datalab name, such as `ws-alice`, and holds that workspace's roles in `resource_access`.

| Resource | Example | Use |
| --- | --- | --- |
| Confidential client | `ws-alice` | Workspace roles and client-credentials tokens. |
| User group | `ws-alice` | Give members `ws_access`. |
| Admin group | `ws-alice-admin` | Give members `ws_admin`. |
| Runtime Secret | `ws-alice-oauth2-client` | Supply `client_id` and `client_secret` to workloads. |

Client settings:

```yaml
accessType: CONFIDENTIAL
serviceAccountsEnabled: true
fullScopeAllowed: false
standardFlowEnabled: true
implicitFlowEnabled: false
directAccessGrantsEnabled: false
oauth2DeviceAuthorizationGrantEnabled: false
```

Provider Datalab reads the provider-keycloak connection Secret in the Datalab resource's namespace. It copies the client ID and secret into `<datalab>-oauth2-client` in the runtime namespace. Anyone who can read that Secret can request a service-account token. Restrict Secret access and rotate the client secret when workspace membership or trust changes.

## Roles

| Role | Assigned to | Workspace API permissions |
| --- | --- | --- |
| `ws_access` | Workspace user group | `VIEW_BUCKET_CREDENTIALS`, `VIEW_MEMBERS`, `VIEW_BUCKETS`, `VIEW_STORES`, `VIEW_SESSIONS` |
| `ws_admin` | Workspace admin group | All `ws_access` permissions, plus `MANAGE_MEMBERS`, `MANAGE_BUCKETS`, `MANAGE_STORES`, `MANAGE_SESSIONS` |
| `ws_api` | Workspace client service account | `VIEW_BUCKET_CREDENTIALS` |
| `admin` on `workspace-api` | Platform administrator | Administration across all workspaces |

The service account receives only `ws_api`. It cannot manage members, buckets, stores, or sessions. Browser and interactive Datalab routes require `ws_access` or `ws_admin`.

With `fullScopeAllowed: false`, role scope mappings limit the roles that can appear in a token. Provider Datalab creates the mappings; the user or service account must also have the roles assigned.

These are API permissions. [Bucket grants](../concepts.md#storage) control S3 access separately.

## Token claims

The gateway checks the token signature, issuer, expiry, audience, and route policy. The Workspace API receives the validated bearer token and reads:

- `aud`: must include the API's expected audience, normally `workspace-api`.
- `preferred_username`: identifies the caller.
- `resource_access`: maps client IDs to roles.

The `admin` role under `resource_access.workspace-api` grants platform administration. Other keys in `resource_access` are read as workspace names.

This browser token gives Alice user access to `ws-alice` and admin access to `ws-bob`:

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

A client-credentials token identifies the workspace service account:

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

For API calls, add the API audience through `EnvironmentConfig.data.iam.extraAudiences`. The gateway policy and API must expect the same audience. Tokens issued only for a runtime service must fail the API gateway's audience check.


## Route protection

The platform gateway must protect the shared Workspace UI and Educates session routes. Check the workspace roles in `resource_access.<workspace>.roles` before forwarding a request.

Provider Datalab supplies OAuth protection for the permanent Data endpoint. Configure its issuer URLs in the [chart values](../getting-started/installation.md).

A service owned by one workspace can use that workspace's client. Set the route policy for its client ID, `azp`, and roles. For example, a service in `ws-bob` can check `resource_access.ws-bob.roles`.
