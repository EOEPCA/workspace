# Workspace scripts

## S3 credentials

Use `s3-credentials.py` to get signing values and an OAuth token for read-only S3 access through the Data endpoint. See [S3 clients](../docs/concepts.md#s3-clients) for the access model and the [Vienna notebook](../docs/getting-started/vienna-imagery-with-stac-and-s3.ipynb) for download examples.

Configure the script as `credential_process` in `~/.aws/config`. AWS CLI and Boto3 can then get new tokens without changes to the application code. The script already returns the required JSON fields, including `Expiration`.

See [Automatic token renewal](../docs/concepts.md#automatic-token-renewal) for the profile setup, hidden client-secret prompt, and AWS CLI and Boto3 examples. The client secret stays in the terminal's `CLIENT_SECRET` setting; the AWS profile contains only the command and public service settings.
