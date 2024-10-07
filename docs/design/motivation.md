# Motivation for the changes between workspace v1 and v2

The initial v1 version of the workspace had several design flaws, making it inflexible and difficult for platform operators to use:

* Each workspace had a fixed number of components, including exactly one bucket and a predefined list of services that were available to all users. This rigid structure made it difficult to customize workspaces for specific needs.
* The services were deployed into Kubernetes through an explicit call on the workspace-api, using a provisioning pipeline defined in code. Upgrading these services to newer versions for all users was difficult, as it required additional workspace-api calls for redeployment. Extending the list of services for specific users was even more challenging.
* Provisioning of infrastructure components like the object storage bucket(s) and associated IAM policies and user are always operator specific and the customization possibilities with custom webhooks were cumbersome.
* Kubernetes namespaces were used for multi-tenancy, making some operations manual (e.g. installing CRDs) or impossible for an operator (using different versions of a CRD, RBAC with cluster wide permissions,...).

The v2 version of the workspace mitigates these issues:

* The workspace controller automatically creates a dedicated space in a Git repository (either a new repository or a separate folder) for each workspace, allowing for declarative descriptions of all deployed services with their current software version and configuration, so this information can be easily inspected. Custom services can be installed via GitOps mechanisms and are declaratively stated the same way. 
* The provisioning pipeline is declaratively stated and can be adapted by the operator. Best-practise blueprints are shared in the workspace EOEPCA repository. The provisioning pipeline is continuously reconciled, always trying to match the desired state with the observed state. Updates of services can therefore be selectively or globally triggered via Git.
* The vcluster tooling is automatically deployed per namespace, providing a dedicated Kubernetes API server runtime for each workspace.


PackgeR - bundle files/objects together for distribution, deployment, or storage.

Define Workspace CRD specification allowing the Workspace controller to:
- Establish a dedicated namespace for each project/user in the Host Kubernetes cluster.
- Apply Kubernetes policies such as ResourceQuota, LimitRange, and NetworkPolicy to the namespace.
- Deploy a vCluster with best-practice configurations within the namespace.
- Create a new Git repository (or a folder in an existing Git repository, depending on the global setup) to store the desired manifests for - Workspace Services to be reconciled through Flux GitOps principles.
- Connect Flux to reconcile the Git repository (or folder) with the vCluster.
- Implement Kubernetes Validating Webhooks to enforce bucket creation policies, such as maximum number and size, and naming pattern conventions, within the namespace.

Reconcile [Workspace CRDs](https://github.com/EOEPCA/workspace/issues/1) and expose:
- vCluster credentials for direct “virtual” Kubernetes cluster access,
- Git settings used for Flux,
- The current reconciliation state.


Define Storage CRD specification allowing the Storage controller to:
- Establish a dedicated bucket or connect a federated bucket.
- Configure bucket access and CORS policies for the bucket.

Reconcile [Storage CRDs](https://github.com/EOEPCA/workspace/issues/3) and expose:
- Bucket credentials,
- Access URL,
- The current reconciliation state.

- 
- establish a dedicated namespace for each project/user in the Host Kubernetes cluster.
apply ResourceQuota to namespace
create Storage via a Storage CRD (https://github.com/EOEPCA/workspace/issues/3) to be picked up by Storage Controller (https://github.com/EOEPCA/workspace/issues/4)
deploy Workspace UI (https://github.com/EOEPCA/workspace/issues/7)



- endpoints to 


Physical storage may either be dynamically provisioned (see [Storage CRDs](https://github.com/EOEPCA/workspace/issues/3)) or linked to existing.

Allow users to search and browse through the content of the storage buckets connected to a given workspace using directory-based file system semantics. 

Allow sharing of specific content via pre-signed URLs, enabling direct HTTP access without requiring user authentication.

--

utili