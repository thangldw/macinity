#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$repo_dir" <<'PY'
from pathlib import Path
from html.parser import HTMLParser
import json,re,sys,urllib.parse,hashlib
root=Path(sys.argv[1]); site=root/'site'; release=json.loads((root/'release.json').read_text())
assert release['product']=='Macinity' and release['version']=='3.1.0'
assert release['signing']=='ad-hoc' and release['notarized'] is False
assert json.loads((site/'release.json').read_text())==release, 'site release metadata drift'
class Links(HTMLParser):
 def __init__(self): super().__init__(); self.urls=[]; self.ids=set(); self.copy=set()
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if 'id' in a: self.ids.add(a['id'])
  for key in ['href','src']:
   if key in a: self.urls.append(a[key])
  for key in ['data-copy','data-aria']:
   if key in a: self.copy.add(a[key])
source=(site/'preview.js').read_text(); begin=source.index('  const copy = ')+len('  const copy = '); end=source.index(';\n  const translate',begin); messages=json.loads(source[begin:end]); keys=set(messages['en'])
assert set(messages)=={'en','vi','ja','zh'}
for lang,table in messages.items(): assert set(table)==keys and all(v.strip() for v in table.values()), lang
for name in ['index.html','guide.html','privacy.html']:
 text=(site/name).read_text(); parser=Links(); parser.feed(text)
 assert '<meta name="viewport"' in text and '<main' in text and '<title>Macinity' in text
 assert parser.copy<=keys, name
 for url in parser.urls:
  split=urllib.parse.urlsplit(url)
  if split.scheme or split.netloc: continue
  destination=site/(split.path or name)
  assert destination.exists(), (name,url)
  if split.fragment:
   fragments=Links(); fragments.feed(destination.read_text()); assert split.fragment in fragments.ids,(name,url)
 assert 'Toolbox 2.0' not in text and 'Toolbox-2.0.0.dmg' not in text
for name,asset in json.loads((site/'shared-assets.json').read_text())['assets'].items():
 assert hashlib.sha256((site/name).read_bytes()).hexdigest()==asset['sha256'], name
assert hashlib.sha256((site/'assets/app-icon.png').read_bytes()).hexdigest()==hashlib.sha256((root/'apps/toolbox/Resources/AppIcon-1024.png').read_bytes()).hexdigest()
print('PASS: Macinity site links, four-locale parity, release identity, native icon and canonical mirrors')
PY
node --check "$repo_dir/site/preview.js"
bash "$repo_dir/tests/unsigned_stable_release_test.sh"
