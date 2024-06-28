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
