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
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui1.png" height="500" alt="Workspace UI - Additional Bucket Creation"/>
  </a>
  &nbsp;
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui2.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui2.png" height="500" alt="Workspace UI - Bucket Sharing"/>
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

## Deployment

This repository serves as an umbrella for documentation and dynamic Helm-chart creation.  
Published charts appear as GitHub Packages under this repository [here](https://github.com/orgs/EOEPCA/packages?tab=packages&q=workspace).

## License

Apache 2.0 (Apache License Version 2.0, January 2004)  
<https://www.apache.org/licenses/LICENSE-2.0>
