#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$repo_dir" <<'PY'
from pathlib import Path
import plistlib,json,sys,re
root=Path(sys.argv[1]); release=json.loads((root/'release.json').read_text()); info=plistlib.loads((root/'apps/toolbox/Resources/Info.plist').read_bytes())
assert info['CFBundleDisplayName']==release['product']=='Orven'
assert info['CFBundleShortVersionString']==release['version']=='3.0.0'
assert info['CFBundleIdentifier']=='com.thang.toolbox' and info['CFBundleExecutable']=='Toolbox'
assert release['app']=='Orven.app' and release['dmg']=='Orven-3.0.0.dmg'
assert release['tag']=='v3.0.0' and release['channel']=='stable' and release['notarized'] is False
for name in ['README.md','SECURITY.md','site/index.html','site/guide.html','apps/toolbox/Resources/Open Orven - First Launch.html']:
 text=(root/name).read_text()
 assert 'Open Anyway' in text, name
 assert re.search(r'(not notarized|not-notarized|unnotarized|not Apple-notarized|Not Apple-notarized)',text,re.I), name
 assert not re.search(r'xattr .*quarantine|spctl .*disable',text),name
print('PASS: Orven ad-hoc stable release identity and safe Gatekeeper disclosure')
PY
