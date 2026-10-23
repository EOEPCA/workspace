"""Check the Helm output against the Storage and Datalab input contracts."""

from pathlib import Path
import subprocess
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[1]


def render(values=None):
    return subprocess.run(
        ["helm", "template", "workspace-pipeline", str(ROOT / "pipeline"), "-f", "-"],
        input=yaml.safe_dump(values or {}),
        capture_output=True,
        text=True,
        check=False,
    )


class PipelineTests(unittest.TestCase):
    def resources(self, values=None):
        result = render(values)
        self.assertEqual(result.returncode, 0, result.stderr)
        return list(yaml.safe_load_all(result.stdout))

    def environment(self, values=None):
        return next(
            item for item in self.resources(values)
            if item["kind"] == "EnvironmentConfig"
        )["data"]

    def test_default_exposure_is_disabled(self):
        data = self.environment()
        self.assertIs(data["ingress"]["enabled"], False)
        self.assertEqual(data["httpRoute"], {"enabled": False, "enableS3": False})
        self.assertNotIn("auth", data)
        self.assertNotIn("database", data)

    def test_storage_force_path_style_uses_camel_case(self):
        for value in (True, False):
            with self.subTest(value=value):
                storage = self.environment({"environmentconfig": {
                    "storage": {"forcePathStyle": value},
                }})["storage"]
                self.assertEqual(storage["forcePathStyle"], str(value).lower())
                self.assertNotIn("force_path_style", storage)

    def test_gateway_and_database_routes_are_independent(self):
        route = {
            "enabled": True,
            "enableS3": True,
            "parentName": "public",
            "parentNamespace": "gateway",
            "sectionName": "workspaces-https",
            "httpSectionName": "http",
        }
        database = {"tlsRoute": {
            "parentName": "public",
            "parentNamespace": "gateway",
            "sectionName": "postgres",
        }, "storageClassName": "fast", "backupStorageClassName": "backup"}
        data = self.environment({"environmentconfig": {
            "httpRoute": route, "database": database,
        }})
        self.assertEqual(data["httpRoute"], route)
        self.assertEqual(data["database"], database)
        self.assertNotIn("gateway", data["database"])

    def test_ingress_exposure_still_works(self):
        data = self.environment({"environmentconfig": {"ingress": {
            "enabled": True, "annotations": {"example.org/setting": "value"},
        }}})
        self.assertIs(data["ingress"]["enabled"], True)
        self.assertEqual(data["ingress"]["annotations"], {"example.org/setting": "value"})
        self.assertIs(data["httpRoute"]["enabled"], False)

    def test_conflicting_exposure_modes_fail(self):
        result = render({"environmentconfig": {
            "ingress": {"enabled": True}, "httpRoute": {"enabled": True},
        }})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Enable only one", result.stderr)

    def test_s3_requires_http_route(self):
        result = render({"environmentconfig": {"httpRoute": {"enableS3": True}}})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("enableS3 requires", result.stderr)

    def test_existing_policy_and_lifecycle_settings_are_preserved(self):
        settings = {
            "storage": {"lifecycle": {"schedule": "17 2 * * *"}},
            "defaults": {"security": {"externalEgress": False, "kubernetesAccess": False}},
            "network": {"internalEgress": [{
                "namespace": "storage",
                "podSelector": {"matchLabels": {"app": "minio"}},
                "ports": [{"protocol": "TCP", "port": 9000}],
            }]},
        }
        data = self.environment({"environmentconfig": settings})
        self.assertEqual(data["storage"]["lifecycle"], settings["storage"]["lifecycle"])
        self.assertEqual(data["defaults"], settings["defaults"])
        self.assertEqual(data["network"]["internalEgress"], settings["network"]["internalEgress"])

    def test_default_packages_use_release_tags(self):
        resources = self.resources()
        packages = {item["spec"]["package"] for item in resources if item["kind"] == "Configuration"}
        self.assertEqual(packages, {
            "ghcr.io/versioneer-tech/provider-storage/minio:0.4.0",
            "ghcr.io/versioneer-tech/provider-datalab/educates:0.11.0",
        })


if __name__ == "__main__":
    unittest.main()
