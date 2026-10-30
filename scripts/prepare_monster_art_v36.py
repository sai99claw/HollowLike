"""Normalize model-authored cells without redrawing their contents.

Original PNGs remain source assets. Shared row scaling preserves pose/body size;
the generated runtime metadata owns exact pixel regions and contact pivots.
"""
from pathlib import Path
from PIL import Image
import argparse,io,json,statistics
import numpy as np
from scipy import ndimage
ROOT=Path(__file__).resolve().parent.parent/'assets/v36/monsters'

def _components(image):
    alpha=np.asarray(image.getchannel('A'))
    labels,count=ndimage.label(alpha>=144)
    areas=np.bincount(labels.ravel())
    objects=ndimage.find_objects(labels)
    components=[]
    for index,region in enumerate(objects,1):
        if region is None or areas[index]<12:continue
        yy,xx=region
        components.append((index,int(areas[index]),(xx.start+xx.stop)*.5,(yy.start+yy.stop)*.5))
    return alpha,labels,components

def _isolated(image,alpha,labels,selected,components,cell):
    # Keep the opaque authored silhouette, then only its nearby painted fringe.
    # Other silhouettes are explicitly a competing source, not copied fragments.
    selected=[selected] if isinstance(selected,int) else selected
    ys,xs=np.where(np.isin(labels,selected))
    margin=int(np.ceil(min(cell)*.16))+2
    box=(max(0,int(xs.min())-margin),max(0,int(ys.min())-margin),min(image.width,int(xs.max())+margin+1),min(image.height,int(ys.max())+margin+1))
    image=image.crop(box);alpha=alpha[box[1]:box[3],box[0]:box[2]];labels=labels[box[1]:box[3],box[0]:box[2]]
    core=np.isin(labels,selected)
    distance=ndimage.distance_transform_edt(~core)
    large_ids=[v[0] for v in components if v[0] not in selected and v[1]>=24]
    others=np.isin(labels,large_ids)
    other_distance=ndimage.distance_transform_edt(~others) if others.any() else np.full(alpha.shape,np.inf)
    keep=(alpha>=8)&(distance<=min(cell)*.16)&(distance<=other_distance)
    keep=ndimage.binary_propagation(core,mask=keep)
    feather=np.clip((min(cell)*.16-distance)/3.0,0,1)
    rgba=np.asarray(image).copy()
    rgba[:,:,3]=np.where(keep,np.rint(alpha*feather),0).astype(np.uint8)
    output=Image.fromarray(rgba,'RGBA')
    bounds=output.getchannel('A').point(lambda v:255 if v>=24 else 0).getbbox()
    if not bounds:raise ValueError('Empty extracted silhouette')
    return output.crop(bounds)

def projectile_pieces(image,rows):
    """Choose full source components before cell cropping, recovering split noses."""
    alpha,labels,components=_components(image)
    width,height=image.size;cell=(width/8,height/rows)
    output=[];used=set()
    for row in range(rows):
        pieces=[]
        for col in range(8):
            center=((col+.5)*cell[0],(row+.5)*cell[1])
            if row>=rows-2:
                # Swipe dissipation is intentionally several pieces. Keep all
                # authored particles whose own centroids belong to this frame;
                # do not collapse it to a single largest sparkle.
                chosen=[item[0] for item in components if item[0] not in used
                        and col*cell[0]<=item[2]<(col+1)*cell[0]
                        and row*cell[1]<=item[3]<(row+1)*cell[1]]
                if not chosen:raise ValueError(f'Empty effect frame {row}/{col}')
                used.update(chosen)
                pieces.append(_isolated(image,alpha,labels,chosen,components,cell))
                continue
            candidates=[]
            for item in components:
                index,area,x,y=item
                if index in used:continue
                dx=(x-center[0])/cell[0];dy=(y-center[1])/cell[1]
                if abs(dx)>.72 or abs(dy)>.72:continue
                cost=dx*dx+dy*dy-.035*np.log(max(12,area))
                candidates.append((cost,item))
            if not candidates:raise ValueError(f'No complete projectile component at {row}/{col}')
            _,chosen=min(candidates,key=lambda v:v[0]);used.add(chosen[0])
            pieces.append(_isolated(image,alpha,labels,chosen[0],components,cell))
        output.append(pieces)
    return output

def actor_pieces(image,rows,source_regions=None):
    # Read the measured per-pose boxes when the source artist supplied them.
    # Otherwise derive complete horizontal pose bands before assigning columns.
    expected=6/(rows*2)
    if abs(image.width/image.height-expected)>expected*.025:
        raise ValueError(f'Actor source must be6x{rows*2}, got {image.size}')
    if source_regions is not None:
        if len(source_regions)!=rows*2 or any(len(row)!=6 for row in source_regions):
            raise ValueError('Measured source regions do not match the six-column layout')
        source_rows=[]
        for source_row in source_regions:
            poses=[]
            for x,y,w,h in source_row:
                cell=image.crop((x,y,x+w,y+h));alpha,labels,components=_components(cell)
                if not components:raise ValueError('Empty measured source pose')
                poses.append(_isolated(cell,alpha,labels,[item[0] for item in components],components,cell.size))
            source_rows.append(poses)
    else:
        alpha=np.asarray(image.getchannel('A'))
        occupied=np.count_nonzero(alpha>=24,axis=1)>=max(4,image.width*.004)
        labels,count=ndimage.label(occupied)
        spans=[]
        for region in ndimage.find_objects(labels):
            if region and region[0].stop-region[0].start>=8:
                spans.append([region[0].start,region[0].stop])
        # Tiny gaps within wings or antlers must not split one source row.
        bands=[]
        for start,end in spans:
            if bands and start-bands[-1][1]<=6:bands[-1][1]=end
            else:bands.append([start,end])
        if len(bands)!=rows*2:
            raise ValueError(f'Expected{rows*2} complete actor row bands, found{len(bands)}; supply measured source regions')
        source_rows=[]
        for top,bottom in bands:
            top=max(0,top-4);bottom=min(image.height,bottom+4)
            row_image=image.crop((0,top,image.width,bottom))
            row_alpha,row_labels,components=_components(row_image);poses=[]
            for col in range(6):
                selected=[item[0] for item in components if col*image.width/6<=item[2]<(col+1)*image.width/6]
                if not selected:raise ValueError(f'Empty actor source pose {len(source_rows)}/{col}')
                poses.append(_isolated(row_image,row_alpha,row_labels,selected,components,(image.width/6,bottom-top)))
            source_rows.append(poses)
    return [[source_rows[row*2+col//6][col%6] for col in range(12)] for row in range(rows)]

def build(biome):
    brief=json.loads((ROOT/f'{biome}-brief.json').read_text())
    projectile_rows=brief['projectile_rows']+brief['effect_rows']
    result={'biome':biome,'sheets':{},'projectiles':{}}
    for kind,cols,rows,side in [('regular',12,5,192),('elite',12,4,192),('projectiles',8,len(projectile_rows),128)]:
        source=ROOT/'source'/f'{biome}-{kind}.png'
        expanded=kind=='regular' and (ROOT.parent.parent/'v37/monsters/source'/f'{biome}-regular.png').exists()
        if expanded:source=ROOT.parent.parent/'v37/monsters/source'/f'{biome}-regular.png'
        image=Image.open(source).convert('RGBA')
        assert image.getextrema()[3][0]==0, f'{source}: missing true alpha'
        atlas=Image.new('RGBA',(cols*side,rows*side));frames=[];references=[];extents=[]
        measured_path=ROOT/f'{biome}-actor-v2-art.json'
        measured=json.loads(measured_path.read_text()).get(kind,{}).get('measured_cell_rects') if measured_path.exists() and not expanded else None
        extracted=projectile_pieces(image,rows) if kind=='projectiles' else actor_pieces(image,rows,measured)
        for row in range(rows):
            pieces=extracted[row];bounds=[]
            for col,piece in enumerate(pieces):
                alpha=piece.getchannel('A').point(lambda v:0 if v<8 else min(255,round(v/8)*8))
                piece.putalpha(alpha)
                box=alpha.point(lambda v:255 if v>=24 else 0).getbbox()
                assert box, f'{source}: empty row {row} column {col}'
                bounds.append(box)
            # A single scale per row avoids the breathing caused by fitting every
            # animation pose separately. Reserve 8% padding on all cell edges.
            maximum=max(max(b[2]-b[0],b[3]-b[1]) for b in bounds)
            scale=side*.84/max(1,maximum)
            row_heights=[];row_extents=[]
            for col,(piece,b) in enumerate(zip(pieces,bounds)):
                cropped=piece.crop(b)
                resized=cropped.resize((max(1,round(cropped.width*scale)),max(1,round(cropped.height*scale))),Image.Resampling.LANCZOS)
                ground=kind!='projectiles' or projectile_rows[row]['id']=='trap_fx'
                # Contact center follows the authored cell center, not silhouette
                # centroid, so asymmetric weapons do not pull the body sideways.
                foot_alpha=np.asarray(cropped.getchannel('A'))
                foot_y=max(0,int(cropped.height*.8))
                _,foot_x=np.where(foot_alpha[foot_y:]>=64)
                pivot_x=(float(np.median(foot_x)) if ground and len(foot_x) else cropped.width*.5)*scale
                left=round(side*.5-pivot_x)
                top=round(side*.90-resized.height) if ground else round(side*.5-resized.height*.5)
                # Clamp placement for exceptionally asymmetric blade/trail poses.
                padding=max(4,round(side*.04))
                left=max(padding,min(side-padding-resized.width,left));top=max(padding,min(side-padding-resized.height,top))
                frame=Image.new('RGBA',(side,side));frame.alpha_composite(resized,(left,top));atlas.alpha_composite(frame,(col*side,row*side))
                foot=[left+pivot_x,top+resized.height] if ground else [left+resized.width*.5,top+resized.height*.5]
                frames.append({'rect':[col*side,row*side,side,side],'pivot':foot,'bounds':[left,top,resized.width,resized.height]})
                if col<(6 if expanded else 3):row_heights.append((b[3]-b[1])*scale)
                row_extents.append(max(resized.size))
            references.append(statistics.median(row_heights));extents.append(statistics.median(row_extents))
        path=ROOT/f'{biome}-{kind}.webp'
        buffer=io.BytesIO();atlas.save(buffer,'WEBP',quality=90,method=4)
        temporary=path.with_suffix('.webp.tmp');temporary.write_bytes(buffer.getvalue());temporary.replace(path)
        result['sheets'][kind]={'path':path.name,'columns':cols,'rows':rows,'size':list(atlas.size),'frames':frames,'reference_heights':references,'source_grid':[8,rows] if kind=='projectiles' else [6,rows*2]}
        if expanded:result['sheets'][kind]['phase_columns']={'move':0,'windup':6,'active':8,'recovery':10};result['sheets'][kind]['phase_counts']={'move':6,'windup':2,'active':2,'recovery':2}
        if kind=='projectiles':
            for row,spec in enumerate(projectile_rows):
                result['projectiles'][spec['id']]={'row':row,'frames':8,'fps':16 if 'axial' in spec.get('rotation','') else 12,'rotation':spec.get('rotation','effect'),'body_extent':extents[row]}
    target=ROOT/f'{biome}-runtime.json';temporary=target.with_suffix('.json.tmp')
    temporary.write_text(json.dumps(result,ensure_ascii=False,separators=(',',':')));temporary.replace(target)
    print(biome,'frames:',sum(len(s['frames']) for s in result['sheets'].values()),'runtime bytes:',sum((ROOT/s['path']).stat().st_size for s in result['sheets'].values()),flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('biomes',nargs='*',default=['underground','trunk','sky'])
    for biome in parser.parse_args().biomes:build(biome)
