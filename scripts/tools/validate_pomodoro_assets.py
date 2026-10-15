"""Validate standalone UI PNGs and manifest dimensions/alpha/hash/padding."""
import hashlib
import json
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[2]
manifest = json.loads((ROOT / 'assets/production/pomodoro_manifest.json').read_text())
checks = []
for asset in manifest['assets']:
    path = ROOT / asset['path']
    with Image.open(path) as im:
        assert im.mode == 'RGBA', path
        assert list(im.size) == asset['size'], path
        alpha = im.getchannel('A')
        assert alpha.getextrema()[0] == 0 and alpha.getextrema()[1] >= 250, path
        assert all(alpha.getpixel(p) == 0 for p in [(0, 0), (im.width-1, 0), (0, im.height-1), (im.width-1, im.height-1)]), path
        assert alpha.getbbox(), path
    assert hashlib.sha256(path.read_bytes()).hexdigest() == asset['sha256'], path
    checks.append({'id': asset['id'], 'rgba': True, 'size': asset['size'], 'transparent_corners': True, 'sha256': asset['sha256']})
print(json.dumps({'asset_count': len(checks), 'failures': 0, 'checks': checks}, ensure_ascii=False, indent=2))
