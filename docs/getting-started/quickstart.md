# Quickstart

Create a workspace for Frank, share data with his team, and run MLflow and a STAC API in the Datalab.

## Environment assumptions

This guide uses the `eoepca-demo` cluster. Set up the [example accounts and permissions](https://github.com/EOEPCA/workspace/tree/main/setup), including the user `frank`, before starting.

| Setting | Example value |
| --- | --- |
| Object storage | MinIO |
| Session mode | `Auto`; `AlwaysOn` also works |
| Runtime | vCluster enabled with `vcluster: true`; namespace mode also works |
| Users | `alice`, `bob`, `eric`, and `frank` |
| Administrator | `oscar`, with the `admin` role on `workspace-api` |
| Existing workspaces | `ws-alice`, `ws-bob`, and `ws-eric` |

Alice, Bob, and Eric can manage their own workspaces. For another deployment, change the account names, workspace names, service URLs, and OAuth settings.

## 1. Create Frank's workspace

Sign in as Oscar through the [device login in the management notebook](../workspace-management.ipynb). Use the resulting `TOKEN` to create Frank's workspace:

```bash
curl -X POST "https://workspace-api.develop-v2.eoepca.org/workspaces" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "preferred_name": "frank",
    "default_owner": "frank"
  }'
```

The API returns the workspace URL:

```text
https://workspace-api.develop-v2.eoepca.org/workspaces/ws-frank
```

The configured prefix is `ws-`. Oscar gives the URL to Frank.

## 2. Open the workspace

Frank opens the URL and signs in. The dashboard shows `ws-frank`, its S3 credentials, and links to the Datalab and management pages.

![Frank's workspace dashboard](../img/q1.png)

## 3. Start the Datalab

Click Open Datalab. The session opens a code editor with Terminal, Editor, and Data tabs.

![Open the Datalab](../img/q2.png)

![Datalab editor](../img/q3.png)

List the buckets and Frank's objects from the terminal:

```bash
aws s3 ls
aws s3 ls s3://ws-frank --recursive
```

![List S3 buckets](../img/q4.png)

![List objects in Frank's bucket](../img/q5.png)

## 4. Run MLflow

Frank uses MLflow to track experiments and store model artifacts in `ws-frank`. Clone the example project:

```bash
git clone https://github.com/mlflow/mlflow-example
cd mlflow-example
```

![MLflow example project](../img/q6.png)

Convert the Conda dependencies to use `uv`, then run the example locally:

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

![Run the training example](../img/q7.png)

To use a shared MLflow server, apply the manifest from the Provider Datalab [additional services guide](https://provider-datalab.versioneer.at/latest/how-to-guides/additional_services/). The Datalab already has `kubectl` configured for its cluster.

![Deploy MLflow](../img/q8.png)

Forward the service port and open it from the editor's Ports tab:

```bash
kubectl port-forward svc/mlflow 5000:5000
```

![Forward the MLflow port](../img/q9.png)

![MLflow in the browser](../img/q10.png)

Point the training script at that server and run it again:

```bash
export MLFLOW_TRACKING_URI="http://localhost:5000"
export MLFLOW_EXPERIMENT_NAME="frank-experiment-1"
uv run python train.py
```

![Train against the shared server](../img/q11.png)

![MLflow experiment results](../img/q12.png)

Find the model in Frank's bucket on the Data tab. Create a [presigned link](../concepts.md#storage) to share it.

![Share a model artifact](../img/q13.png)

## 5. Set up buckets and team access

Frank creates two more buckets:

- `ws-frank-stagein` for data that Bob prepares.
- `ws-frank-publish` for finished datasets.

![Create buckets](../img/q15.png)

Frank adds Alice as a member of `ws-frank`. She can open the workspace, view its credentials, and work in the shared Datalab.

![Add Alice to the workspace](../img/q16.png)

Frank selects Request Access for `ws-eric-shared`. Eric approves the request, and Frank can then use his existing workspace credentials to read the reference data.

![Request access to Eric's bucket](../img/q17.png)

Bob requests write access to `ws-frank-stagein`. Once Frank approves it, Bob can upload data with his own workspace credentials.

![Approve Bob's bucket access](../img/q18.png)

## 6. Use managed services

Bob enables backing services in his Datalab configuration. Their connection settings appear on the dashboard.

![Bob's managed services](../img/q19.png)

![Service connection settings](../img/q20.png)

Bob uses this Datalab configuration:

```yaml
apiVersion: pkg.internal/v1beta2
kind: Datalab
metadata:
  name: ws-bob
  namespace: workspace
  labels:
    datalabs.pkg.internal/environment: datalab
spec:
  users:
    - bob
    - alice
  userOverrides:
    alice:
      grantedAt: "2025-10-15T08:08:53.953000+00:00"
      role: user
  secretName: ws-bob
  sessions:
    - name: default
      state: started
  vcluster: true
  data:
    enabled: true
  quota:
    memory: 18Gi
    storage: 10Gi
    budget: x-large
  registry:
    enabled: true
    storage: 3Gi
  documentStores:
    prod:
      storage: 1Gi
  cacheStores:
    prod:
      storage: 1Gi
  vectorStores:
    prod:
      storage: 1Gi
  databases:
    pg0:
      names:
        - dev
        - prod
      storage: 1Gi
      backupStorage: 10Gi
```

### Store scene metadata in MongoDB

Bob uses MongoDB to record scene metadata and processing status before he sends data to Frank.

The `prod` document store supplies `MONGO_PROD_URI` in the session environment. Libraries that need separate settings can use `MONGO_PROD_HOST`, `MONGO_PROD_PORT`, `MONGO_PROD_DATABASE`, `MONGO_PROD_USER`, `MONGO_PROD_PASSWORD`, and `MONGO_PROD_AUTH_SOURCE`.

Run this script in the Datalab terminal. It clears the selected collection before inserting two demo records:

```bash
cat > mongo_demo.py <<'PY'
import logging
import os
from datetime import datetime, timezone

from pymongo import MongoClient


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger("mongo-demo")

mongo_uri = os.environ["MONGO_PROD_URI"]
database_name = os.getenv("MONGO_PROD_DATABASE", "prod")
collection_name = os.getenv("MONGO_COLLECTION", "curation_demo")

log.info("connecting to MongoDB database=%s collection=%s", database_name, collection_name)

with MongoClient(mongo_uri) as client:
    db = client[database_name]

    if collection_name not in db.list_collection_names():
        db.create_collection(collection_name)
        log.info("created collection %s", collection_name)
    else:
        log.info("collection %s already exists", collection_name)

    collection = db[collection_name]
    collection.delete_many({})
    log.info("cleared previous demo documents")

    documents = [
        {
            "_id": "scene-a",
            "workspace": "ws-bob",
            "status": "prepared",
            "created_at": datetime.now(timezone.utc),
        },
        {
            "_id": "scene-b",
            "workspace": "ws-bob",
            "status": "queued",
            "created_at": datetime.now(timezone.utc),
        },
    ]

    result = collection.insert_many(documents)
    log.info("inserted %s documents: %s", len(result.inserted_ids), result.inserted_ids)

    for item in collection.find({}, {"_id": 1, "workspace": 1, "status": 1}).sort("_id"):
        log.info("found document: %s", item)

    delete_result = collection.delete_one({"_id": "scene-b"})
    log.info("deleted %s document with _id=scene-b", delete_result.deleted_count)

    remaining = list(collection.find({}, {"_id": 1, "workspace": 1, "status": 1}).sort("_id"))
    log.info("remaining documents: %s", remaining)
PY

uv run --with pymongo python mongo_demo.py
```

### Start a STAC API

Run `stac-fastapi-pgstac` against Bob's managed PostgreSQL database to serve a STAC catalogue.

For the `pg0` host and `prod` database, the session supplies `POSTGRES_PG0_HOST`, `POSTGRES_PG0_PORT`, `POSTGRES_PG0_USER`, `POSTGRES_PG0_PASSWORD`, and `POSTGRES_PG0_PROD_URL`.

Create the Service and Deployment:

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
              value: ${POSTGRES_PG0_HOST}
            - name: PGPORT
              value: "${POSTGRES_PG0_PORT}"
            - name: PGDATABASE
              value: prod
            - name: PGUSER
              value: ${POSTGRES_PG0_USER}
            - name: PGPASSWORD
              value: ${POSTGRES_PG0_PASSWORD}
          resources:
            requests: { cpu: "100m", memory: "256Mi" }
            limits:   { cpu: "500m", memory: "1Gi" }
EOF
```

Initialise the database:

```bash
kubectl run pgstac-migrate -it --rm \
  --image=ghcr.io/stac-utils/pgstac-pypgstac:v0.9.8 \
  --restart=Never \
  --env="PGHOST=${POSTGRES_PG0_HOST}" \
  --env="PGPORT=${POSTGRES_PG0_PORT}" \
  --env="PGDATABASE=prod" \
  --env="PGUSER=${POSTGRES_PG0_USER}" \
  --env="PGPASSWORD=${POSTGRES_PG0_PASSWORD}" \
  --command -- sh -lc 'pypgstac migrate'
```

Forward the API port and open it from the editor's Ports tab:

```bash
kubectl port-forward svc/stac-api 8080:8080
```

At `http://localhost:8080`, try these endpoints:

```text
/collections
/search
/collections/{id}/items
```

To remove the API Deployment and Service, run:

```bash
kubectl delete deploy stac-api
kubectl delete svc stac-api
```

The managed database remains available after the API is removed.

## Exchange data

Frank reads Eric's reference data and sends Bob a `.gpkg` file with the geometry and time range he needs. He can share the file from his bucket with a presigned link.

Bob selects the ground-truth data and copies it to `ws-frank-stagein`. He can use `aws s3 sync` or `rclone sync` from his Datalab.

Alice opens Frank's workspace and works with him in the Datalab. When the results are ready, Frank copies them from `ws-frank` to `ws-frank-publish`.

## Storage manifests

The bucket setup used above is defined by these Storage resources:

```yaml
apiVersion: pkg.internal/v1beta1
kind: Storage
metadata:
  name: ws-alice
  namespace: workspace
  labels:
    storages.pkg.internal/environment: datalab
spec:
  principal: ws-alice
  credentialsRollover:
    interval: weekly
    maxToKeep: 2
  buckets:
    - bucketName: ws-alice
      discoverable: true
    - bucketName: ws-alice-2
      discoverable: true
    - bucketName: ws-alice-3
      discoverable: true
  bucketAccessGrants:
    - bucketName: ws-alice-3
      grantee: ws-eric
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
  labels:
    storages.pkg.internal/environment: datalab
spec:
  principal: ws-bob
  buckets:
    - bucketName: ws-bob
      discoverable: true
      lifecycleRules:
        - target: tmp/*
          mode: Delete
          minAge: 12h
        - target: scratch/*
          mode: Notify
          minAge: 1w
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
  labels:
    storages.pkg.internal/environment: datalab
spec:
  principal: ws-eric
  buckets:
    - bucketName: ws-eric
      discoverable: true
    - bucketName: ws-eric-shared
      discoverable: true
  bucketAccessGrants:
    - bucketName: ws-eric-shared
      grantee: ws-alice
      permission: ReadWrite
      grantedAt: "2025-10-19T13:28:45.636000+00:00"
    - bucketName: ws-eric-shared
      grantee: ws-frank
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
  labels:
    storages.pkg.internal/environment: datalab
spec:
  principal: ws-frank
  buckets:
    - bucketName: ws-frank
      discoverable: true
    - bucketName: ws-frank-stagein
      discoverable: true
    - bucketName: ws-frank-publish
      discoverable: true
  bucketAccessGrants:
    - bucketName: ws-frank-stagein
      grantee: ws-bob
      permission: ReadWrite
      grantedAt: "2025-10-20T14:01:49.246000+00:00"
  bucketAccessRequests:
    - bucketName: ws-eric-shared
      reason: requesting access
      requestedAt: "2025-10-20T14:32:10.939000+00:00"
```
