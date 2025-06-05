# Workspace BB

## Goals and Responsibilities

The Workspace BB is a foundational component designed to provide secure, adaptable, and extensible workspaces for individuals or collaborative groups. Its primary responsibilities include:

1. **Compute Resource Provisioning**: Dynamically allocates compute resources within a Kubernetes cluster, ensuring tenant isolation and security. This is achieved using namespaces or vClusters, with adjustable resource quotas to optimize resource utilization.  
2. **Object Storage Provisioning**: Facilitates the creation and management of object storage resources, enabling secure data storage and sharing within each workspace.  
3. **Deployment of Ready-to-Use Applications**: Automatically sets up applications like the Workspace UI tool, empowering users to efficiently manage resources, access visualizations, and interact seamlessly with their workspace.  
4. **Keycloak-Based IAM Integration**: Automates the provisioning of Keycloak resources, integrating workspaces with Identity and Access Management (IAM) systems to secure access and safeguard resources.  
5. **Customizable Services**: Enables operators to deploy additional services through declarative configuration using GitOps and Kubernetes-native tools, allowing workspaces to be tailored to unique project or user requirements.  

These capabilities make the Workspace BB a critical enabler for environments requiring scalable compute and storage resources, robust access controls, and tailored service deployments.

## Implementation Concept

The component responsible for resource provisioning are Workspaces pipelines, which are built with [Crossplane](https://github.com/crossplane/crossplane) ([Apache 2 License](https://github.com/crossplane/crossplane/blob/main/LICENSE)), a Kubernetes-native framework. It is augmented with other Kubernetes-native features to deliver a flexible and powerful solution for resource and service management.

### Core Implementation Features

1. **Crossplane Providers**: The declarative nature of Crossplane allows operators to adapt and configure pipelines with various providers. In the EOEPCA Demo Blueprint, the following providers are employed:
   - [Provider-MinIO](https://github.com/vshn/provider-minio) ([Apache 2 License](https://github.com/vshn/provider-minio/blob/main/LICENSE))
   - [Provider-Kubernetes](https://github.com/crossplane-contrib/provider-kubernetes) ([Apache 2 License](https://github.com/crossplane-contrib/provider-kubernetes/blob/main/LICENSE))
   - [Provider-Helm](https://github.com/crossplane-contrib/provider-helm) ([Apache 2 License](https://github.com/crossplane-contrib/provider-helm/blob/main/LICENSE))
   - [Provider-Keycloak](https://github.com/crossplane-contrib/provider-keycloak) ([Apache 2 License](https://github.com/crossplane-contrib/provider-keycloak/blob/main/LICENSE))

2. **External Secrets Operator**: The system uses the [External Secrets Operator](https://external-secrets.io) to securely handle sensitive data within the Kubernetes ecosystem, with setup [here](./setup/common/eso.yaml)

3. **CSI Providers**: To enable browsing of mounted storage in the Workspace UI (for generating pre-signed URLs for data sharing), the standard mechanism of Kubernetes Persistent Volumes via CSI is used. We are utilizing [RClone](https://github.com/rclone/rclone), but alternatives such as [S3FS-Fuse](https://github.com/s3fs-fuse/s3fs-fuse) or [AWS mountpoint-s3](https://github.com/awslabs/mountpoint-s3) can be substituted as mount-based drivers.

This implementation is inherently Kubernetes-native, emphasizing modularity, scalability, and the flexibility to address diverse platform and user needs.

### Setup & Pipeline Blueprints Overview

Pipeline blueprints illustrate how core features are integrated and applied to provision resources across different infrastructure setups.

1) Required Base Setup

The [`common`](/setup/common) component is **always required**. It installs the Keycloak Provider on top of Crossplane and provides the foundational functionality.


2) Optional: Additional Functionality for Storage and Compute Workspaces

To enable extended features, the [`prerequisites`](/setup/prerequisites) module must always be installed. On top of that, different combinations of storage and workspace setups can be selected depending on the intended use case:

- [EOEPCA Demo](https://github.com/EOEPCA/workspace/tree/main/setup)

   Uses:

   - In-cluster MinIO buckets  
   - vCluster for isolated environments

   Required Modules:

   - [`storage-minio`](/setup/minio)
   - [`workspace-vcluster`](/setup/workspace-vcluster/)

   > 💡 *Note:* This setup uses ArgoCD for rollout.  
   > - You can explore the ArgoCD Application Manifests via the link above.  
   > - Ensure correct component order using `argocd.argoproj.io/sync-wave` annotations.  
   > - Disable pruning and auto-syncing, as Crossplane's provider model does not integrate seamlessly with ArgoCD in fully automated replacement/deletion scenarios.

- Terrabyte Blueprint

   Uses:

   - Quobyte** storage via regular Kubernetes PersistentVolumes and StorageClass, so only dummy Storage implementation is needed.
   - Workloads installed directly into a dedicated namespace on the host cluster.

   Required Modules:

   - [`storage-dummy`](/setup/dummy)
   - [`workspace-hostcluster`](/setup/workspace-hostcluster/)

   > 💡 *Note:* This setup uses ArgoCD for rollout as well.