# Workspace

A workspace gives a team a place to keep data, run code, and share results. Members use shared object storage and services, with browser sessions for their code. They can grant another workspace access to a bucket or publish files for anyone to download.

Open a Datalab session for its editor and terminal. Use its Data tab to browse storage with PackageR. A permanent Data address lets people read and download published results even when compute sessions are stopped.

## Start here

Follow the [quickstart](getting-started/quickstart.md) to create a test workspace, publish satellite images, and read them through public links and S3 clients. The STAC registration example has three flows: publish with Portolan and demonstrate search; copy assets to the public folder in the same workspace bucket with stacpkg relocation and share the catalogue; then deploy a second API from an OCI metadata package by digest.

Use the [notebook guide](usage/notebook-guide.md) to choose an example and check what it needs before you run it.

For an existing workspace, use [Concepts](concepts.md) to add a colleague, share a bucket with another team, publish a dataset, or start a session.

## Set up the service

Operators can use [installation](getting-started/installation.md) to set up the shared services. Use [IAM integration](design/iam-integration.md) to give people and jobs the access they need, and [operational controls](design/operational-controls.md) to set session resources and network access.

The [architecture](design/architecture.md) page shows how the API, Crossplane packages, and runtime services fit together.
