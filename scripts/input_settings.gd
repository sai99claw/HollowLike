class_name InputSettings
extends RefCounted
const DEFAULTS:Dictionary={"left":KEY_LEFT,"right":KEY_RIGHT,"up":KEY_UP,"down":KEY_DOWN,"jump":KEY_SPACE,"attack":KEY_X,"dash":KEY_C,"sub":KEY_Z,"heal":KEY_A,"interact":KEY_E,"bag":KEY_I,"runes":KEY_R,"skills":KEY_K,"map":KEY_TAB,"cycle":KEY_Q,"primary_1":KEY_1,"primary_2":KEY_2,"primary_3":KEY_3,"settings":KEY_ESCAPE}
const NAMES:Dictionary={"left":"向左","right":"向右","up":"向上／站點互動","down":"向下","jump":"跳躍","attack":"普攻／集氣","dash":"衝刺／雙 C 穿刺","sub":"副武器","heal":"長按回血","interact":"裝備狀態面板","bag":"背包","runes":"符文盤","skills":"技能樹","map":"地圖","cycle":"切換副武器","primary_1":"主武器 1","primary_2":"主武器 2","primary_3":"主武器 3","settings":"開關選單"}
static func load_bindings(raw:Variant) -> Dictionary:
	var result:Dictionary=DEFAULTS.duplicate()
	if raw is Dictionary:
		for action in DEFAULTS:
			var value:Variant=raw.get(action,DEFAULTS[action])
			if value is int or value is float:result[action]=int(value)
	# Escape always remains a way out; invalid / duplicate saved bindings fall back.
	result["settings"]=KEY_ESCAPE
	var used:Dictionary={KEY_ESCAPE:"settings"}
	for action in result:
		if action=="settings":continue
		var key:int=int(result[action])
		if key<=0 or key==KEY_ESCAPE or used.has(key):result[action]=0
		else:used[key]=action
	return result
static func label(code:int) -> String:return "未設定" if code<=0 else OS.get_keycode_string(code)
static func action_for(bindings:Dictionary,code:int) -> String:
	for action in bindings:
		if int(bindings[action])==code:return str(action)
	return ""
static func assign(bindings:Dictionary,action:String,code:int) -> bool:
	if not DEFAULTS.has(action) or action=="settings" or code==KEY_ESCAPE or code<=0:return false
	var old:int=int(bindings.get(action,0))
	var other:String=action_for(bindings,code)
	if other!="" and other!=action:bindings[other]=old
	bindings[action]=code
	return true
