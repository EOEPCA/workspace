# Notebook guide

Choose a notebook for the task you need to do. Workspace Management sets up a place for a team to work. Vienna publishes images that other people can read. STAC registration processes a small dataset and makes it available through public links and search APIs.

| Notebook | Use it to | What it checks |
| --- | --- | --- |
| [Workspace Management](../workspace-management.ipynb) | Create a test workspace, give its owner access, and share sample files. | Storage is ready, the owner's roles are available, and temporary and public downloads match the uploaded images. |
| [Vienna imagery with STAC and S3](../getting-started/vienna-imagery-with-stac-and-s3.ipynb) | Crop satellite images and publish them with descriptions that software can read. Try public downloads and authenticated S3 clients. | The STAC items describe the cropped images. Public, S3, and AWS CLI downloads have matching checksums. Byte-range reads return the requested bytes. |
| [Register STAC metadata](../getting-started/register-stac-metadata.ipynb) | Publish three recent usable Sentinel-5P cloud fraction clips, relocate them for public access, and serve STAC search. | Source and public copies match. The clipped grids, API searches, HTTP downloads, and OCI files are checked. |

## Choose where to run

Run Workspace Management first if you need a test workspace. Give its printed workspace name to Vienna. STAC registration defaults to `ws-alice`; you can use another workspace if it has the services and credentials listed below.

Run Workspace Management and Vienna from this repository with `uv sync` and `uv run jupyter lab`. They read public service settings from `eoepca-demo.env` and use device login for user access. Install the AWS CLI for Vienna's final step.

Run STAC registration in the target workspace's Datalab, with its session vCluster kubeconfig. Enter the workspace name, OAuth client ID, and hidden client secret when asked. The client needs the [machine access](../design/iam-integration.md#machine-access) roles and audience. The helper gets storage credentials from the Workspace API before it uploads. The Datalab supplies registry settings for OCI access; enter them if they are missing.

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

To publish new data without opening a notebook, set up a scheduler or another service to run the selection, clipping, and upload steps. Use [OAuth machine access](../design/iam-integration.md#machine-access) for the upload. Supply the workspace name and client ID in the job settings and the client secret through its secret store. Publishing an OCI package also needs registry credentials.

The [quickstart](../getting-started/quickstart.md) gives the steps for all three examples. Run registration to select current observations and produce its images and verification results.
