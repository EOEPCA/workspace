"""Export the sample STAC collection to workspace object storage."""

import hashlib
import json
import os
import tempfile
from pathlib import Path

import boto3
import requests
from botocore.config import Config
from stac_geoparquet.arrow import parse_stac_items_to_arrow, to_parquet


def main():
    session = requests.Session()
    session.trust_env = False
    response = session.post(
        "http://catalog:8080/search",
        json={"collections": ["naip"], "limit": 100},
        timeout=60,
    )
    response.raise_for_status()
    result = response.json()
    if any(link.get("rel") == "next" for link in result.get("links", [])):
        raise ValueError("The sample export must fit in one page.")
    items = result["features"]
    if len(items) != 3:
        raise ValueError("The sample collection must contain three Items.")
    for item in items:
        item["links"] = []
    table = parse_stac_items_to_arrow(items).read_all()
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / "naip.parquet"
        to_parquet(table, path)
        content = path.read_bytes()
    digest = hashlib.sha256(content).hexdigest()
    storage = boto3.client(
        "s3",
        endpoint_url=os.environ["AWS_ENDPOINT_URL"],
        aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
        aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"],
        region_name=os.environ["AWS_REGION"],
        config=Config(signature_version="s3v4", s3={"addressing_style": "path"}),
    )
    key = "exports/naip.parquet"
    storage.put_object(
        Bucket=os.environ["WORKSPACE_BUCKET"], Key=key, Body=content,
        ContentType="application/vnd.apache.parquet", Metadata={"sha256": digest},
    )
    print(json.dumps({"rows": len(items), "key": key, "sha256": digest}))


if __name__ == "__main__":
    main()
