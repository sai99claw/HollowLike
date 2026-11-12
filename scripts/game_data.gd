class_name GameData
extends RefCounted
## Prototype tuning data. Unspecified design values remain replaceable here.
## All damaging actions have separate windup, active and recovery durations.

const PRIMARY: Array[Dictionary] = [
	{"id":"talons","name":"腳爪踢","name_en":"Bare Talons","style":"foot","color":Color("8af3da"),"description":"超快速 · 極短距離 · 強反作用力","charge_time":1.4,"damage_mult":2.0,"speed_mult":3.0,"range_mult":.65},
	{"id":"featherblade","name":"羽毛刀","name_en":"Feather Knife","style":"quick","color":Color("e0d8ff"),"description":"羽毛刀連擊 · 單C中攻擊為大刀斬擊 · 集氣為第三下旋斬","charge_time":1.4,"damage_mult":3.0,"speed_mult":1.5,"range_mult":1.0},
	{"id":"greatblade","name":"大刀","name_en":"Great Cleaver","style":"heavy","color":Color("ffc38d"),"description":"重攻擊 · 正砍／側砍／旋轉 · 強擊退","charge_time":1.4,"damage_mult":5.0,"speed_mult":.7,"range_mult":1.3}
]

const SECONDARY: Array[Dictionary] = [
	{"id": "needle", "name": "翠羽飛針", "kind": "shot", "description": "快速直射", "damage": 2.0, "shots": 1, "speed": 640.0, "color": Color("67e5d1"), "windup": 0.12, "active": 0.08, "recovery": 0.22, "energy": 1.0, "piercing": false},
	{"id": "scatter", "name": "橡實散射", "kind": "fan", "description": "三向散射", "damage": 1.1, "shots": 3, "speed": 540.0, "color": Color("f5c27c"), "windup": 0.19, "active": 0.09, "recovery": 0.33, "energy": 1.0, "piercing": false},
	{"id": "stone", "name": "流星果實", "kind": "throw", "description": "拋物線重擊", "damage": 3.0, "shots": 1, "speed": 430.0, "color": Color("ff916d"), "windup": 0.24, "active": 0.10, "recovery": 0.38, "energy": 1.0, "piercing": false},
	{"id": "moonblade", "name": "月翎刀", "kind": "flying_slash", "description": "寬幅飛行斬擊", "damage": 3.0, "shots": 1, "speed": 460.0, "range": 100.0, "width": 88.0, "color": Color("c6b6ff"), "windup": 0.21, "active": 0.17, "recovery": 0.31, "energy": 1.0, "piercing": false},
	{"id": "ricochet", "name": "迴響彈珠", "kind": "bounce", "description": "碰牆回彈", "damage": 1.8, "shots": 2, "speed": 570.0, "bounces": 3, "color": Color("91c5ff"), "windup": 0.16, "active": 0.08, "recovery": 0.29, "energy": 1.0, "piercing": false},
	{"id": "sunray", "name": "晨光束", "kind": "beam", "description": "貫穿光羽", "damage": 2.5, "shots": 1, "speed": 920.0, "color": Color("fff1b2"), "windup": 0.27, "active": 0.10, "recovery": 0.38, "energy": 1.0, "piercing": true},
	{"id":"multibounce","name":"星籽多重彈射","kind":"bounce","description":"五發彈珠，碰牆反射五次","damage":2.0,"shots":5,"bounces":5,"speed":510.0,"color":Color("9dcfff"),"windup":.2,"active":.1,"recovery":.3,"energy":1.0},
	{"id":"impact_bomb","name":"熾果爆裂砲","kind":"throw","description":"命中爆炸，波及鄰近敵人","damage":4.0,"shots":1,"speed":400.0,"explode_on_hit":true,"explosion_radius":125.0,"color":Color("ffb078"),"windup":.25,"active":.1,"recovery":.4,"energy":1.0},
	{"id":"piercing_laser","name":"穿星雷射","kind":"laser","description":"即時貫穿直線敵群，地形可阻擋","damage":3.0,"shots":1,"speed":0.0,"color":Color("c1f6ff"),"windup":.3,"active":.24,"recovery":.4,"energy":1.0,"piercing":true},
	{"id":"shockwave","name":"裂枝衝擊波","kind":"wave","description":"向左右釋放寬幅穿透震波","damage":3.0,"shots":2,"speed":460.0,"color":Color("e8d0ff"),"windup":.25,"active":.16,"recovery":.35,"energy":1.0,"piercing":true},
	{"id":"chain_staff","name":"連鎖雷擊法杖","kind":"chain","description":"自動索敵，跳躍連鎖最多五個目標","damage":3.0,"shots":1,"speed":0.0,"color":Color("b9c7ff"),"windup":.3,"active":.2,"recovery":.4,"energy":1.0},
	{"id":"homing_missile","name":"逐燈飛彈","kind":"homing","description":"緩速轉向追蹤可見目標","damage":2.5,"shots":1,"speed":360.0,"color":Color("91e5bc"),"windup":.2,"active":.1,"recovery":.3,"energy":1.0},
	{"id":"trap_pod","name":"棘種陷阱匣","kind":"trap","description":"拋出種莢，落地安置後刺擊","damage":2.0,"shots":1,"speed":380.0,"size":18.0,"range":700.0,"color":Color("b2d78a"),"windup":.2,"active":.1,"recovery":.3,"energy":1.0,"arming_time":.65,"lifetime":6.0,"max_hits":6,"hit_interval":.6},
	{"id":"fire_flask","name":"燼根燃燒瓶","kind":"throw","description":"拋物線落地，留下燃燒地板","damage":2.0,"shots":1,"speed":380.0,"ground_fire":true,"explosion_radius":140.0,"color":Color("ff9d60"),"windup":.2,"active":.1,"recovery":.3,"energy":1.0}


]

const ENEMIES: Array[Dictionary] = [
	{"id": "beetle", "name": "苔甲衛士", "hp": 5.0, "move": "walk", "speed": 64.0, "range": 60.0, "damage": 2.0, "windup": 0.43, "active": 0.16, "recovery": 0.55, "secondary": 0, "secondary_cooldown": 3.8, "color": Color("87aa84"), "scale": 1.0},
	{"id": "slinger", "name": "果實投手", "hp": 5.0, "move": "walk", "speed": 46.0, "range": 55.0, "damage": 2.0, "windup": 0.47, "active": 0.14, "recovery": 0.59, "secondary": 2, "secondary_cooldown": 2.4, "color": Color("d5a578"), "scale": 1.0},
	{"id": "moth", "name": "薄暮獵蛾", "hp": 5.0, "move": "fly", "speed": 79.0, "range": 52.0, "damage": 2.0, "windup": 0.38, "active": 0.14, "recovery": 0.45, "secondary": 0, "secondary_cooldown": 2.8, "color": Color("bc9dd3"), "scale": 0.9},
	{"id": "guardian", "name": "古枝守衛", "hp": 10.0, "move": "walk", "speed": 58.0, "range": 100.0, "damage": 2.0, "windup": 0.56, "active": 0.24, "recovery": 0.67, "secondary": 1, "secondary_cooldown": 3.0, "color": Color("c59e69"), "scale": 1.4},
	{"id": "boss", "name": "樹心巨靈", "hp": 60.0, "move": "walk", "speed": 72.0, "range": 150.0, "damage": 2.0, "windup": 0.70, "active": 0.28, "recovery": 0.85, "secondary": 2, "secondary_cooldown": 2.7, "color": Color("dbb17b"), "scale": 2.5}
]

## Temporary prototype effects only; rune design is intentionally still open.
## Small runes keep positional slots; same-species orthogonal links amplify their total effect.
const RUNES: Array[Dictionary] = [
	{"id": "gale", "name": "風羽", "icon": "W", "color": Color("76e3d2"), "desc": "前後搖時間縮短6%", "description": "前後搖時間縮短6%", "effect": "haste", "value": 0.06},
	{"id": "reach", "name": "長翎", "icon": "R", "color": Color("c1b7ff"), "desc": "主武器觸及距離增加", "description": "主武器觸及距離增加", "effect": "reach", "value": 0.07},
	{"id": "soul", "name": "晨露", "icon": "E", "color": Color("8fdbff"), "desc": "近戰命中取得額外能量", "description": "近戰命中取得額外能量", "effect": "energy", "value": 0.15},
	{"id": "guard", "name": "苔盾", "icon": "G", "color": Color("a6d99b"), "desc": "受擊後保護時間增加", "description": "受擊後保護時間增加", "effect": "guard", "value": 0.07},
	{"id": "midas", "name": "金穗", "icon": "M", "color": Color("eac479"), "desc": "金幣吸取距離增加", "description": "金幣吸取距離增加", "effect": "magnet", "value": 20.0},
	{"id": "leech", "name": "赤芽", "icon": "L", "color": Color("ec939a"), "desc": "擊倒敵人時2.5%機率回血1格", "description": "擊倒敵人時2.5%機率回血1格", "effect": "leech", "value": 0.025},
	{"id": "wing", "name": "浮雲", "icon": "J", "color": Color("cadfec"), "desc": "跳躍高度微幅提升", "description": "跳躍高度微幅提升", "effect": "wing", "value": 0.025},
	{"id": "pierce", "name": "穿葉", "icon": "P", "color": Color("f1bd92"), "desc": "副武器穿透能力增加", "description": "副武器穿透能力增加", "effect": "pierce", "value": 1.0},
	{"id":"dewflow","name":"湧泉","icon":"E+","color":Color("91dcff"),"desc":"每8秒自動回復1格能量","description":"每8秒自動回復1格能量","effect":"energy_regen","value":.125},
	{"id":"swarm","name":"蜂群","icon":"B","color":Color("ffe297"),"desc":"召喚1隻蜜蜂，每秒攻擊；每條同種連線再+1隻","description":"召喚1隻蜜蜂，每秒攻擊；每條同種連線再+1隻","effect":"orbit_bee","value":1.0},
	{"id":"multishot","name":"繁羽","icon":"+","color":Color("d9b6ff"),"desc":"副武器投射物數量+1","description":"副武器投射物數量+1","effect":"projectile_count","value":1.0},
	{"id":"sub_velocity","name":"疾矢","icon":"V","color":Color("79dbd0"),"desc":"附武器投射物速度 +15%","description":"附武器投射物速度 +15%","effect":"sub_speed","value":.15},
	{"id":"sub_reach","name":"遠星","icon":"D","color":Color("abb9f7"),"desc":"附武器射程 +15%","description":"附武器射程 +15%","effect":"sub_range","value":.15},
	{"id":"sub_power","name":"熾羽","icon":"P+","color":Color("eeaa87"),"desc":"附武器傷害 +15%","description":"附武器傷害 +15%","effect":"sub_damage","value":.15},
	{"id":"sub_volume","name":"盛羽","icon":"S+","color":Color("daa8ee"),"desc":"投射物尺寸及爆炸範圍 +5%","description":"投射物尺寸及爆炸範圍 +5%","effect":"sub_size","value":.05},
	{"id":"rapid_slash","name":"疾刃","icon":"W","color":Color("a4eee0"),"desc":"普攻與斬擊動畫速度 +10%","description":"普攻與斬擊動畫速度 +10%","effect":"attack_rate","value":.10},
	{"id":"quick_charge","name":"聚羽","icon":"E","color":Color("a7dfff"),"desc":"武器與升空集氣時間縮短12%","description":"武器與升空集氣時間縮短12%","effect":"charge_cut","value":.12},
	{"id":"fleet_foot","name":"輕足","icon":"J","color":Color("c2e9ad"),"desc":"移動與跑速 +10%","description":"移動與跑速 +10%","effect":"run_speed","value":.10}



]

const STRONG_RUNES:Array[Dictionary]=[
	{"id":"reflect","name":"返羽","effect":"reflect","value":1.0,"desc":"斬擊反彈投射物","description":"斬擊反彈投射物","icon":"↗","color":Color("c9e9ff"),"strong":true},
	{"id":"longblade","name":"長空","effect":"reach_mult","value":.5,"desc":"攻擊距離 ×1.5","description":"攻擊距離 ×1.5","icon":"↔","color":Color("d5c5ff"),"strong":true},
	{"id":"swiftblade","name":"瞬羽","effect":"haste_mult","value":.5,"desc":"前後搖縮短三分之一","description":"前後搖縮短三分之一","icon":"»","color":Color("9de4ce"),"strong":true},
	{"id":"sanctuary","name":"靜癒","effect":"heal_guard","value":1.0,"desc":"回血引導時無法移動並無敵","description":"回血引導時無法移動並無敵","icon":"+","color":Color("b5e7b5"),"strong":true},
	{"id":"orbit_shield","name":"環羽盾","effect":"orbit_shield","value":1.0,"desc":"身邊環繞的盾可攔截投射物","description":"身邊環繞的盾可攔截投射物","icon":"◇","color":Color("b4d0ff"),"strong":true},
	{"id":"orbit_bee","name":"蜜使","effect":"orbit_bee","value":1.0,"desc":"環繞蜜蜂自動攻擊可見敵人","description":"環繞蜜蜂自動攻擊可見敵人","icon":"B","color":Color("ffe09a"),"strong":true},
	{"id":"motion_energy","name":"行風","effect":"motion_energy","value":1.0,"desc":"實際移動累積距離回復能量","description":"實際移動累積距離回復能量","icon":"E","color":Color("a3eadc"),"strong":true},
	{"id":"bloodblade","name":"汲命","effect":"lifesteal","value":.12,"desc":"有效命中時12%機率回復1格生命","description":"有效命中時12%機率回復1格生命","icon":"♥","color":Color("efa6b5"),"strong":true},
	{"id":"heartplus","name":"豐羽","effect":"max_hp","value":1.0,"desc":"最大生命 +1","description":"最大生命 +1","icon":"♥+","color":Color("f3c9a4"),"strong":true},
	{"id":"single_pierce","name":"穿風","effect":"single_pierce","value":1.0,"desc":"單按衝刺直接穿刺","description":"單按衝刺直接穿刺","icon":"»","color":Color("c9e9ff"),"strong":true},
	{"id":"held_flight","name":"浮翼","effect":"held_flight","value":1.0,"desc":"長按跳躍飛行","description":"長按跳躍飛行","icon":"↑","color":Color("d5c5ff"),"strong":true},
	{"id":"poison_trail","name":"毒羽","effect":"poison_trail","value":1.0,"desc":"移動留下毒氣三秒，每秒扣一血","description":"移動留下毒氣三秒，每秒扣一血","icon":"◇","color":Color("a1d68a"),"strong":true},
	{"id":"steady_energy","name":"蓄風","effect":"energy_regen","value":.5,"desc":"每兩秒回復一格能量","description":"每兩秒回復一格能量","icon":"E","color":Color("a3eadc"),"strong":true}
]
static func all_runes() -> Array:
	return RUNES+STRONG_RUNES
static func is_strong(id:String) -> bool:
	for rune in STRONG_RUNES:
		if rune["id"]==id:return true
	return false

const ITEMS: Array[Dictionary] = [
	{"id": "heal", "name": "暖心莓果", "desc": "回復兩格生命", "description": "回復兩格生命", "color": Color("99dca2")},
	{"id": "energy", "name": "晨露瓶", "desc": "補滿能量", "description": "補滿能量", "color": Color("88d5f4")},
	{"id": "shock", "name": "震波果", "desc": "強力擊退半個畫面的敵人", "description": "強力擊退半個畫面的敵人", "color": Color("f6b072")},
	{"id": "shield", "name": "羽絨護盾", "desc": "召喚兩面旋轉護盾，持續一分鐘", "description": "召喚兩面旋轉護盾，持續一分鐘", "color": Color("c3bbfa")},
	{"id": "freeze", "name": "霜葉", "desc": "大範圍凍結敵人兩秒", "description": "大範圍凍結敵人兩秒", "color": Color("b2e5ee")},
	{"id":"power","name":"赤羽果","desc":"普通攻擊傷害增加20%，持續兩分鐘","description":"普通攻擊傷害增加20%，持續兩分鐘","color":Color("ff705d")}
]

## A short first adventure opens the whole movement language.
## Root owns evaluation and persistence; attempts are alternate low-barrier paths.
const SKILLS: Array[Dictionary] = [
	{"id": "doublejump", "name": "二段跳", "desc": "空中再次按跳躍", "description": "空中再次按跳躍", "rooms": 0, "attempts": 1},
	{"id": "wall", "name": "貼牆與牆跳", "desc": "貼牆靜止 0.5 秒後下滑，按跳躍離牆", "description": "貼牆靜止 0.5 秒後下滑，按跳躍離牆", "rooms": 0, "attempts": 1},
	{"id": "dash_horizontal", "name": "穿刺雙衝", "desc": "0.5 秒內連按兩下 C", "description": "0.5 秒內連按兩下 C", "rooms": 1, "attempts": 2},
	{"id": "charge_horizontal", "name": "橫向集氣斬", "desc": "長按主攻擊，左右方向放開", "description": "長按主攻擊，左右方向放開", "rooms": 1, "attempts": 2},
	{"id": "dash_vertical", "name": "下砸穿刺", "desc": "下方向連按 C，下衝落地造成震波；上衝已移除", "description": "下方向連按 C，下衝落地造成震波；上衝已移除", "rooms": 2, "attempts": 2},
	{"id": "charge_vertical", "name": "縱向集氣斬", "desc": "蓄力後朝上或朝下放開", "description": "蓄力後朝上或朝下放開", "rooms": 3, "attempts": 3},
	{"id": "dashcharge", "name": "衝刺集氣斬", "desc": "蓄力後在衝刺期間放開主攻擊", "description": "蓄力後在衝刺期間放開主攻擊", "rooms": 4, "attempts": 3}
]


static func primary_attack(index:int,direction:String,charged:bool,dash_charge:bool=false,combo:int=0) -> Dictionary:
	var weapon:Dictionary=PRIMARY[clampi(index,0,2)]
	var style:String=weapon["style"]
	var step:int=posmod(combo,3)
	var def:Dictionary={"kind":"charge" if charged else "primary","library_kind":"slash","primary":true,"parryable":true,"count":1,"direction":direction,"style":style,"charged":charged,"dash_charge":dash_charge,"damage":float(weapon["damage_mult"]),"windup":0.0,"active":.065,"recovery":0.0,"range":37.0,"width":38.0,"shape":"kick","knockback":0.0,"recoil":60.0,"energy_gain":1.0,"color":weapon["color"],"combo":step,"fx_clip":"claw_kick","super_armor":charged,"block_width":38.0}
	if style=="quick":
		def.merge({"windup":.035,"active":.11,"recovery":.1 if step<2 else .19,"range":66.0,"width":54.0 if step<2 else 22.0,"block_width":54.0 if step<2 else 10.0,"shape":"arc" if step<2 else "thrust","knockback":60.0,"recoil":30.0,"fx_clip":["feather_left","feather_right","feather_thrust"][step]},true)
	elif style=="heavy":
		def.merge({"windup":.30 if step<2 else .40,"active":.24 if step<2 else .38,"recovery":.43 if step<2 else .55,"range":85.0,"width":78.0,"block_width":78.0,"shape":"cleave" if step<2 else "spin","knockback":120.0,"recoil":0.0,"fx_clip":["heavy_front","heavy_side","heavy_spin"][step]},true)
	if charged:
		def["damage"]=ceilf(float(def["damage"])*1.5);def["active"]=1.5;def["energy_gain"]=2.0
		if style=="foot":def.merge({"windup":.10,"recovery":.18,"range":100.0,"width":55.0,"knockback":120.0,"recoil":0.0,"fx_clip":"claw_charge"},true)
		elif style=="quick":def.merge({"windup":.18,"recovery":.22,"range":105.0,"width":100.0,"shape":"spin","knockback":60.0,"recoil":30.0,"fx_clip":"dream_feather_charge"},true)
		else:def.merge({"windup":.5,"recovery":.55,"range":165.0,"width":140.0,"shape":"ground_wave","knockback":120.0,"recoil":0.0,"fx_clip":"heavy_charge"},true)
	def["range"]*=1.2;def["width"]*=1.2;def["block_width"]*=1.2;def["active"]*=2.4;def["windup"]*=2.0;def["recovery"]*=2.0;def["hitbox_scale"]=1.2
	if style=="quick":
		def["hitbox_height_mult"]=1.2;def["animation_speed"]=1.5
		def["windup"]/=1.5;def["recovery"]/=1.5
		if not charged:def["active"]/=1.5
	if charged:
		# The full released animation, including its authored anticipation and finish,
		# fits this one second. Normal attacks retain their separate outer phases.
		def.merge({"windup":0.0,"active":1.0,"recovery":0.0,"recoil":0.0,"complete_release":true},true)
	if not charged:
		var cadence:float=float(def["windup"])+float(def["active"])+float(def["recovery"])
		def["windup"]=0.0;def["active"]=[.09,.12,.16][clampi(index,0,2)]
		def["recovery"]=maxf(0,cadence-float(def["active"]))
	def["size"]=float(def["width"])*.5
	return def

## Old profiles remain available to the animation library, not as selectable weapons.
static func action_attack(direction:String,charged:bool,during_dash:bool,combo:int=0) -> Dictionary:
	var def:Dictionary=primary_attack(2 if charged or during_dash else 1,direction,false,false,2 if charged else posmod(combo,2))
	def["dash_attack"]=during_dash
	if during_dash:def["recovery"]=0.0
	if not charged:
		if not during_dash:
			def["body_clip"]={"up":"pigeon_featherblade_up","down":"pigeon_featherblade_down"}.get(direction,["pigeon_feather_left","pigeon_feather_right"][posmod(combo,2)])
	else:
		def.merge({"kind":"charge","charged":true,"great_spin_release":true,"windup":0.0,"active":1.0,"recovery":0.0,"recoil":0.0,"energy_gain":2.0,"super_armor":true,"complete_release":true},true)
	return def

static func secondary_attack(index:int) -> Dictionary:
	var result:Dictionary=SECONDARY[clampi(index,0,SECONDARY.size()-1)].duplicate(true)
	result["primary"]=false;result["weapon_kind"]=result["kind"];result["kind"]="secondary";result["energy_gain"]=0.0
	if result["weapon_kind"]=="flying_slash":result["size"]=22.0;result["piercing"]=true
	result["damage"]=float(result.get("damage",3));result["knockback"]=76.0;result["size"]=22.0 if result["weapon_kind"]=="flying_slash" else 8.0;result["range"]=900.0
	result["windup"]=0.0
	result["library_kind"]="slash" if result["weapon_kind"]=="sword" else ("arc" if result["weapon_kind"]=="throw" else "linear")
	if result["weapon_kind"]=="wave":result["size"]=32.0;result["style_id"]="shockwave"
	result["count"]=int(result.get("shots",1));result["path_kind"]="arc" if result["library_kind"]=="arc" else "straight"
	return result

static func normalize_secondary(source:Dictionary) -> Dictionary:
	var result:Dictionary={}
	for i in SECONDARY.size():
		if source.get("id","")==SECONDARY[i]["id"]:result=secondary_attack(i);break
	if result.is_empty():result=secondary_attack(0)
	result.merge(source,true)
	var kind:String=str(source.get("weapon_kind",source.get("kind",result.get("weapon_kind","shot"))))
	if kind=="secondary":kind=str(result.get("weapon_kind","shot"))
	kind={"linear":"shot","arc":"throw","slash":"sword"}.get(kind,kind)
	result["weapon_kind"]=kind;result["kind"]="secondary";result["windup"]=0.0
	if result.get("color") is String:result["color"]=Color(result["color"])
	return result
