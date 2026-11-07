# Notebook guide

Workspace Management creates a workspace and shows its API operations.
Vienna publishes images. The STAC notebooks add search and package metadata.
The saved runs were checked with Provider Datalab `0.12.0-rc.8` on `eoepca-demo`.

| Notebook | Use it to | What it checks |
| --- | --- | --- |
| [Workspace Management](../workspace-management.ipynb) | Create a workspace, access its virtual cluster, add and delegate a namespace profile, push an OCI package, and share a file. | Namespace access and denial, registry push and pull, and temporary and public file downloads. |
| [STAC with managed PostgreSQL](../getting-started/stac-fastapi-pgstac.ipynb) | Deploy as Alice, search the sample catalog, and submit a GeoParquet export with an exchanged token. | Searches and metadata match. The token permits Jobs in the selected namespace and denies cluster administration. The exported IDs, geometry, and checksum match. |
| [Vienna imagery with STAC and S3](../getting-started/vienna-imagery-with-stac-and-s3.ipynb) | Crop satellite images, publish STAC metadata, and use public downloads and authenticated S3 clients. | The STAC items describe the cropped images. Public, S3, and AWS CLI downloads have matching checksums. Byte-range reads return the requested bytes. |
| [Register STAC metadata](../getting-started/register-stac-metadata.ipynb) | Publish three Sentinel-5P cloud fraction clips, relocate them for public access, and serve STAC search. | Source and public copies match. The clipped grids, API searches, HTTP downloads, and OCI package hashes are checked. |

## Choose where to run

Use the existing `ws-alice` workspace, or a workspace with the same services. Run Workspace Management only if you need to create one.

Workspace Management creates its `demo` profile for namespace `demo` in the
new workspace. The STAC notebooks use `ws-alice/vc0/demo`, which selects
`stac-fastapi-pgstac`. The profiles belong to different workspaces.

Run Vienna from a repository checkout as Alice in `ws-alice`. It needs storage, a Data service, and the AWS CLI. No Kubernetes access is needed.

Run STAC with managed PostgreSQL as Alice in `ws-alice/vc0`. An operator first sets up the `catalog` database and `managed-postgres` Secret binding from `setup/examples.yaml`. Alice signs in and downloads the `demo` profile through Workspace API. She deploys the API with her human token, then exchanges it for namespace access and submits an export Job. The local Kubernetes Service proxy supports registration and search.

Run registration from a repository checkout as Alice. It downloads the same `ws-alice/vc0/demo` profile through Workspace API. Her login supplies Kubernetes and storage access. The notebook deploys CNCF Distribution with a 1 GiB volume and submits a publisher Job in that namespace. The registry has an internal HTTP Service for trusted workspace workloads, with no public route or separate login.

The notebooks use public settings from `eoepca-demo.env`. Tokens and storage credentials stay in kernel memory, except for private temporary token files used by the kubeconfig helper. Credential values stay out of saved output.

Workspace Management uses the default managed registry backed by workspace
storage. Registration creates a separate Distribution registry inside `vc0`
to show package publication from Kubernetes Jobs. It keeps packages on its
own persistent volume.

## Login and token lifetimes

The notebooks sign in through the public `workspace-api` client and keep the
login in kernel memory. They pass short-lived access tokens to kubectl through
private files. Rerun the login cell if the session expires; restarting the
kernel starts a new login. These calls do not use the kubeconfig's offline
login cache.

For standalone kubectl work, the administrator kubeconfig can start device
login and cache it for up to 30 days. See [virtual cluster access](../getting-started/vcluster-access.md#4-reuse-the-cached-login).
An exchanged namespace token has only its reported access-token lifetime and
no refresh token. Offline login does not extend a delegated token.

## Publish images for other people to use

Vienna publishes three Sentinel-2 crops, previews, and a STAC catalogue. PackageR serves Collection and Item links. Readers can download public assets without a workspace account. Workspace members can also read them with S3 tools.

## Process data and add search

Use STAC registration to prepare recent data for applications that need to search by area and date. It selects three recent usable Sentinel-5P cloud fraction observations from the DLR GeoService STAC endpoint and clips them around Vienna. Flow 1 uses Portolan to create the metadata and upload the files under `published/`. A first vCluster API searches those Items through a local Kubernetes Service proxy.

Flow 2 uses stacpkg relocation to copy the assets from `published/` to `public/` in the same workspace bucket and keeps the source files. The public metadata uses PackageR HTTP download routes as primary asset links, with public S3 locations as alternates. The first API restarts with this metadata. PackageR serves the public catalogue dynamically through the existing Data service. MoreGeo STAC Browser previews this catalogue in the user's browser.

| How readers get the metadata | When to use it |
| --- | --- |
| PackageR reads `public/catalog.parquet` and builds Collection and Item responses on request. | Publish a catalogue through the existing Data service. Readers follow links; this view has no `/search` route. |
| The first vCluster API fetches and verifies the uploaded GeoParquet at startup. | Demonstrate search first with private `published/` S3 asset links, then with relocated public HTTP links. |
| A separate STAC API reads an OCI package pulled by an init container. | Start an API with a known copy of the metadata. The package digest fixes that copy until you deploy a new digest. |

Flow 3 bundles the public metadata and asset links into an OCI artifact. A Job pushes it to Distribution in the workspace vCluster and checks a pull by digest. The second API loads that same digest. Image bytes stay in workspace storage. The local proxies last while the notebook is running and its caller token is valid. The Data service and its PackageR catalogue remain available separately. Notebook cleanup keeps the registry PVC and its artifacts.

Each run selects three recent usable observations. It adds them to the shared catalogue and keeps older published data. It does not set up a schedule or delete old observations.

## Run the upload as a job

The registration notebook uses Alice's interactive login. For a scheduled storage upload, use [OAuth machine access](../design/iam-integration.md#machine-access) and supply secrets through the job's secret store. Its registry publisher Job uses the internal workspace Service.

The PgSTAC notebook includes an hourly GeoParquet export CronJob. It starts suspended and runs one Job for validation. Enable its schedule when needed. The Job uses a storage Secret; the exchanged token only submits and inspects it. Refresh the storage Secret after credential rotation or configure a provider Secret binding.
