"""Push and verify a STAC package in the workspace's internal registry."""

import argparse
import hashlib
import json
import re
from pathlib import Path

import requests
import stacpkg.oci as registry
from oras.client import OrasClient


def internal_client(*, plain_http=False, insecure=False, auth_backend="basic"):
    if not plain_http or insecure or auth_backend != "basic":
        raise ValueError("Use the internal HTTP registry with Basic client mode.")
    client = OrasClient(insecure=True, auth_backend="basic")
    # The demo registry has no login. Do not load a saved Docker login.
    client.auth._auth_config = {"auths": {}}
    client.session.trust_env = False
    return client


def hashes(directory):
    return {
        path.name: hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(directory.iterdir())
        if path.is_file() and path.name != "manifest.json"
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=["push", "pull"])
    parser.add_argument("reference")
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    host, repository = args.reference.split("/", 1)
    if not re.fullmatch(r"[a-z0-9-]+\.[a-z0-9-]+\.svc\.cluster\.local:5000", host):
        raise ValueError("Select a registry Service inside the workspace vCluster.")

    # stacpkg has no public client argument. Keep this adapter with its pin.
    registry._oras_client = internal_client
    options = {"plain_http": True, "auth_backend": "basic"}
    if args.operation == "pull":
        registry.pull_package(args.reference, args.directory, **options)
        print("PACKAGE_HASHES=" + json.dumps(hashes(args.directory)), flush=True)
        return

    expected = hashes(args.directory)
    registry.push_package(args.directory, args.reference, **options)
    repository, tag = repository.rsplit(":", 1)
    with requests.Session() as session:
        session.trust_env = False
        response = session.head(
            f"http://{host}/v2/{repository}/manifests/{tag}",
            headers={"Accept": "application/vnd.oci.image.manifest.v1+json"},
            timeout=30,
            allow_redirects=False,
        )
        response.raise_for_status()
        digest = response.headers.get("Docker-Content-Digest", "")
    if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
        raise ValueError("The registry returned no SHA-256 manifest digest.")
    reference = f"{host}/{repository}@{digest}"
    pulled = args.directory.parent / "pulled-package"
    registry.pull_package(reference, pulled, **options)
    actual = hashes(pulled)
    if actual != expected:
        raise ValueError("The pulled package differs from the input package.")
    print("OCI_RESULT=" + json.dumps({"reference": reference, "hashes": actual}), flush=True)


if __name__ == "__main__":
    main()
