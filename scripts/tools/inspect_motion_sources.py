"""Locate isolated character silhouettes; emits rectangles only, never edits artwork."""
import json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
ROOT = Path(__file__).resolve().parents[2]
path = ROOT / 'art/concepts/motion/sources.json'
jobs = json.loads(path.read_text())
for job in jobs:
    if not job['id'].startswith(('fisher-', 'cat-')):
        continue
    image = Image.open(ROOT / ('art/concepts/motion/'+job.get('source',job['id'])+'.png'))
    mask = np.asarray(image.getchannel('A')) > 16
    labels, count = ndimage.label(mask)
    areas = np.bincount(labels.ravel())
    candidates = sorted(range(1,count+1),key=lambda i:areas[i],reverse=True)[:job['count']]
    objects = ndimage.find_objects(labels)
    records = []
    for label in candidates:
        y, x = objects[label-1]
        assert areas[label] > image.width*image.height*.01, job['id']
        records.append(([max(x.start-2,0),max(y.start-2,0),min(x.stop+2,image.width),min(y.stop+2,image.height)],label))
    records.sort(key=lambda record: (int(((record[0][1]+record[0][3])/2)/(image.height/2)),(record[0][0]+record[0][2])/2))
    boxes = [record[0] for record in records]
    assert len(boxes) == job['count']
    job['source_rects'] = [[x,y,r-x,b-y] for x,y,r,b in boxes]
    job['source_masks'] = []
    mask_folder = ROOT / 'art/concepts/motion/regions'
    mask_folder.mkdir(exist_ok=True)
    for index, (box, label) in enumerate(records,1):
        x,y,r,b = box
        selected = ndimage.binary_dilation(labels[y:b,x:r] == label, iterations=1)
        runs = []
        for row, values in enumerate(selected):
            edges = np.flatnonzero(np.diff(np.r_[False,values,False]))
            runs.extend([row,int(start),int(end-start)] for start,end in zip(edges[::2],edges[1::2]))
        name = 'art/concepts/motion/regions/'+job['id']+f'-{index:02d}.json'
        (ROOT / name).write_text(json.dumps(runs,separators=(',',':'))+'\n')
        job['source_masks'].append(name)
    print(job['id'],job['source_rects'])
path.write_text(json.dumps(jobs,indent=2)+'\n')
