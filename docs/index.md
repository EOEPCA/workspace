# Introduction

The **Workspace Building Block (BB)** provides a unified environment where large amounts of data may become instantly accessible, analysable, and shareable. It combines **object storage**, **interactive runtimes**, and **collaborative tooling** into a single Kubernetes-native platform — built on **Crossplane v2** and fully integrated with **Keycloak** for identity and access control.

<div align="center">
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui1.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui1.png" height="250" alt="Workspace UI"/>
  </a>
</div>

Workspaces enable individuals, teams, and organisations to provision isolated, self-service environments for data access, algorithm development, and collaborative exploration — all **declaratively managed** on Kubernetes and orchestrated through the **Workspace REST API** or an intuitive **web interface** built on top of it.

## Key Capabilities

### Unified Storage and Runtime
Each workspace integrates **persistent object storage** (via [provider-storage](https://provider-storage.versioneer.at)) and **interactive compute environments** (via [provider-datalab](https://provider-datalab.versioneer.at)).

<div align="center">
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui3.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui3.png" height="250" alt="Datalab Terminal"/>
  </a>
</div>

Users can browse data, launch code editors or terminals, and generate secure share links directly from their Datalab — without leaving the browser.

<div align="center">
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui4.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui4.png" height="250" alt="Datalab Browser"/>
  </a>
</div>

### Declarative Lifecycle Management
Workspaces are managed through **Crossplane compositions**, ensuring reproducible provisioning and continuous reconciliation. Storage, runtime, and IAM components are described as manifests and can either be orchestrated by the Workspace API or be deployed manually, via API, or through GitOps tools such as Flux or ArgoCD.

```
kubectl get storage -A
NAMESPACE   NAME        SYNCED   READY   COMPOSITION     AGE
workspace   ws-alice    True     True    storage-minio   8d
workspace   ws-bob      True     True    storage-minio   8d
workspace   ws-eric     True     True    storage-minio   8d
```

### Secure Collaboration
Built-in **Keycloak** integration ensures unified authentication and fine-grained access control. Workspace owners can **invite collaborators** and **manage shared storage** by granting or revoking access permissions as needed. Upcoming releases will introduce **vended credentials** for scoped, time-limited access tokens.

<div align="center">
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui2.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/ui2.png" height="250" alt="Bucket Sharing"/>
  </a>
</div>

### Extensible by Design  
Datalab environments can be **curated and customised by teams themselves**, allowing them to adapt the workspace to their individual needs. Running on top of Kubernetes, each Datalab provides the flexibility to **deploy additional services** — such as catalogues, dashboards, or experiment-tracking tools — directly through the Kubernetes API (e.g. using `kubectl`).  

Operators can decide whether to expose a **full Kubernetes API** (via *vcluster*) or to provide **namespaced access** within a shared cluster.  
Within these environments, teams can further personalise their Datalabs by installing additional tools, libraries, or configurations into their **persistent workspace**.

## Architecture Overview

The Workspace Building Block integrates several core components:

- **Workspace API and UI**  
  Orchestrate storage, runtime, and tooling resources via a unified REST API by managing the underlying Kubernetes Custom Resources (CRs).

- **Storage Controller (`provider-storage`)**  
  A Kubernetes Custom Resource responsible for creating and managing S3-compatible buckets (e.g., MinIO, AWS S3, or OTC OBS).

- **Datalab Controller (`provider-datalab`)**  
  A Kubernetes Custom Resource used to deploy persistent VSCode-based environments with direct object-storage access — either directly on Kubernetes or within a vCluster — preconfigured with essential services and tools.

- **Identity & Access (Keycloak)**  
  Manages user and team identities, enabling role-based access control and granting permissions to specific Datalabs and storage resources.