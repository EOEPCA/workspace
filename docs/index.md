# Workspace

A workspace provides shared object storage, virtual Kubernetes clusters, an
OCI registry, and a Data service. Teams can share buckets or publish files
for anyone to download. Browser sessions provide an editor and terminal when
needed; the other services run independently.

## Start here

Follow the [quickstart](getting-started/quickstart.md) to create a workspace,
access its virtual cluster, delegate namespace access, and push a registry
package. The STAC notebooks publish satellite data and serve search APIs.

Use the [notebook guide](usage/notebook-guide.md) to choose an example and check what it needs before you run it.

For an existing workspace, use [Concepts](concepts.md) to add a colleague, share a bucket with another team, publish a dataset, or start a session.

## Set up the service

Operators can use [installation](getting-started/installation.md) to set up the shared services. Use [IAM integration](design/iam-integration.md) to give people and jobs the access they need, and [operational controls](design/operational-controls.md) to set session resources and network access.

The [architecture](design/architecture.md) page shows how the API, Crossplane packages, and runtime services fit together.
