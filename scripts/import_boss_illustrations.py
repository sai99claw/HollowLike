"""Extract and anchor the six delivered Boss atlases and their detached VFX.
Usage: python3 scripts/import_boss_illustrations.py --source <original PNG folder>
"""
from pathlib import Path
from PIL import Image
from scipy.ndimage import label,find_objects,binary_dilation
import numpy as np, json,argparse,io
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--source',required=True,type=Path);args=parser.parse_args()
root=Path(__file__).resolve().parent.parent;out=root/'assets/bosses';out.mkdir(parents=True,exist_ok=True)
manifest={'sources':[],'animations':{},'issues':[]}
characters={
 'sky':('獵鷹首領精靈圖集修復.png',.50), 'canopy':('蘭花螳螂女王動畫精靈圖集.png',.40),
 'branches':('巨型蛛后十二格動畫精靈圖.png',.38),'trunk':('巨型鹿角鍬形蟲帝王動作圖集.png',.42),
 'grass':('苔冠巨蟾動作精靈圖集.png',.42),'underground':('盲眼根鼴王動畫圖集.png',.44)}

def save(crop,path):
 buffer=io.BytesIO();crop.save(buffer,format='PNG',optimize=True);(out/path).write_bytes(buffer.getvalue())

def characters_sheet(biome,name,scale):
 im=Image.open(args.source/name).convert('RGBA');arr=np.array(im)
 labels,n=label(arr[:,:,3]>100);objects=[]
 for i,sl in enumerate(find_objects(labels)):
  if sl is None:continue
  y,x=sl;area=int((labels[sl]==i+1).sum())
  if area>3000:objects.append({'bbox':(x.start,y.start,x.stop,y.stop),'id':i+1})
 groups=[]
 for row in range(3):
  group=[o for o in objects if min(2,int((o['bbox'][1]+o['bbox'][3])*.5/im.height*3))==row]
  group.sort(key=lambda o:(o['bbox'][0]+o['bbox'][2])*.5)
  if len(group)==3:
   large=max(group,key=lambda o:o['bbox'][2]-o['bbox'][0]);x0,y0,x1,y1=large['bbox'];boundary=round((x0+x1)/2/im.width*4)*im.width//4
   group.remove(large);group.extend([{'bbox':(x0,y0,boundary,y1),'id':large['id']},{'bbox':(boundary,y0,x1,y1),'id':large['id']}]);group.sort(key=lambda o:o['bbox'][0])
   manifest['issues'].append(f'{name}: row {row+1} had touching neighboring silhouettes; split for runtime')
  if len(group)!=4:raise ValueError((name,row,len(group)))
  groups.append(group)
 for row,group in enumerate(groups):
  frames=[]
  for col,o in enumerate(group):
   x0,y0,x1,y1=o['bbox'];x0=max(0,x0-3);y0=max(0,y0-3);x1=min(im.width,x1+3);y1=min(im.height,y1+3)
   sub=arr[y0:y1,x0:x1].copy();selected=binary_dilation(labels[y0:y1,x0:x1]==o['id'],iterations=3);sub[:,:,3]=np.where(selected,sub[:,:,3],0)
   # Feet come from the lower central body. This excludes an extended scythe tip.
   occupied=sub[:,:,3]>100;ys,xs=np.where(occupied)
   bottom=int(np.percentile(ys,99.5));foot_x=float(np.median(xs[ys>=bottom-12]))
   if biome=='sky':foot_x=sub.shape[1]*.55;bottom=int(sub.shape[0]*.72)
   pivot=(foot_x*scale,bottom*scale)
   crop=Image.fromarray(sub);crop=crop.resize((max(1,round(crop.width*scale)),max(1,round(crop.height*scale))),Image.Resampling.LANCZOS)
   path=f'{biome}_{row}_{col}.png';save(crop,path)
   frames.append({'path':path,'pivot':list(pivot),'size':list(crop.size),'source_rect':[x0,y0,x1-x0,y1-y0]})
  manifest['animations'][f'{biome}_{["move","melee","ranged"][row]}']={'frames':frames,'source':name}
 manifest['sources'].append(name)
for biome,(name,scale) in characters.items():characters_sheet(biome,name,scale)
fx={
 'sky':('逐霆隼王風雷攻擊圖集.png',[0,410,650,1024]),
 'canopy':('翠粉月牙斬擊與迴旋鏢特效圖集.png',[0,385,708,1024]),
 'branches':('銀紫縫針與繭彈特效圖集.png',[0,400,650,941]),
 'trunk':('琥珀巨鉗樹脂攻擊精靈圖集.png',[0,390,650,941]),
 'grass':('蘆葉斬擊與水滴彈幕圖集.png',[0,440,740,1086]),
 'underground':('盲根掘王：掘爪與根鬚鑽彈.png',[0,385,635,940])}
for biome,(name,bands) in fx.items():
 im=Image.open(args.source/name).convert('RGBA')
 for row in range(3):
  frames=[]
  for col in range(4):
   region=(col*im.width//4,bands[row],(col+1)*im.width//4,bands[row+1]);crop=im.crop(region)
   bbox=crop.getchannel('A').point(lambda a:255 if a>15 else 0).getbbox()
   if bbox:crop=crop.crop(bbox)
   crop=crop.resize((max(1,round(crop.width*.3)),max(1,round(crop.height*.3))),Image.Resampling.LANCZOS)
   path=f'{biome}_fx_{row}_{col}.png';save(crop,path)
   frames.append({'path':path,'pivot':[crop.width*.5,crop.height*.5],'size':list(crop.size),'source_rect':list(region)})
  manifest['animations'][f'{biome}_{["slash_fx","projectile","impact"][row]}']={'frames':frames,'source':name}
 manifest['sources'].append(name)
(out/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print('Boss import:',len(manifest['sources']),'source sheets,',len(manifest['animations']),'clips,',sum(len(c['frames']) for c in manifest['animations'].values()),'frames,',sum(f.stat().st_size for f in out.glob('*.png'))//1024,'KiB')
print('Curation notes:',manifest['issues'])
