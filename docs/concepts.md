# Concepts

## Storage

A `Storage` resource defines a workspace's buckets, credentials, access requests, grants, and lifecycle rules. The workspace uses one storage identity. Its members use the same credentials and bucket permissions.

A bucket can be marked as discoverable so other workspaces can request access. The owner approves a grant with one of these permissions:

| Permission | Access |
| --- | --- |
| `ReadOnly` | List and read objects. |
| `ReadWrite` | Read, write, and delete objects. |
| `WriteOnly` | Write objects. |
| `None` | Deny or remove access. |

The receiving workspace uses its own credentials to reach the shared bucket. The owner can revoke the grant later.

Lifecycle rules go under `spec.buckets[].lifecycleRules`. A rule selects the whole bucket with `*` or a prefix such as `tmp/*`. `Notify` reports matching objects; `Delete` removes them. Set an object age, such as `12h`, or a fixed UTC timestamp in `at`.

See Provider Storage's [permissions guide](https://provider-storage.versioneer.at/latest/how-to-guides/permissions/) for the backend rules.

## Datalabs and sessions

A `Datalab` resource defines the development environment. A session is a running instance of that environment. The session uses the workspace's S3 credentials and has a persistent volume for local files.

Databases and other backing services are configured on the Datalab. They can include PostgreSQL, MongoDB, Redis, Qdrant, and a container registry, depending on the installed operators and runtime settings. See the [quickstart](getting-started/quickstart.md#6-use-managed-services) for an example.

Users with Kubernetes access can also deploy their own applications from the terminal. The provider's [additional services guide](https://provider-datalab.versioneer.at/latest/how-to-guides/additional_services/) has manifests for common applications.

## Data access and sharing

[PackageR](https://provider-datalab.versioneer.at/latest/how-to-guides/usage_concepts/#data-and-sharing) lets you browse workspace storage without starting a compute session. Its permanent address uses the configured Gateway and hostname. A running session's Data tab opens the same service.

Sign in to PackageR to browse workspace data. Public shares and presigned download links work without a Workspace account.

### Public shares

Put files in the `public` folder of the bucket named after the Datalab. For `ws-bob`, that is `s3://ws-bob/public/`. The default public share exposes this folder for browsing and downloads without sign-in. A folder named `public` in another bucket is not automatically shared.

Open the `public` share from Settings, or use `/share/public/` on the Data hostname. You can upload files through PackageR when writes are allowed, or with your storage tools. Every file placed in this folder becomes public.

### Presigned download links

Use a presigned URL to send someone a single file. Select the file in PackageR, open Info, then select Show beside Presigned URL.

The link points directly to object storage and works without a Workspace login until it expires. The recipient must be able to reach that storage endpoint. For a public share, its download route can redirect to a fresh presigned URL; share that route when you need a link that outlives one signed URL.

### S3 clients

The optional [S3 endpoint](https://provider-datalab.versioneer.at/latest/how-to-guides/usage_concepts/#s3-client-access) lets the AWS CLI and S3 libraries read data through the Data hostname. It uses path-style requests and is read only, even when PackageR allows writes. The storage policy determines which buckets and objects it can serve.

Clients sign requests with these values:

| Setting | Value |
| --- | --- |
| Endpoint | The Datalab's permanent Data URL |
| Access key ID | The Datalab name, such as `ws-bob` |
| Secret access key | The same Datalab name |
| Session token | A Keycloak access token |

The signing names are public identifiers. Access requires a valid token with the Datalab name in `aud` and `ws_access`, `ws_admin`, or `ws_api` under that workspace's client roles. The generated service account can use the client credentials grant. Other OAuth clients must supply the same audience and roles.

The endpoint supports listing, HEAD, GET, and byte-range GET. Uploads and S3 query-presigned requests are rejected. Objects in `public/` still need authenticated S3 requests; the public share uses its own route.

Operators enable it for the environment with the [Gateway settings](getting-started/installation.md#use-a-gateway). The [Vienna notebook](getting-started/vienna-stac-s3.ipynb) shows public shares, STAC links, presigned downloads, and S3 client setup with automatic token renewal.

## Membership

Workspace membership controls access to the dashboard, management pages, and Datalab. Bucket grants control which data the workspace can use. Joining a workspace does not grant access to buckets owned by other workspaces.

See [IAM integration](design/iam-integration.md#roles) for the roles and [operational controls](design/operational-controls.md) for session modes and limits.
