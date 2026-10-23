# Operational controls

## Sessions

In `Auto` mode, sessions start on demand and background jobs stop them when inactive. `AlwaysOn` keeps sessions running. Sessions can also be disabled.

Files on persistent volumes and data in object storage remain after a session stops. Choose the inactivity criteria and storage sizes for the work the team needs to run.

## Kubernetes access

Namespace mode uses the host cluster's control plane. RBAC and namespace policies limit the user's access.

In vCluster mode, each started session gets its own Kubernetes control plane. Include its CPU, memory, and state volume when sizing the host cluster.

Use RBAC to limit which resources users can create. Admission policies can block privileged Pods and `hostPath` volumes. `LimitRange` and `ResourceQuota` set namespace limits.

The generated admission policies need Kyverno. See the provider's [sandbox controls](https://provider-datalab.versioneer.at/latest/security/sandbox-controls/) for the policy definitions.

## Network access

The cluster network plugin must enforce Kubernetes NetworkPolicy. A connection is allowed if any policy permits it.

| Policy | Created when | Purpose |
| --- | --- | --- |
| `deny-egress` | Always | Deny outbound traffic unless another policy allows it. |
| `allow-namespace-egress` | Always | Allow traffic within the namespace. |
| `allow-internal-egress` | `network.internalEgress` has entries | Allow selected services in other namespaces. |
| `allow-dns-egress` | `defaults.security.externalEgress` is enabled | Allow DNS traffic under the configured rules. |
| `allow-external-egress` | `defaults.security.externalEgress` is enabled | Allow the configured external CIDRs. |

Use `network.internalEgress` for exceptions to selected services in other namespaces. Each entry needs a namespace, Pod selector, and ports.

Set external CIDRs and exclusions in the EnvironmentConfig. Exclude the cluster Service and Pod CIDRs from broad external rules.

The provider-datalab [installation guide](https://provider-datalab.versioneer.at/latest/how-to-guides/installation/) describes the generated rules.

## Ingress

Manage public routes in the host cluster, including routes to vCluster services. Configure Gateway listeners in the [installation values](../getting-started/installation.md#example-values) and route authentication as described in [IAM integration](iam-integration.md#route-protection).

## Persistent data

Use persistent volumes for session files and vCluster state. Shared volumes need the configured access mode, such as `ReadWriteMany`. Back up session volumes, object storage, and databases according to their retention requirements.
