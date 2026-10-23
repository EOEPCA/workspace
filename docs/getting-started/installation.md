# Install and configure Workspace

The Helm charts are available in [GitHub Packages](https://github.com/orgs/EOEPCA/packages?tab=packages&q=workspace).

## Prerequisites

Install Crossplane v2 and the providers and functions required by your Storage and Datalab packages first. The pipeline chart uses `skipDependencyResolution: true`; it does not install package dependencies.

Install Kyverno and use a network plugin that enforces `NetworkPolicy`. See [operational controls](../design/operational-controls.md) for the runtime limits.

## Workspace settings

| Key | Type | Description |
|-----|------|-------------|
| `clusterIngressDomain` | string | Base domain for workspace sessions, for example `ngx.develop.eoepca.org`. |
| `clusterIngressClass` | string | workspace session ingress class, for example `nginx`. |
| `tlsCertificateRef.name` | string | Name of the TLS secret used for workspace session ingress. |
| `tlsCertificateRef.namespace` | string | Namespace of the TLS secret, for example `workspace`. |

## Pipeline settings

The chart defaults to Provider Datalab `0.11.0` and Provider Storage `0.4.0`.
Use `datalab.package` and `storage.package` to select other package tags.

| Key | Type | Description |
|-----|------|-------------|
| `environmentconfig.name` | string | EnvironmentConfig name for Storage and Datalab resources. Default: `datalab`. |
| `environmentconfig.iam.realm` | string | Keycloak realm name for Workspace authentication. |
| `environmentconfig.iam.namespace` | string | Keycloak namespace for the Data endpoint's OAuth proxy. Provider default: `keycloak`. |
| `environmentconfig.iam.issuerURL` | string | Public Keycloak realm URL for login. |
| `environmentconfig.iam.internalURL` | string | Keycloak realm URL reachable from the cluster. |
| `environmentconfig.iam.extraAudiences` | array | Extra token audiences for generated workspace clients, for example `workspace-api`. |
| `environmentconfig.ingress.enabled` | bool | Keep `false` for Gateway routing. Default: `false`. |
| `environmentconfig.ingress.domain` | string | Base domain for Workspace UIs and services. |
| `environmentconfig.httpRoute.enabled` | bool | Create Data HTTPRoutes. Default: `true`. |
| `environmentconfig.httpRoute.enableS3` | bool | Enable the experimental S3 read endpoint on the Data hostname. Requires `httpRoute.enabled`. Default: `false`. |
| `environmentconfig.httpRoute.parentName` | string | Gateway name for the Data HTTPRoutes. |
| `environmentconfig.httpRoute.parentNamespace` | string | Namespace of that Gateway. |
| `environmentconfig.httpRoute.sectionName` | string | HTTPS listener that terminates TLS for Data HTTPRoutes. |
| `environmentconfig.httpRoute.httpSectionName` | string | HTTP listener for the HTTPS redirect route. |
| `environmentconfig.storage.endpoint` | string | S3 endpoint, for example `https://minio.develop.eoepca.org`. |
| `environmentconfig.storage.forcePathStyle` | bool | Use path-style S3 addresses. Default: `true`. Rendered as `data.storage.forcePathStyle`. |
| `environmentconfig.storage.provider` | string | Storage provider label, for example `MinIO`, `AWS`, or `Other`. |
| `environmentconfig.storage.region` | string | Storage region. |
| `environmentconfig.storage.secretNamespace` | string | Namespace where Datalabs read storage credential Secrets. |
| `environmentconfig.storage.type` | string | Storage type (`s3`). |
| `environmentconfig.storage.lifecycle.schedule` | string | Cron schedule for storage lifecycle jobs. Provider default: `17 2 * * *`. |
| `environmentconfig.storageClasses.allowed` | array | Allowed StorageClasses for Datalab session PVCs. Empty allows any requested class. |
| `environmentconfig.network.externalEgressCIDRs` | array | Allowed external CIDRs for Datalab sessions. See the example below. |
| `environmentconfig.network.internalEgress` | array | Namespaces, Pod selectors, and ports that Datalab workloads can reach. |
| `environmentconfig.network.serviceCIDR` | string | Cluster Service CIDR to exclude from external egress. |
| `environmentconfig.network.podCIDRs` | array | Cluster Pod CIDRs. |
| `environmentconfig.network.blacklistIPs` | array | CIDRs excluded from generated external egress, for example metadata endpoints. |
| `environmentconfig.network.excludePolicies` | array | Generated NetworkPolicy names to skip. |
| `environmentconfig.packages` | array | Extension packages for workspace sessions. |
| `environmentconfig.defaults.quota.memory` | string | Default session memory quota. Provider default: `2Gi`. |
| `environmentconfig.defaults.quota.storage` | string | Default session PVC size. Provider default: `1Gi`. |
| `environmentconfig.defaults.quota.budget` | string | Default resource budget, such as `small`, `medium`, or `large`. Provider default: `medium`. |
| `environmentconfig.defaults.overallQuota.storage` | string | Total requested PVC storage per Datalab environment namespace. Provider default: `100Gi`. |
| `environmentconfig.defaults.security.policy` | string | Default Pod Security Standard level for Datalab sessions (`restricted`, `baseline`, or `privileged`). Default: `baseline`. |
| `environmentconfig.defaults.security.kubernetesAccess` | bool | Give sessions Kubernetes API access. Default: `true`. |
| `environmentconfig.defaults.security.kubernetesRole` | string | Default session namespace RBAC role (`admin`, `edit`, or `view`). Default: `edit`. |
| `environmentconfig.defaults.security.externalEgress` | bool | Allow sessions to use the configured external egress rules. |
| `environmentconfig.database.tlsRoute.parentName` | string | Gateway name for the optional PostgreSQL `TLSRoute`. |
| `environmentconfig.database.tlsRoute.parentNamespace` | string | Namespace of that Gateway. |
| `environmentconfig.database.tlsRoute.sectionName` | string | Gateway listener for PostgreSQL TLS passthrough. |
| `environmentconfig.database.storageClassName` | string | PostgreSQL volume StorageClass. Empty uses the cluster default. |
| `environmentconfig.database.backupStorageClassName` | string | Backup StorageClass, where the PostgreSQL operator supports it. Empty uses the cluster default. |
| `environmentconfig.mongodb.storageClassName` | string | MongoDB StorageClass. Empty uses the cluster default. |
| `environmentconfig.redis.storageClassName` | string | Redis StorageClass. Empty uses the cluster default. |
| `environmentconfig.qdrant.storageClassName` | string | Qdrant StorageClass. Empty uses the cluster default. |

The chart creates one EnvironmentConfig, named `datalab` by default. Set
`storages.pkg.internal/environment: datalab` on Storage resources that share it,
as in the [example manifests](https://github.com/EOEPCA/workspace/blob/main/setup/examples.yaml). Without this label or annotation, the MinIO
composition selects an EnvironmentConfig named `storage`. The corresponding
Datalab key is `datalabs.pkg.internal/environment`.

## Example values

Use a Gateway with HTTP and HTTPS listeners, a certificate, and permission to accept routes from the Datalab runtime namespaces. The HTTPS listener must terminate TLS. Set its listener names and the IAM URLs below. Workspace session ingress has separate settings.

```yaml
environmentconfig:
  iam:
    realm: eoepca
    namespace: iam
    issuerURL: https://identity.example.org/realms/eoepca
    internalURL: http://keycloak-service.iam.svc/realms/eoepca
    extraAudiences:
      - workspace-api
  ingress:
    enabled: false
    domain: lab.example.org
  httpRoute:
    enabled: true
    enableS3: false
    parentName: public
    parentNamespace: gateway
    sectionName: workspaces-https
    httpSectionName: http
  # Optional listener for external PostgreSQL access.
  database:
    tlsRoute:
      parentName: public
      parentNamespace: gateway
      sectionName: postgres
  storage:
    endpoint: https://s3.example.org
    forcePathStyle: true
    provider: Other
    region: eoepca
    secretNamespace: workspace
    type: s3
  storageClasses:
    allowed:
      - fast-rwx
      - standard-rwx
  network:
    # Allow external IPv4 and IPv6 traffic when externalEgress is enabled.
    externalEgressCIDRs:
      - 0.0.0.0/0
      - ::/0
    # Allow access to this service in another namespace.
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

For external PostgreSQL access, `database.tlsRoute` selects a separate TLS passthrough listener. The Gateway controller must support `TLSRoute` v1.

Set `httpRoute.enableS3: true` to enable S3 reads for every Data-enabled Datalab in the environment. There is no per-Datalab override. This option needs a Gateway controller that supports HTTPRoute header regular expressions.

Allow Gateway traffic into the runtime namespace and access from the Data services to storage and Keycloak. See [network access](../design/operational-controls.md#network-access) for the egress rules.
