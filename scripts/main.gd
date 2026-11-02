extends Node2D
## Playable vertical slice. All damaging actions use the same three-phase clock.
const StationView=preload("res://scripts/station_view_v26.gd")
const StationStock=preload("res://scripts/station_inventory_v26.gd")
const GroundFire=preload("res://scripts/ground_fire_v27.gd")
const ChoiceView=preload("res://scripts/choice_view_v27.gd")
const MenuView=preload("res://scripts/menu_view_v27.gd")
const Arsenal=preload("res://scripts/arsenal_v24.gd")
const Equipment=preload("res://scripts/equipment_view_v24.gd")
const WeaponArt=preload("res://scripts/weapon_art_v24.gd")
const ProjectileReadability=preload("res://scripts/projectile_readability_v25.gd")
const LaunchArt=preload("res://scripts/launch_object_v23.gd")
const NewBiome=preload("res://scripts/biome_art_v21.gd")
const CorpseField=preload("res://scripts/corpse_field_v21.gd")
const Tuning=preload("res://scripts/rd_tuning_v19.gd")
const TuningPanel=preload("res://scripts/rd_tuning_panel_v19.gd")
const IdleArt=preload("res://scripts/pigeon_idle_v19.gd")
const PlayerMotion=preload("res://scripts/player_motion_v18.gd")
const EnemyCanvas=preload("res://scripts/enemy_canvas_v18.gd")
const SlashArt=preload("res://scripts/slash_art_v18.gd")
const Attack = preload("res://scripts/attack_state.gd")
const Tower = preload("res://scripts/tower.gd")
const Data = preload("res://scripts/game_data.gd")
const Dream=preload("res://scripts/musou_dream_v41.gd")
var dream=Dream.new()
var dream_visual:Node2D
const Art = preload("res://scripts/art.gd")
const UI = preload("res://scripts/game_ui.gd")
const Cache = preload("res://scripts/cached_canvas.gd")
const BiomeArt=preload("res://scripts/biome_art_v15.gd")
const Scale=preload("res://scripts/world_scale_v17.gd")
const Layout = preload("res://scripts/room_layout.gd")
const CoinField=preload("res://scripts/coin_field_v16.gd")
const RD=preload("res://scripts/rd_room_v16.gd")
const PracticeRD=preload("res://scripts/practice_rd_v22.gd")
const Explosion=preload("res://scripts/explosion_v16.gd")
const Coins = preload("res://scripts/coin_physics.gd")
const Bindings = preload("res://scripts/input_settings.gd")
const Combat = preload("res://scripts/combat_library.gd")
const BossVisual = preload("res://scripts/boss_art.gd")
const BossDirector=preload("res://scripts/boss_director_v35.gd")
const MonsterRoster=preload("res://scripts/monster_roster_v36.gd")
const Motion = preload("res://scripts/enemy_motion.gd")
const MonsterMotion=preload("res://scripts/monster_motion_v18.gd")
const Sprites = preload("res://scripts/sprite_art.gd")
const Ecology = preload("res://scripts/ecology.gd")
const Arms=preload("res://scripts/armament.gd")
const Coll=preload("res://scripts/world_collision.gd")
const RuneLinks=preload("res://scripts/rune_links.gd")
const Bag=preload("res://scripts/expedition_bag.gd")
const Music=preload("res://scripts/room_music.gd")
const Atmosphere=preload("res://scripts/atmosphere.gd")
const Walk=preload("res://scripts/walk_animation.gd")
const Feedback=preload("res://scripts/combat_feedback.gd")
const EnvArt=preload("res://scripts/environment_art.gd")
const TowerMap=preload("res://scripts/tower_map_view.gd")
const FX=preload("res://scripts/combat_visual.gd")
const MonsterDesign=preload("res://scripts/monster_design.gd")
const TrapArt=preload("res://scripts/trap_visual_v22.gd")
const WorldDetail=preload("res://scripts/world_detail.gd")
const Sanctuary=preload("res://scripts/sanctuary_room.gd")
const Ledge=preload("res://scripts/ledge_mantle_v37.gd")
const Bath=preload("res://scripts/bath_water.gd")
const WorldItems=preload("res://scripts/world_item_art.gd")
const HomeArt=preload("res://scripts/home_art.gd")
const Wind=preload("res://scripts/wind_art.gd")
const SanctuaryArt=preload("res://scripts/sanctuary_art.gd")
const Adventure=preload("res://scripts/adventure_visual.gd")
const CONTACT_DAMAGE: float = 1.0
const CONTACT_KNOCKBACK: float = 34.0 * 0.8
const KNOCKBACK_TIME: float = 0.12
const MAX_PARTICLES: int = 180
const MAX_FLOATERS: int = 32

const ROOM_W: float = 1500.0
const ROOM_H: float = 1120.0
const FLOOR_Y: float = 1050.0
const GRAVITY: float = 1250.0
const MOVE_SPEED: float = 330.0
const JUMP_SPEED: float = 530.0
const SAVE_PATH = "user://pigeon_tower_v1.json"
const SKINS = [
	{"name":"原皮", "price":0, "color":Color.WHITE,"id":"original"},
	{"name":"潮流風格披風", "price":0, "color":Color.WHITE,"id":"street"},
	{"name":"未來科技披風", "price":0, "color":Color.WHITE,"id":"future"},
	{"name":"中古世紀披風", "price":0, "color":Color.WHITE,"id":"medieval"},
	{"name":"可愛少女披風", "price":0, "color":Color.WHITE,"id":"cute"}
]

var equipment_page:int=0
var equipment_open:bool=false
var reforge_selection:Array[String]=[]
var reforge_result:String=""
var reforge_result_id:String=""
var forge_result:Dictionary={}
var menu_category:String="adventure"
var warehouse_filter:String="all"
var edge_background:Node2D
var ui: CanvasLayer
var font: Font
var clock: float = 0.0
var idle_time:float=0.0
var tuning_view:Control
var real_clock:float=0.0
var enemy_canvases:Dictionary={}
var slash_canvas:Node2D
var home_sleeping:bool=true
var home_wake_left:float=0
var screen: String = "hub"
var spring_particles:Node2D
var home_atmosphere:Node2D
var mode: String = "rogue"
var meta: Dictionary = {"coins":0,"runes":{"gale":1,"reach":1,"guard":1},"skills":[],"attempts":0,"skins":[0],"skin":0,"best_map":0,"rd_tuning":{},"items":{},"weapons":[],"records":[],"blueprints":[],"settings":{"zoom":1.3,"speed":.8,"keys":{}}}
var tower: Dictionary = {}
var current_room: int = -1
var room: Dictionary = {}
var platforms: Array[Rect2] = []
var doors: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var floaters: Array[Dictionary] = []
var camera_zoom:float=1.3
var key_bindings:Dictionary=Bindings.DEFAULTS.duplicate()
var capturing_key:String=""
var camera_pos: Vector2 = Vector2.ZERO
var shake: float = 0.0
var hitstop: float = 0.0
var room_cooldown: float = 0.0
var freeze_timer: float = 0.0
var heal_timer: float = 0.0
var charge_timer: float = 0.0
var visited_count: int = 0
var revive_used: bool = false
var rng = RandomNumberGenerator.new()
var p_attack = Attack.new()
var keys: Dictionary = {}
var jump_request: bool = false
var last_dash_time: float = -10.0
var dash_chain_open: bool = false
var pending_attack: Dictionary = {}
var weapon_index: int = 1
var secondary_index: int = 0
var bag_weapons: Array[Dictionary] = []
var bag_items: Dictionary = {}
var bag_runes: Dictionary = {}
var rune_slots: Array[String] = []
var upgrades: Dictionary = {"count":0,"power":0.0,"reach":0.0,"haste":0.0,"charge":0.0,"shots":0,"subpower":0.0}
var touch_enabled: bool = false
var show_hitboxes: bool = false
var practice_mode: bool = false
var audio_enabled:bool=true:
	set(value):
		audio_enabled=value
		AudioServer.set_bus_mute(0,not value)
		if not value and audio_player!=null:audio_player.stop();audio_player.stream=null
		if room_music!=null:room_music.set_enabled(value)
		if atmosphere!=null:atmosphere.set_audio_enabled(value)
var walker:Node
var audio_player: AudioStreamPlayer
var sounds: Dictionary = {}
var room_music:AudioStreamPlayer
var hud_timer: float = 0.0
var phase_multiplier: float = 1.0
var p: Dictionary = {}
var backdrop: Node2D
var static_props:Node2D
var terrain_region:Rect2
var player_flash_layer:Node2D
var edge_foreground:Node2D
var corpse_layer:Node2D
var corpses:Array[Dictionary]=[]
var terrain: Node2D
var minimap: Node2D
var layout: Dictionary = {}
var render_camera: Vector2 = Vector2.ZERO
var world_transform: Transform2D = Transform2D.IDENTITY
var view_rect: Rect2 = Rect2(0,0,1280,720)
var drop_through_y: float = -10000.0
var drop_through_timer: float = 0.0
var drop_label_target: int = -1
var draw_clock: float = 0.0
var metrics_timer: float = 0.0
var fps_smoothed: float = 60.0
var low_effects: bool = true
var _rune_cache: Dictionary = {}
var _rune_cache_key: String = ""

var world_speed:float=.8
var run_coins:int=0
var strong_slots:Array[String]=[]
var sub_growth:Dictionary={}
var solids:Array[Rect2]=[]
var props:Array[Dictionary]=[]
var injured:bool=false
var feather:Dictionary={}
var life_event:Dictionary={}
var empty_energy_time:float=0
var move_energy_distance:float=0
var bee_timer:float=0
var combo_index:int=0
var combo_deadline:float=-1
var last_motion_pos:Vector2=Vector2.ZERO
var spawn_serial:int=0
var prep_station:String="forge"
var atmosphere:Node2D
var combat_feedback:Node2D
var minimap_open:bool=false
var minimap_full_tower:bool=false
var rune_target_slot:int=-1
var last_checkpoint:int=-1
var kills:int=0
var deaths:int=0
var passive_energy:float=0
var blood_timer:float=0
var critical_warning:ColorRect
var run_started:float=0
var run_recorded:bool=false
var merchant_trial:Dictionary={}
var bath=Bath.new()
var coin_field=CoinField.new()
var lab_mode:String=""
var lab_meta:Dictionary={}
var lab_ai:bool=true
var rd_view:Control
var lab_buttons:HBoxContainer
var practice_tools:HBoxContainer
var practice_rd_panel:Control
var practice_rd_settings:Dictionary={}


func _ready() -> void:
	preload("res://scripts/render_budget_v40.gd").configure(get_window(),OS.has_feature("web"))
	rng.randomize()
	Sprites.warmup()
	BossVisual.warmup()
	FX.warmup()
	# Sprite alpha is authored in PNGs. Font atlases must use the default shader.
	material=null
	font = load("res://assets/Chinese.otf") if ResourceLoader.exists("res://assets/Chinese.otf") else ThemeDB.fallback_font
	_load_meta()
	_load_settings()
	Tuning.activate(meta.get("rd_tuning",{}))
	backdrop = Cache.new();backdrop.z_index=-20;backdrop.paint=_paint_background;add_child(backdrop)
	terrain = Cache.new();terrain.z_index=-10;terrain.paint=_paint_terrain;add_child(terrain)
	static_props=Cache.new();static_props.z_index=-1;static_props.paint=_paint_static_props;add_child(static_props)
	edge_background=Cache.new();edge_background.z_index=-3;edge_background.paint=_paint_edge_background;add_child(edge_background)
	edge_foreground=Cache.new();edge_foreground.z_index=7;edge_foreground.paint=_paint_edge_foreground;add_child(edge_foreground)
	corpse_layer=Cache.new();corpse_layer.z_index=-2;corpse_layer.paint=_paint_corpses;add_child(corpse_layer)
	minimap = Cache.new();minimap.z_index=10;minimap.paint=_paint_minimap;add_child(minimap)
	_reset_player(Vector2(640,600))
	atmosphere=Atmosphere.new();add_child(atmosphere);atmosphere.configure("branches",0,false);atmosphere.set_audio_enabled(audio_enabled)
	combat_feedback=Feedback.new();combat_feedback.z_index=2;add_child(combat_feedback)
	dream_visual=preload("res://scripts/dream_visual_v41.gd").new();add_child(dream_visual)
	spring_particles=preload("res://scripts/spring_particles_v33.gd").new();spring_particles.z_index=2;add_child(spring_particles)
	home_atmosphere=preload("res://scripts/home_atmosphere_v33.gd").new();add_child(home_atmosphere)
	slash_canvas=Cache.new();slash_canvas.z_index=1;slash_canvas.paint=_paint_player_slash;add_child(slash_canvas)
	player_flash_layer=EnemyCanvas.new();player_flash_layer.z_index=1;player_flash_layer.paint=_paint_player_flash;add_child(player_flash_layer)
	ui = UI.new()
	add_child(ui)
	ui.setup()
	_setup_labs()
	critical_warning=ColorRect.new();critical_warning.name="CriticalCorners";critical_warning.size=Vector2(1280,720);critical_warning.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var warning_material:=ShaderMaterial.new();warning_material.shader=load("res://shaders/critical_health.gdshader");critical_warning.material=warning_material
	ui.ui_root.add_child(critical_warning);ui.ui_root.move_child(critical_warning,0);critical_warning.visible=false
	ui.action_requested.connect(_ui_action)
	ui.touch_action.connect(_set_action)
	touch_enabled = bool(meta.get("settings",{}).get("touch_enabled",preload("res://scripts/screen_touch_v29.gd").mobile_default()))
	ui.set_touch_visible(touch_enabled)
	p_attack.active_started.connect(_player_active_started)
	walker=Walk.new();add_child(walker)
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	room_music=Music.new();add_child(room_music);room_music.set_enabled(audio_enabled);room_music.select("hub","branches")
	for sound_name in ["hit","slash","parry","coin","jump","metal_hit","explosion","ground_slam","dash_wind","double_dash_wind","attack_whoosh","charge_build","charge_release","impact_hit","impact_heavy"]:
		var path: String = "res://assets/v30/audio/"+sound_name+".wav" if sound_name in ["charge_build","charge_release","impact_hit","impact_heavy"] else ("res://assets/v29/audio/" if sound_name in ["explosion","ground_slam","dash_wind","double_dash_wind","attack_whoosh"] else "res://assets/")+sound_name+".wav"
		if ResourceLoader.exists(path): sounds[sound_name] = load(path)
	_configure_home()
	_update_hud()
	_update_shortcuts()
	queue_redraw()
	if OS.get_cmdline_user_args().has("--smoke"):
		new_run("rogue",12345)

func _reset_player(at: Vector2) -> void:
	p = {"pos":at,"vel":Vector2.ZERO,"face":1.0,"hp":5,"max_hp":5,"energy":3,"max_energy":6,"grounded":true,"wall":0,"jumps":0,"air_dash":false,"dash_t":0.0,"dash_dir":Vector2.RIGHT,"invul":0.0,"hurt":0.0,"wall_lock":0.0,"wall_hold_left":0.0,"shield":0.0,"slam":false,"slam_speed":520.0,"knockback_t":0.0,"knockback_dir":1.0,"recoil_left":0.0,"recoil_velocity":Vector2.ZERO,"impact_root":0.0,"jump_cut_allowed":false,"jump_released":false,"landing_left":0.0,"wall_kick_left":0.0,"wall_kick_velocity":0.0,"hp_recovery":0.0,"energy_recovery":0.0,"flash_left":0.0,"coyote_left":0.0,"jump_buffer_left":0.0,"flap_left":0.0,"gust_left":0.0,"heavy_land_left":0.0,"fall_distance":0.0,"mantle_left":0.0}
	p_attack.cancel()
	if walker!=null:walker.reset_turn(float(p["face"]))
	drop_through_timer=0.0
	idle_time=0
	charge_timer = 0.0
	heal_timer = 0.0
	pending_attack.clear()

func _input(event:InputEvent) -> void:
	if practice_rd_panel!=null:
		if event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE:practice_rd_panel.closed.emit();get_viewport().set_input_as_handled()
		return
	if lab_mode=="tuning":
		if event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE:tuning_view._close();get_viewport().set_input_as_handled()
		return
	if lab_mode=="rd":
		if event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE:rd_view._close();get_viewport().set_input_as_handled()
		return
	# Capture before GUI navigation so Space, Tab and arrow keys can be rebound.
	if capturing_key.is_empty():
		if event is InputEventKey and Bindings.action_for(key_bindings,int(event.physical_keycode))=="map":
			if not event.echo:_set_map_held(event.pressed)
			get_viewport().set_input_as_handled();return
		if minimap_open and event is InputEventKey:
			var map_action:String=Bindings.action_for(key_bindings,int(event.physical_keycode))
			if map_action in ["left","right"]:
				if not event.echo:_set_action(map_action,event.pressed)
				get_viewport().set_input_as_handled();return
		if event is InputEventKey and ui!=null and ui.is_panel_open():
			var navigation:String=Bindings.action_for(key_bindings,int(event.physical_keycode))
			if navigation in ["left","right","up","down","attack","interact"]:
				get_viewport().set_input_as_handled()
				if not event.echo:_set_action(navigation,event.pressed)
				return
		return
	if not event is InputEventKey:return
	get_viewport().set_input_as_handled()
	if event.pressed and not event.echo:
		if event.physical_keycode!=KEY_ESCAPE:Bindings.assign(key_bindings,capturing_key,int(event.physical_keycode))
		capturing_key="";_save_settings();_show_keybindings()

func _unhandled_input(event: InputEvent) -> void:
	if practice_rd_panel!=null:get_viewport().set_input_as_handled();return
	if lab_mode in ["rd","tuning"]:get_viewport().set_input_as_handled();return
	if life_event.get("kind","")=="await_choice" and event is InputEventJoypadButton:
		_set_action({JOY_BUTTON_A:"attack",JOY_BUTTON_X:"attack",JOY_BUTTON_DPAD_UP:"up",JOY_BUTTON_DPAD_DOWN:"down",JOY_BUTTON_DPAD_LEFT:"left",JOY_BUTTON_DPAD_RIGHT:"right"}.get(event.button_index,""),event.pressed)
		return
	if minimap_open:
		if event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]:_set_action("left" if event.button_index==JOY_BUTTON_DPAD_LEFT else "right",event.pressed)
		return
	if not life_event.is_empty():return
	if event is InputEventJoypadMotion:
		if event.axis==JOY_AXIS_LEFT_X:
			_set_action("left",event.axis_value<-.25);_set_action("right",event.axis_value>.25)
		elif event.axis==JOY_AXIS_LEFT_Y:
			_set_action("up",event.axis_value<-.5);_set_action("down",event.axis_value>.5)
	elif event is InputEventJoypadButton:
		var pad_action:String={JOY_BUTTON_A:"jump",JOY_BUTTON_B:"dash",JOY_BUTTON_X:"attack",JOY_BUTTON_Y:"sub",JOY_BUTTON_DPAD_UP:"up",JOY_BUTTON_DPAD_DOWN:"down",JOY_BUTTON_DPAD_LEFT:"left",JOY_BUTTON_DPAD_RIGHT:"right",JOY_BUTTON_RIGHT_SHOULDER:"heal"}.get(event.button_index,"")
		if not pad_action.is_empty():_set_action(pad_action,event.pressed)
		if event.pressed and event.button_index==JOY_BUTTON_START:_show_settings()
	elif event is InputEventKey:
		var e:InputEventKey=event
		if e.echo:return
		var action:String=Bindings.action_for(key_bindings,int(e.physical_keycode))
		# Assigned actions win over bare-number item shortcuts. Shift+number is
		# the explicit route to every consumable, including slots1–3.
		if e.pressed and screen=="game" and not ui.is_panel_open() and e.physical_keycode>=KEY_1 and e.physical_keycode<=KEY_9 and (e.shift_pressed or action.is_empty()):
			_use_item(int(e.physical_keycode-KEY_1),true,false);get_viewport().set_input_as_handled();return
		if action.is_empty():return
		if ui.is_panel_open() and action in ["primary_1","primary_2","primary_3","cycle","skills"]:get_viewport().set_input_as_handled();return
		get_viewport().set_input_as_handled()
		if e.pressed:
			match action:
				"settings":
					if ui.is_panel_open():_close_panel()
					else:_show_settings()
					return
				"bag","runes","skills","map":_ui_action(action,null);return
				"primary_1":_select_primary(0);return
				"primary_2":_select_primary(1);return
				"primary_3":_select_primary(2);return
				"cycle":
					if mode=="musou":return
					if not bag_weapons.is_empty() and not ui.is_panel_open():
						_select_secondary((secondary_index+1)%bag_weapons.size())
					return
		_set_action(action,e.pressed)

	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and screen == "hub" and not ui.is_panel_open():
		var mouse: Vector2 = get_global_mouse_position()
		if HomeArt.LEFT_GATE.has_point(mouse): new_run("musou")
		elif HomeArt.RIGHT_GATE.has_point(mouse): new_run("rogue")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: _clear_keys()

func _set_action(action: String, pressed: bool) -> void:
	if practice_rd_panel!=null:return
	if minimap_open:
		if pressed and action in ["left","right"]:
			minimap_full_tower=not minimap_full_tower
			if minimap!=null:minimap.invalidate()
		if not pressed:keys[action]=false
		return
	# Death choices accept the same mapped confirm/navigation as every other panel.
	# Injury, death flight and soul flight still reject all gameplay input.
	if life_event.get("kind","")=="await_choice":
		keys[action]=false
		if pressed and action in ["attack","interact","left","right","up","down"] and ui!=null and ui.is_panel_open():ui.navigate(action)
		return
	if not life_event.is_empty():
		if not pressed:keys[action]=false
		return
	if ui != null and ui.is_panel_open():
		if equipment_open and pressed and action=="interact":_close_panel();return
		if not pressed: keys[action]=false
		elif ui.navigate(action):pass
		return
	if float(p.get("heavy_land_left",0))>0:
		keys[action]=pressed if action in ["left","right","up","down"] else false
		return
	if screen=="hub" and pressed and action in ["jump","dash","attack"]:home_sleeping=false;home_wake_left=0
	if action=="jump":
		if pressed and not _key("jump"):p["jump_buffer_left"]=.12;p["jump_released"]=false
		elif not pressed:p["jump_released"]=true
	if _action_locked() and action in (["attack","sub","interact","up"] if _release_locked() else ["jump","attack","sub","interact","up"]):
		if pressed and action in ["attack","sub"]:_reject_attack("locked")
		keys[action]=false;charge_timer=0;return
	if action=="attack" and pressed and screen=="game" and p_attack.phase=="recovery" and _key("down") and not bool(p["grounded"]) and not _release_locked():
		p_attack.cancel();p["impact_root"]=0
	if action=="attack" and pressed and screen=="game" and (p_attack.is_busy() or float(p.get("hurt",0))>0):
		# Rejected presses never become a delayed swing or charge.
		_reject_attack("hurt" if float(p.get("hurt",0))>0 else "busy")
		keys["attack"]=false;charge_timer=0;pending_attack.clear();return
	var was: bool = bool(keys.get(action,false))
	keys[action]=pressed
	if pressed and not was:
		match action:
			"jump": jump_request=true;p["jump_released"]=false
			"dash":
				if screen in ["game","hub"]: _dash_pressed()
			"attack":
				if _world_confirm():keys["attack"]=false;return
				charge_timer=0.0
				if screen in ["game","hub"]:
					_begin_primary({"dir":_aim_string(),"charged":false});_process_player_attack()
			"sub":
				if screen=="game": _begin_secondary()
			"interact": _show_equipment(0)
			"up": _interact(true)
	if action=="jump" and not pressed and was:
		p["jump_released"]=true
		if bool(p.get("jump_cut_allowed",false)) and p["vel"].y<0:p["vel"].y=PlayerMotion.cut(p["vel"].y);p["jump_cut_allowed"]=false
	if action=="attack" and not pressed and was and screen in ["game","hub"]:
		var threshold:float=_charge_threshold()
		var dir:String=_aim_string()
		var charged:bool=charge_timer>=threshold and _skill("charge_vertical" if dir in ["up","down"] else "charge_horizontal")
		# A ready charge can replace ordinary recovery, including the slow cleaver.
		if charged and p_attack.phase=="recovery":p_attack.cancel()
		if charged and not p_attack.is_busy() and float(p.get("hurt",0))<=0:
			pending_attack={"dir":dir,"charged":true,"dash_charge":float(p["dash_t"])>0 and _skill("dashcharge")}
		charge_timer=0.0

func _set_map_held(pressed:bool) -> void:
	if pressed and not minimap_open:minimap_full_tower=false
	minimap_open=pressed and screen=="game" and life_event.is_empty() and not ui.is_panel_open()
	if ui!=null:ui.header.visible=not minimap_open
	if minimap!=null:minimap.invalidate()

func _clear_keys() -> void:
	_set_map_held(false)
	keys.clear(); jump_request=false;
	if not p.is_empty():p["jump_buffer_left"]=0.0;p["coyote_left"]=0.0
	charge_timer=0.0; pending_attack.clear(); dash_chain_open=false

func _process(delta: float) -> void:
	if lab_buttons!=null:lab_buttons.visible=screen=="hub" and lab_mode not in ["rd","tuning"] and not ui.is_panel_open()
	if practice_tools!=null:practice_tools.visible=lab_mode=="practice" and not ui.is_panel_open() and practice_rd_panel==null
	if lab_mode in ["rd","tuning"]:return
	metrics_timer+=delta
	if metrics_timer>=.5:
		fps_smoothed=Engine.get_frames_per_second()
		metrics_timer=0
	# Every actor and retained terrain use one world camera transform.
	var jitter:Vector2=Vector2.ZERO
	if shake>.05: jitter=Vector2(sin(real_clock*87)*shake,cos(real_clock*71)*shake)*.45
	render_camera=camera_pos
	var zoom:float=_view_zoom() if screen=="game" else 1.0
	world_transform=Transform2D(0,Vector2.ONE*zoom,0,-render_camera*zoom+jitter)
	if edge_background!=null:edge_background.transform=world_transform
	if edge_foreground!=null:edge_foreground.transform=world_transform
	if corpse_layer!=null:corpse_layer.transform=world_transform
	if terrain!=null: terrain.transform=world_transform
	if static_props!=null:static_props.transform=world_transform
	if backdrop!=null:backdrop.transform=(atmosphere.depth_transform(render_camera,zoom,Atmosphere.FAR_FACTOR) if _is_start() else Atmosphere.parallax(render_camera,1.0,Atmosphere.FAR_FACTOR)) if screen=="game" else Transform2D.IDENTITY
	if home_atmosphere!=null:
		home_atmosphere.set_active(screen=="hub");home_atmosphere.focus_x=float(p["pos"].x)
	if spring_particles!=null:spring_particles.transform=world_transform
	if atmosphere!=null:
		atmosphere.set_audio_enabled(audio_enabled and life_event.is_empty() and not ui.is_panel_open())
		atmosphere.update_view(render_camera,zoom,world_transform,p["pos"],draw_clock,world_speed,low_effects)
	view_rect=Rect2(render_camera-Vector2(120,130)/zoom,Vector2(1520,980)/zoom)
	var region:Rect2=preload("res://scripts/render_budget_v40.gd").region(view_rect)
	if region!=terrain_region:
		terrain_region=region
		terrain.invalidate();edge_background.invalidate();edge_foreground.invalidate()
	_sync_enemy_canvases()
	if player_flash_layer!=null:
		player_flash_layer.actor=p;player_flash_layer.refresh(world_transform,screen=="game" and life_event.is_empty() and float(p.get("flash_left",0))>0 and not _wind_form_active())
	if slash_canvas!=null:slash_canvas.invalidate()
	if combat_feedback!=null:
		combat_feedback.set_frozen(hitstop>0 or minimap_open or practice_rd_panel!=null,world_speed)
		combat_feedback.reduced=low_effects
		combat_feedback.transform=world_transform
		combat_feedback.update_charge(screen=="game" and life_event.is_empty() and not ui.is_panel_open() and _key("attack") and charge_timer>.08,p["pos"]-Vector2(0,27),charge_timer,_charge_threshold())
		combat_feedback.update_cache(screen=="game" and ((life_event.get("kind","")=="death" and float(life_event.get("elapsed",0))>.7) or (not feather.is_empty() and int(feather.get("room",-1))==current_room)),p["pos"] if life_event.get("kind","")=="death" else feather.get("pos",Vector2.ZERO),clock)
	if dream_visual!=null:dream_visual.set_view(screen=="game" and mode=="musou",world_transform,p["pos"],dream.rage_left>0 and life_event.is_empty(),hitstop>0 or minimap_open or ui.is_panel_open() or practice_rd_panel!=null or not life_event.is_empty(),world_speed)
	if ui!=null and ui.is_panel_open():
		# Panels already pause gameplay; retained draw lists need no per-frame rebuild.
		return
	queue_redraw()

func _invalidate_scene() -> void:
	if backdrop!=null: backdrop.invalidate()
	if edge_background!=null:edge_background.invalidate()
	if edge_foreground!=null:edge_foreground.invalidate()
	if corpse_layer!=null:corpse_layer.invalidate()
	if terrain!=null: terrain.invalidate()
	if static_props!=null:static_props.visible=screen=="game";static_props.invalidate()
	if minimap!=null: minimap.invalidate()
	queue_redraw()

func _physics_process(delta:float) -> void:
	if practice_rd_panel!=null:return
	if lab_mode in ["rd","tuning"]:return
	if lab_mode=="practice":p["energy"]=p["max_energy"];p["invul"]=2;freeze_timer=0 if lab_ai else 999
	real_clock+=delta
	if minimap_open:return
	# Physics, pose sampling and VFX share the same frozen game clock.
	if hitstop>0 and life_event.is_empty():
		hitstop=maxf(0,hitstop-delta);return
	clock+=delta
	_update_visual_effects(delta*world_speed)
	_update_corpses(delta*world_speed)
	if ui==null:return
	critical_warning.visible=screen=="game" and int(p.get("hp",5))==1 and life_event.is_empty()
	if not life_event.is_empty():
		draw_clock+=delta*world_speed*.08;_update_life_event(delta);return
	if ui.is_panel_open():
		walker.reset();return
	draw_clock+=delta*world_speed
	if screen=="hub":
		_update_home(delta);return
	if screen!="game":return
	_update_dream(delta)
	room_cooldown=maxf(0,room_cooldown-delta);freeze_timer=maxf(0,freeze_timer-delta)
	for key in ["invul","hurt","wall_lock","shield","impact_root","flash_left","heavy_land_left"]:p[key]=maxf(0,float(p[key])-delta)
	if _key("attack"):
		var previous_charge:float=charge_timer;charge_timer+=delta
		if previous_charge<.18 and charge_timer>=.18:_sound("charge_build")
	if not pending_attack.is_empty():
		if not p_attack.is_busy() and float(p.get("hurt",0))<=0:_begin_primary(pending_attack)
		pending_attack.clear()
	var was_piercing:bool=p_attack.is_active() and p_attack.attack.get("kind","")=="pierce"
	# A slow-motion dive must retain its attack and wind body until physical contact.
	if bool(p["slam"]) and p_attack.is_active() and p_attack.attack.get("kind","")=="slam":p_attack.attack["active"]=maxf(float(p_attack.attack["active"]),p_attack.elapsed+delta+.02)
	p_attack.tick(delta)
	if was_piercing and not p_attack.is_active():p["dash_t"]=0.0
	var initial_room:int=current_room
	var previous:Vector2=p["pos"]
	_update_player(delta*world_speed)
	_update_idle(delta)
	var walking:bool=bool(p["grounded"]) and absf(p["vel"].x)>30 and float(p["hurt"])<=0 and float(p["dash_t"])<=0 and float(p["recoil_left"])<=0 and (not p_attack.is_busy() or p_attack.phase=="recovery") and charge_timer<=.15
	Walk.limping=injured
	walker.step_turn(float(p["face"]),delta,bool(p["grounded"]) and (not p_attack.is_busy() or p_attack.phase=="recovery") and charge_timer<=.15 and float(p["dash_t"])<=0 and float(p["hurt"])<=0)
	walker.advance(absf(p["pos"].x-previous.x),walking,Walk.surface(str(_ecology()["id"]),p["pos"],layout),audio_enabled)
	_check_portals()
	if current_room!=initial_room:return
	_process_player_attack()
	if hitstop>0:return
	_update_enemies(delta,delta*world_speed)
	if not life_event.is_empty():return
	_update_projectiles(delta*world_speed)
	_update_hazards(delta)
	_update_drops(delta*world_speed)
	_update_heal(delta)
	_update_passives(delta)
	_update_props(delta)
	bath.step(_active_pool(),p["pos"],p["vel"],delta)
	if not merchant_trial.is_empty():p["energy"]=p["max_energy"]
	if screen=="game":camera_pos=camera_pos.lerp(_camera_target(p["pos"]),minf(1,delta*9))
	hud_timer-=delta
	if hud_timer<=0:_update_hud();hud_timer=.12

func _ecology() -> Dictionary:return Ecology.from_stage(2) if screen=="hub" else room.get("ecology",Ecology.from_stage(int(room.get("map_index",2))))
func _furniture_offset() -> Vector2:return layout.get("furniture_offset",Vector2.ZERO)
func _room_size() -> Vector2:return Vector2(1280,720) if screen=="hub" else layout.get("size",Vector2(ROOM_W,ROOM_H))
func _room_floor() -> float:return 600.0 if screen=="hub" else float(layout.get("floor_y",FLOOR_Y))
func _view_zoom() -> float:
	var bounds:Vector2=_room_size()
	var fit:float=maxf(1280.0/bounds.x,720.0/bounds.y)
	return maxf(Scale.MIN_ZOOM,maxf(camera_zoom,fit))
func _camera_target(at:Vector2) -> Vector2:
	var visible:Vector2=Vector2(1280,720)/_view_zoom();var bounds:Vector2=_room_size()
	return Vector2(clampf(at.x-visible.x*.5,0,maxf(0,bounds.x-visible.x)),clampf(at.y-visible.y*.57,0,maxf(0,bounds.y-visible.y)))
func _in_bath() -> bool:return Bath.contains(_active_pool(),p.get("pos",Vector2.ZERO))

func _active_pool() -> Rect2:
	if room.get("fountain",false) and layout.has("fountain_pos"):return preload("res://scripts/spring_v33.gd").pool(layout["fountain_pos"],str(_ecology()["id"]))
	return layout.get("pool",Rect2())

func _load_settings() -> void:
	var settings:Variant=meta.get("settings",{})
	if not settings is Dictionary:settings={}
	camera_zoom=clampf(float(settings.get("zoom",1.3)),.8,2.0)
	world_speed=clampf(float(settings.get("speed",.8)),.4,1.5)
	audio_enabled=bool(settings.get("audio_enabled",audio_enabled))
	key_bindings=Bindings.load_bindings(settings.get("keys",{}))
	if int(settings.get("bindings_version",0))<2 and int(key_bindings.get("sub",0))==KEY_U and Bindings.action_for(key_bindings,KEY_Z)=="":Bindings.assign(key_bindings,"sub",KEY_Z)

func _save_settings() -> void:
	meta["settings"]={"zoom":camera_zoom,"speed":world_speed,"keys":key_bindings.duplicate(),"bindings_version":2,"audio_enabled":audio_enabled,"touch_enabled":touch_enabled}
	_save_meta()
	_update_shortcuts()

func _update_shortcuts() -> void:
	if ui==null:return
	var names:Dictionary={}
	for action in key_bindings:names[action]=Bindings.label(int(key_bindings[action]))
	ui.update_shortcuts(names)

func _show_keybindings() -> void:
	var rows:Array[Dictionary]=[{"text":"點選動作後按新按鍵；Esc 取消。撞到已使用的按鍵會互換，避免一鍵同時回血與移動。設定會自動保存。"}]
	if not capturing_key.is_empty():rows.append({"heading":"請按新按鍵："+str(Bindings.NAMES[capturing_key])+"（Esc 取消）"})
	for action in Bindings.DEFAULTS:
		if action=="settings":continue
		rows.append({"text":str(Bindings.NAMES[action]),"buttons":[{"label":Bindings.label(int(key_bindings[action])),"action":"rebind","payload":action}]})
	rows.append({"buttons":[{"label":"還原預設鍵位","action":"reset_keys"},{"label":"返回設定","action":"settings"}]})
	_panel("自訂鍵位",rows)

func _key(action: String) -> bool: return bool(keys.get(action,false))
func _skill(id: String) -> bool: return screen=="hub" or practice_mode or meta["skills"].has(id)
func _is_start() -> bool: return screen=="game" and str(room.get("type",""))=="start"
func _height() -> int: return -int(room.get("coord",Vector2i.ZERO).y)

func _aim_string() -> String:
	if _key("up"): return "up"
	if _key("down"): return "down"
	return "right" if float(p["face"])>0 else "left"

func _aim_vector() -> Vector2:
	match _aim_string():
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
	return Vector2.RIGHT

func _rune_effect(effect: String) -> float:
	var key:String=",".join(rune_slots)+"|"+",".join(strong_slots)
	if key!=_rune_cache_key:
		_rune_cache_key=key;_rune_cache.clear()
		var linked:Dictionary=RuneLinks.count_by_id(rune_slots)
		for id in rune_slots+strong_slots:
			if id.is_empty():continue
			for r in Data.all_runes():
				if r["id"]==id:
					var prop:String=r["effect"]
					_rune_cache[prop]=float(_rune_cache.get(prop,0))+float(r["value"])*(1+float(linked.get(id,0))*.01 if not Data.is_strong(id) else 1.0)
	if effect=="orbit_bee":return float(rune_slots.count("swarm")+strong_slots.count("orbit_bee")+int(RuneLinks.count_by_id(rune_slots).get("swarm",0)))
	return float(_rune_cache.get(effect,0))

func _update_player(delta:float) -> void:
	# Preserve ordinary-jump clearance at every global speed setting.
	var steps:int=maxi(1,int(ceil(delta/(1.0/120))))
	for step in steps:_step_player(delta/steps)

func _step_player(delta: float) -> void:
	if float(p.get("mantle_left",0))>0:
		Ledge.step(p,delta);return
	p["_motion_step"]=true
	var pos: Vector2=p["pos"]
	var vel: Vector2=p["vel"]
	var old_pos: Vector2=pos
	var was_grounded:bool=bool(p["grounded"])
	var was_slam:bool=bool(p["slam"])
	if was_grounded or vel.y<0 or int(p["wall"])!=0 or was_slam:p["fall_distance"]=0.0
	var was_attached:bool=int(p["wall"])!=0
	var dash_contact:bool=float(p["dash_t"])>0 and absf(p["dash_dir"].x)>.5 and not bool(p["slam"])
	p["coyote_left"]=.10 if was_grounded else maxf(0,float(p.get("coyote_left",0))-delta)
	if jump_request:p["jump_buffer_left"]=.12;jump_request=false
	else:p["jump_buffer_left"]=maxf(0,float(p.get("jump_buffer_left",0))-delta)
	p["flap_left"]=maxf(0,float(p.get("flap_left",0))-delta)
	p["gust_left"]=maxf(0,float(p.get("gust_left",0))-delta)
	p["landing_left"]=maxf(0,float(p.get("landing_left",0))-delta)
	p["wall_kick_left"]=maxf(0,float(p.get("wall_kick_left",0))-delta)
	p["wall_hold_left"]=maxf(0,float(p.get("wall_hold_left",0))-delta)
	drop_through_timer=maxf(0,drop_through_timer-delta)
	var axis: float=0.0 if _movement_locked() else float(int(_key("right"))-int(_key("left")))
	var speed_factor:float=_movement_factor()
	if _movement_locked():vel.x=0
	if axis!=0 and not _release_locked(): p["face"]=signf(axis)
	if bool(p["slam"]):p["slam_speed"]=minf(1480.0,float(p.get("slam_speed",520))+2100.0*delta)
	var knocked: bool = float(p.get("knockback_t",0))>0
	if knocked:
		var step: float=minf(delta,float(p["knockback_t"]))
		p["knockback_t"]=maxf(0,float(p["knockback_t"])-delta)
		vel.x=float(p["knockback_dir"])*CONTACT_KNOCKBACK/KNOCKBACK_TIME*step/maxf(delta,0.00001)
		vel.y=minf(vel.y+PlayerMotion.RISE_GRAVITY*(Tuning.value("fall_gravity") if vel.y>=0 else 1.0)*delta,PlayerMotion.MAX_FALL_SPEED)
	elif float(p.get("recoil_left",0))>0:
		var step:float=minf(delta,float(p["recoil_left"]))
		p["recoil_left"]=maxf(0,float(p["recoil_left"])-delta)
		var impulse:Vector2=p["recoil_velocity"]*step/maxf(delta,.00001)
		p["recoil_base_y"]=float(p.get("recoil_base_y",vel.y))+GRAVITY*delta
		vel=Vector2(impulse.x,float(p["recoil_base_y"])+impulse.y)
	elif float(p["dash_t"])>0.0 or _wind_form_active():
		p["dash_t"]=maxf(0,float(p["dash_t"])-delta)
		vel=p["dash_dir"]*(940.0 if p_attack.is_active() and p_attack.attack.get("kind","") in ["pierce","slam"] else 650.0)*1.2
		if bool(p["slam"]): vel=Vector2(0,float(p["slam_speed"]))
		# A single retained wind texture replaces per-substep particle allocation.
	else:
		vel.x=axis*MOVE_SPEED*speed_factor
		if axis==0 and float(p.get("wall_kick_left",0))>0:vel.x=float(p["wall_kick_velocity"])
		vel.y=minf(vel.y+PlayerMotion.RISE_GRAVITY*(Tuning.value("fall_gravity") if vel.y>=0 else 1.0)*delta,PlayerMotion.MAX_FALL_SPEED)
		if bool(p["slam"]): vel=Vector2(0,float(p["slam_speed"]))
	if float(p.get("jump_buffer_left",0))>0 and not knocked and not _movement_locked() and float(p.get("hurt",0))<=0:
		var jumped:bool=false
		if int(p["wall"])!=0:
			jumped=true
			vel=Vector2(-int(p["wall"])*390,-JUMP_SPEED)
			pos.x-=int(p["wall"])*8
			p["wall_kick_left"]=.09;p["wall_kick_velocity"]=vel.x
			p["wall_lock"]=.17;p["wall"]=0;p["jumps"]=1;p["grounded"]=false
			_sound("jump")
		elif bool(p["grounded"]) or float(p.get("coyote_left",0))>0:
			jumped=true
			if _key("down") and pos.y<_room_floor()-15:
				drop_through_y=pos.y;drop_through_timer=.22
				pos.y+=3;vel.y=130;p["grounded"]=false
			else:
				vel.y=-JUMP_SPEED*(1.0+_rune_effect("wing"))*Tuning.value("jump_speed");p["grounded"]=false;p["jumps"]=1;_sound("jump")
		elif _skill("doublejump") and int(p["jumps"])<2:
			jumped=true
			vel.y=-JUMP_SPEED*.92*Tuning.value("jump_speed");p["jumps"]=2;p["flap_left"]=.32;p["gust_left"]=.20;combat_feedback.double_jump(pos-Vector2(0,10));_sound("jump")
		if jumped:
			p["jump_buffer_left"]=0;p["coyote_left"]=0;p["jump_cut_allowed"]=true
			if bool(p.get("jump_released",false)) and vel.y<0:vel.y=PlayerMotion.cut(vel.y);p["jump_cut_allowed"]=false
	if _in_bath() and vel.y>200:vel.y=200
	if was_attached and int(p["wall"])!=0 and not dash_contact:vel.y=0.0 if float(p.get("wall_hold_left",0))>0 else PlayerMotion.WALL_SLIDE_SPEED
	var resolved:Dictionary=Coll.move_body(pos,vel,delta,Vector2(34,42),solids,4)
	if _in_bath() and absf(vel.x)>1 and absf(resolved["vel"].x)<1:
		for lift in [8.0,18.0,30.0]:
			var raised:Vector2=pos-Vector2(0,lift)
			if solids.any(func(box:Rect2)->bool:return _body_box(raised).intersects(box)):continue
			var step_up:Dictionary=Coll.move_body(raised,vel,delta,Vector2(34,42),solids)
			if absf(step_up["vel"].x)>1:resolved=step_up;break
	pos=resolved["pos"];vel=resolved["vel"]
	p["grounded"]=resolved["grounded"]
	var wall_contact:int=int(resolved["wall"])
	var dashed_into:bool=dash_contact and signf(p["dash_dir"].x)==wall_contact
	var contact:Dictionary=Ledge.contact(pos,wall_contact,solids)
	var wall_allowed:bool=_skill("wall") and (float(p["wall_lock"])<=0 or dashed_into) and not bool(p["grounded"]) and not bool(p["slam"])
	p["wall"]=wall_contact if wall_allowed and float(contact["ratio"])+.000001>=Ledge.ATTACH_RATIO else 0
	if wall_allowed and contact.has("target"):
		p["pos"]=pos;p["face"]=wall_contact;Ledge.begin(p,contact["target"]);p_attack.cancel();pending_attack.clear();charge_timer=0;p["_motion_step"]=false;return
	if p["grounded"]:_restore_ground_movement()

	if pos.x<4:
		pos.x=4
	elif pos.x>_room_size().x-4:
		pos.x=_room_size().x-4
	var landing_y:float=_support_y(old_pos,pos,vel.y,9.0,drop_through_y if drop_through_timer>0 else -10000.0)
	if bool(p["slam"]):_slam_contacts(old_pos,Vector2(pos.x,minf(pos.y,landing_y)))
	if landing_y<INF:
		pos.y=landing_y;vel.y=0;p["grounded"]=true
		p["wall"]=0
		_restore_ground_movement()
		if bool(p["slam"]): _slam_impact(pos)
	if int(p["wall"])!=0:
		# Clamp the real physics velocity, never shift the rendered sprite toward
		# a wall. Both sides use the same feet anchor and the same AABB solver.
		if not was_attached:p["wall_hold_left"]=1.0
		vel.y=0.0 if float(p.get("wall_hold_left",0))>0 else PlayerMotion.WALL_SLIDE_SPEED;_restore_ground_movement()
		if dashed_into:p["dash_t"]=0;vel.y=0;p["wall_lock"]=0
	if int(p["wall"])==0:p["wall_hold_left"]=0.0
	if bool(p["grounded"]) and bool(p["slam"]):_slam_impact(pos)
	if pos.y<0:pos.y=0;vel.y=maxf(0,vel.y)
	if pos.y>_room_size().y+80 and not room.get("neighbors",{}).has("down"):_hurt_player(2,pos);pos=layout.get("spawn_positions",{}).get("center",Vector2(230,_room_floor()))
	if not was_grounded and not was_slam:p["fall_distance"]=float(p.get("fall_distance",0))+maxf(0,pos.y-old_pos.y)
	if bool(p["grounded"]) and not was_grounded and not was_slam:
		p["landing_left"]=.09
		if float(p.get("fall_distance",0))>float(layout.get("tile_size",96))*6.0 and not p.has("launch_pending_velocity") and not _in_bath():
			_begin_heavy_landing(pos);vel.x=0
		p["fall_distance"]=0.0
	if p.has("launch_pending_velocity"):
		vel=p["launch_pending_velocity"];p.erase("launch_pending_velocity")
		p["grounded"]=false;p["wall"]=0;p["landing_left"]=0
	p["_motion_step"]=false
	p["pos"]=pos;p["vel"]=vel

func _support_y(old:Vector2, next:Vector2, vertical_speed:float, half_width:float=9.0, ignore_y:float=-10000.0) -> float:
	if vertical_speed<0: return INF
	var best:float=INF
	for plat in platforms:
		if absf(plat.position.y-ignore_y)<.5: continue
		if old.y<=plat.position.y+.6 and next.y>=plat.position.y and next.x+half_width>plat.position.x and next.x-half_width<plat.end.x:
			best=minf(best,plat.position.y)
	return best

func _restore_ground_movement() -> void:
	p["jumps"]=0;p["air_dash"]=false

func _dash_pressed() -> void:
	if float(p.get("heavy_land_left",0))>0 or float(p.get("mantle_left",0))>0:return
	if float(p.get("knockback_t",0))>0 or not life_event.is_empty():return
	if _key("up"):return
	if p_attack.is_busy() and p_attack.phase=="active":return
	var elapsed:float=clock-last_dash_time
	var second:bool=dash_chain_open and elapsed<=.5 and elapsed>.02
	if second:
		dash_chain_open=false
		var dir:Vector2=Vector2.DOWN if _key("down") else Vector2(float(p["face"]),0)
		if not _skill("dash_vertical" if dir.y>0 else "dash_horizontal"):_toast("穿刺技能尚未解鎖，請查看技能樹");return
		if float(p["energy"])<1:_toast("穿刺需要1能量");return
		p["energy"]-=1;p_attack.cancel();pending_attack.clear();p["impact_root"]=0;charge_timer=0
		var definition:Dictionary={"kind":"slam" if dir.y>0 else "pierce","windup":.035,"active":1.8 if dir.y>0 else .24,"recovery":0.0,"damage":2.0,"range":38.0,"width":40.0,"dir":dir,"direction":"down" if dir.y>0 else ("right" if dir.x>0 else "left"),"color":Color("d3eaff"),"primary":false}
		p_attack.begin(Dream.instant(definition) if mode=="musou" else definition)
		return
	last_dash_time=clock;dash_chain_open=true
	# Down+C only arms the next press: no movement, no animation cancellation.
	if _key("down"):return
	if bool(p["air_dash"]) and not bool(p["grounded"]) and int(p["wall"])==0:dash_chain_open=false;return
	p_attack.cancel();pending_attack.clear();p["impact_root"]=0
	p["dash_dir"]=Vector2(float(p["face"]),0);p["dash_t"]=.16;p["air_dash"]=true;p["wall_lock"]=.1
	combat_feedback.single_dash(p["pos"]-Vector2(0,24)-Vector2(p["dash_dir"])*12,p["dash_dir"])
	_sound("dash_wind")


func _primary_definition(request:Dictionary) -> Dictionary:
	var def:Dictionary=Data.action_attack(str(request.get("dir","right")),bool(request.get("charged",false)),float(p.get("dash_t",0))>0,int(request.get("combo",combo_index)))
	def["damage"]=float(def["damage"])*Tuning.value("player_damage")
	def["recovery"]=float(def["recovery"])*Tuning.value("attack_recovery")
	var haste:float=(1+float(upgrades["haste"])*.07+_rune_effect("haste"))*(1+_rune_effect("haste_mult"))
	for key in ["windup","recovery"]:def[key]=float(def[key])/haste*phase_multiplier
	if not bool(def["charged"]):def["active"]=float(def["active"])*phase_multiplier
	def["range"]=float(def["range"])*(1+float(upgrades["reach"])*.07+_rune_effect("reach"))*(1+_rune_effect("reach_mult"))
	if mode=="musou":def["damage"]=ceilf(float(def["damage"])*(1+float(upgrades["power"])*.14))
	def["face"]=float(p["face"])
	if mode=="musou":Dream.instant(def)
	return def

func _release_locked() -> bool:
	return p_attack.is_active() and bool(p_attack.attack.get("charged",false)) and bool(p_attack.attack.get("primary",false))

func _movement_locked() -> bool:
	if float(p.get("heavy_land_left",0))>0 or float(p.get("mantle_left",0))>0:return true
	return false if _release_locked() else _action_locked()

func _wind_form_active() -> bool:
	return bool(p.get("slam",false)) or (p_attack.is_active() and p_attack.attack.get("kind","") in ["pierce","slam"])

func _slam_invulnerable() -> bool:
	return bool(p.get("slam",false)) or (p_attack.is_busy() and p_attack.attack.get("kind","") in ["pierce","slam"] and p_attack.phase in ["windup","active"])

func _action_locked() -> bool:
	return float(p.get("mantle_left",0))>0 or float(p.get("heavy_land_left",0))>0 or _wind_form_active() or _release_locked() or (p_attack.is_active() and p_attack.attack.get("style","")=="heavy") or float(p.get("impact_root",0))>0

func _normal_damage() -> float:
	return float(_primary_definition({"dir":"right","charged":false,"dash_charge":false})["damage"])

func _begin_primary(request:Dictionary) -> void:
	if _action_locked():_reject_attack("locked");return
	if clock>combo_deadline:combo_index=0
	var def:Dictionary=_primary_definition(request)
	if def.get("charged",false):p["recoil_left"]=0;p["impact_root"]=0
	if p_attack.begin(def):
		combo_index=(combo_index+1)%3;combo_deadline=clock+float(def["windup"])+float(def["active"])+float(def["recovery"])+.65;charge_timer=0
		if not def.get("charged",false):_sound("attack_whoosh")
		ui.clear_attack_feedback();_update_hud()

func _secondary_at(index:int) -> Dictionary:
	var source:Dictionary=Data.secondary_attack(0) if bag_weapons.is_empty() else Data.normalize_secondary(bag_weapons[clampi(index,0,bag_weapons.size()-1)])
	var result:Dictionary=source.duplicate(true)
	result["damage"]=float(result["damage"])*(1+_rune_effect("sub_damage"))*Tuning.value("player_damage")
	result["speed"]=float(result.get("speed",400))*(1+_rune_effect("sub_speed"))
	result["range"]=float(result.get("range",900))*(1+_rune_effect("sub_range")+_rune_effect("reach_mult"))
	result["size"]=ProjectileReadability.BASE_RADIUS*(1+_rune_effect("sub_size"))
	result["explosion_radius"]=float(result.get("explosion_radius",100))*(1+_rune_effect("sub_size"))
	result["windup"]=0.0
	result["recovery"]=float(result["recovery"])*Tuning.value("attack_recovery")
	result["count"]=clampi(int(result.get("count",result.get("shots",1)))+clampi(int(source.get("duplicate_bonus",0)),0,8)+int(_rune_effect("projectile_count")),1,20);result["shots"]=result["count"]
	return result

func _secondary() -> Dictionary:
	secondary_index=posmod(secondary_index,bag_weapons.size()) if not bag_weapons.is_empty() else 0
	return _secondary_at(secondary_index)

func _musou_timing() -> Dictionary:
	# One stable cast cadence for the entire loadout. A different inspected
	# weapon must never change the cost or rate of the identical sixteen-shot salvo.
	return {"windup":0.0,"active":.08,"recovery":0.0}

func _musou_cycle_seconds() -> float:
	var timing:Dictionary=_musou_timing()
	var haste:float=(1+_rune_effect("haste_mult"))*(1+_rune_effect("haste"))
	return 2.0*phase_multiplier*(float(timing["active"])+float(timing["recovery"])/haste)

func _begin_secondary() -> void:
	if _action_locked():_reject_attack("locked");return
	if p_attack.is_busy():_reject_attack("busy");return
	if float(p.get("hurt",0))>0:_reject_attack("hurt");return
	if bag_weapons.is_empty():_reject_attack("no_weapon");return
	if float(p["energy"])<1:_reject_attack("energy");return
	var def: Dictionary=_secondary().duplicate(true)
	if mode=="musou":
		def["salvo"]=[]
		for index in mini(16,bag_weapons.size()):def["salvo"].append(_secondary_at(index))
		def.merge(_musou_timing(),true)
	def["primary"]=def.get("weapon_kind","")=="sword";def["kind"]="secondary";def["direction"]=_aim_string();def["dir"]=_aim_vector();def["face"]=p["face"]
	def["damage"]=float(def["damage"])
	def["count"]=int(def.get("count",def.get("shots",1)))
	var linked_projectile_fraction:float=fposmod(_rune_effect("projectile_count"),1.0)
	if int(def["count"])<20 and rng.randf()<linked_projectile_fraction:def["count"]+=1
	def["shots"]=def["count"]
	for key in ["windup","active","recovery"]:def[key]=float(def.get(key,.15))*2.0*phase_multiplier/((1+_rune_effect("haste_mult"))*(1+_rune_effect("haste")) if key!="active" else 1.0)
	def["windup"]=0.0
	if mode=="musou":Dream.instant(def)
	if not bool(p["grounded"]) and int(p["wall"])==0:def["air_instant"]=true
	if p_attack.begin(def):
		p["energy"]-=1;charge_timer=0;keys["attack"]=false
		ui.clear_attack_feedback();_update_hud()

func _reject_attack(reason:String) -> void:
	if ui==null:return
	# One retained HUD cue, rate limited in UI; rejected presses remain discarded.
	ui.reject_attack(reason)
	_update_hud()

func _player_active_started() -> void:
	var def: Dictionary=p_attack.attack
	if def.get("charged",false):_sound("charge_release")
	if _in_bath():
		var pool:Rect2=_active_pool()
		spring_particles.splash(Vector2(p["pos"].x,pool.position.y),str(_ecology()["id"]),_attack_direction(def))
		bath.attack(pool,p["pos"])
	match str(def.get("kind","")):
		"secondary":
			if def.has("salvo"):
				for weapon:Dictionary in def["salvo"]:_emit_weapon(p["pos"]-Vector2(0,24),def.get("dir",Vector2.RIGHT),weapon,true)
			elif def.get("weapon_kind","")!="sword": _emit_weapon(p["pos"]-Vector2(0,24),def.get("dir",Vector2.RIGHT),def,true)
		"pierce","slam":
			p["slam_speed"]=520.0;_sound("double_dash_wind")
			p["dash_dir"]=def["dir"];p["dash_t"]=float(def["active"]);p["air_dash"]=true
			p["slam"]=def["kind"]=="slam"
			# The eight-frame wind-form body replaces the pigeon while this skill is active.
		"item_bomb":
			_contact_fx("explosion_artificial",p["pos"]-Vector2(0,25))
			effects[-1]["fx_extent"]=840.0
			for en in enemies:
				if en["pos"].distance_to(p["pos"])<420 and p_attack.mark_hit(int(en["uid"])):_hit_enemy(en,float(def["damage"]),Color("ffd18d"),400)
			_effect(p["pos"],Color("ffca8d"),420,.6);shake=10
		_:
			if bool(def.get("dash_charge",false)): p["vel"]=_aim_vector()*500

func _attack_box(pos: Vector2, def: Dictionary, face: float) -> Rect2:
	var reach: float=float(def.get("range",70))
	var width: float=float(def.get("width",55))
	var box_scale:float=float(def.get("hitbox_scale",1))
	var dir: String=str(def.get("direction","right" if face>0 else "left"))
	var center_y:float=pos.y+float(def.get("origin_y",-28))
	if def.get("shape","")=="ground_wave":return _attack_volume(Rect2(pos.x-reach,pos.y-width,reach*2,width+8*box_scale),def)
	if def.get("shape","") in ["spin"]:return _attack_volume(Rect2(Vector2(pos.x-reach,center_y-reach*.65),Vector2(reach*2,reach*1.3)),def)
	if dir=="up": return _attack_volume(Rect2(pos.x-width*.5,center_y-8*box_scale-reach,width,reach+12*box_scale),def)
	if dir=="down": return _attack_volume(Rect2(pos.x-width*.5,center_y+16*box_scale,width,reach+12*box_scale),def)
	return _attack_volume(Rect2(pos.x if dir=="right" else pos.x-reach,center_y-width*.5,reach,width),def)

func _attack_volume(box:Rect2,definition:Dictionary) -> Rect2:
	var added:float=box.size.y*(float(definition.get("hitbox_height_mult",1)) - 1)
	return Rect2(box.position-Vector2(0,added*.5),box.size+Vector2(0,added))

func _body_box(pos: Vector2, scale_value: float=1.0) -> Rect2:
	return Rect2(pos-Vector2(17,42)*scale_value,Vector2(34,42)*scale_value)

func _process_player_attack() -> void:
	if not p_attack.is_active(): return
	var def: Dictionary=p_attack.attack
	var kind: String=str(def.get("kind",""))
	if kind=="secondary" and def.get("weapon_kind","")!="sword": return
	if kind in ["slam","item_bomb"]: return
	var hitbox: Rect2=_body_box(p["pos"]).grow(12) if kind=="pierce" else _attack_box(p["pos"],def,float(p["face"]))
	for en in enemies:
		if float(en["hp"])<=0: continue
		var ea = en["attack"]
		if bool(def.get("primary",false)) and ea.is_active() and bool(ea.attack.get("primary",false)) and hitbox.intersects(_attack_box(en["pos"],ea.attack,float(en["face"]))):
			_parry(en)
		if hitbox.intersects(_enemy_body_box(en)) and (p_attack.mark_timed_hit(int(en["uid"]),.5,3) if def.get("charged",false) else p_attack.mark_hit(int(en["uid"]))):
			_hit_enemy(en,float(def.get("damage",1)),Color(def.get("color",Color.WHITE)),float(def.get("knockback",76)),Vector2.INF,_attack_direction(def))
			if not en.get("training",false) and float(def.get("recoil",0))>0:_recoil(float(def["recoil"]),en["pos"],-_attack_direction(def))
			_restore_vital("energy",float(def.get("energy_gain",0))*(1.0+_rune_effect("energy")))
			p["air_dash"]=false
			if str(def.get("direction",""))=="down" and not bool(p["grounded"]) and not en.get("training",false):
				_pogo()
	_hit_props(hitbox,float(def.get("damage",1)))
	_damage_traps(hitbox,float(def.get("damage",1)))

func _slam_contacts(old:Vector2,next:Vector2) -> void:
	if not p_attack.is_active() or p_attack.attack.get("kind","")!="slam":return
	var box:Rect2=_body_box(old).merge(_body_box(next)).grow(9)
	for en in enemies:
		if en["hp"]>0 and box.intersects(_enemy_body_box(en)) and p_attack.mark_hit(int(en["uid"])):
			_hit_enemy(en,float(p_attack.attack.get("damage",2)),Color("d5f8ef"),140,next,Vector2.DOWN)
	_hit_props(box,float(p_attack.attack.get("damage",2)))
	_damage_traps(box,float(p_attack.attack.get("damage",2)))

func _slam_impact(at: Vector2) -> void:
	p["slam"]=false;p["dash_t"]=0.0
	p["invul"]=maxf(float(p["invul"]),.5)
	if p_attack.is_active() and p_attack.attack.get("kind","")=="slam":
		p_attack.elapsed=maxf(0,float(p_attack.attack["active"])-.001)
		for en in enemies:
			if en["pos"].distance_to(at)<165 and _enemy_body_box(en).intersects(Rect2(at-Vector2(165,110),Vector2(330,111))) and p_attack.mark_timed_hit(int(en["uid"]),.5,1): _hit_enemy(en,float(p_attack.attack["damage"]),Color("f0cc89"),420)
	_hit_props(Rect2(at-Vector2(165,110),Vector2(330,111)),2)
	_damage_traps(Rect2(at-Vector2(165,110),Vector2(330,111)),2)
	p["slam_speed"]=520.0
	effects.append({"ground_wind":true,"pos":at,"ground_y":at.y,"color":Color.WHITE,"life":.5,"max":.5,"radius":0.0,"ring":false,"vel":Vector2.ZERO})
	# Debris remains on the air side of this exact contacted platform.
	for i in (10 if low_effects else 18):
		effects.append({"pos":at-Vector2(0,3),"ground_y":at.y,"color":Color("ddece4"),"life":.3,"max":.3,"radius":2.0,"ring":false,"vel":Vector2(rng.randf_range(-300,300),rng.randf_range(-280,-100))})
	shake=10;_sound("ground_slam")

func _parry(en: Dictionary) -> void:
	if p_attack.attack.get("direction","")=="down":_pogo()
	en["attack"].cancel();en["stun"]=.72
	p["invul"]=maxf(float(p["invul"]),.5);_restore_vital("energy",2)
	var at: Vector2=(p["pos"]+en["pos"])*.5-Vector2(0,25)
	_particles(at,Color("fff0b8"),24,260);_effect(at,Color("ffe3a0"),80,.35)
	_contact_fx("parry",at)
	_float(at,"拼刀！ +2 能量",Color("ffe3a0"));hitstop=.055;shake=7;_sound("parry")

func _update_heal(delta: float) -> void:
	if _key("heal") and float(p["energy"])>=3 and float(p["hp"])<float(p["max_hp"]) and not p_attack.is_busy():
		heal_timer+=delta
		if rng.randf()<.3: _particles(p["pos"]-Vector2(0,20),Color("8de4ac"),1,25)
		if heal_timer>=.7:
			heal_timer=0;p["energy"]-=3;_restore_vital("hp",1);_float(p["pos"]-Vector2(0,55),"+1",Color("9df3b4"));_sound("coin")
	else: heal_timer=0

func _hit_enemy(en:Dictionary,damage:float,color:Color,knockback:float=76,source:Vector2=Vector2.INF,direction:Vector2=Vector2.ZERO,gain_dream:bool=true) -> void:
	if float(en["hp"])<=0:return
	if mode=="musou":damage*=dream.damage_factor()
	_sound("impact_heavy" if p_attack.is_busy() and p_attack.attack.get("charged",false) else "impact_hit")
	en["flash_left"]=2.0/60.0;en["_impact_time"]=clock
	if gain_dream:_melee_hitstop()
	if en.get("training",false):
		en["training_total"]=float(en.get("training_total",0))+damage
		var contact:Vector2=en["pos"]-Vector2(0,60);_float(contact-Vector2(0,65),"%.1f"%damage,color)
		if combat_feedback!=null:combat_feedback.hit(en,contact,Vector2(float(p["face"]),0),str(p_attack.attack.get("style","quick")),false)
		return
	if float(en["hp"])<=0:return
	if mode=="musou" and gain_dream and damage>0:dream.hit()
	en["hp"]-=damage;en["hurt"]=.2
	var away:float=signf(en["pos"].x-(source.x if source.is_finite() else p["pos"].x))
	if away==0:away=float(p["face"])
	var impulse:Vector2=direction.normalized() if direction.length_squared()>.01 else Vector2(away,0)
	if int(en.get("model",0))==4:
		if BossDirector.hit(en,damage):
			en["push_left"]=.18;en["push_velocity"]=impulse*knockback*.2/.18;en["push_base_y"]=en.get("vel",Vector2.ZERO).y
			_float(en["pos"]-Vector2(0,110),"失衡",Color("ffe5ae"))
	else:
		en["push_left"]=.18;en["push_velocity"]=impulse*knockback/.18;en["push_base_y"]=en.get("vel",Vector2.ZERO).y;en["stun"]=maxf(float(en.get("stun",0)),.12)
	en["death_direction"]=impulse;en["death_knockback"]=knockback
	var contact:Vector2=en["pos"]-Vector2(0,_enemy_body_box(en).size.y*.5)
	if combat_feedback!=null:combat_feedback.hit(en,contact,impulse,str(Data.PRIMARY[weapon_index]["style"]),float(en["hp"])<=0)

	if rng.randf()<clampf(_rune_effect("lifesteal"),0,1):_restore_vital("hp",1);_contact_fx("lifesteal",p["pos"]-Vector2(0,25))
	_float(en["pos"]-Vector2(0,55),"%.1f"%damage,color);shake=maxf(shake,2.2)
	if float(en["hp"])<=0:_enemy_defeated(en)

func _hurt_player(amount:float,source:Vector2) -> bool:
	if _slam_invulnerable() or not life_event.is_empty() or float(p["invul"])>0 or float(p["shield"])>0 or _healing_guard():return false
	amount=maxi(1,roundi(amount)) if amount>0 else 0
	charge_timer=0;keys["attack"]=false;idle_time=0
	p["mantle_left"]=0
	p["hp"]=maxi(0,int(p["hp"])-int(amount));p["flash_left"]=1.0/60;p["hurt"]=.25;p["invul"]=2.0 if mode=="musou" else (.55+_rune_effect("guard"))*1.5
	_hit_flash(p["pos"]-Vector2(0,22),amount,Color("ffad9b"))
	if not (mode=="musou" and not revive_used and int(p["hp"])<=0) and not (_release_locked() or (p_attack.is_active() and bool(p_attack.attack.get("super_armor",false)))):
		var away:float=signf(p["pos"].x-source.x)
		if away==0:away=-float(p["face"])
		p["knockback_t"]=KNOCKBACK_TIME;p["knockback_dir"]=away;p["vel"]=Vector2(away*CONTACT_KNOCKBACK/KNOCKBACK_TIME,-100)
		p_attack.cancel();pending_attack.clear();jump_request=false;charge_timer=0;heal_timer=0;p["slam"]=false;p["dash_t"]=0
	hitstop=maxf(hitstop,.045);_float(p["pos"]-Vector2(0,65),"受傷 -%d"%int(amount),Color("ffb0a4"));shake=9;_sound("hit")
	if float(p["hp"])<=0:_death()
	return true

func _death() -> void:
	_return_trial(false)
	if not life_event.is_empty():return
	_clear_keys();p_attack.cancel();p["dash_t"]=0;p["slam"]=false;p["mantle_left"]=0;p["invul"]=5.0
	var first_down:bool=not revive_used
	if first_down and mode=="musou":
		revive_used=true;injured=true;_sync_vitals();p["hp"]=p["max_hp"];p["invul"]=2.0;p["hurt"]=0;p["knockback_t"]=0
		dream.injure();shake=maxf(shake,20);hitstop=maxf(hitstop,.08)
		var center:Vector2=p["pos"]-Vector2(0,24)
		dream_visual.pulse(center,640/_view_zoom(),true)
		for en:Dictionary in enemies:
			if en["hp"]<=0 or en.get("training",false):continue
			var direction:Vector2=(_enemy_body_box(en).get_center()-center).normalized()
			if direction.length_squared()<.01:direction=Vector2(float(p["face"]),-.25).normalized()
			en["push_left"]=.35;en["push_velocity"]=direction*240/.35;en["push_base_y"]=0;en["dream_burst_push"]=true;en["stun"]=maxf(float(en.get("stun",0)),.35);en["attack"].cancel()
		_toast("夢境爆發！攻擊力 ×2 · 120秒");_update_hud();return
	if first_down:revive_used=true
	else:
		deaths+=1
		var payload:Dictionary=Bag.snapshot(run_coins,bag_runes,bag_items,bag_weapons)
		payload["growth"]=sub_growth.duplicate(true)
		feather={"room":current_room,"pos":Vector2(p["pos"]),"payload":payload}
	life_event={"kind":"injury" if first_down else "death","elapsed":0.0,"origin":p["pos"],"room":current_room,"face":p["face"],"trail":[],"velocity":Vector2(-float(p["face"])*440,-280)}
	_toast("首次倒下：重傷後醒來，這一局再倒下便會死亡" if first_down else "羽翼碎落……選一枚符文返回安全屋，其餘背包留在發光羽毛")

func _update_enemies(delta:float,movement_delta:float=-1) -> void:
	if movement_delta<0:movement_delta=delta*world_speed
	var frozen:bool=freeze_timer>0
	var initial_room:int=current_room
	var world:Array=solids+platforms
	for en in enemies:
		if screen!="game" or current_room!=initial_room:return
		if float(en["hp"])<=0:continue
		if en.get("training",false):
			en["training_age"]=float(en.get("training_age",0))+movement_delta
			if en.get("floating",false):
				var t:float=en["training_age"];en["pos"]=Vector2(en["anchor"])+Vector2(sin(t*.83)*115,sin(t*1.27)*18)
			continue
		Motion.prepare(en)
		if int(en["model"])==4:_confine_boss(en)
		for key in ["hurt","stun","cooldown","flash_left"]:en[key]=maxf(0,float(en.get(key,0))-delta)
		var atk=en["attack"]
		var toward:Vector2=p["pos"]-en["pos"]
		var engaged:bool=_in_aggro(en)
		var body_size:Vector2=MonsterMotion.body_size(en)
		if not engaged and not en.get("passive",false):
			if atk.is_busy():atk.cancel()
			if float(en.get("push_left",0))<=0:
				en["vel"]=Vector2.ZERO
				continue
		if not frozen and int(en["model"])==4:
			var new_phase:int=BossDirector.tick(en,delta,engaged)
			if new_phase==2:_adapt_boss(en)
			elif new_phase==3:
				_float(en["pos"]-Vector2(0,110),"終局",Color("ffbd89"));_toast(str(en["name"])+"進入終局：留意連續攻勢與收招空檔")
		if not frozen:atk.tick(delta)
		var support:Rect2=Rect2() if Motion.airborne(en) and float(en.get("motion_left",1))>movement_delta else _enemy_support(en)
		var grounded:bool=support.size.x>0
		if engaged and not frozen and float(en["stun"])<=0 and not atk.is_busy() and float(en["cooldown"])<=0:
			_try_enemy_attack(en,toward)
		var vel:Vector2=en["vel"]
		var dream_push:bool=mode=="musou" and bool(en.get("dream_burst_push",false)) and float(en.get("push_left",0))>0
		if frozen and not dream_push:vel=Vector2.ZERO
		elif float(en.get("boss_phase_left",0))>0 and not dream_push:
			vel.x=move_toward(vel.x,0,delta*1500)
			vel.y=move_toward(vel.y,0,delta*1500) if Motion.airborne(en) else minf(800,vel.y+GRAVITY*delta)
		elif float(en["stun"])>0 and float(en.get("push_left",0))<=0:
			vel.x=move_toward(vel.x,0,delta*300)
			vel.y=move_toward(vel.y,0,delta*300) if Motion.airborne(en) else minf(800,vel.y+GRAVITY*delta)
		elif float(en.get("push_left",0))>0:
			var step:float=minf(movement_delta,float(en["push_left"]))
			en["push_left"]=maxf(0,float(en["push_left"])-movement_delta)
			var impulse:Vector2=en["push_velocity"]*step/maxf(movement_delta,.00001)
			en["push_base_y"]=float(en.get("push_base_y",vel.y))+(0 if Motion.airborne(en) else GRAVITY*movement_delta)
			vel=Vector2(impulse.x,float(en["push_base_y"])+impulse.y)
		else:vel=Motion.velocity(en,p["pos"],movement_delta,rng,grounded,world,body_size)
		# A ram is one deliberately telegraphed attack, not a second movement attack.
		if not frozen and float(en["stun"])<=0 and atk.is_active() and atk.attack.get("ram",false):
			vel.x=float(atk.attack.get("ram_direction",en["face"]))*float(atk.attack.get("ram_speed",340))
		# Facing is held through the hysteresis zone and telegraphed charges.
		var flying:bool=Motion.airborne(en)
		if not flying and grounded and vel.y>=0:
			var margin:float=20.0*float(en["scale"])
			if en["pos"].x+vel.x*movement_delta<support.position.x+margin or en["pos"].x+vel.x*movement_delta>support.end.x-margin:vel.x=0
		var old:Vector2=en["pos"]
		var resolved:Dictionary=Coll.move_body(old,vel,movement_delta,body_size,world if flying else solids)
		Motion.resolve_collision(en,vel,resolved["vel"])
		if atk.is_active() and atk.attack.get("ram",false) and absf(vel.x)>80 and absf(resolved["vel"].x)<absf(vel.x)*.25:
			atk._change_phase("recovery");en["ram_hit_wall"]=true
		en["pos"]=resolved["pos"];vel=resolved["vel"]
		var half_width:float=body_size.x*.5
		en["pos"].x=clampf(en["pos"].x,400 if int(en["model"])==4 else 28+half_width,_room_size().x-400 if int(en["model"])==4 else _room_size().x-28-half_width)
		if flying:
			en["pos"].y=clampf(en["pos"].y,55+body_size.y,_room_floor()-30)
		else:
			var ground:float=_support_y(old,en["pos"],vel.y,9.0*float(en["scale"]))
			if ground<INF:en["pos"].y=ground;vel.y=0
			en["pos"].y=maxf(55+body_size.y,en["pos"].y)
		if en.get("render_face",en["face"])!=en["face"]:en["turn_left"]=.25
		else:en["turn_left"]=maxf(0,float(en.get("turn_left",0))-delta)
		en["render_face"]=en["face"]
		en["vel"]=vel
		if int(en["model"])==4:_confine_boss(en)
		if float(en.get("contact_damage",CONTACT_DAMAGE))>0 and _enemy_body_box(en).intersects(_body_box(p["pos"])):
			_hurt_player(float(en.get("contact_damage",CONTACT_DAMAGE)),en["pos"])
			if screen!="game" or current_room!=initial_room:return
		if frozen:continue
		if atk.is_active() and not bool(atk.attack.get("emitted",false)):
			atk.attack["emitted"]=true
			if atk.attack.get("library_kind","")=="trap":_emit_traps(en,atk.attack)
			elif atk.attack.get("library_kind","")=="explosion":_explode(en["pos"]-Vector2(0,25),float(atk.attack["range"]),float(atk.attack["damage"]),150,false,{},str(atk.attack.get("group","biological")))
			elif not bool(atk.attack.get("primary",true)):
				_emit_weapon(en["pos"]+Vector2(0,float(atk.attack.get("origin_y",-30))),atk.attack.get("aim",toward.normalized()),atk.attack,false)
		if atk.is_active() and bool(atk.attack.get("primary",false)):
			if not atk.attack.get("ram",false) and p_attack.is_active() and bool(p_attack.attack.get("primary",false)) and _attack_box(p["pos"],p_attack.attack,float(p["face"])).intersects(_attack_box(en["pos"],atk.attack,float(en["face"]))):
				_parry(en);continue
			var swing:int=mini(int(atk.attack.get("count",1))-1,int(atk.progress()*int(atk.attack.get("count",1))))
			var enemy_hit:Rect2=_enemy_body_box(en) if atk.attack.get("ram",false) else _attack_box(en["pos"],atk.attack,float(en["face"]))
			if enemy_hit.intersects(_body_box(p["pos"])) and atk.mark_hit(-1-swing):_hurt_player(float(atk.attack["damage"]),en["pos"])

func _try_enemy_attack(en:Dictionary,toward:Vector2) -> void:
	if float(en.get("hp",0))<=0 or not _in_aggro(en) or en.get("passive",false) or not Motion.can_attack(en) or float(en.get("boss_phase_left",0))>0:return
	if Motion.current(en)=="dash" and (float(en.get("motion_dash_left",0))>0 or float(en.get("motion_dash_wait",0))<0):return
	var attacks:Array=en.get("attacks",[])
	if attacks.is_empty():return
	var cursor:int=int(en.get("attack_cursor",0))
	var candidates:Array[int]=[]
	for offset in attacks.size():
		var index:int=(cursor+offset)%attacks.size()
		var def:Dictionary=attacks[index]
		var melee:bool=def["library_kind"] in ["slash","explosion"]
		var origin:Vector2=en["pos"]+Vector2(0,float(def.get("origin_y",-28)))
		var center:Vector2=p["pos"]-Vector2(0,21)
		var fits:bool=absf(center.x-origin.x)<float(def["range"])+30 and absf(center.y-origin.y)<float(def["size"])+35 if melee else toward.length()<minf(900,float(def["range"])+100)
		if def.get("ram",false):
			var enemy_box:Rect2=_enemy_body_box(en);var player_box:Rect2=_body_box(p["pos"])
			fits=absf(toward.x)<_ram_trigger_distance(en,def) and absf(enemy_box.get_center().y-player_box.get_center().y)<(enemy_box.size.y+player_box.size.y)*.5-2.0
		if not fits:continue
		if int(en.get("model",0))==4:
			candidates.append(index);continue
		_start_enemy_attack(en,def)
		en["attack_cursor"]=(index+1)%attacks.size()
		return
	if not candidates.is_empty():
		var chosen:int=BossDirector.choose(en,toward,candidates)
		_start_enemy_attack(en,attacks[chosen])
		if en["attack"].is_busy():BossDirector.started(en,chosen);en["attack_cursor"]=(chosen+1)%attacks.size()

func _ram_trigger_distance(en:Dictionary,definition:Dictionary) -> float:
	# Attack clocks use real seconds while bodies integrate world-speed seconds.
	# Reserve a small end-of-lunge margin so a stationary target at the trigger
	# edge is reachable, including discrete physics steps and both body widths.
	var active_seconds:float=float(definition.get("active",.42))*phase_multiplier/maxf(.1,float(en.get("attack_speed",1)))
	var stride:float=float(definition.get("ram_speed",340))*active_seconds*world_speed
	var contact_span:float=(_enemy_body_box(en).size.x+_body_box(p["pos"]).size.x)*.5
	return minf(float(definition.get("range",235))+30.0,maxf(0,stride+contact_span-16.0))

func _start_enemy_attack(en:Dictionary,definition:Dictionary) -> void:
	if float(en.get("hp",0))<=0:return
	var def:Dictionary=BossDirector.attack_definition(en,definition) if int(en.get("model",0))==4 else definition.duplicate(true)
	var origin:Vector2=en["pos"]+Vector2(0,float(def.get("origin_y",-28)))
	var target:Vector2=p["pos"]-Vector2(0,21)
	en["face"]=signf(target.x-origin.x) if absf(target.x-origin.x)>1 else en["face"]
	if def.get("ram",false):def["ram_direction"]=float(en["face"])
	def["direction"]="right" if float(en["face"])>0 else "left"
	def["owner_uid"]=en["uid"]
	def["aim"]=(target-origin).normalized()
	def["target"]=en["pos"]+(p["pos"]-en["pos"]).limit_length(float(def.get("range",500)))
	for key in ["windup","active","recovery"]:def[key]=float(def[key])*phase_multiplier/maxf(.1,float(en.get("attack_speed",1)))
	if mode=="musou":Dream.instant(def)
	if en["attack"].begin(def):en["cooldown"]=float(def["windup"])+float(def["active"])+float(def["recovery"])+float(def.get("attack_cooldown",1.1))/maxf(.1,float(en.get("attack_speed",1)))

func _enemy_body_box(en:Dictionary) -> Rect2:
	var body:Vector2=MonsterMotion.body_size(en)
	return Rect2(en["pos"]-Vector2(body.x*.5,body.y),body)

func _air_spawn(anchor:Vector2,scale_value:float,actual_size:Vector2=Vector2.ZERO) -> Vector2:
	for offset_y in [65,110,160,35,210]:
		for offset_x in [0,55,-55,110,-110,165,-165]:
			var half:float=maxf(50,actual_size.x*.5+12);var top:float=maxf(65,actual_size.y+12)
			var at:Vector2=Vector2(clampf(anchor.x+offset_x,half,_room_size().x-half),clampf(anchor.y-offset_y,top,_room_floor()-60))
			var body:Rect2=Rect2(at-Vector2(actual_size.x*.5,actual_size.y),actual_size).grow(5) if actual_size!=Vector2.ZERO else _body_box(at,scale_value).grow(5)
			var free:bool=true
			for surface in platforms+solids:
				if body.intersects(surface):free=false;break
			if free:return at
	return Vector2.INF if actual_size!=Vector2.ZERO else anchor-Vector2(0,65)

func _fit_enemy_ground(en:Dictionary) -> Vector2:
	var desired:Vector2=en["pos"];var body:Vector2=MonsterMotion.body_size(en)
	var best:=Vector2.INF;var distance:float=INF
	for surface:Rect2 in platforms:
		if surface.size.x<body.x+2 or absf(surface.position.y-desired.y)>192:continue
		var x:float=clampf(desired.x,surface.position.x+body.x*.5+1,surface.end.x-body.x*.5-1)
		if absf(x-desired.x)>192:continue
		var at:=Vector2(x,surface.position.y);var box:=Rect2(at-Vector2(body.x*.5,body.y),body).grow(-.01)
		if solids.any(func(rock:Rect2)->bool:return box.intersects(rock)):continue
		if doors.any(func(door:Dictionary)->bool:return at.distance_to(door["pos"])<180):continue
		var cost:float=absf(at.x-desired.x)+absf(at.y-desired.y)*2
		if cost<distance:distance=cost;best=at
	return best

func _enemy_support(en:Dictionary) -> Rect2:
	for surface in platforms+solids:
		if absf(en["pos"].y-surface.position.y)<1 and en["pos"].x>=surface.position.x and en["pos"].x<=surface.end.x:
			return surface
	return Rect2()

func _enemy_begin(en:Dictionary,ranged:bool) -> void:
	for def in en.get("attacks",[]):
		if bool(def.get("primary",false))!=ranged:_start_enemy_attack(en,def);return

func _emit_weapon(at:Vector2,dir:Vector2,def:Dictionary,from_player:bool) -> void:
	if from_player and def.get("weapon_kind","")=="trap":
		var trap:Dictionary=def.duplicate(true);trap["from_player"]=true;trap["group"]="biological";trap["hazard_visual_id"]="moss_thorns";trap["target"]=at+dir.normalized()*260
		_emit_traps({"pos":at+Vector2(0,35),"uid":-1},trap);return
	if from_player and def.get("weapon_kind","") in ["laser","chain"]:_cast_special(at,dir,def);return
	var shots:int=clampi(int(def.get("count",def.get("shots",1))),1,20)
	var kind:String=str(def.get("weapon_kind","shot"))
	if def.get("library_kind","")=="explosion":_explode(at,float(def.get("range",90)),float(def.get("damage",3)),float(def.get("knockback",180)),from_player,{},str(def.get("group","weapon" if from_player else "biological")));return
	var sprite:String="needle" if kind=="shot" else ("fruit" if kind=="throw" else ("acorn" if kind=="fan" else ""))
	if def.has("sprite"):sprite=str(def["sprite"])
	var direction:Vector2=dir.normalized() if dir.length_squared()>.001 else Vector2.RIGHT
	var path:String=str(def.get("path_kind","arc" if kind=="throw" else "straight"))
	var spread:float=float(def.get("spread",.23 if kind=="fan" else .17))
	for i in shots:
		if projectiles.size()>=384:break
		var heading:Vector2=direction.rotated((float(i)-float(shots-1)*.5)*spread)
		if def.get("style_id","")=="root_wave" or kind=="wave":heading=Vector2(1 if i%2==0 else -1,0)
		var radius:float=float(def.get("size",9 if kind=="throw" else 6))
		var spawn:Vector2=at
		spawn.y=minf(spawn.y,_room_floor()-radius-2)
		if spread==0 and shots>1 and def.get("style_id","")!="root_wave":spawn+=direction.orthogonal()*(float(i)-float(shots-1)*.5)*radius*2.1
		var velocity:Vector2=heading*float(def.get("speed",550))
		var gravity:float=float(def.get("gravity",600)) if path=="arc" or kind=="throw" else 0
		if gravity!=0:velocity.y+=float(def.get("launch_y",-260))
		var distance:float=float(def.get("range",900))
		projectiles.append({"pos":spawn,"vel":velocity,"sprite":sprite,"from_player":from_player,"damage":float(def.get("damage",3)),"life":float(def.get("lifetime",distance/maxf(1,velocity.length())+1)),"color":def.get("color",Color.WHITE),"kind":kind,"radius":radius,"gravity":gravity,"pierce":bool(def.get("piercing",false)) or (from_player and _rune_effect("pierce")>0),"hits":{},"bounces":int(def.get("bounces",0)),"distance_left":distance,"style_id":str(def.get("style_id",kind)),"boss_biome":str(def.get("boss_biome","")),"visual_id":str(def.get("visual_id","")),"group":str(def.get("group","weapon" if from_player else "biological")),"elapsed":0.0,"return_after":float(def.get("return_after",.7 if path=="return" else 0)),"origin":spawn,"launch_angle":direction.angle(),"base_velocity":velocity,"wave_amplitude":float(def.get("wave_amplitude",0)) if path=="sine" or def.get("style_id","")=="dew_bubble" else 0.0,"wave_frequency":float(def.get("wave_frequency",4)),"knockback":float(def.get("knockback",76)),"explode_on_hit":bool(def.get("explode_on_hit",false)),"explosion_radius":float(def.get("explosion_radius",80)),"parryable":bool(def.get("parryable",kind=="flying_slash")),"owner_uid":int(def.get("owner_uid",-2)),"weapon_id":str(def.get("id","")),"homing":def.get("weapon_kind","")=="homing","ground_fire":bool(def.get("ground_fire",false)),"fire_size":float(def.get("explosion_radius",100)),"dream_slash":bool(def.get("dream_slash",false))})
	_effect(at,Color(def.get("color",Color.WHITE)),28,.15);_sound("slash")

func _segment_hits_box(a:Vector2,b:Vector2,box:Rect2) -> bool:
	var direction:Vector2=b-a
	var lower:float=0.0;var upper:float=1.0
	for axis in 2:
		if absf(direction[axis])<.000001:
			if a[axis]<box.position[axis] or a[axis]>box.end[axis]:return false
		else:
			var t1:float=(box.position[axis]-a[axis])/direction[axis]
			var t2:float=(box.end[axis]-a[axis])/direction[axis]
			lower=maxf(lower,minf(t1,t2));upper=minf(upper,maxf(t1,t2))
			if lower>upper:return false
	return true

func _projectile_impact(pr:Dictionary) -> void:
	var biome:String=pr.get("boss_biome","")
	if biome.is_empty():return
	if effects.size()>=MAX_PARTICLES:effects.pop_front()
	effects.append({"boss_fx":biome,"pos":pr["pos"],"color":pr["color"],"life":.4,"max":.4,"radius":0.0,"ring":false,"vel":Vector2.ZERO,"fx_scale":.65})

func _projectile_surfaces() -> Array:
	# Pass-through traversal ledges are supports, never horizontal shot barriers.
	var pass_through:Array=layout.get("one_way",[])
	return solids+platforms.filter(func(surface:Rect2)->bool:return not pass_through.has(surface))

func _update_projectiles(delta:float) -> void:
	var initial_room:int=current_room
	var world:Array=_projectile_surfaces()
	for pr in projectiles:
		if float(pr["life"])<=0:continue
		pr["life"]-=delta;pr["elapsed"]=float(pr.get("elapsed",0))+delta
		if float(pr.get("return_after",0))>0 and float(pr["elapsed"])>=float(pr["return_after"]):pr["vel"]=(pr["origin"]-pr["pos"]).normalized()*pr["base_velocity"].length()
		if float(pr.get("wave_amplitude",0))>0:pr["vel"].y=pr["base_velocity"].y+float(pr["wave_amplitude"])*float(pr["wave_frequency"])*cos(float(pr["elapsed"])*float(pr["wave_frequency"]))
		if pr.get("homing",false) and pr.get("from_player",false):
			var target:Vector2=Vector2.INF;var closest:float=600
			for enemy:Dictionary in enemies:
				var center:Vector2=_enemy_body_box(enemy).get_center();var distance:float=center.distance_to(pr["pos"])
				if enemy["hp"]>0 and distance<closest and Coll.first_solid(pr["pos"],center,1,solids)==INF:target=center;closest=distance
			if target.is_finite():pr["vel"]=Vector2(pr["vel"]).rotated(clampf(Vector2(pr["vel"]).angle_to(target-pr["pos"]),-2.4*delta,2.4*delta))
		pr["vel"].y+=float(pr.get("gravity",0))*delta
		var old:Vector2=pr["pos"];var radius:float=float(pr["radius"])
		var movement:Vector2=(pr["vel"]*delta).limit_length(maxf(0,float(pr.get("distance_left",INF))))
		var next:Vector2=old+movement
		var wall_t:float=Coll.first_solid(old,next,radius,world)
		var wall_hit:bool=wall_t<INF
		if wall_hit:next=old+movement*maxf(0,wall_t-.0001)
		pr["pos"]=next
		ProjectileReadability.record(pr,old,next,delta)
		if combat_feedback!=null and view_rect.grow(80).has_point(pr["pos"]):combat_feedback.projectile_trail(pr,world_speed)
		pr["distance_left"]=float(pr.get("distance_left",INF))-old.distance_to(next)
		if pr.get("trap_carrier",false):
			if not pr.get("destroyed",false) and (wall_hit or pr["life"]<=0 or pr["distance_left"]<=0):_settle_trap(pr);pr["life"]=0
			continue
		if bool(pr["from_player"]):
			for en in enemies:
				if en["hp"]<=0:continue
				var ea=en["attack"]
				if ea.is_active() and bool(ea.attack.get("primary",false)) and _segment_hits_box(old,next,_attack_box(en["pos"],ea.attack,float(en["face"])).grow(radius)):
					pr["life"]=0;_projectile_impact(pr);_block_effect(next);break
				if not pr["hits"].has(en["uid"]) and _segment_hits_box(old,next,_enemy_body_box(en).grow(radius)):
					pr["hits"][en["uid"]]=true;_projectile_impact(pr)
					if pr.get("bee",false):_contact_fx("bee_hit",next)
					_hit_enemy(en,float(pr["damage"]),pr["color"],float(pr.get("knockback",76)),old,pr["vel"].normalized(),not pr.get("dream_slash",false))
					_projectile_explosion(pr)
					if not pr["pierce"]:pr["life"]=0;break
			if float(pr["life"])>0:
				_hit_props(Rect2(next-Vector2.ONE*radius,Vector2.ONE*radius*2),float(pr["damage"]),1)
				_damage_traps(Rect2(old.min(next),old.max(next)-old.min(next)).grow(radius),float(pr["damage"]),not pr.get("dream_slash",false))
		else:
			var blocked:bool=false
			if _rune_effect("orbit_shield")>0:
				for i in 2:
					var shield:Vector2=p["pos"]-Vector2(0,24)+Vector2.from_angle(draw_clock*2+i*PI)*52
					if _segment_hits_box(old,next,Rect2(shield-Vector2.ONE*(12+radius),Vector2.ONE*(24+radius*2))):pr["life"]=0;blocked=true;_block_effect(shield,"orbit_shield_intercept");break
			if not blocked and p_attack.is_active() and bool(p_attack.attack.get("primary",false)) and _segment_hits_box(old,next,_block_box().grow(radius)):
				if pr.get("parryable",false):
					for en in enemies:
						if int(en["uid"])==int(pr.get("owner_uid",-2)):_parry(en);break
				if _rune_effect("reflect")>0:
					pr["from_player"]=true;pr["hits"]={};pr["vel"]=-pr["vel"];pr["base_velocity"]=pr["vel"];pr["pos"]=p["pos"]+Vector2(float(p["face"])*45,-25);pr["distance_left"]=maxf(200,float(pr["distance_left"]));pr["return_after"]=0
				else:pr["life"]=0
				blocked=true;_projectile_impact(pr);_block_effect(next,"reflect" if _rune_effect("reflect")>0 else "block")
			if not blocked and not pr["hits"].has(-1) and _segment_hits_box(old,next,_body_box(p["pos"]).grow(radius)):
				pr["hits"][-1]=true;_projectile_impact(pr);_hurt_player(float(pr["damage"]),pr["pos"]);_projectile_explosion(pr)
				if not pr["pierce"]:pr["life"]=0
		if screen!="game" or current_room!=initial_room or not life_event.is_empty():return
		if wall_hit and float(pr["life"])>0:
			if int(pr.get("bounces",0))>0:
				var contact:Dictionary=Explosion.contact(pr["pos"],pr["vel"],world,radius)
				var normal:Vector2=contact.get("normal",Vector2.LEFT)
				pr["vel"]=Vector2(pr["vel"]).bounce(normal);pr["base_velocity"]=pr["vel"];pr["pos"]+=normal*1.0;pr["bounces"]-=1
			else:
				var impact:Dictionary=Explosion.contact(pr["pos"],pr["vel"],world,radius)
				pr["impact_normal"]=impact.get("normal",Vector2.ZERO);pr["impact_point"]=impact.get("point",pr["pos"])
				pr["life"]=0;_projectile_impact(pr);_projectile_explosion(pr)
		if pr["distance_left"]<=.001:pr["life"]=0
	if combat_feedback!=null:
		for pr in projectiles:
			if float(pr["life"])<=0:combat_feedback.finish_trail(pr)
	projectiles=projectiles.filter(func(pr:Dictionary)->bool:return float(pr["life"])>0)

func _trap_position(at:Vector2) -> Vector2:
	var y:float=INF
	var x:float=clampf(at.x,35,_room_size().x-35)
	for surface:Rect2 in platforms+solids:
		if x>surface.position.x+12 and x<surface.end.x-12 and surface.position.y>=at.y-5:y=minf(y,surface.position.y)
	return Vector2(x,_room_floor() if y==INF else y)

func _emit_traps(en:Dictionary,def:Dictionary) -> void:
	var target:Vector2=def.get("target",p["pos"])
	for i in clampi(int(def.get("count",1)),1,20):
		if projectiles.size()>=384:break
		var landing:Vector2=_trap_position(target+Vector2((i-float(int(def.get("count",1))-1)*.5)*float(def["size"])*1.8,0))
		var start:Vector2=en["pos"]-Vector2(0,35)
		var gravity:float=900;var flight:float=.38
		var velocity:Vector2=(landing-start)/flight-Vector2(0,.5*gravity*flight)
		projectiles.append({"pos":start,"vel":velocity,"launch_angle":Vector2(target-start).angle(),"radius":float(def.get("size",16)) if def.get("from_player",false) else 8.0,"life":flight,"elapsed":0.0,"gravity":gravity,"distance_left":1000.0,"trap_carrier":true,"landing":landing,"visual_id":str(def.get("visual_id","")),"hazard_visual_id":str(def.get("hazard_visual_id","")),"weapon_id":str(def.get("id","")),"definition":def.duplicate(true),"group":str(def.get("group","biological")),"from_player":bool(def.get("from_player",false)),"owner_uid":en["uid"],"color":def["color"],"kind":"throw","sprite":"fruit","hits":{},"pierce":false,"damage":0.0,"bounces":0,"boss_biome":str(def.get("boss_biome",""))})

func _update_hazards(delta:float) -> void:
	var initial_room:int=current_room
	for hazard in hazards:
		if float(hazard.get("hp",1))<=0:continue
		hazard["elapsed"]+=delta
		if hazard.get("fire",false):GroundFire.emit(hazard,effects,delta,low_effects,MAX_PARTICLES)
		if hazard["elapsed"]<float(hazard.get("arming_time",0)) or hazard["elapsed"]>float(hazard.get("lifetime",4))+float(hazard.get("arming_time",0)):continue
		var zone:Rect2=Rect2(Vector2(hazard["pos"])-Vector2(float(hazard.get("size",100))*.5,32),Vector2(float(hazard.get("size",100)),32)) if hazard.get("fire",false) else TrapArt.body_box(hazard)
		if hazard.get("from_player",false):
			for en in enemies:
				var uid:int=int(en["uid"]);var hits:int=int(hazard["hits"].get(uid,0))
				if en["hp"]<=0 or hits>=int(hazard["max_hits"]) or hazard["elapsed"]<float(hazard["next_hit"].get(uid,0)):continue
				if zone.intersects(_enemy_body_box(en)):
					_hit_enemy(en,float(hazard["damage"]),hazard["color"],float(hazard.get("knockback",76)));hazard["hits"][uid]=hits+1;hazard["next_hit"][uid]=float(hazard["elapsed"])+float(hazard["hit_interval"])
		else:
			var hits:int=int(hazard["hits"].get(-1,0))
			if hits>=int(hazard["max_hits"]) or hazard["elapsed"]<float(hazard["next_hit"].get(-1,0)):continue
			if zone.intersects(_body_box(p["pos"])) and _hurt_player(float(hazard["damage"]),hazard["pos"]):hazard["hits"][-1]=hits+1;hazard["next_hit"][-1]=float(hazard["elapsed"])+float(hazard["hit_interval"])
		if screen!="game" or current_room!=initial_room or not life_event.is_empty():return
	hazards=hazards.filter(func(hazard:Dictionary)->bool:return float(hazard.get("hp",1))>0 and float(hazard["elapsed"])<float(hazard.get("lifetime",4))+float(hazard.get("arming_time",0)) and (hazard.get("from_player",false) or int(hazard["hits"].get(-1,0))<int(hazard["max_hits"])))

func _block_effect(at:Vector2,clip:String="block") -> void:
	_contact_fx(clip,at)
	_particles(at,Color("fff1b3"),10,150);_float(at,"擋彈",Color("fff1b3"));_sound("parry")

func _enemy_defeated(en: Dictionary) -> void:
	if en.get("corpse_created",false):return
	en["corpse_created"]=true;corpses.append(CorpseField.create(en));room["corpses"]=corpses
	if corpse_layer!=null:corpse_layer.invalidate()
	kills+=1
	var gold: int=150+int(room.get("map_index",0))*25 if int(en["model"])==4 else 3
	if int(en["model"])==4:
		for i in 5:_drop("coin",en["pos"]+Vector2((i-2)*85,-25),gold/5)
	else:_drop("coin",en["pos"]-Vector2(0,15),gold)
	if rng.randf()<.1: _drop("item",en["pos"]-Vector2(25,20),rng.randi_range(0,Data.ITEMS.size()-1))
	if rng.randf()<(.32 if mode=="musou" else .07): _drop("heal",en["pos"]+Vector2(25,-20),1)
	if rng.randf()<.24:_drop("rune",en["pos"]+Vector2(10,-45),_random_rune_index())
	if rng.randf()<(.60 if mode=="musou" else .25):_drop("weapon",en["pos"]+Vector2(15,-35),Arsenal.random_index(rng))
	if rng.randf()<_rune_effect("leech"): _restore_vital("hp",1)
	if int(en["model"])==4:
		_drop("rune",en["pos"]-Vector2(35,40),Data.RUNES.size()+rng.randi_range(0,Data.STRONG_RUNES.size()-1))
		_drop("weapon",en["pos"]+Vector2(55,-40),Arsenal.random_index(rng))
	_check_room_clear()

func _check_room_clear() -> void:
	if room.get("type","") not in ["elite","boss"] or room.get("cleared",false):return
	if enemies.any(func(enemy:Dictionary)->bool:return float(enemy["hp"])>0 and not enemy.get("training",false)):return
	room["cleared"]=true;hazards.clear()
	if room["type"]=="elite":
		var at:Vector2=_trap_position(p["pos"])
		props.append({"kind":"chest","pos":at,"used":false,"hurt":0.0,"guaranteed_strong":true});room["props"]=props
		_toast("菁英房清除！寶箱必定含大符文")
	else:_toast("首領與菁英守衛已擊敗，下一關側門開啟！")
	_invalidate_scene();_save_meta()

func _drop(kind: String, at: Vector2, value: int) -> void:
	if kind=="coin":
		for i in maxi(0,value):
			var coin:Dictionary={"kind":"coin","pos":Vector2(clampf(at.x+float(i%7-3)*3,35,_room_size().x-35),at.y-float(i/7)*3),"value":1,"seed":rng.randf()*TAU,"taken":false,"impact_cd":0.0}
			Coins.initialize(coin,Vector2(rng.randf_range(-210,210),rng.randf_range(-300,-130)))
			drops.append(coin)
		return
	var position:=Vector2(clampf(at.x,42,_room_size().x-42),at.y)
	for attempt in 19:
		position.x=clampf(at.x+(0 if attempt==0 else (1 if attempt%2 else -1)*ceili(attempt*.5)*38),42,_room_size().x-42)
		if not drops.any(func(other:Dictionary)->bool:return other["kind"]!="coin" and Vector2(other["pos"]).distance_to(position)<36):break
	var drop:Dictionary={"kind":kind,"pos":position,"value":value,"seed":rng.randf()*TAU,"taken":false,"radius":18.0}
	Coins.initialize(drop,Vector2(rng.randf_range(-180,180),rng.randf_range(-350,-190)))
	drops.append(drop)

func _update_drops(delta:float) -> void:
	var picked_gold:int=0
	var bounds:=Rect2(Vector2(18,0),_room_size()-Vector2(36,0))
	for drop in drops:
		if bool(drop["taken"]):continue
		if drop.get("display_only",false) or drop.get("gift",false):
			drop["pos"]=drop.get("display_anchor",drop["pos"]);drop["vel"]=Vector2.ZERO;continue
		if not drop.has("radius"):drop["radius"]=7.0 if drop["kind"]=="coin" else 18.0
		Coins.initialize(drop,Vector2(rng.randf_range(-180,180),rng.randf_range(-350,-190)) if not drop.has("vel") else Vector2.ZERO)
		drop["impact_cd"]=maxf(0,float(drop.get("impact_cd",0))-delta)
		var target:Vector2=p["pos"]-Vector2(0,20)
		var distance:float=drop["pos"].distance_to(target)
		if drop["kind"]=="coin" and float(drop["age"])>.35 and distance<125+_rune_effect("magnet"):
			drop["sleeping"]=false;drop["vel"]=drop["vel"].move_toward((target-drop["pos"]).normalized()*450,delta*1200)
		var nearby:Array=[] if drop.get("sleeping",false) and Vector2(drop["vel"]).length_squared()<.01 else coin_field.query(drop["pos"],drop["vel"],delta,float(drop["radius"])+3)
		if Coins.step(drop,delta,nearby,bounds) and drop["kind"]=="coin" and float(drop["impact_cd"])<=0:
			drop["impact_cd"]=.15;_particles(drop["pos"],Color("efdba3"),4,65);_sound("coin")
		var dist:float=drop["pos"].distance_to(p["pos"]-Vector2(0,20))
		if dist<36 and float(drop.get("age",0))>.35:
			drop["taken"]=true
			if drop["kind"]=="coin":picked_gold+=int(drop["value"])
			else:_give_drop(str(drop["kind"]),int(drop["value"]))
	CoinField.collide(drops.filter(func(d:Dictionary)->bool:return not d.get("display_only",false) and not d.get("gift",false)))
	if picked_gold>0:run_coins+=picked_gold;_sound("coin")
	drops=drops.filter(func(drop:Dictionary)->bool:return not bool(drop["taken"]))
	room["drops"]=drops

func _give_drop(kind: String, value: int) -> void:
	_sound("coin")
	match kind:
		"coin":run_coins+=value
		"heal": _restore_vital("hp",1);_float(p["pos"]-Vector2(0,50),"+1 生命",Color("a9ecc1"))
		"rune":
			var id:String=Data.all_runes()[value]["id"]
			bag_runes[id]=int(bag_runes.get(id,0))+1
			var equipped:bool=_auto_equip_rune(id)
			_toast(("自動裝備：" if equipped else "取得符文：")+Data.all_runes()[value]["name"]+"；存入倉庫後永久保存")
		"weapon":
			_acquire_weapon(Data.secondary_attack(value))
		"growth":_grow_secondary(value)
		"upgrade":_apply_upgrade(value)
		"item":
			bag_items[str(value)]=int(bag_items.get(str(value),0))+1;_toast("道具收入背包："+Data.ITEMS[value]["name"])
	_save_meta()

func _apply_upgrade(value: int) -> void:
	var names: Array[String]=["主武器觸及","攻擊節奏","集氣效率","副武器火力","彈體數量","主武器力量"]
	var prop: String=["reach","haste","charge","subpower","shots","power"][value]
	upgrades[prop]+=1;upgrades["count"]+=1
	_toast("累加強化："+names[value]+" +1　總強化 %d"%int(upgrades["count"]))

func _use_item(index: int, from_bag: bool=true,open_bag:bool=true) -> void:
	if not merchant_trial.is_empty():_toast("請先歸還試用品，再使用補給");return
	if index<0 or index>=Data.ITEMS.size() or _action_locked():return
	var item: Dictionary=Data.ITEMS[index]
	if from_bag:
		if int(bag_items.get(str(index),0))<=0: return
		bag_items[str(index)]-=1
	match item["id"]:
		"heal": _restore_vital("hp",2)
		"energy": p["energy"]=p["max_energy"]
		"shield": p["shield"]=5.0
		"freeze": freeze_timer=4.0
		"bomb":
			p_attack.cancel()
			var definition:Dictionary={"kind":"item_bomb","primary":false,"windup":.12,"active":.10,"recovery":.24,"damage":7.0+float(upgrades["power"]),"range":420.0,"color":Color("ffd18d")}
			p_attack.begin(Dream.instant(definition) if mode=="musou" else definition)
	_effect(p["pos"]-Vector2(0,20),item["color"],100,.45)
	_toast("施放："+item["name"])
	if from_bag and open_bag:_show_bag()
	_update_hud()

func new_run(chosen_mode: String, seed_value: int=-1) -> void:
	_return_trial(false)
	Tuning.activate(meta.get("rd_tuning",{}))
	mode=chosen_mode;screen="game";weapon_index=1;home_atmosphere.set_active(false);spring_particles.clear();_clear_keys();ui.close_panel()
	dream.clear();dream_visual.clear_waves()
	meta["attempts"]+=1
	kills=0;deaths=0;run_started=clock;run_recorded=false;last_checkpoint=-1;passive_energy=0
	rune_target_slot=-1;visited_count=0;revive_used=false;injured=false;feather={};life_event={};run_coins=0;sub_growth={};strong_slots.clear();empty_energy_time=0;move_energy_distance=0;bag_items.clear();bag_runes.clear();bag_weapons.clear();rune_slots.clear()
	upgrades={"count":0,"power":0.0,"reach":0.0,"haste":0.0,"charge":0.0,"shots":0,"subpower":0.0}
	var chosen_seed:int=seed_value if seed_value>=0 else (int(Tuning.value("seed")) if Tuning.value("seed")>0 else rng.randi_range(1,2000000000))
	tower=Tower.generate(chosen_seed,6,int(Tuning.value("rooms_per_stage")),Tuning.current)
	secondary_index=0
	_reset_player(Vector2(230,FLOOR_Y))
	_update_skills()
	_enter_room(int(tower["maps"][0]["start_id"]),"center")
	_toast("%s冒險開始：安全屋可取用收藏、切換武器與合成"%_mode_name())
	_save_meta()

func _enter_room(id: int, from_dir: String="center") -> void:
	_return_trial(false);bath.reset();spring_particles.clear()
	if dream_visual!=null:dream_visual.clear_waves()
	if not room.is_empty():
		room["enemies"]=enemies;room["drops"]=drops;room["corpses"]=corpses
	if walker!=null:walker.reset();walker.reset_turn(float(p["face"]))
	current_room=id;room=tower["rooms"][id]
	room["ecology"]=Ecology.from_stage(int(room["map_index"]))
	if room["type"]=="start":last_checkpoint=id
	if room_music!=null:room_music.select(str(room["type"]),str(room["ecology"]["id"]),bool(room.get("spring",false)))
	if not bool(room.get("visited",false)):
		visited_count+=1;room["visited"]=true;_update_skills()
	meta["best_map"]=maxi(int(meta["best_map"]),int(room["map_index"])+1)
	if not room.has("layout"):
		room["layout"]=Layout.generate(room,int(tower["seed"]))
	layout=room["layout"]
	if room.get("fountain",false) and not layout.has("fountain_pos"):preload("res://scripts/spring_v33.gd").prepare(layout)
	NewBiome.prepare(layout,int(layout.get("seed",0)))
	if room.get("type","")=="merchant" and not room.has("stock"):
		room["stock"]=Sanctuary.stock(int(room["map_index"]))
		for item:Dictionary in room["stock"]:item["pos"]+=_furniture_offset()
	platforms.assign(layout["platforms"])
	solids.assign(layout.get("solids",[]))
	coin_field.rebuild(platforms,solids)
	doors.clear()
	for dir in room["neighbors"]:
		doors.append({"dir":dir,"pos":layout["doors"][dir],"target":int(room["neighbors"][dir])})
	if not bool(room.get("initialized",false)):
		room["initialized"]=true;room["enemies"]=[];room["drops"]=[]
		var biome:Dictionary=_ecology()
		var plan:Array[Dictionary]=[]
		var spawn_density:float=float(room.get("practice_density",Tuning.value("enemy_density")))
		if room["type"] in ["combat","elite"] and not room.get("spring",false) and spawn_density>0:plan=Ecology.spawn_plan(layout,biome,mode,int(layout["seed"]),int(room["map_index"]),spawn_density)
		elif room["type"]=="boss":
			plan.append({"model":4,"pos":Vector2(_room_size().x*.5,_room_floor()),"platform":0})
			for guard in 3:plan.append({"model":3,"pos":Vector2(_room_size().x*(.30+.20*guard),_room_floor()),"platform":0})
		if room["type"]=="elite":
			for entry:Dictionary in plan:entry["model"]=3
			if plan.is_empty():
				for guard in 3:plan.append({"model":3,"pos":Vector2(_room_size().x*(.3+.2*guard),_room_floor()),"platform":0})
		plan=plan.filter(func(entry:Dictionary)->bool:
			if int(entry["model"])==4:return true
			for door in doors:
				if Vector2(entry["pos"]).distance_to(door["pos"])<180:return false
			return true)
		if mode=="musou":plan=Dream.expand_plan(plan,layout,int(room["map_index"]),int(layout["seed"]),doors)
		for i in plan.size():
			var model:int=int(plan[i]["model"])
			var spawn_rng:=RandomNumberGenerator.new();spawn_rng.seed=int(layout["seed"])+i*827+spawn_serial*3571
			var def:Dictionary=Combat.boss(["underground","grass","trunk","branches","canopy","sky"][int(room["map_index"])]) if model==4 else (MonsterRoster.elite(int(room["map_index"])) if model==3 else MonsterRoster.regular(str(biome["id"]),int(plan[i].get("roster_variant",(i+id)%5))))
			if room["type"]!="elite" and model!=4 and model!=3 and i==0 and int(layout["seed"])%3==0:def=Arms.cute_wanderer(spawn_rng)
			if model==4:
				for attack in def["attacks"]:attack["damage"]*=2;attack["knockback"]=120.0
			def["uid"]=id*100+i+1
			if model==4:room["boss_id"]=def["id"]
			def["pos"]=plan[i]["pos"];def["spawn_platform"]=plan[i]["platform"]
			if model!=4:def["biome"]=biome["id"]
			def["ecology_id"]=biome["id"]
			if not def.has("roster_id"):def["contact_damage"]=0.0 if def.get("passive",false) else CONTACT_DAMAGE

			if def["move"]=="fly":def["pos"]=_air_spawn(def["pos"]-Vector2(0,140 if model==4 else 0),float(def["scale"]),MonsterMotion.body_size(def))
			elif model!=4:
				var grounded_spawn:Vector2=_fit_enemy_ground(def)
				if not grounded_spawn.is_finite():continue
				def["pos"]=grounded_spawn
			if not Vector2(def["pos"]).is_finite():continue
			if model!=4 and doors.any(func(door:Dictionary)->bool:return def["pos"].distance_to(door["pos"])<180):continue
			def["vel"]=Vector2.ZERO;def["face"]=-1.0;def["stun"]=0.0;def["hurt"]=0.0;def["cooldown"]=1.0+i*.15;def["attack"]=Attack.new()
			def["hp"]=float(def["hp"])+float(room["map_index"])*(.5 if model!=4 else 10)
			if def.get("elite",false):def["hp"]*=3.0
			def["hp"]*=Tuning.value("enemy_hp");def["speed"]*=Tuning.value("enemy_speed")
			def["max_hp"]=def["hp"]
			room["enemies"].append(def)
		if room["type"] in ["merchant","start"]:
			for i in (2 if room["type"]=="start" else 1):
				var dummy_rng:=RandomNumberGenerator.new();dummy_rng.seed=int(layout["seed"])+i
				var dummy:Dictionary=Arms.enemy("walk",dummy_rng,false,true)
				var anchor:=_furniture_offset()+Vector2(870 if i==0 and room["type"]=="start" else (1110 if i==1 else 1360),1050-(35 if i==1 else 0))
				dummy.merge({"training":true,"floating":i==1,"anchor":anchor,"training_age":0.0,"contact_damage":0.0,"uid":id*100+98+i,"pos":anchor,"vel":Vector2.ZERO,"face":-1.0,"hp":999999.0,"max_hp":999999.0,"body_size":Vector2(84,120),"hurt":0.0,"stun":0.0,"cooldown":1000.0,"attack":Attack.new(),"training_total":0.0},true)
				room["enemies"].append(dummy)
		if room["type"]=="start" and int(room["map_index"])==0 and not room.get("gift_given",false):
			room["gift_given"]=true
			room["drops"].append({"kind":"weapon","pos":_furniture_offset()+Vector2(620,1050-90),"value":Arsenal.random_index(rng),"seed":0.0,"taken":false,"gift":true,"display_only":true,"display_anchor":_furniture_offset()+Vector2(620,1050-90)})
	if not room.has("props"):room["props"]=_make_props()
	props.assign(room["props"])
	var loaded_enemies:Array[Dictionary]=[]
	loaded_enemies.assign(room["enemies"])
	var loaded_drops:Array[Dictionary]=[]
	loaded_drops.assign(room["drops"])
	enemies=loaded_enemies;drops=loaded_drops
	var loaded_corpses:Array[Dictionary]=[];loaded_corpses.assign(room.get("corpses",[]));corpses=loaded_corpses
	if corpse_layer!=null:corpse_layer.invalidate()
	projectiles.clear();hazards.clear();effects.clear();
	if combat_feedback!=null:combat_feedback.clear()
	if atmosphere!=null:
		atmosphere.room_bounds=_room_size();atmosphere.configure(str(room["ecology"]["id"]),int(layout["seed"]),true,room["type"]=="merchant",room["type"] in ["start","merchant","reward"] or room.get("spring",false),layout)
	p_attack.cancel();p["slam"]=false;p["dash_t"]=0
	var spawn: Vector2=layout["spawn_positions"].get(from_dir,layout["spawn_positions"]["center"])
	drop_through_timer=0.0
	p["pos"]=spawn;p["vel"]=Vector2.ZERO;p["grounded"]=true;p["wall"]=0;p["invul"]=maxf(.5,float(p["invul"]));_restore_ground_movement()
	room_cooldown=.6;camera_pos=_camera_target(spawn);last_motion_pos=spawn
	atmosphere.depth_origin=camera_pos;atmosphere.depth_origin_ready=true
	_save_meta();_update_hud();_invalidate_scene()

func _interact(allow_panel:bool=true) -> void:
	if _action_locked():return
	if room_cooldown>0: return
	if screen=="hub":
		_home_interact();return
	if screen!="game":return
	if allow_panel and merchant_trial.is_empty() and room.get("type","")=="merchant":
		var product:int=Sanctuary.nearest_stock(room.get("stock",[]),p["pos"])
		if product>=0:_show_merchant(product);return
	for prop in props:
		if prop["pos"].distance_to(p["pos"])<110:
			if prop["kind"]=="chest" and not prop.get("used",false):_open_chest(prop);return
			if prop["kind"]=="merchant" and allow_panel:_show_merchant();return
	if allow_panel:
		for drop in drops:
			if drop.get("gift",false) and not drop.get("taken",false) and (drop["pos"]+Vector2(0,90)).distance_to(p["pos"])<90:_claim_gift();return
	if allow_panel and _nearest_reward()>=0:_show_reward(_nearest_reward());return
	if room["type"]=="boss" and int(room["map_index"])==5 and bool(room.get("cleared",false)) and absf(p["pos"].x-_room_size().x*.5)<150:
		_complete_run();return
	if allow_panel and _is_start():
		_activate_station(_nearest_station())

func _activate_station(station:String,attack_confirm:bool=false) -> bool:
	# Attacking the nearest practice prop must still hit it, rather than open
	# an adjacent forge or the dummy's information panel.
	if station.is_empty() or (attack_confirm and station in ["dummy","energy_infinite"]):return false
	match station:
		"aid":_first_aid()
		"wardrobe":_show_shop()
		_:_show_prep(station)
	return true

func _nearest_station() -> String:
	var nearest:float=105;var chosen:String=""
	for prop in props:
		if prop["kind"] not in ["aid","mail","energy_infinite","dummy","forge","reforge","wardrobe"]:continue
		var distance:float=prop["pos"].distance_to(p["pos"])
		if distance<nearest:nearest=distance;chosen=prop["kind"]
	return chosen

func _complete_run() -> void:
	_return_trial(false)
	if run_recorded:return
	run_recorded=true;run_coins+=100
	var names:Array[String]=[]
	for weapon in bag_weapons:names.append(str(weapon["name"]))
	var record:Dictionary={"primary":Data.PRIMARY[weapon_index]["name"],"secondary":names,"runes":rune_slots+strong_slots,"kills":kills,"deaths":deaths,"seed":tower["seed"],"mode":mode,"duration":clock-run_started,"date":Time.get_datetime_string_from_system()}
	meta["records"].push_front(record)
	if meta["records"].size()>30:meta["records"].resize(30)
	# Victory delivers the collected treasure before the flight back to the nest.
	Bag.deposit(meta,Bag.snapshot(run_coins,bag_runes,bag_items,[]));_save_meta();_clear_keys();p_attack.cancel()
	life_event={"kind":"victory","elapsed":0.0,"origin":p["pos"]}
	_toast("六圖通關！光榮返巢，戰利品已寄回，紀錄已保存")


func _update_skills() -> void:
	for s in Data.SKILLS:
		if not meta["skills"].has(s["id"]) and (visited_count>=int(s["rooms"]) or int(meta["attempts"])>=int(s["attempts"])):
			meta["skills"].append(s["id"])
			if ui!=null: _toast("技能解鎖："+s["name"])

func _select_primary(_index: int) -> void:
	if _action_locked():return
	weapon_index=1;p_attack.cancel()
	_toast("主武器："+Data.PRIMARY[weapon_index]["name"])

func _mode_name() -> String: return "無雙夢境" if mode=="musou" else "Roguelike"

func _toast(message: String) -> void:
	if ui!=null:ui.show_message(message)

func _save_meta() -> void:
	if not lab_mode.is_empty() and lab_mode!="tuning":return
	if not preload("res://scripts/meta_store_v35.gd").save_data(SAVE_PATH,meta,meta):
		_toast("儲存失敗，請保留遊戲視窗並稍後重試；未覆寫原有存檔")

func _load_meta() -> void:
	var result:Dictionary=preload("res://scripts/meta_store_v35.gd").load_data(SAVE_PATH,meta)
	var parsed:Dictionary=result["data"]
	for key in meta:if parsed.has(key):meta[key]=parsed[key]
	if bool(result["recovered"]):call_deferred("_toast","存檔異常，已從上一次有效備份恢復倉庫資料")
	elif bool(result["damaged"]):call_deferred("_toast","存檔及備份無法讀取，請保留檔案以便修復")
	for weapon in meta.get("weapons",[]):_unlock_blueprint(str(weapon.get("id","")))

func _sound(id: String) -> void:
	if audio_enabled and sounds.has(id):
		var voice:=AudioStreamPlayer.new();voice.stream=sounds[id];voice.pitch_scale=rng.randf_range(.97,1.03);voice.volume_db=-13;voice.set_meta("combat_voice",true)
		var voices:Array= get_children().filter(func(child:Node)->bool:return child.get_meta("combat_voice",false))
		if voices.size()>=12:voices[0].stop();voices[0].queue_free()
		add_child(voice);voice.finished.connect(voice.queue_free);voice.play()

func _effect(at:Vector2,color:Color,radius:float,life:float) -> void:
	if effects.size()>=MAX_PARTICLES: effects.pop_front()
	effects.append({"pos":at,"color":color,"life":life,"max":life,"radius":radius,"ring":true,"vel":Vector2.ZERO})

func _particles(at:Vector2,color:Color,count:int,speed:float) -> void:
	for i in mini(maxi(2,int(count*.55)) if low_effects else count,maxi(0,MAX_PARTICLES-effects.size())):
		effects.append({"pos":at,"color":color,"life":.25+rng.randf()*.25,"max":.5,"radius":rng.randf_range(2,5),"ring":false,"vel":Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(speed*.2,speed)})

func _float(at:Vector2,message:String,color:Color) -> void:
	if floaters.size()>=MAX_FLOATERS: floaters.pop_front()
	floaters.append({"pos":at,"text":message,"color":color,"life":.8})

func _update_visual_effects(delta:float) -> void:
	if combat_feedback!=null:combat_feedback.step(delta)
	for e in effects:
		e["life"]-=delta;e["pos"]+=e["vel"]*delta
		if not bool(e["ring"]) and not e.has("beam") and not e.has("lightning") and not e.has("boss_fx") and not e.has("combat_fx") and not e.has("ground_wind") and not e.has("wind_burst") and not e.has("water_attack") and not e.has("fire_ember"):e["vel"].y+=180*delta
		if e.has("ground_y") and not e.has("ground_wind") and e["pos"].y>float(e["ground_y"])-float(e["radius"]):e["life"]=0
	effects=effects.filter(func(e:Dictionary)->bool:return float(e["life"])>0)
	for f in floaters:f["life"]-=delta;f["pos"].y-=35*delta
	floaters=floaters.filter(func(f:Dictionary)->bool:return float(f["life"])>0)
	shake=move_toward(shake,0,delta*25)

func _panel(title:String,sections:Array[Dictionary]) -> void:
	equipment_open=false
	_clear_keys();ui.show_panel(title,sections)

func _close_panel() -> void:
	equipment_open=false
	ui.close_panel();capturing_key="";_clear_keys()

func _ui_action(action:String,payload:Variant) -> void:
	if not life_event.is_empty() and life_event.get("kind","")!="await_choice":return
	if life_event.get("kind","")=="await_choice" and action not in ["soul_choose","station_noop"]:_show_soul_choice();return
	match action:
		"menu_category":menu_category=str(payload);_show_settings()
		"equipment_page":_show_equipment(int(payload))
		"craft_weapon":_craft_weapon(str(payload));_show_forge()
		"reforge_add":
			if _is_start() and reforge_selection.size()<3 and StationStock.available(str(payload),bag_runes,meta)>reforge_selection.count(str(payload)):reforge_selection.append(str(payload))
			_show_reforge(false)
		"reforge_remove":
			if int(payload)>=0 and int(payload)<reforge_selection.size():reforge_selection.remove_at(int(payload))
			_show_reforge(false)
		"warehouse_filter":warehouse_filter=str(payload);_show_warehouse()
		"warehouse_take":_warehouse_take(payload)
		"warehouse_store_unused":
			if _is_start():
				var count:int=StationStock.store_unused(bag_runes,meta,rune_slots,strong_slots);_save_meta();_show_warehouse();_toast("已儲存%d枚未使用符文"%count)
		"station_noop":pass
		"reforge_clear":reforge_selection.clear();_show_reforge(false)
		"reforge_confirm":_reforge_runes();_show_reforge(false)
		"lab_tools":_show_practice()
		"lab_enter":_enter_practice()
		"lab_art":_open_rd()
		"lab_tuning":_open_tuning()
		"developer_tools":_show_developer_tools()
		"lab_primary":weapon_index=1;_close_panel();_update_hud()
		"lab_secondary":secondary_index=clampi(int(payload),0,bag_weapons.size()-1);_close_panel();_update_hud()
		"lab_monster":_summon_monster(int(payload));_close_panel()
		"lab_clear":enemies.clear();projectiles.clear();hazards.clear();drops.clear();_close_panel()
		"lab_ai":lab_ai=not lab_ai;_show_practice()
		"lab_runes":_close_panel();_show_runes(false)
		"close":equipment_open=false;capturing_key="";_clear_keys()
		"hub":
			if not lab_mode.is_empty():_leave_lab();return
			_return_trial(false);_close_panel();screen="hub";home_sleeping=true;home_wake_left=0;room={};tower={};enemies=[];drops=[];projectiles=[];hazards=[];run_coins=0;bag_items.clear();bag_runes.clear();bag_weapons.clear();rune_slots.clear();strong_slots.clear();sub_growth.clear();feather={};injured=false;current_room=-1;_reset_player(Vector2(640,600));camera_pos=Vector2.ZERO;room_music.select("hub","branches");atmosphere.configure("branches",0,false);atmosphere.set_audio_enabled(audio_enabled);combat_feedback.clear();_configure_home();_invalidate_scene()
		"start_musou":new_run("musou")
		"start_rogue":new_run("rogue")
		"restart":new_run(mode)
		"bag":_show_equipment(0)
		"runes":_show_equipment(3)
		"prep":_show_prep()
		"skills":_show_skills()
		"map":_show_map()
		"settings":capturing_key="";_show_settings()
		"keybindings":_show_keybindings()
		"rebind":capturing_key=str(payload);_show_keybindings()
		"reset_keys":key_bindings=Bindings.DEFAULTS.duplicate();capturing_key="";_save_settings();_show_keybindings()
		"speed":world_speed=clampf(float(payload),.4,1.5);_save_settings()
		"zoom":
			camera_zoom=clampf(float(payload),.8,2.0);camera_pos=_camera_target(p["pos"]) if screen=="game" else Vector2.ZERO;_save_settings()
		"feedback":
			if OS.has_feature("web"):JavaScriptBridge.eval("window.PigeonFeedback.open()",true)
			else:_toast("請在網頁版本提交意見")
		"shop":_show_shop()
		"help":_show_help()
		"primary":_select_primary(int(payload));_show_prep()
		"sub_select":
			if int(payload)>=0 and int(payload)<bag_weapons.size():_select_secondary(int(payload))
			_update_hud();_show_equipment(1,true)
		"primary_inventory":
			_select_primary(int(payload));_show_equipment(0,true)
		"use_item":_use_item(int(payload),true,false);_show_equipment(2,true)
		"rune_slot":rune_target_slot=clampi(int(payload),0,15);_show_runes(false)
		"rune_equip":_equip_rune(str(payload));_show_runes(false)
		"rune_remove":
			var index:int=int(payload)
			if index>=0 and index<rune_slots.size():rune_slots[index]="";rune_target_slot=index
			_sync_vitals();_show_runes(false)
		"rune_random":_randomize_rune_loadout();_show_runes(false)
		"rune_take":
			if _is_start() and int(meta["runes"].get(str(payload),0))>0:
				if not _rune_has_space(str(payload)):_toast("請先卸下一枚符文，再取用收藏");return
				var id:String=str(payload);bag_runes[id]=int(bag_runes.get(id,0))+1;meta["runes"][id]-=1
				if int(meta["runes"][id])<=0:meta["runes"].erase(id)
				_equip_rune(id);_save_meta();_show_runes(true)
		"strong_remove":
			if int(payload)>=0 and int(payload)<strong_slots.size():strong_slots.remove_at(int(payload))
			_sync_vitals();_show_runes(false)
		"stash_item":
			if _is_start():
				var key:String=str(payload)
				if int(meta.get("items",{}).get(key,0))>0:
					meta["items"][key]-=1;bag_items[key]=int(bag_items.get(key,0))+1
					_use_item(int(key),true,false);_save_meta();_show_bag()
		"stash_weapon":
			if _is_start() and int(payload)>=0 and int(payload)<meta.get("weapons",[]).size():
				bag_weapons.append(Bag.restore_weapon(meta["weapons"][int(payload)]));meta["weapons"].remove_at(int(payload));secondary_index=bag_weapons.size()-1;_save_meta();_update_hud();_show_bag()
		"first_aid":_first_aid();_close_panel()
		"parcel":_send_parcel(str(payload))
		"soul_choose":_choose_soul_rune(str(payload))
		"withdraw_items":
			if _is_start():Bag.merge_counts(bag_items,meta.get("items",{}));meta["items"]={};_save_meta();_show_prep()
		"victory_return":screen="game";_close_panel();_enter_room(int(tower["maps"][0]["start_id"]))
		"stash":_show_runes(true)
		"fusion":_fuse_weapons()
		"buy_skin":_buy_skin(int(payload))
		"touch":touch_enabled=not touch_enabled;ui.set_touch_visible(touch_enabled);_save_settings();_show_settings()
		"hitboxes":show_hitboxes=not show_hitboxes;_invalidate_scene();_show_settings()
		"practice":practice_mode=not practice_mode;_show_settings()
		"audio":audio_enabled=not audio_enabled;_save_settings();_show_settings()
		"mute":audio_enabled=not audio_enabled;_save_settings();_update_hud()
		"effects":low_effects=not low_effects;_show_settings()
		"timing_slower":phase_multiplier=1.6 if phase_multiplier<1.2 else 1.0;_show_settings()
		"reward":_claim_reward(int(payload))
		"minimap":pass
		"hot_item":_use_item(int(payload),true,false)
		"claim_gift":_claim_gift();_show_forge()
		"trial_buy":
			if not merchant_trial.is_empty():_merchant_buy(int(merchant_trial["index"]))
		"merchant_buy":_merchant_buy(int(payload))
		"merchant_inspect":_show_merchant(int(payload))
		"merchant_try":_start_trial(int(payload))
		"merchant_return":_return_trial();_close_panel()
		"records":_show_records()

func _inventory_data() -> Dictionary:
	var home_weapons:Array=[]
	for weapon in meta.get("weapons",[]):home_weapons.append(Bag.restore_weapon(weapon))
	return {"primary":Data.PRIMARY[weapon_index],"primary_index":weapon_index,"primary_defs":Data.PRIMARY,"weapons":bag_weapons,"selected":secondary_index,"items":bag_items,"item_defs":Data.ITEMS,"coins":run_coins,"mode":mode,"upgrades":_growth_summary(),"slots":rune_slots,"bag":bag_runes,"stash":meta["runes"],"defs":Data.all_runes(),"strong_slots":strong_slots,"in_start":_is_start(),"target_slot":rune_target_slot,"stash_items":meta.get("items",{}),"stash_weapons":home_weapons,"cycle_key":Bindings.label(int(key_bindings["cycle"])),"musou_cycle_seconds":_musou_cycle_seconds()}

func _show_bag() -> void:
	if equipment_open:_show_equipment(equipment_page,true);return
	_return_trial(false)
	if screen!="game":_toast("先選擇一扇模式門開始冒險");return
	_clear_keys();ui.show_inventory(_inventory_data())

func _show_runes(_stash:bool) -> void:
	if equipment_open:_show_equipment(3,true);return
	_return_trial(false)
	if screen!="game":_toast("安全屋可取用符文收藏");return
	_clear_keys();ui.show_rune_board(_inventory_data())

func _rune_has_space(id:String) -> bool:
	return strong_slots.size()<3 and not strong_slots.has(id) if Data.is_strong(id) else RuneLinks.occupied(rune_slots)<16

func _auto_equip_rune(id:String) -> bool:
	if not _rune_has_space(id):return false
	# A pickup fills the first empty slot, independently of a cursor left in
	# the inventory. Equipped copies remain counted in the owned bag.
	if not Data.is_strong(id) and rune_slots.count(id)>=int(bag_runes.get(id,0)):return false
	var previous:int=rune_target_slot;rune_target_slot=-1
	_equip_rune(id);rune_target_slot=previous
	return true

func _equip_rune(id:String) -> void:
	if int(bag_runes.get(id,0))<=0:_toast("沒有可用的這種符文");return
	if not _rune_has_space(id):_toast("請先卸下一枚符文，或選擇其他種類");return
	if Data.is_strong(id):
		if strong_slots.size()<3 and not strong_slots.has(id):strong_slots.append(id)
	else:
		if rune_slots.count(id)>=int(bag_runes.get(id,0)):_toast("持有的這種符文都已裝備");return
		var index:int=rune_target_slot if rune_target_slot>=0 and (rune_target_slot>=rune_slots.size() or rune_slots[rune_target_slot].is_empty()) else -1
		if index<0:
			for i in 16:
				if i>=rune_slots.size() or rune_slots[i].is_empty():index=i;break
		if index<0:return
		while rune_slots.size()<=index:rune_slots.append("")
		rune_slots[index]=id;rune_target_slot=-1
	_sync_vitals()

func _rune_name(id:String) -> String:
	for r in Data.all_runes():
		if r["id"]==id:return r["name"]
	return id

func _show_prep(station:String="") -> void:
	if not _is_start():_toast("請回初始安全屋操作");return
	if not station.is_empty():prep_station=station
	match prep_station:
		"mail":_show_warehouse();return
		"reforge":_show_reforge();return
		"forge","rack":_show_forge();return
		"aid":_first_aid();return
	var rows:Array[Dictionary]=[]
	var title:String={"energy_infinite":"能量花","dummy":"試打假人"}.get(prep_station,"安全屋")
	if prep_station=="energy_infinite":rows.append({"text":"關閉選單後攻擊能量花，每次命中回復2格能量，可無限使用。"})
	if prep_station=="dummy":rows.append({"text":"關閉選單後攻擊假人可測試傷害、連段與擊退；假人不會死亡。"})
	_panel(title,rows)

func _fuse_weapons() -> void:
	_show_forge()

func _show_skills() -> void:
	var rows:Array[Dictionary]=[{"text":"低門檻解鎖：探索房間或累積冒險次數，符合任一條件就開放。解鎖永久保留。設定中的練習模式可立刻試用全部動作。"}]
	for s in Data.SKILLS:rows.append({"text":("已解鎖　" if _skill(s["id"]) else "尚未解鎖　")+s["name"]+"\n"+s["desc"]+"　條件：探索 %d 房或冒險 %d 次"%[int(s["rooms"]),int(s["attempts"])]})
	_panel("羽翼技能樹",rows)

func _show_map() -> void:
	if tower.is_empty():_toast("開始冒險後可查看全塔地圖");return
	var rows:Array[Dictionary]=[{"tower_graph":{"tower":tower,"current":current_room}},{"text":"全塔採同一套位置。上 40%%／下 30%%／左右各 15%%，每圖 20%% 機率獎勵房。種子 %d"%int(tower["seed"])}]
	for m in tower["maps"]:
		var start:Dictionary=tower["rooms"][int(m["start_id"])];var boss:Dictionary=tower["rooms"][int(m["boss_id"])];var visited:int=0
		for r in tower["rooms"]:
			if r["map_index"]==m["index"] and bool(r["visited"]):visited+=1
		rows.append({"text":"%s第 %d 圖　探索 %d 房　起點 %s → Boss %s　%s"%["目前 " if int(room.get("map_index",-1))==int(m["index"]) else "",int(m["index"])+1,visited,str(start["coord"]),str(boss["coord"]),"有獎勵房" if int(m["reward_id"])>=0 else "無獎勵房"]})
	rows.append({"text":"右上角小地圖以真實相對位置顯示所有房間。青色為目前房間，金色為獎勵，紅色為 Boss，白色為安全屋，藍色為溫泉房。"})
	_panel("六圖全塔地圖",rows)

func _show_settings() -> void:
	equipment_open=false;_clear_keys()
	MenuView.build(ui,self,menu_category)

func _show_shop() -> void:
	equipment_open=false;_clear_keys()
	preload("res://scripts/cloak_view_v29.gd").build(ui,SKINS,clampi(int(meta.get("skin",0)),0,4))

func _buy_skin(index:int) -> void:
	if index<0 or index>=SKINS.size():return
	meta["skin"]=index
	if not meta["skins"].has(index):meta["skins"].append(index)
	_save_meta();_show_shop()

func _show_help() -> void:
	_panel("從鳥巢開始",[
		{"text":"預設方向鍵移動；空白鍵短按小跳、長按大跳與二段跳。上牆吸附1秒後緩滑，視同落地，按跳躍可離牆。"},
		{"text":"C 單按小噴射，沒有無敵；0.5 秒內雙按化身為風，前搖與攻擊時無敵。↓＋雙 C 下砸全程無敵，落地後保護0.5秒；向上衝刺已移除。"},
		{"text":"X 按下即出刀；繼續按住1.4秒集氣，放開後完整施放1秒，期間可移動及跳躍。左右與上下集氣是獨立技能。"},
		{"text":"Z 施放附武器（－1能量）。Roguelike用Q切換，同武器重複取得投射物+1，最多+8；無雙夢境一次發動最多16把。A長按回血（－3能量）。"},
		{"text":"主武器在打擊期碰到敵人武器可拼刀；揮擊能擋下彈體。普攻即時出招；後搖可移動，或用衝刺與空中下劈取消。空中下劈命中會反彈並重置二段跳與空中衝刺。"},
		{"text":"人物穿過門口即可換房。站點按↑使用；急救站立即補滿。E 開啟裝備，左右切換主武器、附武器、消耗品與符文；R 直達符文。按住Tab＋左右切換區域／全塔圖。"},
		{"text":"六張隨機地圖構成一次冒險；每圖 Boss 旁接下一圖初始房。首次生命歸零會重傷，第二次才死亡；重傷可回安全屋急救。死亡變成羽毛，可帶一枚符文返回安全屋，其餘背包留在羽毛中取回。"},
		{"text":"可在設定調整鏡頭及自訂鍵位。此版為可玩原型：符文效果、技能門檻、合成配方與部分數值為暫用設定，可在原始碼中替換。"}
	])

func _reward_choices() -> Array:
	if not room.has("reward_choices"):
		var random:=RandomNumberGenerator.new();random.seed=int(layout["seed"])+818
		room["reward_choices"]=[{"kind":"rune","value":random.randi_range(0,Data.RUNES.size()-1)}, {"kind":"weapon","value":Arsenal.random_index(random)}, {"kind":"rune","value":Data.RUNES.size()+random.randi_range(0,Data.STRONG_RUNES.size()-1)}, {"kind":"supply","value":0}]
	return room["reward_choices"]
func _reward_position(index:int) -> Vector2:return _furniture_offset()+Vector2(270+index*320,1050)
func _nearest_reward() -> int:
	if room.get("type","")!="reward" or room.get("reward_claimed",false):return -1
	for i in _reward_choices().size():
		if p["pos"].distance_to(_reward_position(i))<90:return i
	return -1
func _show_reward(selected:int=0) -> void:
	var entries:Array[Dictionary]=[]
	for i in _reward_choices().size():
		var item:Dictionary=_reward_choices()[i]
		var def:Dictionary=Data.secondary_attack(int(item["value"])) if item["kind"]=="weapon" else Data.all_runes()[int(item["value"])] if item["kind"]=="rune" else {"name":"旅途補給","description":"回滿生命、能量，並獲得15金幣。"}
		entries.append({"name":def["name"],"description":def["description"],"icon":WorldItems.stock_icon(item) if item["kind"]!="supply" else "items_heal","weapon_id":str(def.get("id","")) if item["kind"]=="weapon" else "","buttons":[{"label":"領取這件贈禮","action":"reward","payload":i}]})
	equipment_open=false;_clear_keys();ChoiceView.build(ui,"枝間贈禮 · 四選一",entries,"reward","先查看大圖與效果，再領取一件贈禮；其餘展示品會封存。",selected)

func _claim_reward(index:int) -> void:
	if room.get("type","")!="reward" or bool(room.get("reward_claimed",false)):return
	if index<0 or index>=_reward_choices().size():return
	room["reward_claimed"]=true;room["reward_selected"]=index
	var item:Dictionary=_reward_choices()[index]
	if item["kind"]=="supply":p["hp"]=p["max_hp"];p["energy"]=p["max_energy"];_drop("coin",p["pos"]-Vector2(0,50),15)
	else:_give_drop(item["kind"],item["value"])
	_save_meta();_close_panel();_toast("已選取此件，其餘贈禮封存")
func _draw_rewards() -> void:
	for i in _reward_choices().size():
		var at:Vector2=_reward_position(i);var item:Dictionary=_reward_choices()[i]
		SanctuaryArt.part(self,"table",Rect2(at+Vector2(0,10)-Vector2(135,90),Vector2(270,90)))
		if room.get("reward_claimed",false):continue
		var icon:String=WorldItems.stock_icon(item) if item["kind"]!="supply" else "items_heal"
		WorldItems.draw_icon(self,icon,Rect2(at-Vector2(30,142),Vector2(60,60)),world_transform)
		draw_set_transform_matrix(world_transform)
		if _nearest_reward()==i:draw_arc(at-Vector2(0,112),38,0,TAU,24,Color("ffe3a1"),2,true);_text(at-Vector2(90,166),"↑／X · 查看贈禮",14,Color("ffe3a1"))

func _update_hud() -> void:
	if ui==null:return
	var phase_name:String=p_attack.phase
	ui.update_hud({"hp":p.get("hp",5),"max_hp":p.get("max_hp",5),"energy":p.get("energy",3),"max_energy":p.get("max_energy",6),"hp_recovery":float(p.get("hp_recovery",0)),"energy_recovery":float(p.get("energy_recovery",0)),"hp_recovering":heal_timer>0 or float(p.get("hp_recovery",0))>0,"energy_recovering":float(p.get("energy_recovery",0))>0 or (float(p.get("energy",1))<1 and empty_energy_time>0),"injured":injured,"coins":int(meta["coins"]) if screen=="hub" else run_coins,"map":int(room.get("map_index",-1))+1,"room":current_room+1,"biome":_biome_name(),"mode":"鳥巢" if screen=="hub" else _mode_name(),"weapon":Data.PRIMARY[weapon_index]["name"],"sub":_secondary()["name"] if not bag_weapons.is_empty() else "尚未裝備","phase":phase_name,"phase_progress":p_attack.progress(),"phase_remaining":maxf(0,float(p_attack.attack.get(p_attack.phase,0))-p_attack.elapsed),"show_attack":screen=="game","dash_key":Bindings.label(int(key_bindings["dash"])),"revive":not revive_used,"audio_enabled":audio_enabled,"sub_icon":UI.Icons.secondary(_secondary()) if not bag_weapons.is_empty() else "","cycle_key":Bindings.label(int(key_bindings["cycle"])),"seed":tower.get("seed",0),"fps":fps_smoothed,"dream_energy":dream.energy,"dream_rage":dream.rage_left,"in_start":_is_start()})
	ui.update_trial(merchant_trial,room.get("stock",[]),run_coins)
	ui.update_quickbar(bag_items,Data.ITEMS)
	ui.quickbar.visible=screen=="game" and not ui.is_panel_open()
	ui.minimap_button.visible=screen=="game" and not ui.is_panel_open()

func _biome_name() -> String:
	if screen=="hub":return "鳥巢與樹"
	return str(_ecology()["name"])

func _paint_background(canvas:CanvasItem) -> void:
	if screen=="hub":backdrop.material=null;HomeArt.background(canvas);return
	if _is_start():
		backdrop.material=preload("res://scripts/depth_style_v32.gd").material(str(_ecology()["id"]),"far",low_effects);preload("res://scripts/scene_art_v33.gd").safehouse(canvas,str(_ecology()["id"]),_room_size(),_room_floor());return
	var id:String=str(_ecology()["id"])
	backdrop.material=preload("res://scripts/depth_style_v32.gd").material(id,"far",low_effects)
	canvas.draw_rect(preload("res://scripts/depth_style_v32.gd").backdrop_rect(),Color("193751") if id=="sky" else (Color("173e31") if id=="trunk" else Color("493521")))
	BiomeArt.layer(canvas,id,"far",preload("res://scripts/depth_style_v32.gd").backdrop_rect())
	if room.get("type","")=="merchant":BiomeArt.layer(canvas,"merchant","far",preload("res://scripts/depth_style_v32.gd").backdrop_rect())

func _paint_terrain(canvas:CanvasItem) -> void:
	if screen=="hub":
		pass # The home branch belongs to the newly painted home background.
		return
	if layout.has("maze_grid"):
		var id:String=str(_ecology()["id"])
		if not NewBiome.draw_terrain(canvas,id,layout,solids,terrain_region):
			for solid:Rect2 in solids:BiomeArt.terrain(canvas,id,solid)
			for plat:Rect2 in layout.get("one_way",[]):BiomeArt.terrain(canvas,id,plat,true)
		if show_hitboxes:
			for solid:Rect2 in solids:canvas.draw_rect(solid,Color(1,.3,.1,.5),false,1)
		return
	if layout.get("single_screen",false):SanctuaryArt.background(canvas,room)
	for plat in platforms:Art.draw_platform(canvas,plat,_height(),show_hitboxes)
	_draw_terrain_details(canvas)


func _draw() -> void:
	if font==null:return
	if screen=="hub":_draw_hub();return
	draw_set_transform_matrix(world_transform)
	for door in doors:_draw_door(door)
	_draw_props()
	if room.get("type","")=="boss" and int(room.get("map_index",0))==5 and bool(room.get("cleared",false)):
		_effect_static(Vector2(740,FLOOR_Y-50),Color("fff0a5"),70)
		_text(Vector2(620,FLOOR_Y-140),"遠行終點 · 按 "+Bindings.label(int(key_bindings["up"])),22,Color("fff0a5"))
	var nearest:float=145.0
	drop_label_target=-1
	for i in drops.size():
		var dist:float=drops[i]["pos"].distance_to(p["pos"]-Vector2(0,20))
		if dist<nearest: nearest=dist;drop_label_target=i
	for i in drops.size():
		if view_rect.has_point(drops[i]["pos"]): _draw_drop(drops[i],i==drop_label_target)
	for en in enemies:
		if float(en["hp"])<=0 or not view_rect.has_point(en["pos"]):continue
		if en.get("training",false):SanctuaryArt.dummy(self,en["pos"],clock,preload("res://scripts/world_placement_v27.gd").prop_base(world_transform));continue
		var atk=en["attack"]

		MonsterDesign.draw_charge(self,en,clock,world_transform)
		_draw_attack(en["pos"],atk,float(en["face"]),false)
		_draw_enemy_warning(en)
		var hpw:float=70 if int(en["model"])==4 else 36
		draw_rect(Rect2(en["pos"]-Vector2(hpw*.5,60 if int(en["model"])!=4 else 100),Vector2(hpw,4)),Color("20383b"))
		draw_rect(Rect2(en["pos"]-Vector2(hpw*.5,60 if int(en["model"])!=4 else 100),Vector2(hpw*maxf(0,float(en["hp"])/float(en["max_hp"])),4)),Color("e9b97d"))
	_draw_player_body()
	if room.get("fountain",false) and layout.has("fountain_pos"):
		preload("res://scripts/spring_v33.gd").draw_water(self,layout["fountain_pos"],str(_ecology()["id"]),world_transform,bath,draw_clock)
	elif room.get("spring",false):
		bath.draw(self,_active_pool(),world_transform,draw_clock)
		SanctuaryArt.pool_front(self,_active_pool(),draw_clock,world_transform)
	if _is_healing():FX.fitted(self,"heal_guard",0,Rect2(p["pos"]-Vector2(35,65),Vector2(70,75)),world_transform,"right","idle",Color(.7,1,.8,.65),clock)
	if float(p["dash_t"])>0 and not _wind_form_active():preload("res://scripts/dash_flap_v39.gd").gust(self,p["pos"],p["dash_dir"],.16-float(p["dash_t"]),world_transform)
	_draw_attack(p["pos"],p_attack,float(p["face"]),true)
	if charge_timer>.15 and show_hitboxes:
		var threshold:float=_charge_threshold()
		draw_arc(p["pos"]-Vector2(0,25),34,0,TAU*minf(1,charge_timer/threshold),32,Color("fff0a5") if charge_timer>=threshold else Color("90dccd"),3,true)
	if float(p["shield"])>0:draw_arc(p["pos"]-Vector2(0,23),36,0,TAU,40,Color("b9c4ff"),2,true)
	for hazard in hazards:
		if hazard.get("fire",false):
			GroundFire.draw(self,hazard,clock,world_transform);continue
		if view_rect.has_point(hazard["pos"]) and not MonsterDesign.draw_hazard(self,hazard,clock,world_transform) and not FX.hazard(self,hazard,clock,world_transform):BossVisual.hazard(self,hazard,clock,world_transform,show_hitboxes)
	for pr in projectiles:
		if not view_rect.grow(160).has_point(pr["pos"]):continue
		ProjectileReadability.draw_trail(self,pr,world_transform);ProjectileReadability.draw_cue(self,pr,world_transform)
		var visual:Dictionary=pr.duplicate(false);visual["radius"]=ProjectileReadability.visual_radius(pr)
		if WeaponArt.Animated.has(str(pr.get("weapon_id",""))) or (pr.get("from_player",false) and WeaponArt.texture(str(pr.get("weapon_id","")),true)!=null):
			WeaponArt.draw(self,str(pr["weapon_id"]),pr["pos"],pr["vel"],float(visual["radius"]),true,world_transform,float(pr.get("elapsed",0)),float(pr.get("launch_angle",0)));draw_set_transform_matrix(world_transform);continue
		if not MonsterDesign.draw_projectile(self,visual,clock,world_transform) and not FX.projectile(self,visual,clock,world_transform) and not BossVisual.projectile(self,visual,clock,world_transform) and not Sprites.projectile(self,visual,clock,world_transform):
			draw_circle(pr["pos"],float(visual["radius"]),pr["color"]);draw_circle(pr["pos"],2,Color.WHITE)
	for e in effects:
		if not view_rect.has_point(e["pos"]):continue
		var c:Color=e["color"];c.a=clampf(float(e["life"])/float(e["max"]),0,1)
		if e.has("beam"):preload("res://scripts/laser_art_v38.gd").draw(self,e,world_transform)
		elif e.has("lightning"):
			var end:Vector2=e["end"]
			var points:=PackedVector2Array([e["pos"]]);var tangent:Vector2=(end-e["pos"]).normalized().orthogonal()
			for i in range(1,8):points.append(Vector2(e["pos"]).lerp(end,float(i)/8)+tangent*sin(i*7.3)*10)
			points.append(end);draw_polyline(points,Color(c,.4),9,true);draw_polyline(points,Color(1,1,1,c.a),2,true)
		elif e.has("explosion_v16"):Explosion.draw(self,e,world_transform)
		elif e.has("ground_wind"):Wind.impact(self,e["pos"],1-c.a,world_transform)
		elif e.has("boss_fx"):BossVisual.impact(self,e,world_transform)
		elif e.has("combat_fx"):
			var extent:float=float(e.get("fx_extent",65))
			FX.fitted(self,e["combat_fx"],1-float(e["life"])/float(e["max"]),Rect2(e["pos"]-Vector2.ONE*extent*.5,Vector2.ONE*extent),world_transform,"right","",Color(1,1,1,c.a))
		elif bool(e["ring"]):draw_arc(e["pos"],float(e["radius"])*(1-c.a*.75),0,TAU,40,c,3,true)
		else:draw_circle(e["pos"],float(e["radius"])*c.a,c)
	for f in floaters:_text(f["pos"],f["text"],16,Color(f["color"],minf(1,float(f["life"])*2)))
	if show_hitboxes:
		draw_rect(_body_box(p["pos"]),Color("9ff5de"),false,1)
		for en in enemies:
			if en["hp"]>0:draw_rect(_enemy_body_box(en),Color("f6aa82"),false,1)
	draw_set_transform(Vector2.ZERO)
	if combat_feedback!=null:combat_feedback.draw_screen(self,world_transform)
	_draw_boss_bar()
	_draw_exit_indicators()
	if float(p["hurt"])>0:draw_rect(Rect2(0,0,1280,720),Color(1,.35,.25,float(p["hurt"])*.35))
	_draw_life_event()


func _draw_boss_bar() -> void:
	for en in enemies:
		if int(en["model"])!=4 or float(en["hp"])<=0:continue
		var color:Color=en["color"]
		draw_rect(Rect2(480,72,420,43),Color("10282c",.88))
		_text(Vector2(492,91),str(en["name"]),17,color)
		_text(Vector2(790,91),["I","II","III"][clampi(int(en.get("boss_phase",1))-1,0,2)],17,color)
		var posture:float=float(en.get("boss_posture",0))/BossDirector.posture_limit(en)
		draw_rect(Rect2(492,111,396,2),Color("40534f"))
		draw_rect(Rect2(492,111,396*posture,2),Color("ffe5ae"))
		draw_rect(Rect2(492,102,396,5),Color("40534f"))
		draw_rect(Rect2(492,102,396*maxf(0,float(en["hp"])/float(en["max_hp"])),5),color)
		for threshold:float in [BossDirector.PHASE_TWO_HP,BossDirector.PHASE_THREE_HP]:
			draw_line(Vector2(492+396*threshold,101),Vector2(492+396*threshold,108),Color("10282c"),2)

func _draw_enemy_warning(en:Dictionary) -> void:
	# Boss tells are combat information, not a developer hitbox option.
	if not show_hitboxes and int(en.get("model",0))!=4:return
	var atk=en["attack"]
	if atk.phase!="windup":return
	var def:Dictionary=atk.attack
	var kind:String=def.get("library_kind","")
	var color:Color=Color(def.get("color",Color.WHITE),.4+.3*atk.progress())
	if kind=="trap":
		var count:int=int(def.get("count",1))
		for i in count:
			var at:Vector2=_trap_position(def.get("target",p["pos"])+Vector2((i-float(count-1)*.5)*float(def["size"])*1.8,0))
			Art._ellipse(self,at,Vector2(float(def["size"]),10),Color(color,.22))
			draw_line(at-Vector2(float(def["size"]),0),at+Vector2(float(def["size"]),0),color,2,false)
	elif kind in ["linear","flying_slash","arc"]:
		var at:Vector2=en["pos"]+Vector2(0,float(def.get("origin_y",-30)))
		var dir:Vector2=def.get("aim",Vector2.RIGHT)
		draw_line(at,at+dir*minf(350,float(def["range"])),Color(color,.28),2,false)

func _draw_player_body() -> void:
	var anim:String="limp" if injured else ("rest" if idle_time>=5 else "idle")
	if absf(p["vel"].x)>30:anim="limp" if injured else "run"
	if not bool(p["grounded"]):anim="jump_up" if p["vel"].y < -70 else ("jump_down" if p["vel"].y>70 else "jump_apex")
	elif float(p.get("landing_left",0))>0 and not injured:anim="land"
	if float(p["dash_t"])>0:anim="dash"
	if int(p["wall"])!=0:anim="wall"
	if charge_timer>.15:anim="charge"
	if _is_healing():anim="heal"
	if p_attack.is_busy():
		if p_attack.phase!="recovery" or (charge_timer<=.15 and (not p["grounded"] or absf(p["vel"].x)<=30)):anim=p_attack.phase
	if float(p.get("heavy_land_left",0))>0:anim="heavy_land"
	if float(p.get("mantle_left",0))>0:anim="mantle"
	if float(p["hurt"])>0 and not _release_locked():anim="hurt"
	var tint:Color=SKINS[clampi(int(meta["skin"]),0,SKINS.size()-1)]["color"]*Color(1.13,1.13,1.13,1)
	if float(p["invul"])>0 and int(clock*20)%2==0:tint.a=.5
	var player_base:Transform2D=world_transform
	var dream_progress:float=dream_visual.body_progress() if mode=="musou" else -1.0
	if float(p.get("landing_left",0))>0 and anim in ["idle","run","limp"]:
		var squash:float=sin(float(p["landing_left"])/.09*PI)*.08
		player_base=world_transform*Transform2D(0,Vector2(1+squash,1-squash),0,p["pos"])*Transform2D(0,-Vector2(p["pos"]))
	if float(p.get("gust_left",0))>0:preload("res://scripts/adventure_art_v29.gd").jump_gust(self,p["pos"],.20-float(p["gust_left"]),world_transform)
	if not _wind_form_active():
		if anim=="mantle":preload("res://scripts/mantle_art_v37.gd").draw(self,p,player_base,tint)
		elif anim=="heavy_land":preload("res://scripts/heavy_landing_v28.gd").draw(self,p["pos"],float(p["face"]),.5-float(p["heavy_land_left"]),player_base,tint)
		elif float(p.get("dash_t",0))>0 and not p_attack.is_busy():preload("res://scripts/double_jump_v27.gd").draw(self,p["pos"],float(p["face"]),(.16-float(p["dash_t"]))*2,player_base,tint)
		elif float(p.get("flap_left",0))>0 and not bool(p["grounded"]) and not p_attack.is_busy() and anim not in ["hurt","heal","wall","dash"]:preload("res://scripts/double_jump_v27.gd").draw(self,p["pos"],float(p["face"]),.32-float(p["flap_left"]),player_base,tint)
		elif dream_progress>=0 and anim not in ["hurt","heal","wall"]:FX.actor(self,"pigeon_feather_charge",dream_progress,p["pos"],player_base,float(p["face"]),1.0,tint,"active")
		elif anim in ["idle","rest"]:IdleArt.draw(self,p["pos"],float(p["face"]),idle_time,player_base,tint)
		else:Art.draw_pigeon(self,p["pos"],float(p["wall"]) if anim=="wall" else float(p["face"]),clock,anim,tint,1.0,(1-float(p["hurt"])/.25) if anim=="hurt" else p_attack.progress(),player_base,str(p_attack.attack.get("style","quick")),p_attack.attack)
	if not _wind_form_active():preload("res://scripts/cloak_art_v29.gd").draw(self,int(meta.get("skin",0)),p["pos"],float(p["wall"]) if anim=="wall" else float(p["face"]),clock,anim not in ["idle","rest","heavy_land"],player_base,anim,tint.a)
	if p_attack.is_busy() and p_attack.attack.get("kind","")=="secondary":WorldItems.secondary(self,p_attack.attack,p["pos"],float(p["face"]),world_transform)

func _draw_hub() -> void:
	HomeArt.gates(self,clock,p["pos"]);HomeArt.nest(self)
	preload("res://scripts/home_visual_v33.gd").prop(self,"records",Vector2(790,600),Vector2(90,105))
	for prop:Dictionary in props:
		if prop["kind"]=="launcher":LaunchArt.draw(self,prop,"trunk",preload("res://scripts/world_placement_v27.gd").prop_base(Transform2D.IDENTITY))
	if home_sleeping or home_wake_left>0:HomeArt.resting(self,clock,home_wake_left if not home_sleeping else -1)
	else:
		_draw_player_body()
		if float(p["dash_t"])>0 and not _wind_form_active():preload("res://scripts/dash_flap_v39.gd").gust(self,p["pos"],p["dash_dir"],.16-float(p["dash_t"]),Transform2D.IDENTITY)
		_draw_attack(p["pos"],p_attack,float(p["face"]),true)
	HomeArt.nest(self,true)
	_text(Vector2(510,100),"枝間鴿行",42,Color("fff2cf"))
	_text(Vector2(484,132),"樹梢之巢 · 冒險的起點",18,Color("d6e8da"))
	_text(Vector2(150,650),"無雙夢境",25,Color("ffe1a6"));_text(Vector2(1000,650),"肉鴿",25,Color("c6ddf7"))
	_text(Vector2(738,465),"冒險紀錄 · ↑",16,Color("ffdc98"))
	_text(Vector2(365,495),"彈跳花 · 砍擊跳更高",14,Color("c0dfae"))
	_text(Vector2(1185,710),"v0.41",13,Color("a6c1b6"))

func _configure_home() -> void:
	camera_pos=Vector2.ZERO;render_camera=Vector2.ZERO;world_transform=Transform2D.IDENTITY
	layout={"size":Vector2(1280,720),"floor_y":600.0,"pool":Rect2(),"spawn_positions":{"center":Vector2(640,600)}}
	platforms.assign([Rect2(40,600,1200,9)])
	solids.assign([Rect2(0,600,1280,120),Rect2(18,0,22,600),Rect2(1240,0,22,600),Rect2(0,-20,1280,20)])
	props.assign([{"kind":"adventure_records","pos":Vector2(790,600),"used":false,"hurt":0.0},{"kind":"launcher","pos":Vector2(455,600),"used":false,"hurt":0.0,"launch_left":0.0,"launch_cooldown":0.0,"launch_hit_cooldown":0.0}])
	p_attack.cancel();pending_attack.clear();charge_timer=0;room_cooldown=0;weapon_index=1
	if home_atmosphere!=null:home_atmosphere.set_active(true)
	if spring_particles!=null:spring_particles.clear()

func _home_interact() -> bool:
	if home_sleeping:_wake_home();return true
	if Vector2(p["pos"]).distance_to(Vector2(790,600))<100:_show_records();return true
	if Vector2(p["pos"]).distance_to(Vector2(200,600))<100:new_run("musou");return true
	if Vector2(p["pos"]).distance_to(Vector2(1080,600))<100:new_run("rogue");return true
	return false

func _update_home(delta:float) -> void:
	var axis:float=float(int(_key("right"))-int(_key("left")))
	if axis!=0 and home_sleeping:_wake_home()
	if home_wake_left>0:home_wake_left=maxf(0,home_wake_left-delta);return
	if home_sleeping:return
	for key in ["invul","hurt","wall_lock","shield","impact_root","flash_left","heavy_land_left"]:p[key]=maxf(0,float(p[key])-delta)
	p["energy"]=p["max_energy"]
	if _key("attack"):charge_timer+=delta
	if not pending_attack.is_empty() and not p_attack.is_busy():_begin_primary(pending_attack);pending_attack.clear()
	p_attack.tick(delta)
	var before:Vector2=p["pos"]
	_update_player(delta*world_speed);_update_idle(delta);_process_player_attack()
	_update_props(delta)
	walker.step_turn(float(p["face"]),delta,bool(p["grounded"]))
	walker.advance(absf(p["pos"].x-before.x),bool(p["grounded"]) and absf(p["vel"].x)>30,"wood",audio_enabled)
	_update_hud()
	if p["pos"].y>530:
		if axis<0 and absf(p["pos"].x-200)<35:new_run("musou")
		elif axis>0 and absf(p["pos"].x-1080)<35:new_run("rogue")

func _wake_home() -> void:
	home_sleeping=false;home_wake_left=.48


func _door_label(door:Dictionary) -> String:
	var target:Dictionary=tower["rooms"][int(door["target"])]
	if int(target["map_index"])>int(room["map_index"]) and not bool(room.get("cleared",false)): return "Boss 未擊敗"
	if int(target["map_index"])!=int(room["map_index"]):return "第 %d 圖"%(int(target["map_index"])+1)
	return {"start":"安全屋","combat":"戰鬥房","reward":"獎勵房","boss":"Boss 房","merchant":"商人房"}[target["type"]]

func _door_locked(door:Dictionary) -> bool:
	var target:Dictionary=tower["rooms"][int(door["target"])]
	return int(target["map_index"])>int(room["map_index"]) and not bool(room.get("cleared",false))

func _draw_door(door:Dictionary) -> void:
	var target:Dictionary=tower["rooms"][int(door["target"])]
	var locked:bool=_door_locked(door)
	var color:Color=Adventure.door_color(target,locked)
	var at:Vector2=door["pos"]
	if not view_rect.grow(180).has_point(at):return
	Adventure.portal(self,at,color,clock,world_transform,str(room["ecology"]["id"]),str(door["dir"]),float(layout.get("tile_size",64))*3 if layout.get("door_width",1)==3 else 64,low_effects)
	if locked:draw_line(at-Vector2(25,52),at+Vector2(25,-19),Color("e1b18b"),5)

func _draw_exit_indicators() -> void:
	pass

func _draw_drop(drop:Dictionary,show_label:bool=false) -> void:
	var kind:String=drop["kind"];var color:Color=Color("e9c776");var label:String="金幣"
	match kind:
		"growth":color=Color("c3cbff");label=Arms.GROWTH_NAMES[Arms.GROWTH[posmod(int(drop["value"]),Arms.GROWTH.size())]]
		"rune":color=Color("ffcf65") if Data.is_strong(Data.all_runes()[int(drop["value"])]["id"]) else Color("c088ff");label=Data.all_runes()[int(drop["value"])]["name"]
		"weapon":color=Data.SECONDARY[int(drop["value"])]["color"];label=Data.SECONDARY[int(drop["value"])]["name"]
		"item":color=Data.ITEMS[int(drop["value"])]["color"];label=Data.ITEMS[int(drop["value"])]["name"]
		"upgrade":color=Color("e9b8ff");label="累加強化"
		"heal":color=Color("9ce4ac");label="補血包"
	var at:Vector2=drop["pos"]
	if kind=="rune":
		preload("res://scripts/adventure_art_v29.gd").rune_halo(self,at,clock,world_transform)
	if drop.get("gift",false):
		for layer in range(4,0,-1):draw_circle(at,layer*11,Color(.7,1,.84,.04*(5-layer)))
		_text(at-Vector2(65,58),"免費副武器 · E／X領取",16,Color("e9ffb2"))
	var icon:String="coin_spin"
	match kind:
		"rune":icon=UI.Icons.rune(str(Data.all_runes()[int(drop["value"])]["id"]))
		"weapon":icon=UI.Icons.secondary(Data.secondary_attack(int(drop["value"])))
		"item":icon="items_"+str(Data.ITEMS[int(drop["value"])]["id"])
		"growth":icon="growth_"+str(Arms.GROWTH[posmod(int(drop["value"]),Arms.GROWTH.size())])
		"heal":icon="items_heal"
		"upgrade":icon="growth_damage"
	var target:=Rect2(at-Vector2.ONE*(8 if kind=="coin" else 22),Vector2.ONE*(16 if kind=="coin" else 44))
	var icon_drawn:bool=WorldItems.draw_icon(self,icon,target,world_transform) if kind in ["weapon","rune","item","heal"] else FX.fitted(self,icon,0,target,world_transform,"right","idle",Color.WHITE,clock)
	if not icon_drawn:
		match kind:
			"coin":
				draw_circle(at,7,color)
				var axis:Vector2=Vector2.from_angle(float(drop.get("rotation",0)))*4
				draw_line(at-axis,at+axis,Color("6e5935"),2)
			"rune":draw_colored_polygon(PackedVector2Array([at+Vector2(0,-10),at+Vector2(8,0),at+Vector2(0,10),at+Vector2(-8,0)]),color)
			"weapon":draw_line(at+Vector2(-7,7),at+Vector2(7,-7),color,5);draw_line(at+Vector2(-6,-2),at+Vector2(2,6),Color("fff3d1"),3)
			"heal":draw_line(at-Vector2(7,0),at+Vector2(7,0),color,5);draw_line(at-Vector2(0,7),at+Vector2(0,7),color,5)
			"item":draw_rect(Rect2(at-Vector2(6,7),Vector2(12,14)),color)
			_:draw_colored_polygon(PackedVector2Array([at+Vector2(-8,7),at+Vector2(0,-9),at+Vector2(8,7)]),color)
	if show_label or drop.get("gift",false):
		if kind=="coin":label="金幣 ×%d"%int(drop["value"])
		var width:float=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+16
		draw_rect(Rect2(at+Vector2(-width*.5,-46),Vector2(width,22)),Color("173c38",.95))
		_text(at+Vector2(-width*.5+8,-30),label,13,color)

func _draw_attack(at:Vector2,atk:Variant,face:float,is_player:bool) -> void:
	if not atk.is_busy():return
	if not is_player and atk.attack.has("melee_visual_id"):
		if bool(atk.attack.get("primary",false)):preload("res://scripts/monster_art_v36.gd").draw_melee(self,at,atk,face,world_transform)
		if show_hitboxes and atk.is_active():draw_rect(_attack_box(at,atk.attack,face),Color("ffe3a0"),false,1)
		return
	if is_player and atk.attack.get("kind","") in ["pierce","slam"]:
		if atk.is_active() or bool(p.get("slam",false)):Wind.wind_form(self,at-Vector2(0,22),atk.attack["dir"],atk.elapsed,float(atk.attack["active"]),world_transform,atk.attack["kind"]=="slam")
		return
	if is_player and atk.attack.get("primary",false) and (not atk.attack.get("charged",false) or atk.attack.get("great_spin_release",false)):
		if show_hitboxes and atk.is_active():draw_rect(_attack_box(at,atk.attack,face),Color("ffe3a0"),false,1)
		return
	if is_player and atk.attack.has("fx_clip"):
		var primary:Dictionary=atk.attack
		var hitbox:Rect2=_attack_box(at,primary,face)
		if FX.fitted(self,str(primary["fx_clip"]),atk.progress(),hitbox,world_transform,str(primary.get("direction","right")),atk.phase,Color.WHITE,atk.elapsed if atk.phase=="active" else -1):
			if show_hitboxes and atk.is_active():draw_rect(hitbox,Color("ffe3a0"),false,1)
			return
	var def:Dictionary=atk.attack
	var rect:Rect2=_attack_box(at,def,face)
	var color:Color=def.get("color",Color("f4b175"))
	if atk.phase=="windup":
		if show_hitboxes:draw_arc(at-Vector2(0,22),30,0,TAU*atk.progress(),22,Color(color,.7),2,true)
		if not is_player and show_hitboxes:draw_rect(rect,Color(color,.12));draw_rect(rect,Color(color,.55),false,1)
	elif atk.phase=="active":
		if def.get("kind","") in ["pierce","slam"]:
			var dir:Vector2=def.get("dir",Vector2(face,0))
			draw_line(at-Vector2(0,20)-dir*48,at-Vector2(0,20)+dir*48,Color(color,.4),22,true)
			draw_line(at-Vector2(0,20)-dir*48,at-Vector2(0,20)+dir*48,Color("fff6d7"),5,true)
		elif bool(def.get("primary",false)) or def.get("weapon_kind","")=="sword":
			var center:Vector2=at+Vector2(0,float(def.get("origin_y",-26)))
			var dir:Vector2=Vector2.UP if def.get("direction","")=="up" else (Vector2.DOWN if def.get("direction","")=="down" else Vector2(face,0))
			var length:float=float(def.get("range",60));var angle:float=dir.angle()
			if def.get("shape","")=="thrust":
				draw_line(center,center+dir*length,Color(color,.35),14,true);draw_line(center,center+dir*length,Color("fff7df"),3,true)
			elif def.get("shape","")=="twin_arc":
				draw_arc(center,length*.9,angle-1.2,angle+.8,24,Color(color,.35),16,true)
				draw_arc(center+dir*15,length*.58,angle-.8,angle+1.2,24,color,8,true)
				draw_arc(center,length*.9,angle-1.2,angle+.8,24,Color("fff8e5"),3,true)
			elif def.get("shape","")=="cleave":
				var poly:PackedVector2Array=PackedVector2Array([center])
				for i in 17:poly.append(center+Vector2.from_angle(angle-1.2+float(i)/16*2.4)*length)
				draw_colored_polygon(poly,Color(color,.22))
				draw_arc(center,length,angle-1.2,angle+1.2,32,color,12,true)
				draw_arc(center,length,angle-1.1,angle+1.1,32,Color("fff4cf"),3,true)
			else:
				draw_arc(center,length*.8,angle-1.0,angle+1.0,24,Color(color,.25),18,true)
				draw_arc(center,length*.8,angle-1.0,angle+1.0,24,color,7,true)
				draw_arc(center,length*.81,angle-.85,angle+.85,24,Color("fff8e5"),2,true)
			if show_hitboxes:draw_rect(rect,color,false,1)
	else:
		if show_hitboxes:draw_arc(at-Vector2(0,23),25,0,TAU*(1-atk.progress()),16,Color(color,.35),1,true)

func _paint_minimap(canvas:CanvasItem) -> void:
	if tower.is_empty() or not minimap_open:return
	canvas.draw_rect(Rect2(0,0,1280,720),Color(0,.025,.045,.75))
	canvas.draw_rect(Rect2(150,65,980,590),Color("0e2432",.98))
	var heading:String="練習房" if tower.get("maps",[]).is_empty() else ("全塔路線 · 六關連通" if minimap_full_tower else "第 %d 關 · %s"%[int(room.get("map_index",0))+1,tower["maps"][room.get("map_index",0)]["stage_name"]])
	_text_on(canvas,Vector2(178,103),heading,22,Color("eef5e6"))
	_text_on(canvas,Vector2(178,128),"按住 Tab ＋ ←／→ 切換章節／全塔 · 放開 Tab 返回",15,Color("b7d0d2"))
	if minimap_full_tower:TowerMap.draw_full_tower(canvas,tower,current_room,Rect2(180,155,915,422),font)
	else:
		TowerMap.draw_chapter(canvas,tower,current_room,Rect2(180,155,700,422),font)
		TowerMap.draw_stage_list(canvas,tower,current_room,Rect2(904,169,195,400),font)
	_text_on(canvas,Vector2(180,616),"安 安全屋　王 首領　商 商人　寶 獎勵　泉 泉水　· 戰鬥",16,Color("dceade"))

func _effect_static(at:Vector2,color:Color,radius:float) -> void:
	draw_line(at,at-Vector2(0,100),Color(color,.12),36,true)
	draw_circle(at,20,color);draw_arc(at,radius+sin(clock*2)*4,0,TAU,40,Color(color,.6),2,true)

func _text(at:Vector2,message:String,size:int,color:Color) -> void:
	draw_string(font,at,message,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _text_on(canvas:CanvasItem,at:Vector2,message:String,size:int,color:Color) -> void:
	canvas.draw_string(font,at,message,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

# v0.5 expedition, props and lifecycle orchestration.
func _in_aggro(en:Dictionary) -> bool:
	if int(en.get("model",0))==4 and en.get("combat_engaged",false):return true
	var visible:Rect2=Rect2(camera_pos,Vector2(1280,720)/_view_zoom()).grow(-24)
	var seen:bool=visible.has_point(_enemy_body_box(en).get_center())
	if seen and int(en.get("model",0))==4:en["combat_engaged"]=true
	return seen

func _attack_direction(def:Dictionary) -> Vector2:
	return {"up":Vector2.UP,"down":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}.get(str(def.get("direction","")),Vector2(float(p["face"]),0))

func _recoil(distance:float,source:Vector2,direction:Vector2=Vector2.ZERO) -> void:
	var away:float=signf(p["pos"].x-source.x)
	if away==0:away=-float(p["face"])
	p["recoil_left"]=.18;p["recoil_base_y"]=p["vel"].y
	p["recoil_velocity"]=(direction.normalized() if direction.length_squared()>.01 else Vector2(away,0))*distance/.18

func _contact_fx(clip:String,at:Vector2) -> void:
	if effects.size()>=MAX_PARTICLES:effects.pop_front()
	effects.append({"pos":at,"color":Color.WHITE,"life":.3,"max":.3,"ring":false,"radius":0.0,"vel":Vector2.ZERO,"combat_fx":clip})

func _hit_flash(at:Vector2,damage:float,color:Color) -> void:
	if effects.size()>=MAX_PARTICLES:effects.pop_front()
	effects.append({"pos":at,"color":Color.WHITE,"life":.25,"max":.25,"ring":false,"radius":0.0,"vel":Vector2.ZERO,"combat_fx":"hit_light" if damage<=2 else ("hit_medium" if damage<5 else "hit_heavy")})

func _restore_vital(kind:String,amount:float) -> void:
	if amount<=0:return
	var cap:int=int(p["max_"+kind]);var current:int=int(p[kind]);var key:String=kind+"_recovery"
	if current>=cap:p[kind]=cap;p[key]=0.0;return
	var progress:float=float(p.get(key,0))+amount
	var units:int=int(floor(progress+0.00001));p[kind]=mini(cap,current+units)
	p[key]=0.0 if int(p[kind])>=cap else maxf(0,progress-units)

func _station_event(kind:String,event:String) -> void:
	for prop in props:
		if prop["kind"]==kind:prop["event"]=event;prop["event_left"]=.8

func _sync_vitals() -> void:
	var old_max:float=float(p.get("max_hp",5))
	p["max_hp"]=5+int(_rune_effect("max_hp"))-(2 if injured else 0)
	p["max_energy"]=6-(2 if injured else 0)
	p["hp"]=int(clampf(float(p["hp"])+maxf(0,float(p["max_hp"])-old_max),0,float(p["max_hp"])))
	p["energy"]=int(clampf(float(p["energy"]),0,float(p["max_energy"])))

func _healing_guard() -> bool:
	return _rune_effect("heal_guard")>0 and _key("heal") and float(p["energy"])>=3 and float(p["hp"])<float(p["max_hp"]) and not p_attack.is_busy()

func _update_dream(delta:float) -> void:
	if mode!="musou":return
	dream.step(delta);dream_visual.step(delta*world_speed)
	if dream.pending>0:
		dream.pending-=1;_release_dream_slash()
	for wave:Dictionary in dream_visual.waves:
		if wave["injury"]:continue
		wave["pos"]=p["pos"]-Vector2(0,24)
		var radius:float=float(wave["radius"])*(.15+.85*clampf(float(wave["age"])/float(wave["duration"]),0,1))
		for en:Dictionary in enemies:
			if en["hp"]<=0 or wave["hits"].has(en["uid"]):continue
			var box:Rect2=_enemy_body_box(en)
			if box.get_center().distance_to(wave["pos"])>radius+box.size.x*.5:continue
			wave["hits"][en["uid"]]=true
			_hit_enemy(en,float(wave["damage"]),Color("c9dcff"),120,wave["pos"],box.get_center()-Vector2(wave["pos"]),false)
		_damage_traps(Rect2(Vector2(wave["pos"])-Vector2.ONE*radius,Vector2.ONE*radius*2),float(wave["damage"]),false)

func _release_dream_slash() -> void:
	var at:Vector2=p["pos"]-Vector2(0,24)
	var damage:float=_normal_damage()
	dream_visual.pulse(at,180/_view_zoom(),false,damage*2)
	var definition:Dictionary={"id":"moonblade","weapon_kind":"flying_slash","damage":damage,"count":8,"spread":TAU/8,"speed":560.0,"range":640/_view_zoom(),"size":16.0,"piercing":true,"knockback":100.0,"color":Color("c9dcff"),"dream_slash":true}
	_emit_weapon(at,Vector2.from_angle(PI/8),definition,true)
	shake=maxf(shake,7);_update_hud()

func _update_passives(delta:float) -> void:
	passive_energy+=delta*_rune_effect("energy_regen")
	while passive_energy>=1:passive_energy-=1;_restore_vital("energy",1)
	blood_timer-=delta
	if injured and blood_timer<=0 and p["pos"].distance_to(last_motion_pos)>1:
		blood_timer=.18;_particles(p["pos"]-Vector2(0,6),Color("b04b51"),2,12)
	if float(p["energy"])<1:
		empty_energy_time+=delta
		if empty_energy_time>=5:_restore_vital("energy",1);empty_energy_time=0;_float(p["pos"]-Vector2(0,60),"能量 +1",Color("9edfe5"))
	else:empty_energy_time=0
	var distance:float=p["pos"].distance_to(last_motion_pos);last_motion_pos=p["pos"]
	if _rune_effect("motion_energy")>0 and distance<80:
		move_energy_distance+=distance
		while move_energy_distance>=220:move_energy_distance-=220;_restore_vital("energy",1);_contact_fx("motion_energy",p["pos"]-Vector2(0,24))
	bee_timer-=delta
	if _rune_effect("orbit_bee")>0 and bee_timer<=0:
		bee_timer=1.0
		var candidates:Array=enemies.filter(func(enemy:Dictionary)->bool:return enemy["hp"]>0 and _in_aggro(enemy) and enemy["pos"].distance_to(p["pos"])<450)
		for bee in int(_rune_effect("orbit_bee")):
			if candidates.is_empty():break
			var target:Dictionary=candidates[bee%candidates.size()]
			var at:Vector2=_bee_position(bee)
			_emit_weapon(at,_enemy_body_box(target).get_center()-at,Combat.attack("linear",{"damage":3,"speed":400,"range":450,"size":6,"knockback":45,"color":Color("ffe49c")}),true)
			if not projectiles.is_empty():projectiles[-1]["bee"]=true

func _bee_position(index:int) -> Vector2:
	return p["pos"]-Vector2(0,35)+Vector2.from_angle(draw_clock*3+TAU*index/maxf(1,_rune_effect("orbit_bee")))*(50+int(index/8)*10)

func _check_portals() -> void:
	if _release_locked():return
	if room_cooldown>0 or not life_event.is_empty():return
	var at:Vector2=p["pos"]
	var opening:float=float(layout.get("tile_size",64))*3 if layout.get("door_width",1)==3 else 96
	for door in doors:
		var direction:String=door["dir"];var anchor:Vector2=door["pos"]
		var crossed:bool=false
		match direction:
			"left":crossed=at.x<25 and at.y>anchor.y-opening+36 and at.y<anchor.y+24
			"right":crossed=at.x>_room_size().x-25 and at.y>anchor.y-opening+36 and at.y<anchor.y+24
			"up":crossed=at.y<48 and absf(at.x-anchor.x)<opening*.5-17
			"down":crossed=at.y>_room_size().y-42 and absf(at.x-anchor.x)<opening*.5-17
		if not crossed:continue
		if _door_locked(door):
			var inward:Vector2={"left":Vector2.RIGHT,"right":Vector2.LEFT,"up":Vector2.DOWN,"down":Vector2.UP}[direction]
			p["pos"]=at+inward*55;p["vel"]=Vector2.ZERO;return
		var velocity:Vector2=p["vel"]
		_enter_room(int(door["target"]),direction)
		p["vel"]=velocity;p["grounded"]=false
		return

func _make_props() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if room["type"]=="start":
		if int(room.get("map_index",0))==0:result.append({"kind":"gift_pedestal","pos":_furniture_offset()+Vector2(620,1050),"used":false,"hurt":0.0})
		result.append({"kind":"wardrobe","pos":_furniture_offset()+Vector2(360,850),"used":false,"hurt":0.0})
		for entry in [["aid",540],["forge",720],["reforge",900],["mail",1080],["energy_infinite",1260]]:result.append({"kind":entry[0],"pos":_furniture_offset()+Vector2(entry[1],850),"used":false,"hurt":0.0})
	elif room["type"]=="merchant":
		result.append({"kind":"merchant","pos":_furniture_offset()+Vector2(160,1050),"used":false,"hurt":0.0})
	elif room.get("spring",false):result.append({"kind":"spring","pos":_furniture_offset()+Vector2(690,1050),"used":false,"hurt":0.0})
	elif room["type"]=="reward":
		_reward_choices()
		for i in 3:result.append({"kind":"coin_urn","variant":3,"pos":_furniture_offset()+Vector2(430+i*320,1050),"used":false,"hurt":0.0,"coins":10+i*10})
	elif room["type"] in ["combat","elite"]:
		var prop_rng:=RandomNumberGenerator.new();prop_rng.seed=int(layout["seed"])+440
		if not layout["enemy_spawns"].is_empty():
			if prop_rng.randf()<.24:result.append({"kind":"chest","pos":layout["enemy_spawns"][prop_rng.randi_range(0,layout["enemy_spawns"].size()-1)],"used":false,"hurt":0.0})
			if prop_rng.randf()<.4:result.append({"kind":"energy","pos":layout["enemy_spawns"][prop_rng.randi_range(0,layout["enemy_spawns"].size()-1)],"used":false,"hurt":0.0})
			if prop_rng.randf()<.01:result.append({"kind":"health","pos":layout["enemy_spawns"][prop_rng.randi_range(0,layout["enemy_spawns"].size()-1)],"used":false,"hurt":0.0})
	if room.get("fountain",false) and layout.has("fountain_pos"):result.append({"kind":"fountain","pos":layout["fountain_pos"],"used":false,"hurt":0.0,"water_cd":0.0})
	if room["type"] in ["combat","elite"] and not room.get("spring",false):
		for reward:Dictionary in layout.get("dead_end_rewards",[]):
			var cell:Vector2i=reward["cell"];var at:=Vector2((cell.x+.5)*96,(cell.y+1)*96)
			result.append({"kind":"chest","pos":at,"used":false,"hurt":0.0,"dead_end_length":reward["length"]})
		for at:Vector2 in layout.get("launcher_spawns",[]):
			if result.any(func(prop:Dictionary)->bool:return Vector2(prop["pos"]).distance_to(at)<120):continue
			result.append({"kind":"launcher","pos":at,"used":false,"hurt":0.0,"launch_left":0.0,"launch_cooldown":0.0})
	var object_rng:=RandomNumberGenerator.new();object_rng.seed=int(layout["seed"])+981
	var eligible:Array[Vector2]=[]
	for at:Vector2 in layout.get("ground_spawns",layout.get("enemy_spawns",[])):
		var clearance:=Rect2(at-Vector2(40,90),Vector2(80,89.9))
		if solids.any(func(rect:Rect2)->bool:return rect.intersects(clearance)):continue
		if doors.any(func(door:Dictionary)->bool:return at.distance_to(door["pos"])<170):continue
		if result.any(func(prop:Dictionary)->bool:return Vector2(prop["pos"]).distance_to(at)<110):continue
		if eligible.any(func(other:Vector2)->bool:return other.distance_to(at)<110):continue
		eligible.append(at)
	# Bounded to18objects per room; shuffle positions using the room seed.
	for i in mini(18,eligible.size()):
		var at:Vector2=eligible.pop_at(object_rng.randi_range(0,eligible.size()-1))
		result.append({"kind":"ecology_object","variant":i%6,"art_set":"v15" if (i/6)%2==1 else "v21","object_id":BiomeArt.object_id(str(_ecology()["id"]),i%6),"pos":at,"used":false,"hurt":0.0,"hp":1.0})
	return result

func _update_props(delta:float) -> void:
	for prop in props:
		prop["hurt"]=maxf(0,float(prop["hurt"])-delta)
		for timer in ["break_left","event_left","launch_left","launch_cooldown","launch_hit_cooldown"]:prop[timer]=maxf(0,float(prop.get(timer,0))-delta)
		if prop["kind"]=="launcher":
			var body:Rect2=LaunchArt.body_box(prop,str(_ecology()["id"]))
			var proximity:float=body.position.y-Vector2(p["pos"]).y
			prop["compression"]=2 if proximity<35 else 1
			if proximity<0 or proximity>100 or absf(p["pos"].x-body.get_center().x)>60 or p["vel"].y<=0:prop["compression"]=0
			if float(prop.get("launch_cooldown",0))<=0 and _body_box(p["pos"]).intersects(body):_launch_from_object(prop,false)
		prop["water_cd"]=maxf(0,float(prop.get("water_cd",0))-delta)
		if prop["kind"] in ["spring","fountain"] and _in_bath():
			_restore_vital("hp",delta)
			_restore_vital("energy",delta*2)

func _hit_props(box:Rect2,damage:float,attack_id:int=-1) -> void:
	for i in props.size():
		var prop:Dictionary=props[i]
		if prop.get("used",false) or prop["kind"] not in ["fountain","dummy","shop_dummy","energy_infinite","energy","health","grass","ecology_object","coin_urn","launcher"]:continue
		if prop["kind"]=="fountain":
			if box.intersects(preload("res://scripts/spring_v33.gd").body(prop["pos"])) and float(prop.get("water_cd",0))<=0:
				prop["water_cd"]=.12;spring_particles.splash(preload("res://scripts/spring_v33.gd").water_at(prop["pos"],str(_ecology()["id"])),str(_ecology()["id"]),_aim_vector())
			continue
		if prop["kind"]=="launcher":
			if attack_id>=0:continue # Remote projectiles do not teleport recoil to the player.
			if box.intersects(LaunchArt.body_box(prop,str(_ecology()["id"]))) and float(prop.get("launch_hit_cooldown",0))<=0:
				if attack_id<0 and not p_attack.mark_hit(-10000-i):continue
				_launch_from_object(prop,true)
			continue
		var prop_size:Vector2=BiomeArt.object_size(prop.get("variant",0)) if prop["kind"]=="ecology_object" else Vector2(84,120) if prop["kind"]=="shop_dummy" else Vector2(46,60)
		if not box.intersects(Rect2(prop["pos"]-Vector2(prop_size.x*.5,prop_size.y),prop_size)):continue
		if attack_id<0 and not (p_attack.mark_timed_hit(-10000-i,.5,3) if p_attack.attack.get("charged",false) else p_attack.mark_hit(-10000-i)):continue
		if prop["kind"]=="coin_urn":
			prop["used"]=true;prop["break_left"]=.6;static_props.invalidate();_drop("coin",prop["pos"]-Vector2(0,32),int(prop["coins"]));_hit_flash(prop["pos"]-Vector2(0,30),damage,Color("ffdf94"));continue
		if prop["kind"] in ["grass","ecology_object"]:
			prop["used"]=true;static_props.invalidate();prop["hp"]=0;prop["break_left"]=BiomeArt.CUT_DURATION if prop["kind"]=="ecology_object" else .45
			combat_feedback.grass_hit(prop["pos"]-Vector2(0,18),Vector2(float(p["face"]),0),str(p_attack.attack.get("style","quick")))
			_particles(prop["pos"]-Vector2(0,15),Color("a9c6a0"),7,80);continue
		prop["hurt"]=.3
		if prop["kind"] in ["dummy","shop_dummy"]:combat_feedback.hit({},prop["pos"]-Vector2(0,35),_aim_vector(),str(p_attack.attack.get("style","quick")),false)
		else:_hit_flash(prop["pos"]-Vector2(0,35),damage,Color("aee8dc"))
		if prop["kind"]=="health":p["hp"]=p["max_hp"];prop["used"]=true;prop["break_left"]=.5;p["hp_recovery"]=0.0;_toast("生命已回滿")
		elif prop["kind"] in ["energy","energy_infinite"]:_restore_vital("energy",2);prop["used"]=prop["kind"]=="energy";prop["break_left"]=.5 if prop["used"] else 0
		else:
			_restore_vital("energy",1)
			_float(prop["pos"]-Vector2(0,80),"%.0f"%damage,Color.WHITE)
			pass # Training props never apply recoil to the player.
	if not feather.is_empty() and int(feather["room"])==current_room and box.intersects(Rect2(feather["pos"]-Vector2(80,132),Vector2(160,132))):_recover_feather()

func _random_rune_index() -> int:
	return Data.RUNES.size()+rng.randi_range(0,Data.STRONG_RUNES.size()-1) if rng.randf()<.15 else rng.randi_range(0,Data.RUNES.size()-1)

func _grow_secondary(index:int=-1) -> void:
	var id:String=Arms.GROWTH[rng.randi_range(0,Arms.GROWTH.size()-1) if index<0 else posmod(index,Arms.GROWTH.size())]
	Arms.grow(sub_growth,id);upgrades["count"]+=1;_toast(Arms.GROWTH_NAMES[id])

func _growth_summary() -> String:
	var labels:Array[String]=[]
	for id in sub_growth:labels.append(str(Arms.GROWTH_NAMES[id])+" ×%d"%int(sub_growth[id]))
	return "尚未取得副武器成長" if labels.is_empty() else "\n".join(labels)

func _send_parcel(category:String) -> void:
	if not _is_start():return
	var payload:Dictionary=Bag.snapshot(run_coins if category in ["all","coins"] else 0,bag_runes if category in ["all","runes"] else {},bag_items if category in ["all","items"] else {},bag_weapons if category in ["all","weapons"] else [])
	Bag.deposit(meta,payload)
	if category in ["all","coins"]:run_coins=0
	if category in ["all","runes"]:bag_runes.clear();rune_slots.clear();strong_slots.clear();_sync_vitals()
	if category in ["all","items"]:bag_items.clear()
	if category in ["all","weapons"]:bag_weapons.clear();secondary_index=0
	_save_meta();_station_event("mail","send");_show_prep("mail");_toast("物品已存入倉庫，內容已永久保存")

func _update_life_event(delta:float) -> void:
	var kind:String=life_event.get("kind","")
	if kind=="await_choice":return
	life_event["elapsed"]+=delta
	var elapsed:float=life_event["elapsed"]
	if kind=="victory":
		p["pos"]=Vector2(life_event["origin"])+Vector2(sin(elapsed*2)*55,-elapsed*210);_feather_burst(p["pos"],1)
		camera_pos=camera_pos.lerp(_camera_target(p["pos"]),minf(1,delta*5))
		if elapsed>=2.4:life_event={};_ui_action("hub",null);_show_records()
		return
	if kind=="soul":
		p["pos"]=Vector2(life_event["origin"]).lerp(Vector2(740,120),clampf(elapsed/1.4,0,1))
		if elapsed>=1.4:_respawn_from_soul()
		return
	_update_enemies(delta*.08,delta*.08*world_speed)
	if not life_event.get("landed",false):
		var old:Vector2=p["pos"]
		life_event["velocity"].y+=GRAVITY*delta
		var resolved:Dictionary=Coll.move_body(old,life_event["velocity"],delta,Vector2(34,42),solids)
		var position:Vector2=resolved["pos"];var velocity:Vector2=resolved["vel"]
		var ground:float=_support_y(old,position,velocity.y,17)
		if ground<INF:position.y=ground;resolved["grounded"]=true
		position.x=clampf(position.x,18,_room_size().x-18)
		if position.y>_room_size().y+96:position=layout["spawn_positions"]["center"];resolved["grounded"]=true
		p["pos"]=position;life_event["velocity"]=velocity
		if resolved["grounded"] and velocity.y>=0:
			life_event["landed"]=true;life_event["land_time"]=elapsed;life_event["velocity"]=Vector2.ZERO
			if kind=="death" and not feather.is_empty():feather["pos"]=position
	else:
		var down_time:float=elapsed-float(life_event["land_time"])
		if down_time>=(1.0 if kind=="injury" else 1.1):
			if kind=="injury":
				injured=true;revive_used=true;life_event={};_sync_vitals();p["hp"]=p["max_hp"];p["invul"]=2;p["vel"]=Vector2.ZERO;_toast("重傷：移動−20%，請回安全屋急救")
			else:
				life_event["kind"]="await_choice";_show_soul_choice()
			return
	var trail:Array=life_event["trail"]
	if trail.is_empty() or p["pos"].distance_to(trail.back())>12:trail.append(p["pos"])
	if trail.size()>22:trail.pop_front()
	camera_pos=camera_pos.lerp(_camera_target(p["pos"]),minf(1,delta*5))


func _show_soul_choice() -> void:
	var entries:Array[Dictionary]=[]
	for def:Dictionary in Data.all_runes():
		var id:String=def["id"]
		if int(bag_runes.get(id,0))>0:entries.append({"name":def["name"],"description":def["description"],"icon":UI.Icons.rune(id),"caption":"×%d"%int(bag_runes[id]),"buttons":[{"label":"攜帶這枚返回","action":"soul_choose","payload":id}]})
	entries.append({"name":"空手返回","description":"不攜帶符文。所有物品留在發光羽毛，返回後仍可攻擊羽毛取回。","icon":"","buttons":[{"label":"不攜帶符文返回","action":"soul_choose","payload":""}]})
	equipment_open=false;_clear_keys();ChoiceView.build(ui,"死亡 · 帶一枚符文返程",entries,"death","選一枚隨身符文隨靈魂返回，其餘物品留在發光羽毛。再次死亡將失去前一次未取回的掉包。")

func _choose_soul_rune(id:String) -> void:
	if life_event.get("kind","")!="await_choice" or feather.is_empty():return
	var kept:bool=not id.is_empty() and Bag.remove_one(feather["payload"],id)
	bag_runes.clear();bag_items.clear();bag_weapons.clear();rune_slots.clear();strong_slots.clear();sub_growth.clear();run_coins=0
	if kept:bag_runes[id]=1;_auto_equip_rune(id)
	life_event={"kind":"soul","elapsed":0.0,"origin":p["pos"],"kept":id if kept else ""}
	ui.close_panel();_clear_keys()

func _respawn_from_soul() -> void:
	dream.clear();dream_visual.clear_waves()
	life_event={};injured=false;revive_used=false;spawn_serial+=1;secondary_index=0
	if not room.is_empty():room["enemies"]=enemies;room["drops"]=drops;room["corpses"]=corpses
	for candidate in tower["rooms"]:
		if candidate["type"] in ["combat","elite"] or (candidate["type"]=="boss" and not candidate.get("cleared",false)):
			candidate["initialized"]=false;candidate["enemies"]=[];candidate["drops"]=[];candidate["corpses"]=[]
	# Room entry saves the outgoing arrays. Detach them before entering so the
	# old enemies cannot overwrite the freshly reset room state.
	room={};enemies=[];drops=[];corpses=[];projectiles.clear();hazards.clear();effects.clear();hitstop=0
	combat_feedback.clear()
	_reset_player(Vector2(230,FLOOR_Y));_sync_vitals();p["hp"]=p["max_hp"];p["energy"]=3
	_enter_room(last_checkpoint if last_checkpoint>=0 else int(tower["maps"][0]["start_id"]));p["invul"]=2
	_toast("靈魂已返回最近安全屋。小怪重生；找回發光羽毛可取回背包")

func _recover_feather() -> void:
	if feather.is_empty() or int(feather["room"])!=current_room:return
	var payload:Dictionary=feather["payload"]
	run_coins+=int(payload["coins"]);Bag.merge_counts(bag_runes,payload["runes"]);Bag.merge_counts(bag_items,payload["items"])
	var remaining:Array=[]
	for stored:Dictionary in payload["weapons"]:
		var match_index:int=-1
		if mode=="rogue":
			for i in bag_weapons.size():
				if bag_weapons[i].get("id","")==stored.get("id",""):match_index=i;break
		if match_index>=0:
			bag_weapons[match_index]["duplicate_bonus"]=mini(8,int(bag_weapons[match_index].get("duplicate_bonus",0))+int(stored.get("duplicate_bonus",0))+1)
		elif mode!="musou" or bag_weapons.size()<16:bag_weapons.append(stored.duplicate(true))
		else:remaining.append(stored.duplicate(true))
	Bag.merge_counts(sub_growth,payload.get("growth",{}));p["energy"]=p["max_energy"]
	if remaining.is_empty():feather={}
	else:feather["payload"]={"coins":0,"runes":{},"items":{},"weapons":remaining,"growth":{}}
	_toast("背包已取回，能量回滿；請存入倉庫以永久保存" if remaining.is_empty() else "背包武器已滿，其餘武器仍留在羽毛")

func _block_box() -> Rect2:
	var def:Dictionary=p_attack.attack.duplicate()
	def["width"]=float(def.get("block_width",def.get("width",48)))
	return _attack_box(p["pos"],def,float(p["face"]))

func _projectile_explosion(pr:Dictionary) -> void:
	if pr.get("ground_fire",false) and not pr.get("fire_created",false):
		pr["fire_created"]=true
		var at:Vector2=_trap_surface(pr)
		var fire:Dictionary={"pos":at,"from_player":true,"elapsed":0.0,"arming_time":0.0,"lifetime":4.0,"damage":pr["damage"],"size":float(pr.get("fire_size",100)),"fire":true,"hp":1.0,"hits":{},"next_hit":{},"max_hits":8,"hit_interval":.5,"color":pr["color"]}
		if hazards.size()<40:hazards.append(fire)
	if pr.get("explode_on_hit",false):_explode(pr["pos"],float(pr.get("explosion_radius",80)),float(pr["damage"]),170,bool(pr["from_player"]),pr["hits"],str(pr.get("group","biological")),pr.get("impact_normal",Vector2.ZERO),pr.get("impact_point",pr["pos"]))

func _explode(at:Vector2,radius:float,damage:float,knockback:float,from_player:bool,exclude:Dictionary={},group:String="",normal:Vector2=Vector2.ZERO,point:Vector2=Vector2.INF) -> void:
	var origin:Vector2=at if point==Vector2.INF else point
	_sound("explosion")
	effects.append({"explosion_v16":true,"pos":origin,"normal":normal,"radius":radius,"life":.5,"max":.5,"color":Color.WHITE,"vel":Vector2.ZERO,"ring":false})
	# The contact atlas and its entire animation remain above the hit plane.
	shake=maxf(shake,6)
	if from_player:
		for en in enemies:
			if en["hp"]>0 and not exclude.has(en["uid"]) and _enemy_body_box(en).get_center().distance_to(at)<=radius:_hit_enemy(en,damage,Color("ffe0aa"),knockback)
		_hit_props(Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),damage,1)
		_damage_traps(Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),damage)
	elif not exclude.has(-1) and _body_box(p["pos"]).get_center().distance_to(at)<=radius:
		if _hurt_player(damage,at):p["recoil_left"]=.18;p["recoil_velocity"]=Vector2(signf(p["pos"].x-at.x)*knockback/.18,0);p["knockback_t"]=0

func _trap_surface(carrier:Dictionary) -> Vector2:
	var at:Vector2=carrier["pos"];var radius:float=float(carrier.get("radius",8))
	var best:Vector2=Vector2.ZERO;var distance:float=INF
	for surface:Rect2 in platforms+solids:
		if at.x<surface.position.x-radius or at.x>surface.end.x+radius:continue
		var gap:float=absf(at.y-surface.position.y)
		if gap<distance and gap<=radius+16:
			distance=gap;best=Vector2(clampf(at.x,surface.position.x+1,surface.end.x-1),surface.position.y)
	if distance<INF:return best
	# A side/underside collision does not leave a floating mine; settle on support below.
	return _trap_position(at+Vector2(0,radius))

func _settle_trap(carrier:Dictionary) -> void:
	if hazards.size()>=40:return
	var hazard:Dictionary=carrier["definition"].duplicate(true)
	hazard["pos"]=_trap_surface(carrier);hazard["owner_uid"]=carrier.get("owner_uid",0);hazard["from_player"]=carrier.get("from_player",false)
	var planted:Vector2=_planted_trap_position(hazard)
	if not planted.is_finite():return
	hazard["pos"]=planted
	hazard["hp"]=1.0;hazard["elapsed"]=0.0;hazard["hits"]={};hazard["next_hit"]={}
	hazard["arming_time"]=maxf(.625,float(hazard.get("arming_time",.65)))
	hazards.append(hazard)

func _planted_trap_position(hazard:Dictionary) -> Vector2:
	var desired:Vector2=hazard["pos"];var size:Vector2=TrapArt.body_box(hazard).size
	var best:=Vector2.INF;var cost:float=INF
	for surface:Rect2 in platforms+solids:
		if surface.position.y<desired.y-.5 or surface.size.x<size.x:continue
		var x:float=clampf(desired.x,surface.position.x+size.x*.5,surface.end.x-size.x*.5)
		if absf(x-desired.x)>192:continue
		var candidate:=Vector2(x,surface.position.y);var copy:Dictionary=hazard.duplicate();copy["pos"]=candidate
		var box:Rect2=TrapArt.body_box(copy).grow(-.05)
		if solids.any(func(rock:Rect2)->bool:return box.intersects(rock)):continue
		var distance:float=absf(candidate.y-desired.y)+absf(x-desired.x)*2
		if distance<cost:cost=distance;best=candidate
	return best

func _draw_terrain_details(c:CanvasItem) -> void:
	var biome:String=str(_ecology()["id"])
	var color:Color=_ecology()["accent"]
	for block:Rect2 in layout.get("blocks",[]):
		EnvArt.solid(c,block,biome,"block")
		if show_hitboxes:c.draw_rect(block,Color(color,.65),false,2)
	for trunk:Rect2 in layout.get("trunks",[]):
		EnvArt.solid(c,trunk,biome,"trunk")
		if show_hitboxes:c.draw_rect(trunk,Color(color,.65),false,2)
	for wall:Rect2 in layout.get("walls",[]):
		EnvArt.solid(c,wall,biome,"trunk" if wall.size.y>wall.size.x else "block")
		if show_hitboxes:c.draw_rect(wall,Color(color,.35),false,1)
	for decoration in layout.get("decorations",[]):Sprites.module(c,decoration["id"],decoration["rect"],Color(1,1,1,.8))

func _draw_props() -> void:
	var biome:String=str(_ecology()["id"])
	var accent:Color=_ecology()["accent"]
	var prop_base:Transform2D=preload("res://scripts/world_placement_v27.gd").prop_base(world_transform)
	if room.get("type","")=="merchant":
		var local_stock:Array=room.get("stock",[]).duplicate(true)
		for item:Dictionary in local_stock:item["pos"]-=_furniture_offset()
		SanctuaryArt.market(self,local_stock,p["pos"]-_furniture_offset(),clock,prop_base*Transform2D(0,_furniture_offset()),font)
		draw_set_transform_matrix(world_transform)
	if room.get("type","")=="reward":_draw_rewards()
	for prop in props:
		if prop.get("used",false) and prop["kind"]!="chest" and float(prop.get("break_left",0))<=0:continue
		var at:Vector2=prop["pos"];var kind:String=prop["kind"]
		if not view_rect.grow(140).has_point(at):continue
		if kind=="fountain":
			if at.distance_to(p["pos"])<160:_text(at-Vector2(75,90),"泉水 · 回復生命與能量",14,accent)
			continue
		if kind=="launcher":
			LaunchArt.draw(self,prop,biome,prop_base);continue
		if kind=="coin_urn":
			if not prop.get("used",false):continue
			BiomeArt.prop(self,prop,"underground",clock,prop_base);continue
		if kind=="ecology_object":
			if not prop.get("used",false):continue
			BiomeArt.prop(self,prop,biome,clock,prop_base);continue
		if kind=="grass":
			WorldDetail.grass(self,prop,clock,prop_base);continue
		if kind=="spring" and layout.get("pool",Rect2()).size.x>0:
			continue # Pool masonry and steam use a retained draw list.
		if kind=="shop_dummy":SanctuaryArt.dummy(self,at,clock,prop_base);continue
		if kind=="merchant":Adventure.merchant(self,at,clock,prop_base);continue
		elif kind=="chest":Adventure.chest(self,at,clock,prop_base,bool(prop.get("used",false)))
		elif _is_start() and kind in ["aid","forge","reforge","mail","energy_infinite","wardrobe"]:pass # Station paintings live in the retained static layer.
		elif kind in ["gift_pedestal","wardrobe"]:preload("res://scripts/adventure_art_v29.gd").station(self,kind,at,prop_base)
		elif kind in ["forge","reforge","mail"]:preload("res://scripts/station_art_v26.gd").draw(self,kind,at,prop_base)
		else:EnvArt.prop(self,prop,biome,clock,prop_base,weapon_index)
		var label:String={"wardrobe":"披風換裝站","gift_pedestal":"免費附武器展示台","forge":"藍圖鍛造台","reforge":"符文重鑄台","aid":"急救站","mail":"倉庫","dummy":"試打假人","energy_infinite":"無限能量花","energy":"砍破回能量","health":"砍破回滿生命","spring":"溫泉 · 回復生命與能量","chest":"寶箱 · ↑／X開啟","merchant":"貓頭鷹商人 · ↑交易"}.get(kind,kind)
		var label_height:float=132 if kind in ["forge","reforge","mail","wardrobe"] else 92
		if _is_start() and kind in ["aid","forge","reforge","mail","energy_infinite","wardrobe","dummy"]:
			# One expanded prompt follows the same nearest-station target as interaction.
			var focused:bool=kind==_nearest_station()
			var short_label:String={"aid":"急救","forge":"鍛造","reforge":"重鑄","mail":"倉庫","energy_infinite":"能量","wardrobe":"披風","dummy":"試打"}.get(kind,label)
			var caption:String=Bindings.label(int(key_bindings["up"]))+" · "+label if focused else short_label
			var text_width:float=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
			_text(at-Vector2(text_width*.5,label_height),caption,14,Color("fff0c6") if focused else Color("b0c2b3"))
		else:_text(at-Vector2(40,label_height),label,14,accent)
	draw_set_transform_matrix(world_transform)
	if _rune_effect("orbit_shield")>0:
		for i in 2:
			var at:Vector2=p["pos"]-Vector2(0,24)+Vector2.from_angle(draw_clock*2+i*PI)*52
			FX.fitted(self,"orbit_shield_fly",0,Rect2(at-Vector2.ONE*15,Vector2.ONE*30),world_transform,"right","idle",Color.WHITE,clock)
	if _rune_effect("orbit_bee")>0:
		for bee in int(_rune_effect("orbit_bee")):
			var at:Vector2=_bee_position(bee)
			FX.fitted(self,"bee_attack" if bee_timer>.8 else "bee_fly",0,Rect2(at-Vector2.ONE*14,Vector2.ONE*28),world_transform,"right","idle",Color.WHITE,clock)
	if _healing_guard():FX.fitted(self,"heal_guard",0,Rect2(p["pos"]-Vector2(40,65),Vector2(80,80)),world_transform,"right","idle",Color.WHITE,clock)
	if not feather.is_empty() and int(feather["room"])==current_room and life_event.get("kind","") not in ["death","await_choice"]:
		var at:Vector2=feather["pos"]-Vector2(0,58+sin(clock*.65)*6)
		Adventure.feather(self,at,clock,world_transform)
		_text(at-Vector2(70,55),"發光羽毛 · 攻擊取回背包",14,Color("e1f1ff"))

func _draw_life_event() -> void:
	if life_event.is_empty():return
	draw_set_transform_matrix(Transform2D.IDENTITY)
	draw_rect(Rect2(0,0,1280,720),Color(.015,.025,.05,.82))
	var kind:String=life_event.get("kind","")
	var elapsed:float=float(life_event.get("elapsed",0))
	var big:float=1.65 if kind in ["death","await_choice"] else 1.0
	draw_set_transform_matrix(world_transform)
	var clip:String="pigeon_soul_fly" if kind in ["soul","victory"] else ("pigeon_heavy_hurt" if kind=="injury" else "pigeon_death")
	var progress:float=clampf(elapsed/(2.2 if kind=="injury" else 1.6),0,1)
	if kind=="injury":progress=.25 if not life_event.get("landed",false) else lerpf(.45,1.0,clampf((elapsed-float(life_event.get("land_time",elapsed))-.75)/.25,0,1))
	for at in life_event.get("trail",[]):FX.actor(self,clip,progress,at,world_transform,float(p["face"]),big,Color(1,1,1,.08))
	if kind=="await_choice":
		Adventure.feather(self,p["pos"]-Vector2(0,40),clock,world_transform)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	elif kind=="death" and life_event.get("landed",false) and elapsed-float(life_event.get("land_time",elapsed))>.25:
		Adventure.feather(self,p["pos"]-Vector2(0,40),clock,world_transform)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	FX.actor(self,clip,progress,p["pos"],world_transform,float(p["face"]),big,Color(1.2,1.2,1.2,1),"",elapsed if kind in ["soul","await_choice"] else -1)
	draw_set_transform_matrix(world_transform)
	if kind=="soul" and not str(life_event.get("kept","")).is_empty():draw_circle(p["pos"]+Vector2(-35,10),9,Color("d1d3ff"))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	_text(Vector2(570,180),"重傷" if kind=="injury" else ("光榮返巢" if kind=="victory" else ("靈魂返程" if kind=="soul" else "羽翼碎落")),32,Color.WHITE)

func _movement_factor() -> float:
	var factor:float=(.8 if injured else 1.0)*Tuning.value("move_speed")
	if _is_healing():factor*=.4
	if _in_bath():factor*=.55
	if _key("dash") and not _key("down"):factor*=1.55
	return factor

func _is_healing() -> bool:
	return _key("heal") and int(p.get("energy",0))>=3 and int(p.get("hp",5))<int(p.get("max_hp",5)) and not p_attack.is_busy()

func _feather_burst(at:Vector2,count:int) -> void:
	if combat_feedback==null:return
	var burst:CPUParticles2D=combat_feedback._burst(at,UI.Icons.texture("death_feather_glow"),count,.6)
	burst.initial_velocity_min=50;burst.initial_velocity_max=220;burst.direction=Vector2.UP;burst.spread=120;burst.gravity=Vector2(0,90);burst.angular_velocity_min=-90;burst.angular_velocity_max=90
	burst.scale_amount_min=.07;burst.scale_amount_max=.16

func _world_confirm() -> bool:
	if screen=="hub":return _home_interact()
	if screen!="game" or room_cooldown>0:return false
	if room.get("type","")=="merchant" and not merchant_trial.is_empty():return false
	if room.get("type","")=="merchant" and merchant_trial.is_empty():
		var product:int=Sanctuary.nearest_stock(room.get("stock",[]),p["pos"])
		if product>=0:_show_merchant(product);return true
	for drop in drops:
		if drop.get("gift",false) and not drop.get("taken",false) and (drop["pos"]+Vector2(0,90)).distance_to(p["pos"])<90:_claim_gift();return true
	if _is_start():return _activate_station(_nearest_station(),true)
	for prop in props:
		if prop["pos"].distance_to(p["pos"])>110:continue
		match str(prop["kind"]):
			"chest":
				if not prop.get("used",false):_open_chest(prop);return true
			"merchant":_show_merchant();return true
	if _nearest_reward()>=0:_show_reward(_nearest_reward());return true
	if room.get("type","")=="boss" and room.get("cleared",false) and int(room["map_index"])==5 and absf(p["pos"].x-_room_size().x*.5)<150:_complete_run();return true
	return false

func _claim_gift() -> void:
	for drop in drops:
		if drop.get("gift",false) and not drop.get("taken",false):
			drop["taken"]=true;_give_drop("weapon",int(drop["value"]));_update_hud();return

func _damage_traps(box:Rect2,damage:float,gain_dream:bool=true) -> void:
	if damage<=0:return
	for hazard in hazards:
		if hazard.get("from_player",false) or float(hazard.get("hp",1))<=0:continue
		if box.intersects(TrapArt.body_box(hazard)):
			if hazard.get("pogoable",false) and p_attack.is_active() and p_attack.attack.get("direction","")=="down" and not p["grounded"]:_pogo();_melee_hitstop()
			hazard["hp"]=0.0;_contact_fx("block",hazard["pos"]-Vector2(0,15));_particles(hazard["pos"],Color("d0e9c8"),8,100)
			if mode=="musou" and gain_dream and damage>0:dream.hit()
	for pr in projectiles:
		if not pr.get("trap_carrier",false) or pr.get("from_player",false) or float(pr["life"])<=0:continue
		if box.has_point(pr["pos"]):
			pr["life"]=0;pr["destroyed"]=true;_contact_fx("block",pr["pos"])
			if mode=="musou" and gain_dream and damage>0:dream.hit()

func _open_chest(chest:Dictionary) -> void:
	if chest.get("used",false):return
	chest["used"]=true
	var at:Vector2=chest["pos"]
	_drop("coin",at-Vector2(0,25),rng.randi_range(12,28))
	_drop("item",at-Vector2(35,30),rng.randi_range(0,Data.ITEMS.size()-1))
	if chest.get("guaranteed_strong",false):_drop("rune",at+Vector2(35,-30),Data.RUNES.size()+rng.randi_range(0,Data.STRONG_RUNES.size()-1))
	elif rng.randf()<.5:_drop("rune",at+Vector2(35,-30),_random_rune_index())
	else:_drop("weapon",at+Vector2(35,-30),Arsenal.random_index(rng))
	_feather_burst(at-Vector2(0,25),12);_sound("coin");_toast("寶箱已開啟！")

func _show_merchant(index:int=-1) -> void:
	if room.get("type","")!="merchant":return
	if not room.has("stock"):room["stock"]=Sanctuary.stock(int(room.get("map_index",0)))
	if index<0:index=Sanctuary.nearest_stock(room["stock"],p["pos"])
	var entries:Array[Dictionary]=[]
	for i in room["stock"].size():
		var item:Dictionary=room["stock"][i];var def:Dictionary=Data.secondary_attack(int(item["value"])) if item["kind"]=="weapon" else Data.all_runes()[int(item["value"])]
		var owned:Array=bag_weapons if merchant_trial.is_empty() else merchant_trial["weapons"]
		var capacity:String=Arsenal.acquisition_status(owned,def,mode) if item["kind"]=="weapon" else "new"
		var unavailable:bool=capacity in ["max","full"]
		var capacity_note:String="\n這把武器已達 +8，無法再購買。" if capacity=="max" else "\n附武器已滿16把，無法再購買。" if capacity=="full" else ""
		entries.append({"name":def["name"],"description":str(def["description"])+capacity_note+"\n價格%d金幣 · 隨身%d金幣"%[int(item["price"]),run_coins],"icon":WorldItems.stock_icon(item),"weapon_id":str(def.get("id","")) if item["kind"]=="weapon" else "","caption":"已售出" if item["sold"] else "%d金幣"%int(item["price"]),"buttons":[{"label":"拿起試用","action":"merchant_try","payload":i,"disabled":bool(item["sold"])},{"label":"買下商品","action":"merchant_buy","payload":i,"disabled":bool(item["sold"]) or unavailable or run_coins<int(item["price"])},{"label":"放回試用品","action":"merchant_return","disabled":merchant_trial.is_empty()}]})
	equipment_open=false;_clear_keys();ChoiceView.build(ui,"貓頭鷹的三桌小舖",entries,"merchant","可先免費試用並攻擊假人測試。購買前商品屬於店家，離房或開背包會自動歸還。",maxi(0,index))

func _start_trial(index:int) -> void:
	if room.get("type","")!="merchant" or index<0 or index>=room.get("stock",[]).size():return
	var item:Dictionary=room["stock"][index]
	if item.get("sold",false):return
	_return_trial(false)
	merchant_trial={"room":current_room,"index":index,"weapons":bag_weapons.duplicate(true),"selected":secondary_index,"runes":rune_slots.duplicate(),"strong":strong_slots.duplicate(),"hp":p["hp"],"energy":p["energy"],"hp_recovery":p["hp_recovery"],"energy_recovery":p["energy_recovery"],"passive_energy":passive_energy,"move_energy_distance":move_energy_distance}
	if item["kind"]=="weapon":
		if mode=="musou" and bag_weapons.size()>=16:bag_weapons[15]=Data.secondary_attack(int(item["value"]))
		else:bag_weapons.append(Data.secondary_attack(int(item["value"])))
		secondary_index=bag_weapons.size()-1
	else:
		var id:String=Data.all_runes()[int(item["value"])]["id"]
		if Data.is_strong(id):
			if not strong_slots.has(id):
				if strong_slots.size()>=3:strong_slots[2]=id
				else:strong_slots.append(id)
		else:
			var slot:int=-1
			for i in 16:
				if i>=rune_slots.size() or rune_slots[i].is_empty():slot=i;break
			if slot<0:slot=15
			while rune_slots.size()<=slot:rune_slots.append("")
			rune_slots[slot]=id
	_sync_vitals();p["energy"]=p["max_energy"];_close_panel();_update_hud();_toast("免費試用中：到右側假人試打，滿意再買")

func _return_trial(notify:bool=true) -> void:
	if merchant_trial.is_empty():return
	var previous:Dictionary=merchant_trial;merchant_trial={}
	bag_weapons.assign(previous["weapons"]);secondary_index=int(previous["selected"]);rune_slots.assign(previous["runes"]);strong_slots.assign(previous["strong"])
	_sync_vitals()
	for key in ["hp","energy","hp_recovery","energy_recovery"]:p[key]=previous[key]
	passive_energy=float(previous["passive_energy"]);move_energy_distance=float(previous["move_energy_distance"])
	p_attack.cancel();pending_attack.clear();charge_timer=0;keys["attack"]=false;keys["sub"]=false;projectiles.clear();hazards.clear()
	if combat_feedback!=null:combat_feedback.clear()
	if ui!=null:_update_hud()
	if notify:_toast("試用品已歸還，原裝備已還原")

func _merchant_buy(index:int) -> void:
	if room.get("type","")!="merchant" or index<0 or index>=room.get("stock",[]).size():return
	var item:Dictionary=room["stock"][index]
	if item["sold"] or run_coins<int(item["price"]):return
	# Restore the real inventory before checking capacity: a trial is temporary
	# and must neither bypass the +8 cap nor falsely occupy the sixteenth slot.
	_return_trial(false)
	if item["kind"]=="weapon":
		var weapon:Dictionary=Data.secondary_attack(int(item["value"]))
		var status:String=Arsenal.acquisition_status(bag_weapons,weapon,mode)
		if status in ["max","full"]:
			_toast("這把武器已達 +8，未扣款" if status=="max" else "附武器已滿16把，未扣款");return
		var acquired:String=_acquire_weapon(weapon)
		if acquired not in ["new","upgrade"]:return
		if acquired=="new":secondary_index=bag_weapons.size()-1
		else:
			for i in bag_weapons.size():
				if bag_weapons[i].get("id","")==weapon["id"]:secondary_index=i;break
	else:_give_drop("rune",int(item["value"]))
	# The stock and payment commit only after the item has actually been granted.
	run_coins-=int(item["price"]);item["sold"]=true
	_close_panel();_sound("coin");_toast("購買完成，商品已正式加入行囊");_update_hud()

func _adapt_boss(en:Dictionary) -> void:
	if en.get("adapted",false) or float(en.get("hp",0))<=0:return
	en["adapted"]=true
	# Phase two adds one authored ecology attack, never an unrelated random move.
	var biome:String=str(en.get("biome","underground"))
	var kind:String={"sky":"linear","canopy":"flying_slash","branches":"arc","trunk":"flying_slash","grass":"arc","underground":"arc"}.get(biome,"arc")
	var attack:Dictionary=Combat.attack(kind,{"damage":1.0,"range":720.0,"size":23.0,"count":2,"speed":240.0,"spread":.3,"gravity":500.0,"launch_y":-260.0,"windup":1.05,"active":.16,"recovery":1.05,"color":en["color"],"group":"biological"})
	MonsterDesign.decorate_adaptation(attack,en);en["attacks"].append(attack)
	en["adaptations"]=["新攻擊"]
	_float(en["pos"]-Vector2(0,110),"首領覺醒",Color("ffbd89"));_toast(str(en["name"])+"進入第二階段：新招式已解放")

func _cast_special(at:Vector2,dir:Vector2,def:Dictionary) -> void:
	var kind:String=def["weapon_kind"]
	if kind=="laser":
		var direction:Vector2=dir.normalized()
		var beam_width:float=float(def.get("size",ProjectileReadability.BASE_RADIUS))*2
		for i in int(def.get("count",1)):
			var start:Vector2=at+direction.orthogonal()*(i-float(int(def.get("count",1))-1)*.5)*maxf(20,beam_width*1.25)
			var finish:Vector2=start+direction*float(def.get("range",900))
			var wall:float=Coll.first_solid(start,finish,beam_width*.5,_projectile_surfaces())
			if wall<INF:finish=start+(finish-start)*wall
			for en in enemies:
				if en["hp"]>0 and _segment_hits_box(start,finish,_enemy_body_box(en).grow(beam_width*.5)):_hit_enemy(en,float(def["damage"]),def["color"],70,start,direction)
			_damage_traps(Rect2(start.min(finish),start.max(finish)-start.min(finish)).grow(beam_width*.5),float(def["damage"]))
			effects.append({"pos":start,"end":finish,"beam":true,"width":beam_width,"weapon_id":str(def.get("id","")),"vel":Vector2.ZERO,"life":.34,"max":.34,"color":def["color"],"ring":false,"radius":1.0})
	else:
		var origin:Vector2=at;var hit:Dictionary={}
		for i in 5+int(def.get("count",1))-1:
			var target:Dictionary={};var closest:float=420 if i==0 else 270
			for en in enemies:
				if en["hp"]<=0 or hit.has(en["uid"]) or not _in_aggro(en):continue
				var center:Vector2=_enemy_body_box(en).get_center();var distance:float=center.distance_to(origin)
				if distance<closest and Coll.first_solid(origin,center,1,solids)==INF:closest=distance;target=en
			if target.is_empty():break
			var end:Vector2=_enemy_body_box(target).get_center();hit[target["uid"]]=true
			_hit_enemy(target,float(def["damage"]),def["color"],45,origin,(end-origin).normalized())
			effects.append({"pos":origin,"end":end,"lightning":true,"weapon_id":str(def.get("id","")),"vel":Vector2.ZERO,"life":.3,"max":.3,"color":def["color"],"ring":false,"radius":1.0});origin=end
	_sound("slash")

func _show_records() -> void:
	var rows:Array[Dictionary]=[{"text":"光榮返巢的冒險會在此保存武器組合、擊殺數與死亡次數，最多保留30次。"}]
	for record in meta.get("records",[]):
		var weapons:String=str(record["primary"])+" ＋ "+"／".join(record.get("secondary",[]))
		rows.append({"heading":str(record.get("date",""))+" · "+("無雙夢境" if record.get("mode","")=="musou" else "Roguelike"),"text":weapons+"\n擊殺 %d · 死亡 %d · 種子 %d"%[int(record["kills"]),int(record["deaths"]),int(record["seed"])]})
	if meta.get("records",[]).is_empty():rows.append({"text":"還沒有通關紀錄。選擇模式門，開始你的遠行。"})
	_panel("冒險紀錄",rows)

func _lab_button(label:String,callback:Callable) -> Button:
	var button:=Button.new();button.text=label;button.custom_minimum_size=Vector2(156,42);button.add_theme_font_override("font",font);button.add_theme_font_size_override("font_size",18)
	var style:=StyleBoxFlat.new();style.bg_color=Color("183d36");style.border_color=Color("b9ac74");style.set_border_width_all(1);style.set_corner_radius_all(8);button.add_theme_stylebox_override("normal",style);button.pressed.connect(callback);return button
func _setup_labs() -> void:
	lab_buttons=HBoxContainer.new();lab_buttons.position=Vector2(475,640);lab_buttons.add_theme_constant_override("separation",18);ui.ui_root.add_child(lab_buttons)
	lab_buttons.add_child(_lab_button("練習房",_enter_practice));lab_buttons.add_child(_lab_button("RD 美術室",_open_rd))
	practice_tools=HBoxContainer.new();practice_tools.position=Vector2(378,114);practice_tools.add_theme_constant_override("separation",12);ui.ui_root.add_child(practice_tools);practice_tools.visible=false
	practice_tools.add_child(_lab_button("練習工具／召喚",_show_practice));practice_tools.add_child(_lab_button("RD 房間設定",_open_practice_rd));practice_tools.add_child(_lab_button("返回鳥巢",_leave_lab))
func _show_developer_tools() -> void:
	if screen!="hub":return
	_panel("開發工具",[
		{"text":"用於檢查素材、地圖與數值的開發工具；修改參數可能影響之後的冒險。"},
		{"buttons":[{"label":"RD 美術室","action":"lab_art"},{"label":"RD 參數調教","action":"lab_tuning"}]},
		{"buttons":[{"label":"返回設定","action":"settings"}]}
	])
func _open_rd() -> void:
	if screen!="hub":return
	_close_panel();_clear_keys();lab_mode="rd";lab_buttons.hide();atmosphere.configure("branches",0,false)
	var layer:=CanvasLayer.new();layer.layer=60;add_child(layer)
	rd_view=RD.new();layer.add_child(rd_view)
	rd_view.closed.connect(func()->void:lab_mode="";layer.queue_free();rd_view=null;_clear_keys();_invalidate_scene())
func _enter_practice() -> void:
	if screen!="hub":return
	Tuning.activate(meta.get("rd_tuning",{}))
	lab_meta=meta.duplicate(true);lab_mode="practice";lab_ai=true;practice_mode=true
	_close_panel();_clear_keys();bag_weapons.clear();bag_runes.clear();rune_slots.clear();strong_slots.clear();bag_items.clear();sub_growth.clear()
	for id:String in Arsenal.IDS:bag_weapons.append(Data.secondary_attack(Arsenal.index_of(id)))
	for rune in Data.all_runes():bag_runes[rune["id"]]=99;meta["runes"][rune["id"]]=99
	for i in Data.ITEMS.size():bag_items[str(i)]=99
	secondary_index=0;weapon_index=1;run_coins=9999;mode="rogue";screen="game";room={};current_room=-1;injured=false;life_event.clear();feather.clear()
	tower={"seed":160016,"rooms":[{"id":0,"map_index":2,"type":"start","laboratory":true,"width":25,"height":15,"neighbors":{},"doors_config":{},"coord":Vector2i.ZERO,"visited":false,"initialized":false}],"maps":[]}
	_reset_player(Vector2(300,896));_enter_room(0);_toast("練習房：全部武器、符文與怪物。能量無限，角色無敵。")
func _leave_lab() -> void:
	if lab_mode in ["rd","tuning"]:return
	if lab_mode=="practice":meta=lab_meta.duplicate(true);lab_meta.clear()
	lab_mode="";practice_mode=false;lab_ai=true;freeze_timer=0;_close_panel();_ui_action("hub",null);_update_hud()

func _open_practice_rd() -> void:
	if lab_mode!="practice" or practice_rd_panel!=null:return
	_close_panel();_clear_keys()
	var layer:=CanvasLayer.new();layer.layer=61;add_child(layer)
	practice_rd_panel=PracticeRD.new();layer.add_child(practice_rd_panel);practice_rd_panel.setup(practice_rd_settings)
	practice_rd_panel.regenerate.connect(_regenerate_practice)
	practice_rd_panel.closed.connect(func()->void:practice_rd_panel=null;layer.queue_free();_clear_keys();_invalidate_scene())

func _regenerate_practice(parameters:Dictionary) -> void:
	if lab_mode!="practice":return
	practice_rd_settings=PracticeRD.DEFAULTS.duplicate();practice_rd_settings.merge(parameters,true)
	var options:Dictionary=practice_rd_settings;var seed_value:int=int(options["seed"])
	if seed_value<=0:seed_value=rng.randi_range(1,2000000000)
	var biome:String=str(options["biome"]);var stage:int={"underground":0,"trunk":2,"sky":4}.get(biome,2)
	var definition:Dictionary={"id":0,"map_index":stage,"type":"combat","laboratory":true,"practice_arena":bool(options["arena"]),"practice_density":float(options["enemy_density"]),"layout_profile":str(options["profile"]),"plaza_scale":float(options["plaza_scale"]),"maze_config":{"straight_bias":float(options["straight_bias"]),"braid_rate":float(options["braid_rate"]),"corridor_width_mode":"random","dead_end_chance":clampf(float(options.get("dead_end_chance",.25)),.2,1)},"maze_seed":seed_value,"width":clampi(int(options["width"])|1,17,25),"height":clampi(int(options["height"])|1,11,17),"neighbors":{},"doors_config":{},"coord":Vector2i.ZERO,"visited":false,"initialized":false}
	# This is an isolated laboratory room; keep the current loadout and bag.
	room={};enemies=[];drops=[];corpses=[];props=[];current_room=-1;life_event.clear();feather.clear()
	tower={"seed":seed_value,"rooms":[definition],"maps":[]}
	_clear_keys();p_attack.cancel();_reset_player(Vector2(300,896));_enter_room(0)
	_toast("練習房已重生 · "+_ecology()["name"]+" · 種子 %d"%seed_value)
func _show_practice() -> void:
	if lab_mode!="practice":return
	var sections:Array[Dictionary]=[{"text":"自由試用所有裝備；練習結果不寫入冒險紀錄。","buttons":[{"label":"符文配置（全部可用）","action":"lab_runes"},{"label":"清空怪物與彈體","action":"lab_clear"},{"label":"怪物AI："+("開" if lab_ai else "停"),"action":"lab_ai"}]}]
	var primary_buttons:Array=[]
	for i in [1]:primary_buttons.append({"label":Data.PRIMARY[i]["name"],"action":"lab_primary","payload":i})
	sections.append({"text":"主武器","buttons":primary_buttons})
	for i in Data.SECONDARY.size():sections.append({"text":Data.SECONDARY[i]["description"],"buttons":[{"label":"裝備 "+Data.SECONDARY[i]["name"],"action":"lab_secondary","payload":i}]})
	for i in _lab_monsters().size():sections.append({"text":"召喚實際遊戲敵人","buttons":[{"label":_lab_monsters()[i],"action":"lab_monster","payload":i}]})
	_panel("練習工具 · 裝備與怪物",sections)
func _lab_monsters() -> Array[String]:
	var names:Array[String]=[]
	for i in 5:names.append(MonsterRoster.regular("underground",i)["name"])
	for i in 5:names.append("菁英："+str(MonsterRoster.elite(i)["name"]))
	names.append("可愛遊盪者")
	for biome:String in ["underground","grass","trunk","branches","canopy","sky"]:names.append("Boss："+str(Combat.boss(biome)["name"]))
	for biome:String in ["trunk","sky"]:
		for i in 5:names.append(MonsterRoster.regular(biome,i)["name"])
	names.append("菁英："+str(MonsterRoster.elite(5)["name"]))
	return names
func _summon_monster(index:int) -> void:
	if lab_mode!="practice" or index<0 or index>=_lab_monsters().size():return
	var definition:Dictionary
	if index>=11 and index<=16:definition=Combat.boss(["underground","grass","trunk","branches","canopy","sky"][index-11])
	elif index==10:definition=Arms.cute_wanderer(rng)
	elif index<5:definition=MonsterRoster.regular("underground",index)
	elif index<10:definition=MonsterRoster.elite(index-5)
	elif index==27:definition=MonsterRoster.elite(5)
	else:definition=MonsterRoster.regular("trunk" if index<22 else "sky",index-17)
	if definition.get("elite",false):definition["hp"]*=3.0
	definition["hp"]*=Tuning.value("enemy_hp");definition["speed"]*=Tuning.value("enemy_speed")
	spawn_serial+=1
	var at:=Vector2(clampf(p["pos"].x+float(p["face"])*240,260,_room_size().x-260),_room_floor())
	if definition["move"]=="fly":at.y-=180
	definition.merge({"uid":100000+spawn_serial,"pos":at,"anchor":at,"spawn_platform":0,"biome":definition.get("biome",_ecology()["id"]),"ecology_id":_ecology()["id"],"vel":Vector2.ZERO,"face":-1.0,"hurt":0.0,"stun":0.0,"cooldown":1.0,"attack":Attack.new(),"contact_damage":float(definition.get("contact_damage",1.0)),"max_hp":definition["hp"]},true)
	var placement:Vector2=_air_spawn(at,float(definition["scale"]),MonsterMotion.body_size(definition)) if definition["move"]=="fly" else _fit_enemy_ground(definition)
	if not placement.is_finite():_toast("附近沒有足夠空間，請換個位置召喚這隻怪物");return
	definition["pos"]=placement;definition["anchor"]=placement
	enemies.append(definition);_toast("召喚："+_lab_monsters()[index])

func _paint_static_props(c:CanvasItem) -> void:
	if screen!="game":return
	for prop:Dictionary in props:
		if prop.get("used",false):continue
		if _is_start() and prop["kind"] in ["aid","forge","reforge","mail","energy_infinite","wardrobe"]:preload("res://scripts/scene_art_v33.gd").station(c,str(_ecology()["id"]),prop["kind"],prop["pos"],preload("res://scripts/world_placement_v27.gd").prop_base())
		if prop["kind"] in ["ecology_object","coin_urn"]:BiomeArt.prop(c,prop,"underground" if prop["kind"]=="coin_urn" else str(_ecology()["id"]),0,preload("res://scripts/world_placement_v27.gd").prop_base())
	if room.get("fountain",false) and layout.has("fountain_pos"):preload("res://scripts/spring_v33.gd").draw(c,layout["fountain_pos"],str(_ecology()["id"]),preload("res://scripts/world_placement_v27.gd").prop_base())
	if room.get("spring",false):SanctuaryArt.pool_back(c,layout.get("pool",Rect2()),0,Transform2D.IDENTITY)

func _paint_enemy_body(canvas:CanvasItem,en:Dictionary) -> void:
	var atk=en["attack"]
	var kind:String={0:"melee",1:"ranged",2:"fly",3:"elite",4:"boss",5:"elite"}.get(int(en["model"]),"melee")
	if int(en["model"])==4:BossVisual.draw(canvas,en,draw_clock,Transform2D.IDENTITY)
	elif not MonsterDesign.draw_actor(canvas,en,draw_clock,Transform2D.IDENTITY):
		var phase:String="hurt" if float(en["hurt"])>0 else atk.phase
		var progress:float=1-float(en["hurt"])/.2 if phase=="hurt" else atk.progress()
		if phase=="idle" and str(en.get("visual_movement",""))=="dash":
			if float(en.get("motion_dash_wait",0))<0:phase="prepare";progress=1+float(en["motion_dash_wait"])/float(en.get("dash_windup",.5))
			elif float(en.get("motion_dash_wait",0))>0:phase="brake";progress=1-float(en["motion_dash_wait"])/.9
		if phase=="idle" and str(en.get("visual_movement",""))=="drift" and float(en.get("turn_left",0))>0:phase="turn";progress=1-float(en["turn_left"])/.25
		var clip:String=FX.enemy_clip(en,phase)
		if not FX.actor(canvas,clip,progress,en["pos"],Transform2D.IDENTITY,float(en["face"]),float(en["scale"]),Color.WHITE,phase,draw_clock if phase=="idle" else -1,str(en.get("visual_movement",en.get("movements",["walk"])[0])) in ["hover","drift"]):
			Sprites.enemy(canvas,en["pos"],float(en["face"]),draw_clock,kind,phase,atk.progress(),Transform2D.IDENTITY,not bool(atk.attack.get("primary",true)),float(en["scale"]))
		if en.get("elite",false):
			var weapon:String=str(en["attacks"][1].get("weapon_visual","weapon_heavy"))
			if not FX.frame(canvas,weapon,0,en["pos"]+Vector2(float(en["face"])*23,-28),Transform2D.IDENTITY,float(en["face"]),46):
				canvas.draw_line(en["pos"]+Vector2(20,-5),en["pos"]+Vector2(35,-55),Color("dfc2a5"),5)
			_text_on(canvas,en["pos"]-Vector2(20,75),"菁英",12,Color("ffd7a1"))

func _sync_enemy_canvases() -> void:
	var alive:Dictionary={}
	var stamp:int=int(draw_clock*30)
	for en:Dictionary in enemies:
		if en.get("training",false) or float(en["hp"])<=0:continue
		var id:int=int(en["uid"]);alive[id]=true
		var enabled:bool=screen=="game" and view_rect.intersects(_enemy_body_box(en).grow(24))
		if not enemy_canvases.has(id):
			if not enabled and float(en.get("flash_left",0))<=0:continue
			var fresh=EnemyCanvas.new();fresh.local_origin=true;fresh.paint=_paint_enemy_body;add_child(fresh);enemy_canvases[id]=fresh
		var sprite=enemy_canvases[id];sprite.actor=en
		var attack=en["attack"]
		var signature:Array=[stamp,en.get("face",1),attack.phase,int(attack.progress()*60),int(float(en.get("hurt",0))*60),en.get("scale",1),int(float(en.get("turn_left",0))*60)]
		if en.has("roster_id"):
			var sample:Dictionary=preload("res://scripts/monster_art_v36.gd").actor_sample(en,draw_clock)
			signature=[sample["sheet"],sample["row"],sample["column"],en.get("face",1),float(en.get("hurt",0))>0,en.get("scale",1)]
		sprite.refresh(world_transform,enabled,signature)
	for id in enemy_canvases.keys():
		if not alive.has(id):enemy_canvases[id].queue_free();enemy_canvases.erase(id)

func _paint_player_slash(canvas:CanvasItem) -> void:
	if screen not in ["game","hub"] or not p_attack.is_active() or not p_attack.attack.get("primary",false) or (p_attack.attack.get("charged",false) and not p_attack.attack.get("great_spin_release",false)):return
	SlashArt.draw(canvas,_attack_box(p["pos"],p_attack.attack,float(p["face"])),p_attack.attack,p_attack.progress(),world_transform)

func _pogo() -> void:
	p["jump_cut_allowed"]=false;p["recoil_left"]=0;p["wall_kick_left"]=0
	p["vel"].y=-PlayerMotion.POGO_SPEED;p["grounded"]=false
	p["air_dash"]=false;p["jumps"]=1;p["invul"]=maxf(.14,float(p["invul"]))

func _melee_hitstop() -> void:
	if not p_attack.is_active() or not p_attack.attack.get("primary",false):return
	var style:String=str(p_attack.attack.get("style","foot"))
	hitstop=maxf(hitstop,{"foot":.05,"quick":4.0/60,"heavy":.08}.get(style,.05))

func _charge_threshold() -> float:
	return Tuning.value("charge_seconds")/(1+float(upgrades["charge"])*.08)

func _update_idle(delta:float) -> void:
	var quiet:bool=bool(p["grounded"]) and p["vel"].length_squared()<1 and not p_attack.is_busy() and not _key("attack") and not _key("heal") and float(p["hurt"])<=0 and float(p["dash_t"])<=0
	idle_time=idle_time+delta if quiet else 0.0

func _select_secondary(index:int) -> void:
	if bag_weapons.is_empty():secondary_index=0;return
	secondary_index=posmod(index,bag_weapons.size())
	# Switching a sidearm cancels the old sidearm's outer phases, never its hit.
	if p_attack.attack.get("kind","")=="secondary" and p_attack.phase in ["windup","recovery"]:p_attack.cancel()
	keys["sub"]=false
	_update_hud();_toast("副武器 %d/%d：%s"%[secondary_index+1,bag_weapons.size(),_secondary()["name"]])

func _confine_boss(en:Dictionary) -> void:
	var half:float=_enemy_body_box(en).size.x*.5;var height:float=_enemy_body_box(en).size.y
	var before:Vector2=en["pos"]
	var safe:=Rect2(Vector2(maxf(half+96,200),height+96),Vector2(maxf(1,_room_size().x-maxf(half+96,200)*2),maxf(1,_room_floor()-height-96)))
	en["pos"]=Vector2(clampf(before.x,safe.position.x,safe.end.x),clampf(before.y,safe.position.y,safe.end.y))
	if en["pos"]!=before:
		if en["pos"].x!=before.x:en["vel"].x=0
		if en["pos"].y!=before.y:en["vel"].y=0
		en["push_left"]=0;en["motion_dash_left"]=0
		if en.get("charge_phase","idle")=="active":en["charge_phase"]="recovery";en["charge_left"]=.35

func _open_tuning() -> void:
	if screen!="hub":return
	_close_panel();_clear_keys();lab_mode="tuning";lab_buttons.hide()
	var layer:=CanvasLayer.new();layer.layer=60;add_child(layer)
	tuning_view=TuningPanel.new();layer.add_child(tuning_view);tuning_view.setup(meta.get("rd_tuning",{}))
	tuning_view.saved.connect(func(parameters:Dictionary)->void:meta["rd_tuning"]=parameters;_save_meta())
	tuning_view.closed.connect(func()->void:lab_mode="";layer.queue_free();tuning_view=null;_clear_keys();_invalidate_scene())

func _update_corpses(delta:float) -> void:
	var changed:bool=false
	for body:Dictionary in corpses:
		if CorpseField.step(body,delta,solids,platforms,_room_size()):changed=true
	if changed and corpse_layer!=null:corpse_layer.invalidate()

func _paint_corpses(canvas:CanvasItem) -> void:
	if screen!="game":return
	for body:Dictionary in corpses:CorpseField.draw(canvas,body)

func _paint_edge_background(canvas:CanvasItem) -> void:
	if screen=="game":NewBiome.draw_details(canvas,str(_ecology()["id"]),layout,-1,terrain_region)

func _paint_edge_foreground(canvas:CanvasItem) -> void:
	if screen=="game":NewBiome.draw_details(canvas,str(_ecology()["id"]),layout,1,terrain_region)

func _paint_player_flash(canvas:CanvasItem,_actor:Dictionary) -> void:
	Art.draw_pigeon(canvas,p["pos"],float(p["face"]),clock,"hurt",Color.WHITE,1.0,1-float(p.get("hurt",0))/.25,Transform2D.IDENTITY,str(Data.PRIMARY[weapon_index]["style"]),p_attack.attack)

func _launch_from_object(prop:Dictionary,attacked:bool) -> void:
	if _wind_form_active():p_attack.cancel()
	var height_multiplier:float=3.0 if attacked else 1.0
	# Height is proportional to v²/(2g):3×height needs sqrt(3)×speed.
	var normal_speed:float=JUMP_SPEED*(1+_rune_effect("wing"))*Tuning.value("jump_speed")
	p["vel"]=Vector2(float(p["vel"].x),-normal_speed*sqrt(height_multiplier))
	# Swept down-slam contacts happen inside the AABB step. Preserve the new
	# impulse after its local collision result is committed at step end.
	if p.get("_motion_step",false):p["launch_pending_velocity"]=p["vel"]
	p["grounded"]=false;p["wall"]=0;p["dash_t"]=0;p["slam"]=false
	p["recoil_left"]=0;p["knockback_t"]=0;p["jump_cut_allowed"]=false
	p["jump_buffer_left"]=0;p["coyote_left"]=0;p["landing_left"]=0;p["heavy_land_left"]=0;p["fall_distance"]=0
	_restore_ground_movement()
	prop["launch_left"]=.625;prop["launch_cooldown"]=.45
	if attacked:prop["launch_hit_cooldown"]=.15
	_contact_fx("block",prop["pos"]-Vector2(0,30));_sound("jump")

func _unlock_blueprint(id:String) -> void:
	if Arsenal.index_of(id)<0:return
	if not meta.has("blueprints"):meta["blueprints"]=[]
	if not meta["blueprints"].has(id):meta["blueprints"].append(id)

func _acquire_weapon(weapon:Dictionary) -> String:
	_unlock_blueprint(str(weapon.get("id","")))
	var result:String=Arsenal.acquire(bag_weapons,weapon,mode)
	match result:
		"new":_toast("取得副武器："+str(weapon["name"])+(" · 一次發動 %d / 16把"%bag_weapons.size() if mode=="musou" else " · 藍圖已解鎖"))
		"upgrade":_toast(str(weapon["name"])+" · 重複強化，投射物 +1（最多 +8）")
		"max":_toast(str(weapon["name"])+"已達投射物 +8；藍圖已保留")
		"full":_toast("無雙夢境已裝滿16把附武器；此武器藍圖已保留")
	_save_meta();return result

func _show_equipment(page:int=0,preserve_focus:bool=false) -> void:
	_return_trial(false)
	if screen!="game":_toast("開始冒險後可查看裝備");return
	ui.equipment_navigation.prepare(ui,posmod(page,4),preserve_focus and equipment_open)
	_clear_keys();equipment_page=posmod(page,4);equipment_open=true
	Equipment.build(ui,_inventory_data(),equipment_page)

func _first_aid() -> void:
	if not _is_start():return
	injured=false;_sync_vitals();p["hp"]=p["max_hp"];p["energy"]=p["max_energy"]
	_station_event("aid","heal");_update_hud();_toast("急救完成：生命與能量已補滿")

func _station_panel(page:String) -> void:
	equipment_open=false;_clear_keys()
	if ui.station_page!=page:ui.station_focus_key="";ui.station_selection=""

func _show_forge() -> void:
	if not _is_start():return
	_station_panel("forge");prep_station="forge"
	StationView.forge(ui,{"blueprints":meta.get("blueprints",[]),"coins":run_coins,"bank":int(meta["coins"]),"weapons":bag_weapons,"mode":mode,"result":forge_result})

func _craft_weapon(id:String) -> bool:
	if not _is_start() or not meta.get("blueprints",[]).has(id):return false
	var index:int=Arsenal.index_of(id)
	if index<0 or run_coins+int(meta["coins"])<Arsenal.CRAFT_COST:return false
	# Capacity is checked before spending, including capped duplicate upgrades.
	if mode=="musou" and bag_weapons.size()>=16:return false
	if mode=="rogue" and bag_weapons.any(func(held:Dictionary)->bool:return held.get("id","")==id and int(held.get("duplicate_bonus",0))>=8):_toast("這把武器已達 +8");return false
	var carried:int=mini(run_coins,Arsenal.CRAFT_COST);run_coins-=carried;meta["coins"]-=Arsenal.CRAFT_COST-carried
	_acquire_weapon(Data.secondary_attack(index));forge_result=Data.secondary_attack(index).duplicate(true)
	if mode=="rogue":
		for held:Dictionary in bag_weapons:
			if held.get("id","")==id:forge_result=held.duplicate(true);break
	_save_meta();_update_hud();return true

func _show_reforge(reset:bool=true) -> void:
	if not _is_start():return
	_station_panel("reforge");prep_station="reforge"
	if reset:reforge_selection.clear();reforge_result="";reforge_result_id=""
	StationView.reforge(ui,{"selection":reforge_selection,"bag":bag_runes,"vault":meta,"slots":rune_slots,"strong_slots":strong_slots,"result":reforge_result,"result_id":reforge_result_id})

func _reforge_runes() -> bool:
	if not _is_start() or reforge_selection.size()!=3:return false
	var pool:Array=Data.all_runes().filter(func(definition:Dictionary)->bool:return not reforge_selection.has(str(definition["id"])))
	if pool.is_empty() or not StationStock.consume(reforge_selection,bag_runes,meta,rune_slots,strong_slots):return false
	var result:Dictionary=pool[rng.randi_range(0,pool.size()-1)]
	reforge_selection.clear();var id:String=result["id"];bag_runes[id]=int(bag_runes.get(id,0))+1;_auto_equip_rune(id);reforge_result=str(result["name"]);reforge_result_id=id
	_sync_vitals();_save_meta();_toast("重鑄完成："+reforge_result);return true

func _show_warehouse() -> void:
	if not _is_start():return
	_station_panel("warehouse");prep_station="mail"
	var unused:int=0
	for id:String in bag_runes:unused+=StationStock.free_count(id,bag_runes,rune_slots,strong_slots)
	StationView.warehouse(ui,{"vault":meta,"filter":warehouse_filter,"unused":unused})

func _warehouse_take(entry:Dictionary) -> bool:
	if not _is_start() or entry.is_empty():return false
	var kind:String=entry.get("kind","");var key:String=str(entry.get("payload",""))
	match kind:
		"rune":
			if int(meta["runes"].get(key,0))<=0:return false
			meta["runes"][key]-=1;bag_runes[key]=int(bag_runes.get(key,0))+1
			if int(meta["runes"][key])<=0:meta["runes"].erase(key)
		"item":
			if int(meta["items"].get(key,0))<=0:return false
			meta["items"][key]-=1;bag_items[key]=int(bag_items.get(key,0))+1
			if int(meta["items"][key])<=0:meta["items"].erase(key)
		"weapon":
			var index:int=int(key)
			if index<0 or index>=meta["weapons"].size():return false
			var outcome:String=_acquire_weapon(Bag.restore_weapon(meta["weapons"][index]))
			if outcome not in ["new","upgrade"]:return false
			meta["weapons"].remove_at(index)
		"coins":
			if int(meta["coins"])<=0:return false
			run_coins+=int(meta["coins"]);meta["coins"]=0
		_:return false
	_save_meta();_update_hud();_show_warehouse();_toast("已取出至行囊");return true

func _begin_heavy_landing(at:Vector2) -> void:
	_sound("ground_slam")
	p["heavy_land_left"]=.5;p["landing_left"]=0;p["flap_left"]=0
	p["dash_t"]=0;p["recoil_left"]=0;p["jump_buffer_left"]=0
	p_attack.cancel();pending_attack.clear();charge_timer=0;heal_timer=0;jump_request=false
	keys["attack"]=false;keys["jump"]=false
	hitstop=maxf(hitstop,.04);shake=maxf(shake,2.5)

func _randomize_rune_loadout() -> void:
	var result:Dictionary=preload("res://scripts/rune_random_v29.gd").choose(bag_runes,meta.get("runes",{}),_is_start(),rng)
	if result["small"].is_empty() and result["large"].is_empty():_toast("目前沒有可裝配的符文");return
	for id:String in result["take"]:
		var count:int=int(result["take"][id]);meta["runes"][id]=int(meta["runes"].get(id,0))-count
		if int(meta["runes"][id])<=0:meta["runes"].erase(id)
		bag_runes[id]=int(bag_runes.get(id,0))+count
	rune_slots.assign(result["small"]);strong_slots.assign(result["large"]);rune_target_slot=-1
	_sync_vitals();_save_meta();_toast("已隨機自動裝配符文")

func _restart_after_death() -> void:
	var chosen_mode:String=mode
	var previous_seed:int=int(tower.get("seed",0))
	var next_seed:int=rng.randi_range(1,2000000000)
	if next_seed==previous_seed:next_seed=previous_seed%2000000000+1
	new_run(chosen_mode,next_seed)
	weapon_index=1;hitstop=0;shake=0;freeze_timer=0;equipment_open=false;_clear_keys()
	_toast("新的一局已開始，只有存入倉庫的物品會保留")
