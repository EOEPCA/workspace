
# Understanding vCluster: Setup and Operational Considerations

`vCluster` offers significantly more flexibility and stronger multi-tenancy guarantees than exposing a single Kubernetes namespace. However, for long-term sustainable operation, there are still several architectural and operational decisions that must be made by the platform operator. This document outlines our current setup and highlights these decisions, particularly with regard to static and dynamic operation modes.

## Different Operational Models for vCluster

In the **static mode**, vClusters are provisioned ahead of time and persist over their lifetime. Optionally, they can be scaled down to zero. Note that this only works if an `ownerReference` is configured to ensure that dependent user workloads (such as pods) are also shut down correctly. This mode is resource-stable but incurs a constant footprint.

In contrast, the **dynamic mode** allows vClusters to be spawned on-demand based on user requests. This makes the ephemeral nature of the environment clearer to users, while their storage is persistently mounted into pods. In this setup, a proper UI indicating whether a vCluster is currently running or not is even more necessary, highlighting that user state may be ephemeral or must be externalized. This can be supported by tooling, but it also requires proper status indication and user guidance.

In a static vCluster deployment, each instance has a fixed compute and storage footprint. We use the `k0s` Kubernetes distribution, which results in a number of always-on components: the control plane container, the init container for bootstrapping `k0s`, the vCluster proxy, and a metrics server.

This introduces a baseline resource overhead. Even when idle, a vCluster typically consumes around 300–500MiB of memory and 0.1–0.2 vCPU. These values should be monitored over time and optimized based on workload patterns.

Each vCluster instance also requires a dedicated PersistentVolumeClaim (PVC) for storing control plane metadata such as Kubernetes Custom Resources. This volume is provisioned using a specific `storageClassName`.

In addition, PVCs for user code and data are mounted into pods. These must support `ReadWriteMany` access modes — typically via NFS — since multiple containers may need access to the same volume. However, NFS can become a performance bottleneck when working with large numbers of small files, so this should be evaluated based on usage patterns.

## Resource Synchronization

To enable access to shared infrastructure while maintaining strong workspace isolation, we synchronize key Kubernetes resources between the virtual cluster and the host cluster.

PVCs created inside the vCluster are automatically backed by volumes on the host. Host-side storage classes are made visible to the vCluster, allowing user pods to dynamically provision volumes.

Secrets are selectively mapped into the virtual cluster using a controlled mapping strategy. All secrets from the host namespace where the vCluster runs are automatically mounted into the `default` namespace inside the vCluster. This enables secure injection of credentials (such as kubeconfigs or S3 tokens) without overexposing host resources.

ServiceAccounts created inside the vCluster are also synced back to the host cluster. This supports identity mapping and integration with host-level RBAC and access policies.

## Networking and Ingress Design

We deliberately do not enable ingress inside the vCluster. Instead, all routing is handled by a centralized ingress controller operating in the host cluster (e.g., APISIX or Traefik). This model aligns with patterns used in multi-tenant platforms like JupyterHub, where a single internal component acts as a gateway to all services in a workspace.

This approach simplifies routing, centralizes TLS termination, and allows authentication and access policy enforcement to be handled in a uniform way by the platform operator.

## TLS and SAN Handling

We expose the vCluster control plane via a unique server URL and context, with custom SANs configured using the `proxy.extraSANs` config option. This allows users to interact with their vCluster instance using standard tools like `kubectl`, while still benefiting from certificate-based validation.

To support this, TLS passthrough must be enabled at the outer ingress or load balancer. TLS must be terminated inside the vCluster to allow the custom SAN to be validated correctly.

## CoreDNS Integration

Each vCluster runs its own CoreDNS instance. This ensures that Kubernetes-internal DNS resolution works independently for tenant workloads.

Where needed, the vCluster CoreDNS can forward queries to the host DNS for resolving external services such as persistent volume provisioning endpoints, container registries, or federated identity services. This design ensures seamless interoperation with the host cluster while preserving namespace isolation within the vCluster.
