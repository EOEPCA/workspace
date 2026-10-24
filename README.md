# Workspace

Helm chart sources, documentation, and examples for the EOEPCA Workspace Building Block.

- [Documentation](https://eoepca.readthedocs.io/projects/workspace/)
- [Installation and chart settings](docs/getting-started/installation.md)
- [Quickstart](docs/getting-started/quickstart.md)
- [Notebook guide and checked outcomes](docs/usage/notebook-guide.md)
- [Concepts](docs/concepts.md)
- [Workspace API source](https://github.com/EOEPCA/rm-workspace-api/)

## Local checks

```bash
helm lint pipeline
helm template workspace-pipeline pipeline
uv run --no-project --with pyyaml python -m unittest discover -s tests
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
