"""QA projections only. Source sprites are never modified by this script."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/qa/stage4'
config = json.loads((ROOT / 'assets/production/motion.animation.json').read_text())
CREAM = '#fff9eb'
BLUE = '#94cbd5'
TEXT = '#486675'
cache = {}
def source(path, pixels):
    key = path, pixels
    if key not in cache:
        image = Image.open(ROOT / path)
        image.thumbnail((pixels,pixels),Image.Resampling.LANCZOS)
        cache[key] = image
    return cache[key]
def paste(canvas,path,xy,pixels):
    canvas.alpha_composite(source(path,pixels),xy)
def board(group):
    clips = config['groups'][group]['clips']
    canvas = Image.new('RGBA',(1240,50+len(clips)*174),CREAM)
    draw = ImageDraw.Draw(canvas)
    draw.text((24,16),'V2.6 / '+group+' / independent authored frames',fill=TEXT)
    for row,(clip,item) in enumerate(clips.items()):
        y=50+row*174
        draw.text((14,y+6),clip,fill=TEXT)
        for i,path in enumerate(item['frames']):
            x=80+i*144
            draw.rectangle((x,y+18,x+136,y+154),fill=BLUE if row%2 else CREAM)
            paste(canvas,path,(x,y+18),136)
            draw.text((x+5,y+156),str(i+1),fill=TEXT)
    canvas.convert('RGB').save(OUT / ('contact-'+group+'.png'))
for group in config['groups']:
    board(group)
# Hand pivots are shown explicitly for internal attachment review.
canvas=Image.new('RGBA',(1160,810),CREAM)
draw=ImageDraw.Draw(canvas)
for row,(clip,item) in enumerate(config['groups']['fisher']['clips'].items()):
    draw.text((5,row*200+5),clip,fill=TEXT)
    for i,path in enumerate(item['frames']):
        x=30+i*184;y=row*200+20
        paste(canvas,path,(x,y),174)
        point=item['grip'][min(i,len(item['grip'])-1)]
        px=x+point[0]*174;py=y+point[1]*174
        draw.ellipse((px-3,py-3,px+3,py+3),outline='#e65564',width=2)
canvas.convert('RGB').save(OUT/'grip-review.png')
samples=[]
for group,data in config['groups'].items():
    for clip,item in data['clips'].items():
        index=2 if len(item['frames'])>2 else 0
        samples.append((group+'/'+clip,item['frames'][index]))
samples += [('gear/'+name,item['path']) for name,item in config['gear'].items()]
for name,bg in [('cream',CREAM),('blue',BLUE)]:
    canvas=Image.new('RGBA',(960,50+((len(samples)+2)//3)*150),bg)
    draw=ImageDraw.Draw(canvas)
    draw.text((16,16),'32 / 48 / 64 / 96 px / '+name,fill=TEXT)
    for i,(label,path) in enumerate(samples):
        x=(i%3)*320+12;y=50+(i//3)*150
        draw.text((x,y),label,fill=TEXT)
        offset=0
        for pixels in [32,48,64,96]:
            paste(canvas,path,(x+offset,y+25+96-pixels),pixels)
            offset += pixels+10
    canvas.convert('RGB').save(OUT/('sizes-'+name+'.png'))
# Motion contact preview: all thirteen clips, same timing as runtime JSON.
tiles=[(group,clip,item) for group,data in config['groups'].items() for clip,item in data['clips'].items()]
frames=[]
for tick in range(40):
    canvas=Image.new('RGBA',(960,720),CREAM)
    draw=ImageDraw.Draw(canvas)
    draw.text((20,14),'V2.6 / motion & gear / actual PNG frames + JSON timing',fill=TEXT)
    for i,(group,clip,item) in enumerate(tiles):
        x=12+(i%4)*236;y=44+(i//4)*160
        draw.rectangle((x,y,x+228,y+150),fill=BLUE if group=='fx' else '#f3f2e7')
        draw.text((x+8,y+6),group+'/'+clip,fill=TEXT)
        t=tick/10 % (item['duration'] if item['loop'] else item['duration']+.4)
        index=min(int(t/item['duration']*len(item['frames'])),len(item['frames'])-1)
        paste(canvas,item['frames'][index],(x+50,y+23),128)
    for i,(gear,item) in enumerate(config['gear'].items()):
        x=12+236+(i%3)*70;y=44+3*160
        if i==3:x=12+236;y+=75
        paste(canvas,item['path'],(x,y),68)
        draw.text((x,y+67),gear,fill=TEXT)
    frames.append(canvas.convert('RGB').quantize(colors=112,method=Image.Quantize.MEDIANCUT))
frames[0].save(OUT/'motion-preview.gif',save_all=True,append_images=frames[1:],duration=100,loop=0,optimize=True,disposal=2)
print('Contact sheets, grip review, all 17 clip/gear samples at four sizes/two backgrounds and animated timing preview rendered')
