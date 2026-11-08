#!/usr/bin/env python3
"""Check version consistency and packaged privacy manifests in an iOS app/archive."""
import argparse
import plistlib
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("product", type=Path, help=".app or .xcarchive directory")
args = parser.parse_args()
root = args.product
if root.suffix == ".xcarchive":
    apps = list((root / "Products/Applications").glob("*.app"))
    if len(apps) != 1:
        parser.error("archive must contain exactly one main application")
    root = apps[0]
if not root.is_dir() or root.suffix != ".app":
    parser.error("expected an existing .app or .xcarchive")

def read(path):
    with path.open("rb") as source:
        return plistlib.load(source)

main = read(root / "Info.plist")
version = (main["CFBundleShortVersionString"], main["CFBundleVersion"])
bundles = [root] + sorted(p for p in root.rglob("*") if p.suffix in (".app", ".appex") and p.is_dir())
for bundle in bundles:
    info = read(bundle / "Info.plist")
    actual = (info.get("CFBundleShortVersionString"), info.get("CFBundleVersion"))
    if actual != version:
        raise SystemExit(f"FAIL: {bundle.name} version {actual}, expected {version}")
    manifest = read(bundle / "PrivacyInfo.xcprivacy")
    for api in manifest.get("NSPrivacyAccessedAPITypes", []):
        if not api.get("NSPrivacyAccessedAPIType") or not api.get("NSPrivacyAccessedAPITypeReasons"):
            raise SystemExit(f"FAIL: invalid API declaration in {bundle.name}")
    print(f"PASS: {bundle.relative_to(root)} version {version[0]} ({version[1]}), privacy manifest")
print(f"PASS: {len(bundles)} application/extension bundles")
