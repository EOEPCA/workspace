# Install and configure Workspace

Set up the shared services so teams can create workspaces, store data, and open sessions. Install the runtime, provider dependencies, composition packages, and API in that order. Use your platform's GitOps process for a shared cluster.

## Prerequisites

The platform needs Crossplane v2, Keycloak, object storage, an ingress controller, and a network plugin that enforces NetworkPolicy. Install the providers, functions, namespaced ProviderConfigs, and RBAC required by the selected Storage and Datalab packages.

Install Educates before creating Datalabs. The selected Educates base or ingress policies can also require Kyverno. Provider Datalab passes security settings to Educates; it does not create a complete host security policy.

Optional PostgreSQL, MongoDB, Redis, and Qdrant stores need their operators installed first. The [Provider Datalab installation guide](https://provider-datalab.versioneer.at/latest/how-to-guides/installation/) lists these dependencies and the environment settings.

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

Set cluster values and overrides under `environmentconfig`. The chart copies all keys except `name` and `annotations` directly into `EnvironmentConfig.data`. Existing paths such as `environmentconfig.iam.realm` stay the same. New provider fields need no chart change. The [Provider Datalab installation guide](https://provider-datalab.versioneer.at/latest/how-to-guides/installation/) lists all EnvironmentConfig values and defaults.

| Chart key | Purpose |
| --- | --- |
| `environmentconfig.name` | EnvironmentConfig name. Default: `datalab`. |
| `environmentconfig.annotations` | Annotations on the EnvironmentConfig resource. |
| `globalAnnotations` | Annotations shared by the chart resources. |

Use the provider guide above for field names and defaults. Omit a field to use its provider default. The chart preserves YAML types, explicit `false` values, and empty lists. Use the type required by the provider, such as `storage.forcePathStyle: "true"`.

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
    forcePathStyle: "true"
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
```

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
