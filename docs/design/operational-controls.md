# Operational Controls

## Session Mode

If **sessions** are not generally *disabled* via the corresponding session mode flag, the **Workspace Building Block (BB)** provides isolated, user-facing compute environments (*Datalabs*) running on top of a shared Kubernetes host cluster.  These sessions can be either *long-running* or *started on-demand* (in so called `Auto` session mode), with background jobs automatically shutting down inactive sessions according to configurable criteria.  Both modes maintain persistent access to user files, configurations, and mounted object storage, ensuring seamless continuity between session restarts.

Each workspace represents a logical boundary for a team or project and includes its own compute, storage, and access configuration.  While users are free to execute arbitrary code, deploy additional components through the Kubernetes API (e.g., via `kubectl`), or interact with data via networked storage and APIs, platform operators must ensure that this flexibility remains **secure**, **resource-efficient**, and **compliant** with operational policies.  

Details on the underlying security model of the Datalab environment are available in the [provider-datalab security documentation](https://provider-datalab.versioneer.at/latest/how-to-guides/security/).

## Cluster Exposure

Workspaces can run either in *namespace mode* (shared host control plane) or in *vCluster mode* (isolated virtual control plane based on [vCluster](https://vcluster.com)).

- In *namespace mode*, workspaces share the host Kubernetes control plane. This mode has minimal overhead and is suited for trusted environments where global RBAC and quotas can be centrally enforced.  
- In *vCluster mode*, each workspace runs its own k3s-based control plane (API server, controller-manager, scheduler) inside a pod on the host cluster. Users interact with the vCluster as if it were a standalone Kubernetes cluster.

vClusters offer stronger isolation but introduce a modest baseline overhead (~300–500 MiB RAM, 0.1–0.2 vCPU per idle control plane).

## Deployment Permissions

Controlled through Kubernetes RBAC and namespace-level policies. 

- Operators can restrict the creation of `Ingress`, `ClusterRole`, or `ClusterRoleBinding` resources.  
- Privileged pods or the use of `HostPath` mounts can be blocked.  
- Resource consumption can be limited through `LimitRange` and `ResourceQuota` definitions on the namespace level, passed through [provider-datalab](https://provider-datalab.versioneer.at/) configuration.

## Network Isolation

Enforced via **NetworkPolicies** to define allowed communication paths.  

- Outbound traffic can be limited.  
- Cross-workspace pod communication can blocked to prevent lateral movement.  
- Egress to the public internet can be disabled, except for approved external data sources.  

## Ingress and Authentication

Ingress routing should handled centrally at the host-cluster level (not within individual vClusters).  

## Data Persistence and Storage

- Persistent volumes are used for:

  - Control plane state (vCluster metadata)  
  - User home directories and shared data (`ReadWriteMany` PVCs)  
  - Object storage integration via [CSI Rclone](https://github.com/versioneer-tech/csi-rclone)
