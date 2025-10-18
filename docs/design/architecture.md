# Architecture

The Workspace Building Block (BB) provides a cohesive and modular environment that unifies **compute**, **storage**, and **tooling** into a single declaratively managed system. Its architecture is Kubernetes-native, built upon [Crossplane](https://crossplane.io), which serves as the foundation for modeling and orchestrating complex service dependencies using Custom Resource Definitions (CRDs) and Compositions.  

## Architectural Composition

At its core, the Workspace BB is composed of three tightly integrated subsystems:

**Storage Management** — implemented through the [provider-storage](https://provider-storage.versioneer.at) abstraction, which provisions and manages object storage across multiple backends such as MinIO, AWS S3, and OTC OBS.  
   
   - Buckets are represented as Kubernetes CRs (`Storage` objects).  
   - The reconciliation process automatically provisions S3 buckets, configures access policies (e.g. read-write grants), and returns endpoint and credential data to dependent components such as datalabs or applications.  
   - Credentials are securely propagated into runtime environments via Kubernetes secrets or environment variables.  
   - The system supports both local and external S3-compatible endpoints, enabling hybrid storage configurations.

**Runtime Management** — handled by the [provider-datalab](https://provider-datalab.versioneer.at), which builds on the [educates.dev](https://educates.dev) project to create isolated compute environments either as Kubernetes namespaces or as [vClusters](https://www.vcluster.com/) for enhanced multi-tenancy and isolation.  
   
   - Each datalab hosts one or more user-facing applications such as VSCode Server or web-based terminal and browser interfaces.  
   - Datalabs automatically connect to workspace-specific storage, mounting buckets via [CSI Rclone](https://github.com/versioneer-tech/csi-rclone) into the file system and preloading common command-line tools (`awscli`, `rclone`, `boto3`).  
   - This design ensures immediate, persistent, and secure access to datasets — supporting both exploratory workflows and automated pipelines.  
   - Users can extend Datalabs by deploying additional Kubernetes-native services such as databases, dashboards, or custom data processors.

**Orchestration & Interaction Layer** — composed of the [workspace-api](https://github.com/EOEPCA/rm-workspace-api) and the Workspace UI, which form the primary entry point for users and operators.  
   
   - The API provides a unified REST interface that translates user actions (e.g., creating a workspace, adding buckets, or launching Datalabs) into declarative CRDs managed by [Crossplane](https://crossplane.io).  
   - The UI presents these capabilities graphically, enabling users to create and manage storage, grant or revoke bucket access, and invite collaborators.  
   - Authentication and authorization are delegated to Keycloak, ensuring that each workspace inherits consistent identity, role, and group configurations across all integrated services.

## Crossplane as the Control Plane

All orchestration logic is implemented declaratively through [Crossplane](https://crossplane.io) Compositions. Each high-level abstraction — such as Workspace, Storage, or Datalab — is modeled as a Composite Resource (XR) that maps to one or more Managed Resources (MR).

This layered model allows infrastructure and application services to be managed through the same GitOps workflow as any Kubernetes manifest:

- Providers such as [provider-kubernetes](https://marketplace.upbound.io/providers/crossplane-contrib/provider-kubernetes), [provider-helm](https://marketplace.upbound.io/providers/crossplane-contrib/provider-helm), [provider-minio](https://marketplace.upbound.io/providers/crossplane-contrib/provider-minio), and [provider-keycloak](https://marketplace.upbound.io/providers/crossplane-contrib/provider-keycloak) expose declarative APIs for managing external systems.  
- Compositions define how these providers interact to realize higher-level abstractions (e.g., create a bucket, generate credentials, store them as a secret, and inject them into a datalab).  
- EnvironmentConfigs define cluster-wide parameters such as ingress domains, TLS secrets, S3 endpoints, and Keycloak realms, ensuring that all Compositions operate within a consistent configuration context.

Each workspace is therefore not a fixed allocation but a composable graph of managed resources — continuously synchronized through Crossplane’s reconciliation loop to ensure desired state alignment.

## Runtime and Storage Integration

A key design goal of the Workspace BB is data proximity and transparent access. Every datalab automatically receives credentials for the storage resources within its workspace scope. Using CSI Rclone, these buckets are mounted as file systems inside the containerized environment, providing familiar navigation and manipulation of data.  

The integrated file browser in the Datalab UI allows:

- Hierarchical navigation of storage buckets  
- Preview of text, imagery, and EO product assets  
- Instant data sharing via presigned URLs  

By exposing data through both object APIs and filesystem mounts, users can fluidly transition between interactive analysis, batch computation, and automated packaging workflows — without reconfiguring credentials or access paths.

## IAM and Policy Enforcement

Identity and Access Management (IAM) is centralized through Keycloak, ensuring consistent user identity and access policies across the entire platform. Crossplane’s [provider-keycloak](https://marketplace.upbound.io/providers/crossplane-contrib/provider-keycloak) enables the declarative management of users, groups, clients, and roles — functionality dynamically leveraged by the [provider-datalab](https://provider-datalab.versioneer.at) compositions to associate these entities with specific workspaces and runtime environments.  

This approach ensures that collaboration is securely limited to authorized users within designated workspaces, maintaining both security and compliance across all deployments.  
It also lays the groundwork for future extensions, enabling more granular role-based access control across services and datasets.

## Declarative Workflow

The entire system operates on declarative state entities managed through [Crossplane](https://crossplane.io) compositions. All resources exist natively within Kubernetes and are continuously reconciled, ensuring complete traceability, consistency, and reproducibility across all components.  

Storage, runtime, and IAM elements are defined as Kubernetes manifests and can be orchestrated either by the [workspace-api](https://github.com/EOEPCA/rm-workspace-api) or deployed manually — for instance via direct API calls or GitOps tools such as Flux or ArgoCD.  
This approach provides full flexibility in how the platform is operated, including hybrid modes where certain entities are managed declaratively through GitOps while others are created dynamically via API interactions.  
This model is particularly advantageous for static or example setups, which can be easily bootstrapped and maintained using the same declarative principles.

## Motivation for Switch from v1 to v2

The initial **v1** implementation of the Workspace introduced a functional but rigid design that limited operator flexibility, scalability, and usability in collaborative contexts.  

- Each workspace included exactly one bucket and a fixed set of services, preventing customization for specific projects or workloads.  
- A workspace was implicitly tied to a single user through a naming convention — a team concept did not exist.  
- Service deployment relied on imperative API calls, making upgrades, versioning, and selective redeployment difficult to automate.  
- Infrastructure provisioning (e.g., buckets, IAM policies) required operator-specific logic and custom webhook extensions.  
- Multi-tenancy was limited to namespace isolation, which complicated CRD versioning, RBAC scoping, and cluster-wide policy management.  

The **v2** model resolves these limitations through a declarative workflow based on composable pipelines and continuous reconciliation.  It introduces flexible team membership, optional [vCluster](https://www.vcluster.com/) integration for enhanced multi-tenancy, and a unified GitOps-compatible model — allowing operators and users alike to declaratively define and evolve workspaces, services, and access policies with full transparency and control.