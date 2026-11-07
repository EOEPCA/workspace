# IAM integration

People need to sign in to manage a workspace. Jobs need access that works without a person at a browser. Keycloak provides both user tokens and service-account tokens; workspace roles determine which API actions each caller can use. Storage policies control S3 object access.

## Login and workspace clients

Use a central public client, such as `workspace-api`, for user login to the API, UI, and shared session routes. For the notebooks, enable Device Authorization Grant and S256 PKCE on this client. A user signs in once and receives the roles for their workspaces.

Provider Datalab creates a separate confidential client for each workspace.
Its ID matches the Datalab name. It enables service accounts, browser login,
device login, and restricted user-token exchange. It limits role scope and
disables implicit and password grants.

| Resource | Example | Use |
| --- | --- | --- |
| Central public client | `workspace-api` | Browser and device login for people. |
| Workspace confidential client | `ws-alice` | Workspace roles and machine tokens. |
| User group | `ws-alice` | Assign `ws_access`. |
| Admin group | `ws-alice-admin` | Assign `ws_admin`. |
| OAuth client Secret | Resolved from `status.oauth2` | Supply the workspace client ID and secret to authorized callers. |

The client secret authenticates the workspace OAuth client. It supports service-account token requests and human device login. The STAC notebooks use Alice's login to obtain their workspace credentials.

## Roles

| Role | Workspace API access |
| --- | --- |
| `ws_access` | View workspace connections, OAuth client credentials, members, buckets, stores, sessions, and vclusters. |
| `ws_admin` | All user actions; manage members, buckets, stores, sessions, and vclusters; issue workspace tokens. |
| `ws_api` | Read storage and service connection credentials; no OAuth client credentials. |
| `admin` on `workspace-api` | Platform administration across workspaces, including workspace creation. |

The token-issuance permission is `ISSUE_TOKENS`; `ws_admin` includes it. The workspace service account has `ws_api` by default. This role cannot manage a workspace or open interactive browser routes.

A workspace role limits management actions. Members with access to the shared storage credentials use the same storage policy. [Bucket grants](../concepts.md#storage) control which other workspace buckets that identity can use.

## Token claims

The gateway checks the token signature, issuer, expiry, audience, and route policy. The Workspace API reads the validated bearer token:

- `aud` includes the API audience, normally `workspace-api`.
- `preferred_username` identifies the caller.
- `resource_access.<workspace>.roles` holds the workspace roles.
- `resource_access.workspace-api.roles` can hold the platform `admin` role.

This example gives Alice user access to one workspace and administrator access to another:

```json
{
  "aud": ["workspace-api"],
  "azp": "workspace-api",
  "preferred_username": "alice",
  "resource_access": {
    "ws-alice": {"roles": ["ws_access"]},
    "ws-bob": {"roles": ["ws_admin"]}
  }
}
```

For generated workspace clients, add the API audience through `EnvironmentConfig.data.iam.extraAudiences`. Configure the central user client to emit the required audiences and workspace roles as well. Refresh a user token after a new workspace or membership is created.

The Data S3 endpoint also requires the workspace name in `aud`. See [S3 clients](../concepts.md#s3-clients) for its signing values.

## Machine access

A client-credentials token identifies the workspace service account. It has `ws_api` under the workspace client roles and a username such as `service-account-ws-alice`.

Use OAuth client credentials for a scheduled upload or a task delegated to another service. The job requests a token with its client ID and secret, calls the Workspace API for storage credentials, and passes those credentials to its upload tool. No workspace team member needs to be present or sign in through a browser. The token needs the API audience and the target workspace's `ws_api` role.

The [STAC registration notebook](../getting-started/register-stac-metadata.ipynb) uses Alice's login to obtain storage credentials for Portolan uploads and stacpkg relocation. For a scheduled upload, use the machine-access flow above and get the client secret from the job's secret store. The first API's startup Secret supplies storage access until it switches to public HTTP metadata. The notebook's OCI publisher uses an internal Distribution Service in the workspace vCluster.

The API also has `/workspaces/<workspace-name>/token` for callers with
`ISSUE_TOKENS` or platform administration. Without `scope`, it returns a
workspace service-account token with `ws_api`. With configured profile scopes,
it exchanges the caller's user token for selected profile roles. See
[delegated access](../getting-started/vcluster-access.md#case-2-delegate-the-demo-profile-to-a-process).

## Virtual cluster access

The dashboard supplies connection settings separately from caller credentials.
Provider Datalab automatically grants workspace administrators `ws_admin`
and each configured instance's built-in vcluster administrator role.
Alice therefore already has `vcluster_vc0_cluster-admin`. She uses the
administrator profile for device login with her human identity; no separate
role assignment is needed. Current profiles request offline access and cache
the CLI login for up to 30 days, subject to Keycloak offline-session limits.
Notebook logins through the central public client have a separate lifetime.

For a process, Alice requests an exchanged token for one additional profile.
The recipient supplies that token through `DATALAB_ACCESS_TOKEN_FILE` and
uses the downloaded profile without a browser prompt. The token keeps Alice's
subject and selected roles. A namespace kubeconfig alone cannot restrict a
token that still has administrator roles.

Follow [Access a workspace virtual cluster](../getting-started/vcluster-access.md)
for UI downloads, token exchange, namespace checks, and login lifetimes. The
[Provider Datalab guide](https://github.com/versioneer-tech/provider-datalab/blob/main/docs/how-to-guides/vcluster.md)
describes the underlying profiles, cache, and revocation limits.

## Route protection

Protect the shared UI and session routes with the workspace roles in `resource_access`. A service owned by one workspace can use its confidential client and require the expected audience, client ID, and roles.

Provider Datalab supplies OAuth protection for the permanent Data browser. Public-share routes allow anonymous downloads. The read-only Data S3 endpoint validates its own signed requests and bearer tokens. Configure the Data issuer URLs in the [installation values](../getting-started/installation.md).
