# Operational controls

Use these settings to choose when sessions start, how much storage and memory they can request, and which services they can reach. The platform operator manages the host cluster, public routing, and storage services.

## Sessions

Choose whether a new workspace starts a session immediately, starts one when a user opens it, or has no default session. The Workspace API's `SESSION_MODE` sets this initial state:

| Value | Initial state |
| --- | --- |
| `auto` | Declare `default` as `stopped`; opening its Datalab link starts it. |
| `on` | Declare `default` as `started`. |
| `off` | Do not declare a default session. |

Automatic shutdown needs an operator job or policy. The API does not stop idle sessions by itself.

A stopped session keeps its home PVC. Object storage and shared Data or database services have separate lifecycles. Set `spec.quota` for session memory, volume size, and budget. `spec.overallQuota.storage` limits requested PVC storage in the Datalab environment namespace; it does not cover object storage or PVCs in other namespaces.

## Kubernetes access

Namespace mode uses the host control plane and a session namespace role. In vCluster mode, each started session gets a virtual Kubernetes control plane. Its workloads still use host-cluster nodes and remain subject to host policies.

Use `spec.security` to select the Pod security level, Kubernetes token access, namespace role, and external egress. Omitted fields use `EnvironmentConfig.data.defaults.security`, then provider defaults. Configure the host's admission policies and resource limits separately.

## Network access

Allow the connections that session code needs, such as HTTPS to a data provider or access to platform storage. The network plugin must enforce Kubernetes NetworkPolicy. Policies add their allowed connections together.

| Generated policy | Created when | Allows |
| --- | --- | --- |
| `deny-egress` | By default | No outbound traffic on its own. |
| `allow-namespace-egress` | By default | Pods in the same runtime namespace. |
| `allow-vcluster-egress` | vCluster is enabled | The session's virtual API. |
| `allow-dns-egress` | External egress, vCluster, or Data is enabled | Cluster DNS. |
| `allow-external-egress` | External egress is enabled and external CIDRs are set | The configured external CIDRs, with exclusions. |
| `allow-internal-egress` | Valid `network.internalEgress` entries exist | Selected Pods and ports in other namespaces. |

The per-Datalab `spec.security.externalEgress` setting overrides the environment default. An empty external CIDR list creates no broad external allow rule.

Set the cluster Service and Pod CIDRs and any blocked ranges in the EnvironmentConfig. The provider excludes them from broad external rules. Use `network.internalEgress` for selected storage, identity, and other platform services.

`network.excludePolicies` can omit generated policies by name. Data services also have their own policies. Check the policies actually installed in each namespace when testing a connection.

## Data and public routes

Use a permanent Data address for downloads that must stay available when a compute session stops. `spec.data.enabled` defaults to `true` and cannot change after Datalab creation. Set it when creating the resource. `spec.data.readOnlyMount` controls Data browser permissions; storage IAM still controls object access. The optional Data S3 endpoint is always read only.

Manage public routes in the host cluster. For a permanent Data address, the public load balancer must reach the selected Gateway listener, and that listener must terminate TLS. Storage can be ready before the Data workload and its route are ready.

See [installation](../getting-started/installation.md#example-values) for routing values and [IAM integration](iam-integration.md#route-protection) for authentication.

## Persistent data

Session files use PVCs; datasets use object storage; managed stores have their own volumes. Stopping a session keeps its home volume. See [Operations](https://eoepca.readthedocs.io/projects/operations/) for backups, retention, host security, and platform recovery.
