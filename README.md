# Workspace

The EOEPCA Workspace Building Block provides shared storage, virtual Kubernetes
clusters, an OCI registry, and data services for a team. Browser sessions and
managed databases are available when configured. Published files remain
available through the Data service when browser sessions stop.

Start with [Workspace Management](docs/workspace-management.ipynb) to create a workspace, access its virtual
cluster, delegate a namespace profile, and push a registry package. The other
notebooks publish satellite images and serve STAC search.

This repository contains the Helm charts, documentation, and examples. Deploy the Workspace API and UI separately from their source repository.

- [Documentation](https://eoepca.readthedocs.io/projects/workspace/)
- [Components and environment configuration](docs/getting-started/installation.md)
- [Quickstart](docs/getting-started/quickstart.md)
- [Choose a notebook](docs/usage/notebook-guide.md)
- [Concepts](docs/concepts.md)
- [Workspace API source](https://github.com/EOEPCA/rm-workspace-api/)

## Local checks

```bash
helm lint pipeline
helm template workspace-pipeline pipeline
```

To build the documentation and check links within it:

```bash
uv run --no-project --with-requirements docs/requirements.txt mkdocs build --strict
```

To preview it locally:

```bash
uv run --no-project --with-requirements docs/requirements.txt mkdocs serve
```

## License

[Apache 2.0](LICENSE).
