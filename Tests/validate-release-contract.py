#!/usr/bin/env python3
import plistlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / "PowerMesh.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")
testing_en = (ROOT / "docs/TESTING.md").read_text(encoding="utf-8")
testing_es = (ROOT / "docs/TESTING.es.md").read_text(encoding="utf-8")


def fail(message):
    raise SystemExit(message)


def load(path):
    with path.open("rb") as handle:
        return plistlib.load(handle)


versions = set(re.findall(r"MARKETING_VERSION = ([0-9.]+);", project))
builds = set(re.findall(r"CURRENT_PROJECT_VERSION = ([0-9]+);", project))
if len(versions) != 1 or len(builds) != 1:
    fail(f"version contract failed: versions={sorted(versions)} builds={sorted(builds)}")

version = next(iter(versions))
build = next(iter(builds))

if f"**Current `main`: {version} (build {build}).**" not in readme:
    fail("version contract failed: English README status is stale")
if f"**`main` actual: {version} (build {build}).**" not in readme:
    fail("version contract failed: Spanish README status is stale")
if not testing_en.startswith(f"# PowerMesh {version} "):
    fail("version contract failed: English physical test plan is stale")
if not testing_es.startswith(f"# PowerMesh {version} "):
    fail("version contract failed: Spanish physical test plan is stale")

# Main/Watch CloudKit + App Group.
main_entitlements = load(ROOT / "PowerMesh/PowerMesh.entitlements")
main_release_entitlements = load(ROOT / "PowerMesh/PowerMeshRelease.entitlements")
watch_entitlements = load(ROOT / "PowerMesh/PowerMeshWatch.entitlements")
watch_release_entitlements = load(ROOT / "PowerMesh/PowerMeshWatchRelease.entitlements")
mac_entitlements = load(ROOT / "PowerMesh/PowerMeshMac.entitlements")
mac_release_entitlements = load(ROOT / "PowerMesh/PowerMeshMacRelease.entitlements")
widget_entitlements = load(ROOT / "PowerMeshWidgets/PowerMeshWidgets.entitlements")
widget_mac_entitlements = load(ROOT / "PowerMeshWidgets/PowerMeshWidgetsMac.entitlements")
watch_widget_entitlements = load(ROOT / "PowerMeshWidgets/PowerMeshWatchWidgets.entitlements")

expected_container = ["iCloud.com.tiburonns.PowerMesh"]
expected_services = ["CloudKit"]
expected_group = ["group.com.tiburonns.PowerMesh"]

for label, entitlements in [
    ("main-debug", main_entitlements),
    ("main-release", main_release_entitlements),
    ("watch-debug", watch_entitlements),
    ("watch-release", watch_release_entitlements),
    ("mac-debug", mac_entitlements),
    ("mac-release", mac_release_entitlements),
]:
    if entitlements.get("com.apple.developer.icloud-container-identifiers") != expected_container:
        fail(f"CloudKit contract failed: {label} container mismatch")
    if entitlements.get("com.apple.developer.icloud-services") != expected_services:
        fail(f"CloudKit contract failed: {label} service mismatch")
    if entitlements.get("com.apple.security.application-groups") != expected_group:
        fail(f"App Group contract failed: {label} group mismatch")

for label, entitlements, environment in [
    ("main-debug", main_entitlements, "Development"),
    ("watch-debug", watch_entitlements, "Development"),
    ("mac-debug", mac_entitlements, "Development"),
    ("main-release", main_release_entitlements, "Production"),
    ("watch-release", watch_release_entitlements, "Production"),
    ("mac-release", mac_release_entitlements, "Production"),
]:
    if entitlements.get("com.apple.developer.icloud-container-environment") != environment:
        fail(f"CloudKit environment contract failed: {label} must use {environment}")

for label, entitlements, environment in [
    ("main-debug", main_entitlements, "development"),
    ("watch-debug", watch_entitlements, "development"),
    ("main-release", main_release_entitlements, "production"),
    ("watch-release", watch_release_entitlements, "production"),
]:
    if entitlements.get("aps-environment") != environment:
        fail(f"APNs contract failed: {label} must use {environment}")

for label, entitlements, environment in [
    ("mac-debug", mac_entitlements, "development"),
    ("mac-release", mac_release_entitlements, "production"),
]:
    if entitlements.get("com.apple.developer.aps-environment") != environment:
        fail(f"APNs contract failed: {label} must use {environment}")
    for key in [
        "com.apple.security.app-sandbox",
        "com.apple.security.network.client",
        "com.apple.security.device.bluetooth",
    ]:
        if entitlements.get(key) is not True:
            fail(f"macOS sandbox contract failed: {label} missing {key}")

if widget_entitlements.get("com.apple.security.application-groups") != expected_group:
    fail("App Group contract failed: widget group mismatch")
if widget_mac_entitlements.get("com.apple.security.application-groups") != expected_group:
    fail("App Group contract failed: macOS widget group mismatch")
if widget_mac_entitlements.get("com.apple.security.app-sandbox") is not True:
    fail("macOS widget sandbox contract failed")
if watch_widget_entitlements.get("com.apple.security.application-groups") != expected_group:
    fail("App Group contract failed: Watch widget group mismatch")

for required in [
    "CODE_SIGN_ENTITLEMENTS = PowerMesh/PowerMesh.entitlements;",
    "CODE_SIGN_ENTITLEMENTS = PowerMesh/PowerMeshWatch.entitlements;",
    "CODE_SIGN_ENTITLEMENTS = PowerMesh/PowerMeshRelease.entitlements;",
    "CODE_SIGN_ENTITLEMENTS = PowerMesh/PowerMeshWatchRelease.entitlements;",
    '"CODE_SIGN_ENTITLEMENTS[sdk=macosx*]" = PowerMesh/PowerMeshMac.entitlements;',
    '"CODE_SIGN_ENTITLEMENTS[sdk=macosx*]" = PowerMesh/PowerMeshMacRelease.entitlements;',
    "CODE_SIGN_ENTITLEMENTS = PowerMeshWidgets/PowerMeshWidgets.entitlements;",
    '"CODE_SIGN_ENTITLEMENTS[sdk=macosx*]" = PowerMeshWidgets/PowerMeshWidgetsMac.entitlements;',
    "CODE_SIGN_ENTITLEMENTS = PowerMeshWidgets/PowerMeshWatchWidgets.entitlements;",
    "PowerMeshWidgets.appex",
    "PowerMeshWatchWidgets.appex",
    "name = PowerMeshWatchWidgets;",
    "PRODUCT_BUNDLE_IDENTIFIER = com.tiburonns.PowerMesh.watchkitapp.widgets;",
    "INFOPLIST_FILE = PowerMeshWidgets/Info.plist;",
    "PowerMeshWatch.app in Embed Watch Content",
    'name = "Embed Watch Content";',
    "dstSubfolderSpec = 13;",
    "platformFilter = ios;",
]:
    if required not in project:
        fail(f"Xcode target contract failed: missing {required}")

if "INFOPLIST_KEY_NSExtension_NSExtensionPointIdentifier" in project:
    fail("widget contract failed: nested NSExtension must come from a real Info.plist")

watch_embed_marker = "PowerMeshWatch.app in Embed Watch Content"
watch_embed_entries = [
    line for line in project.splitlines()
    if watch_embed_marker in line and "PBXBuildFile" in line
]
if not any("platformFilter = ios;" in line for line in watch_embed_entries):
    fail("Watch contract failed: embedded Watch app is not filtered to the iOS host")

watch_dependency_lines = [
    line for line in project.splitlines()
    if "PBXTargetDependency" in line
    and "target = E20000000000000000000001" in line
]
if not any("platformFilter = ios;" in line for line in watch_dependency_lines):
    fail("Watch contract failed: host dependency on Watch target is not iOS-only")

pbx_like_ids = set(re.findall(r"\b([A-Z0-9]{24})\b", project))
invalid_pbx_ids = sorted(
    value for value in pbx_like_ids
    if re.fullmatch(r"[A-F0-9]{24}", value) is None
)
if invalid_pbx_ids:
    fail(f"Xcode project contract failed: non-hex PBX IDs {invalid_pbx_ids}")

pbx_ids = set(re.findall(r"\b([A-F0-9]{24})\b", project))
pbx_definitions = set(
    re.findall(r"^\s*([A-F0-9]{24})\s+(?:/\*.*?\*/\s+)?=\s+\{", project, re.MULTILINE)
)
undefined_pbx_ids = sorted(pbx_ids - pbx_definitions)
if undefined_pbx_ids:
    fail(f"Xcode project contract failed: undefined PBX IDs {undefined_pbx_ids}")

for source_root in [ROOT / "PowerMesh", ROOT / "PowerMeshWidgets"]:
    for source_path in source_root.rglob("*.swift"):
        if source_path.name not in project:
            fail(
                "Xcode project contract failed: Swift source is not referenced "
                f"by project: {source_path.relative_to(ROOT)}"
            )

if "WatchSettingsView.swift in Sources" not in project:
    fail("Watch target contract failed: WatchSettingsView.swift is not in the Watch sources phase")

widget_info = load(ROOT / "PowerMeshWidgets/Info.plist")
extension = widget_info.get("NSExtension")
if not isinstance(extension, dict):
    fail("widget contract failed: NSExtension dictionary is missing")
if extension.get("NSExtensionPointIdentifier") != "com.apple.widgetkit-extension":
    fail("widget contract failed: incorrect NSExtensionPointIdentifier")

def config_block(config_id, config_name):
    marker = f"{config_id} /* {config_name} */"
    if marker not in project:
        fail(f"Xcode target contract failed: missing {marker}")
    return project.split(marker, 1)[1].split(f"name = {config_name};", 1)[0]

for config_id, config_name in [
    ("F31000000000000000000001", "Debug"),
    ("F31000000000000000000003", "DebugLocal"),
    ("F31000000000000000000002", "Release"),
]:
    block = config_block(config_id, config_name)
    if "watchos" in block or "watchsimulator" in block:
        fail("widget target contract failed: iOS/macOS widget target still declares watchOS")

for config_id, config_name in [
    ("F41000000000000000000001", "Debug"),
    ("F41000000000000000000003", "DebugLocal"),
    ("F41000000000000000000002", "Release"),
]:
    block = config_block(config_id, config_name)
    if 'SUPPORTED_PLATFORMS = "watchos watchsimulator";' not in block:
        fail("Watch widget target contract failed: dedicated target is not watchOS-only")
    if "iphoneos" in block or "macosx" in block:
        fail("Watch widget target contract failed: dedicated target leaks non-watch platforms")

if "PowerMeshWatchWidgets.appex in Embed App Extensions" not in project:
    fail("Watch widget target contract failed: Watch app does not embed dedicated widget extension")
if "dependencies = (AA0000000000000000000001 /* PBXTargetDependency */);" not in project:
    fail("Watch widget target contract failed: Watch app dependency is missing")
if not (ROOT / "PowerMesh.xcodeproj/xcshareddata/xcschemes/PowerMeshWatchWidgets.xcscheme").exists():
    fail("Watch widget target contract failed: shared scheme is missing")

# DebugLocal must remain installable without paid CloudKit/App Group capabilities.
if "POWERMESH_LOCAL_ONLY" not in project:
    fail("local-test contract failed: POWERMESH_LOCAL_ONLY is missing")
if "PRODUCT_BUNDLE_IDENTIFIER = com.tiburonns.PowerMesh.local;" not in project:
    fail("local-test contract failed: local app bundle identifier is missing")

for config_id in [
    "F11000000000000000000003 /* DebugLocal */",
    "F21000000000000000000003 /* DebugLocal */",
    "F31000000000000000000003 /* DebugLocal */",
    "F41000000000000000000003 /* DebugLocal */",
]:
    if config_id not in project:
        fail(f"local-test contract failed: missing {config_id}")
    block = project.split(config_id, 1)[1].split("name = DebugLocal;", 1)[0]
    if "CODE_SIGN_ENTITLEMENTS" in block:
        fail(f"local-test contract failed: {config_id} must not require entitlements")

if "PRODUCT_BUNDLE_IDENTIFIER = com.tiburonns.PowerMesh.local.watchkitapp;" not in project:
    fail("local-test contract failed: local Watch bundle identifier is missing")
if "PRODUCT_BUNDLE_IDENTIFIER = com.tiburonns.PowerMesh.local.watchkitapp.widgets;" not in project:
    fail("local-test contract failed: local Watch widget bundle identifier is missing")
if not (ROOT / "PowerMesh.xcodeproj/xcshareddata/xcschemes/PowerMeshWatch Local.xcscheme").exists():
    fail("local-test contract failed: PowerMeshWatch Local scheme is missing")

cloud_store = (ROOT / "PowerMesh/Services/CloudBatteryStore.swift").read_text(encoding="utf-8")
for required in [
    "CKContainer(identifier: Self.containerIdentifier)",
    "accountStatus()",
    "CKQuerySubscription(",
    "shouldSendContentAvailable = true",
    "firesOnRecordCreation",
    "firesOnRecordUpdate",
    "firesOnRecordDeletion",
]:
    if required not in cloud_store:
        fail(f"CloudKit contract failed: missing {required}")
if "FileManager.default.ubiquityIdentityToken" in cloud_store:
    fail("CloudKit contract failed: availability must not depend on iCloud Drive")

info = load(ROOT / "PowerMesh/Info.plist")
if info.get("BGTaskSchedulerPermittedIdentifiers") != ["com.tiburonns.PowerMesh.refresh"]:
    fail("background contract failed: BGTask identifier mismatch")
modes = set(info.get("UIBackgroundModes", []))
if not {"fetch", "remote-notification"}.issubset(modes):
    fail("background contract failed: fetch/remote-notification modes are missing")
if "NSBluetoothAlwaysUsageDescription" not in info:
    fail("Bluetooth contract failed: purpose string key missing")

background = (ROOT / "PowerMesh/Services/BackgroundRefreshCoordinator.swift").read_text(encoding="utf-8")
if "com.tiburonns.PowerMesh.refresh" not in background:
    fail("background contract failed: iOS identifier mismatch")
if "WatchBackgroundRefreshCoordinator" not in background:
    fail("background contract failed: watchOS refresh path missing")

lifecycle = (ROOT / "PowerMesh/Support/AppLifecycle.swift").read_text(encoding="utf-8")
for required in [
    "PowerMeshWatchAppDelegate",
    "WKApplicationDelegate",
    "WKApplication.shared().registerForRemoteNotifications()",
    "WKBackgroundFetchResult",
]:
    if required not in lifecycle:
        fail(f"Watch push contract failed: missing {required}")

ble = (ROOT / "PowerMesh/Services/AccessoryBatteryScanner.swift").read_text(encoding="utf-8")
for required in ['CBUUID(string: "180F")', 'CBUUID(string: "2A19")']:
    if required not in ble:
        fail(f"Bluetooth contract failed: missing {required}")

for path in [
    ROOT / "PowerMesh/en.lproj/InfoPlist.strings",
    ROOT / "PowerMesh/es.lproj/InfoPlist.strings",
    ROOT / "PowerMeshWidgets/en.lproj/Localizable.strings",
    ROOT / "PowerMeshWidgets/es.lproj/Localizable.strings",
]:
    if not path.exists() or not path.read_text(encoding="utf-8").strip():
        fail(f"localization contract failed: missing {path.relative_to(ROOT)}")

widget_swift = (ROOT / "PowerMeshWidgets/BatteryOverviewWidget.swift").read_text(encoding="utf-8")
if '"Open PowerMesh"' in widget_swift or '"Abre PowerMesh"' in widget_swift:
    fail("localization contract failed: translated widget copy is hard-coded in Swift")
for required in [".accessoryCorner", "widget.stale", "widget.offline"]:
    if required not in widget_swift:
        fail(f"widget contract failed: missing {required}")

for locale_path in [
    ROOT / "PowerMeshWidgets/en.lproj/Localizable.strings",
    ROOT / "PowerMeshWidgets/es.lproj/Localizable.strings",
]:
    widget_strings = locale_path.read_text(encoding="utf-8")
    for key in ["widget.stale", "widget.offline"]:
        if f'"{key}"' not in widget_strings:
            fail(f"widget localization contract failed: {key} missing from {locale_path.name}")

# Verify every AppText key is present in both tables.
language_source = (ROOT / "PowerMesh/Support/AppLanguage.swift").read_text(encoding="utf-8")
enum_prefix = language_source.split("fileprivate func value", 1)[0].split(
    "enum AppText: String, Hashable {", 1
)[1]
keys = set()
for line in enum_prefix.splitlines():
    line = line.strip()
    if line.startswith("case "):
        keys.update(part.strip() for part in line[5:].split(","))
english_block = language_source.split("private static let english:", 1)[1].split(
    "private static let spanish:", 1
)[0]
spanish_block = language_source.split("private static let spanish:", 1)[1]
english_keys = set(re.findall(r"\.(\w+)\s*:", english_block))
spanish_keys = set(re.findall(r"\.(\w+)\s*:", spanish_block))
if keys != english_keys:
    fail(f"localization contract failed: English mismatch missing={sorted(keys-english_keys)} extra={sorted(english_keys-keys)}")
if keys != spanish_keys:
    fail(f"localization contract failed: Spanish mismatch missing={sorted(keys-spanish_keys)} extra={sorted(spanish_keys-keys)}")

if "PrivacyInfo.xcprivacy in Widget Resources" not in project:
    fail("privacy contract failed: iOS/macOS widget target must embed PrivacyInfo.xcprivacy")
if "PrivacyInfo.xcprivacy in Watch Widget Resources" not in project:
    fail("privacy contract failed: Watch widget target must embed PrivacyInfo.xcprivacy")

privacy = load(ROOT / "PowerMesh/PrivacyInfo.xcprivacy")
if privacy.get("NSPrivacyTracking") is not False:
    fail("privacy contract failed: tracking must be false")
reasons = {
    item.get("NSPrivacyAccessedAPIType"): set(item.get("NSPrivacyAccessedAPITypeReasons", []))
    for item in privacy.get("NSPrivacyAccessedAPITypes", [])
}
if "CA92.1" not in reasons.get("NSPrivacyAccessedAPICategoryUserDefaults", set()):
    fail("privacy contract failed: UserDefaults reason CA92.1 is missing")

hardcoded_teams = [
    value for value in re.findall(r"DEVELOPMENT_TEAM = ([^;]+);", project)
    if value.strip().strip('"')
]
if hardcoded_teams:
    fail(f"build contract failed: hardcoded Apple team(s): {hardcoded_teams}")

print(
    f"PASS: PowerMesh {version} (build {build}) release contract: "
    "bilingual UI/docs, CloudKit, background refresh, App Group/widgets, BLE, privacy"
)
