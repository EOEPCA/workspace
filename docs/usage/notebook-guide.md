# Notebook guide

Choose a notebook for the task you need to do. Workspace Management sets up a place for a team to work. Vienna publishes images that other people can read. STAC registration processes a small dataset and makes it available through public links and search APIs.

| Notebook | Use it to | What it checks |
| --- | --- | --- |
| [Workspace Management](../workspace-management.ipynb) | Create a test workspace, give its owner access, and share sample files. | Storage is ready, the owner's roles are available, and temporary and public downloads match the uploaded images. |
| [STAC with managed PostgreSQL](../getting-started/stac-fastapi-pgstac.ipynb) | Run STAC FastAPI PgSTAC in Alice's virtual cluster and register the three-Item sample catalog. | The API uses the managed database. Item listing, pagination, area and date searches, and asset metadata checks pass. |
| [Vienna imagery with STAC and S3](../getting-started/vienna-imagery-with-stac-and-s3.ipynb) | Crop satellite images and publish them with descriptions that software can read. Try public downloads and authenticated S3 clients. | The STAC items describe the cropped images. Public, S3, and AWS CLI downloads have matching checksums. Byte-range reads return the requested bytes. |
| [Register STAC metadata](../getting-started/register-stac-metadata.ipynb) | Publish three recent usable Sentinel-5P cloud fraction clips, relocate them for public access, and serve STAC search. | Source and public copies match. The clipped grids, API searches, HTTP downloads, and OCI files are checked. |

## Choose where to run

Use the existing `ws-alice` and `ws-bob` workspaces, or a workspace with the same services. Run Workspace Management only if you need to create one.

Run Vienna from a repository checkout as Alice in `ws-alice`. It needs storage, a Data service, and the AWS CLI. No Kubernetes access is needed.

Run STAC with managed PostgreSQL as Alice in `ws-alice/vc0`. An operator first sets up the `catalog` database and `managed-postgres` Secret binding from `setup/examples.yaml`. The notebook requests the `demo` kubeconfig through the Workspace API. If the deployed API does not return profiles, Alice must get that profile from the workspace operator and enter its relative file path. The notebook uses a local Kubernetes Service proxy for registration and search.

Run registration in Bob's `ws-bob/default` Datalab session. It uses the session's kubeconfig and registry settings. Bob signs in for workspace storage access. No OAuth client secret is needed.

All three notebooks use public service settings from `eoepca-demo.env`. Tokens and storage credentials stay in kernel memory.

## Publish images for other people to use

Use Vienna to learn how someone else will read your results. It crops three Sentinel-2 images, creates previews, and uploads the files with a STAC catalogue. PackageR serves Collection and Item links. Readers can download the public assets without a workspace account, and workspace members can read them with S3 tools.

## Process data and add search

Use STAC registration to prepare recent data for applications that need to search by area and date. It selects three recent usable Sentinel-5P cloud fraction observations from the DLR GeoService STAC endpoint and clips them around Vienna. Flow 1 uses Portolan to create the metadata and upload the files under `published/`. A first vCluster API demonstrates search over those Items through a port-forward.

Flow 2 uses stacpkg relocation to copy the assets from `published/` to `public/` in the same workspace bucket and keeps the source files. The public metadata uses PackageR HTTP download routes as primary asset links, with public S3 locations as alternates. The first API restarts with this metadata. PackageR serves the public catalogue dynamically through the existing Data service. MoreGeo STAC Browser previews this catalogue in the user's browser.

| How readers get the metadata | When to use it |
| --- | --- |
| PackageR reads `public/catalog.parquet` and builds Collection and Item responses on request. | Publish a catalogue through the existing Data service. Readers follow links; this view has no `/search` route. |
| The first vCluster API fetches and verifies the uploaded GeoParquet at startup. | Demonstrate search first with private `published/` S3 asset links, then with relocated public HTTP links. |
| A separate STAC API reads an OCI package pulled by an init container. | Start an API with a known copy of the metadata. The package digest fixes that copy until you deploy a new digest. |

Flow 3 bundles the relocated public metadata and asset links into a package and pushes it to the workspace OCI container registry as an artifact. The second API pulls the package by digest, so a team can deploy the same catalogue again. Image bytes stay in workspace storage. Both API deployments run in the session's vCluster and need that session to stay running. The permanent Data service and its PackageR catalogue have a separate lifecycle.

Each run selects three recent usable observations. It adds them to the shared catalogue and keeps older published data. It does not set up a schedule or delete old observations.

## Run the upload as a job

The registration notebook uses Bob's interactive login. For a scheduled upload, use [OAuth machine access](../design/iam-integration.md#machine-access) and supply secrets through the job's secret store. Registry publication also needs registry credentials.
