# Concepts

This page introduces the core concepts of the Workspace platform: who uses it, what it’s made of, and how collaboration actually works. At its heart, a Workspace brings together three elements — **Storage**, the **Runtime environment (Datalab)**, and **Tools & Services** — under a single identity and lifecycle.

- **Storage** offers S3-compatible buckets with consistent policies.  
- **The Datalab** provides a browser-based environment (VS Code Server, Terminal, Data Browser) wired to those buckets and credentials.  
- **Tooling** supplies pre-configured CLIs and SDKs combined with operator-provided and user-managed **Services**, so teams can work productively from day one.  

The Workspace ties these parts together by orchestrating Crossplane Compositions, ensuring that what you run is reproducible, auditable, and easy to reason about.

The platform serves three personas with overlapping responsibilities.

**Platform Operators** stand up and maintain the system, connect identity, and enforce guardrails.  

**Workspace Managers** curate the project space, invite members, organize buckets, and define how data is shared.  

**Workspace Users** focus on exploration and delivery, using the Datalab and tools to turn data into results.  

> While these roles clarify intent, there is currently no strict RBAC split between “manager” and “user”: once assigned to a workspace, members possess the same capabilities within that environment.

Identity and access cut across everything. Authentication is centralized in **Keycloak** (OIDC), and authorization is expressed through workspace membership and bucket-level policies. These bucket-level policies are deliberately simple (`readOnly`, `readWrite`, `writeOnly`) and grant flows are supported through an interactive UI. For sustained collaboration, workspaces grant each other access so foreign buckets appear alongside local ones with no extra bootstrap steps. For ad-hoc, external sharing of **individual objects**, users can mint **pre-signed URLs** directly from the lab's Data Browser.  

The Datalab can be **on-demand** (auto-start/cull) for cost-effective interactivity or **always-on** when continuous services are required. Operators can provide shared services as the Datalab runs on the same underlying Kubernetes cluster, and users can deploy their own session-bound additional Servicers — all under the same policy umbrella.

For deeper dives into the building blocks: storage capabilities are implemented by [**provider-storage**](https://provider-storage.versioneer.at), and the interactive runtime by [**provider-datalab**](https://provider-datalab.versioneer.at). Their documentation explains the operational details, usage patterns, and guardrails you can apply in production.

## Storage in Practice

The object storage layer is built and abstracted to allow both operators and users to deploy across different backends depending on needs, constraints, and budgets — providing a unified model for bucket access and sharing.  

It gives end users a simple way to request and share S3 buckets, and it gives operators a consistent control plane to enforce policies across multiple backends such as **MinIO**, **AWS S3**, **OTC OBS**, and others.  

### Example Flow: Cross-workspace collaboration

Users from Alice’s workspace (`ws-alice`) want to access data stored in Eric’s shared workspace (`ws-eric-shared`).  
They therefore **request access** to the relevant bucket, and a member of Eric’s team can **approve or deny the request**, i.e. grant access via simple click when collaboration is desired.

**Result:**  
Alice’s team can directly browse and read the curated objects from Eric’s shared bucket without duplicating data. If the request is denied, the bucket remains inaccessible, ensuring that all data exchange is intentional and auditable.

<div align="center">
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/a1.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/a1.png" height="250" alt="Request Access"/>
  </a>
  &nbsp;
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/a2.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/a2.png" height="250" alt="Grant Access"/>
  </a>
  &nbsp;
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/a3.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/a3.png" height="250" alt="Explore Bucket"/>
  </a>
  &nbsp;
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/a4.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/a4.png" height="250" alt="Access Bucket Data"/>
  </a>
</div>

### Example Flow: Ad-hoc sharing with **pre-signed URLs**

Eric holds interesting VHR data in his bucket and a colleague asks him to share a specific file for review.  He previews the data in the **Data Browser** and generates a **pre-signed URL** directly from the Datalab, which produces a time-limited link. The colleague can then access the object directly without needing a Workspace account or any prior setup.

**Result:**  
The file becomes temporarily accessible to anyone holding the link until it expires. This lightweight sharing method is ideal for quick, one-off reviews or data exchanges outside the workspace, while long-term collaboration should rely on workspace-to-workspace access grants.

<div align="center">
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/b1.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/b1.png" height="250" alt="Preview Bucket Data"/>
  </a>
  &nbsp;
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/b2.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/b2.png" height="250" alt="Share Bucket Data"/>
  </a>
</div>

For further information on specific aspects of the Storage Layer:

- **[Usage Concepts](https://provider-storage.versioneer.at/latest/how-to-guides/usage_concepts/)** — explains how users can create, view, and manage S3 buckets within their workspace, how storage requests are processed, and how shared buckets appear across workspaces through declarative grants.  
- **[Permissions and Access Control](https://provider-storage.versioneer.at/latest/how-to-guides/permissions/)** — describes how workspace-to-workspace access is managed, how readOnly, readWrite, and writeOnly permissions are enforced, and how users can grant or revoke access directly through the Workspace UI.  

## Datalab in Practice

The Datalab is the powerhouse of the workspace experience — an interactive runtime that connects compute, storage, and services. It can operate in **on-demand** mode, where sessions start automatically when needed and shut down when idle, or in **always-on** mode for continuous collaboration or long-running services. Users can also launch auxiliary services bound to their session, such as dashboards, notebooks, or backend APIs, while operators can provide persistent shared services for teams. All Datalab sessions respect workspace policies and quotas, inheriting network rules, resource limits, and access control. Buckets are mounted or accessed via SDKs and command-line tools, while the integrated object browser allows quick previews and pre-signed URL generation.

### Example Flow: Deploying MLflow for Experiment Tracking

Alice wants to train a machine learning model in a Jupyter Notebook within her workspace.  
To ensure the experiment is **tracked and reproducible**, she deploys **MLflow** directly from the Datalab environment. This allows her to monitor metrics, parameters, and results interactively as the training progresses.

**Result:**  
The **MLflow UI** becomes available directly from the Datalab, providing a seamless and interactive experience for experiment tracking and visualization — all within the same authenticated workspace environment.

<div align="center">
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/c1.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/c1.png" height="250" alt="Deploy MLflow"/>
  </a>
  &nbsp;
  <a href="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/c2.png" target="_blank">
    <img src="https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/c2.png" height="250" alt="Share Bucket Data"/>
  </a>
</div>

For further information on specific aspects of the Datalab:

- **[Usage Concepts](https://provider-datalab.versioneer.at/latest/how-to-guides/usage_concepts/)** — explains how users can start, stop, and reconnect Datalab sessions across workspaces. It also outlines persistence options, data retention behavior, and the lifecycle of ephemeral versus persistent sessions.  
- **[Additional Services](https://provider-datalab.versioneer.at/latest/how-to-guides/additional_services/)** — describes how to extend a Datalab session with additional services, such as dashboards, APIs, or other runtime components that can be attached to a user session or shared workspace.  
- **[Security and Constraints](https://provider-datalab.versioneer.at/latest/how-to-guides/security/)** — discusses how authentication, network isolation, and configuration settings are applied in Datalab environments, as well as how quotas and resource limits ensure secure multi-tenant operation.
