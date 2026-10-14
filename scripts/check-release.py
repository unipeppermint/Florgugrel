#!/usr/bin/env python3
"""Read-only checks. Exit 1 is a technical defect; exit 2 is missing submission information."""
import json
import plistlib
import struct
import sys
from pathlib import Path
from urllib.parse import urlparse

root = Path(__file__).resolve().parent.parent
bundle = Path(sys.argv[1]) if len(sys.argv) > 1 else root / 'Florgugrel'
failures, pending = [], []
info = plistlib.loads((bundle / 'Info.plist').read_bytes())
manifest = bundle / 'PrivacyInfo.xcprivacy'
if not manifest.exists():
    failures.append('PrivacyInfo.xcprivacy is missing from the bundle')
else:
    data = plistlib.loads(manifest.read_bytes())
    reasons = {entry['NSPrivacyAccessedAPIType']: entry['NSPrivacyAccessedAPITypeReasons'] for entry in data.get('NSPrivacyAccessedAPITypes', [])}
    if 'CA92.1' not in reasons.get('NSPrivacyAccessedAPICategoryUserDefaults', []):
        failures.append('Missing declared use of app-owned UserDefaults')
    if data.get('NSPrivacyTracking') is not False or data.get('NSPrivacyCollectedDataTypes') != []:
        failures.append('Privacy declaration does not match current offline implementation')

icon = root / 'Florgugrel/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
png = icon.read_bytes()
w, h, depth, color = struct.unpack('>IIBB', png[16:26])
if (w, h) != (1024, 1024) or color in (4, 6) or b'tRNS' in png:
    failures.append('Store icon must be 1024 square and have no transparency')
if info.get('CFBundleDisplayName') != '牌阵师':
    failures.append('Unexpected app display name')
if bundle != root / 'Florgugrel':
    if info.get('CFBundleIdentifier') != 'com.teskl.Florgugrel':
        failures.append('Bundle identifier changed unexpectedly')
    if not (bundle / 'Assets.car').exists():
        failures.append('Compiled assets missing')
    if not (bundle / 'Base.lproj/LaunchScreen.storyboardc').exists():
        failures.append('Launch storyboard missing')

for key in ('HandcraftPrivacyURL', 'HandcraftSupportURL'):
    raw = info.get(key, '')
    url = urlparse(raw)
    if url.scheme != 'https' or not url.netloc or any(token in url.netloc for token in ('example.', 'localhost', 'invalid')):
        pending.append(key + ': supply the real published HTTPS URL and verify it is accessible')
submission = json.loads((root / 'release/Submission.json').read_text())
for key in ('publisher_name', 'support_email', 'review_contact', 'territories'):
    if not submission.get(key):
        pending.append(key + ': publisher information required')
print('TECHNICAL CHECKS: ' + ('FAILED' if failures else 'PASSED'))
for issue in failures:
    print('FAIL: ' + issue)
for issue in pending:
    print('PENDING: ' + issue)
print('This check does not sign, upload, publish, or guarantee App Review approval.')
sys.exit(1 if failures else 2 if pending else 0)
