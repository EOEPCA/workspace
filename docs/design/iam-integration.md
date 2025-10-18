# IAM Integration

The Workspace Building Block (BB) provides a unified and secure access model that connects **Keycloak-based identity management**, **object storage authorization**, and **ingress-level enforcement** into one cohesive system.  It ensures that both users and workloads can seamlessly and securely access workspace resources — including Datalabs, storage buckets, and shared services — using centrally managed identities and declarative policies.

## Key Principles

- **Full Keycloak Integration:**  
  Each workspace is represented as a first-class entity within Keycloak.  
  Workspace-specific Keycloak clients, roles, and groups are created automatically during provisioning, ensuring end-to-end access management for the Workspace UI, Datalab, and APIs.

- **Automated Membership and Role Management:**  
  Adding or removing workspace members automatically updates Keycloak group membership and role assignments. These changes take effect immediately, ensuring that workspace access reflects the current membership state at all times.

- **Unified Principal for Storage Access:**  
  Each workspace has a corresponding **storage principal** (e.g., S3 user or service account) in the configured backend (MinIO, AWS S3, or OTC OBS).  
  This principal owns the workspace’s buckets, and all workspace members share its credentials — securely injected into their runtime environments through Kubernetes Secrets.  
  This design ensures that all users and workloads within a workspace operate under the same “workspace identity” when accessing object storage.

## Workspace-Level IAM Entities

When a workspace is provisioned, the following Keycloak entities are automatically created and configured:

**Keycloak Client**  

  - Created per workspace (e.g., `ws-alice`)  
  - Used for OpenID Connect authentication at ingress level  
  - Defines a role (e.g., `ws_access`) used to authorize requests to the workspace endpoints  

**Keycloak Group**  

  - Mirrors the workspace name (e.g., `ws-alice`)  
  - Group membership defines access to the Workspace UI and Datalab  
  - The workspace owner is automatically added to the group as the initial member  

Adding or removing users from the workspace group dynamically updates their access to the UI, API, and Datalab without manual operator intervention.

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

Access to workspace endpoints (UI, API, and Datalab) is protected at the ingress layer following the common **EOEPCA IAM concepts**.  The Workspace BB leverages **APISix** ingress configuration combined with **Open Policy Agent (OPA)** policies to enforce both authentication and fine-grained authorization.  

- The APISix **OIDC plugin** validates user tokens via Keycloak and ensures only authenticated users can reach workspace endpoints.  
- The **OPA plugin** enforces declarative access rules defined in policy repositories (e.g., `eoepca/iam-policies`), controlling which users or roles can access which workspaces.  
- These policies are managed in a **GitOps-compatible** way, enabling version-controlled and auditable authorization configurations across environments.

This approach seamlessly ties ingress-level access control to the same Keycloak clients and groups that govern workspace membership, ensuring uniform and transparent access enforcement.

## Credentials Management and Future Enhancements

- **Automatic Credential Injection:**  
  Storage credentials are securely mounted into all Datalab sessions and workloads via Kubernetes Secrets.  
  Users and services can immediately access workspace buckets without manually handling access keys.

- **Credential Rollover (Planned):**  
  Future releases will support periodic credential rotation and lifecycle management to improve security and compliance.

- **Vended (Time-Limited) Credentials (Planned):**  
  Short-lived credentials will be supported to grant temporary access to shared resources — providing secure, time-bound data sharing and external system integration.