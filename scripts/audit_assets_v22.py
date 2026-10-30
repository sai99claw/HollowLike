"""Audit active render routes and source-pixel density; do not alter PNG pixels."""
from pathlib import Path
import argparse,json,re,collections
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
parser=argparse.ArgumentParser();parser.add_argument('catalog',type=Path);args=parser.parse_args()
items=json.loads(args.catalog.read_text())
def read(path):return json.loads((ROOT/path).read_text())
source='\n'.join(p.read_text() for p in (ROOT/'scripts').glob('*.gd') if not (p.name.startswith('rd_') or p.name in ['art_catalog_v16.gd','practice_rd_v22.gd','room_layout.gd']))
literals=set(re.findall(r'"([a-z0-9_./:-]+)"',source))
inventory=read('assets/inventory_v11/manifest.json')
new_libraries={key:read('assets/v22/'+key+'-manifest.json') for key in ['death','trap','monster-actions','boss-actions','pigeon-motion']}
move=read('assets/v18/monster-motion-manifest.json');idle=read('assets/v19/idle-manifest.json')
primary={'pigeon_talons_kick','pigeon_feather_left','pigeon_feather_right','pigeon_feather_thrust','pigeon_great_front','pigeon_great_side','pigeon_great_spin','pigeon_talons_up','pigeon_talons_down','pigeon_featherblade_up','pigeon_featherblade_down','pigeon_greatblade_up','pigeon_greatblade_down','pigeon_talons_charge','pigeon_feather_charge','pigeon_great_charge','pigeon_hurt','pigeon_death','pigeon_soul','pigeon_return'}
old_slashes={'claw_kick','feather_left','feather_right','feather_thrust','heavy_front','heavy_side','heavy_spin'}
def used(item):
 id=item['id']
 if id.startswith('v22:monster-actions:pillbug_') and not id.endswith('_hurt'):return False,'可愛遊盪者不攻擊；這些預備動作只供RD展示。'
 if id.startswith(('v22:','motion:v18:','idle:v19:','slash:v18','home:','wind:','explosion:','inventory:')):return True,'目前遊戲的角色、互動、裝備或效果路徑。'
 if id.startswith('v21:'):return not id.startswith('v21:terrain:'),'v21物件／邊緣／中景仍在使用；舊地形已由v22取代。'
 if id.startswith('ecology:'):
  return ':object:' in id or id.endswith((':far',':near')),'三生態背景、前景或可砍物件；舊中景與地形已停用。'
 if id=='ambient:dragonfly' or id=='merchant:owl':return True,'遊戲中的環境生物／商人。'
 if id in ['ambient:bird','spring:legacy','merchant:mid'] or id.startswith('illustrated:'):return False,'舊版或替代素材，已由目前圖集取代。'
 if id.startswith('merchant:'):return id.endswith(':far'),'商人房背景使用；舊中景已移除。'
 if id.startswith('pigeon_action:'):return True,'目前回血、跛行與風技前後姿態。'
 if id.startswith('walk_v2:'):return id.endswith('pigeon_walk_master'),'行走只使用256px主圖集；80px舊版保留。'
 if id.startswith('sanctuary:'):return id.split(':')[-1] in ['pool_back','pool_front','water','steam','table','dummy'],'目前商店桌面、假人與溫泉互動。'
 if id.startswith('monster_projectile:'):return id.split(':')[-1] not in ['cute_pillbug','moss_thorns','pollen_flower','silk_web','dew_pool'],'生態投射物仍使用；陷阱與鼠婦本體已由獨立動畫取代。'
 if id.startswith('bosses:'):return id.endswith(('_slash_fx','_impact')),'首領刀光／命中特效保留；舊身體和投射物已取代。'
 if id.startswith('combat_v05:'):
  clip=id.split(':',1)[1]
  if clip.startswith(('enemy_','elite_')):return False,'怪物身體已使用v18移動及v22攻擊、受傷、死亡原畫。'
  if clip.startswith('pigeon_'):return clip in primary or clip in literals,'目前角色動作；舊替代姿態不再繪製。'
  if clip in old_slashes:return False,'普攻已改用獨立v18月牙刀光。'
  if clip.startswith(('runes_','strong_','items_','secondary_')):
   key=clip.removeprefix('runes_').removeprefix('strong_')
   group='runes' if clip.startswith(('runes_','strong_')) else 'items'
   if key in inventory.get(group,{}):return False,'此圖示已由新背包圖集取代。'
   return True,'背包、技能或掉落物使用的圖示／保留的武器特效。'
  if clip.startswith(('skills_','growth_','weapon_','projectile_','flying_slash_','beam_')):return True,'目前技能／武器／投射物路徑。'
  parts=clip.split('_')
  if parts[0] in ['sky','trunk','underground','canopy','branches','grass']:
   return parts[0] in ['sky','trunk','underground'] and any(word in clip for word in ['_energy_','_fullheal_','_ambient_']),'當前3生態的互動物件與微粒；舊生態和方塊素材保留。'
  return clip in literals,'目前效果呼叫使用的ID；未被呼叫的版本保留。'
 if id.startswith('procedural:'):return id!='procedural:grass','遊戲即時門光與水面；草叢程式示例只在RD展示。'
 if id.startswith('raw:'):
  path='res://assets/'+id[4:]
  return path in source and not path.startswith('res://assets/motion_v13/merchant-'),'程式直接參照的圖檔；未參照來源保留。'
 return False,'保留於貼圖庫，未接入目前遊戲畫面。'

def density(item):
 id=item['id'];ratio=None;reason='依用途顯示；背景、粒子、圖示使用各自固定尺寸。'
 if id.startswith('v22:'):
  parts=id.split(':');library=parts[1]
  if library in new_libraries:
   c=new_libraries[library].get('clips',new_libraries[library].get('animations',{})).get(':'.join(parts[2:]),{})
   if c:ratio=float(c.get('reference_height',c.get('reference_width',1)))/float(c.get('world_height',c.get('world_width',1)))
  elif library=='material':
   c=read('assets/v22/surfaces-manifest.json')['biomes'][parts[2]]['material'];ratio=c['source_rect'][2]/288
  elif library=='platform':
   c=read('assets/v22/surfaces-manifest.json')['biomes'][parts[2]]['platforms'][parts[3]];ratio=c['body_source_rect'][2]/(96*int(parts[3]))
  elif library=='water_attack':ratio=444/176
 elif id.startswith('motion:v18:'):
  c=move['animations'][id.split(':')[-1]];ratio=c['reference_height']/c['world_height']
 elif id.startswith('idle:v19:'):
  c=idle['animations'][id.split(':')[-1]];ratio=c['reference_height']/idle['world_height']
 elif id=='walk_v2:pigeon_walk_master':ratio=256/80
 elif id.startswith('illustrated:') or (id.startswith('bosses:') and id.endswith(('_move','_melee','_ranged'))):
  ratio=1;reason='舊版原生尺寸過小，已有高解析替代；標記un-used。'
 if ratio is not None:
  return round(ratio,3),f'來源密度 {ratio:.2f} px／遊戲像素；以固定比例繪製。'+(' 舊低解析版本已停用。' if ratio<1.8 and not used(item)[0] else '')
 return None,reason
entries={};file_uses=collections.defaultdict(list)
for item in items:
 active,note=used(item);ratio,dnote=density(item)
 entries[item['id']]={'runtime_usage':'used' if active else 'un-used','usage_note':note,'source_pixels_per_world_pixel':ratio,'density_note':dnote}
 if active:
  for f in item['frames']:
   if f.get('path','').startswith('res://assets/'):file_uses[f['path'].removeprefix('res://')].append(item['id'])
files={}
for path in sorted((ROOT/'assets').rglob('*')):
 if path.suffix.lower() not in ['.png','.webp','.jpg','.jpeg']:continue
 with Image.open(path) as image:dimensions=list(image.size)
 relative=path.relative_to(ROOT).as_posix();refs=sorted(set(file_uses[relative]))
 files[relative]={'dimensions':dimensions,'runtime_usage':'used' if refs else 'un-used','entry_ids':refs}
counts=collections.Counter(x['runtime_usage'] for x in entries.values());file_counts=collections.Counter(x['runtime_usage'] for x in files.values())
result={'version':22,'method':'Reachability audit of the active renderer, dynamic clip routers and source image references. RD-only previews and historical fallbacks count as un-used; this is implementation status, not whether the current player has encountered an asset. PhysicalprintPPI is not meaningful for a game; density is native sourcepixels perworldpixel atfixedactor/material scale.','entries':entries,'files':files,'summary':{'entries':dict(counts),'files':dict(file_counts)}}
(ROOT/'assets/v22/asset-audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
text=f'''# v0.22 貼圖使用與清晰度稽核\n\n目前圖庫共{len(items)}項素材、{len(files)}張來源圖。素材已實裝{counts['used']}項，標記`un-used` {counts['un-used']}項；來源圖使用{file_counts['used']}張、保留未使用{file_counts['un-used']}張。\n\n「已使用」表示目前遊戲的渲染路徑有接入；RD預覽本身、歷史備用圖及已替換版本不算。原圖保留，沒有刪除。\n\n## 密度與替換\n\n以來源像素／遊戲世界像素比較，不能用列印PPI判斷。舊跳躍、貼牆及首領身體多為約1:1，現在由v0.22獨立原畫取代。一般怪物攻擊／受傷由約70～150px角色改為約164～334px角色，並使用一物種一個固定比例。\n\n- 保留原行走主圖256px（3.2px／遊戲像素）。\n- 新三生態地形內部560～640px，覆蓋288世界像素，並先畫不透明底，四邊填滿碰撞框。鏡像方向每6格才改變。\n- 每種生態1／2／3／4格平台各有獨立圖，固定等比標定。\n- 新死亡12種、陷阱4種，以及主角空中／貼牆／瞌睡動作皆為獨立原畫。\n- 清晰度仍需在實際WebGL畫面確認；純資料稽核不能保證不同原畫筆觸完全一致。\n\n## 使用狀態\n\n完整逐項、逐檔記錄在`assets/v22/asset-audit.json`。RD矩陣可按分類、動靜態、使用狀態與名稱／ID搜尋，且每項可複製ID。\n\n原v0.15的18種小物件現在會混入地圖可砍物件，保留其破壞動畫；舊中景背景已停用，改為大型／中型世界物件的暗色半透明版本。\n'''
(ROOT/'docs/asset-audit-v22.md').write_text(text)
print(json.dumps(result['summary'],ensure_ascii=False))
