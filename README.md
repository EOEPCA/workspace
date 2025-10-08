# Workspace BB

The **Workspace Building Block (BB)** provides secure and extensible workspaces that combine compute, storage, and tools into one cohesive environment.  
It represents a **trifecta** of capabilities — **storage**, **runtime**, and **tooling** — designed to simplify how users work with data, collaborate, and deploy applications.

A workspace brings together:

1. **Storage Resources** — object storage or network volumes for persisting and sharing data.  
2. **Runtime Environments** — isolated Kubernetes namespaces or [vClusters](https://www.vcluster.com/) providing a full Kubernetes API surface for workloads.  
3. **Domain-Specific Tooling** — e.g. VSCode-based datalabs preconfigured for Earth Observation, data analysis, or processing workflows.

These three elements form the core of the Workspace concept.  
They are managed using Kubernetes-native resources — a **Storage** abstraction for object storage (MinIO, AWS S3, OTC, etc.) and a **Datalab** abstraction providing an interactive development and execution environment.

Both layers are orchestrated by the [Workspace API & UI](https://github.com/EOEPCA/rm-workspace-api/), which exposes an HTTP API and web interface to manage users, storage, and runtime resources for individuals or teams.


## Core Responsibilities

1. **Compute Provisioning** — Allocates compute environments within Kubernetes using namespaces or vClusters for isolation and resource control.  
2. **Object Storage Provisioning** — Creates and manages workspace-specific object storage, including access policies and credentials.  
3. **Application Setup** — Deploys ready-to-use user environments such as VSCode datalabs or the Workspace UI.  
4. **IAM Integration** — Uses Keycloak to automate user, group, and role management, ensuring secure access across all layers.


## Implementation Concept

The Workspace BB is built on **[Crossplane](https://github.com/crossplane/crossplane)** — an open-source control plane that extends Kubernetes with declarative resource provisioning and **composable APIs**.  
In addition to managing infrastructure, Crossplane enables the definition of custom APIs through **Compositions**, allowing domain-specific abstractions such as “Storage,” “Datalab,” or “Workspace” to be defined declaratively and combined into higher-level resource types.

The Workspace BB leverages this composability by defining its own Crossplane **Compositions** that tie together compute, storage, and IAM layers under one unified “Workspace” API.  
This allows infrastructure and service provisioning to be described, versioned, and managed in the same way as standard Kubernetes resources.

The main providers used are:

- **Provider-Kubernetes** — manages native Kubernetes resources.  
- **Provider-Helm** — installs and configures Helm-based components.  
- **Provider-Keycloak** — provisions users, clients, and roles for IAM.  
- **Provider-MinIO** — handles S3-compatible object storage, but can be replaced by any other provider supporting AWS S3, OTC, or similar APIs.


## Kubernetes-Native Design

The Workspace API sits on top of two CRDs — **Storage** and **Datalab** — and reads and patches them to present a unified “Workspace” view.  
This view includes the workspace’s storage, memberships, and session state, while all operations are applied via standard REST calls to simplify access and hide the complexity of direct CRD management.

The Workspace API acts as a **facade** over the underlying Kubernetes resources, providing a single entry point for managing all workspace-related entities while remaining fully declarative and compliant with Kubernetes conventions.

See: [Storage CRD](https://provider-storage.versioneer.at/latest/reference-guides/api/) · [Datalab CRD](https://provider-datalab.versioneer.at/latest/reference-guides/api/)



## Storage and Runtime Integration

Workspaces integrate object storage directly through CSI drivers, allowing data to be accessed as mounted volumes or via presigned URLs.  
[RClone CSI](https://github.com/rclone/rclone) is used by default, with alternatives like [s3fs-fuse](https://github.com/s3fs-fuse/s3fs-fuse) or [mountpoint-s3](https://github.com/awslabs/mountpoint-s3) supported.

Each workspace can include a **Datalab**, typically a VSCode instance deployed into its namespace or vCluster.  
It is preconfigured with storage credentials and tools such as the AWS CLI or rclone, allowing immediate access to workspace data for analysis or automation.


## Design Approach

The Workspace BB emphasizes:

- **Kubernetes-Native Integration** — all resources are CRDs managed by the Kubernetes control plane.  
- **Composable APIs** — Crossplane Compositions define higher-level abstractions that unify multiple resource types.  
- **Multi-Cloud Compatibility** — supports S3-compatible and cloud-specific environments.  
- **Reproducibility** — all configurations are declarative and versioned.  
- **Simplicity** — the Workspace API abstracts low-level CRD operations into familiar REST endpoints.


## License

[Apache 2.0](LICENSE)  
(Apache License Version 2.0, January 2004)  
https://www.apache.org/licenses/LICENSE-2.0