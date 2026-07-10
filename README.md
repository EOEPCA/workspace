# Workspace BB

The **Workspace Building Block (BB)** provisions a **trifecta** of capabilities — **storage**, **runtime**, and **tooling** — designed to simplify how users work with data, collaborate, and deploy applications.

A workspace combines:

1. **Storage Resources** — object storage or network volumes for persisting and sharing data.  
2. **Runtime Environments** — isolated Kubernetes namespaces or [vClusters](https://www.vcluster.com/) providing a full Kubernetes API surface for workloads.  
3. **Domain-Specific Tooling** — such as VSCode Server–based datalabs preconfigured for EO data exploration, analysis, and processing workflows.

These three elements are managed through Kubernetes-native abstractions — a **Storage** resource for object storage (MinIO, AWS S3, OTC, etc.) and a **Datalab** resource providing an interactive development and exploration environment.

See: [Storage CRD](https://provider-storage.versioneer.at/latest/reference-guides/api/) · [Datalab CRD](https://provider-datalab.versioneer.at/latest/reference-guides/api/)

Both layers are orchestrated by the [Workspace API & UI](https://github.com/EOEPCA/rm-workspace-api/), which exposes a REST API and web interface to manage users, storage, and runtime resources for individuals or teams.

See: [Workspace OpenAPI Specification](https://workspace-api.develop.eoepca.org/docs)

<div align="left">
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui1.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui1.png" height="200" alt="Workspace UI - Additional Bucket Creation"/>
  </a>
  &nbsp;
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui2.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui2.png" height="200" alt="Workspace UI - Bucket Sharing"/>
  </a>
  &nbsp;
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui3.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui3.png" height="200" alt="Workspace UI - Datalab Terminal"/>
  </a>
  &nbsp;
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui4.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui4.png" height="200" alt="Workspace UI - Datalab Browser"/>
  </a>
</div>

## Core Responsibilities

1. **Compute Provisioning** — Allocates compute environments within Kubernetes using namespaces or vClusters for isolation and resource control.  
2. **Object Storage Provisioning** — Creates and manages workspace-specific object storage, including access policies and credentials.  
3. **Application Setup** — Deploys ready-to-use user environments such as VSCode datalabs or the Workspace UI.  
4. **IAM Integration** — Uses Keycloak to automate user, group, and role management, ensuring secure access across all layers.

## Implementation Concept

The Workspace BB is built on **[Crossplane](https://github.com/crossplane/crossplane)** — an open-source control plane that extends Kubernetes with declarative resource provisioning and composable custom APIs through **Compositions** (see [Workspace Pipeline](./pipeline/)). This enables domain-specific abstractions such as “Storage” and “Datalab” to be defined declaratively and combined into higher-level resource types. As a result, infrastructure and service provisioning can be described, versioned, and managed like any other Kubernetes resource.

The main low-level providers on which these two compositions are built include:

- **Provider-Kubernetes** — manages native Kubernetes resources.  
- **Provider-Helm** — installs and configures Helm-based components.  
- **Provider-Keycloak** — provisions users, clients, and roles for IAM.  
- **Provider-MinIO** — handles S3-compatible object storage.

Other providers can be used interchangeably, e.g. to use AWS S3, OTC OBS, or similar APIs instead of MinIO.

## Storage and Runtime Integration

Each workspace includes a **Datalab**, a VSCode Server instance deployed into a Kubernetes namespace or a dynamically created vCluster.  

A datalab is preconfigured with workspace-specific storage credentials, allowing seamless integration with data-access libraries such as [Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html) and equipped with commonly used command-line tools like [AWS CLI](https://aws.amazon.com/cli/) and [rclone](https://rclone.org/). Together, this ready-made setup provides immediate access to workspace data for analysis, automation, and large-scale file transfers. In addition, the browser-based interface enables interactive data exploration through a unified file abstraction layer. This file abstraction is established via CSI drivers, enabling data to be mounted as volumes or accessed through higher-level tooling.  These integrations further support advanced capabilities such as packaging related data objects or sharing individual assets via presigned URLs.

See: [Workspace Documentation](https://eoepca.readthedocs.io/projects/workspace/)

## Deployment via Helm

This repository serves as an umbrella for documentation and dynamic Helm-chart creation.  
Published charts appear as GitHub Packages under this repository [here](https://github.com/orgs/EOEPCA/packages?tab=packages&q=workspace).

### 🧩 Prerequisites

Please note that **Crossplane v2** and the providers listed above must be installed in the cluster **before deploying any of the Workspace Helm charts**.  
These providers supply the foundational CRDs required by the `workspace-pipeline` and dependency charts.

The target cluster must also provide:

- A CNI that enforces Kubernetes `NetworkPolicy`; generated Datalab policies rely on CNI enforcement.
- Kyverno; the Workspace/Datalab setup can create policy resources automatically, but enforcement requires the admission controller to be present.

Keep the detailed runtime policy model in the provider-datalab documentation: [authentication](https://provider-datalab.versioneer.at/latest/how-to-guides/usage_concepts/#authentication), [workspace sessions as sandboxes](https://provider-datalab.versioneer.at/latest/security/workspace-sessions/), and [sandbox security measures](https://provider-datalab.versioneer.at/latest/security/sandbox-controls/).

### Workspace Dependency – CSI Rclone

No specific configuration values are required for this chart.

### Workspace Dependency – Educates

| Key | Type | Description |
|-----|------|-------------|
| `clusterIngressDomain` | string | Base domain under which Educates workshop environments will be exposed (e.g., `ngx.develop.eoepca.org`). |
| `clusterIngressClass` | string | Ingress class used by Educates (e.g., `nginx`). |
| `tlsCertificateRef.name` | string | Name of the TLS secret used for Educates ingress. |
| `tlsCertificateRef.namespace` | string | Namespace where the TLS secret resides (e.g., `workspace`). |

### Workspace Pipeline

| Key | Type | Description |
|-----|------|-------------|
| `environmentconfig.name` | string | EnvironmentConfig name used by matching Storage and Datalab resources. Default: `datalab`. |
| `environmentconfig.iam.realm` | string | Keycloak realm name for Workspace authentication. |
| `environmentconfig.iam.extraAudiences` | array | Extra token audiences for generated workspace clients, for example `workspace-api`. |
| `environmentconfig.ingress.class` | string | Ingress class to use (e.g., `nginx`). |
| `environmentconfig.ingress.domain` | string | Base domain for Workspace UIs and services. |
| `environmentconfig.ingress.secret` | string | TLS secret for Workspace ingresses. |
| `environmentconfig.storage.endpoint` | string | S3-compatible endpoint (e.g., `https://minio.develop.eoepca.org`). |
| `environmentconfig.storage.forcePathStyle` | bool | Use path-style addressing (`true` for MinIO/OTC). |
| `environmentconfig.storage.provider` | string | Storage provider label (`MinIO`, `AWS`, `Other`, etc.). |
| `environmentconfig.storage.region` | string | Region or identifier for the object storage backend. |
| `environmentconfig.storage.secretNamespace` | string | Namespace where Datalabs read storage credential Secrets. |
| `environmentconfig.storage.type` | string | Storage type (`s3`). |
| `environmentconfig.storage.lifecycle.schedule` | string | Cron schedule for storage lifecycle jobs. Provider default: `17 2 * * *`. |
| `environmentconfig.storageClasses.allowed` | array | Allowed StorageClasses for Datalab session PVCs. Empty allows any requested class. |
| `environmentconfig.network.externalEgressCIDRs` | array | Allowed external CIDRs for Datalab sessions. See the example below. |
| `environmentconfig.network.internalEgress` | array | Explicit cross-namespace Pod destinations and ports allowed for Datalab workloads. |
| `environmentconfig.network.serviceCIDR` | string | Cluster Service CIDR, used to keep service traffic out of broad egress rules. |
| `environmentconfig.network.podCIDRs` | array | Cluster Pod CIDRs. |
| `environmentconfig.network.blacklistIPs` | array | CIDRs excluded from generated external egress, for example metadata endpoints. |
| `environmentconfig.network.excludePolicies` | array | Generated NetworkPolicy names to skip. |
| `environmentconfig.packages` | array | Extension packages to inject into workshops. |
| `environmentconfig.auth.type` | string | Datalab session authentication mode: `credentials` or `delegated`. See [Datalab authentication](https://provider-datalab.versioneer.at/latest/how-to-guides/usage_concepts/#authentication). |
| `environmentconfig.defaults.quota.memory` | string | Default memory quota for Datalab sessions when unspecified. Default: `2Gi`. |
| `environmentconfig.defaults.quota.storage` | string | Default volume size (PVC) for Datalab sessions when unspecified. Default: `1Gi`. |
| `environmentconfig.defaults.quota.budget` | string | Default resource budget class (`small`, `medium`, `large`, …). Default: `medium`. |
| `environmentconfig.defaults.overallQuota.storage` | string | Aggregate PVC requested-storage quota for each Datalab environment namespace. Default: `100Gi`. |
| `environmentconfig.defaults.security.policy` | string | Default Pod Security Standard level for Datalab sessions (`restricted`, `baseline`, or `privileged`). Default: `baseline`. |
| `environmentconfig.defaults.security.kubernetesAccess` | bool | Whether sessions receive Kubernetes API access by default. Default: `true`. |
| `environmentconfig.defaults.security.kubernetesRole` | string | Default session namespace RBAC role (`admin`, `edit`, or `view`). Default: `edit`. |
| `environmentconfig.defaults.security.externalEgress` | bool | Default external egress setting for Datalab runtime namespaces. |
| `environmentconfig.database.gateway.parentName` | string | Name of the Gateway API `Gateway` hosting the PostgreSQL `TLSRoute` for external access (optional). |
| `environmentconfig.database.gateway.parentNamespace` | string | Namespace of the referenced Gateway API `Gateway` (optional). |
| `environmentconfig.database.gateway.sectionName` | string | Listener / section name on the Gateway to attach the PostgreSQL `TLSRoute` (optional). |
| `environmentconfig.database.storageClassName` | string | StorageClass for the primary PostgreSQL data volume (empty uses cluster default). |
| `environmentconfig.database.backupStorageClassName` | string | StorageClass for database backups if supported by the PostgreSQL operator (empty uses cluster default). |
| `environmentconfig.mongodb.storageClassName` | string | StorageClass for Datalab-managed MongoDB document stores (empty uses cluster default). |
| `environmentconfig.redis.storageClassName` | string | StorageClass for Datalab-managed Redis cache stores (empty uses cluster default). |
| `environmentconfig.qdrant.storageClassName` | string | StorageClass for Datalab-managed Qdrant vector stores (empty uses cluster default). |

Example:

```yaml
environmentconfig:
  iam:
    realm: eoepca
    extraAudiences:
      - workspace-api
  ingress:
    class: nginx
    domain: ws.example.org
    secret: workspace-tls
  storage:
    endpoint: https://s3.example.org
    forcePathStyle: true
    provider: Other
    region: eoepca
    secretNamespace: workspace
    type: s3
  storageClasses:
    allowed:
      - fast-rwx
      - standard-rwx
  network:
    # Allow all external IPv4/IPv6 egress for sessions with externalEgress enabled.
    externalEgressCIDRs:
      - 0.0.0.0/0
      - ::/0
    # Allow access to an explicitly selected service in another namespace.
    internalEgress:
      - namespace: platform-services
        podSelector:
          matchLabels:
            app: artifact-proxy
        ports:
          - protocol: TCP
            port: 443
    serviceCIDR: 10.43.0.0/16
    podCIDRs:
      - 10.42.0.0/16
    blacklistIPs:
      - 169.254.169.254/32
      - fd00:ec2::254/128
  defaults:
    overallQuota:
      storage: 100Gi
    security:
      policy: baseline
      kubernetesAccess: true
      kubernetesRole: edit
      externalEgress: true
```

For the detailed NetworkPolicy semantics of `externalEgressCIDRs`, `internalEgress`, `serviceCIDR`, `podCIDRs`, and `blacklistIPs`, see the provider-datalab [installation guide](https://provider-datalab.versioneer.at/latest/how-to-guides/installation/).
For the ingress and egress policy model, including `allow-internal-egress`, the `externalEgress` toggle, and explicit `internalEgress` rules, see [IAM Integration](docs/design/iam-integration.md).

### Authentication and User Management

Workspace authentication is intentionally split between the platform edge, Keycloak, provider-datalab, and workspace-api.

For shared Workspace UI and Datalab session ingress, the platform gateway should use a central browser OAuth2/OIDC client such as `workspace-api`. Concrete workspace authorization still comes from roles under the generated workspace client in `resource_access`, for example `resource_access.ws-alice.roles`.

Provider-datalab creates those workspace-local Keycloak resources while reconciling each `Datalab`: groups, roles, a confidential `ws-*` client, and a runtime `<datalab>-oauth2-client` Secret for machine-to-machine use. The generated client can call selected workspace-scoped APIs and can also protect services owned by that workspace, while browser and Datalab UI access should require human `ws_access` or `ws_admin` roles.

For the full access model, token examples, `ws_api` limits, and ingress policy guidance, see [IAM Integration](docs/design/iam-integration.md). For the backend authorization contract, see the Workspace API README on [authentication and authorization](https://github.com/EOEPCA/rm-workspace-api/?tab=readme-ov-file#authentication-and-authorization). Provider-datalab documents the underlying [authentication patterns](https://provider-datalab.versioneer.at/latest/how-to-guides/usage_concepts/#authentication) and [workspace session security](https://provider-datalab.versioneer.at/latest/security/workspace-sessions/).

## Getting Started with Live Code

The [documentation section](./docs) contains notebooks preconfigured for the EOEPCA demo system to demonstrate typical user journeys for both operators and workspace users. These examples use a [preconfigured setup](./setup) with the test users **alice**, **bob**, and **eric**. Each of them is an administrator of their own workspace but may also have access to other workspaces. In addition, **oscar** acts as a global administrator and is able to create and delete workspaces, as shown in the operator view tutorial.

You can follow the examples locally with the steps below:

 
```
pyenv local 3.12.11
python --version
uv lock --python python
uv sync --python python --extra dev
```

and follow the notebooks in the [Getting Started](./docs/getting-started) getting-started section.

## License

Apache 2.0 (Apache License Version 2.0, January 2004)  
<https://www.apache.org/licenses/LICENSE-2.0>
