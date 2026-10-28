# Install and configure Workspace

Set up the shared services so teams can create workspaces, store data, and open sessions. Install the runtime, provider dependencies, composition packages, and API in that order. Use your platform's GitOps process for a shared cluster.

## Prerequisites

The platform needs Crossplane v2, Keycloak, object storage, an ingress controller, and a network plugin that enforces NetworkPolicy. Install the providers, functions, namespaced ProviderConfigs, and RBAC required by the selected Storage and Datalab packages.

Install Educates before creating Datalabs. The selected Educates base or ingress policies can also require Kyverno. Provider Datalab passes security settings to Educates; it does not create a complete host security policy.

Optional PostgreSQL, MongoDB, Redis, and Qdrant stores need their operators installed first. The [Provider Datalab installation guide](https://github.com/versioneer-tech/provider-datalab/blob/main/docs/how-to-guides/installation.md) lists these dependencies.

## Charts and API

This repository publishes charts in [GitHub Packages](https://github.com/orgs/EOEPCA/packages?tab=packages&q=workspace):

| Component | What it installs |
| --- | --- |
| Educates dependency chart | The session runtime. Its input is `dependencies/input.yaml`. |
| `workspace-pipeline` | The Storage and Datalab configuration packages and one EnvironmentConfig. |

Deploy the Workspace API and UI separately. Their [source repository](https://github.com/EOEPCA/rm-workspace-api/) describes API configuration.

The pipeline uses `skipDependencyResolution: true`. It does not install the packages' providers or functions. Check the exact package pins in `pipeline/values.yaml`; set `storage.package` and `datalab.package` to change them. A deployed environment can use different pins from this checkout.

From this checkout, save the values below as `workspace-values.yaml`, replace the example domains and network ranges, then install the pipeline:

```bash
helm upgrade --install workspace-pipeline ./pipeline \
  --namespace workspace --create-namespace \
  --values workspace-values.yaml
```

Check package health before creating a workspace:

```bash
kubectl get configurations.pkg.crossplane.io
kubectl get providers.pkg.crossplane.io
kubectl get functions.pkg.crossplane.io
```

## Educates runtime values

Educates provides the sessions that users open from their dashboard. These values configure its dependency chart. Set the same domain, ingress class, and certificate in the Datalab environment configuration so session links reach the correct runtime.

| Key | Purpose |
| --- | --- |
| `clusterIngressDomain` | Session domain, such as `lab.example.org`. |
| `clusterIngressClass` | Session ingress controller, such as `apisix` or `nginx`. |
| `tlsCertificateRef.name` | TLS Secret used for session hosts. |
| `tlsCertificateRef.namespace` | Namespace containing that TLS Secret. |

## Pipeline environment values

Use these values to give workspaces a common storage service, login system, network policy, and set of resource defaults. The keys are under `environmentconfig` in Helm values. The chart writes them into `EnvironmentConfig.data`. Empty default fields leave the provider to choose its fallback. The Datalab resource can override session resource and security defaults.

### Identity and routing

| Key | Purpose |
| --- | --- |
| `name` | EnvironmentConfig name. Chart default: `datalab`. |
| `iam.realm` | Keycloak realm. |
| `iam.namespace` | Keycloak namespace. |
| `iam.issuerURL` | Public realm URL used for login. |
| `iam.internalURL` | Realm URL reachable from the cluster. |
| `iam.extraAudiences` | Extra audiences for generated workspace-client tokens, such as `workspace-api`. |
| `ingress.enabled` | Use an Ingress for permanent Data access. Chart default: `false`. |
| `ingress.class`, `ingress.domain`, `ingress.secret` | Ingress controller, workspace domain, and TLS Secret name. The domain is also used by Data HTTPRoutes. |
| `ingress.annotations` | Ingress controller settings. |
| `httpRoute.enabled` | Use Gateway API for permanent Data access. Chart default: `true`. |
| `httpRoute.enableS3` | Enable experimental S3 reads. Chart default: `false`. Requires HTTPRoute access. |
| `httpRoute.parentName`, `httpRoute.parentNamespace` | Gateway name and namespace. |
| `httpRoute.sectionName` | HTTPS listener that terminates TLS for Data. |
| `httpRoute.httpSectionName` | HTTP listener for the HTTPS redirect route. |

For a permanent Data address, enable exactly one of `ingress.enabled` and `httpRoute.enabled`. With both disabled, Data uses session ingress. Enabling both stops reconciliation. The public load balancer must send traffic to the selected controller or Gateway.

### Storage and services

| Key | Purpose |
| --- | --- |
| `storage.endpoint`, `storage.region` | Backing S3 endpoint and region. |
| `storage.forcePathStyle` | Path-style S3 addresses. Chart default: `true`; written as a string for the provider. |
| `storage.provider`, `storage.type` | Storage provider label and type. Type defaults to `s3`. |
| `storage.secretNamespace` | Namespace where Datalabs read their input storage Secrets. |
| `storage.lifecycle.schedule` | Storage lifecycle-job cron schedule. Provider fallback: `17 2 * * *`. |
| `storageClasses.allowed` | Session PVC classes. An unlisted requested class falls back to the first entry. An empty list allows the requested or cluster default class. |
| `database.storageClassName`, `database.backupStorageClassName` | PostgreSQL data and backup classes, where supported by its operator. |
| `database.tlsRoute.parentName`, `database.tlsRoute.parentNamespace`, `database.tlsRoute.sectionName` | Gateway listener for optional external PostgreSQL access. |
| `mongodb.storageClassName`, `redis.storageClassName`, `qdrant.storageClassName` | Managed-store volume classes. Empty uses the cluster default. |
| `packages` | Extension packages for sessions. |

### Resources and network

| Key | Purpose |
| --- | --- |
| `defaults.quota.memory` | Session memory. Provider fallback: `2Gi`. |
| `defaults.quota.storage` | Session home-volume size. Provider fallback: `1Gi`. |
| `defaults.quota.budget` | Educates resource budget. Provider fallback: `medium`. |
| `defaults.overallQuota.storage` | Total PVC requests in the Datalab environment namespace. Provider fallback: `100Gi`. |
| `defaults.security.policy` | Pod security level: `restricted`, `baseline`, or `privileged`. Provider fallback: `baseline`. |
| `defaults.security.kubernetesAccess` | Supply a Kubernetes service account token. Provider fallback: `true`. |
| `defaults.security.kubernetesRole` | Namespace role: `view`, `edit`, or `admin`. Provider fallback: `edit`. |
| `defaults.security.externalEgress` | Enable the configured external rules. Provider fallback: `true`. |
| `network.externalEgressCIDRs` | External ranges allowed when external egress is enabled. An empty list creates no broad external allow rule. |
| `network.internalEgress` | Allowed namespaces, Pod selectors, and ports for internal services. |
| `network.internalIngress` | Allowed source namespaces, Pod selectors, and destination ports. Use `targetPodSelector` to select destination Pods. |
| `network.serviceCIDR`, `network.podCIDRs` | Cluster address ranges excluded from broad external rules. |
| `network.blacklistIPs` | Other ranges excluded from broad external rules, such as metadata endpoints. |
| `network.excludePolicies` | Generated NetworkPolicy names to omit. |

See [operational controls](../design/operational-controls.md) for how these settings affect sessions and Data.

## Example values

This example uses Gateway API for Data. Its HTTPS listener needs a certificate for `*.lab.example.org` and must accept routes from Datalab runtime namespaces. S3 reads also need support for HTTPRoute header regular expressions.

```yaml
environmentconfig:
  name: datalab
  iam:
    realm: eoepca
    namespace: iam
    issuerURL: https://identity.example.org/realms/eoepca
    internalURL: http://keycloak-service.iam.svc/realms/eoepca
    extraAudiences:
      - workspace-api
  ingress:
    enabled: false
    class: apisix
    domain: lab.example.org
    secret: workspace-tls
  httpRoute:
    enabled: true
    enableS3: true
    parentName: public
    parentNamespace: gateway
    sectionName: workspaces-https
    httpSectionName: http
  storage:
    endpoint: https://s3.example.org
    forcePathStyle: true
    provider: Other
    region: us-east-1
    secretNamespace: workspace
    type: s3
  network:
    externalEgressCIDRs:
      - 0.0.0.0/0
      - ::/0
    internalEgress:
      - namespace: platform-services
        podSelector:
          matchLabels:
            app: artifact-proxy
        ports:
          - protocol: TCP
            port: 443
    serviceCIDR: 10.43.0.0/16
    podCIDRs:
      - 10.42.0.0/16
    blacklistIPs:
      - 169.254.169.254/32
      - fd00:ec2::254/128
  defaults:
    overallQuota:
      storage: 100Gi
    security:
      policy: baseline
      kubernetesAccess: true
      kubernetesRole: edit
      externalEgress: true
```

`httpRoute.enableS3` applies to all Data-enabled Datalabs in this environment. There is no per-Datalab S3 override. It controls the read-only Data endpoint; backing storage retains its own permissions.

For external PostgreSQL, configure a separate TLS-passthrough listener through `database.tlsRoute`. The Gateway controller must serve `TLSRoute` v1 and support direct PostgreSQL TLS with SNI.

## Select the environment

The chart creates one EnvironmentConfig named `datalab` by default. A manually created Storage resource can select it with:

```yaml
metadata:
  labels:
    storages.pkg.internal/environment: datalab
```

Without an environment annotation or label, the MinIO composition selects `storage`. The Datalab key is `datalabs.pkg.internal/environment`. The Workspace API uses its `PROVIDER_ENVIRONMENT` setting for resources it creates; its default is `datalab`.

## Verify the user path

Run the examples to check that users can reach the services you installed. [Workspace Management](../workspace-management.ipynb) creates a test workspace and checks storage and Data separately. This catches a workspace whose storage is ready but whose public address is not.

Use [Vienna](vienna-imagery-with-stac-and-s3.ipynb) to check public downloads and authenticated S3 access. Use [STAC registration](register-stac-metadata.ipynb) to check service-account uploads, registry transfers, and STAC APIs in a session vCluster.
