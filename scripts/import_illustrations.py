"""Curate delivered sprite sheets into engine-ready, anchored transparent frames.
This is asset extraction / resizing, not animation interpolation or redrawing.
"""
import argparse
from PIL import Image
from pathlib import Path
from scipy.ndimage import label,find_objects,binary_dilation
import numpy as np, json
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source',type=Path,required=True,help='Directory containing the 17 original delivered PNGs')
args=parser.parse_args()
src=args.source;out=Path(__file__).resolve().parent.parent/'assets/illustrated';out.mkdir(parents=True,exist_ok=True)
manifest={'version':1,'animations':{},'modules':{},'backgrounds':{},'sources':[]}

def extract(name, key, cols, rows, scale, sequences, override=None, airborne=False):
 im=Image.open(src/name).convert('RGBA');arr=np.array(im);mask=arr[:,:,3]>100
 lab,n=label(mask);sl=find_objects(lab)
 objects=[]
 for i,bb in enumerate(sl):
  if bb is None:continue
  yy,xx=bb;area=int((lab[bb]==i+1).sum())
  if area>1000:objects.append({'i':i+1,'bbox':(xx.start,yy.start,xx.stop,yy.stop),'area':area})
 # Select components by row and core center. Avoid regular crops cutting long weapons.
 objects.sort(key=lambda o:(o['bbox'][1]+o['bbox'][3])*.5)
 row_groups=[];remaining=objects[:]
 for row in range(rows):
  target_y=(row+.5)*im.height/rows
  # Most core centers stay within their row; choose nearest row center, then sort horizontally.
  group=[o for o in objects if min(rows-1,int(((o['bbox'][1]+o['bbox'][3])*.5)/im.height*rows))==row]
  group.sort(key=lambda o:(o['bbox'][0]+o['bbox'][2])*.5)
  if override and row in override:group=override[row]
  if len(group)!=cols:
   print('CURATION',key,'row',row,'objects',len(group),'expected',cols)
  row_groups.append(group)
 frames={}
 for row,group in enumerate(row_groups):
  for col,o in enumerate(group):
   x0,y0,x1,y1=o['bbox'];pad=5
   x0=max(0,x0-pad);y0=max(0,y0-pad);x1=min(im.width,x1+pad);y1=min(im.height,y1+pad)
   sub=arr[y0:y1,x0:x1].copy()
   if 'i' in o:
    # Include antialiased fringe around the selected connected silhouette only.
    selected=binary_dilation(lab[y0:y1,x0:x1]==o['i'],iterations=4)
    sub[:,:,3]=np.where(selected,sub[:,:,3],0)
   else:
    # Manual regions only for overlapping Boss frames.
    pass
   # Pink pigeon feet anchor to the surface; other enemies use bottom center.
   alpha=sub[:,:,3]>100
   if key.startswith('pigeon'):
    red=(sub[:,:,0]>85)&(sub[:,:,0]>sub[:,:,1].astype(float)*1.20)&(sub[:,:,0]>sub[:,:,2].astype(float)*1.08)&alpha
    red[:int(sub.shape[0]*.55),:]=False
    ys,xs=np.where(red)
    if len(xs)>12:
     foot_y=int(np.percentile(ys,99));foot_x=float(np.median(xs[ys>foot_y-13]))
     pivot=(foot_x,foot_y)
    else:pivot=(sub.shape[1]*.5,sub.shape[0]-pad)
   elif airborne:pivot=(sub.shape[1]*.5,sub.shape[0]*.55+22)
   else:pivot=(sub.shape[1]*.44,sub.shape[0]-pad)
   img=Image.fromarray(sub)
   newsize=(max(1,round(img.width*scale)),max(1,round(img.height*scale)))
   img=img.resize(newsize,Image.Resampling.LANCZOS)
   path=f'{key}_{row}_{col}.png';img.save(out/path,optimize=True)
   frames[row,col]={'path':path,'pivot':[round(pivot[0]*scale,2),round(pivot[1]*scale,2)],'size':list(newsize),'source_rect':[x0,y0,x1-x0,y1-y0]}
 for anim,refs in sequences.items():
  manifest['animations'][anim]={'frames':[frames[r,c] for r,c in refs if (r,c) in frames],'source':name}
 manifest['sources'].append(name)

seq=lambda r,n=4:[(r,c) for c in range(n)]
extract('16隻鴿子角色透明精靈圖集.png','pigeon_walk',4,4,.25,{'pigeon_walk':seq(0),'pigeon_quick_pose':seq(1),'pigeon_heavy_pose':seq(2),'pigeon_reach_pose':seq(3)})
extract('哥德風鴿子英雄戰鬥動作圖集.png','pigeon_attack',4,4,.25,{'pigeon_quick':seq(1),'pigeon_heavy':seq(2),'pigeon_reach':seq(3)})
extract('鴿子英雄跳躍衝刺精靈表.png','pigeon_move',4,3,.20,{'pigeon_jump':seq(0),'pigeon_wall':[(1,0),(1,1),(1,2)],'pigeon_dash':[(2,0),(2,1),(2,2)],'pigeon_land':[(2,3)]})
extract('鴿子英雄五式攻擊圖鑑.png','pigeon_special',3,5,.26,{'pigeon_charge_quick':seq(0,3),'pigeon_charge_heavy':seq(1,3),'pigeon_charge_reach':seq(2,3),'pigeon_pierce':seq(3,3),'pigeon_slam':seq(4,3)})
extract('苔甲甲蟲守衛動作圖集.png','beetle',4,2,.16,{'beetle_walk':seq(0),'beetle_attack':seq(1)})
extract('森林果實投擲者動作精靈圖集.png','slinger',4,3,.18,{'slinger_walk':seq(0),'slinger_attack':seq(1),'slinger_ranged':seq(2)})
extract('暮色獵蛾動作圖集.png','moth',4,3,.17,{'moth_walk':seq(0),'moth_attack':seq(1),'moth_ranged':seq(2)},airborne=True)
extract('古老枝木守衛動畫圖集.png','guardian',4,3,.19,{'guardian_walk':seq(0),'guardian_attack':seq(1),'guardian_ranged':seq(2)})
# Generated Boss blade silhouettes touch between frames 7 and 8. Split the common
# component into separate frame regions; retain the limitation in asset audit.
# Also the raised axe frame begins in the previous row. Curate complete regions.
boss_override={0:[{'bbox':(10,5,342,338)},{'bbox':(374,6,697,338)},{'bbox':(733,8,1057,350)},{'bbox':(1096,9,1433,350)}],1:[{'bbox':(4,350,398,719)},{'bbox':(384,338,712,721)},{'bbox':(715,433,1093,734)},{'bbox':(1093,435,1448,736)}],2:[{'bbox':(8,752,393,1074)},{'bbox':(394,713,720,1074)},{'bbox':(737,760,1119,1075)},{'bbox':(1118,758,1440,1078)}]}
extract('樹心巨像首領十二姿態圖集.png','boss',4,3,.29,{'boss_walk':seq(0),'boss_attack':seq(1),'boss_ranged':seq(2)},override=boss_override)
extract('森林投射物四列動畫圖集.png','projectile',4,4,.095,{'projectile_needle':seq(0),'projectile_fruit':seq(1),'projectile_acorn':seq(2),'projectile_bossfruit':seq(3)})
# Modules use individually curated rectangles because this sheet is not a grid.
modules={'branch_small':(40,45,315,225),'branch_medium':(366,49,735,269),'branch_large':(753,60,1218,294),'grass_platform':(14,280,374,518),'root_platform':(410,300,778,557),'mushroom_platform':(802,294,1210,564),'foliage':(15,545,429,868),'fern':(452,558,801,866),'hanging_root':(840,568,1207,985),'door_musou':(15,827,430,1237),'door_rogue':(434,861,842,1241),'nest':(872,1020,1205,1251)}
im=Image.open(src/'哥德森林平台與樹門圖集.png')
for key,rect in modules.items():
 crop=im.crop(rect);crop.thumbnail((600,500));name=f'module_{key}.png';crop.save(out/name,optimize=True)
 manifest['modules'][key]={'path':name,'size':list(crop.size)}
for key,val in {'branch_small':65,'branch_medium':57,'branch_large':48,'grass_platform':95,'root_platform':55,'mushroom_platform':65}.items():manifest['modules'][key]['surface_y']=val
manifest['sources'].append('哥德森林平台與樹門圖集.png')
bgs={'sky':'巨樹之上的暮色天穹.png','canopy':'月霧中的古老樹冠.png','branches':'古樹枝間的靛藍霧境.png','trunk':'幽藍古樹根境.png','grass':'巨樹根畔的月霧草原.png','underground':'幽藍古樹根窟.png'}
for key,name in bgs.items():
 im=Image.open(src/name).convert('RGB').resize((1280,720),Image.Resampling.LANCZOS)
 path=f'background_{key}.webp';im.save(out/path,quality=88,method=6)
 manifest['backgrounds'][key]=path;manifest['sources'].append(name)
# Retain curation metadata in the repository alongside the runtime assets.
(out/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print('Imported',len(manifest['sources']),'source sheets,',len(manifest['animations']),'animation clips,',sum(len(v['frames']) for v in manifest['animations'].values()),'referenced frames,',sum(p.stat().st_size for p in out.iterdir())//1024,'KiB')
