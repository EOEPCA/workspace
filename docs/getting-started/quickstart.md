# Quickstart

This guide walks through a fictive end-to-end scenario to be executed on the `eoepca-demo` Kubernetes cluster to demonstrate the capabilities of the **Workspace** Building Block (BB). It highlights the roles of different personas — **operator**, **manager**, and **user** — and covers workspace creation, member management, data sharing on Object **Storage**, and collaborative use of the runtime in so called **Datalabs**.

## Environment Assumptions

- **Object Storage:** MinIO (S3 compatible). Alternatives (AWS S3, OTC OBS, …) work the same.
- **Session Mode:** `Auto` (on-demand start/stop). `AlwaysOn` also works for this guide.
- **Isolation Mode:** `useVcluster=true` (workspace-scoped vcluster). Namespace mode would also work here.
- **Users in Keycloak:** `alice`, `bob`, `eric`, `frank`; platform operator `oscar` (has `admin` role on the Workspace client).
- **Existing Workspaces:** `ws-alice`, `ws-bob`, `ws-eric`.

## Scenario

**Frank** is prototyping a **data-driven AI workflow**. He needs:

- A **workspace** with a VS Code like runtime to develop and and buckets for storage.
- **Alice** as a collaborator (co-development).
- Read access to **Bob’s** shared reference data.
- A way to let **Eric** stage subsets of large ground-truth data into Frank’s workspace.
- **MLflow** for experiment tracking, with model artifacts stored in Frank’s bucket.
- A clear **separation of storage buckets**, each potentially holding data ranging from gigabytes to terabytes.

Personas:

- **Oscar** — platform operator, provisions the workspace.
- **Frank** — workspace owner.
- **Alice** — collaborator in Frank’s workspace.
- **Eric** — provides a shared reference bucket.
- **Bob** — curates large datasets and stages subsets for Frank. He also uses the managed database instance of his workspace to keep track of what has been prepared and delivered.

### 1) Oscar: Creating a Workspace for Frank

Oscar sets up a new workspace for Frank using an **HTTP API–driven approach**, enabling seamless integration into the existing workflows of the platform operations team.

> The same setup can alternatively be created directly via the **Kubernetes API** (e.g., using `kubectl`).

After authenticating (e.g., through the **OAuth2 Device Code Flow** to obtain a `TOKEN`; see [Operator View](https://eoepca.readthedocs.io/projects/workspace/en/latest/getting-started/operator-view/)), Oscar initiates the workspace creation request:

```bash
curl -X POST "https://workspace-api.develop.eoepca.org/workspaces" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "preferred_name": "frank",
    "default_owner": "frank"
  }'
```

**Expected result:**  
The API returns a workspace URL such as:

```
https://workspace-api.develop.eoepca.org/workspaces/ws-frank
```

(where `ws-` is the configured prefix for workspace names).

Oscar then shares this URL with Frank.

### 2) Frank: Open the Workspace and verify access

1. Frank opens the URL in a browser and logs in.  
2. The **Workspace Dashboard** displays:

   - Workspace details (`ws-frank`)
   - Default **S3 bucket credentials** (for `ws-frank`)
   - Links to the **Datalab** and management pages`

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q1.png)

### 3) Frank: Start the Datalab and explore the environment

1. Click **Open Datalab**.  
2. After the session starts, Frank sees a familiar **VS Code** interface: **Terminal**, **Editor**, and a **Data** tab.

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q2.png)

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q3.png)

**Verify S3 connectivity in Datalab terminal:**

```bash
aws s3 ls
aws s3 ls s3://ws-frank --recursive
```

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q4.png)

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q5.png)

### 4) Frank: Use MLflow in the Datalab environment as Additional Service

Frank wants MLflow for experiment tracking (artifacts to go to `ws-frank`).

**Clone an example project:**
```bash
git clone https://github.com/mlflow/mlflow-example
cd mlflow-example
```

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q6.png)

**Run example project with local MLflow:**

> Note: Frank prefers to use `uv` over conda so he has to convert the environment file

```bash
yq eval -o=json '.dependencies[]' conda.yaml | jq -r '
  if type=="string" then .
  elif has("pip") then .pip[]
  else empty end
' > requirements.txt

uv venv
uv pip install -r requirements.txt
uv run python train.py
```

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q7.png)

That worked successfully, but so far MLflow is only running in a local development shell. Next, it will be deployed as an additional service within the workspace.

**Deploy MLflow Server and Run Example Project Again**

Since `kubectl` is already preinstalled and configured for the connected Kubernetes cluster, we can simply apply the manifest (for example, the one provided in the [documentation](https://provider-datalab.versioneer.at/latest/how-to-guides/additional_services/)).

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q8.png)

Next, **port-forward the MLflow service** so that it appears in the **Ports** tab, allowing direct access to the MLflow UI in the browser.

```bash
kubectl port-forward svc/mlflow 5000:5000
```

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q9.png)

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q10.png)

Now, point to the newly deployed MLflow server and run the example project again:

```bash
export MLFLOW_TRACKING_URI="http://localhost:5000"
export MLFLOW_EXPERIMENT_NAME="frank-experiment-1"
uv run python train.py
```

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q11.png)

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q12.png)


The trained model is  stored as an **MLflow artifact** in a bucket within **Frank’s workspace**. Frank can also navigate to the **Data** tab of the Datalab environment, locate the artifacts, and share specific files — for example, the `.pkl` file with the model — via a **presigned URL**.  This allows others to download the (potentially large) ML model directly from the bucket using a **temporary access link**, without requiring permanent credentials.

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q13.png)

Confident that the Datalab can support his prototype development, Frank now turns to planning how best to structure storage and manage access.

### 5) Frank: Prepare storage layout for collaboration

Frank begins by creating two additional buckets to organize data exchange and publication:

- `ws-frank-stagein` — to be used by **Bob** to stage curated data subsets (e.g., filtered by geometry or time).  
- `ws-frank-publish` — used by **Frank** himself to store and share finalized datasets with others.

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q15.png)

Frank then adds **Alice** as a member of `ws-frank`, granting her access to all workspace resources.

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q16.png)

With these permissions in place, **Alice** can now open **Frank’s workspace**, view the necessary credentials, and collaborate with him in the shared Datalab environment.

Next, **Frank** requests access to `ws-eric-shared` to use Eric’s reference data.

- In the **Workspace UI**, he selects **Request Access** for the desired bucket.  
- **Eric** then **approves** the request.  
- Once approved, **Frank** can access `ws-eric-shared` seamlessly using his existing credentials.

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q17.png)

Frank also notices that **Bob** has submitted a request to access `ws-frank-stagein`.  Frank reviews and **approves** the request.From that moment on, **Bob** can access `ws-frank-stagein` seamlessly using his existing credentials — unless **Frank** later decides to **revoke** the permission.

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q18.png)

### 6) Bob: Connects stac-fastapi-pgstac to the managed database instance of his workspace

Bob has created several managed PostgreSQL database instances via the **Workspace UI**.

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q19.png)

Using the database credentials exposed on his dashboard page, he can directly connect applications such as **stac-fastapi-pgstac** to a database inside his workspace.

![alt text](https://github.com/EOEPCA/workspace/raw/refs/heads/main/docs/img/q20.png)

Each workspace exposes ready-to-use environment variables like `DATABASE_HOST`, `DATABASE_USER`, `DATABASE_PASSWORD` and similar. This allows applications to connect immediately without additional configuration.

> Note: The Postgres endpoint is exposed through Envoy, which requires immediate TLS with SNI (direct TLS). The PostgreSQL server and libpq-based clients (e.g. psql, psycopg) fully support this. However, some non-libpq drivers such as asyncpg do not yet implement this negotiation correctly and may fail during connection setup.

Bob uses **stac-fastapi-pgstac** to catalog curated datasets and expose them through a STAC API. Because he does not need the service running permanently, he starts it **on demand** inside the Datalab only when required.

First, apply the following manifests to the Kubernetes cluster.

```bash
envsubst <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: stac-api
spec:
  selector:
    app: stac-api
  ports:
    - name: http
      port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stac-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: stac-api
  template:
    metadata:
      labels:
        app: stac-api
    spec:
      containers:
        - name: api
          image: ghcr.io/stac-utils/stac-fastapi-pgstac:6.2.0
          ports:
            - containerPort: 8080
          env:
            - name: PGHOST
              value: ${DATABASE_HOST}
            - name: PGPORT
              value: "${DATABASE_PORT}"
            - name: PGDATABASE
              value: ${DATABASE_NAME}
            - name: PGUSER
              value: ${DATABASE_USER}
            - name: PGPASSWORD
              value: ${DATABASE_PASSWORD}
          resources:
            requests: { cpu: "100m", memory: "256Mi" }
            limits:   { cpu: "500m", memory: "1Gi" }
EOF
```

Next, **port-forward the stac-fastapi-pgstac service** so that it appears in the **Ports** tab, allowing direct access to the service in the browser.

```bash
kubectl port-forward svc/stac-api 8080:8080
```

Now you can open `http://localhost:8080` and browse common endpoints like

```
/collections
/search
/collections/{id}/items
```

To cleanup, run

```bash
kubectl delete deploy stac-api
kubectl delete svc stac-api
```

This keeps the service **ephemeral and cost-efficient** while still benefiting from a fully managed database that provides persistence and automated backups.

## Summary

With the storage setup in place, everyone now understands where data should reside, and the collaboration begins.

- **Frank** downloads the necessary reference data from the `ws-eric-shared` bucket to start refining his prototype.  
- He then shares the **selection criteria** (e.g., geometry and time range) with **Bob** by preparing them online and placing the corresponding `.gpkg` file in his bucket.  
  Frank can simply send a **presigned URL** to Bob’s team for direct access.  
- **Bob** subsequently copies the relevant **ground-truth data** into `ws-frank-stagein`.

> **Note:**  
> Since **Bob** is also using Workspaces, he can easily perform this transfer using preinstalled tools such as `aws s3 sync` or `rclone sync`, ensuring efficient data movement.

- **Alice** continues working collaboratively in the shared **Datalab**, starting her browser session directly from  
  [https://workspace-api.develop.eoepca.org/workspaces/ws-frank](https://workspace-api.develop.eoepca.org/workspaces/ws-frank).  

- Once the prototype is complete and the first data products are generated, **Frank** synchronizes results from `ws-frank` to `ws-frank-publish`, ensuring a clear separation between **working**, **staging**, and **published** data.

## Bonus Section for Operators

The entire **storage configuration** is captured **declaratively** within the Kubernetes cluster. From there, it is continuously managed by **reconciliation engines** that enforce the desired state and ensure the setup remains consistent with the defined specification.

The relevant portion of the **storage manifest** can be found directly after this quickstart, providing operators with a clear view of how the workspace and its associated buckets are provisioned and maintained.

```yaml
apiVersion: pkg.internal/v1beta1
kind: Storage
metadata:
  name: ws-alice
  namespace: workspace
spec:
  principal: alice
  buckets:
    - bucketName: ws-alice
      discoverable: true
    - bucketName: ws-alice-2
      discoverable: true
    - bucketName: ws-alice-3
      discoverable: true
  bucketAccessGrants:
    - bucketName: ws-alice-3
      grantee: eric
      permission: ReadWrite
      grantedAt: "2025-10-14T08:09:10.817000+00:00"
  bucketAccessRequests:
    - bucketName: ws-eric-shared
      reason: requesting access
      requestedAt: "2025-10-19T13:25:59.655000+00:00"
---
apiVersion: pkg.internal/v1beta1
kind: Storage
metadata:
  name: ws-bob
  namespace: workspace
spec:
  principal: bob
  buckets:
    - bucketName: ws-bob
      discoverable: true
  bucketAccessGrants: []
  bucketAccessRequests:
    - bucketName: ws-frank-stagein
      reason: requesting access
      requestedAt: "2025-10-20T14:00:05.494000+00:00"
---
apiVersion: pkg.internal/v1beta1
kind: Storage
metadata:
  name: ws-eric
  namespace: workspace
spec:
  principal: eric
  buckets:
    - bucketName: ws-eric
      discoverable: true
    - bucketName: ws-eric-shared
      discoverable: true
  bucketAccessGrants:
    - bucketName: ws-eric-shared
      grantee: alice
      permission: ReadWrite
      grantedAt: "2025-10-19T13:28:45.636000+00:00"
    - bucketName: ws-eric-shared
      grantee: frank
      permission: ReadWrite
      grantedAt: "2025-10-20T14:32:22.153000+00:00"
  bucketAccessRequests:
    - bucketName: ws-alice-3
      reason: requesting access
      requestedAt: "2025-10-14T08:08:53.953000+00:00"
---
apiVersion: pkg.internal/v1beta1
kind: Storage
metadata:
  name: ws-frank
  namespace: workspace
spec:
  principal: frank
  buckets:
    - bucketName: ws-frank
      discoverable: true
    - bucketName: ws-frank-stagein
      discoverable: true
    - bucketName: ws-frank-publish
      discoverable: true
  bucketAccessGrants:
    - bucketName: ws-frank-stagein
      grantee: bob
      permission: ReadWrite
      grantedAt: "2025-10-20T14:01:49.246000+00:00"
  bucketAccessRequests:
    - bucketName: ws-eric-shared
      reason: requesting access
      requestedAt: "2025-10-20T14:32:10.939000+00:00"

```