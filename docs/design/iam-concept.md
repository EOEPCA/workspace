# Workspace Access and IAM Integration concept

## Workspace Specification

The workspace specification defines key attributes of a workspace, including its unique name (e.g. `ws-example-78`) and the username of its owner. These attributes play a crucial role in Identity and Access Management (IAM) within the EOEPCA system.

## IAM Entities Provisioned per Workspace

When a workspace is created, the provisioning pipeline automatically establishes the following IAM entities in Keycloak:

- **Keycloak Client:** A non-confidential OAuth2 client is created, named after the workspace (e.g. `ws-example-78`). This client supports:
  - OAuth2 Standard Flow
  - Implicit Flow
  - Device Flow
  - A client role called `ws_access`

- **Keycloak Group:** A group with the same name as the workspace (e.g. `ws-example-78`) is created. This group includes a role mapping to the `ws_access` role of the client.

This setup ensures that any user added to the workspace-specific group will have access to that workspace. Since users can belong to multiple groups (e.g. `ws-example-78` and `ws-example-79`), they will automatically gain access to all corresponding workspaces if added to these groups.

- **Keycloak Membership for the Owner:** The workspace owner is automatically assigned membership in the workspace group, ensuring they have access to their own workspace.

### Future Development

EOEPCA plans to introduce tooling that allows workspace owners to manage access for other users (see [#35](https://github.com/EOEPCA/workspace/issues/35)). Currently, operators can manually add users to workspace groups via Keycloak's tooling or leverage GitOps reconciliation mechanisms between Kubernetes and Keycloak.

## What Does Workspace Access Mean?

Workspace provisioning establishes key resources, including:

- **Storage Resources:** Dedicated object storage buckets
- **Preconfigured Deployments:** Services such as the Workspace UI, bundled with a storage layer for data management

To facilitate access, the following mechanisms are in place:

### Object Storage Access

A dedicated API endpoint allows users or authorized services to request credentials for workspace object storage. The endpoint follows this format:

```
https://workspace-api.apx.develop.eoepca.org/workspaces/<workspace-name>
```

For example:

```
https://workspace-api.apx.develop.eoepca.org/workspaces/ws-example-78
```

### Workspace UI & Storage Layer Access

Each workspace is assigned a dedicated subdomain with a valid TLS certificate:

```
https://<workspace-name>.apx.develop.eoepca.org/
```

For example:

```
https://ws-example-79.apx.develop.eoepca.org/
```

Access to these resources is restricted based on IAM policies: users must have the `ws_access` role for the corresponding client in order to gain entry.

## Authorization via OPA Policies

EOEPCA has adopted **Open Policy Agent (OPA)** to manage authorization. This allows for:

- GitOps-style declarative specification of access policies, for above workspace components see [here](https://github.com/EOEPCA/iam-policies/tree/main/policies/eoepca/workspace)
- Seamless integration with **APISix Ingress** via the OPA plugin, working in conjunction with the OpenID Connect plugin

While Keycloak's native authorization capabilities were considered, OPA was chosen due to its flexibility and compatibility with EOEPCA's infrastructure. For further details on the IAM architecture and decision-making process, refer to the [IAM BB Documentation](https://eoepca.readthedocs.io/projects/iam/en/latest/)