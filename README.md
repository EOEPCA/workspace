# Workspace BB

The **Workspace Building Block (BB)** provisions a **trifecta** of capabilities — **storage**, **runtime**, and **tooling** — designed to simplify how users work with data, collaborate, and deploy applications.

A workspace combines:

1. **Storage Resources** — object storage or network volumes for persisting and sharing data.  
2. **Runtime Environments** — isolated Kubernetes namespaces or [vClusters](https://www.vcluster.com/) providing a full Kubernetes API surface for workloads.  
3. **Domain-Specific Tooling** — such as VSCode Server–based datalabs preconfigured for EO data exploration, analysis, and processing workflows.

These three elements are managed through Kubernetes-native abstractions — a **Storage** resource for object storage (MinIO, AWS S3, OTC, etc.) and a **Datalab** resource providing an interactive development and exploraration environment.

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
| `environmentconfig.iam.realm` | string | Keycloak realm name for Workspace authentication. |
| `environmentconfig.ingress.class` | string | Ingress class to use (e.g., `nginx`). |
| `environmentconfig.ingress.domain` | string | Domain for all Workspace UIs and services. |
| `environmentconfig.ingress.secret` | string | TLS secret for the domain. |
| `environmentconfig.storage.endpoint` | string | S3-compatible endpoint (e.g., `https://minio.develop.eoepca.org`). |
| `environmentconfig.storage.forcePathStyle` | bool | Use path-style addressing (`true` for MinIO/OTC). |
| `environmentconfig.storage.provider` | string | Storage provider label (`MinIO`, `AWS`, `Other`, etc.). |
| `environmentconfig.storage.region` | string | Region or identifier for the object storage backend. |
| `environmentconfig.storage.secretNamespace` | string | Namespace for generated storage credentials. |
| `environmentconfig.storage.type` | string | Storage type (`s3`). |
| `environmentconfig.network.serviceCIDR` | string | Kubernetes service CIDR (e.g., `10.43.0.0/12`). |
| `environmentconfig.packages` | array | Optional list of extension packages to inject into workshops, each item supports `name` and `files[].image.url`. |
| `environmentconfig.auth.type` | string | Authentication mode, `credentials` (default) prompts for storage credentials; `none` adds no additional check. |
| `environmentconfig.default.quota.memory` | string | Default memory quota for Datalab sessions when unspecified. Default: `2Gi`. |
| `environmentconfig.default.quota.storage` | string | Default volume size (PVC) for Datalab sessions when unspecified. Default: `1Gi`. |
| `environmentconfig.default.quota.budget` | string | Default resource budget class (`small`, `medium`, `large`, …). Default: `medium`. |
| `environmentconfig.database.gateway.parentName` | string | Name of the Gateway API `Gateway` hosting the PostgreSQL `TLSRoute` for external access (optional). |
| `environmentconfig.database.gateway.parentNamespace` | string | Namespace of the referenced Gateway API `Gateway` (optional). |
| `environmentconfig.database.gateway.sectionName` | string | Listener / section name on the Gateway to attach the PostgreSQL `TLSRoute` (optional). |
| `environmentconfig.database.storageClassName` | string | StorageClass for the primary PostgreSQL data volume (empty uses cluster default). |
| `environmentconfig.database.backupStorageClassName` | string | StorageClass for database backups if supported by the PostgreSQL operator (empty uses cluster default). |

### Authentication and User Management

The workspace API and UI layer use a gateway-based authentication concept. OAuth2 JWTs are passed from the edge (Kubernetes ingress) to the workspace API with validated claims. These claims are enforced to grant management permissions. For more details, see the Workspace API README on [authentication and authorization](https://github.com/EOEPCA/rm-workspace-api/?tab=readme-ov-file#authentication-and-authorization).

Two complementary permission layers exist within the system.

**Global Workspace Administration**

General administrative actions - such as:

- viewing all workspaces  
- editing any workspace  
- creating new workspaces  
- deleting existing workspaces  

are controlled through the `admin` role of the `workspace-api` client.

Users assigned this role have platform-wide authority over the workspace lifecycle and configuration, independent of any individual workspace membership.

**Workspace-Specific Permissions**

In addition to global administration, each workspace has its own dedicated authorization context.

The workspace-pipeline component automatically provisions:

- a dedicated OAuth2 client for each workspace  
- the roles `ws-access` and `ws-admin` bound to that client  

These roles grant permissions only for the specific workspace to which the client belongs.  
This ensures strict isolation between workspaces while still enabling delegated administration at workspace level.

All authentication and authorization decisions are enforced by the EOEPCA IAM framework, based on:

- the APISIX OpenID Connect plugin for identity verification  
- Open Policy Agent (OPA) for fine-grained policy evaluation  

To perform privileged actions, the operator must therefore be:

- authenticated via OIDC  
- assigned the appropriate role  
  - either the global `admin` role on the `workspace-api` client to follow the Operator View  
  - or the workspace-local `ws-admin` or `ws-access` role on the dedicated workspace client to follow the User View  

Only then are management operations permitted by the policy enforcement layer.

By orchestrating **DataLab** resources, the workspace layer also allows these claims to be bootstrapped automatically. This includes provisioning `ws_admin` Keycloak roles in addition to `ws_access` roles, as well as creating the corresponding Keycloak user and admin groups for each individual workspace. All of this is provisioned dynamically through the workspace pipelines orchestrating the DataLab Crossplane XRs.

Further details are available in the [DataLab documentation](https://provider-datalab.versioneer.at/).

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
