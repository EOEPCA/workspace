# IAM integration

People need to sign in to manage a workspace. Jobs need access that works without a person at a browser. Keycloak provides both user tokens and service-account tokens; workspace roles determine which API actions each caller can use. Storage policies control S3 object access.

## Login and workspace clients

Use a central public client, such as `workspace-api`, for user login to the API, UI, and shared session routes. For Workspace Management and the Vienna notebook, enable Device Authorization Grant and S256 PKCE on this client. A user signs in once and receives the roles for their workspaces.

Provider Datalab creates a separate confidential client for each workspace. Its ID matches the Datalab name. It enables service accounts and browser login, limits role scope, and disables implicit, password, and device grants.

| Resource | Example | Use |
| --- | --- | --- |
| Central public client | `workspace-api` | Browser and device login for people. |
| Workspace confidential client | `ws-alice` | Workspace roles and machine tokens. |
| User group | `ws-alice` | Assign `ws_access`. |
| Admin group | `ws-alice-admin` | Assign `ws_admin`. |
| Runtime Secret | `ws-alice-oauth2-client` | Supply `client_id` and `client_secret` to services. |

The runtime Secret is a machine credential. A caller who can read it can request a service-account token for that workspace. The STAC registration notebook uses client credentials to show how an upload can run without user login.

## Roles

| Role | Workspace API access |
| --- | --- |
| `ws_access` | View storage credentials, members, buckets, resource usage, stores, and sessions. |
| `ws_admin` | All user actions; manage members, buckets, stores, and sessions; request machine tokens. |
| `ws_api` | View workspace storage credentials. Assigned to the workspace client service account. |
| `admin` on `workspace-api` | Platform administration across workspaces, including workspace creation. |

The resource-usage permission is `VIEW_RESOURCE_USAGE`. The machine-token permission is `ISSUE_TOKENS`; `ws_admin` includes both. The service-account role `ws_api` cannot manage a workspace or open interactive browser routes.

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

The [STAC registration notebook](../getting-started/register-stac-metadata.ipynb) uses this path for Portolan uploads and stacpkg relocation. The first API's startup Secret supplies storage access until it switches to public HTTP metadata. For a job, replace the prompts with job settings and a client secret from its secret store. OCI publishing uses separate registry credentials.

The API also has `/workspaces/<workspace-name>/token` for callers with `ISSUE_TOKENS` or platform administration. That route returns a workspace machine token. It does not replace user login.

## Route protection

Protect the shared UI and session routes with the workspace roles in `resource_access`. A service owned by one workspace can use its confidential client and require the expected audience, client ID, and roles.

Provider Datalab supplies OAuth protection for the permanent Data browser. Public-share routes allow anonymous downloads. The read-only Data S3 endpoint validates its own signed requests and bearer tokens. Configure the Data issuer URLs in the [installation values](../getting-started/installation.md).
