# Architecture

## Overview
As laid out in the [System Architecture document](https://eoepca.readthedocs.io/projects/architecture/) the Workspace building-block comprises:

* **Workspace Controller**<br>
  Platform-level API for administration of workspaces with capabilities via an API for **Workspace Provisioning** and **Workspace Utilisation**

* **Storage Controller**<br>
  User-level API for management of storage buckets with capabilities via an API for **Bucket Provisioning**, **Bucket Management** and **Bucket Federation**

* **Workspace Services**<br>
  Comprising the **extensible set of Services** dynamically instantiated on a workspace within the scope of a project/user.

* **Workspace UI**<br>
  **Web-enabled user interface** for the capabilities offered by the Workspace and Storage Controllers.

## Design

A workspace involves allocating compute and storage resources tailored to a specific project or user. By leveraging Kubernetes and the multi-tenant features of the vCluster project, a balance between isolation and cost efficiency is achieved while retaining the benefits of Kubernetes. As a result, a workspace is implemented as a vCluster installation, hosting multiple "virtual" Kubernetes clusters within a single "host" Kubernetes cluster.

In line with Kubernetes native concepts, a workspace is defined using a new Kubernetes Workspace CRD (Custom Resource Definition), with a corresponding Kubernetes **Workspace Controller** responsible for reconciling the desired state as specified in the Workspace CRD manifest on the cluster.

The reconciliation process within the **Workspace Controller** for each workspace manifest involves the following steps

- Establish a dedicated namespace for each project/user in the Host Kubernetes cluster.
- Apply Kubernetes policies such as ResourceQuota, LimitRange, and NetworkPolicy to the namespace.
- Deploy a vCluster with best-practice configurations within the namespace.
- Create a new GIT repository (or a folder in an existing GIT repository, depending on the global setup) to store the desired manifests for Workspace Services to be reconciled through Flux GitOps principles.
- Connect Flux to reconcile the GIT repository (or folder) with the vCluster.
- Implement Kubernetes Validating Webhooks to enforce bucket creation policies, such as maximum number and size, and naming pattern conventions, within the namespace.

and finally exposes

- vCluster credentials for direct "virtual" Kubernetes cluster access,
- GIT settings used for Flux,
- The current reconciliation state.

An operator can establish a workspace for a project/user imperatively via the Kubernetes API by submitting a Workspace manifest or by following a declarative (Gitops-style) approach with the Workspace manifest checked in to GIT. The Kubernetes Web UI Dashboard may be deployed on the "host" Kubernetes cluster supporting the operator process in a graphical way during **Workspace Provisioning**. For **Workspace Utilization** dedicated Grafana dashboard are established tracking workspace metrics.

Note: The EOEPCA 1.x workspace API is obsolete and not included in EOEPCA+.

A workspace can be accessed via the Kubernetes API and is integrated with GitOps tooling through Flux. Both common and optional components can be installed for a specific project or user. By default, the template GitRepository includes the Storage Controller, responsible for **Bucket Provisioning** and **Bucket Federation**, as well as common EOEPCA Building Blocks (BB) for resource discovery and EO data management. These **Workspace Services** can be enriched with additional tools from the EOEPCA Application Hub BB and EOEPCA MLHub BB.

The **Storage Controller** is tasked with reconciling the desired state as specified in the storage manifest (for the new Kubernetes Storage CRD). It uses Terraform internally for the reconciliation process, with documentation providing specifications for common cloud providers like AWS as examples.

Note: Kubernetes Validating Webhooks established in the namespace of the "host" cluster will enforce proper bucket creation policies.

The reconciliation process within the Storage Controller for each storage manifest includes the following steps:

- Establish a dedicated bucket or connect a federated bucket.
- Configure bucket access and CORS policies for the bucket.

and finally exposes:

- Bucket credentials,
- Access URL,
- The current reconciliation state.

TBC
