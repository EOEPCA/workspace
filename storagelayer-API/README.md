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

# Runtime Privileges

The workspace BB adheres to the principle of delegating runtime privilege management to the virtual cluster. As a result, applications like `code-server` are not started in privileged mode and must comply with the security policies enforced within the vCluster — that is, whatever restrictions apply to the vCluster also apply transparently to its workloads.

To verify that containers are running without elevated privileges, the following checks can be performed:

```bash
getpcaps 1
```

Checks whether the main process has any assigned Linux capabilities (e.g., `CAP_SYS_ADMIN`, `CAP_NET_ADMIN`).

```bash
capsh --print
```

Displays the current, bounding, and permitted capabilities of the container process.

```bash
mkdir /tmp/mnt
mount -t tmpfs tmpfs /tmp/mnt
```

Attempts to mount a temporary filesystem. This will fail unless the container has `CAP_SYS_ADMIN`, making it a useful check for privileged access.

```bash
sudo
```

Typical output:
```
sudo: The "no new privileges" flag is set, which prevents sudo from running as root.
```

Indicates that `sudo` is blocked due to the `no_new_privileges` flag, a common hardening measure in Kubernetes environments that prevents privilege escalation.


**Note**: As we inject the `KUBECONFIG` into the `code-server` pod, it is still possible to start processes in a Docker-like style:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl
mkdir -p ~/.local/bin/
mv kubectl ~/.local/bin/

kubectl run hello-server --image=nginx
kubectl expose pod hello-server --port=8080 --type=NodePort
kubectl expose pod hello-server --port=8080 --target-port=80 --type=NodePort
curl http://hello-server:8080
```

Please refer to our design considerations on ingress in the [docs](https://eoepca.readthedocs.io/projects/workspace/en/latest/design/vcluster/#networking-and-ingress-design).

Our envisioned approach allows the platform operator to set up a shared gateway within the vCluster. This gateway may then be exposed by the platform operator via ingress externally, enabling end-users inside the cluster to register their services on the gateway still allowing them to be publically exposed.