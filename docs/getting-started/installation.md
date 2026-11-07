# Configure Workspace

Follow the component guides for installation. The [EOEPCA+ deployment][deployment] links below use a fixed revision with the configuration examples.

## Components

| Component and installation guide | Purpose | Documented version requirement |
| --- | --- | --- |
| [Kubernetes](https://kubernetes.io/docs/setup/) | Runs controllers and workloads. Needs NetworkPolicy enforcement and persistent volumes. | No Workspace minimum stated. Educates 3.8 bundles clients for [1.33–1.36][educates-versions]. |
| [Ingress controller (APISIX)](https://apisix.apache.org/docs/ingress-controller/getting-started/) | Routes sessions; needs WebSockets, wildcard DNS, and TLS. | No minimum stated; see the [runtime requirements][cluster-requirements]. |
| [Gateway API controller (Envoy Gateway)](https://gateway.envoyproxy.io/docs/tasks/quickstart/) | Routes Data when using HTTPRoute; see the [deployment][gateway]. | HTTPRoute with cross-namespace routes; header regular expressions for S3. External PostgreSQL needs TLSRoute `v1`. |
| [Crossplane](https://docs.crossplane.io/latest/get-started/install/) | Reconciles Storage and Datalab resources. | [`>= 2.0, < 3.0`][crossplane-range]. |
| [Keycloak](https://www.keycloak.org/guides) | Manages workspace identities, groups, roles, and OAuth clients. | [26.2 or later][keycloak-exchange] for standard token exchange; no provisioning minimum stated. |
| [Educates](https://docs.educates.dev/en/stable/installation-guides/installation-instructions.html) | Provides browser sessions, terminals, and editors. The notebooks use workspace vClusters instead. | [Pinned to 3.8.0][dependency-input]; no minimum stated. |
| [Kyverno](https://kyverno.io/docs/installation/) | Enforces the selected Educates security policies. | [Bundled policies][educates-base] require 1.11.0 or later. Extra platform policies can require newer versions. |
| [S3-compatible object storage][storage-guide] | Stores workspace data. | Backend supported by Provider Storage; no common minimum stated. |
| [Provider Storage][storage-guide] | Creates buckets, storage identities, grants, and credential Secrets. | [`>= 0.4.0`][api-requirements] for the current Workspace API. |
| [Provider Datalab][datalab-guide] | Creates membership, Data services, workspace vClusters, browser sessions, and managed services. | Documented API requirement: [`>= 0.12.0`][api-requirements]. This demo was checked with `0.12.0-rc.8`. |
| [rm-workspace-api][api-setup] | Optional Workspace management UI, HTTP API, and token exchange. | No minimum stated; see the deployment's [image tag][api-deployment]. |
| [Managed-store operators][datalab-guide] | Optional PostgreSQL, MongoDB, and Redis services. | See the provider guide's tested operator pins for enabled stores. |
| [CNCF Distribution](https://distribution.github.io/distribution/about/deploying/) | The registration notebook deploys its OCI registry inside the workspace vCluster. | No minimum stated. The [example manifest](register-stac-metadata/08-registry.yaml) pins 3.1.2 by digest. |

Install provider and function dependencies, namespaced ProviderConfigs, and RBAC through the provider guides. Pins and tested versions do not establish minimum versions.

Without `rm-workspace-api`, create `Storage` and `Datalab` resources through Kubernetes or GitOps. You then have no Workspace management UI, Workspace HTTP API, or Workspace token-exchange endpoint. The notebook quickstart needs the API.

## 1. Set the environment

Adapt the deployment's [pipeline values][pipeline-values]: IAM URLs and realm, storage endpoint, ingress domain and certificate, Gateway listeners, and Pod and Service network ranges. For browser sessions, keep the [Educates ingress values][runtime-values] consistent. The [provider guide][datalab-guide] lists fields and defaults.

The `workspace-pipeline` chart installs the configuration packages and creates the EnvironmentConfig. It copies `environmentconfig` into `EnvironmentConfig.data`, except for `name` and `annotations`. The example's prerelease package overrides differ from the [chart defaults][pipeline-defaults]. Keep exact pins in your deployment.

The example uses the EnvironmentConfig name `datalab`. Select it on each resource with an annotation or label:

| Resource | Key | Value |
| --- | --- | --- |
| Storage | `storages.pkg.internal/environment` | `datalab` |
| Datalab | `datalabs.pkg.internal/environment` | `datalab` |

For resources created by Workspace API, set `PROVIDER_ENVIRONMENT=datalab`.

## 2. Create a workspace

With Workspace API, configure its [deployment][api-deployment] and [accounts and roles](https://github.com/EOEPCA/workspace/tree/main/setup), then run [Workspace Management](../workspace-management.ipynb). It creates a workspace and waits for storage, Data, the virtual cluster, and the managed registry.

For direct Kubernetes use, save the provider's [Storage example][storage-example] as `storage.yaml` and [Datalab example][datalab-example] as `datalab.yaml`. Adapt them before applying:

1. Use `ws-example` for both resource names and the Storage principal, in namespace `workspace`. Choose a unique bucket name. Remove sample bucket access requests and grants.
2. Set both environment selectors from the table above. Select the storage backend with `spec.crossplane.compositionSelector.matchLabels.provider`, for example `minio`.
3. Set the EnvironmentConfig's `storage.secretNamespace` to `workspace`. Storage creates a Secret named after its principal; Datalab reads it using its resource name.
4. Set an existing Keycloak username in `spec.users`. For the STAC notebooks, use the `spec.vclusters` configuration from [the workspace example](https://github.com/EOEPCA/workspace/blob/main/setup/examples.yaml). Omit `spec.sessions` unless you need browser sessions.

```bash
kubectl apply -n workspace -f storage.yaml
kubectl wait -n workspace --for=condition=Ready storage/ws-example --timeout=300s
kubectl apply -n workspace -f datalab.yaml
kubectl wait -n workspace --for=condition=Ready datalab/ws-example --timeout=300s
kubectl get storages,datalabs -n workspace
```

## 3. Use the workspace

With Workspace API, continue with the [quickstart](quickstart.md). The [notebook guide](../usage/notebook-guide.md) lists services needed for each example. For direct Kubernetes use, check Datalab status for service and session addresses.

[deployment]: https://github.com/EOEPCA/eoepca-plus/tree/ae95041d7ab18e54fce4bf28691cfbe5c0f35b7c/argocd/eoepca/workspace
[pipeline-values]: https://github.com/EOEPCA/eoepca-plus/blob/ae95041d7ab18e54fce4bf28691cfbe5c0f35b7c/argocd/eoepca/workspace/parts/app-workspace-pipeline.yaml
[runtime-values]: https://github.com/EOEPCA/eoepca-plus/blob/ae95041d7ab18e54fce4bf28691cfbe5c0f35b7c/argocd/eoepca/workspace/parts/app-workspace-dependencies.yaml
[api-deployment]: https://github.com/EOEPCA/eoepca-plus/blob/ae95041d7ab18e54fce4bf28691cfbe5c0f35b7c/argocd/eoepca/workspace/parts/app-workspace-api.yaml
[gateway]: https://github.com/EOEPCA/eoepca-plus/tree/ae95041d7ab18e54fce4bf28691cfbe5c0f35b7c/argocd/infra/gateway
[cluster-requirements]: https://docs.educates.dev/en/stable/installation-guides/cluster-requirements.html
[educates-versions]: https://github.com/educates/educates-training-platform/blob/3.8.0/project-docs/release-notes/version-3.8.0.md
[educates-base]: https://github.com/versioneer-tech/bases/blob/4e29af2ee9f3/educates/default/manifest.yaml
[crossplane-range]: https://github.com/versioneer-tech/provider-datalab/blob/0.12.0-rc.8/crossplane.yaml
[keycloak-exchange]: https://www.keycloak.org/2025/04/keycloak-2620-released
[storage-guide]: https://provider-storage.versioneer.at/latest/how-to-guides/installation/
[datalab-guide]: https://github.com/versioneer-tech/provider-datalab/blob/0.12.0-rc.8/docs/how-to-guides/installation.md
[api-requirements]: https://github.com/EOEPCA/rm-workspace-api#set-up-workspace-api
[api-setup]: https://github.com/EOEPCA/rm-workspace-api/blob/main/docs/setup.md
[storage-example]: https://github.com/versioneer-tech/provider-storage/blob/0.4.0/examples/base/001-buckets.yaml
[datalab-example]: https://github.com/versioneer-tech/provider-datalab/blob/0.12.0-rc.8/examples/base/001-lab.yaml
[dependency-input]: https://github.com/EOEPCA/workspace/blob/main/dependencies/input.yaml
[pipeline-defaults]: https://github.com/EOEPCA/workspace/blob/main/pipeline/values.yaml
