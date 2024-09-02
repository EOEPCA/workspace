# Agenda 20240902

## Workspace Concepts and Interfac

3 CRDs to express desired state got introduced for the Workspace BB

> [!Note]
> - internally more CRDs can get deployed on the Kubernetes cluster based on the configured reconciliation pipelines, e.g. the Minio Bucket CRD

1) Workspace

- managed by platform operator

- exposes kube-context as K8s secret to be used by end-user (or by tooling installed for end-user)

2) Storage

- used by Workspace reconciliation pipeline

- exposes bucket details and credentials as K8s secret to be used by platform operator and by tools like the Workspace UI for the end-user

3) ShareUrl

- used by the Workspace UI for the end-user

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

> [!Upcoming]  
> - align on best way to install & upgrade CRDs on K8s cluster with EOEPCA core team
> - allow to manually connect existing buckets to a workspace

## Workspace UI & Data Sharing

the currently deployed status of Workspace UI allows authenticated users to browse and select a path in a configured bucket and to share all objects below this path with a stable url, with this stable share urls anyone (i.e. anonymous access) is able to browse the shared objects as well to request via API or via file download a list with presigned urls for each shared object

> [!Upcoming]
> - allow to browse multiple buckets (e.g. all buckets provisioned for a workspace) and allow sharing from them
> - become K8s-native and make configuration dynamic (i.e. config like bucketnames and secrets should be read via K8s API dynamically and not be statically injected)
> - store (and leverage) above stable share urls for data sharing in dedicated K8s CRD instead of an internal database
> - extend concept on how stable share urls can be leveraged besides the list of presigned urls
