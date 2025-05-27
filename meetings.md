# Agenda 20250513 & 20250527

- modularize workspace pipelines (=Crossplane compositions) for flexible setup  
  - avoid installing unnecessary providers, e.g. only install MinIO provider when MinIO is in use  
  - support minimal setups like Crossplane&Keycloak-only without storage&workspace components

- introduce environment abstraction using Crossplane's `EnvironmentConfig` CRD
  - simplify bridging differences between test/prod instances (e.g. Urls)

- enable deployments on multiple clusters without code duplication  
  - EOEPCA demo cluster: with MinIO and vCluster
  - Terrabyte setup: with Quobyte and vCluster

for corresponding links see https://github.com/EOEPCA/workspace/issues/55#issuecomment-2911260992

# Agenda 20250401

- support(reenable) both API as well as browser-based UI access to workspace-api endpoint
- demonstrate usage of vcluster for workloads like mlflow or vs-code-server
- vcluster hibernation mode (https://github.com/EOEPCA/workspace/issues/31)
- UI support for memember management (https://github.com/EOEPCA/workspace/issues/35)
- separate meeting to align workspace and perhaps vcluster integration with other BBs

# Agenda 20250318

- dynamic retrieval of vcluster KUBECONFIG via workspace-api endpoint (https://github.com/EOEPCA/workspace/issues/41)

# Agenda 20250304

- the EOEPCA IAM concept made Git (for static setup) resp. Kubernetes (for dynamic use-cases like workspace provisioning) the source of truth for many IAM entities (groups, clients, memberships, roles...), i.e. Keycloak functionality "sits" on top of derived state

- as first step the Workspace-UI got connected with Kubernetes to retrieve groups & memberships as well as to update memberships, still WIP as UI functionality is missing yet but Workspace-UI CLI allows to demonstrate:
  - Allow workspace owner to add additional users to a teams workspace via API (https://github.com/EOEPCA/workspace/issues/35)
  - Allow a user in Workspace UI to share data with other explicitly selected platform groups (as stored in Keycloak) (https://github.com/EOEPCA/workspace/issues/36)

# Agenda 20250218

- demo support for "stable listing of shared item", i.e. creation of a package where file index is separately stored

# Agenda 20250204

- demo IAM integration established for Workspace UI & Storage Layer (in addition to the already existing integration in the Workspace API), see
https://eoepca.readthedocs.io/projects/workspace/en/latest/design/iam-concept/
- started to align K8s <-> Keyloak reconciliation mechanism for general operator setup https://github.com/EOEPCA/workspace/issues/44


# Agenda 20250115

Demo
- notebook [Workspace Management demo](https://github.com/EOEPCA/demo/blob/main/demoroot/notebooks/05%20Workspace%20Management.ipynb)
- options to inspect/manage provisioned workspaces (Kubernetes API, Kubernetes Dashboard, Workspace-API)
- share data on versioned bucket

# Agenda 20241210

aligned with IAM BB on various authn/authz related topics
- agreed on user <-> team=project association and implemented via keycloak users and groups
- protected team-specific HTTP path routes on central workspace-api (ongoing)

note: similar logic to be implemented for data-access and registration components based on HTTP method (ongoing)

- automated process of keycloak group, membership, openid-client,... creation
- enabled ownership definition for team during workspace creation
- secured access to workspace-ui deployments via dedicated apisixroute enforcing team association (ongoing)

# Agenda 20241126

- showcased package creation in workspace-ui for sharing subsets of data
- explained authn/authz roadmap after first alignments with IAM BB

# Agenda 20241029

- closing multi source management (i.e. which buckets are connected to a workspace) -> now possible via K8s (GitOps, new workspace provisioning pipelines), via Workspace storage layer API and visually via UI

- internal discussions on IAM concept (details shared on EOEPCA slack)

> [!Note]
> Upcoming:
> - document storage layer API flows to curate and share data, publish openapi spec
> - visualize details on connected bucket (incl. status)

# Agenda 20241001

- trimmed down workspace-api for v2.0, see Compatibility matrix (https://github.com/EOEPCA/workspace/issues/24)

- clean deployments of workspace components to follow, there will be one global Workspace UI for demonstration and each user/team will have its own dedicated Workspace UI

- present slides and sketch demo for Q2/2024 review, Q3/2024 outlook

# Agenda 20240917

- aligned on process how CRDs can be rolled out on cluster by making them part of ArgoCD deployment

- pipeline adapted to rollout latest version of Workspace UI with all connected buckets to a workspace

> [!Note]
> Upcoming:
> - link external buckets via Storage Layer API (and subsequently expose capabilities in Workspace UI)
> - Storage Layer API endpoint documentation

# Agenda 20240903

## Workspace Concepts and API Interfaces

3 CRDs to express desired state got introduced as API contracts by the Workspace BB

> [!Note] 
> Internally more CRDs are used and will get deployed on the Kubernetes cluster based on the configured reconciliation pipelines, e.g. the Minio Bucket CRD

1) Workspace CRD (https://github.com/EOEPCA/workspace/issues/1)

- used by the Platform Operator to provision and manage runtime and storage infrastructure (incl. quotas) as well as install higher level tooling (API services, UI applications,...)

- exposes a K8s kube-context as K8s secret to be picked up directly by the end-user or indirectly by installed tooling

2) Storage CRD (https://github.com/EOEPCA/workspace/issues/3)

- used by the Workspace reconciliation pipeline internally to provision buckets

- exposes bucket details and credentials as K8s secret to be used internally but also may be used within EOEPCA context by other tooling or the end-user 

3) Source CRD (https://github.com/EOEPCA/workspace/issues/9)

- used by the Storage Layer API in the Workspace UI to show connected buckets

- exposes a secret name providing url and credentials to access the shared objects

## Workspace UI

the Workspace UI got extended to support browsing of multiple buckets as well as to get the necessary connection information directly from K8s

> [!Note]
> Upcoming:
> - update deployments to leverage above Sources exposed via K8s -> https://github.com/EOEPCA/workspace/issues/9

# Agenda 20240806

## Workspace & Storage Provisioning

an adaptable, configurable pipeline=workflow for provisioning is a **must**, because
- platform infrastructure is different: AWS vs CloudFerro vs ... for cloud infrastructure, AWS S3 vs Minio vs ... for object storage, ...
- platform setup is different: one bucket or multiple buckets, allow to link additional buckets or now, ...
- platform operator business model is different: commercial subscription plans, free trials, ...
- platform tooling is different: expose infrastrucure specific tooling (e.g. Minio client) vs generic BB tooling (EOEPCA Workspace UI), ...

a reconciliation pipeline for K8s cluster on CloudFerro leveraging the preinstalled Minio installation got deployed on EOEPCA demo/development cluster

this pipeline includes:
- resource limits based on subscription setting for a team are configured
- 2 buckets (stage & results) with scoped policies are created and credentials exposed
- Workspace UI providing view on bucket also allowing to share items in buckets is automatically deployed (in addition to generic Minio console)

> [!Note]
> Upcoming:
> - align on best way to install & upgrade CRDs on K8s cluster with EOEPCA core team -> scheduled for Fr 20240906
> - allow to manually connect existing buckets to a workspace -> depending on dynamic configuration (see below)

## Workspace UI & Data Sharing

the currently deployed status of Workspace UI allows authenticated users to browse and select a path in a configured bucket and to share all objects below this path with a stable url, with this stable share urls anyone (i.e. anonymous access) is able to browse the shared objects as well to request via API or via file download a list with presigned urls for each shared object

> [!Note]
> Upcoming:
> - allow to browse multiple buckets (e.g. all buckets provisioned for a workspace) and allow sharing objects from them -> https://github.com/EOEPCA/workspace/issues/7
> - become K8s-native and make the configuration dynamic (i.e. config like bucketnames and secrets should be read via K8s API dynamically and not be statically injected) -> https://github.com/EOEPCA/workspace/issues/7
> - extend sharing logic storage to be K8s-native -> update in 20240903
