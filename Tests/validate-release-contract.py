#!/usr/bin/env python3
import plistlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / "PowerMesh.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")
testing_en = (ROOT / "docs/TESTING.md").read_text(encoding="utf-8")
testing_es = (ROOT / "docs/TESTING.es.md").read_text(encoding="utf-8")

versions = set(re.findall(r"MARKETING_VERSION = ([0-9.]+);", project))
builds = set(re.findall(r"CURRENT_PROJECT_VERSION = ([0-9]+);", project))
if len(versions) != 1 or len(builds) != 1:
    raise SystemExit(f"version contract failed: versions={sorted(versions)} builds={sorted(builds)}")

version = next(iter(versions))
build = next(iter(builds))

if f"**Current `main`: {version} (build {build}).**" not in readme:
    raise SystemExit("version contract failed: English README status is stale")
if f"**`main` actual: {version} (build {build}).**" not in readme:
    raise SystemExit("version contract failed: Spanish README status is stale")

if not testing_en.startswith(f"# PowerMesh {version} "):
    raise SystemExit("version contract failed: English physical test plan is stale")
if not testing_es.startswith(f"# PowerMesh {version} "):
    raise SystemExit("version contract failed: Spanish physical test plan is stale")

if "CODE_SIGN_ENTITLEMENTS = PowerMesh/PowerMesh.entitlements;" not in project:
    raise SystemExit("CloudKit contract failed: main target entitlements are not wired")
if "CODE_SIGN_ENTITLEMENTS = PowerMesh/PowerMeshWatch.entitlements;" not in project:
    raise SystemExit("CloudKit contract failed: Watch target entitlements are not wired")

if 'name = DebugLocal;' not in project:
    raise SystemExit("local-test contract failed: DebugLocal configuration is missing")
if 'POWERMESH_LOCAL_ONLY' not in project:
    raise SystemExit("local-test contract failed: POWERMESH_LOCAL_ONLY is not configured")
if 'PRODUCT_BUNDLE_IDENTIFIER = com.tiburonns.PowerMesh.local;' not in project:
    raise SystemExit("local-test contract failed: local bundle identifier is missing")
if 'F11000000000000000000003 /* DebugLocal */' in project:
    debug_local = project.split(
        'F11000000000000000000003 /* DebugLocal */', 1
    )[1].split('name = DebugLocal;', 1)[0]
    if "CODE_SIGN_ENTITLEMENTS" in debug_local:
        raise SystemExit(
            "local-test contract failed: DebugLocal must not require CloudKit entitlements"
        )

cloud_store = (
    ROOT / "PowerMesh/Services/CloudBatteryStore.swift"
).read_text(encoding="utf-8")
if "FileManager.default.ubiquityIdentityToken" in cloud_store:
    raise SystemExit(
        "CloudKit contract failed: CloudKit availability must not depend on iCloud Drive"
    )
if "CKContainer(identifier: Self.containerIdentifier)" not in cloud_store:
    raise SystemExit(
        "CloudKit contract failed: the declared private container is not selected explicitly"
    )
if "accountStatus()" not in cloud_store:
    raise SystemExit(
        "CloudKit contract failed: account availability is not checked with CloudKit"
    )

def load(path):
    with path.open("rb") as handle:
        return plistlib.load(handle)

main_entitlements = load(ROOT / "PowerMesh/PowerMesh.entitlements")
watch_entitlements = load(ROOT / "PowerMesh/PowerMeshWatch.entitlements")

expected_container = ["iCloud.com.tiburonns.PowerMesh"]
expected_services = ["CloudKit"]

for label, entitlements in [
    ("main", main_entitlements),
    ("watch", watch_entitlements),
]:
    if entitlements.get("com.apple.developer.icloud-container-identifiers") != expected_container:
        raise SystemExit(f"CloudKit contract failed: {label} container mismatch")
    if entitlements.get("com.apple.developer.icloud-services") != expected_services:
        raise SystemExit(f"CloudKit contract failed: {label} service mismatch")

privacy = load(ROOT / "PowerMesh/PrivacyInfo.xcprivacy")
if privacy.get("NSPrivacyTracking") is not False:
    raise SystemExit("privacy contract failed: tracking must be false")

reasons = {}
for item in privacy.get("NSPrivacyAccessedAPITypes", []):
    reasons[item.get("NSPrivacyAccessedAPIType")] = set(
        item.get("NSPrivacyAccessedAPITypeReasons", [])
    )
if "CA92.1" not in reasons.get("NSPrivacyAccessedAPICategoryUserDefaults", set()):
    raise SystemExit("privacy contract failed: UserDefaults reason CA92.1 is missing")

hardcoded_teams = [
    value for value in re.findall(r"DEVELOPMENT_TEAM = ([^;]+);", project)
    if value.strip().strip('"')
]
if hardcoded_teams:
    raise SystemExit(f"build contract failed: hardcoded Apple team(s): {hardcoded_teams}")

print(
    f"PASS: PowerMesh {version} (build {build}) version, bilingual docs, "
    "CloudKit entitlements, and privacy contract"
)
