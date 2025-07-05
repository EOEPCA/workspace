# Workspace Storage Layer API Documentation

This document provides example API calls for the Workspace Storage Layer API.

Note: `ws_example_1` to be replaced with concret workspace team name as the Workspace Storage Layer API is deployed per project team.

## Example API Calls

1. Login

```bash
curl -X GET -H "Content-Type: application/json" -d '{"username": "default", "password": "changeme"}' https://ws_example_1.apx.develop.eoepca.org/api/login
```

This call sends a GET request to the /login endpoint with the username and password in the request body. A successful response (200 OK) will return a JWT token in the response body. Save this token; it's required for subsequent authenticated requests.

2. Create Share Link
```bash
curl -X POST -H "x-auth: <token>" https://ws_example_1.apx.develop.eoepca.org/api/share/sources/application-package/s-expression/s-expression-0_0_2.cwl
```

This call creates a share link for file at the specified file path, here with `application-package/s-expression/s-expression-0_0_2.cwl` as example path. It's a POST request to the /share/sources/{path} endpoint. The Authorization header includes the JWT token obtained from the login step. Replace <YOUR_JWT_TOKEN> with your actual token.

Example response:
`{"hash":"KjtmA0Bu","path":"/sources/ws-example-1736871929/application-package/s-expression/s-expression-0_0_2.cwl","userID":1,"expire":0,"creationTime":1736871971}`

3. Resolve Share Link (Download)
```bash
curl -X GET https://ws_example_1.apx.develop.eoepca.org/api/public/dl/KjtmA0Bu?inline=true
```
This call resolves a share link, identified by the hash KjtmA0Bu, and initiates a download. It's a GET request to the /public/dl/{hash} endpoint, replacing {hash} with the share link's hash. The `inline=true` query parameter suggests an inline download. If `inline=false` The response will be a HTTP 302 and contain a Location header with the presigned URL for downloading the file.