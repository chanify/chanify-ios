#!/usr/bin/env python3
"""Generate the existing iOS/macOS acknowledgements from vendored licenses."""
from pathlib import Path
import plistlib

ROOT = Path(__file__).resolve().parents[1]
LICENSES = ROOT / 'Packages/ChanifyDependencies/Licenses'
items = [{
    'Title': 'Acknowledgements',
    'Type': 'PSGroupSpecifier',
    'FooterText': 'This application makes use of the following third party libraries:',
}]
for name in ('FMDB', 'JLRoutes', 'Masonry', 'Protobuf'):
    items.append({
        'Title': name,
        'Type': 'PSGroupSpecifier',
        'FooterText': (LICENSES / name / 'LICENSE').read_text(),
    })
items.append({'Title': '', 'Type': 'PSGroupSpecifier', 'FooterText': ''})
content = plistlib.dumps({'PreferenceSpecifiers': items, 'StringsTable': 'Acknowledgements'})
for destination in ('iOS/Resources/Settings.bundle/Acknowledgements.plist',
                    'OSX/Resources/Acknowledgements.plist'):
    (ROOT / destination).write_bytes(content)
