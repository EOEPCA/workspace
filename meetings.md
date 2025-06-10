# Agenda 20250610

- Crunchy Data Postgres Operator as infra component (not directly workspace related but generally applicable))
  - Goal: individual BB should not bundle Postgres themselves but "request" a database from platform, so they also get scoped user and can bootstrap schema and initial data → Crunchy Data Postgres Operator provides these capabilities  
  - Status: such setup existed purely for eoapi, but now we also want to open up the database for resource management and, in future, other BBs (IAM with Keycloak, …)  see https://github.com/EOEPCA/roadmap/issues/415#issuecomment-2948746291
    > this setup not only created database `eoapi` and scoped access credentials but also makes the corresponding DB access credentials available as a k8s Secret—no need to pass credentials around!  

    -> Crunchy Data Postgres Operator becomes an infrastructure component relevant for many BBs, with desired state fully trackable via GitOps; established on eoepca-demo with  
    https://github.com/EOEPCA/eoepca-plus/blob/4ece2c408a70c6bcf3a226f082267a5621b85805/argocd/infra/pgo/parts/postgrescluster.yaml#L39  

  - Open Callenge: credentials are created in the `infra` namespace but must be accessible to namespaces like `data-access` (eoapi) and `rm` (pycsw/pygeoapi/…), proposal to make the External Secrets Operator (already used in workspace pipelines for similar reasons) an infra component, tracked in https://github.com/EOEPCA/roadmap/issues/415#issuecomment-2894332551 TBC

- Modularized workspace pipelines (blueprints as Crossplane compositions) are referenced, not copied  
  - Goal: all variants must be consumable externally allowing to just point to these blueprints – two complementary concepts used: EnvironmentConfig and physical separation within different folder structures (see https://github.com/EOEPCA/workspace/issues/55)  
  - Status: applied on `eoepca-demo`  (MinIO, vCluster – see https://github.com/EOEPCA/workspace/issues/54#issuecomment-2909051138) and on `terrabyte-test` / `terrabyte-prod` clusters (also via ArgoCD using Quobyte and k8s namespace, but no vcluster currently), using tag `v2025.06.05`  
  - Next: Richard’s scripted deployments provided additional findings and feedback (https://github.com/EOEPCA/workspace/issues/52#issuecomment-2949261918), adaptions to be made until final Q2 2025 release (may include breaking changes)

    > development dependency on final DNS naming for correct eoepca-demo deployment (ApiSix <-> nginx migration by Richard with IAM team)

- Extended `Workspace` object as the canonical source of truth:  
  - track members in addition to owner and propagate from there
    > this addresses an identified permission flaw in the previous version’s member management (https://github.com/EOEPCA/workspace/issues/53)
  - additional buckets (only one created by default)  
  - buckets where workspace members also have access  
  - grants given to other users  

  ```yaml
  spec:
    owner: alice                  
    subscription: silver          
    vcluster: active              

    members:                      
      - carol

    extraBuckets:                 
      - ws-alice-results

    linkedBuckets:                
      - ws-eric-shared

    grants:                       
      - bucket: ws-alice-results
        grantees:
          - bob
          - eric
  ```
  -> to be finalized and documented  

- On terrabyte we already mount an existing PVC via Quobyte storageClass (i.e., not relying on a created volume during provisioning pipeline), this can be generalized in https://github.com/EOEPCA/workspace/issues/52 so Workspace can be used against NFS and any other PVC (but for sure no presigned URLs then, so you always proxy through)  

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
