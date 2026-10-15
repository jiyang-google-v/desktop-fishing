"""Record visible illustration bounds; source RGBA PNG files remain unchanged."""
import json
from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parents[2]
path = root / 'assets/production/collection_manifest.json'
manifest = json.loads(path.read_text())
for asset in manifest['assets']:
    image = Image.open(root / asset['path']).convert('RGBA')
    bounds = image.getchannel('A').point(lambda alpha: 255 if alpha > 8 else 0).getbbox()
    if bounds is None:
        raise ValueError(f"Empty portrait: {asset['id']}")
    left, top, right, bottom = bounds
    left, top = max(0, left - 8), max(0, top - 8)
    right, bottom = min(image.width, right + 8), min(image.height, bottom + 8)
    asset['display_rect'] = [left, top, right - left, bottom - top]
path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
