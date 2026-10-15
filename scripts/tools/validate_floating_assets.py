"""Validate the six new layers and unchanged reused art; Python + Pillow only."""
import hashlib,json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
manifest=json.loads((ROOT/'assets/production/floating_manifest.json').read_text())
assert len(manifest['assets'])==6
report=[]
for asset in manifest['assets']:
 path=ROOT/asset['path'];image=Image.open(path)
 assert image.mode=='RGBA' and list(image.size)==asset['size'],asset['id']
 assert hashlib.sha256(path.read_bytes()).hexdigest()==asset['sha256'],asset['id']
 alpha=image.getchannel('A');h=alpha.histogram();total=image.width*image.height
 assert h[0]>total*.15 and sum(h[16:])>total*.005,asset['id']
 bounds=alpha.point(lambda v:255 if v>16 else 0).getbbox()
 if not asset['intentional_canvas_contacts']:
  assert 0<bounds[0] and 0<bounds[1] and bounds[2]<image.width and bounds[3]<image.height,asset['id']
 report.append({'id':asset['id'],'mode':image.mode,'size':list(image.size),'sha256':asset['sha256'],'alpha_range':list(alpha.getextrema()),'transparent_fraction':round(h[0]/total,4),'visible_bounds_alpha_over_16':bounds,'intentional_canvas_contacts':asset['intentional_canvas_contacts'],'passed':True})
for entry in manifest['reused']:
 for path,expected in zip(entry.get('frames',[entry.get('path')]),entry.get('frame_sha256',[entry.get('sha256')])):
  assert (ROOT/path).is_file(),path
  if expected:assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==expected,path
config=json.loads((ROOT/'assets/production/floating.animation.json').read_text())
assert config['profiles']['mini']['allowed_art']==['rod','bobber','mini-water']
assert config['render_rules']['vertical_line_below_rod_tip']
for name in ['scene-transparent-idle.png','mini-transparent-idle.png']:
 path=ROOT/'docs/qa/floating'/name
 if path.exists():
  alpha=Image.open(path).getchannel('A');assert alpha.getpixel((0,0))==0 and alpha.getextrema()[1]>0
out=ROOT/'docs/qa/floating/asset-checks.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,indent=2)+'\n')
# Source transparency on both wallpaper tones, at real small display dimensions.
board=Image.new('RGB',(1000,690),'#edf2ed');d=ImageDraw.Draw(board)
for i,asset in enumerate(manifest['assets']):
 x=(i%3)*330+10;y=(i//3)*335+10
 d.text((x+4,y+4),asset['id'],fill='#486575')
 for n,bg in enumerate(['#fffbee','#27343c']):
  box=Image.new('RGBA',(310,140),bg);im=Image.open(ROOT/asset['path']).convert('RGBA');im.thumbnail((280,125),Image.Resampling.LANCZOS);box.alpha_composite(im,((310-im.width)//2,(140-im.height)//2));board.paste(box.convert('RGB'),(x,y+25+n*145))
board.save(ROOT/'docs/qa/floating/layers-light-dark.png')
print('Floating art: six RGBA/checksum/padding checks passed; reused files and minimal whitelist passed.')
