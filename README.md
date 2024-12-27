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
   - [Provider-MinIO](https://github.com/vshn/provider-minio) ([Apache 2 License](https://github.com/vshn/provider-minio/blob/main/LICENSE)): config [here](./setup/eoepca-demo/crossplane-provider-minio.yaml)
   - [Provider-Kubernetes](https://github.com/crossplane-contrib/provider-kubernetes) ([Apache 2 License](https://github.com/crossplane-contrib/provider-kubernetes/blob/main/LICENSE)): config [here](./setup/eoepca-demo/crossplane-provider-kubernetes.yaml)
   - [Provider-Helm](https://github.com/crossplane-contrib/provider-helm) ([Apache 2 License](https://github.com/crossplane-contrib/provider-helm/blob/main/LICENSE)): config [here](./setup/eoepca-demo/crossplane-provider-helm.yaml)
   - [Provider-Keycloak](https://github.com/crossplane-contrib/provider-keycloak) ([Apache 2 License](https://github.com/crossplane-contrib/provider-keycloak/blob/main/LICENSE)): config [here](./setup/eoepca-demo/crossplane-provider-keycloak.yaml)

2. **External Secrets Operator**: The system uses the [External Secrets Operator](https://external-secrets.io) to securely handle sensitive data within the Kubernetes ecosystem, with setup [here](./setup/eoepca-demo/eso.yaml)

3. **CSI Providers**: For platform-level storage operations, [CSI-Rclone](https://github.com/SwissDataScienceCenter/csi-rclone) ([Apache 2 License](https://github.com/SwissDataScienceCenter/csi-rclone/blob/master/LICENSE)) is the default driver, with setup [here](./setup/eoepca-demo/csi-rclone.yaml). It facilitates browsing of mounted storage in the Workspace UI to generate pre-signed URLs for data sharing. Alternatives such as [S3FS-Fuse](https://github.com/s3fs-fuse/s3fs-fuse) or [AWS mountpoint-s3](https://github.com/awslabs/mountpoint-s3) mount-based drivers can be substituted, but these CSI providers are not intended for end-user data access.

This implementation is inherently Kubernetes-native, emphasizing modularity, scalability, and the flexibility to address diverse platform and user needs.

## Pipeline Blueprints

Pipeline blueprints showcase the integration of these features and their application in provisioning resources across various infrastructure setups:

- [EOEPCA Demo Blueprint](https://github.com/EOEPCA/workspace/tree/main/setup/eoepca-demo): Demonstrates the implementation of the Workspace BB in a practical setting using in-cluster MinIO buckets.
- **EOX-AWS Blueprint** (Coming Soon!): A planned pipeline leveraging AWS infrastructure.  
- **DLR-Terrabyte Blueprint** (Coming Soon!): A forthcoming pipeline customized for DLR-Terrabyte-specific requirements.  
