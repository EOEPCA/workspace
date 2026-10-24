# Notebook guide

The notebooks cover three parts of a workspace workflow. Start with Workspace Management and use its printed workspace name in the other two.

| Notebook | What it demonstrates | What the checks prove |
| --- | --- | --- |
| [Workspace Management](../workspace-management.ipynb) | An administrator creates storage for a user; the user uploads and shares files. | Storage is ready, the owner's roles are available, and temporary and public downloads match the uploaded images. |
| [Vienna imagery with STAC and S3](../getting-started/vienna-imagery-with-stac-and-s3.ipynb) | Publish image files and their STAC metadata in one workspace. Read them with public links and authenticated S3 clients. | The three STAC items describe the cropped images; public, S3, and AWS CLI downloads have matching checksums. Byte-range reads return the requested bytes. |
| [Register STAC metadata](../getting-started/register-stac-metadata.ipynb) | Package STAC items from DLR's Geoservice once, then serve them from a workspace STAC API. | The OCI package survives push, pull, and deployment with the same file checksums. API queries return the selected items and their source asset links. |

## Choose where to run

Run Workspace Management and Vienna from this repository with `uv sync` and `uv run jupyter lab`. They read public service settings from `eoepca-demo.env` and use device login for user access. Install the AWS CLI for Vienna's final step.

Run STAC registration in the test workspace's Datalab. It needs the session registry credentials and vCluster kubeconfig supplied by that runtime. Its OCI registry login uses Basic authentication.

## Choose what to publish

Use Vienna when you want the image files in workspace storage. Its public catalogue serves Collection and Item links.

Use registration when the source already hosts the rasters and you want a selected metadata package with a fixed OCI digest. Its deployed API also supports STAC search. Access to the raster files still depends on the source service.

The [quickstart](../getting-started/quickstart.md) gives the run order and prerequisites. Each notebook keeps its outputs so you can inspect the images, checksums, and API results.
