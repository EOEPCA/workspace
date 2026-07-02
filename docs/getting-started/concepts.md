# Concepts

Workspace brings together storage, runtime, and tooling under one Kubernetes-native control plane. The detailed behavior lives in the provider documentation; this page keeps only the platform-level highlights.

## Building Blocks

- **Storage** is the persistent data layer. It provides S3-compatible buckets, normalized credentials, cross-workspace access requests and grants, and bucket-level lifecycle rules.
- **Datalab** is the interactive runtime. It gives users a browser-based development environment with terminal access, object storage integration, and optional Kubernetes access for additional services.
- **Tools and services** are layered on top. Datalabs include common CLIs and SDKs, and can run extra user or operator-provided services when the cluster policy allows it.

These pieces are reconciled through Crossplane compositions so the desired workspace state stays declarative, auditable, and reproducible.

## Access Model

Authentication is centralized through Keycloak/OIDC and enforced at the platform edge before requests reach workspace-api or Datalab sessions.

Workspace membership controls access to the Workspace UI and Datalab. Storage authorization stays separate and is enforced at bucket policy level. For the detailed Keycloak clients, roles, token claims, and machine-credential contract, see [IAM Integration](../design/iam-integration.md).

Bucket access is intentionally simple:

- `ReadOnly` for listing and reading objects.
- `ReadWrite` for reading, writing, and deleting objects.
- `WriteOnly` for write-oriented exchange workflows.
- `None` for explicit denial or removal of access.

Workspaces can request access to discoverable buckets owned by other workspaces. Owners approve or deny those requests through grants, and individual objects can still be shared ad hoc with pre-signed URLs from the Datalab data browser.

## Storage Highlights

Provider Storage gives users one `Storage` API while operators choose the backing implementation. Current supported storage backends include MinIO, AWS S3, and OTC OBS, with the same bucket, credential, request, grant, and lifecycle model across them.

Buckets can include lifecycle rules under `spec.buckets[].lifecycleRules`. A rule targets either the whole bucket (`*`) or a prefix such as `tmp/*`, then either:

- `Notify` reports matching objects when the time condition is met.
- `Delete` removes matching objects when the time condition is met.

Rules can use a relative object age such as `12h`, `30d`, or `2w`, or a fixed UTC timestamp via `at`.

Read more in the provider-storage docs:

- [Usage & Concepts](https://provider-storage.versioneer.at/latest/how-to-guides/usage_concepts/)
- [Permissions](https://provider-storage.versioneer.at/latest/how-to-guides/permissions/)
- [Backend Differences](https://provider-storage.versioneer.at/latest/how-to-guides/backend_differences/)
- [Storage API Reference](https://provider-storage.versioneer.at/latest/reference-guides/api/)

## Datalab Highlights

Provider Datalab manages the interactive workspace runtime. A Datalab can run on demand for cost-efficient work, stay always-on for long-running collaboration, or run in a vCluster when stronger isolation and a fuller Kubernetes API surface are needed.

Different storage types can be attached or provisioned depending on operator configuration and workload needs:

- Object storage buckets for data, artifacts, and workspace exchange.
- Session PVC storage for the Datalab runtime filesystem.
- Managed PostgreSQL databases for relational state.
- MongoDB document stores, Redis cache stores, and Qdrant vector stores for application services.
- A workspace-scoped Docker registry for local container images when Docker-capable sessions are enabled.

Datalab sessions inherit configured quotas, security settings, network rules, and storage credentials. Users can deploy additional services such as dashboards, APIs, Dask, or MLflow from inside the Datalab when Kubernetes access is enabled.

Read more in the provider-datalab docs:

- [Usage & Concepts](https://provider-datalab.versioneer.at/latest/how-to-guides/usage_concepts/)
- [Additional Services](https://provider-datalab.versioneer.at/latest/how-to-guides/additional_services/)
- [Authentication](https://provider-datalab.versioneer.at/latest/how-to-guides/usage_concepts/#authentication)
- [Workspace Sessions as Sandboxes](https://provider-datalab.versioneer.at/latest/security/workspace-sessions/)
- [Sandbox Security Measures](https://provider-datalab.versioneer.at/latest/security/sandbox-controls/)
- [Datalab API Reference](https://provider-datalab.versioneer.at/latest/reference-guides/api/)
