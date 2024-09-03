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

3) RemoteUrl CRD (https://github.com/EOEPCA/workspace/issues/9)

- used by the Workspace Storage Layer for the end-user

- exposes an url allowing to request access to the shared objects

## Workspace UI

the Workspace UI got extended to support browsing of multiple buckets as well as to directly connect to K8s for configuration

> [!Note] Upcoming:
> - store (and leverage) above RemoteUrls for data sharing in dedicated K8s CRD instead of an internal database -> https://github.com/EOEPCA/workspace/issues/9
> - extend concept on how RemoteUrls can be leveraged besides requesting a list of presigned urls for the individual shared objects -> https://github.com/EOEPCA/workspace/issues/10

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

> [!Note] Upcoming:
> - [ ] align on best way to install & upgrade CRDs on K8s cluster with EOEPCA core team -> scheduled for Fr 20240906
> - [ ] allow to manually connect existing buckets to a workspace -> depending on dynamic configuration (see below)

## Workspace UI & Data Sharing

the currently deployed status of Workspace UI allows authenticated users to browse and select a path in a configured bucket and to share all objects below this path with a stable url, with this stable share urls anyone (i.e. anonymous access) is able to browse the shared objects as well to request via API or via file download a list with presigned urls for each shared object

> [!Note] Upcoming:
> - allow to browse multiple buckets (e.g. all buckets provisioned for a workspace) and allow sharing objects from them -> https://github.com/EOEPCA/workspace/issues/7
> - become K8s-native and make the configuration dynamic (i.e. config like bucketnames and secrets should be read via K8s API dynamically and not be statically injected) -> https://github.com/EOEPCA/workspace/issues/7
> - extend sharing logic storage to be K8s-native -> update in 20240903