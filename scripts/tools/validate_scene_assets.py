"""Run with Python + Pillow; validates source PNG metadata and transparent padding."""
import json
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[2]
manifest = json.loads((ROOT / 'assets/production/asset_manifest.json').read_text())
results = []
for asset in manifest['assets']:
    image = Image.open(ROOT / asset['path'])
    assert image.mode == 'RGBA', asset['id']
    assert list(image.size) == asset['size'], asset['id']
    alpha = image.getchannel('A')
    histogram = alpha.histogram()
    bbox = alpha.getbbox()
    visible_bbox = alpha.point(lambda v: 255 if v > 16 else 0).getbbox()
    if asset['role'] == 'transparent_overlay':
        assert histogram[0] > image.width * image.height * .1
        assert visible_bbox[0] > 0 and visible_bbox[1] > 0 and visible_bbox[2] < image.width and visible_bbox[3] < image.height
    results.append({'id': asset['id'], 'size': list(image.size), 'mode': image.mode,
                    'alpha_range': list(alpha.getextrema()), 'transparent_pixels': histogram[0],
                    'alpha_bounds': bbox, 'visible_bounds_alpha_over_16': visible_bbox, 'passed': True})
config = json.loads((ROOT / 'assets/production/scene.animation.json').read_text())
for layer in config['layers']:
    assert (ROOT / 'assets/production' / layer['path']).is_file()
out = ROOT / 'docs/qa/stage2/asset-checks.json'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(results, indent=2))
print('Scene assets: RGBA, actual dimensions, alpha padding and animation paths passed')
