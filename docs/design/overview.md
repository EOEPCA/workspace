# Architecture

## Overview
As laid out in the [System Architecture document](https://eoepca.readthedocs.io/projects/architecture/) the Workspace building-block comprises:

* **Workspace Controller**<br>
  Platform-level API for administration of workspaces with capabilities of the Workspace Controller API for **Workspace Provisioning** and **Workspace Utilisation**

* **Storage Controller & Storage Layer**<br>
  User-level API for management of storage buckets with capabilities of the Storage Controller API for **Bucket Provisioning**, **Bucket Management** and **Bucket Federation** and of the Storage Layer API and UI for **Bucket Content Browsing** and specific **Bucket Content Sharing** via HTTP.

* **Workspace Services**<br>
  Comprising the **extensible set of Services** dynamically instantiated on a workspace within the scope of a project/user.

* **Workspace & Storage UI**<br>
  **Web-enabled user interfaces** designed for operators resp. users, offering relevant capabilities in an intuitive manner.

## Design

A workspace involves allocating compute and storage resources tailored to a specific project or user. By leveraging Kubernetes and the multi-tenant features of the vCluster project, a balance between isolation and cost efficiency is achieved while retaining the benefits of Kubernetes. As a result, a workspace is implemented as a vCluster installation, hosting multiple "virtual" Kubernetes clusters within a single "host" Kubernetes cluster.

In line with Kubernetes native concepts, a workspace is defined using a new Kubernetes Workspace CRD (Custom Resource Definition), with a corresponding Kubernetes **Workspace Controller** responsible for reconciling the desired state as specified in the Workspace CRD manifest on the cluster.

The reconciliation process within the **Workspace Controller** for each workspace manifest involves the following steps

- Establish a dedicated namespace for each project/user in the Host Kubernetes cluster.
- Apply Kubernetes policies such as ResourceQuota, LimitRange, and NetworkPolicy to the namespace.
- Deploy a vCluster with best-practice configurations within the namespace.
- Create a new Git repository (or a folder in an existing Git repository, depending on the global setup) to store the desired manifests for Workspace Services to be reconciled through Flux GitOps principles.
- Connect Flux to reconcile the Git repository (or folder) with the vCluster.
- Implement Kubernetes Validating Webhooks to enforce bucket creation policies, such as maximum number and size, and naming pattern conventions, within the namespace.

and finally exposes

- vCluster credentials for direct "virtual" Kubernetes cluster access,
- Git settings used for Flux,
- The current reconciliation state.

An operator can establish a workspace for a project/user imperatively via the Kubernetes API by submitting a Workspace manifest or by following a declarative GitOps approach with the Workspace manifest checked in to Git. The Kubernetes Web UI Dashboard may be deployed on the "host" Kubernetes cluster supporting the operator process in a graphical way during **Workspace Provisioning**. For **Workspace Utilization** dedicated Grafana dashboard are established tracking workspace metrics.

Note: The EOEPCA 1.x workspace API is obsolete and not included in EOEPCA+.

A workspace can be accessed via the Kubernetes API and is integrated with GitOps tooling through Flux. Both common and optional components can be installed for a specific project or user. By default, the template GitRepository includes the Storage Controller API, responsible for **Bucket Provisioning**, **Bucket Management** and **Bucket Federation**, the Storage Layer API and UI for **Bucket Content Browsing** and specific **Bucket Content Sharing** via HTTP, as well as common EOEPCA Building Blocks (BB) for resource discovery and EO data management. These **Workspace Services** can be enriched with additional tools from the EOEPCA Application Hub BB and EOEPCA MLHub BB.

The **Storage Controller** is tasked with reconciling the desired state as specified in the storage manifest (for the new Kubernetes Storage CRD). It uses Terraform internally for the reconciliation process, with documentation providing specifications for common cloud providers like AWS as examples.

Note: Kubernetes Validating Webhooks established in the namespace of the "host" cluster will enforce proper bucket creation policies.

The reconciliation process within the Storage Controller for each storage manifest includes the following steps:

- Establish a dedicated bucket or connect a federated bucket.
- Configure bucket access and CORS policies for the bucket.

and finally exposes:

- Bucket credentials,
- Access URL,
- The current reconciliation state.

The **Storage Layer** is implemented as a microservice that allows users to search and browse through the content of the storage buckets connected to a given workspace using directory-based file system semantics. For "text files" like markdown, direct preview capabilities are provided. Besides navigation and search, the main use case for the Storage Layer is sharing specific content via pre-signed URLs, enabling direct HTTP access without requiring user authentication.

Note: The EOEPCA+ team acknowledges that object storage solutions like AWS S3 store content as key-value pairs without true directory functionality, which can have performance implications when using a file system abstraction. By supporting only read-only browsing and not allowing modifications like move or rename operations, treating bucket content as files within the storage layer has been identified as the most intuitive approach for users to navigate content hierarchies.
