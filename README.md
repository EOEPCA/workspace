# Workspace

The EOEPCA Workspace Building Block gives a team a place to store data, run code, and share results. Team members use the same storage and can request browser sessions and managed services. A permanent Data address keeps published files available when compute sessions stop.

The notebooks take you from an empty workspace to public satellite images and searchable STAC metadata. Start with the quickstart to create a workspace. Use the notebook guide to choose an example for public downloads, automated uploads with Portolan, or STAC search.

This repository contains the Helm charts, documentation, and examples. Deploy the Workspace API and UI separately from their source repository.

- [Documentation](https://eoepca.readthedocs.io/projects/workspace/)
- [Installation and chart settings](docs/getting-started/installation.md)
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
