"""Padding/cropping only. Original imagegen alpha and RGB pixels remain intact."""
from pathlib import Path
from PIL import Image
import json,hashlib
ROOT=Path(__file__).resolve().parent

def write(path,data):path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def boxbounds(image):return image.getchannel('A').point(lambda a:255 if a>=24 else 0).getbbox()
def effects():
 source=ROOT/'effects/source/feather-crescent.png';im=Image.open(source).convert('RGBA');atlas=Image.new('RGBA',(1728,1152));anims={'feathers':[],'crescent':[]}
 origins=[(65,262),(539,262),(1052,268)]
 heights=[]
 for row in range(2):
  for col in range(3):
   x,y=col*512,row*512;piece=im.crop((x,y,x+512,y+512));atlas.alpha_composite(piece,(col*576+32,row*576+32))
   bounds=boxbounds(piece)
   px,py=origins[col] if row==0 else (x+(bounds[0]+bounds[2])*.5,y+(bounds[1]+bounds[3])*.5)
   item={'source_rect':[col*576,row*576,576,576],'pivot':[px-x+32,py-y+32],'original_rect':[x,y,512,512],'original_pivot':[px,py],'bounds':[bounds[0]+32,bounds[1]+32,bounds[2]-bounds[0],bounds[3]-bounds[1]]}
   anims['feathers' if row==0 else 'crescent'].append(item)
   if row==1:heights.append(bounds[3]-bounds[1])
 target=ROOT/'effects/feather-crescent.webp';atlas.save(target,'WEBP',lossless=True,method=4)
 write(target.with_suffix('.json'),{'version':37,'path':target.name,'mode':'built-in image_gen','source':'source/feather-crescent.png','source_sha256':sha(source),'size':list(atlas.size),'cell_size':[576,576],'feather_duration':.18,'crescent_duration':.14,'crescent_world_long_axis':1280/3,'crescent_reference_height':max(heights),'animations':anims,'notes':['Feathers authored spraying RIGHT; pivot is left emission origin.','Crescent pivot is visible crescent center. Use one shared scale across allframes.','Only transparent padding added. Source alpha preserved.']})
 return atlas

def player():
 source=ROOT/'player/source/ledge-mantle.png';im=Image.open(source).convert('RGBA');atlas=Image.new('RGBA',(2560,768));frames=[]
 crops=[(0,0,582,724),(582,0,1100,724),(1100,0,1650,724),(1650,0,2172,724)]
 pivots=[(547,335),(1060,335),(1585,438),(1975,576)]
 poses=['ledge_grip','pull_up','step_over','stand']
 for i,(crop,pivot) in enumerate(zip(crops,pivots)):
  piece=im.crop(crop);ox=(640-piece.width)//2;oy=22;atlas.alpha_composite(piece,(i*640+ox,oy));b=boxbounds(piece)
  frames.append({'pose':poses[i],'source_rect':[i*640,0,640,768],'pivot':[pivot[0]-crop[0]+ox,pivot[1]-crop[1]+oy],'original_rect':[crop[0],crop[1],crop[2]-crop[0],crop[3]-crop[1]],'original_pivot':list(pivot),'bounds':[b[0]+ox,b[1]+oy,b[2]-b[0],b[3]-b[1]]})
 reference=375
 target=ROOT/'player/ledge-mantle.webp';atlas.save(target,'WEBP',lossless=True,method=4)
 write(target.with_suffix('.json'),{'version':37,'path':target.name,'mode':'built-in image_gen','source':'source/ledge-mantle.png','source_sha256':sha(source),'size':list(atlas.size),'cell_size':[640,768],'duration':.32,'loop':False,'world_height':50.9375,'reference_height':reference,'pixel_factor':50.9375/reference,'timing_seconds':[0,.08,.16,.24,.32],'frames':frames,'notes':['Measured whole-body crops preserve first-pose wing beyond nominal source cell.','First2pivots are forward wing grip; last2 are support foot. Runtime moves anchor onto ledge.','Fixed scale from standing height375px. No per-frame normalization.','Only transparent padding added.']})
 return atlas

if __name__=='__main__':
 for name,atlas in [('effects',effects()),('player',player())]:
  bg=Image.new('RGBA',atlas.size,'#284835');bg.alpha_composite(atlas);bg.convert('RGB').save('/tmp/v37-'+name+'-composite.jpg')
  print(name,atlas.size)
