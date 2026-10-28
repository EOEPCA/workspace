# Concepts

Use workspace storage to keep a team's datasets in one place. Add members to work with those files, grant another workspace access to a bucket, or publish results for readers without an account. Sessions and managed services give the team tools to process that data.

Open your workspace dashboard and select **Management** to manage members, buckets, sessions, and services. The available tabs and actions depend on your [workspace role](design/iam-integration.md#roles).

## Storage

A `Storage` resource defines buckets, a storage identity, access requests, grants, and lifecycle rules. Workspace members use that identity and its bucket permissions. A bucket grant lets another workspace use selected data with its own credentials, so teams can share a dataset without copying it.

A discoverable bucket can appear in another workspace's access-request list. Its owner still has to approve access. The receiving workspace then uses its own storage credentials to reach the bucket.

| Permission | Access |
| --- | --- |
| `ReadOnly` | List and read objects. |
| `ReadWrite` | List, read, write, and delete objects. |
| `WriteOnly` | List, write, and delete objects, without reading their contents. |
| `None` | Record that access is not granted. |

For manifest-based setup, backends that resolve requests from peer `Storage` resources also need `storages.pkg.internal/discoverable: "true"` on the owner resource. The per-bucket `discoverable` field advertises the bucket; it is not a storage policy.

Lifecycle rules belong to `spec.buckets[].lifecycleRules`. A rule selects the whole bucket with `*` or a prefix such as `tmp/*`. `Notify` reports matching objects; `Delete` removes them. Set exactly one age (`minAge`, such as `12h`) or UTC cutoff (`at`).

See the provider's [permission model](https://github.com/versioneer-tech/provider-storage/blob/main/docs/how-to-guides/permissions.md) for backend details.

### Create a bucket

Open **Buckets**, add a unique bucket name, and save it. Start the name with your workspace name, for example `ws-test-20261024071434-test`. Wait for storage to finish creating the bucket before uploading files.

[![Buckets tab with a new bucket row and the Save button](img/concepts/buckets.png)](img/concepts/buckets.png)

Mark a bucket as discoverable to let other workspaces find it and request access. This does not make its objects public. See [public shares](#public-shares) for public downloads.

### Share a bucket with another workspace

1. In the receiving workspace, request access to the owner's discoverable bucket.
2. In the owner's workspace, open **Requested Buckets**, review the permission, and select **Grant bucket access**.
3. Wait for the storage policy to update.
4. In the receiving workspace, use its existing storage credentials to access the shared bucket.

[![Requested Buckets tab, with no incoming requests in this test workspace](img/concepts/requested-buckets.png)](img/concepts/requested-buckets.png)

Use `ReadOnly` for a reader. The [permission table](#storage) describes each level.

## Datalabs and sessions

A `Datalab` resource defines the team's users, sessions, and shared services. Start a session when you need an editor, a terminal, or a place to run code. Each named session has a persistent home volume, so you can stop it and keep your files for the next run.

Sessions share the workspace's storage identity and managed services. A session can use a host-cluster namespace or its own virtual Kubernetes control plane. See [operational controls](design/operational-controls.md) for the settings.

### Start or stop a session

Open **Sessions** to add a named session or change its state. Opening its Datalab link starts a stopped session when the API supports on-demand access.

[![Sessions tab with the started default session and its open and stop controls](img/concepts/sessions.png)](img/concepts/sessions.png)

Shared storage, Data, and managed databases have separate lifecycles. See [session controls](design/operational-controls.md#sessions) for the initial mode and storage limits.

## Managed services

Use a managed service when your code needs a database, cache, or vector store shared within the workspace. PostgreSQL, MongoDB, Redis, and Qdrant need their operators installed in the platform. A registry can store container images and OCI packages for use by session workloads.

### Add a managed service

Use **Stores** to request an available service. The platform operator must install and configure its database operator first.

[![Stores tab with an unsaved request for a MongoDB store named test](img/concepts/stores.png)](img/concepts/stores.png)

An operator can also add a service to the existing Datalab configuration. For example, this block requests a MongoDB store named `test`:

```yaml
spec:
  documentStores:
    test:
      storage: 1Gi
```

Keep the Datalab's other fields when adding this block. The session receives `MONGO_TEST_URI` after the service is ready. Stop and start the session to load changed connection settings.

Provider Datalab's [usage guide](https://provider-datalab.versioneer.at/latest/how-to-guides/usage_concepts/) describes the PostgreSQL, cache, vector, and registry fields. Its [application examples](https://provider-datalab.versioneer.at/latest/how-to-guides/additional_services/) cover tools such as MLflow.

## Data access and sharing

PackageR is the workspace storage browser. The Data service is enabled by default. An operator can give it a permanent address such as `https://<workspace-name>.lab.example.org`. The Datalab's Data tab opens that same service.

With a permanent address, storage browsing and public shares work without a running compute session. Sign in to browse private workspace data. A public share or presigned download link can be used without a workspace account.

### Public shares

Put files in the `public/` folder of the bucket named after the workspace. For `ws-bob`, this is `s3://ws-bob/public/`. The default share exposes that folder for public browsing and downloads. A `public/` folder in another bucket is not shared automatically.

Open `/share/public/` on the Data hostname. Every file placed in this folder is public. Upload files through PackageR when writes are allowed, or use the backing storage endpoint and its credentials.

[![Public Data browser with the Vienna image folder, preview images, and STAC catalogue](img/quickstart/public-data.png)](img/quickstart/public-data.png)

### Presigned download links

A presigned URL gives temporary access to one object. In PackageR, select a file, open **Info**, then select **Show** beside **Presigned URL**.

This URL points to object storage. It works until it expires, and the recipient needs network access to that storage endpoint.

A public-share download route can redirect to a fresh presigned URL. Share that route when you need a link that lasts longer than one signed URL. [Workspace Management](workspace-management.ipynb) checks both download paths against the uploaded bytes.

### STAC catalogues

Use STAC to describe when data was collected, which area it covers, and where to download its files. Applications can read these descriptions to choose the data they need.

Put a STAC GeoParquet file at `public/catalog.parquet` to publish a catalogue through the existing Data service. PackageR reads it when someone requests the catalogue and builds Collection and Item responses with public asset links. Relative asset paths resolve within the share folder.

Start with the [Vienna notebook](getting-started/vienna-imagery-with-stac-and-s3.ipynb) to publish satellite images and let other people download them. It crops three images, adds descriptions for the cropped area, and checks public and authenticated S3 downloads.

Use the [registration notebook](getting-started/register-stac-metadata.ipynb) to upload with Portolan under `published/`, demonstrate API search, then copy the assets with stacpkg under `public/`. Public metadata uses PackageR HTTP asset links for browser access. A second API reads an OCI metadata package fixed to a digest. The [notebook guide](usage/notebook-guide.md#process-data-and-add-search) compares these views and their setup.

### S3 clients

The optional Data S3 endpoint lets AWS tools read data through the Data hostname. It uses path-style requests, and is read only. Uploads use the backing object-storage endpoint.

| Signing setting | Value |
| --- | --- |
| Endpoint | The workspace's permanent Data URL. |
| Access key ID | The workspace name. |
| Secret access key | The same workspace name. |
| Session token | A valid Keycloak access token. |

The signing names are public identifiers. The token must include the workspace name in `aud` and `ws_access`, `ws_admin`, or `ws_api` under that workspace's client roles. Human users can use device login through the central client. A service can use the generated workspace client's credentials.

The endpoint supports bucket and object listing, HEAD, GET, and byte-range GET. It rejects uploads and S3 query-presigned requests. S3 reads of `public/` objects still need a token; public-share links use a separate route.

Operators enable S3 through the [Gateway settings](getting-started/installation.md#example-values). The Vienna notebook refreshes its device login before the S3 and AWS CLI steps and checks the downloaded files by SHA-256.

#### Automatic token renewal

For service access, use `scripts/s3-credentials.py` as an AWS `credential_process`. The script returns the signing values, an OAuth access token, and its expiry time. AWS CLI and Boto3 can run it again when they need fresh credentials. See the [AWS process credential documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sourcing-external.html).

Run these commands from the repository root. Install Python and AWS CLI first. Replace the workspace name, Data URL, and Keycloak realm URL with your service settings. The workspace OAuth client must have the audience and role described above.

```bash
aws configure set region us-east-1 --profile ws-alice
aws configure set endpoint_url https://ws-alice.lab.example.org --profile ws-alice
aws configure set s3.addressing_style path --profile ws-alice
aws configure set credential_process \
  "python3 \"$PWD/scripts/s3-credentials.py\" --tenant ws-alice --issuer https://keycloak.example.org/realms/eoepca" \
  --profile ws-alice
```

These commands add a profile to `~/.aws/config`. The process command uses the script's absolute path. It belongs in the config file; do not copy the returned token into `~/.aws/credentials`. The resulting profile has this form:

```ini
[profile ws-alice]
region = us-east-1
endpoint_url = https://ws-alice.lab.example.org
credential_process = python3 "/absolute/path/to/workspace/scripts/s3-credentials.py" --tenant ws-alice --issuer https://keycloak.example.org/realms/eoepca
s3 =
    addressing_style = path
```

Enter the OAuth client secret once for the current terminal. The hidden prompt keeps it out of shell history. The helper reads `CLIENT_SECRET` when AWS starts it.

```bash
CLIENT_SECRET="$(python3 -c 'import getpass; print(getpass.getpass("OAuth client secret: "))')"
export CLIENT_SECRET
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
aws s3 ls s3://ws-alice/ --profile ws-alice
```

Boto3 can use the same profile from a process started in that terminal:

```python
import boto3

session = boto3.Session(profile_name="ws-alice")
s3 = session.client("s3")
objects = s3.list_objects_v2(Bucket="ws-alice", MaxKeys=10)
```

Keep `CLIENT_SECRET` available while these clients run so the helper can get new tokens. Run `unset CLIENT_SECRET` when you finish. This profile provides read-only access through the Data endpoint. Use the registration notebook for uploads to backing storage.

## Membership

Add members so colleagues can use the workspace's data and services. A workspace role controls dashboard and management actions. Members who can view storage credentials use the workspace's full storage policy, including its existing bucket grants.

The owner of another workspace approves any additional bucket grant. See [IAM roles](design/iam-integration.md#roles) for the management permissions.

### Add a member

1. Open **Members**.
2. Add an existing Keycloak username and select its workspace role.
3. Save the change.
4. Ask the new member to sign in again to load the assigned roles.

[![Members tab with an unsaved row for Bob, a role selector, and the Save button](img/concepts/members.png)](img/concepts/members.png)

Give workspace administrator access to people who need to manage members, buckets, sessions, or stores.

## Check a workspace that is still starting

An operator can inspect status without reading credential values:

```bash
kubectl get storage,datalab -n workspace
workspace_name=ws-test-20261024071434
kubectl describe datalab "$workspace_name" -n workspace
```

Set `workspace_name` to the name printed by your notebook. Check the reported conditions and events. If storage works but the Data hostname does not, check its workload, HTTPRoute, Gateway listener, certificate reference, DNS, and public load-balancer route.
