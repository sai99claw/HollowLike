from pathlib import Path
from PIL import Image
import shutil,json
R=Path(__file__).resolve().parent/'effects';src=R/'source/laser-beam.png'
im=Image.open(src);frames=[]
# Crop/pack authored cells without changing their artwork or alpha.
out=Image.new('RGBA',(1536,512))
for i in range(8):
 x=(i%2)*768;y=(i//2)*256
 cell=im.crop((x,y,x+768,y+256));box=cell.getchannel('A').point(lambda a:255 if a>5 else 0).getbbox();print(i,box)
 cut=cell.crop(box);w,h=cut.size
 assert h<128 and w>600
 ox=(i%2)*768+(768-w)//2;oy=(i//2)*128+(128-h)//2
 out.alpha_composite(cut,(ox,oy))
 frames.append({'source_rect':[(i%2)*768,(i//2)*128,768,128],'pivot':[(768-w)//2,64],'reference_width':w,'reference_height':h,'bounds':[(768-w)//2,(128-h)//2,w,h]})
out.save(R/'laser-beam.webp',lossless=True)
(R/'laser-beam.json').write_text(json.dumps({'path':'laser-beam.webp','frames':frames,'fps':24},indent=2))
bg=Image.new('RGBA',out.size,'#183326');bg.alpha_composite(out);bg.thumbnail((1100,500));bg.convert('RGB').save('/tmp/laser-preview.jpg')

im=Image.open(R/'source/clean-crescent.png');im=im.crop(im.getchannel('A').getbbox());im.save(R/'clean-crescent.webp',lossless=True)
w,h=im.size;(R/'clean-crescent.json').write_text(json.dumps({'path':'clean-crescent.webp','source_rect':[0,0,w,h],'pivot':[w/2,h/2],'reference_height':h,'frames':1,'duration':.12}))
