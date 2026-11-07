# Demo setup

These manifests define the demo accounts, storage, and Datalabs.

| File | Resources |
| --- | --- |
| `admin.yaml` | Oscar's platform administrator group and membership. |
| `examples.yaml` | Storage and Datalabs for Alice, Bob, and Eric. |
| `demos.yaml` | Cloudferro storage and a virtual cluster for `ws-demos`. |

Alice's `vc0` uses the managed `catalog` database. Its Secret binding copies
the PostgreSQL connection to `stac-fastapi-pgstac/managed-postgres`. The `demo`
profile selects that namespace. Both STAC API notebooks use this workspace
vCluster. Registration also deploys Distribution with its own volume in that
namespace. Default browser sessions stay stopped until requested.

Every declared virtual cluster has a built-in `cluster-admin` profile.
Provider Datalab assigns that role to workspace administrators. The optional
profiles under `groups` add namespace roles. Selecting a kubeconfig does not
reduce the token's permissions. Alice uses an exchanged token to delegate
only the `demo` profile.

Profile kubeconfigs contain public connection settings. Download the
profile through Workspace API, as shown in the notebooks.
Sign in with your own account and supply your access-token file through
`DATALAB_ACCESS_TOKEN_FILE`. The token must include the workspace audience
and an assigned virtual cluster role.

Machine access uses the workspace client secret supplied separately.
The workspace service account has only `ws_api` by default; virtual API
access needs an explicit role grant. `status.oauth2` lists the existing
client and its source Secret reference. It does not grant Secret access.

For operator setup, use the provider's
[installation guide](https://provider-datalab.versioneer.at/latest/how-to-guides/installation/).
