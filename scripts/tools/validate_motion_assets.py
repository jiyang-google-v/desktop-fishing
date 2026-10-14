"""Inspect delivered PNGs; --write-manifest records the actual frame inventory."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--write-manifest', action='store_true')
args = parser.parse_args()
config = json.loads((ROOT / 'assets/production/motion.animation.json').read_text())
items = []
for group, data in config['groups'].items():
    for clip, sequence in data['clips'].items():
        hashes = set()
        for index, path in enumerate(sequence['frames'], 1):
            image = Image.open(ROOT / path)
            assert image.mode == 'RGBA' and list(image.size) == data['canvas'], path
            # Hash only visible composited content, not hidden RGB at alpha zero.
            projected = Image.alpha_composite(Image.new('RGBA', image.size, '#fff9eb'), image)
            hashes.add(hashlib.sha256(projected.tobytes()).hexdigest())
            items.append({'id':f'{group}-{clip}-{index:02d}', 'path':path,
                          'size':list(image.size), 'pivot':data['pivot'], 'facing':'right',
                          'role':'transparent_overlay', 'group':group, 'clip':clip})
        assert len(hashes) == len(sequence['frames']), f'Duplicated static frame: {group}/{clip}'
for name, data in config['gear'].items():
    image = Image.open(ROOT / data['path'])
    assert image.size == (512, 512), name
    items.append({'id':'gear-'+name, 'path':data['path'], 'size':list(image.size),
                  'pivot':data['pivot'], 'facing':'right' if name == 'rod' else 'none',
                  'role':'transparent_overlay', 'group':'gear'})
image = Image.open(ROOT / config['scene']['pier'])
items.append({'id':'pier-clear', 'path':config['scene']['pier'], 'size':list(image.size),
              'pivot':[0,.5], 'facing':'right', 'role':'transparent_overlay', 'group':'scene'})
results = []
for item in items:
    image = Image.open(ROOT / item['path'])
    alpha = image.getchannel('A')
    hist = alpha.histogram()
    box = alpha.point(lambda value: 255 if value > 16 else 0).getbbox()
    assert image.mode == 'RGBA' and alpha.getextrema()[0] == 0, item['id']
    assert hist[0] > image.width * image.height * .10, item['id']
    assert box and box[0] > 0 and box[1] > 0 and box[2] < image.width and box[3] < image.height, (item['id'], box)
    results.append({'id':item['id'], 'size':list(image.size), 'mode':image.mode,
                    'alpha_range':list(alpha.getextrema()), 'transparent_pixels':hist[0],
                    'visible_bounds_alpha_over_16':box, 'passed':True})
    item.update(style_version='V2.6',status='integration_candidate',source='built-in imagegen; fixed-grid extraction and registration',qa='docs/STAGE4_ART_QA.md')
assert sum(x.get('group') == 'fisher' for x in items) == 22
assert sum(x.get('group') == 'cat' for x in items) == 16
assert sum(x.get('group') == 'fx' for x in items) == 34
assert len(items) == 77
(ROOT / 'docs/qa/stage4/asset-checks.json').write_text(json.dumps(results,indent=2)+'\n')
if args.write_manifest:
    path = ROOT / 'assets/production/asset_manifest.json'
    manifest = json.loads(path.read_text())
    ids = {item['id'] for item in items}
    manifest['assets'] = [item for item in manifest['assets'] if item['id'] not in ids] + items
    manifest['motion_animation'] = 'assets/production/motion.animation.json'
    manifest['note'] = 'Stage4 independent authored frames are integration candidates pending final visual acceptance; legacy scene sources retained for traceability.'
    path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('77 visual assets: 22 fisher +16 cat +34 FX +4 gear +1 pier; RGBA, padding, distinct authored frames and references passed')
