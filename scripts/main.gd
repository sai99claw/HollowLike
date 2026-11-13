extends Node2D
const PerfLog=preload("res://scripts/performance_log_v42.gd")
var perf_log=PerfLog.new()
var perf_bridge:JavaScriptObject
var perf_callback:JavaScriptObject
var perf_paused:bool=false
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
const GothicProps=preload("res://scripts/gothic_props_v82.gd")
const PropStrike=preload("res://scripts/hit_art_v37.gd")
const NewBiome=preload("res://scripts/biome_art_v21.gd")
const PigeonPose=preload("res://scripts/pigeon_motion_v22.gd")
const AdventurePose=preload("res://scripts/adventure_visual.gd")
const HIT_WHITE_SECONDS:float=.03
const CorpseField=preload("res://scripts/corpse_field_v21.gd")
const Tuning=preload("res://scripts/rd_tuning_v19.gd")
const TuningPanel=preload("res://scripts/rd_tuning_panel_v19.gd")
const IdleArt=preload("res://scripts/pigeon_idle_v19.gd")
const PlayerMotion=preload("res://scripts/player_motion_v18.gd")
const DepthPass=preload("res://scripts/visual_depth_v74.gd")
const Overhang=preload("res://scripts/platform_overhang_v74.gd")
const Juice=preload("res://scripts/visual_juice_v74.gd")
const EnemyVitals=preload("res://scripts/enemy_vitals_v74.gd")
var visual_depth:Node2D
var visual_juice:Node2D
var visual_layout:Dictionary
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
const Stones=preload("res://scripts/throwable_stones.gd")
const Explosion=preload("res://scripts/explosion_v16.gd")
const Coins = preload("res://scripts/coin_physics.gd")
const Bindings = preload("res://scripts/input_settings.gd")
const Combat = preload("res://scripts/combat_library.gd")
const BossVisual = preload("res://scripts/boss_art.gd")
const SkillArt=preload("res://scripts/skill_art_v59.gd")
const BossActionArt=preload("res://scripts/boss_art_v57.gd")
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
const PROJECT_URL: String = "https://github.com/sai99claw/HollowLike"
const PROJECTION_FONT = preload("res://assets/v65/home/NotoSerifTC-Projection.ttf")
const PROJECTION_TRIM = preload("res://assets/v65/home/projection_bottom.png")
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
const JUMP_SPEED: float = PlayerMotion.JUMP_SPEED
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
var player_slashes:Array[Dictionary]=[]
var home_sleeping:bool=true
var home_wake_left:float=0
var screen: String = "hub"
var spring_particles:Node2D
var home_atmosphere:Node2D
var mode: String = "rogue"
var meta: Dictionary = {"coins":0,"runes":{"gale":1,"reach":1,"guard":1},"skills":[],"attempts":0,"skins":[0],"skin":0,"best_map":0,"rd_tuning":{},"items":{},"weapons":[],"records":[],"blueprints":[],"trophies":{"weapons":[],"runes":[]},"settings":{"zoom":1.3,"speed":.8,"keys":{}}}
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
const LIFT_CHARGE_SECONDS:float=1.0
const LIFT_SPEED:float=1070.0
const ULTIMATE_CAPACITY:int=6
const ULTIMATE_RADIUS:float=280.0
const LIFT_HIT_DAMAGE:float=2.0
const SHIELD_RADIUS:float=38.0
const ULTIMATE_DAMAGE:float=12.0
const ULTIMATE_KNOCKBACK:float=680.0
const ROOM_CLEAR_SLOW_SECONDS:float=2.0
const ROOM_CLEAR_WORLD_RATE:float=.28
var room_clear_slow_left:float=0.0
var camera_zoom:float=1.3
const DISPLAY_SIZE:=Vector2(1280,720)
const DISPLAY_ZOOM_MAX:float=2.0
var display_fit:String="contain"
var display_zoom:float=1.0
var trophy_room:bool=false
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
const SHIELD_BASE_CELLS:int=2
const SHIELD_QUIET_SECONDS:float=6.0
const SHIELD_RECHARGE_INTERVAL:float=1.0
const PORTAL_HEIGHT:float=3.0*96.0
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
var background_volume:float=1.0
var sfx_volume:float=1.0
var home_fragments:Array[Dictionary]=[]
var audio_enabled:bool=true:
	set(value):
		audio_enabled=value
		AudioServer.set_bus_mute(0,not value)
		if not value and combat_audio!=null:combat_audio.stop_all()
		if not value and walker!=null:walker.stop_audio()
		if room_music!=null:room_music.set_enabled(value)
		if atmosphere!=null:atmosphere.set_audio_enabled(value)
var walker:Node
const AudioCues = preload("res://scripts/combat_audio_v63.gd")
var combat_audio: AudioCues
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
var low_effects: bool = false
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
var last_motion_pos:Vector2=Vector2.ZERO
var spawn_serial:int=0
var prep_station:String="forge"
var atmosphere:Node2D
var combat_feedback:Node2D
var minimap_open:bool=false
var minimap_page:int=-1
var map_held:bool=false
var map_pinned:bool=false
var display_probe:float=0.0
var display_safe:=Rect2(0,0,1280,720)
var poison_clouds:Array[Dictionary]=[]
var poison_left:float=0.0
const NewRoster=preload("res://scripts/monster_roster_v55.gd")
const NewMonsterArt=preload("res://scripts/monster_art_v55.gd")
const HazardRoom=preload("res://scripts/hazard_room_v54.gd")
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
var projectile_surfaces: Array = []
var lab_mode:String=""
var tutorial_previous_practice:bool=false
var lab_meta:Dictionary={}
var lab_ai:bool=true
var rd_view:Control
var home_projector:Dictionary={}
var home_credits:HBoxContainer
var home_hint_fade_at:float=INF
var home_backdrop_y:float=INF
var lab_buttons:HBoxContainer
var practice_tools:HBoxContainer
var practice_rd_panel:Control
var practice_rd_settings:Dictionary={}
var practice_page:String="rooms"


func _ready() -> void:
	if not OS.has_feature("web"):get_window().size_changed.connect(_apply_display_fit)
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
	terrain.material=ShaderMaterial.new()
	terrain.material.shader=preload("res://shaders/terrain_core_v74.gdshader")
	terrain.set_meta("graded_terrain",true)
	static_props=Cache.new();static_props.z_index=-1;static_props.paint=_paint_static_props;add_child(static_props)
	edge_background=Cache.new();edge_background.z_index=-3;edge_background.paint=_paint_edge_background;add_child(edge_background)
	edge_foreground=Cache.new();edge_foreground.z_index=7;edge_foreground.paint=_paint_edge_foreground;add_child(edge_foreground)
	corpse_layer=Cache.new();corpse_layer.z_index=-2;corpse_layer.paint=_paint_corpses;add_child(corpse_layer)
	minimap = Cache.new();minimap.z_index=20;minimap.paint=_paint_minimap;add_child(minimap)
	_reset_player(Vector2(640,600))
	atmosphere=Atmosphere.new();add_child(atmosphere);atmosphere.configure("branches",0,false);atmosphere.set_audio_enabled(audio_enabled)
	combat_feedback=Feedback.new();combat_feedback.z_index=2;add_child(combat_feedback)
	dream_visual=preload("res://scripts/dream_visual_v41.gd").new();add_child(dream_visual)
	spring_particles=preload("res://scripts/spring_particles_v33.gd").new();spring_particles.z_index=2;add_child(spring_particles)
	home_atmosphere=preload("res://scripts/home_atmosphere_v33.gd").new();add_child(home_atmosphere)
	slash_canvas=Cache.new();slash_canvas.z_index=1;slash_canvas.paint=_paint_player_slash;add_child(slash_canvas)
	p_attack.active_started.connect(_start_player_slash)
	player_flash_layer=EnemyCanvas.new();player_flash_layer.z_index=1;player_flash_layer.paint=_paint_player_flash;add_child(player_flash_layer)
	visual_depth=DepthPass.new()
	add_child(visual_depth)
	visual_juice=Juice.new()
	add_child(visual_juice)
	ui = UI.new()
	add_child(ui)
	ui.setup()
	_setup_labs()
	_setup_home_credits()
	critical_warning=ColorRect.new();critical_warning.name="CriticalCorners";critical_warning.size=Vector2(1280,720);critical_warning.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var warning_material:=ShaderMaterial.new();warning_material.shader=load("res://shaders/critical_health.gdshader");critical_warning.material=warning_material
	ui.ui_root.add_child(critical_warning);critical_warning.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.ui_root.move_child(critical_warning,0);critical_warning.visible=false
	ui.action_requested.connect(_ui_action)
	ui.touch_action.connect(_set_action)
	touch_enabled = bool(meta.get("settings",{}).get("touch_enabled",preload("res://scripts/screen_touch_v29.gd").mobile_default()))
	ui.set_touch_visible(touch_enabled)
	p_attack.active_started.connect(_player_active_started)
	walker=Walk.new();add_child(walker)
	combat_audio = AudioCues.new()
	add_child(combat_audio)
	room_music=Music.new();room_music.bus="Background";add_child(room_music);room_music.set_enabled(audio_enabled);room_music.select("hub","branches")
	AudioCues.load_cues(sounds)
	_configure_home()
	_update_hud()
	_update_shortcuts()
	_setup_performance_log()
	queue_redraw()
	if OS.get_cmdline_user_args().has("--smoke"):
		new_run("rogue",12345)

func _reset_player(at: Vector2) -> void:
	if visual_juice!=null:visual_juice.clear()
	player_slashes.clear()
	combo_index=0
	p = {"pos":at,"vel":Vector2.ZERO,"face":1.0,"hp":5,"max_hp":5,"energy":3,"max_energy":6,"grounded":true,"wall":0,"jumps":0,"air_dash":false,"dash_t":0.0,"dash_dir":Vector2.RIGHT,"invul":0.0,"hurt":0.0,"wall_lock":0.0,"wall_hold_left":0.0,"wall_slide_age":0.0,"jump_rise_age":-1.0,"slam_age":0.0,"slam_land_left":0.0,"shield":0.0,"slam":false,"slam_speed":520.0,"knockback_t":0.0,"knockback_dir":1.0,"recoil_left":0.0,"recoil_velocity":Vector2.ZERO,"impact_root":0.0,"jump_cut_allowed":false,"jump_released":false,"landing_left":0.0,"wall_kick_left":0.0,"wall_kick_velocity":0.0,"hp_recovery":0.0,"energy_recovery":0.0,"flash_left":0.0,"coyote_left":0.0,"jump_buffer_left":0.0,"flap_left":0.0,"heavy_land_left":0.0,"fall_distance":0.0,"mantle_left":0.0}
	p["max_shield"]=SHIELD_BASE_CELLS+int(_rune_effect("max_shield"))
	p["shield_cells"]=p["max_shield"]
	p["ultimate_charge"]=float(p["energy"])
	p["shield_recharge_left"]=0.0
	dash_chain_open=false
	if ui!=null:ui.feather_collection.clear()
	p_attack.cancel()
	if walker!=null:walker.reset_turn(float(p["face"]))
	drop_through_timer=0.0
	idle_time=0
	charge_timer = 0.0
	heal_timer = 0.0
	pending_attack.clear()

func _input(event:InputEvent) -> void:
	if perf_paused:return
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
		if event is InputEventKey:
			var code:int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
			var focused:Control=get_viewport().gui_get_focus_owner()
			if focused is LineEdit and focused.name=="DisplayZoomInput" and code!=KEY_ESCAPE:return
			if code==KEY_ESCAPE and minimap_open and event.pressed:
				map_pinned=false;_set_map_held(false)
				get_viewport().set_input_as_handled();return
			if code==KEY_M and (minimap_open or _can_open_map()):
				if event.pressed and not event.echo:
					map_pinned=not map_pinned
					_refresh_map_visibility()
				get_viewport().set_input_as_handled();return
			var item_index:int=code-KEY_1 if code>=KEY_1 and code<=KEY_5 else (code-KEY_KP_1 if code>=KEY_KP_1 and code<=KEY_KP_5 else -1)
			if item_index>=0 and not event.shift_pressed and screen=="game" and not minimap_open and not ui.is_panel_open() and life_event.is_empty():
				if event.pressed and not event.echo:_use_item(item_index,true,false)
				get_viewport().set_input_as_handled();return
			if code==KEY_TAB or Bindings.action_for(key_bindings,code)=="map":
				if not event.echo:_set_map_held(event.pressed)
				get_viewport().set_input_as_handled();return
		if minimap_open and event is InputEventKey:
			var map_code:int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
			var map_action:String={KEY_LEFT:"left",KEY_RIGHT:"right"}.get(map_code,Bindings.action_for(key_bindings,map_code))
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
	if perf_paused:return
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
		var pad_action:String={JOY_BUTTON_A:"jump",JOY_BUTTON_B:"dash",JOY_BUTTON_X:"attack",JOY_BUTTON_Y:"sub",JOY_BUTTON_DPAD_UP:"up",JOY_BUTTON_DPAD_DOWN:"down",JOY_BUTTON_DPAD_LEFT:"left",JOY_BUTTON_DPAD_RIGHT:"right",JOY_BUTTON_RIGHT_SHOULDER:"heal",JOY_BUTTON_LEFT_SHOULDER:"ultimate"}.get(event.button_index,"")
		if not pad_action.is_empty():_set_action(pad_action,event.pressed)
		if event.pressed and event.button_index==JOY_BUTTON_START:_show_settings()
	elif event is InputEventKey:
		var e:InputEventKey=event
		if e.echo:return
		var action:String=Bindings.action_for(key_bindings,int(e.physical_keycode))

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

func _home_controls_visible() -> bool:
	return screen=="hub" and not trophy_room and camera_pos.y>-24.0 and lab_mode not in ["rd","tuning"] and ui!=null and not ui.is_panel_open()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: _clear_keys(false)

func _set_action(action: String, pressed: bool) -> void:
	if perf_paused:return
	if practice_rd_panel!=null:return
	if minimap_open:
		if pressed and action in ["left","right"]:
			minimap_page=posmod(minimap_page+(-1 if action=="left" else 1),3)
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
	var cancelled_lift:bool=p.get("lift_flying",false) and pressed and not _key(action) and action in ["left","right","up","down","jump","dash","attack","sub","heal","ultimate","interact"]
	if cancelled_lift:
		p.erase("lift_flying")
		p["vel"]=Vector2.ZERO
	if screen=="hub" and pressed and action in ["jump","dash","attack"]:home_sleeping=false;home_wake_left=0
	if action=="jump":
		if pressed and not _key("jump"):p["jump_buffer_left"]=0.0 if _key("up") and _can_start_lift() else .12;p["jump_released"]=false
		elif not pressed:p["jump_released"]=true
	if _action_locked() and action in (["attack","sub","interact","up"] if _release_locked() else ["jump","attack","sub","interact","up"]):
		if pressed and action in ["attack","sub"]:_reject_attack("locked")
		keys[action]=false;charge_timer=0;return
	if action=="attack" and pressed and screen in ["game","hub"] and (float(p.get("hurt",0))>0 or _primary_press_blocked()):
		# Rejected presses never become a delayed swing or charge.
		_reject_attack("hurt" if float(p.get("hurt",0))>0 else "busy")
		keys["attack"]=false;charge_timer=0;pending_attack.clear();return
	var was: bool = bool(keys.get(action,false))
	keys[action]=pressed
	if pressed and not was:
		match action:
			"jump":
				var lift_pressed:bool=_key("up") and _can_start_lift()
				if lift_pressed:p["lift_charge"]=0.0
				jump_request=not lift_pressed
				p["jump_released"]=false
			"dash":
				if screen in ["game","hub"]: _dash_pressed(cancelled_lift)
			"attack":
				charge_timer=0.0
				if screen in ["game","hub"]:
					_begin_primary({"dir":_aim_string(),"charged":false});_process_player_attack()
			"sub":
				if screen=="game": _begin_secondary()
			"interact": _show_equipment(0)
			"up":
				if _key("jump") and _can_start_lift():p["lift_charge"]=0.0
				elif not _key("jump"):_interact()
			"ultimate":_cast_ultimate()
	if action=="up" and not pressed:p.erase("lift_charge")
	if action=="jump" and not pressed and was:
		_release_lift()
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

func _cycle_map() -> void:
	if screen!="game" or ui.is_panel_open() or not life_event.is_empty():return
	minimap_page=(minimap_page+1)%4
	minimap_open=minimap_page<3
	ui.header.visible=not minimap_open
	ui.health_background.visible=ui.header.visible and screen=="game"
	minimap.invalidate()

func _can_open_map() -> bool:
	return screen=="game" and ui!=null and not ui.is_panel_open() and life_event.is_empty()

func _refresh_map_visibility() -> void:
	var previously_open:bool=minimap_open
	minimap_open=(map_held or map_pinned) and _can_open_map()
	if minimap_open and not previously_open:
		minimap_page=0
		keys.clear()
		jump_request=false
		p["jump_buffer_left"]=0.0
	if not minimap_open:minimap_page=-1
	if ui!=null:
		ui.header.visible=not minimap_open
		ui.health_background.visible=ui.header.visible and screen=="game"
		ui.quickbar.visible=_can_open_map() and not minimap_open
	if minimap!=null:minimap.invalidate()

func _set_map_held(pressed:bool) -> void:
	map_held=pressed and _can_open_map()
	_refresh_map_visibility()

func _clear_keys(close_map:bool=true) -> void:
	if close_map:map_pinned=false
	_set_map_held(false)
	keys.clear(); jump_request=false;
	if not p.is_empty():p["jump_buffer_left"]=0.0;p["coyote_left"]=0.0;p.erase("lift_charge")
	charge_timer=0.0; pending_attack.clear(); dash_chain_open=false

func _process(delta: float) -> void:
	display_probe-=delta
	if display_probe<=0:
		display_probe=.30
		_update_safe_interface()
	if not perf_log.active:
		_process_profiled_body(delta);return
	perf_log.begin_frame()
	var measured:int=Time.get_ticks_usec()
	_process_profiled_body(delta)
	perf_log.span("process.total",Time.get_ticks_usec()-measured)
	if perf_log.finish_frame(_performance_context):call_deferred("_show_performance_report")

func _process_profiled_body(delta: float) -> void:
	if lab_buttons!=null:lab_buttons.visible=_home_controls_visible()
	if home_credits!=null:home_credits.visible=screen=="hub" and not trophy_room and lab_mode.is_empty() and not ui.is_panel_open()
	if practice_tools!=null:practice_tools.visible=lab_mode=="practice" and not ui.is_panel_open() and practice_rd_panel==null
	if lab_mode in ["rd","tuning"]:return
	metrics_timer+=delta
	if metrics_timer>=.5:
		fps_smoothed=Engine.get_frames_per_second()
		metrics_timer=0
	# Every actor and retained terrain use one world camera transform.
	var jitter:Vector2=Vector2.ZERO
	if shake>.05: jitter=Vector2(sin(draw_clock*87)*shake,cos(draw_clock*71)*shake)*.45
	render_camera=camera_pos
	var zoom:float=_view_zoom() if screen=="game" else 1.0
	world_transform=Transform2D(0,Vector2.ONE*zoom,0,-render_camera*zoom+jitter)
	if edge_background!=null:edge_background.transform=world_transform
	if edge_foreground!=null:edge_foreground.transform=world_transform
	if corpse_layer!=null:corpse_layer.transform=world_transform.translated_local(Vector2(0,5))
	if terrain!=null: terrain.transform=world_transform
	if static_props!=null:static_props.transform=world_transform
	if backdrop!=null:backdrop.transform=(atmosphere.depth_transform(render_camera,zoom,Atmosphere.FAR_FACTOR) if _is_start() else Atmosphere.parallax(render_camera,1.0,Atmosphere.FAR_FACTOR)) if screen=="game" else Transform2D.IDENTITY
	if screen=="hub" and absf(render_camera.y-home_backdrop_y)>.25:
		home_backdrop_y=render_camera.y
		backdrop.invalidate()
	if home_atmosphere!=null:
		home_atmosphere.set_active(screen=="hub" and not trophy_room)
	if spring_particles!=null:spring_particles.transform=world_transform
	if atmosphere!=null:
		atmosphere.set_audio_enabled(audio_enabled and life_event.is_empty() and not ui.is_panel_open())
		atmosphere.backdrop_transform=backdrop.transform
		atmosphere.update_view(render_camera,zoom,world_transform,p["pos"],draw_clock,0.0 if perf_paused else world_speed*_clear_world_rate(),low_effects)
	view_rect=Rect2(render_camera-Vector2(120,130)/zoom,Vector2(1520,980)/zoom)
	var region:Rect2=preload("res://scripts/render_budget_v40.gd").region(view_rect)
	if region!=terrain_region:
		terrain_region=region
		terrain.invalidate();edge_background.invalidate();edge_foreground.invalidate()
	if not is_same(visual_layout,layout):
		visual_layout=layout
		var sources:Array=doors if screen=="game" else ([{"pos":HomeArt.STATIONS["musou"]},{"pos":HomeArt.STATIONS["rogue"]}] if not trophy_room else [])
		visual_depth.configure(layout,solids,sources,props,screen=="game",str(_ecology()["id"]))
	var fog_floor:float=_room_floor()
	var feet:Vector2=p["pos"]
	if screen=="game":
		for platform:Rect2 in platforms:
			if feet.x>=platform.position.x-25 and feet.x<=platform.end.x+25 and platform.position.y>=feet.y-4:
				fog_floor=minf(fog_floor,platform.position.y)
	var visible_world:bool=screen in ["game","hub"] and lab_mode not in ["rd","tuning"]
	visual_depth.update_view(render_camera,world_transform,display_safe,feet,fog_floor,draw_clock,visible_world,low_effects,perf_paused or hitstop>0 or minimap_open or ui.is_panel_open(),terrain_region,_clear_world_rate())
	visual_juice.update_view(world_transform,draw_clock,low_effects)
	_sync_enemy_canvases()
	if player_flash_layer!=null:
		player_flash_layer.actor=p;player_flash_layer.refresh(world_transform,screen=="game" and life_event.is_empty() and float(p.get("flash_left",0))>0 and not _wind_form_active())
	if slash_canvas!=null:slash_canvas.invalidate()
	if combat_feedback!=null:
		combat_feedback.set_frozen(perf_paused or hitstop>0 or minimap_open or practice_rd_panel!=null,world_speed*_clear_world_rate())
		combat_feedback.reduced=low_effects
		combat_feedback.transform=world_transform
		var lift_elapsed:float=float(p.get("lift_charge",-1))
		var charging:bool=lift_elapsed>=0 or (_key("attack") and charge_timer>.08)
		combat_feedback.update_charge(screen=="game" and life_event.is_empty() and not ui.is_panel_open() and charging,p["pos"]-Vector2(0,27),lift_elapsed if lift_elapsed>=0 else charge_timer,_lift_threshold() if lift_elapsed>=0 else _charge_threshold())
		combat_feedback.update_cache(screen=="game" and ((life_event.get("kind","")=="death" and float(life_event.get("elapsed",0))>.7) or (not feather.is_empty() and int(feather.get("room",-1))==current_room)),p["pos"] if life_event.get("kind","")=="death" else feather.get("pos",Vector2.ZERO),clock)
	if dream_visual!=null:dream_visual.set_view(screen=="game" and mode=="musou",world_transform,p["pos"],dream.rage_left>0 and life_event.is_empty(),perf_paused or hitstop>0 or minimap_open or ui.is_panel_open() or practice_rd_panel!=null or not life_event.is_empty(),world_speed)
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
	if not perf_log.active:
		_physics_process_profiled_body(delta);return
	var measured:int=Time.get_ticks_usec()
	_physics_process_profiled_body(delta)
	perf_log.span("physics.total",Time.get_ticks_usec()-measured)

func _physics_process_profiled_body(delta:float) -> void:
	if perf_paused:return
	if practice_rd_panel!=null:return
	if lab_mode in ["rd","tuning"]:return
	if lab_mode=="tutorial":p["energy"]=p["max_energy"]
	if lab_mode=="practice":p["energy"]=p["max_energy"];p["invul"]=2;freeze_timer=0 if lab_ai else 999
	real_clock+=delta
	if minimap_open:return
	var real_delta:float=delta
	if screen=="game":
		if not ui.is_panel_open() and life_event.is_empty():
			var slow_delta:float=minf(delta,room_clear_slow_left)
			delta-=slow_delta*(1.0-ROOM_CLEAR_WORLD_RATE)
			room_clear_slow_left-=slow_delta
			_update_shield(real_delta)
			if p.has("lift_invul_left"):p["lift_invul_left"]=maxf(0.0,float(p["lift_invul_left"])-real_delta)
			ui.feather_collection.step(real_delta,world_transform,ui.energy_collection_target())
		_update_hit_white(delta)
	# Physics, pose sampling and VFX share the same frozen game clock.
	if hitstop>0 and life_event.is_empty():
		# Landing protection measures real gameplay seconds, including impact hitstop.
		if screen=="game" and float(p.get("slam_land_left",0))>0 and not ui.is_panel_open():
			p["invul"]=maxf(0.0,float(p["invul"])-real_delta)
		if screen=="game" and room.get("cleared",false) and not ui.is_panel_open():_update_drops(real_delta)
		hitstop=maxf(0,hitstop-real_delta);return
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
	for key in ["invul","hurt","wall_lock","shield","impact_root","flash_left","heavy_land_left","power_item_left","shield_item_left"]:p[key]=maxf(0,float(p.get(key,0))-delta)
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
	var was_in_bath:bool=_in_bath()
	_update_player(delta*world_speed)
	if _in_bath() and not was_in_bath:_sound("water_splash")
	_update_idle(delta)
	var walking:bool=bool(p["grounded"]) and absf(p["vel"].x)>30 and float(p["hurt"])<=0 and float(p["dash_t"])<=0 and float(p["recoil_left"])<=0 and (not p_attack.is_busy() or p_attack.phase=="recovery")
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
	_update_drops(real_delta if room.get("cleared",false) else delta*world_speed)
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
func _clear_world_rate() -> float:
	return ROOM_CLEAR_WORLD_RATE if screen=="game" and room_clear_slow_left>0.0 else 1.0

func _view_zoom() -> float:
	var bounds:Vector2=_room_size()
	var fit:float=maxf(1280.0/bounds.x,720.0/bounds.y)
	return maxf(Scale.MIN_ZOOM,maxf(camera_zoom,fit))
func _camera_target(at:Vector2) -> Vector2:
	if screen=="hub":return Vector2(0,clampf(at.y-720.0*2.0/3.0,HomeArt.CEILING_Y,0)) if not trophy_room else Vector2.ZERO
	var visible:Vector2=Vector2(1280,720)/_view_zoom();var bounds:Vector2=_room_size()
	return Vector2(clampf(at.x-visible.x*.5,0,maxf(0,bounds.x-visible.x)),clampf(at.y-visible.y*2.0/3.0,0,maxf(0,bounds.y-visible.y)))
func _in_bath() -> bool:return Bath.contains(_active_pool(),p.get("pos",Vector2.ZERO))

func _active_pool() -> Rect2:
	if room.get("fountain",false) and layout.has("fountain_pos"):return preload("res://scripts/spring_v33.gd").pool(layout["fountain_pos"],str(_ecology()["id"]))
	return layout.get("pool",Rect2())

func _load_settings() -> void:
	var settings:Variant=meta.get("settings",{})
	if not settings is Dictionary:settings={}
	camera_zoom=clampf(float(settings.get("zoom",1.3)),.8,2.0)
	display_fit="cover" if settings.get("display_fit","contain")=="cover" else "contain"
	display_zoom=_normalize_display_zoom(settings.get("display_zoom",1.0))
	_apply_display_fit()
	world_speed=clampf(float(settings.get("speed",.8)),.4,1.5)
	audio_enabled=bool(settings.get("audio_enabled",audio_enabled))
	_set_audio_volume("Background",float(settings.get("background_volume",1.0)))
	_set_audio_volume("Effects",float(settings.get("sfx_volume",1.0)))
	key_bindings=Bindings.load_bindings(settings.get("keys",{}))
	if int(settings.get("bindings_version",0))<2 and int(key_bindings.get("sub",0))==KEY_U and Bindings.action_for(key_bindings,KEY_Z)=="":Bindings.assign(key_bindings,"sub",KEY_Z)

func _set_audio_volume(bus_name:String,value:float) -> void:
	value=clampf(value,0.0,1.0) if is_finite(value) else 1.0
	if bus_name=="Background":background_volume=value
	else:sfx_volume=value
	var bus_index:int=AudioServer.get_bus_index(bus_name)
	if bus_index<0:return
	AudioServer.set_bus_mute(bus_index,value==0.0)
	AudioServer.set_bus_volume_db(bus_index,linear_to_db(maxf(value,.0001)))

func _normalize_display_zoom(value:Variant) -> float:
	if not (value is float or value is int) or not is_finite(float(value)):return 1.0
	return clampf(snappedf(float(value),.01),1.0,DISPLAY_ZOOM_MAX)

func _apply_display_fit() -> void:
	var cover:bool=display_fit=="cover"
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.documentElement.dataset.gameFit="+JSON.stringify(display_fit)
			+";document.documentElement.style.setProperty('--game-zoom',"+JSON.stringify(display_zoom)+")")
	else:
		var window:Window=get_window()
		if window.size.x<=0 or window.size.y<=0:return
		if cover:
			# EXPAND keeps one scale for both axes and removes letterboxing.
			# Translate the logical canvas so the extra crop is centered.
			var scale_by_axis:Vector2=Vector2(window.size)/DISPLAY_SIZE
			window.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
			window.content_scale_factor=maxf(scale_by_axis.x,scale_by_axis.y)/minf(scale_by_axis.x,scale_by_axis.y)*display_zoom
			var visible:Vector2=window.get_visible_rect().size
			window.global_canvas_transform=Transform2D(0,(visible-DISPLAY_SIZE)*.5)
		else:
			window.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
			window.content_scale_factor=1.0
			window.global_canvas_transform=Transform2D.IDENTITY
	display_probe=0.0

func _update_safe_interface() -> void:
	if ui==null or ui.ui_root==null:return
	var visible:Vector2=DISPLAY_SIZE
	if display_fit=="cover":
		if OS.has_feature("web"):
			var fraction:Variant=JSON.parse_string(str(JavaScriptBridge.eval("""
				(() => {
					const canvas = document.getElementById('canvas').getBoundingClientRect();
					const view = document.documentElement;
					return JSON.stringify([view.clientWidth / canvas.width, view.clientHeight / canvas.height]);
				})()
			""")))
			if fraction is Array and fraction.size()==2 and float(fraction[0])>0 and float(fraction[1])>0:
				visible=DISPLAY_SIZE*Vector2(minf(1.0,float(fraction[0])),minf(1.0,float(fraction[1])))
		else:
			visible=get_window().get_visible_rect().size
	var safe:=Rect2((DISPLAY_SIZE-visible)*.5,visible)
	if safe==display_safe:return
	display_safe=safe
	ui.set_safe_rect(safe)
	var fit:Transform2D=_safe_canvas_transform()
	if minimap!=null:minimap.transform=fit
	for panel in [rd_view,tuning_view,practice_rd_panel]:
		if is_instance_valid(panel):panel.get_parent().transform=fit
	if lab_buttons!=null:lab_buttons.position=Vector2((ui.ui_root.size.x-330)*.5,ui.ui_root.size.y-80)
	if practice_tools!=null:practice_tools.position.x=(ui.ui_root.size.x-492)*.5

func _safe_canvas_transform() -> Transform2D:
	var logical:=Vector2(1280,720)
	if not display_safe.has_area():return Transform2D.IDENTITY
	var factor:float=minf(display_safe.size.x/logical.x,display_safe.size.y/logical.y)
	return Transform2D(0,Vector2.ONE*factor,0,display_safe.get_center()-logical*factor*.5)

func _save_settings() -> void:
	meta["settings"]={"zoom":camera_zoom,"speed":world_speed,"keys":key_bindings.duplicate(),"bindings_version":2,"audio_enabled":audio_enabled,"background_volume":background_volume,"sfx_volume":sfx_volume,"touch_enabled":touch_enabled,"display_fit":display_fit,"display_zoom":display_zoom}
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
	if not perf_log.active:
		_update_player_profiled_body(delta);return
	var measured:int=Time.get_ticks_usec()
	_update_player_profiled_body(delta)
	perf_log.span("physics.player",Time.get_ticks_usec()-measured)

func _update_player_profiled_body(delta:float) -> void:
	if _healing_guard():
		p["vel"]=Vector2.ZERO
		return
	# Preserve ordinary-jump clearance at every global speed setting.
	var steps:int=maxi(1,int(ceil(delta/PlayerMotion.MOTION_STEP)))
	for step in steps:_step_player(delta/steps)

func _step_player(delta: float) -> void:
	if p.get("lift_flying",false):
		_step_lift(delta)
		return
	var preparing_lift:bool=p.has("lift_charge") and _key("up") and _key("jump") and _can_start_lift()
	if preparing_lift:
		var previous_charge:float=float(p["lift_charge"])
		var threshold:float=_lift_threshold()
		p["lift_charge"]=minf(threshold,previous_charge+delta)
		if previous_charge==0.0:_sound("lift_charge")
		if previous_charge<threshold and float(p["lift_charge"])>=threshold:_sound("lift_ready")
		p["jump_buffer_left"]=0.0
		jump_request=false
	else:p.erase("lift_charge")
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
	p["landing_left"]=maxf(0,float(p.get("landing_left",0))-delta)
	p["wall_kick_left"]=maxf(0,float(p.get("wall_kick_left",0))-delta)
	var wall_hold_left:float=float(p["wall_hold_left"])
	p["wall_hold_left"]=maxf(0,wall_hold_left-delta)
	if was_attached:p["wall_slide_age"]+=maxf(0,delta-wall_hold_left)
	if float(p["jump_rise_age"])>=0:p["jump_rise_age"]+=delta
	p["slam_land_left"]=maxf(0,float(p["slam_land_left"])-delta)
	drop_through_timer=maxf(0,drop_through_timer-delta)
	var axis: float=0.0 if preparing_lift or _movement_locked() else float(int(_key("right"))-int(_key("left")))
	var speed_factor:float=_movement_factor()
	if _movement_locked():vel.x=0
	if axis!=0 and not _release_locked(): p["face"]=signf(axis)
	if bool(p["slam"]):
		p["slam_age"]+=delta
		p["slam_speed"]=minf(1480.0,float(p["slam_speed"])+2100.0*delta)
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
		if bool(p["slam"]): vel=Vector2(0,float(p["slam_speed"])*PlayerMotion.SLAM_SPEED_FACTOR)
		# A single retained wind texture replaces per-substep particle allocation.
	else:
		vel.x=axis*MOVE_SPEED*speed_factor
		if axis==0 and float(p.get("wall_kick_left",0))>0:vel.x=float(p["wall_kick_velocity"])
		vel.y=minf(vel.y+PlayerMotion.RISE_GRAVITY*(Tuning.value("fall_gravity") if vel.y>=0 else 1.0)*delta,PlayerMotion.MAX_FALL_SPEED)
		if bool(p["slam"]): vel=Vector2(0,float(p["slam_speed"])*PlayerMotion.SLAM_SPEED_FACTOR)
	if float(p.get("jump_buffer_left",0))>0 and not knocked and not _movement_locked() and float(p.get("hurt",0))<=0:
		var jumped:bool=false
		if int(p["wall"])!=0:
			jumped=true
			vel=Vector2(-int(p["wall"])*390,-JUMP_SPEED)
			pos.x-=int(p["wall"])*8
			p["wall_kick_left"]=.09;p["wall_kick_velocity"]=vel.x
			p["wall_lock"]=.17;p["wall"]=0;p["jumps"]=1;p["grounded"]=false
			_sound("wall_jump")
		elif bool(p["grounded"]) or float(p.get("coyote_left",0))>0:
			jumped=true
			if _key("down") and bool(p["grounded"]) and _can_drop_through(pos):
				drop_through_y=pos.y;drop_through_timer=.22
				p["drop_to_lower_room"]=_in_lower_exit_lane(pos)
				pos.y+=3;vel.y=130;p["grounded"]=false;_sound("drop_through")
			else:
				p["jump_rise_age"]=0.0
				vel.y=-JUMP_SPEED*(1.0+_rune_effect("wing"))*Tuning.value("jump_speed");p["grounded"]=false;p["jumps"]=1;_sound("jump")
		elif _skill("doublejump") and int(p["jumps"])<2:
			jumped=true
			vel.y=-JUMP_SPEED*.92*Tuning.value("jump_speed");p["jumps"]=2;p["flap_left"]=.32;combat_feedback.double_jump(pos-Vector2(0,18));_sound("double_jump")
		if jumped:
			if vel.y<0:Juice.squash(p,Juice.LAUNCH,draw_clock,.15)
			p["jump_buffer_left"]=0;p["coyote_left"]=0;p["jump_cut_allowed"]=true
			if bool(p.get("jump_released",false)) and vel.y<0:vel.y=PlayerMotion.cut(vel.y);p["jump_cut_allowed"]=false
	var can_glide:bool=_key("jump") and not p.get("drop_to_lower_room",false) and not p["grounded"] and int(p["wall"])==0 and not _wind_form_active() and float(p["dash_t"])<=0 and not knocked and float(p["hurt"])<=0 and not _in_bath()
	var gliding:bool=can_glide and vel.y>=0.0
	if gliding:
		var descent:float=PlayerMotion.GLIDE_FALL_SPEED
		if _rune_effect("held_flight")>0:descent*=.5
		vel.y=minf(vel.y,descent)
	if _in_bath() and vel.y>200:vel.y=200
	if was_attached and int(p["wall"])!=0 and not dash_contact:vel.y=0.0 if float(p.get("wall_hold_left",0))>0 else PlayerMotion.WALL_SLIDE_SPEED
	var rising:bool=vel.y<0.0
	var approach_x:float=vel.x
	var mushroom_solids:Array[Rect2]=_mushroom_bodies()
	var player_solids:Array=solids if mushroom_solids.is_empty() else solids+mushroom_solids
	var resolved:Dictionary=Coll.move_body(pos,vel,delta,Vector2(34,42),player_solids,4)
	if _in_bath() and absf(vel.x)>1 and absf(resolved["vel"].x)<1:
		for lift in [8.0,18.0,30.0]:
			var raised:Vector2=pos-Vector2(0,lift)
			if solids.any(func(box:Rect2)->bool:return _body_box(raised).intersects(box)):continue
			var step_up:Dictionary=Coll.move_body(raised,vel,delta,Vector2(34,42),player_solids)
			if absf(step_up["vel"].x)>1:resolved=step_up;break
	pos=resolved["pos"];vel=resolved["vel"]
	p["grounded"]=resolved["grounded"]
	var wall_contact:int=int(resolved["wall"])
	var dashed_into:bool=dash_contact and signf(p["dash_dir"].x)==wall_contact
	var wall_allowed:bool=not rising and wall_contact!=0 and _skill("wall") and (float(p["wall_lock"])<=0 or dashed_into) and not bool(p["grounded"]) and not bool(p["slam"])
	var contact:Dictionary=Ledge.contact(pos,wall_contact,solids) if wall_allowed else {}
	p["wall"]=wall_contact if float(contact.get("ratio",0.0))+.000001>=Ledge.ATTACH_RATIO else 0
	if wall_allowed and axis*wall_contact>0 and approach_x*wall_contact>0 and not knocked and contact.has("target"):
		p["pos"]=pos;p["face"]=wall_contact;Ledge.begin(p,contact["target"]);_sound("mantle");p_attack.cancel();pending_attack.clear();charge_timer=0;p["_motion_step"]=false;return
	if p["grounded"]:_restore_ground_movement()

	if pos.x<4:
		pos.x=4
	elif pos.x>_room_size().x-4:
		pos.x=_room_size().x-4
	var exit_drop:bool=p.get("drop_to_lower_room",false) and _key("down") and _in_lower_exit_lane(pos) and not p["grounded"]
	if not exit_drop and p.has("drop_to_lower_room"):p.erase("drop_to_lower_room")
	var landing_y:float=_support_y(old_pos,pos,vel.y,9.0,drop_through_y if drop_through_timer>0 else -10000.0,exit_drop)
	if bool(p["slam"]):_slam_contacts(old_pos,Vector2(pos.x,minf(pos.y,landing_y)))
	if landing_y<INF:
		pos.y=landing_y;vel.y=0;p["grounded"]=true
		p["wall"]=0
		_restore_ground_movement()
		if bool(p["slam"]): _slam_impact(pos)
	if int(p["wall"])!=0:
		# Clamp the real physics velocity, never shift the rendered sprite toward
		# a wall. Both sides use the same feet anchor and the same AABB solver.
		if not was_attached:p["wall_hold_left"]=PlayerMotion.WALL_HOLD_SECONDS;p["wall_slide_age"]=0.0;_sound("wall_attach")
		vel.y=0.0 if float(p.get("wall_hold_left",0))>0 else PlayerMotion.WALL_SLIDE_SPEED;_restore_ground_movement()
		if dashed_into:p["dash_t"]=0;vel.y=0;p["wall_lock"]=0
	if int(p["wall"])==0:p["wall_hold_left"]=0.0;p["wall_slide_age"]=0.0
	if vel.y>=0:p["jump_rise_age"]=-1.0
	if bool(p["grounded"]) and bool(p["slam"]):_slam_impact(pos)
	var ceiling:float=HomeArt.CEILING_Y if screen=="hub" and not trophy_room else 0.0
	if pos.y<ceiling:pos.y=ceiling;vel.y=maxf(0,vel.y)
	if pos.y>_room_size().y+80 and (layout.has("hazard_room") or not room.get("neighbors",{}).has("down")):_hurt_player(2,pos);pos=layout.get("spawn_positions",{}).get("center",Vector2(230,_room_floor()))
	if not was_grounded and not was_slam:p["fall_distance"]=float(p.get("fall_distance",0))+maxf(0,pos.y-old_pos.y)
	if bool(p["grounded"]) and not was_grounded and not was_slam:
		p["landing_left"]=.09
		if not p.has("launch_pending_velocity") and not _in_bath():
			Juice.squash(p,Juice.LAND,draw_clock,.12)
			visual_juice.flash(pos-Vector2(0,2),Vector2.UP,draw_clock,"dust")
		if float(p.get("fall_distance",0))>float(layout.get("tile_height",layout.get("tile_size",96)))*6.0 and not p.has("launch_pending_velocity") and not _in_bath():
			_begin_heavy_landing(pos);vel.x=0
		elif not p.has("launch_pending_velocity"):_sound("land")
		p["fall_distance"]=0.0
	if p.has("launch_pending_velocity"):
		gliding=false
		vel=p["launch_pending_velocity"];p.erase("launch_pending_velocity")
		p["grounded"]=false;p["wall"]=0;p["landing_left"]=0
	p["_motion_step"]=false
	var glide_was_open:bool=p.get("gliding",false)
	p["gliding"]=gliding and not p["grounded"] and int(p["wall"])==0
	if p["gliding"] and not glide_was_open:_sound("glide_open")
	p["pos"]=pos;p["vel"]=vel
	if visual_depth!=null and (dash_contact or (p_attack.is_active() and p_attack.attack.get("kind","")=="pierce")):
		visual_depth.record_grass_wind(old_pos,pos,draw_clock)

func _can_start_lift() -> bool:
	return screen=="game" and bool(p["grounded"]) and not _action_locked() and not _is_healing() and float(p["hurt"])<=0 and float(p.get("dash_t",0))<=0 and not p_attack.is_busy() and not _in_bath()

func _lift_threshold() -> float:
	return LIFT_CHARGE_SECONDS*maxf(.25,1.0-_rune_effect("charge_cut"))

func _release_lift() -> void:
	var charged:bool=p.has("lift_charge") and float(p["lift_charge"])+.00001>=_lift_threshold()
	p.erase("lift_charge")
	if not charged or not _key("up") or not _can_start_lift():return
	p["lift_flying"]=true
	p["lift_age"]=0.0
	p["recoil_left"]=0.0
	p["vel"]=Vector2(0,-LIFT_SPEED)
	p["grounded"]=false
	p["wall"]=0
	p["jump_cut_allowed"]=false
	p["jump_buffer_left"]=0.0
	p["coyote_left"]=0.0
	p["fall_distance"]=0.0
	_sound("flight_boost")
	effects.append({"lift_fog":true,"pos":p["pos"],"vel":Vector2.ZERO,"life":.48,"max":.48,"radius":0.0,"ring":false,"color":Color.WHITE})

func _step_lift(delta:float) -> void:
	p["lift_age"]+=delta
	var from:Vector2=p["pos"]
	var motion:Dictionary=Coll.move_body(from,Vector2(0,-LIFT_SPEED),delta,Vector2(34,42),solids+_mushroom_bodies(),4)
	var at:Vector2=motion["pos"]
	at.y=maxf(42.0,at.y)
	var target:Dictionary={}
	var first:float=INF
	for enemy:Dictionary in enemies:
		if float(enemy["hp"])<=0:continue
		var body:Rect2=_enemy_body_box(enemy)
		var contact_zone:=Rect2(body.position-Vector2(17,0),body.size+Vector2(34,42))
		var contact:float=Coll.segment(from,at,contact_zone)
		if contact<first:
			first=contact
			target=enemy
	if not target.is_empty():
		p.erase("lift_flying")
		p["vel"]=Vector2.ZERO
		p["pos"]=from.lerp(at,first)
		p["lift_invul_left"]=.5
		_sound("lift_hit")
		_hit_enemy(target,LIFT_HIT_DAMAGE,Color("d3eaff"),145.0,from,Vector2.UP)
		_contact_fx("hit_medium",_enemy_body_box(target).get_center(),.25,72.0)
		return
	var blocked:bool=float(motion["vel"].y)>=0.0 or at.y<=42.0
	if blocked:
		p.erase("lift_flying")
		p["vel"]=Vector2.ZERO
		p["pos"]=Vector2(at.x,maxf(42.0,at.y))
	else:
		p["pos"]=at
		p["vel"]=Vector2(0,-LIFT_SPEED)

func _cast_ultimate() -> void:
	if screen!="game" or _action_locked() or p_attack.is_busy() or _ordinary_slash_playing() or float(p["hurt"])>0:return
	if _ultimate_progress()<1.0:_toast("能量全滿才能施放大招");return
	p_attack.begin({"kind":"ultimate","windup":0.0,"active":.24,"recovery":.18})
	if mode=="musou":
		dream.energy=0
		_release_dream_slash()
		return
	p["ultimate_charge"]=0.0
	var center:Vector2=_body_box(p["pos"]).get_center()
	_contact_fx("feather_charge",center,.45,ULTIMATE_RADIUS*2)
	for enemy:Dictionary in enemies:
		var body:Rect2=_enemy_body_box(enemy)
		var closest:Vector2=center.clamp(body.position,body.end)
		if float(enemy["hp"])<=0 or center.distance_squared_to(closest)>ULTIMATE_RADIUS*ULTIMATE_RADIUS:continue
		_hit_enemy(enemy,ULTIMATE_DAMAGE,Color("f6e8ff"),ULTIMATE_KNOCKBACK,center,center.direction_to(body.get_center()))
	_sound("ultimate_cast")
	shake=maxf(shake,11.0)
	_update_hud()

func _ultimate_progress() -> float:
	return float(dream.energy)/Dream.CAPACITY if mode=="musou" else float(p.get("ultimate_charge",0.0))/ULTIMATE_CAPACITY

func _in_lower_exit_lane(at:Vector2) -> bool:
	if screen!="game" or at.y<_room_floor()-15.0:return false
	var lower_exit:Vector2=layout.get("doors",{}).get("down",Vector2.INF)
	return absf(at.x-lower_exit.x)<PORTAL_HEIGHT*.5-17.0

func _can_drop_through(at:Vector2) -> bool:
	for solid:Rect2 in solids:
		if absf(at.y-solid.position.y)<.6 and at.x+17.0>solid.position.x and at.x-17.0<solid.end.x:
			return false
	# Generated exit ledges can be below the nominal room floor.
	var ledges:Array=layout.get("one_way",[]) if at.y>=_room_floor()-15.0 else platforms
	for ledge:Rect2 in ledges:
		if absf(at.y-ledge.position.y)<.6 and at.x+9.0>ledge.position.x and at.x-9.0<ledge.end.x:
			return true
	return false

func _support_y(old:Vector2, next:Vector2, vertical_speed:float, half_width:float=9.0, ignore_y:float=-10000.0, skip_one_way:bool=false) -> float:
	if vertical_speed<0: return INF
	var best:float=INF
	for plat in platforms:
		if absf(plat.position.y-ignore_y)<.5: continue
		if old.y<=plat.position.y+.6 and next.y>=plat.position.y and next.x+half_width>plat.position.x and next.x-half_width<plat.end.x:
			if skip_one_way and layout.get("one_way",[]).has(plat):continue
			best=minf(best,plat.position.y)
	return best

func _restore_ground_movement() -> void:
	p["jumps"]=0;p["air_dash"]=false

func _dash_pressed(interrupting_lift:bool=false) -> void:
	if p.get("lift_flying",false):return
	if float(p.get("heavy_land_left",0))>0 or float(p.get("mantle_left",0))>0:return
	if float(p.get("knockback_t",0))>0 or not life_event.is_empty():return
	if _key("up") and not interrupting_lift:return
	if p_attack.is_busy() and p_attack.phase=="active":return
	var elapsed:float=clock-last_dash_time
	var second:bool=dash_chain_open and elapsed<=.5 and elapsed>=0.0
	if second:
		dash_chain_open=false
		var dir:Vector2=Vector2.DOWN if _key("down") else Vector2(float(p["face"]),0)
		_begin_dash_followup(dir)
		return
	last_dash_time=clock;dash_chain_open=true
	# Down+C only arms the next press: no movement, no animation cancellation.
	if _key("down"):return
	if bool(p["air_dash"]) and not bool(p["grounded"]) and int(p["wall"])==0:dash_chain_open=false;return
	p_attack.cancel();pending_attack.clear();p["impact_root"]=0
	p["dash_dir"]=Vector2(float(p["face"]),0);p["dash_t"]=.16;p["air_dash"]=true;p["wall_lock"]=.1
	Juice.squash(p,Juice.LAUNCH,draw_clock,.15)
	combat_feedback.single_dash(p["pos"]-Vector2(0,24)-Vector2(p["dash_dir"])*12,p["dash_dir"])
	_sound("dash_wind")


func _begin_dash_followup(dir:Vector2) -> void:
	if _rune_effect("single_pierce")<=0 and not _skill("dash_vertical" if dir.y>0 else "dash_horizontal"):_toast("穿刺技能尚未解鎖，請查看技能樹");return
	if float(p["energy"])<1:_toast("穿刺需要1能量");return
	Juice.squash(p,Juice.LAUNCH,draw_clock,.15)
	p["energy"]-=1;p_attack.cancel();pending_attack.clear();p["impact_root"]=0;charge_timer=0
	var definition:Dictionary={"kind":"slam" if dir.y>0 else "pierce","windup":0.0,"active":1.8 if dir.y>0 else .24,"recovery":0.0,"damage":2.0,"range":38.0,"width":40.0,"dir":dir,"direction":"down" if dir.y>0 else ("right" if dir.x>0 else "left"),"color":Color("d3eaff"),"primary":false}
	p_attack.begin(Dream.instant(definition) if mode=="musou" else definition)

func _primary_definition(request:Dictionary) -> Dictionary:
	var def:Dictionary=Data.action_attack(str(request.get("dir","right")),bool(request.get("charged",false)),float(p.get("dash_t",0))>0,int(request.get("combo",combo_index)))
	def["damage"]=float(def["damage"])*Tuning.value("player_damage")*(1.20 if not def.get("charged",false) and float(p.get("power_item_left",0))>0 else 1.0)
	def["recovery"]=float(def["recovery"])*Tuning.value("attack_recovery")
	var haste:float=(1+float(upgrades["haste"])*.07+_rune_effect("haste"))*(1+_rune_effect("haste_mult"))
	def["windup"]=0.0
	def["recovery"]=float(def["recovery"])/haste*phase_multiplier
	if not bool(def["charged"]):
		var rate:float=1.0+_rune_effect("attack_rate")
		def["active"]=float(def["active"])*phase_multiplier/rate
		def["recovery"]=float(def["recovery"])/rate
		def["animation_rate"]=rate
	def["range"]=float(def["range"])*(1+float(upgrades["reach"])*.07+_rune_effect("reach"))*(1+_rune_effect("reach_mult"))
	if mode=="musou":def["damage"]=ceilf(float(def["damage"])*(1+float(upgrades["power"])*.14))
	def["face"]=float(p["face"])
	if mode=="musou":Dream.instant(def)
	return def

func _release_locked() -> bool:
	return p_attack.is_active() and bool(p_attack.attack.get("charged",false)) and bool(p_attack.attack.get("primary",false))

func _movement_locked() -> bool:
	if _healing_guard():return true
	if float(p.get("heavy_land_left",0))>0 or float(p.get("mantle_left",0))>0:return true
	return false if _release_locked() else _action_locked()

func _wind_form_active() -> bool:
	return bool(p.get("slam",false)) or (p_attack.is_active() and p_attack.attack.get("kind","") in ["pierce","slam"])

func _slam_invulnerable() -> bool:
	return bool(p.get("slam",false)) or (p_attack.is_busy() and p_attack.attack.get("kind","") in ["pierce","slam"] and p_attack.phase in ["windup","active"])

func _action_locked() -> bool:
	return p.get("lift_flying",false) or float(p.get("mantle_left",0))>0 or float(p.get("heavy_land_left",0))>0 or _wind_form_active() or _release_locked() or (p_attack.is_active() and p_attack.attack.get("style","")=="heavy" and not p_attack.attack.get("instant_strike",false)) or float(p.get("impact_root",0))>0

func _normal_damage() -> float:
	return float(_primary_definition({"dir":"right","charged":false,"dash_charge":false})["damage"])

func _ordinary_slash_playing() -> bool:
	if player_slashes.is_empty():return false
	var last:Dictionary=player_slashes.back()
	return not last["definition"].get("charged",false) and (draw_clock-float(last["start"]))*float(last["definition"].get("animation_rate",1.0))<SlashArt.DURATION

func _primary_press_blocked() -> bool:
	if _rune_effect("instant_strike")>0:
		return p_attack.is_busy() and not p_attack.attack.get("instant_strike",false)
	return p_attack.is_busy() or _ordinary_slash_playing()

func _begin_primary(request:Dictionary) -> void:
	var ordinary:bool=not request.get("charged",false)
	if ordinary and _primary_press_blocked():_reject_attack("busy");return
	if _action_locked():_reject_attack("locked");return
	var def:Dictionary=_primary_definition(request)
	if ordinary and _rune_effect("instant_strike")>0:
		p_attack.cancel()
		def.merge({"instant_strike":true,"active":.001,"recovery":0.0},true)
	if def.get("charged",false):p["recoil_left"]=0;p["impact_root"]=0
	if p_attack.begin(def):
		if not def["charged"] and def["direction"] in ["left","right"]:combo_index=1-int(def["combo"])
		charge_timer=0
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
		bath.attack(pool,p["pos"]);_sound("water_splash")
	match str(def.get("kind","")):
		"secondary":
			if def.has("salvo"):
				for weapon:Dictionary in def["salvo"]:_emit_weapon(p["pos"]-Vector2(0,24),def.get("dir",Vector2.RIGHT),weapon,true)
			elif def.get("weapon_kind","")=="sword":_sound(AudioCues.attack_cue(def))
			else: _emit_weapon(p["pos"]-Vector2(0,24),def.get("dir",Vector2.RIGHT),def,true)
		"pierce","slam":
			p["slam_speed"]=520.0;p["slam_age"]=0.0;p["slam_land_left"]=0.0;_sound("slam_wind" if def["kind"]=="slam" else "double_dash_wind")
			p["dash_dir"]=def["dir"];p["dash_t"]=float(def["active"]);p["air_dash"]=true
			p["slam"]=def["kind"]=="slam"
		"item_bomb":
			_sound("explosion")
			_contact_fx("explosion_artificial",p["pos"]-Vector2(0,25))
			effects[-1]["fx_extent"]=840.0
			for en in enemies:
				if en["pos"].distance_to(p["pos"])<420 and p_attack.mark_hit(int(en["uid"])):_hit_enemy(en,float(def["damage"]),Color("ffd18d"),400)
			_effect(p["pos"],Color("ffca8d"),420,.6);shake=10
		_:
			if bool(def.get("dash_charge",false)): p["vel"]=_aim_vector()*500
			if def.get("primary",false) and not def.get("charged",false):_sound(AudioCues.primary_cue(def))

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

func _player_strike_box(def:Dictionary) -> Rect2:
	return _attack_box(p["pos"],def,float(p["face"]))

func _attack_volume(box:Rect2,definition:Dictionary) -> Rect2:
	var added:float=box.size.y*(float(definition.get("hitbox_height_mult",1)) - 1)
	return Rect2(box.position-Vector2(0,added*.5),box.size+Vector2(0,added))

func _body_box(pos: Vector2, scale_value: float=1.0) -> Rect2:
	return Rect2(pos-Vector2(17,42)*scale_value,Vector2(34,42)*scale_value)

func _process_player_attack() -> void:
	if not perf_log.active:
		_process_player_attack_profiled_body();return
	var measured:int=Time.get_ticks_usec()
	_process_player_attack_profiled_body()
	perf_log.span("physics.attack",Time.get_ticks_usec()-measured)
func _process_player_attack_profiled_body() -> void:
	if not p_attack.is_active(): return
	var def: Dictionary=p_attack.attack
	var kind: String=str(def.get("kind",""))
	if kind=="secondary" and def.get("weapon_kind","")!="sword": return
	if kind in ["slam","item_bomb","ultimate"]: return
	var hitbox: Rect2=_body_box(p["pos"]).grow(12) if kind=="pierce" else _player_strike_box(def)
	for en in enemies:
		if float(en["hp"])<=0: continue
		var ea = en["attack"]
		if bool(def.get("primary",false)) and ea.is_active() and bool(ea.attack.get("primary",false)) and hitbox.intersects(_attack_box(en["pos"],ea.attack,float(en["face"]))):
			_parry(en)
		if hitbox.intersects(_enemy_body_box(en)) and (p_attack.mark_timed_hit(int(en["uid"]),.5,3) if def.get("charged",false) else p_attack.mark_hit(int(en["uid"]))):
			_hit_enemy(en,float(def.get("damage",1)),Color(def.get("color",Color.WHITE)),float(def.get("knockback",76)),Vector2.INF,_attack_direction(def),true,.07 if def.get("primary",false) else .125)
			if float(def.get("recoil",0))>0:_recoil(float(def["recoil"]),en["pos"],-_attack_direction(def))
			_restore_vital("energy",float(def.get("energy_gain",0))*(1.0+_rune_effect("energy")))
			p["air_dash"]=false
			if str(def.get("direction",""))=="down" and not bool(p["grounded"]):
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
	p["slam"]=false;p["dash_t"]=0.0;p["slam_land_left"]=.125
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
	Juice.squash(p,Juice.LAND,draw_clock,.12)
	visual_juice.flash(at-Vector2(0,3),Vector2.UP,draw_clock)
	hitstop=maxf(hitstop,.075)
	shake=10;_sound("ground_slam")

func _parry(en: Dictionary) -> void:
	if p_attack.attack.get("direction","")=="down":_pogo()
	en["attack"].cancel();en["stun"]=.72
	p["invul"]=maxf(float(p["invul"]),.5);_restore_vital("energy",2)
	var at: Vector2=(p["pos"]+en["pos"])*.5-Vector2(0,25)
	visual_juice.flash(at,_attack_direction(p_attack.attack),draw_clock)
	_effect(at,Color("ffe3a0"),80,.35)
	_contact_fx("parry",at)
	_float(at,"拼刀！ +2 能量",Color("ffe3a0"));hitstop=.055;shake=7;_sound("parry")

func _update_heal(delta: float) -> void:
	if not perf_log.active:
		_update_heal_profiled_body(delta);return
	var measured:int=Time.get_ticks_usec()
	_update_heal_profiled_body(delta)
	perf_log.span("physics.heal",Time.get_ticks_usec()-measured)
func _update_heal_profiled_body(delta: float) -> void:
	if _key("heal") and float(p["energy"])>=3 and float(p["hp"])<float(p["max_hp"]) and not p_attack.is_busy():
		if heal_timer==0:_sound("heal_build")
		heal_timer+=delta
		if rng.randf()<.3: _particles(p["pos"]-Vector2(0,20),Color("8de4ac"),1,25)
		if heal_timer>=.7:
			heal_timer=0;p["energy"]-=3;_restore_vital("hp",1);_float(p["pos"]-Vector2(0,55),"+1",Color("9df3b4"));_sound("heal_finish")
	else: heal_timer=0

func _update_hit_white(delta:float) -> void:
	for en:Dictionary in enemies:
		var remaining:float=float(en.get("flash_left",0))
		if remaining<=0:continue
		en["flash_left"]=maxf(0,remaining-delta)
		if float(en["hp"])<=0 and en["flash_left"]<=0 and corpse_layer!=null:corpse_layer.invalidate()

func _hit_enemy(en:Dictionary,damage:float,color:Color,knockback:float=76,source:Vector2=Vector2.INF,direction:Vector2=Vector2.ZERO,gain_dream:bool=true,impact_duration:float=.125) -> void:
	if float(en["hp"])<=0:return
	if mode=="musou":damage*=dream.damage_factor()
	var heavy:bool=p_attack.is_busy() and p_attack.attack.get("charged",false)
	_sound("impact_heavy" if heavy else "impact_hit")
	en["flash_left"]=HIT_WHITE_SECONDS;en["_impact_time"]=clock
	if int(en.get("model",0))!=4 or float(en.get("boss_impact_guard",0))<=0:
		en["impact_freeze_left"]=impact_duration;en["impact_pose_clock"]=draw_clock
		if int(en.get("model",0))==4:en["boss_impact_guard"]=.45
	var training:bool=en.get("training",false)
	if training:
		en["training_total"]=float(en.get("training_total",0))+damage
		if not en.has("tutorial_respawn"):
			var dummy:Dictionary={"kind":"dummy","gothic_broken":en.get("gothic_broken",false)}
			_prop_impact(dummy,_enemy_body_box(en).get_center(),Vector2(float(p["face"]),0),true,false)
			en["gothic_broken"]=dummy["gothic_broken"]
	else:
		if mode=="musou" and gain_dream and damage>0:dream.hit()
		if damage>0:EnemyVitals.damaged(en,clock)
		en["hp"]-=damage
	en["hurt"]=.2
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
	if impact_duration<.1 and visual_juice!=null:
		visual_juice.flash(contact,impulse,draw_clock)
		shake=maxf(shake,4.5)
	if combat_feedback!=null:combat_feedback.hit(en,contact,impulse)
	if damage>0 and ui!=null and screen=="game":
		ui.feather_collection.burst(CombatFeedback.impact_center(en,contact),impulse,world_transform,low_effects)

	if not training and rng.randf()<clampf(_rune_effect("lifesteal"),0,1):_restore_vital("hp",1);_contact_fx("lifesteal",p["pos"]-Vector2(0,25))
	_float(en["pos"]-Vector2(0,55),"%.1f"%damage,color);shake=maxf(shake,2.2)
	if float(en["hp"])<=0:_enemy_defeated(en)

func _hurt_player(amount:float,source:Vector2,enemy_contact:bool=false,projectile:bool=false) -> bool:
	if lab_mode=="tutorial":return false
	if _slam_invulnerable() or not life_event.is_empty() or float(p["invul"])>0 or float(p.get("lift_invul_left",0))>0 or float(p["shield"])>0 or _healing_guard():return false
	if amount<=0:return false
	amount=maxi(1,roundi(amount))
	p["shield_recharge_left"]=SHIELD_QUIET_SECONDS
	if int(p["shield_cells"])>0:
		p["shield_cells"]-=1
		var broken:bool=int(p["shield_cells"])==0
		ui.flash_shield()
		_effect(_body_box(p["pos"]).get_center(),Color("acddff"),110.0 if broken else 44.0,.45 if broken else .21)
		shake=maxf(shake,26.0 if broken else 3.0)
		_sound("shield_break" if broken else "shield_hit")
		if not projectile:p["invul"]=2.0 if mode=="musou" else .55+_rune_effect("guard")
		if enemy_contact:_knock_player_back(source)
		_update_hud()
		return true
	p.erase("lift_flying");p.erase("lift_charge")
	charge_timer=0;keys["attack"]=false;idle_time=0
	p["mantle_left"]=0
	p["hp"]=maxi(0,int(p["hp"])-int(amount));p["flash_left"]=HIT_WHITE_SECONDS;p["hurt"]=.25;p["invul"]=2.0 if mode=="musou" else (.55+_rune_effect("guard"))*1.5
	_hit_flash(p["pos"]-Vector2(0,22),amount,Color("ffad9b"))
	if not (mode=="musou" and not revive_used and int(p["hp"])<=0) and not (_release_locked() or (p_attack.is_active() and bool(p_attack.attack.get("super_armor",false)))):
		_knock_player_back(source)
	hitstop=maxf(hitstop,.045);_float(p["pos"]-Vector2(0,65),"受傷 -%d"%int(amount),Color("ffb0a4"));shake=maxf(shake,9.0);_sound("hurt")
	if float(p["hp"])<=0:_death()
	return true

func _knock_player_back(source:Vector2) -> void:
	var away:float=signf(p["pos"].x-source.x)
	if away==0:away=-float(p["face"])
	p["knockback_t"]=KNOCKBACK_TIME
	p["knockback_dir"]=away
	p["vel"]=Vector2(away*CONTACT_KNOCKBACK/KNOCKBACK_TIME,-100)
	p.erase("lift_flying")
	p.erase("lift_charge")
	p_attack.cancel();pending_attack.clear();jump_request=false;charge_timer=0;heal_timer=0;p["slam"]=false;p["dash_t"]=0

func _death() -> void:
	_return_trial(false)
	if not life_event.is_empty():return
	_clear_keys();p_attack.cancel();p["dash_t"]=0;p["slam"]=false;p["mantle_left"]=0;p["invul"]=5.0
	var first_down:bool=not revive_used
	if first_down and mode=="musou":
		revive_used=true;injured=true;_sync_vitals();p["hp"]=p["max_hp"];p["invul"]=2.0;p["hurt"]=0;p["knockback_t"]=0
		dream.injure();shake=maxf(shake,20);hitstop=maxf(hitstop,.08);_sound("dream_burst")
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
	_sound("death")
	life_event={"kind":"injury" if first_down else "death","elapsed":0.0,"origin":p["pos"],"room":current_room,"face":p["face"],"trail":[],"velocity":Vector2(-float(p["face"])*440,-280)}
	_toast("首次倒下：重傷後醒來，這一局再倒下便會死亡" if first_down else "羽翼碎落……選一枚符文返回安全屋，其餘背包留在發光羽毛")

func _update_enemies(delta:float,movement_delta:float=-1) -> void:
	if not perf_log.active:
		_update_enemies_profiled_body(delta,movement_delta);return
	var measured:int=Time.get_ticks_usec()
	_update_enemies_profiled_body(delta,movement_delta)
	perf_log.span("physics.enemies",Time.get_ticks_usec()-measured)

func _spawn_boss_reinforcements(roster:Array, count:int, elite:bool, random:RandomNumberGenerator) -> void:
	var biome:String=str(_ecology()["id"])
	for index in count:
		var definition:Dictionary=MonsterRoster.elite(random.randi_range(0,5)) if elite else MonsterRoster.regular(biome,random.randi_range(0,MonsterRoster.REGULAR_COUNT-1))
		var edge:float=minf(440.0,_room_size().x*.28)
		var center:float=lerpf(edge,_room_size().x-edge,float(index)/maxi(1,count-1))
		var spawn:=Vector2.INF
		for attempt in ceili(_room_size().x/40.0)*2:
			var offset_x:float=ceili(attempt*.5)*40.0*(1.0 if attempt%2==1 else -1.0)
			var x:float=center+offset_x
			if x<96 or x>_room_size().x-96:continue
			definition["pos"]=Vector2(x,_room_floor())
			var candidate:Vector2=_enemy_spawn(definition,104.0 if definition.get("air_lunge",false) else 0.0)
			if not candidate.is_finite():continue
			definition["pos"]=candidate
			var body:Rect2=_enemy_body_box(definition).grow(8)
			if roster.any(func(actor:Dictionary)->bool:return float(actor["hp"])>0 and body.intersects(_enemy_body_box(actor))):continue
			spawn=candidate
			break
		if not spawn.is_finite():continue
		spawn_serial+=1
		var health:float=(float(definition["hp"])+float(room["map_index"])*.5)*(3.0 if elite else 1.0)*Tuning.value("enemy_hp")
		definition.merge({"uid":200000+spawn_serial,"pos":spawn,"spawn_home":spawn,"spawn_platform":0,"ecology_id":biome,"hp":health,"max_hp":health,"speed":float(definition["speed"])*Tuning.value("enemy_speed"),"vel":Vector2.ZERO,"face":-1.0,"hurt":0.0,"stun":0.0,"cooldown":1.0+index*.15,"attack":Attack.new()},true)
		roster.append(definition)

func _boss_summoning(en:Dictionary,delta:float) -> bool:
	en["summon_check_left"]=float(en.get("summon_check_left",15.0))-delta
	var cast_left:float=float(en.get("summon_cast_left",0))
	if cast_left>0.0:
		en["summon_cast_left"]=maxf(0,cast_left-delta)
		if en["summon_cast_left"]<=0.0:_spawn_boss_reinforcements(enemies,3,false,rng)
		return true
	if float(en["summon_check_left"])>0.0:return false
	en["summon_check_left"]=15.0
	var elite_count:int=0
	for enemy in enemies:
		if enemy.get("elite",false) and float(enemy["hp"])>0:elite_count+=1
	if elite_count>=2:return false
	en["attack"].cancel()
	en["charge_phase"]="idle";en["charge_left"]=0.0
	en["motion_dash_left"]=0.0;en["motion_dash_wait"]=0.0
	en["vel"]=Vector2.ZERO;en["summon_cast_left"]=.8;_sound(AudioCues.actor_cue(en,"summon","boss_summon"))
	_float(en["pos"]-Vector2(0,110),"召喚援軍",Color("ffbd89"))
	return true

func _update_enemies_profiled_body(delta:float,movement_delta:float=-1) -> void:
	if movement_delta<0:movement_delta=delta*world_speed
	var frozen:bool=freeze_timer>0
	var initial_room:int=current_room
	var enemy_solids:Array=solids+_mushroom_bodies()
	var world:Array=enemy_solids+platforms
	for index in enemies.size():
		if screen!="game" or current_room!=initial_room:return
		var en:Dictionary=enemies[index]
		if en.has("boss_impact_guard"):en["boss_impact_guard"]=maxf(0.0,float(en["boss_impact_guard"])-delta)
		if float(en["hp"])>0 and float(en.get("frost_left",0))>0:
			en["frost_left"]=maxf(0.0,float(en["frost_left"])-delta)
			continue
		if float(en["hp"])>0 and float(en.get("impact_freeze_left",0))>0:
			en["impact_freeze_left"]=maxf(0.0,float(en["impact_freeze_left"])-delta)
			continue
		if en.has("tutorial_respawn"):
			if float(en["hp"])<=0:
				en["tutorial_respawn"]=maxf(0,float(en["tutorial_respawn"])-delta)
				if en["tutorial_respawn"]<=0:
					en["hp"]=en["max_hp"];en["pos"]=en["anchor"];en["vel"]=Vector2.ZERO
					for key in ["hurt","stun","flash_left","push_left","impact_freeze_left"]:en[key]=0.0
					en["tutorial_patrol_age"]=0.0
					_sound("dummy_respawn")
			else:
				for key in ["hurt"]:en[key]=maxf(0,float(en.get(key,0))-delta)
				var age:float=float(en.get("tutorial_patrol_age",0))+movement_delta
				en["tutorial_patrol_age"]=age
				var previous:Vector2=en["pos"]
				var patrol:Vector2=en.get("tutorial_patrol",Vector2.ZERO)
				en["pos"]=Vector2(en["anchor"])+Vector2(sin(age*1.45)*patrol.x,sin(age*2.1)*patrol.y)
				_keep_enemy_in_room(en,Vector2(en["anchor"]))
				var travel:Vector2=en["pos"]-previous
				en["vel"]=travel/maxf(.0001,movement_delta)
				if absf(travel.x)>.01:en["face"]=signf(travel.x)
			continue
		if float(en["hp"])<=0:continue
		Motion.prepare(en)
		if int(en["model"])==4:
			_confine_boss(en)
			BossDirector.enrage(en)
			if mode=="musou" and room.get("type","")=="boss":
				if not frozen and _boss_summoning(en,delta):continue
				if float(en.get("summon_cast_left",0))>0.0:continue
		for key in ["hurt","stun","cooldown"]:en[key]=maxf(0,float(en.get(key,0))-delta)
		var atk=en["attack"]
		var toward:Vector2=p["pos"]-en["pos"]
		var engaged:bool=not en.get("training",false) and _in_aggro(en)
		var body_size:Vector2=MonsterMotion.body_size(en)
		if not engaged and atk.is_busy():atk.cancel()
		if en.has("wall_spawn_face"):
			var launch:float=en["wall_spawn_face"]
			en.erase("wall_spawn_face")
			en["vel"]=Vector2(launch*180,-230)

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
		elif en.get("training",false):vel=Vector2(0,minf(800.0,vel.y+GRAVITY*movement_delta))
		else:
			var previous_charge:String=en.get("charge_phase","idle")
			vel=Motion.velocity(en,p["pos"],movement_delta,rng,grounded,world,body_size,engaged,support)
			if engaged and previous_charge!="active" and en.get("charge_phase","idle")=="active":
				Juice.squash(en,Juice.LAUNCH,draw_clock,.15)
				var cue:String="boss_move_"+str(en.get("biome","")) if int(en["model"])==4 else AudioCues.actor_cue(en,"rush","enemy_ram")
				_sound(cue)
			if engaged and grounded and vel.y<-140 and Motion.current(en)=="jump":
				Juice.squash(en,Juice.LAUNCH,draw_clock,.15)
				_sound(AudioCues.actor_cue(en,"jump","boss_jump" if int(en["model"])==4 else "enemy_jump"))
		# A ram is one deliberately telegraphed attack, not a second movement attack.
		if not frozen and float(en["stun"])<=0 and atk.is_active() and atk.attack.get("ram",false):
			vel.x=float(atk.attack.get("ram_direction",en["face"]))*float(atk.attack.get("ram_speed",340))
		# Facing is held through the hysteresis zone and telegraphed charges.
		var flying:bool=Motion.airborne(en)
		if not flying and grounded and vel.y>=0:
			var margin:float=20.0*float(en["scale"])
			if (vel.x<0 and en["pos"].x+vel.x*movement_delta<support.position.x+margin) or (vel.x>0 and en["pos"].x+vel.x*movement_delta>support.end.x-margin):vel.x=0
		var old:Vector2=en["pos"]
		var falling:bool=vel.y>75.0
		var resolved:Dictionary=Coll.move_body(old,vel,movement_delta,body_size,world if flying else enemy_solids)
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
			if falling and not grounded and (ground<INF or bool(resolved.get("grounded",false))) and not en.get("training",false):
				Juice.squash(en,Juice.LAND,draw_clock,.12)
				if view_rect.has_point(en["pos"]):visual_juice.flash(Vector2(en["pos"])-Vector2(0,2),Vector2.UP,draw_clock,"dust")
			en["pos"].y=maxf(55+body_size.y,en["pos"].y)
		if en.get("render_face",en["face"])!=en["face"]:en["turn_left"]=.25
		else:en["turn_left"]=maxf(0,float(en.get("turn_left",0))-delta)
		en["render_face"]=en["face"]
		en["vel"]=vel
		if int(en["model"])==4:_confine_boss(en)
		_keep_enemy_in_room(en,old)
		if float(en.get("contact_damage",CONTACT_DAMAGE))>0 and _enemy_body_box(en).intersects(_body_box(p["pos"])):
			_hurt_player(float(en.get("contact_damage",CONTACT_DAMAGE)),en["pos"],true)
			if screen!="game" or current_room!=initial_room:return
		if frozen:continue
		if atk.is_active() and not bool(atk.attack.get("emitted",false)):
			atk.attack["emitted"]=true
			if atk.attack.get("primary",false) and not atk.attack.get("ram",false) and view_rect.has_point(en["pos"]):
				var face:=Vector2(float(en["face"]),0)
				var origin:Vector2=Vector2(en["pos"])+Vector2(face.x*8,float(atk.attack.get("origin_y",-30)))
				visual_juice.flash(origin,face,draw_clock,"smear",clampf(float(atk.attack.get("range",75))*.65,32.0,145.0))
			_sound(AudioCues.enemy_attack_cue(en,atk.attack,int(atk.attack.get("audio_slot",-1))))
			if atk.attack.get("poison_cloud",false):
				poison_clouds.append({"pos":Vector2(en["pos"])+Vector2(float(en["face"])*48,-26),"left":3.0,"hostile":true})
			elif atk.attack.get("library_kind","")=="trap":_emit_traps(en,atk.attack)
			elif atk.attack.get("library_kind","")=="explosion":_explode(en["pos"]-Vector2(0,25),float(atk.attack["range"]),float(atk.attack["damage"]),150,false,{},str(atk.attack.get("group","biological")))
			elif not bool(atk.attack.get("primary",true)):
				_emit_weapon(en["pos"]+Vector2(0,float(atk.attack.get("origin_y",-30))),atk.attack.get("aim",toward.normalized()),atk.attack,false)
		if atk.is_active() and bool(atk.attack.get("primary",false)):
			if not atk.attack.get("ram",false) and p_attack.is_active() and bool(p_attack.attack.get("primary",false)) and _player_strike_box(p_attack.attack).intersects(_attack_box(en["pos"],atk.attack,float(en["face"]))):
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
	def["audio_slot"]=en.get("attacks",[]).find(definition)
	def["aim"]=(target-origin).normalized()
	def["target"]=en["pos"]+(p["pos"]-en["pos"]).limit_length(float(def.get("range",500)))
	for key in ["windup","active","recovery"]:def[key]=float(def[key])*phase_multiplier/maxf(.1,float(en.get("attack_speed",1)))
	if mode=="musou" and int(en.get("model",0))!=4 and not def.get("ram",false) and not def.get("poison_cloud",false):Dream.instant(def)
	if not str(def.get("boss_tell","")).is_empty():def["windup"]=maxf(.42,float(def["windup"]))
	if en["attack"].begin(def):
		if not str(def.get("boss_tell","")).is_empty():_sound(AudioCues.actor_cue(en,"warning","boss_warning"))
		en["cooldown"]=float(def["windup"])+float(def["active"])+float(def["recovery"])+float(def.get("attack_cooldown",1.1))/maxf(.1,float(en.get("attack_speed",1)))

func _enemy_body_box(en:Dictionary) -> Rect2:
	var body:Vector2=MonsterMotion.body_size(en)
	return Rect2(en["pos"]-Vector2(body.x*.5,body.y),body)

func _enemy_spawn(en:Dictionary,flight_lift:float=0.0) -> Vector2:
	match str(en["spawn_surface"]):
		"flight":return _air_spawn(Vector2(en["pos"])-Vector2(0,flight_lift),MonsterMotion.body_size(en))
		"wall":return _fit_enemy_wall(en)
		"ground":return _fit_enemy_ground(en)
	return Vector2.INF

func _fit_enemy_wall(en:Dictionary) -> Vector2:
	var desired:Vector2=en["pos"]
	var body:Vector2=MonsterMotion.body_size(en)
	var best:=Vector2.INF
	var distance:float=INF
	for wall:Rect2 in solids:
		if wall.size.y<maxf(96.0,body.y+20.0):continue
		var y:float=clampf(desired.y-55,wall.position.y+body.y+4,wall.end.y-4)
		for face in [-1.0,1.0]:
			var at:=Vector2((wall.end.x if face>0 else wall.position.x)+face*(body.x*.5+.03),y)
			if at.x<body.x*.5+28 or at.x>_room_size().x-body.x*.5-28 or at.y<55+body.y:continue
			if at.distance_to(desired)>=distance or not _spawn_space_clear(at,body):continue
			best=at
			distance=at.distance_to(desired)
			en["wall_spawn_face"]=face
	return best

func _spawn_space_clear(at:Vector2,body:Vector2) -> bool:
	if not at.is_finite():return false
	var full_body:=Rect2(at-Vector2(body.x*.5,body.y),body)
	if not Rect2(Vector2.ZERO,_room_size()).encloses(full_body):return false
	var box:=full_body.grow(-.01)
	for rock:Rect2 in platforms+solids:
		if box.intersects(rock):return false
	for spike:Rect2 in layout.get("spike_rects",[]):
		if box.intersects(spike.grow(.5)):return false
	for door:Dictionary in doors:
		if at.distance_to(door["pos"])<180:return false
	return true

func _air_spawn(anchor:Vector2,body:Vector2) -> Vector2:
	var half:float=maxf(50,body.x*.5+12)
	var top:float=maxf(65,body.y+12)
	for offset_y in [65,110,160,35,210,-40]:
		for offset_x in [0,55,-55,110,-110,165,-165]:
			var at:=Vector2(clampf(anchor.x+offset_x,half,_room_size().x-half),clampf(anchor.y-offset_y,top,_room_floor()-60))
			if _spawn_space_clear(at,body):return at
	return Vector2.INF

func _fit_enemy_ground(en:Dictionary) -> Vector2:
	var desired:Vector2=en["pos"];var body:Vector2=MonsterMotion.body_size(en)
	var best:=Vector2.INF;var distance:float=INF
	var edge:float=400.0 if int(en.get("model",0))==4 else 28.0+body.x*.5
	for surface:Rect2 in platforms+solids:
		if surface.position.y<55+body.y or absf(surface.position.y-desired.y)>192:continue
		var left:float=maxf(edge,surface.position.x+body.x*.5+1)
		var right:float=minf(_room_size().x-edge,surface.end.x-body.x*.5-1)
		if left>right:continue
		var x:float=clampf(desired.x,left,right)
		if absf(x-desired.x)>192:continue
		var at:=Vector2(x,surface.position.y)
		if not _spawn_space_clear(at,body):continue
		var cost:float=absf(at.x-desired.x)+absf(at.y-desired.y)*2
		if cost<distance:distance=cost;best=at
	return best

func _keep_enemy_in_room(enemy:Dictionary,previous:Vector2) -> void:
	var bounds:=Rect2(Vector2.ZERO,_room_size())
	var body:Rect2=_enemy_body_box(enemy)
	if bounds.encloses(body):return
	var home:Vector2=enemy.get("spawn_home",previous)
	var size:Vector2=body.size
	enemy["pos"]=home.clamp(Vector2(size.x*.5,size.y),Vector2(bounds.size.x-size.x*.5,bounds.size.y))
	enemy["vel"]=Vector2.ZERO
	enemy["push_left"]=0.0

func _enemy_support(en:Dictionary) -> Rect2:
	for surface in platforms+solids:
		if absf(en["pos"].y-surface.position.y)<1 and en["pos"].x>=surface.position.x and en["pos"].x<=surface.end.x:
			return surface
	return Rect2()

func _enemy_begin(en:Dictionary,ranged:bool) -> void:
	for def in en.get("attacks",[]):
		if bool(def.get("primary",false))!=ranged:_start_enemy_attack(en,def);return

func _emit_weapon(at:Vector2,dir:Vector2,def:Dictionary,from_player:bool) -> void:
	if from_player:_sound(AudioCues.attack_cue(def))
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
		var radius:float=float(def.get("size",9 if kind=="throw" else 6))*(1.20 if from_player else 1.0)
		var spawn:Vector2=at
		spawn.y=minf(spawn.y,_room_floor()-radius-2)
		if spread==0 and shots>1 and def.get("style_id","")!="root_wave":spawn+=direction.orthogonal()*(float(i)-float(shots-1)*.5)*radius*2.1
		var velocity:Vector2=heading*float(def.get("speed",550))
		var gravity:float=float(def.get("gravity",600)) if path=="arc" or kind=="throw" else 0
		if gravity!=0:velocity.y+=float(def.get("launch_y",-260))
		var distance:float=float(def.get("range",900))
		projectiles.append({"pos":spawn,"vel":velocity,"sprite":sprite,"from_player":from_player,"damage":float(def.get("damage",3)),"life":float(def.get("lifetime",distance/maxf(1,velocity.length())+1)),"color":def.get("color",Color.WHITE),"kind":kind,"radius":radius,"gravity":gravity,"pierce":bool(def.get("piercing",false)) or (from_player and _rune_effect("pierce")>0),"hits":{},"bounces":int(def.get("bounces",0)),"distance_left":distance,"style_id":str(def.get("style_id",kind)),"boss_biome":str(def.get("boss_biome","")),"visual_id":str(def.get("visual_id","")),"group":str(def.get("group","weapon" if from_player else "biological")),"elapsed":0.0,"return_after":float(def.get("return_after",.7 if path=="return" else 0)),"origin":spawn,"launch_angle":direction.angle(),"base_velocity":velocity,"wave_amplitude":float(def.get("wave_amplitude",0)) if path=="sine" or def.get("style_id","")=="dew_bubble" else 0.0,"wave_frequency":float(def.get("wave_frequency",4)),"knockback":float(def.get("knockback",76)),"explode_on_hit":bool(def.get("explode_on_hit",false)),"explosion_radius":float(def.get("explosion_radius",80)),"parryable":bool(def.get("parryable",kind=="flying_slash")),"owner_uid":int(def.get("owner_uid",-2)),"weapon_id":str(def.get("id","")),"homing":def.get("weapon_kind","")=="homing","ground_fire":bool(def.get("ground_fire",false)),"fire_size":float(def.get("explosion_radius",100)),"dream_slash":bool(def.get("dream_slash",false))})
	_effect(at,Color(def.get("color",Color.WHITE)),28,.15)

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
	return projectile_surfaces

func _rebuild_projectile_surfaces() -> void:
	# Pass-through traversal ledges are supports, never horizontal shot barriers.
	var pass_through:Array=layout.get("one_way",[])
	projectile_surfaces=solids+platforms.filter(func(surface:Rect2)->bool:return not pass_through.has(surface))

func _update_projectiles(delta:float) -> void:
	if not perf_log.active:
		_update_projectiles_profiled_body(delta);return
	var measured:int=Time.get_ticks_usec()
	_update_projectiles_profiled_body(delta)
	perf_log.span("physics.projectiles",Time.get_ticks_usec()-measured)

func _straight_shot_left_room(pr:Dictionary, bounds:Rect2) -> bool:
	if pr.get("trap_carrier",false) or pr.get("homing",false) or int(pr.get("bounces",0))>0:
		return false
	if float(pr.get("return_after",0))>0 or float(pr.get("wave_amplitude",0))!=0 or float(pr.get("gravity",0))!=0:
		return false
	var at:Vector2=pr["pos"]
	var velocity:Vector2=pr["vel"]
	return ((at.x<bounds.position.x and velocity.x<=0) or (at.x>bounds.end.x and velocity.x>=0)
		or (at.y<bounds.position.y and velocity.y<=0) or (at.y>bounds.end.y and velocity.y>=0))

func _try_projectile_riposte(enemy:Dictionary,shot:Dictionary,old:Vector2,next:Vector2,radius:float) -> bool:
	var attack=enemy["attack"]
	var center:Vector2=_enemy_body_box(enemy).get_center()
	if attack.is_busy() or float(enemy.get("cooldown",0))>0 or float(enemy.get("stun",0))>0 or float(enemy.get("frost_left",0))>0 or float(enemy.get("impact_freeze_left",0))>0:return false
	var incoming:Vector2=shot["vel"]
	if incoming.dot(center-old)<=0 or not _segment_hits_box(old,next,_enemy_body_box(enemy).grow(radius+33)):return false
	_start_enemy_attack(enemy,Combat.attack("slash",{"windup":0.0,"active":.13,"recovery":.36,"range":95.0,"damage":1.0}))
	var direction:Vector2=(Vector2(p["pos"])-Vector2(0,22)-next).normalized()
	shot["from_player"]=false
	shot["vel"]=direction*maxf(320.0,incoming.length())
	shot["base_velocity"]=shot["vel"]
	shot["pos"]=next+direction*8
	shot["hits"]={}
	shot["owner_uid"]=enemy["uid"]
	shot["homing"]=false
	shot["return_after"]=0.0
	shot["distance_left"]=maxf(400,float(shot.get("distance_left",0)))
	shot["life"]=maxf(.7,float(shot["life"]))
	_block_effect(next,"reflect")
	return true

func _update_projectiles_profiled_body(delta:float) -> void:
	if projectiles.is_empty():return
	var room_bounds:=Rect2(Vector2.ZERO,_room_size())
	var trail_view:=view_rect.grow(250)
	var initial_room:int=current_room
	var world:Array=_projectile_surfaces()
	for pr in projectiles:
		if float(pr["life"])<=0:continue
		if _straight_shot_left_room(pr,room_bounds.grow(320+ProjectileReadability.visual_radius(pr))):
			pr["life"]=0
			continue
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
		if trail_view.has_point(next):
			ProjectileReadability.record(pr,old,next,delta)
			if combat_feedback!=null and ProjectileReadability.uses_dust(pr):
				combat_feedback.projectile_trail(pr,world_speed)
		elif pr.has("trail_points"):
			pr.erase("trail_points");pr.erase("trail_times")
			if combat_feedback!=null:combat_feedback.finish_trail(pr)
			pr.erase("trail_id")
		pr["distance_left"]=float(pr.get("distance_left",INF))-old.distance_to(next)
		if pr.get("trap_carrier",false):
			if not pr.get("destroyed",false) and (wall_hit or pr["life"]<=0 or pr["distance_left"]<=0):_settle_trap(pr);pr["life"]=0
			continue
		if bool(pr["from_player"]):
			for en in enemies:
				if en["hp"]<=0:continue
				if en.get("projectile_riposte",false) and _try_projectile_riposte(en,pr,old,next,radius):
					break
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
				_hit_props(Rect2(next-Vector2.ONE*radius,Vector2.ONE*radius*2),float(pr["damage"]),1,old,pr["hits"])
				_damage_traps(Rect2(old.min(next),old.max(next)-old.min(next)).grow(radius),float(pr["damage"]),not pr.get("dream_slash",false))
		else:
			var blocked:bool=false
			if _rune_effect("orbit_shield")>0 or float(p.get("shield_item_left",0))>0:
				for i in 2:
					var shield:Vector2=p["pos"]-Vector2(0,24)+Vector2.from_angle(draw_clock*2+i*PI)*52
					if _segment_hits_box(old,next,Rect2(shield-Vector2.ONE*(12+radius),Vector2.ONE*(24+radius*2))):pr["life"]=0;blocked=true;_block_effect(shield,"orbit_shield_intercept");break
			if not blocked and p_attack.is_active() and bool(p_attack.attack.get("primary",false)) and _segment_hits_box(old,next,_block_box().grow(radius)):
				if pr.get("parryable",false):
					for en in enemies:
						if int(en["uid"])==int(pr.get("owner_uid",-2)):_parry(en);break
				if _rune_effect("reflect")>0:
					pr["from_player"]=true;pr["hits"]={};pr["vel"]=-pr["vel"];pr["base_velocity"]=pr["vel"];pr["pos"]=p["pos"]+Vector2(float(p["face"])*45,-25);pr["distance_left"]=maxf(200,float(pr["distance_left"]));pr["return_after"]=0
					pr.erase("trail_points");pr.erase("trail_times")
				else:pr["life"]=0
				blocked=true;_projectile_impact(pr);_block_effect(next,"reflect" if _rune_effect("reflect")>0 else "block")
			if not blocked and int(p["shield_cells"])>0:
				var shield_center:Vector2=_body_box(p["pos"]).get_center()
				if Geometry2D.get_closest_point_to_segment(shield_center,old,next).distance_to(shield_center)<=SHIELD_RADIUS+radius:
					if _hurt_player(float(pr["damage"]),next,false,true):
						pr["life"]=0
						blocked=true
						_block_effect(next,"orbit_shield_intercept")
			if not blocked and not pr["hits"].has(-1) and _segment_hits_box(old,next,_body_box(p["pos"]).grow(radius)):
				pr["hits"][-1]=true;_projectile_impact(pr);_hurt_player(float(pr["damage"]),pr["pos"],false,true);_projectile_explosion(pr)
				if not pr["pierce"]:pr["life"]=0
		if screen!="game" or current_room!=initial_room or not life_event.is_empty():return
		if wall_hit and float(pr["life"])>0:
			if int(pr.get("bounces",0))>0:
				var contact:Dictionary=Explosion.contact(pr["pos"],pr["vel"],world,radius)
				var normal:Vector2=contact.get("normal",Vector2.LEFT)
				pr["vel"]=Vector2(pr["vel"]).bounce(normal);pr["base_velocity"]=pr["vel"];pr["pos"]+=normal*1.0;pr["bounces"]-=1;_sound("projectile_bounce")
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
		projectiles.append({"pos":start,"vel":velocity,"launch_angle":Vector2(target-start).angle(),"radius":float(def.get("size",16))*1.20 if def.get("from_player",false) else 8.0,"life":flight,"elapsed":0.0,"gravity":gravity,"distance_left":1000.0,"trap_carrier":true,"landing":landing,"visual_id":str(def.get("visual_id","")),"hazard_visual_id":str(def.get("hazard_visual_id","")),"weapon_id":str(def.get("id","")),"definition":def.duplicate(true),"group":str(def.get("group","biological")),"from_player":bool(def.get("from_player",false)),"owner_uid":en["uid"],"color":def["color"],"kind":"throw","sprite":"fruit","hits":{},"pierce":false,"damage":0.0,"bounces":0,"boss_biome":str(def.get("boss_biome",""))})

func _update_hazards(delta:float) -> void:
	if not perf_log.active:
		_update_hazards_profiled_body(delta);return
	var measured:int=Time.get_ticks_usec()
	_update_hazards_profiled_body(delta)
	perf_log.span("physics.hazards",Time.get_ticks_usec()-measured)

func _update_hazards_profiled_body(delta:float) -> void:
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
	if en.has("tutorial_respawn"):
		_sound(AudioCues.actor_cue(en,"defeat","enemy_defeat"))
		en["tutorial_respawn"]=3.0
		return
	if en.get("corpse_created",false):return
	_sound(AudioCues.actor_cue(en,"defeat","boss_defeat" if int(en.get("model",0))==4 else "enemy_defeat"))
	en["corpse_created"]=true
	var body:Dictionary=CorpseField.create(en)
	body["hit_actor"]=en
	corpses.append(body);room["corpses"]=corpses
	if corpse_layer!=null:corpse_layer.invalidate()
	if lab_mode=="tutorial":return
	kills+=1
	var gold: int=150+int(room.get("map_index",0))*25 if int(en["model"])==4 else 3
	if int(en["model"])==4:
		for i in 5:_drop("coin",en["pos"]+Vector2((i-2)*85,-25),gold/5)
	else:_drop("coin",en["pos"]-Vector2(0,15),gold)
	if rng.randf()<.1: _drop("item",en["pos"]-Vector2(25,20),rng.randi_range(0,Data.ITEMS.size()-1))
	if rng.randf()<(.32 if mode=="musou" else .07): _drop("heal",en["pos"]+Vector2(25,-20),1)
	if rng.randf()<.24:
		var major_chance:float=.75 if layout.get("hazard_room","")=="spike_islands" else .15
		_drop("rune",en["pos"]+Vector2(10,-45),_random_rune_index(major_chance))
	if int(en["model"])==4 or rng.randf()<(.10 if en.get("elite",false) or int(en["model"])==3 else .02):
		_drop("weapon",en["pos"]+Vector2(15,-35),Arsenal.random_index(rng))
	if rng.randf()<_rune_effect("leech"): _restore_vital("hp",1)
	if int(en["model"])==4:
		_drop("rune",en["pos"]-Vector2(35,40),Data.RUNES.size()+rng.randi_range(0,Data.STRONG_RUNES.size()-1))
		room["boss_defeated"]=true
	_check_room_clear()

func _check_room_clear() -> void:
	if room.get("type","") not in ["combat","elite","boss"] or room.get("cleared",false):return
	if enemies.any(func(enemy:Dictionary)->bool:return float(enemy["hp"])>0 and not enemy.get("training",false)):return
	room["cleared"]=true
	room_clear_slow_left=ROOM_CLEAR_SLOW_SECONDS
	_sound("room_clear")
	if room["type"]=="combat":return
	hazards.clear()
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
	if not perf_log.active:
		_update_drops_profiled_body(delta);return
	var measured:int=Time.get_ticks_usec()
	_update_drops_profiled_body(delta)
	perf_log.span("physics.drops",Time.get_ticks_usec()-measured)

func _update_drops_profiled_body(delta:float) -> void:
	if drops.is_empty():return
	var target:Vector2=p["pos"]-Vector2(0,20)
	var magnet_radius:float=125+_rune_effect("magnet")
	var cleared:bool=bool(room.get("cleared",false))
	var picked_gold:int=0
	var bounds:=Rect2(Vector2(18,0),_room_size()-Vector2(36,0))
	for drop in drops:
		if bool(drop["taken"]):continue
		if drop.get("display_only",false) or drop.get("gift",false):
			drop["pos"]=drop.get("display_anchor",drop["pos"]);drop["vel"]=Vector2.ZERO;continue
		if not drop.has("radius"):drop["radius"]=Coins.RADIUS if drop["kind"]=="coin" else 18.0
		Coins.initialize(drop,Vector2(rng.randf_range(-180,180),rng.randf_range(-350,-190)) if not drop.has("vel") else Vector2.ZERO)
		drop["impact_cd"]=maxf(0,float(drop.get("impact_cd",0))-delta)
		var collected:bool=false
		if cleared:
			collected=_step_clear_loot_vortex(drop,target,delta)
		else:
			if drop["kind"]=="coin" and float(drop["age"])>.35 and Vector2(drop["pos"]).distance_squared_to(target)<magnet_radius*magnet_radius:
				drop["sleeping"]=false;drop["vel"]=drop["vel"].move_toward((target-drop["pos"]).normalized()*450,delta*1200)
			var nearby:Array=[] if drop.get("sleeping",false) and Vector2(drop["vel"]).length_squared()<.01 else coin_field.query(drop["pos"],drop["vel"],delta,float(drop["radius"])+3)
			if Coins.step(drop,delta,nearby,bounds) and drop["kind"]=="coin" and float(drop["impact_cd"])<=0:
				drop["impact_cd"]=.15;_particles(drop["pos"],Color("efdba3"),4,65);_sound("coin")
			collected=Vector2(drop["pos"]).distance_squared_to(target)<36*36 and float(drop.get("age",0))>.35
		if collected:
			drop["taken"]=true
			if drop["kind"]=="coin":picked_gold+=int(drop["value"])
			else:_give_drop(str(drop["kind"]),int(drop["value"]))
	if not cleared:CoinField.collide(drops)
	if picked_gold>0:run_coins+=picked_gold;_sound("coin_collect")
	drops=drops.filter(func(drop:Dictionary)->bool:return not bool(drop["taken"]))
	room["drops"]=drops

func _step_clear_loot_vortex(drop:Dictionary,target:Vector2,delta:float) -> bool:
	var seed:float=float(drop.get("seed",0.0))
	var radius:float=52.0+24.0*fposmod(seed*.37,1.0)
	var duration:float=.57+.13*fposmod(seed*.83,1.0)
	drop["rotation"]=float(drop.get("rotation",0.0))+delta*8.0
	if not drop.has("orbit_angle"):
		# The entry point follows the player and stays on the loot's side.
		var offset:Vector2=Vector2(drop["pos"])-target
		var angle:float=offset.angle() if offset.length_squared()>.01 else seed
		var entry:Vector2=target+Vector2.from_angle(angle)*radius
		var speed:float=move_toward(float(drop.get("attract_speed",280.0)),1800.0,4000.0*delta)
		drop["attract_speed"]=speed
		var arrival_time:float=Vector2(drop["pos"]).distance_to(entry)/speed
		drop["pos"]=Vector2(drop["pos"]).move_toward(entry,speed*delta)
		if arrival_time>delta:return false
		drop["orbit_angle"]=angle
		delta-=arrival_time
	var elapsed:float=float(drop.get("orbit_elapsed",0.0))+delta
	drop["orbit_elapsed"]=elapsed
	var progress:float=clampf(elapsed/duration,0.0,1.0)
	var angle:float=float(drop["orbit_angle"])+TAU*pow(progress,1.35)
	var pull:float=smoothstep(.70,1.0,progress)
	drop["pos"]=target+Vector2.from_angle(angle)*radius*(1.0-pull)
	return progress>=1.0

func _give_drop(kind: String, value: int) -> void:
	_sound(str({"coin":"coin_collect","heal":"heal_finish","rune":"rune_collect","weapon":"weapon_collect","growth":"weapon_collect","upgrade":"rune_collect","item":"item_collect"}.get(kind,"item_collect")))
	match kind:
		"coin":run_coins+=value
		"heal": _restore_vital("hp",1);_float(p["pos"]-Vector2(0,50),"+1 生命",Color("a9ecc1"))
		"rune":
			var id:String=Data.all_runes()[value]["id"]
			if lab_mode.is_empty():_collect_trophy("runes",id)
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
		"energy":
			p["energy"]=p["max_energy"]
			if mode!="musou":p["ultimate_charge"]=ULTIMATE_CAPACITY
		"shield":p["shield_item_left"]=60.0
		"power":p["power_item_left"]=120.0
		"freeze":
			for enemy:Dictionary in enemies:
				if float(enemy["hp"])>0 and Vector2(enemy["pos"]).distance_to(p["pos"])<=900:
					enemy["frost_pose_clock"]=_enemy_pose_clock(enemy)
					enemy["frost_left"]=2.0
		"shock":
			var center:Vector2=p["pos"]
			for enemy:Dictionary in enemies:
				if float(enemy["hp"])<=0 or Vector2(enemy["pos"]).distance_to(center)>640/_view_zoom():continue
				var away:Vector2=(Vector2(enemy["pos"])-center).normalized()
				enemy["push_left"]=.55;enemy["push_velocity"]=Vector2(away.x*1050,-200)
				enemy["push_base_y"]=0.0
			_effect(center,Color("d7faff"),640/_view_zoom(),.35)

	_sound("heal_finish" if item["id"]=="heal" else "item_"+str(item["id"]))
	_effect(p["pos"]-Vector2(0,20),item["color"],100,.45)
	_toast("施放："+item["name"])
	if from_bag and open_bag:_show_bag()
	_update_hud()

func new_run(chosen_mode: String, seed_value: int=-1) -> void:
	room_clear_slow_left=0.0
	if lab_mode=="tutorial":_leave_lab()
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
	p.erase("drop_to_lower_room")
	p.erase("lift_charge");p.erase("lift_flying")
	if visual_juice!=null:visual_juice.clear()
	player_slashes.clear()
	dash_chain_open=false
	if ui!=null:ui.feather_collection.clear()
	if perf_log.active:perf_log.mark(_performance_context(),"room_change")
	_return_trial(false);bath.reset();spring_particles.clear();poison_clouds.clear()
	if dream_visual!=null:dream_visual.clear_waves()
	if not room.is_empty():
		room["enemies"]=enemies;room["drops"]=drops;room["corpses"]=corpses
	if walker!=null:walker.reset();walker.reset_turn(float(p["face"]))
	if current_room>=0 and current_room!=id:_sound("portal_enter")
	current_room=id;room=tower["rooms"][id]
	room["ecology"]=Ecology.from_stage(int(room["map_index"]))
	if room["type"]=="start":last_checkpoint=id
	if room_music!=null:room_music.select(str(room["type"]),str(room["ecology"]["id"]),bool(room.get("spring",false)))
	if not bool(room.get("visited",false)):
		visited_count+=1;room["visited"]=true;_update_skills()
	meta["best_map"]=maxi(int(meta["best_map"]),int(room["map_index"])+1)
	if not room.has("layout"):
		room["layout"]=Layout.generate(room,int(tower["seed"]))
		var forced_hazard:String=room.get("practice_hazard","")
		if not forced_hazard.is_empty():
			HazardRoom.prepare(room["layout"],id,forced_hazard)
			if room["layout"].has("hazard_room"):room["fountain"]=false
	layout=room["layout"]
	if room.get("fountain",false) and not layout.has("fountain_pos"):preload("res://scripts/spring_v33.gd").prepare(layout)
	NewBiome.prepare(layout,int(layout.get("seed",0)))
	if room.get("type","")=="merchant" and not room.has("stock"):
		room["stock"]=Sanctuary.stock(int(room["map_index"]))
		for item:Dictionary in room["stock"]:item["pos"]+=_furniture_offset()
	platforms.assign(layout["platforms"])
	solids.assign(layout.get("solids",[]))
	coin_field.rebuild(platforms,solids)
	_rebuild_projectile_surfaces()
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

		if layout.has("hazard_room"):
			plan.clear()
			for i in 3:
				plan.append({"model":3,"pos":Vector2(_room_size().x*(.29+i*.20),_room_floor()*.66),"platform":0,"flying_elite":true})
		if room["type"]=="elite":
			for entry:Dictionary in plan:entry["model"]=3
			if plan.is_empty():
				for guard in 3:plan.append({"model":3,"pos":Vector2(_room_size().x*(.3+.2*guard),_room_floor()),"platform":0})
		plan=plan.filter(func(entry:Dictionary)->bool:
			if int(entry["model"])==4:return true
			for door in doors:
				if Vector2(entry["pos"]).distance_to(door["pos"])<180:return false
			return true)
		if mode=="musou" and room["type"]!="boss":plan=Dream.expand_plan(plan,layout,int(room["map_index"]),int(layout["seed"]),doors)
		for i in plan.size():
			var model:int=int(plan[i]["model"])
			var spawn_rng:=RandomNumberGenerator.new();spawn_rng.seed=int(layout["seed"])+i*827+spawn_serial*3571
			var def:Dictionary=Combat.boss(["underground","grass","trunk","branches","canopy","sky"][int(room["map_index"])]) if model==4 else (MonsterRoster.elite(int(room["map_index"])) if model==3 else MonsterRoster.regular(str(biome["id"]),int(plan[i].get("roster_variant",(i+id)%MonsterRoster.REGULAR_COUNT))))
			if plan[i].get("flying_elite",false):
				# Use winged species with their authored flight animations.
				def=NewRoster.create("sky",spawn_rng.randi_range(3,4),int(room["map_index"])) if spawn_rng.randf()<.5 else MonsterRoster.elite(spawn_rng.randi_range(4,5))
			elif model!=4 and not def.get("air_lunge",false) and spawn_rng.randf()<.5:
				def=NewRoster.create(str(biome["id"]),spawn_rng.randi_range(3,4) if model==3 else spawn_rng.randi_range(0,2),int(room["map_index"]))
			if room["type"]!="elite" and model!=4 and model!=3 and i==0 and int(layout["seed"])%3==0 and not def.has("v55_row") and not def.get("air_lunge",false):def=Arms.cute_wanderer(spawn_rng)
			if model==4:
				for attack in def["attacks"]:attack["damage"]*=2;attack["knockback"]=120.0
			def["uid"]=id*100+i+1
			if model==4:room["boss_id"]=def["id"];def["summon_check_left"]=15.0
			def["pos"]=plan[i]["pos"];def["spawn_platform"]=plan[i]["platform"]
			if model!=4:def["biome"]=biome["id"]
			def["ecology_id"]=biome["id"]
			if not def.has("roster_id"):def["contact_damage"]=0.0 if def.get("passive",false) else CONTACT_DAMAGE

			def["pos"]=_enemy_spawn(def,140.0 if model==4 else 104.0 if def.get("air_lunge",false) else 0.0)
			if not Vector2(def["pos"]).is_finite():continue
			def["spawn_home"]=def["pos"]
			if model!=4 and doors.any(func(door:Dictionary)->bool:return def["pos"].distance_to(door["pos"])<180):continue
			def["vel"]=Vector2.ZERO;def["face"]=-1.0;def["stun"]=0.0;def["hurt"]=0.0;def["cooldown"]=1.0+i*.15;def["attack"]=Attack.new()
			def["hp"]=float(def["hp"])+float(room["map_index"])*(.5 if model!=4 else 10)
			if model==4:def["hp"]*=2.0
			if def.get("elite",false):def["hp"]*=3.0
			def["hp"]*=Tuning.value("enemy_hp");def["speed"]*=Tuning.value("enemy_speed")
			def["max_hp"]=def["hp"]
			room["enemies"].append(def)
		if room["type"]=="boss":
			var guard_rng:=RandomNumberGenerator.new()
			guard_rng.seed=int(layout["seed"])+4251
			_spawn_boss_reinforcements(room["enemies"],6,true,guard_rng)
		if room["type"] in ["merchant","start"] and lab_mode!="tutorial":
			var dummy:Dictionary=MonsterRoster.regular(str(biome["id"]),0)
			var anchor:=_furniture_offset()+Vector2(870 if room["type"]=="start" else 1360,1050)
			dummy.merge({"training":true,"passive":true,"contact_damage":0.0,"uid":id*100+98,
				"pos":anchor,"vel":Vector2.ZERO,"face":-1.0,"hurt":0.0,"stun":0.0,
				"cooldown":0.0,"max_hp":dummy["hp"],"attack":Attack.new(),"training_total":0.0},true)
			var dummy_at:Vector2=_enemy_spawn(dummy)
			if dummy_at.is_finite():
				dummy["pos"]=dummy_at
				dummy["spawn_home"]=dummy_at
				room["enemies"].append(dummy)

	if not room.has("props"):
		room["props"]=_make_props()
		for rect:Rect2 in layout.get("spike_rects",[]):
			room["props"].append({"kind":"spikes","pos":rect.get_center(),"rect":rect,"hurt":0.0})
		if room["type"] in ["combat","elite"] and not room.get("spring",false):
			var avoid:Array=layout["spawn_positions"].values()
			for door:Dictionary in doors:avoid.append(door["pos"])
			for prop:Dictionary in room["props"]:
				if prop["kind"] in ["launcher","chest","fountain"]:avoid.append(prop["pos"])
			for spike:Rect2 in layout.get("spike_rects",[]):avoid.append(spike.get_center())
			room["props"].append_array(Stones.spawn(layout,platforms+solids,solids,avoid))
	props.assign(room["props"])
	var loaded_enemies:Array[Dictionary]=[]
	loaded_enemies.assign(room["enemies"])
	var loaded_drops:Array[Dictionary]=[]
	loaded_drops.assign(room["drops"])
	enemies=loaded_enemies;drops=loaded_drops
	if room["type"]=="start" and (room.get("refresh_gift",false) or (int(room["map_index"])==0 and not room.get("gift_given",false))):
		_refresh_checkpoint_gift()
	var loaded_corpses:Array[Dictionary]=[];loaded_corpses.assign(room.get("corpses",[]));corpses=loaded_corpses
	if corpse_layer!=null:corpse_layer.invalidate()
	projectiles.clear();hazards.clear();effects.clear();
	if combat_feedback!=null:combat_feedback.clear()
	if atmosphere!=null:
		atmosphere.room_bounds=_room_size();atmosphere.configure(str(room["ecology"]["id"]),int(layout["seed"]),true,room["type"]=="merchant",room["type"] in ["start","merchant","reward"] or room.get("spring",false),layout,_background_rect())
	p_attack.cancel();p["slam"]=false;p["dash_t"]=0
	var spawn: Vector2=layout["spawn_positions"].get(from_dir,layout["spawn_positions"]["center"])
	drop_through_timer=0.0
	p["pos"]=spawn;p["vel"]=Vector2.ZERO;p["grounded"]=true;p["wall"]=0;p["invul"]=maxf(.5,float(p["invul"]));_restore_ground_movement()
	room_cooldown=.6;camera_pos=_camera_target(spawn);last_motion_pos=spawn
	atmosphere.depth_origin=camera_pos;atmosphere.depth_origin_ready=true
	_save_meta();_update_hud();_invalidate_scene()

func _interact() -> void:
	if _action_locked() or room_cooldown>0:return
	if screen=="hub":
		_home_interact();return
	if screen!="game":return
	var focus:Dictionary=_game_station()
	match str(focus.get("kind","")):
		"tutorial":_show_tutorial_station(focus["index"])
		"product":_show_merchant(focus["index"])
		"merchant":_show_merchant()
		"chest":_open_chest(focus["prop"])
		"gift":_claim_gift()
		"reward":_show_reward(focus["index"])
		"victory":_complete_run()
		"aid":_first_aid()
		"wardrobe":_show_shop()
		"mail","energy_infinite","dummy","forge","reforge":_show_prep(focus["kind"])

func _game_station() -> Dictionary:
	if screen!="game" or room_cooldown>0 or _action_locked() or not life_event.is_empty() or not merchant_trial.is_empty() or (ui!=null and ui.is_panel_open()):return {}
	var at:Vector2=p["pos"]
	if lab_mode=="tutorial":
		var index:int=_nearby_tutorial_station()
		if index>=0:return {"kind":"tutorial","index":index,"pos":_tutorial_station_position(index)}
	if room.get("type","")=="merchant":
		var stock:Array=room.get("stock",[])
		var product:int=Sanctuary.nearest_stock(stock,at)
		if product>=0:return {"kind":"product","index":product,"pos":Vector2(stock[product]["pos"])+Vector2(0,124)}
	var nearest:float=110
	var chosen:Dictionary={}
	for prop:Dictionary in props:
		if prop["kind"] not in ["chest","merchant"] or prop.get("used",false):continue
		var distance:float=at.distance_to(prop["pos"])
		if distance<nearest:
			nearest=distance
			chosen=prop
	if not chosen.is_empty():return {"kind":chosen["kind"],"pos":chosen["pos"],"prop":chosen}
	for drop:Dictionary in drops:
		var anchor:Vector2=Vector2(drop["pos"])+Vector2(0,90)
		if drop.get("gift",false) and not drop.get("taken",false) and anchor.distance_to(at)<90:return {"kind":"gift","pos":anchor}
	var reward:int=_nearest_reward()
	if reward>=0:return {"kind":"reward","index":reward,"pos":_reward_position(reward)}
	if room.get("type","")=="boss" and int(room.get("map_index",0))==5 and bool(room.get("cleared",false)):
		var finish:=Vector2(_room_size().x*.5,_room_floor())
		if at.distance_to(finish)<150:return {"kind":"victory","pos":finish}
	if _is_start():
		var station:String=_nearest_station()
		if not station.is_empty():
			for prop:Dictionary in props:
				if prop["kind"]==station:return {"kind":station,"pos":prop["pos"]}
	return {}

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
	if not audio_enabled or combat_audio == null or id.is_empty():
		return
	var stream: AudioStream = sounds.get(id)
	if stream == null:
		stream = AudioCues.cue_stream(id)
		if stream != null:
			sounds[id] = stream
	combat_audio.play_cue(id, stream)

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
	if not perf_log.active:
		_update_visual_effects_profiled_body(delta);return
	var measured:int=Time.get_ticks_usec()
	_update_visual_effects_profiled_body(delta)
	perf_log.span("physics.effects",Time.get_ticks_usec()-measured)
func _update_visual_effects_profiled_body(delta:float) -> void:
	if combat_feedback!=null:combat_feedback.step(delta)
	_step_fragments(delta)
	for e in effects:
		e["life"]-=delta;e["pos"]+=e["vel"]*delta
		if not bool(e["ring"]) and not e.has("beam") and not e.has("lightning") and not e.has("boss_fx") and not e.has("combat_fx") and not e.has("ground_wind") and not e.has("wind_burst") and not e.has("water_attack") and not e.has("fire_ember") and not e.has("prop_flash") and not e.has("lift_fog"):e["vel"].y+=180.0*delta
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
		"lab_page":
			if lab_mode=="practice":
				practice_page=str(payload)
				_show_practice()
		"lab_room":
			if lab_mode=="practice":
				var parameters:Dictionary=practice_rd_settings.duplicate()
				parameters["room_kind"]=str(payload)
				_close_panel()
				_regenerate_practice(parameters)
		"lab_terrain":
			if lab_mode=="practice":
				_close_panel()
				_open_practice_rd()
		"lab_enter":_enter_practice()
		"tutorial_guide":_show_tutorial()
		"tutorial_demo":
			if lab_mode=="tutorial":_tutorial_demo(str(payload))
		"tutorial_rune":
			if lab_mode=="tutorial":
				for rune in Data.all_runes():
					var id:String=rune["id"]
					if id!=str(payload):continue
					bag_runes[id]=int(bag_runes.get(id,0))+1
					_toast("取得 "+str(rune["name"])+" ×1")
					break
		"tutorial_reset":
			if lab_mode=="tutorial":_leave_lab();_enter_practice(true)
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
		"start_rogue":
			if screen!="hub" or _at_rogue_gate():new_run("rogue")
			else:_close_panel();_toast("肉鴿入口在鳥巢中上方，下砍蘑菇反彈後再二段跳")
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
		"display_fit":
			display_fit="cover" if str(payload)=="cover" else "contain"
			_apply_display_fit();_save_settings();_show_settings()
		"display_zoom":
			display_zoom=_normalize_display_zoom(payload)
			_apply_display_fit();_update_safe_interface();_save_settings()
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
		"background_volume":_set_audio_volume("Background",float(payload));_save_settings()
		"sfx_volume":_set_audio_volume("Effects",float(payload));_save_settings()
		"audio":audio_enabled=not audio_enabled;_save_settings();_show_settings()
		"mute":audio_enabled=not audio_enabled;_save_settings();_update_hud()
		"performance_panel":
			if perf_bridge!=null:
				_close_panel()
				perf_bridge.open()
		"effects":low_effects=not low_effects;terrain.invalidate();_show_settings()
		"timing_slower":phase_multiplier=1.6 if phase_multiplier<1.2 else 1.0;_show_settings()
		"reward":_claim_reward(int(payload))
		"minimap":_cycle_map()
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
	if tower.get("maps",[]).is_empty():_toast("開始冒險後可查看全塔地圖");return
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
		{"text":"預設方向鍵移動；空白鍵短按小跳、長按大跳，空中再次按可二段跳，下降時持續按住可展翅滑翔。上牆吸附1秒後緩滑，視同落地，按跳躍可離牆。"},
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

func _update_hud() -> void:
	if not perf_log.active:
		_update_hud_profiled_body();return
	var measured:int=Time.get_ticks_usec()
	_update_hud_profiled_body()
	perf_log.span("process.hud",Time.get_ticks_usec()-measured)

func _update_hud_profiled_body() -> void:
	if ui==null:return
	var phase_name:String=p_attack.phase
	ui.update_hud({"hp":p.get("hp",5),"max_hp":p.get("max_hp",5),"energy":p.get("energy",3),"max_energy":p.get("max_energy",6),"hp_recovery":float(p.get("hp_recovery",0)),"energy_recovery":float(p.get("energy_recovery",0)),"hp_recovering":heal_timer>0 or float(p.get("hp_recovery",0))>0,"energy_recovering":float(p.get("energy_recovery",0))>0 or (float(p.get("energy",1))<1 and empty_energy_time>0),"injured":injured,"coins":int(meta["coins"]) if screen=="hub" else run_coins,"mode":"新手教學" if lab_mode=="tutorial" else ("鳥巢" if screen=="hub" else _mode_name()),"weapon":Data.PRIMARY[weapon_index]["name"],"sub":_secondary()["name"] if not bag_weapons.is_empty() else "尚未裝備","phase":phase_name,"phase_progress":p_attack.progress(),"phase_remaining":maxf(0,float(p_attack.attack.get(p_attack.phase,0))-p_attack.elapsed),"show_attack":screen=="game","ultimate_key":Bindings.label(int(key_bindings["ultimate"])),"lift_progress":float(p.get("lift_charge",-1.0))/_lift_threshold(),"dash_key":Bindings.label(int(key_bindings["dash"])),"audio_enabled":audio_enabled,"sub_count":0 if bag_weapons.is_empty() else (bag_weapons.size() if mode=="musou" else int(_secondary()["count"])),"sub_icon":UI.Icons.secondary(_secondary()) if not bag_weapons.is_empty() else "","cycle_key":Bindings.label(int(key_bindings["cycle"])),"in_start":_is_start()})
	var timed_effects:=PackedStringArray()
	var frost_left:float=0.0
	for enemy:Dictionary in enemies:
		if float(enemy.get("hp",0.0))>0:frost_left=maxf(frost_left,float(enemy.get("frost_left",0.0)))
	for effect:Array in [
		["力量",p.get("power_item_left",0.0)],
		["羽盾道具",p.get("shield_item_left",0.0)],
		["防護",p.get("shield",0.0)],
		["夢境爆發 ×2",dream.rage_left if mode=="musou" else 0.0],
		["清房慢動作",room_clear_slow_left],
		["凍結",frost_left],
		["護盾回復",p.get("shield_recharge_left",0.0)],
	]:
		if float(effect[1])>0.0:timed_effects.append("%s  %d 秒"%[effect[0],ceili(float(effect[1]))])
	var ultimate_full:bool=screen=="game" and _ultimate_progress()>=1.0
	if ultimate_full and not p.get("ultimate_audio_full",false):_sound("ultimate_ready")
	p["ultimate_audio_full"]=ultimate_full
	ui.update_ultimate_hud(_ultimate_progress(),screen=="game")
	ui.update_shield_hud(int(p.get("shield_cells",SHIELD_BASE_CELLS)),int(p.get("max_shield",SHIELD_BASE_CELLS)),timed_effects,screen=="game")
	ui.update_trial(merchant_trial,room.get("stock",[]),run_coins)
	ui.update_quickbar(bag_items,Data.ITEMS)
	ui.quickbar.visible=screen=="game" and not ui.is_panel_open() and not minimap_open

func _biome_name() -> String:
	if screen=="hub":return "鳥巢與樹"
	return str(_ecology()["name"])

func _background_rect() -> Rect2:
	if _is_start():
		return preload("res://scripts/scene_art_v33.gd").safehouse_rect(str(_ecology()["id"]),_room_size(),_room_floor())
	return preload("res://scripts/depth_style_v32.gd").backdrop_rect()

func _paint_background(canvas:CanvasItem) -> void:
	if screen=="hub":backdrop.material=null;HomeArt.background(canvas,render_camera.y);return
	if _is_start():
		backdrop.material=preload("res://scripts/depth_style_v32.gd").material(str(_ecology()["id"]),"far",low_effects);preload("res://scripts/scene_art_v33.gd").safehouse(canvas,str(_ecology()["id"]),_room_size(),_room_floor());return
	var id:String=str(_ecology()["id"])
	backdrop.material=preload("res://scripts/depth_style_v32.gd").material(id,"far",low_effects)
	canvas.draw_rect(_background_rect(),Color("193751") if id=="sky" else (Color("173e31") if id=="trunk" else Color("493521")))
	BiomeArt.layer(canvas,id,"far",_background_rect())
	if room.get("type","")=="merchant":BiomeArt.layer(canvas,"merchant","far",_background_rect())

func _paint_terrain(canvas:CanvasItem) -> void:
	if screen=="hub":
		pass # The home branch belongs to the newly painted home background.
		return
	if layout.has("maze_grid") or layout.has("hazard_room") or lab_mode=="tutorial":
		var id:String=str(_ecology()["id"])
		if not NewBiome.draw_terrain(canvas,id,layout,solids,terrain_region,low_effects):
			for solid:Rect2 in solids:BiomeArt.terrain(canvas,id,solid)
			for plat:Rect2 in layout.get("one_way",[]):BiomeArt.terrain(canvas,id,plat,true)
			Overhang.shade_fallback(canvas,solids,terrain_region)
		if show_hitboxes:
			for solid:Rect2 in solids:canvas.draw_rect(solid,Color(1,.3,.1,.5),false,1)
		return
	if layout.get("single_screen",false):SanctuaryArt.background(canvas,room)
	for plat in platforms:Art.draw_platform(canvas,plat,_height(),show_hitboxes)
	_draw_terrain_details(canvas)
	Overhang.shade_fallback(canvas,platforms,terrain_region)


func _draw() -> void:
	if not perf_log.active:
		_draw_profiled_body();return
	var measured:int=Time.get_ticks_usec()
	_draw_profiled_body()
	perf_log.span("draw.main",Time.get_ticks_usec()-measured)

func _draw_profiled_body() -> void:
	if font==null:return
	if screen=="hub":_draw_hub();return
	draw_set_transform_matrix(world_transform)
	for door in doors:_draw_door(door)
	var focus:Dictionary=_game_station()
	_draw_props(focus)
	_draw_fragments()
	if not focus.is_empty():
		draw_set_transform_matrix(world_transform)
		HomeArt.station_light(self,focus["pos"])
		if focus["kind"]!="tutorial":
			var label:String="按 %s 互動"%_tutorial_key("up")
			var width:float=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
			_text(Vector2(focus["pos"])+Vector2(-width*.5,-116),label,15,Color("fff0c6"))
	if room.get("type","")=="boss" and int(room.get("map_index",0))==5 and bool(room.get("cleared",false)):
		var finish:=Vector2(_room_size().x*.5,_room_floor())
		_effect_static(finish-Vector2(0,50),Color("fff0a5"),70)
		_text(finish-Vector2(45,140),"遠行終點",22,Color("fff0a5"))
	var nearest:float=145.0
	drop_label_target=-1
	for i in drops.size():
		var dist:float=drops[i]["pos"].distance_to(p["pos"]-Vector2(0,20))
		if dist<nearest: nearest=dist;drop_label_target=i
	for i in drops.size():
		if view_rect.has_point(drops[i]["pos"]): _draw_drop(drops[i],i==drop_label_target)
	for en in enemies:
		if float(en["hp"])<=0 or not view_rect.has_point(en["pos"]):continue
		if en.get("training",false):continue
		var atk=en["attack"]

		MonsterDesign.draw_charge(self,en,clock,world_transform)
		_draw_attack(en["pos"]+Vector2(0,5),atk,float(en["face"]),false)
		_draw_enemy_warning(en)
		if int(en["model"])!=4:EnemyVitals.draw(self,en,_enemy_body_box(en),clock)
	_draw_player_body()
	if room.get("fountain",false) and layout.has("fountain_pos"):
		preload("res://scripts/spring_v33.gd").draw_water(self,layout["fountain_pos"],str(_ecology()["id"]),world_transform,bath,draw_clock)
	elif room.get("spring",false):
		bath.draw(self,_active_pool(),world_transform,draw_clock)
	if _is_healing():FX.fitted(self,"heal_guard",0,Rect2(p["pos"]-Vector2(35,65),Vector2(70,75)),world_transform,"right","idle",Color(.7,1,.8,.65),clock)
	if p.has("lift_charge"):_draw_lift_charge()
	_draw_attack(p["pos"],p_attack,float(p["face"]),true)
	for cloud:Dictionary in poison_clouds:
		var fog:=Color(.75,.29,.8,.67) if cloud.get("hostile",false) else Color(.55,.82,.30,.64)
		SkillArt.draw(self,SkillArt.POISON,1.0-float(cloud["left"])/3.0,Rect2(Vector2(cloud["pos"])-Vector2(58,38),Vector2(116,76)),fog)

	if float(p.get("power_item_left",0))>0:
		draw_texture_rect(preload("res://assets/v55/effects/aura.svg"),Rect2(Vector2(p["pos"])-Vector2(45,67),Vector2(90,90)),false,Color(1,.22,.12,.78))

	if float(p["shield"])>0:draw_texture_rect(preload("res://assets/v55/effects/aura.svg"),Rect2(Vector2(p["pos"])-Vector2(44,67),Vector2(88,88)),false,Color(.69,.79,1,.8))
	for hazard in hazards:
		if hazard.get("fire",false):
			GroundFire.draw(self,hazard,clock,world_transform);continue
		if view_rect.has_point(hazard["pos"]) and not MonsterDesign.draw_hazard(self,hazard,clock,world_transform) and not FX.hazard(self,hazard,clock,world_transform):BossVisual.hazard(self,hazard,clock,world_transform,show_hitboxes)
	for pr in projectiles:
		if not view_rect.grow(160).has_point(pr["pos"]):continue
		ProjectileReadability.draw_trail(self,pr,world_transform,low_effects);ProjectileReadability.draw_cue(self,pr,world_transform)
		var visual:Dictionary=pr.duplicate(false);visual["radius"]=ProjectileReadability.visual_radius(pr)
		if WeaponArt.Animated.has(str(pr.get("weapon_id",""))) or (pr.get("from_player",false) and WeaponArt.texture(str(pr.get("weapon_id","")),true)!=null):
			WeaponArt.draw(self,str(pr["weapon_id"]),pr["pos"],pr["vel"],float(visual["radius"]),true,world_transform,float(pr.get("elapsed",0)),float(pr.get("launch_angle",0)));draw_set_transform_matrix(world_transform);continue
		if not MonsterDesign.draw_projectile(self,visual,clock,world_transform) and not FX.projectile(self,visual,clock,world_transform) and not BossVisual.projectile(self,visual,clock,world_transform) and not Sprites.projectile(self,visual,clock,world_transform):
			var size:float=float(visual["radius"])*2.3
			draw_texture_rect(preload("res://assets/v55/effects/spark.svg"),Rect2(Vector2(pr["pos"])-Vector2.ONE*size*.5,Vector2.ONE*size),false,pr["color"])
	for e in effects:
		if not view_rect.has_point(e["pos"]):continue
		if _draw_prop_impact(e):continue
		var c:Color=e["color"];c.a=clampf(float(e["life"])/float(e["max"]),0,1)
		if e.has("beam"):preload("res://scripts/laser_art_v38.gd").draw(self,e,world_transform)
		elif e.has("lightning"):
			var end:Vector2=e["end"]
			var points:=PackedVector2Array([e["pos"]]);var tangent:Vector2=(end-e["pos"]).normalized().orthogonal()
			for i in range(1,8):points.append(Vector2(e["pos"]).lerp(end,float(i)/8)+tangent*sin(i*7.3)*10)
			points.append(end);draw_polyline(points,Color(c,.4),9,true);draw_polyline(points,Color(1,1,1,c.a),2,true)
		elif e.has("explosion_v16"):Explosion.draw(self,e,world_transform)
		elif e.has("lift_fog"):_draw_lift_fog(e["pos"],1.0,c.a,true)
		elif e.has("ground_wind"):Wind.impact(self,e["pos"],1-c.a,world_transform)
		elif e.has("boss_fx"):BossVisual.impact(self,e,world_transform)
		elif e.has("combat_fx"):
			var extent:float=float(e.get("fx_extent",65))
			var alpha:float=Explosion.OPACITY if str(e["combat_fx"]).begins_with("explosion_") else 1.0
			var progress:float=1-float(e["life"])/float(e["max"])
			if e["combat_fx"]=="feather_charge":FX.frame(self,"feather_charge",progress,e["pos"],world_transform,1.0,extent)
			else:FX.fitted(self,e["combat_fx"],progress,Rect2(e["pos"]-Vector2.ONE*extent*.5,Vector2.ONE*extent),world_transform,"right","",Color(1,1,1,alpha))
		elif bool(e["ring"]):
			var radius:float=float(e["radius"])
			SkillArt.draw_ring(self,1.0-c.a,Rect2(Vector2(e["pos"])-Vector2.ONE*radius,Vector2.ONE*radius*2),e["color"])
		else:
			var size:float=float(e["radius"])*c.a*2.0
			draw_texture_rect(preload("res://assets/v55/effects/spark.svg"),Rect2(Vector2(e["pos"])-Vector2.ONE*size*.5,Vector2.ONE*size),false,c)
	for f in floaters:_text(f["pos"],f["text"],16,Color(f["color"],minf(1,float(f["life"])*2)))
	if show_hitboxes:
		draw_rect(_body_box(p["pos"]),Color("9ff5de"),false,1)
		for en in enemies:
			if en["hp"]>0:draw_rect(_enemy_body_box(en),Color("f6aa82"),false,1)
	if lab_mode=="tutorial":_draw_tutorial_stations(focus)
	draw_set_transform(Vector2.ZERO)
	if combat_feedback!=null:combat_feedback.draw_screen(self,world_transform,display_safe.size.x)
	_draw_boss_bar()
	_draw_enemy_edge_indicators()
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
	var atk=en["attack"]
	if atk.phase!="windup":return
	var body:Rect2=_enemy_body_box(en)
	Juice.warning(self,Vector2(body.get_center().x+float(en["face"])*body.size.x*.20,body.position.y+body.size.y*.35),atk.progress())
	if not show_hitboxes and int(en.get("model",0))!=4:return
	var def:Dictionary=atk.attack
	if BossDirector.draw_tell(self,en,def,atk.progress(),world_transform,world_speed):return
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

func _draw_lift_charge() -> void:
	var progress:float=clampf(float(p["lift_charge"])/_lift_threshold(),0.0,1.0)
	_draw_lift_fog(p["pos"],progress,1.0)

func _draw_lift_fog(feet:Vector2,progress:float,opacity:float,release:bool=false) -> void:
	draw_set_transform_matrix(world_transform)
	var spread:float=(1.0-opacity)*40.0 if release else 0.0
	var count:int=11 if low_effects else 18
	for i in count:
		var angle:float=draw_clock*(3.1+progress*2.0)+float(i)*TAU/count
		var phase:float=fposmod(draw_clock*.9+float(i)*.27,1.0)
		var wide:float=32.0+29.0*progress+spread+float(i%3)*7.0
		var at:Vector2=feet+Vector2(cos(angle)*wide,-12.0+sin(angle)*9.0-phase*8.0)
		var mist:float=sin(PI*phase)*opacity*(.38+progress*.62)
		for layer in 4:
			var radius:float=(5.0+float(layer)*3.2)*(1.0+phase*.5)
			Art._ellipse(self,at,Vector2(radius*2.1,radius*.45),Color(.77,.88,.93,mist*(.105-float(layer)*.021)))

func _draw_player_body() -> void:
	var anim:String="limp" if injured else ("rest" if idle_time>=5 else "idle")
	if absf(p["vel"].x)>30:anim="limp" if injured else "run"
	if not bool(p["grounded"]):anim="jump_up" if p["vel"].y < 0 else ("jump_down" if p["vel"].y>70 else "jump_apex")
	elif float(p.get("landing_left",0))>0 and not injured:anim="land"
	if not p["grounded"] and p.get("gliding",false) and _key("jump"):anim="glide"
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
	var body_scale:Vector2=Juice.pose(p,draw_clock,anim=="idle")
	if body_scale!=Vector2.ONE:
		player_base=world_transform*Transform2D(0,body_scale,0,p["pos"])*Transform2D(0,-Vector2(p["pos"]))
	if float(p["slam_land_left"])>0:
		AdventurePose.draw_action(self,3,3,p["pos"],p["face"],player_base,tint)
	elif p.get("lift_flying",false):
		AdventurePose.draw_action(self,3,AdventurePose.slam_frame(float(p["lift_age"])),p["pos"],p["face"],player_base,tint,1.0,true)
	elif p.has("lift_charge"):
		preload("res://scripts/double_jump_v27.gd").draw(self,p["pos"],float(p["face"]),fposmod(draw_clock,.70)*.32/.70,player_base,tint)
	elif bool(p["slam"]):
		AdventurePose.draw_action(self,3,AdventurePose.slam_frame(p["slam_age"]),p["pos"],p["face"],player_base,tint)
	elif _wind_form_active():
		AdventurePose.draw_action(self,2,1,p["pos"],p_attack.attack["dir"].x,player_base,tint)
	else:
		if anim=="mantle":preload("res://scripts/mantle_art_v37.gd").draw(self,p,player_base,tint)
		elif anim=="heavy_land":preload("res://scripts/heavy_landing_v28.gd").draw(self,p["pos"],float(p["face"]),.5-float(p["heavy_land_left"]),player_base,tint)
		elif float(p.get("dash_t",0))>0 and not p_attack.is_busy():preload("res://scripts/double_jump_v27.gd").draw(self,p["pos"],float(p["face"]),(.16-float(p["dash_t"]))*2,player_base,tint)
		elif anim=="glide":AdventurePose.draw_glide(self,p["pos"],p["face"],player_base,tint)
		elif float(p.get("flap_left",0))>0 and not bool(p["grounded"]) and not p_attack.is_busy() and anim not in ["hurt","heal","wall","dash","charge"]:preload("res://scripts/double_jump_v27.gd").draw(self,p["pos"],float(p["face"]),.32-float(p["flap_left"]),player_base,tint)
		elif dream_progress>=0 and anim not in ["hurt","heal","wall","jump_up"] and not (p_attack.attack.get("kind","")=="primary" and anim in ["windup","active","recovery"]):FX.actor(self,"pigeon_feather_charge",dream_progress,p["pos"],player_base,float(p["face"]),1.0,tint,"active")
		elif anim=="charge":
			var feet:Vector2=p["pos"]
			if walker.moving and bool(p["grounded"]) and absf(p["vel"].x)>30:
				var atlas:Texture2D=preload("res://assets/v48/pigeon_quickdraw_walk.webp")
				var frame:int=floori(walker.phase*.5)%6
				var cell:=Vector2(112,83)
				var source:=Rect2(Vector2(frame%3,floori(frame/3.0))*cell,cell)
				var size:Vector2=cell*(51.0/cell.y)
				draw_set_transform_matrix(player_base*Transform2D(0,Vector2(float(p["face"]),1),0,feet))
				draw_texture_rect_region(atlas,Rect2(Vector2(-size.x*.5,-size.y),size),source,tint)
			else:
				var pose:Texture2D=preload("res://assets/v47/pigeon_quickdraw.webp")
				var windup:float=clampf((charge_timer-.15)/.22,0,1)
				var breath:float=sin(clock*8.0)*.015
				var shape:=Vector2(lerpf(.90,1.0,windup),lerpf(1.08,.96,windup)+breath)
				var size:Vector2=pose.get_size()*(51.0/pose.get_height())
				draw_set_transform_matrix(player_base*Transform2D(0,Vector2(float(p["face"])*shape.x,shape.y),0,feet))
				draw_texture_rect(pose,Rect2(Vector2(-size.x*.5,-size.y),size),false,tint)
			draw_set_transform_matrix(world_transform)
		elif anim=="wall":PigeonPose.draw_pose(self,"wall",PigeonPose.wall_frame(float(p["wall_hold_left"])>0,float(p["wall_slide_age"])),p["pos"],float(p["wall"]),player_base,tint)
		elif anim=="jump_up" and float(p["jump_rise_age"])>=0:AdventurePose.draw_jump(self,p["jump_rise_age"],p["pos"],p["face"],player_base,tint)
		elif anim in ["idle","rest"]:IdleArt.draw(self,p["pos"],float(p["face"]),idle_time,player_base,tint)
		else:Art.draw_pigeon(self,p["pos"],float(p["wall"]) if anim=="wall" else float(p["face"]),clock,anim,tint,1.0,(1-float(p["hurt"])/.25) if anim=="hurt" else p_attack.progress(),player_base,str(p_attack.attack.get("style","quick")),p_attack.attack)
	if not _wind_form_active() and float(p["slam_land_left"])<=0:preload("res://scripts/cloak_art_v29.gd").draw(self,int(meta.get("skin",0)),p["pos"],float(p["wall"]) if anim=="wall" else float(p["face"]),clock,anim not in ["idle","rest","heavy_land"],player_base,anim,tint.a)
	if p_attack.is_busy() and p_attack.attack.get("kind","")=="secondary":WorldItems.secondary(self,p_attack.attack,p["pos"],float(p["face"]),world_transform)

func _draw_hub() -> void:
	draw_set_transform_matrix(world_transform)
	if trophy_room:_draw_trophy_room();return
	var focus:String=_home_station()
	if not focus.is_empty():HomeArt.station_light(self,HomeArt.STATIONS[focus])
	HomeArt.gates(self,clock,low_effects,world_transform)
	HomeArt.nest(self)
	for prop:Dictionary in props:
		if prop["kind"]=="launcher":LaunchArt.draw(self,prop,"trunk",world_transform)
		elif prop["kind"] in ["adventure_records","trophy_case"]:GothicProps.draw_prop(self,prop,"trunk",world_transform)
	_draw_home_projector()
	_draw_fragments()
	for effect:Dictionary in effects:_draw_prop_impact(effect)
	draw_set_transform_matrix(world_transform)
	if home_sleeping or home_wake_left>0:HomeArt.resting(self,clock,home_wake_left if not home_sleeping else -1,world_transform)
	else:
		_draw_player_body()
		_draw_attack(p["pos"],p_attack,float(p["face"]),true)
	draw_set_transform_matrix(world_transform)
	_draw_home_keys()
	for entry:Array in [["musou","無雙夢境"],["tutorial","新手教學"],["rogue","肉鴿"],["trophy","戰利品房"],["records","冒險紀錄"]]:
		var feet:Vector2=HomeArt.STATIONS[entry[0]]
		_home_gate_sign(feet+Vector2(0,8),entry[1],"按 %s 互動"%_tutorial_key("up") if focus==entry[0] else "",Color("ffe1a6"))

func _draw_home_keys() -> void:
	var opacity:float=1.0-clampf((clock-home_hint_fade_at)/.65,0,1)
	if opacity<=0.0 or ui.is_panel_open():return
	var center:Vector2=Vector2(p["pos"])-Vector2(0,108+sin(clock*2.6)*3)
	var tint:=Color(.92,.98,.87,opacity*(.88+sin(clock*2.6)*.12))
	for entry:Array in [["up",Vector2(0,-24)],["left",Vector2(-35,5)],["down",Vector2(0,5)],["right",Vector2(35,5)]]:
		var at:Vector2=center+entry[1]
		var cap:=Rect2(at-Vector2(15,12),Vector2(30,24))
		draw_rect(Rect2(cap.position+Vector2(0,3),cap.size),Color(.06,.10,.09,opacity*.9))
		draw_rect(cap,Color(.16,.26,.23,opacity*.94))
		draw_rect(cap,Color(tint,opacity*.75),false,1.0)
		var direction:Vector2={KEY_UP:Vector2.UP,KEY_LEFT:Vector2.LEFT,KEY_DOWN:Vector2.DOWN,KEY_RIGHT:Vector2.RIGHT}.get(int(key_bindings[entry[0]]),Vector2.ZERO)
		if direction!=Vector2.ZERO:
			var tip:Vector2=at+direction*6
			var wing:Vector2=direction.orthogonal()*4
			draw_line(at-direction*6,tip,tint,1.8,true)
			draw_polyline(PackedVector2Array([at+wing,tip,at-wing]),tint,1.8,true)
		else:
			var key:String=_tutorial_key(entry[0])
			var size:int=12
			var width:float=font.get_string_size(key,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
			_text(at+Vector2(-width*.5,4),key,size,tint)

func _draw_home_projector() -> void:
	if home_projector.is_empty():return
	var at:Vector2=HomeArt.lamp_center(home_projector,clock)
	var broken:bool=home_projector["used"]
	var opacity:float=1.0-clampf((clock-float(home_projector.get("broken_at",clock)))/.55,0,1)
	if opacity>0:
		var origin:Vector2=Vector2(home_projector.get("break_origin",at))+Vector2(21,5)
		var screen_rect:Rect2=HomeArt.PROJECTION_SCREEN
		var beam:=Color(.68,.94,.83,.22*opacity)
		var edge:=Color(.69,.95,.84,.63*opacity)
		draw_polygon(PackedVector2Array([origin+Vector2(0,-5),screen_rect.position,Vector2(screen_rect.position.x,screen_rect.end.y),origin+Vector2(0,6)]),PackedColorArray([beam,Color(beam,0),Color(beam,0),beam]))
		draw_rect(screen_rect,Color(.04,.12,.11,.92*opacity))
		draw_rect(screen_rect,edge,false,1.0)
		var trim_size:Vector2=PROJECTION_TRIM.get_size()*((screen_rect.size.x+16.0)/PROJECTION_TRIM.get_width())
		draw_texture_rect(PROJECTION_TRIM,Rect2(Vector2(screen_rect.get_center().x-trim_size.x*.5,screen_rect.end.y-5),trim_size),false,Color(1,1,1,opacity))
		var center_x:float=screen_rect.get_center().x
		draw_line(Vector2(center_x-62,screen_rect.position.y+66),Vector2(center_x+62,screen_rect.position.y+66),Color(.81,.67,.42,.52*opacity),1,true)
		for line:Array in [["枝間鴿行",32,38],["樹梢之巢 · 冒險的起點",14,59],["你是一隻鴿子 可以繼續睡",16,89],["也可以舉起羽毛冒險",16,112]]:
			var width:float=PROJECTION_FONT.get_string_size(line[0],HORIZONTAL_ALIGNMENT_LEFT,-1,line[1]).x
			var tint:=Color(1,.92,.72,opacity) if line[1]==32 else Color(.88,.98,.91,opacity)
			draw_string(PROJECTION_FONT,Vector2(center_x-width*.5,screen_rect.position.y+line[2]),line[0],HORIZONTAL_ALIGNMENT_LEFT,-1,line[1],tint)
	var hit_age:float=clock-float(home_projector.get("hit_at",-10.0))
	var projector:=home_projector.duplicate(false)
	projector["pos"]=Vector2(home_projector.get("break_origin",at) if broken else at)+Vector2(0,29)
	GothicProps.draw_prop(self,projector,"trunk",world_transform)
	if hit_age<.18:
		var impact:Vector2=home_projector["hit_point"]
		for i in 7:
			var ray:=Vector2.from_angle(i*TAU/7.0+.25)
			var tail:Vector2=impact+ray*(9+hit_age*145)
			draw_line(tail,tail+ray*maxf(2,13-hit_age*55),Color("fff0aa"),2.0,true)

func _home_gate_sign(at:Vector2,title:String,hint:String,tint:Color) -> void:
	var width:float=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x
	var hint_width:float=font.get_string_size(hint,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
	var plate_width:float=maxf(width,hint_width)+24
	var plate:=Rect2(at-Vector2(plate_width*.5,0),Vector2(plate_width,34 if hint.is_empty() else 50))
	draw_rect(plate,Color("#101b19ed"))
	draw_line(plate.position,Vector2(plate.end.x,plate.position.y),Color(tint,.78),2)
	_text(at+Vector2(-width*.5,25),title,22,tint)
	if not hint.is_empty():_text(at+Vector2(-hint_width*.5,43),hint,14,Color("e0e8d7"))

func _configure_home(reset_lamp:bool=true) -> void:
	trophy_room=false
	camera_pos=Vector2.ZERO;render_camera=Vector2.ZERO;world_transform=Transform2D.IDENTITY
	layout={"size":Vector2(1280,720),"floor_y":600.0,"pool":Rect2(),"spawn_positions":{"center":Vector2(640,600)}}
	platforms.assign([Rect2(40,600,1200,9),HomeArt.ROGUE_PLATFORM])
	solids.assign([Rect2(0,600,1280,120),Rect2(18,HomeArt.CEILING_Y,22,600-HomeArt.CEILING_Y),Rect2(1240,HomeArt.CEILING_Y,22,600-HomeArt.CEILING_Y),Rect2(0,HomeArt.CEILING_Y-20,1280,20)])
	_rebuild_projectile_surfaces()
	props.assign([{"kind":"adventure_records","pos":HomeArt.STATIONS["records"]+HomeArt.STATION_SINK,"used":false,"hurt":0.0},{"kind":"trophy_case","pos":HomeArt.STATIONS["trophy"]+HomeArt.STATION_SINK,"used":false,"hurt":0.0},{"kind":"launcher","pos":Vector2(455,600),"used":false,"hurt":0.0,"launch_left":0.0,"launch_cooldown":0.0,"launch_hit_cooldown":0.0}])
	if reset_lamp:
		home_fragments.clear()
		home_projector={"kind":"home_projector","pos":Vector2(365,451),"used":false,"hurt":0.0,"hits":0}
		home_hint_fade_at=INF
	props.append(home_projector)
	p_attack.cancel();pending_attack.clear();charge_timer=0;room_cooldown=0;weapon_index=1
	if home_atmosphere!=null:home_atmosphere.set_active(true)
	if spring_particles!=null:spring_particles.clear()

func _at_rogue_gate() -> bool:
	var at:Vector2=p["pos"]
	return absf(at.x-HomeArt.ROGUE_GATE.get_center().x)<86.0 and absf(at.y-HomeArt.ROGUE_PLATFORM_Y)<=12.0 and bool(p["grounded"])

func _collect_trophy(kind:String,id:String) -> void:
	if not meta.has("trophies"):meta["trophies"]={"weapons":[],"runes":[]}
	if not meta["trophies"].has(kind):meta["trophies"][kind]=[]
	if not meta["trophies"][kind].has(id):meta["trophies"][kind].append(id)

func _enter_trophy_room() -> void:
	trophy_room=true
	camera_pos=Vector2.ZERO;render_camera=Vector2.ZERO;world_transform=Transform2D.IDENTITY
	home_sleeping=false;home_wake_left=0
	_clear_keys()
	props.clear()
	platforms.assign([Rect2(40,600,1200,9),Rect2(200,475,880,12)])
	_reset_player(Vector2(113,600))
	_rebuild_projectile_surfaces()

func _leave_trophy_room() -> void:
	_clear_keys()
	_configure_home(false)
	_reset_player(HomeArt.STATIONS["trophy"])

func _draw_trophy_room() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("162323"))
	var slot:Texture2D=preload("res://assets/v55/ui/etched_slot.svg")
	var trophies:Dictionary=meta.get("trophies",{})
	var clips:Array[String]=[]
	for weapon:Dictionary in Data.SECONDARY:
		if weapon["id"] in trophies.get("weapons",[]) or weapon["id"] in meta.get("blueprints",[]):clips.append(UI.Icons.secondary(weapon))
	for rune:Dictionary in Data.all_runes():
		if rune["id"] in trophies.get("runes",[]) or meta.get("runes",{}).has(rune["id"]):clips.append(UI.Icons.rune(rune["id"]))
	for i in maxi(12,clips.size()):
		var at:=Vector2(202+(i%12)*74,240+(i/12)*72)
		draw_texture_rect(slot,Rect2(at,Vector2(63,63)),false)
		if i<clips.size():
			var icon:Texture2D=UI.Icons.texture(clips[i])
			if icon!=null:draw_texture_rect(icon,Rect2(at+Vector2(9,9),Vector2(45,45)),false)
	BiomeArt.terrain(self,"trunk",Rect2(40,600,1200,120))
	BiomeArt.terrain(self,"trunk",Rect2(200,475,880,12),true)
	var focused:bool=_home_station()=="exit"
	if focused:HomeArt.station_light(self,HomeArt.STATIONS["exit"])
	Adventure.portal(self,HomeArt.STATIONS["exit"]+HomeArt.STATION_SINK,Color("d8c188"),clock,Transform2D.IDENTITY,"trunk","left",96,low_effects)
	_text(Vector2(510,168),"戰利品房",34,Color("efdaaa"))
	_text(Vector2(45,632),"回鳥巢 · "+_tutorial_key("up") if focused else "回鳥巢",16,Color("dfca9b"))
	_draw_player_body()

func _home_station() -> String:
	if home_sleeping or _action_locked() or (ui!=null and ui.is_panel_open()):return ""
	var at:Vector2=p["pos"]
	if trophy_room:return "exit" if at.distance_to(HomeArt.STATIONS["exit"])<85 else ""
	if _at_rogue_gate():return "rogue"
	var nearest:float=85
	var selected:String=""
	for id:String in ["musou","tutorial","trophy","records"]:
		var distance:float=at.distance_to(HomeArt.STATIONS[id])
		if distance<nearest:
			nearest=distance
			selected=id
	return selected

func _home_interact() -> bool:
	if home_sleeping:_wake_home();return true
	match _home_station():
		"exit":_leave_trophy_room()
		"rogue":new_run("rogue")
		"trophy":_enter_trophy_room()
		"records":_show_records()
		"musou":new_run("musou")
		"tutorial":_enter_practice(true)
		_:return false
	return true

func _update_home(delta:float) -> void:
	if not perf_log.active:
		_update_home_profiled_body(delta);return
	var measured:int=Time.get_ticks_usec()
	_update_home_profiled_body(delta)
	perf_log.span("physics.home",Time.get_ticks_usec()-measured)
func _update_home_profiled_body(delta:float) -> void:
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
	if not trophy_room and is_inf(home_hint_fade_at) and Vector2(p["pos"]).distance_squared_to(before)>.25:
		home_hint_fade_at=clock+3.0
	_update_props(delta)
	walker.step_turn(float(p["face"]),delta,bool(p["grounded"]))
	walker.advance(absf(p["pos"].x-before.x),bool(p["grounded"]) and absf(p["vel"].x)>30,"wood",audio_enabled)
	_update_hud()
	camera_pos=camera_pos.lerp(_camera_target(p["pos"]),1.0-exp(-delta*10.0))

func _wake_home() -> void:
	_sound("home_wake")
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
	var direction:String=door["dir"]
	var side:bool=direction in ["left","right"]
	var center:Vector2=at-Vector2(0,PORTAL_HEIGHT*.5) if side else at
	if not view_rect.grow(PORTAL_HEIGHT*.5).has_point(center):return
	Adventure.portal(self,at,color,clock,world_transform,str(room["ecology"]["id"]),direction,PORTAL_HEIGHT,low_effects,true)
	if locked:draw_line(center+Vector2(-25,28),center+Vector2(25,-28),Color("e1b18b"),5)

func _enemy_edge_markers(bounds:Rect2) -> Array[Dictionary]:
	var markers:Array[Dictionary]=[]
	var inner:Rect2=bounds.grow(-16.0)
	if not inner.has_area():return markers
	var center:Vector2=inner.get_center()
	for enemy:Dictionary in enemies:
		if float(enemy["hp"])<=0 or enemy.get("training",false) or enemy.get("passive",false):continue
		var body:Rect2=world_transform*_enemy_body_box(enemy)
		if bounds.intersects(body):continue
		var direction:Vector2=body.get_center()-center
		var distance:float=maxf(absf(direction.x)/(inner.size.x*.5),absf(direction.y)/(inner.size.y*.5))
		markers.append({"position":center+direction/distance,"direction":direction.normalized()})
	return markers

func _draw_enemy_edge_indicators() -> void:
	if screen!="game" or minimap_open or not life_event.is_empty() or ui.is_panel_open():return
	for marker:Dictionary in _enemy_edge_markers(display_safe):
		var point:Vector2=marker["position"]
		var dir:Vector2=marker["direction"]
		var side:Vector2=dir.orthogonal()*5.5
		draw_colored_polygon(PackedVector2Array([point+dir*8.0,point-dir*6.0+side,point-dir*6.0-side]),Color("ff524d"))
		draw_polyline(PackedVector2Array([point-dir*6.0+side,point+dir*8.0,point-dir*6.0-side]),Color("581d2c"),1.4,true)

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
	var icon:String=""
	match kind:
		"rune":icon=UI.Icons.rune(str(Data.all_runes()[int(drop["value"])]["id"]))
		"weapon":icon=UI.Icons.secondary(Data.secondary_attack(int(drop["value"])))
		"item":icon="items_"+str(Data.ITEMS[int(drop["value"])]["id"])
		"growth":icon="growth_"+str(Arms.GROWTH[posmod(int(drop["value"]),Arms.GROWTH.size())])
		"heal":icon="items_heal"
		"upgrade":icon="growth_damage"
	var target:=Rect2(at-Vector2.ONE*22,Vector2.ONE*44)
	if kind=="coin":
		var angle:float=float(drop.get("rotation",0))
		draw_set_transform_matrix(world_transform*Transform2D(angle,at))
		draw_texture_rect(preload("res://assets/combat_v05/common/currency/coin_00.png"),Rect2(-16,-16,32,32),false)
		draw_set_transform_matrix(world_transform)
	else:
		var icon_drawn:bool=WorldItems.draw_icon(self,icon,target,world_transform)
		if not icon_drawn:FX.fitted(self,"delivery_parcel",0,target,world_transform,"right","idle",color)
	if show_label or drop.get("gift",false):
		if kind=="coin":label="金幣 ×%d"%int(drop["value"])
		var width:float=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+16
		draw_rect(Rect2(at+Vector2(-width*.5,-46),Vector2(width,22)),Color("173c38",.95))
		_text(at+Vector2(-width*.5+8,-30),label,13,color)

func _draw_attack(at:Vector2,atk:Variant,face:float,is_player:bool) -> void:
	if not atk.is_busy():return
	if not is_player:
		if atk.is_active():
			var body_fx:bool=atk.attack.has("boss_animation_slot") and (atk.attack.get("primary",false) or atk.attack.get("library_kind","")=="explosion") and BossActionArt.has_actor(str(atk.attack.get("boss_biome","")))
			var authored:bool=body_fx or preload("res://scripts/monster_art_v36.gd").draw_melee(self,at,atk,face,world_transform)
			if not authored:_draw_enemy_release(at,atk,face)
			if show_hitboxes:draw_rect(_attack_box(at-Vector2(0,5),atk.attack,face),Color("ffe3a0"),false,1)
		return
	if is_player and atk.attack.get("kind","") in ["pierce","slam"]:
		if bool(p.get("slam",false)) or (atk.is_active() and atk.attack["kind"]=="pierce"):
			var down:bool=atk.attack["kind"]=="slam"
			Wind.wind_form(self,at-AdventurePose.WIND_BODY_CENTER,atk.attack["dir"],float(p["slam_age"]) if down else atk.elapsed,float(atk.attack["active"]),world_transform,down)
		return
	if is_player and atk.attack.get("primary",false) and (not atk.attack.get("charged",false) or atk.attack.get("great_spin_release",false)):
		if show_hitboxes and atk.is_active():draw_rect(_player_strike_box(atk.attack),Color("ffe3a0"),false,1)
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

func _draw_enemy_release(at:Vector2,atk:Variant,face:float) -> void:
	var def:Dictionary=atk.attack
	var progress:float=atk.progress()
	var at_fx:=at+Vector2(face*26,float(def.get("origin_y",-24)))
	var extent:=Vector2(62,50)
	var row:int=SkillArt.attack_row(def)
	match row:
		SkillArt.POISON:extent=Vector2(94,62)
		SkillArt.RUSH:
			extent=Vector2(134,56)
			at_fx.x-=face*38
		SkillArt.SWIPE:
			extent=Vector2(clampf(float(def.get("range",65)),42,155),clampf(float(def.get("size",32))*2,40,108))
			at_fx.x=at.x+face*extent.x*.5
	var tint:Color=Color.WHITE.lerp(def.get("color",Color.WHITE),.35)
	tint.a=Explosion.OPACITY if def.get("library_kind","")=="explosion" else 1.0
	draw_set_transform_matrix(world_transform*Transform2D(0,Vector2(face,1),0,at_fx))
	SkillArt.draw(self,row,progress,Rect2(-extent*.5,extent),tint)
	draw_set_transform_matrix(world_transform)

func _minimap_enemy_markers() -> Array[Dictionary]:
	var markers:Array[Dictionary]=[]
	for enemy:Dictionary in enemies:
		if float(enemy["hp"])<=0:continue
		var boss:bool=int(enemy.get("model",0))==4
		var elite:bool=enemy.get("elite",false) or int(enemy.get("model",0))==3
		markers.append({"pos":_enemy_body_box(enemy).get_center(),"radius":5.0 if boss else (3.8 if elite else 2.6),"color":Color("ff8ada") if boss else (Color("ffb565") if elite else Color("ff776a"))})
	return markers

func _paint_minimap(canvas:CanvasItem) -> void:
	if tower.is_empty() or not minimap_open:return
	canvas.draw_rect(Rect2(0,0,1280,720),Color(0,.025,.045,.75))
	canvas.draw_rect(Rect2(150,65,980,590),Color("0e2432",.98))
	var heading:String=["房間地形","本關探索","全塔地圖"][mini(minimap_page,2)]
	_text_on(canvas,Vector2(178,103),heading,22,Color("eef5e6"))
	_text_on(canvas,Vector2(178,128),"左右切換 · Esc 關閉",15,Color("b7d0d2"))
	var area:=Rect2(180,155,915,422)
	canvas.draw_texture_rect(preload("res://assets/v57/maps/paper.svg"),area,false)
	match minimap_page:
		0:
			var factor:float=minf(area.size.x/_room_size().x,area.size.y/_room_size().y)
			var origin:Vector2=area.get_center()-_room_size()*factor*.5
			var map_transform:=Transform2D(0,Vector2.ONE*factor,0,origin)
			var biome:String=_ecology()["id"]
			for surface:Rect2 in solids:BiomeArt.terrain(canvas,biome,surface,false,map_transform)
			for surface:Rect2 in platforms:BiomeArt.terrain(canvas,biome,surface,true,map_transform)
			canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
			for prop:Dictionary in props:
				if prop["kind"] in ["launcher","spikes"]:canvas.draw_circle(origin+Vector2(prop["pos"])*factor,3,Color("f0b88d"))
			for marker:Dictionary in _minimap_enemy_markers():
				var at:Vector2=(origin+Vector2(marker["pos"])*factor).clamp(area.position+Vector2.ONE*6,area.end-Vector2.ONE*6)
				var radius:float=marker["radius"]
				canvas.draw_circle(at,radius+1.25,Color("281021"))
				canvas.draw_circle(at,radius,marker["color"])
			canvas.draw_circle(origin+Vector2(p["pos"])*factor,6,Color("fff0a6"))
		1:TowerMap.draw_chapter(canvas,tower,current_room,area,font,true)
		2:
			if tower.get("maps",[]).is_empty():TowerMap.draw_chapter(canvas,tower,current_room,area,font,true)
			else:TowerMap.draw_full_tower(canvas,tower,current_room,area,font,true)

func _effect_static(at:Vector2,color:Color,radius:float) -> void:
	draw_line(at,at-Vector2(0,100),Color(color,.12),36,true)
	draw_circle(at,20,color);draw_arc(at,radius+sin(clock*2)*4,0,TAU,40,Color(color,.6),2,true)

func _text(at:Vector2,message:String,size:int,color:Color) -> void:
	draw_string(font,at,message,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _text_on(canvas:CanvasItem,at:Vector2,message:String,size:int,color:Color) -> void:
	canvas.draw_string(font,at,message,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

# v0.5 expedition, props and lifecycle orchestration.
func _in_aggro(en:Dictionary) -> bool:
	if int(en.get("model",0))==4 and en.get("combat_engaged",false) and not Motion.airborne(en):return true
	var zoom:float=_view_zoom()
	var visible:=Rect2(camera_pos,Vector2(1280,720)/zoom)
	if display_safe.has_area():visible=Rect2(camera_pos+display_safe.position/zoom,display_safe.size/zoom)
	if en.get("elite",false):return visible.intersects(_enemy_body_box(en))
	var seen:bool=visible.grow(-24).has_point(_enemy_body_box(en).get_center())
	if seen and int(en.get("model",0))==4:en["combat_engaged"]=true
	return seen

func _attack_direction(def:Dictionary) -> Vector2:
	return {"up":Vector2.UP,"down":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}.get(str(def.get("direction","")),Vector2(float(p["face"]),0))

func _recoil(distance:float,source:Vector2,direction:Vector2=Vector2.ZERO) -> void:
	var away:float=signf(p["pos"].x-source.x)
	if away==0:away=-float(p["face"])
	p["recoil_left"]=.18;p["recoil_base_y"]=p["vel"].y
	p["recoil_velocity"]=(direction.normalized() if direction.length_squared()>.01 else Vector2(away,0))*distance/.18

func _contact_fx(clip:String,at:Vector2,duration:float=.3,extent:float=65.0) -> void:
	if effects.size()>=MAX_PARTICLES:effects.pop_front()
	effects.append({"pos":at,"color":Color.WHITE,"life":duration,"max":duration,"ring":false,"radius":0.0,"vel":Vector2.ZERO,"combat_fx":clip,"fx_extent":extent})

func _hit_flash(at:Vector2,damage:float,color:Color) -> void:
	if effects.size()>=MAX_PARTICLES:effects.pop_front()
	effects.append({"pos":at,"color":Color.WHITE,"life":.25,"max":.25,"ring":false,"radius":0.0,"vel":Vector2.ZERO,"combat_fx":"hit_light" if damage<=2 else ("hit_medium" if damage<5 else "hit_heavy")})

func _restore_vital(kind:String,amount:float) -> void:
	if amount<=0:return
	if kind=="energy" and mode!="musou":p["ultimate_charge"]=minf(ULTIMATE_CAPACITY,float(p.get("ultimate_charge",0))+amount)
	var cap:int=int(p["max_"+kind]);var current:int=int(p[kind]);var key:String=kind+"_recovery"
	if current>=cap:p[kind]=cap;p[key]=0.0;return
	var progress:float=float(p.get(key,0))+amount
	var units:int=int(floor(progress+0.00001));p[kind]=mini(cap,current+units)
	p[key]=0.0 if int(p[kind])>=cap else maxf(0,progress-units)

func _station_event(kind:String,event:String) -> void:
	for prop in props:
		if prop["kind"]==kind:prop["event"]=event;prop["event_left"]=.8

func _update_shield(delta:float) -> void:
	var cells:int=int(p["shield_cells"])
	var capacity:int=int(p["max_shield"])
	if cells>=capacity:return
	var remaining:float=float(p["shield_recharge_left"])-delta
	while remaining<=.000001 and cells<capacity:
		cells+=1
		remaining+=SHIELD_RECHARGE_INTERVAL
	if cells>int(p["shield_cells"]):_sound("shield_recover")
	p["shield_cells"]=cells
	p["shield_recharge_left"]=maxf(0.0,remaining) if cells<capacity else 0.0

func _sync_vitals() -> void:
	var old_shield_max:int=int(p["max_shield"])
	p["max_shield"]=SHIELD_BASE_CELLS+int(_rune_effect("max_shield"))
	p["shield_cells"]=mini(int(p["shield_cells"]),int(p["max_shield"]))
	if int(p["max_shield"])>old_shield_max and float(p["shield_recharge_left"])<=0.0:
		p["shield_recharge_left"]=SHIELD_RECHARGE_INTERVAL
	var old_max:float=float(p.get("max_hp",5))
	p["max_hp"]=5+int(_rune_effect("max_hp"))-(2 if injured else 0)
	p["max_energy"]=6-(2 if injured else 0)
	p["hp"]=int(clampf(float(p["hp"])+maxf(0,float(p["max_hp"])-old_max),0,float(p["max_hp"])))
	p["energy"]=int(clampf(float(p["energy"]),0,float(p["max_energy"])))

func _healing_guard() -> bool:
	return _rune_effect("heal_guard")>0 and _key("heal") and float(p["energy"])>=3 and float(p["hp"])<float(p["max_hp"]) and not p_attack.is_busy()

func _update_dream(delta:float) -> void:
	if not perf_log.active:
		_update_dream_profiled_body(delta);return
	var measured:int=Time.get_ticks_usec()
	_update_dream_profiled_body(delta)
	perf_log.span("physics.dream",Time.get_ticks_usec()-measured)

func _update_dream_profiled_body(delta:float) -> void:
	if mode!="musou":return
	dream.step(delta);dream_visual.step(delta*world_speed)
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
	if not perf_log.active:
		_update_passives_profiled_body(delta);return
	var measured:int=Time.get_ticks_usec()
	_update_passives_profiled_body(delta)
	perf_log.span("physics.passives",Time.get_ticks_usec()-measured)
func _update_passives_profiled_body(delta:float) -> void:
	poison_left-=delta
	if _rune_effect("poison_trail")>0 and poison_left<=0 and Vector2(p["vel"]).length_squared()>100:
		poison_left=.35
		poison_clouds.append({"pos":Vector2(p["pos"])-Vector2(float(p["face"])*26,18),"left":3.0})
	for cloud:Dictionary in poison_clouds:cloud["left"]-=delta
	poison_clouds=poison_clouds.filter(func(cloud:Dictionary)->bool:return cloud["left"]>0)
	for cloud:Dictionary in poison_clouds:
		if cloud.get("hostile",false) and Vector2(cloud["pos"]).distance_squared_to(Vector2(p["pos"])-Vector2(0,22))<58*58:
			_hurt_player(1,cloud["pos"])
			break
	for enemy:Dictionary in enemies:
		if poison_clouds.is_empty():break
		if float(enemy["hp"])<=0:continue
		enemy["poison_tick"]=maxf(0.0,float(enemy.get("poison_tick",1.0))-delta) if poison_clouds.any(func(cloud:Dictionary)->bool:return not cloud.get("hostile",false) and Vector2(cloud["pos"]).distance_squared_to(enemy["pos"])<65*65) else 1.0
		if float(enemy["poison_tick"])<=0:
			enemy["poison_tick"]=1.0
			enemy["hp"]-=1.0
			if float(enemy["hp"])<=0:_enemy_defeated(enemy)
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
		while move_energy_distance>=220:move_energy_distance-=220;_restore_vital("energy",1)
	bee_timer-=delta
	if _rune_effect("orbit_bee")>0 and bee_timer<=0:
		bee_timer=1.0
		var candidates:Array=enemies.filter(func(enemy:Dictionary)->bool:return enemy["hp"]>0 and _in_aggro(enemy) and enemy["pos"].distance_to(p["pos"])<450)
		for bee in int(_rune_effect("orbit_bee")):
			if candidates.is_empty():break
			var target:Dictionary=candidates[bee%candidates.size()]
			var at:Vector2=_bee_position(bee)
			_emit_weapon(at,_enemy_body_box(target).get_center()-at,Combat.attack("linear",{"id":"bee","damage":3,"speed":400,"range":450,"size":6,"knockback":45,"color":Color("ffe49c")}),true)
			if not projectiles.is_empty():projectiles[-1]["bee"]=true

func _bee_position(index:int) -> Vector2:
	return p["pos"]-Vector2(0,35)+Vector2.from_angle(draw_clock*3+TAU*index/maxf(1,_rune_effect("orbit_bee")))*(50+int(index/8)*10)

func _check_portals() -> void:
	if _release_locked():return
	if room_cooldown>0 or not life_event.is_empty():return
	var at:Vector2=p["pos"]
	for door in doors:
		var direction:String=door["dir"];var anchor:Vector2=door["pos"]
		var opening:float=PORTAL_HEIGHT
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
	if lab_mode=="tutorial":
		var tutorial_props:Array[Dictionary]=[{"kind":"launcher","pos":Vector2(1040,_room_floor()),"used":false,"hurt":0.0,"launch_left":0.0,"launch_cooldown":0.0}]
		for index in TUTORIAL_STATIONS.size():
			tutorial_props.append({"kind":["gift_pedestal","reforge","dummy"][index],"pos":_tutorial_station_position(index),"hurt":0.0,"tutorial_fixture":true})
		return tutorial_props
	var result:Array[Dictionary]=[]
	if layout.has("hazard_room"):
		for at:Vector2 in layout["launcher_spawns"]:
			result.append({"kind":"launcher","pos":at,"hurt":0.0})
		return result
	if room["type"]=="start":
		if int(room.get("map_index",0))==0:result.append({"kind":"gift_pedestal","pos":_furniture_offset()+Vector2(620,1050),"used":false,"hurt":0.0})
		result.append({"kind":"wardrobe","pos":_furniture_offset()+Vector2(360,850),"used":false,"hurt":0.0})
		for entry in [["aid",540],["forge",720],["reforge",900],["mail",1080],["energy_infinite",1260]]:result.append({"kind":entry[0],"pos":_furniture_offset()+Vector2(entry[1],850),"used":false,"hurt":0.0})
	elif room["type"]=="merchant":
		result.append({"kind":"merchant","pos":_furniture_offset()+Vector2(160,1050),"used":false,"hurt":0.0})
		for table:Vector2 in Sanctuary.TABLES:
			result.append({"kind":"merchant_table","pos":table+_furniture_offset(),"hurt":0.0})
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
	if room["type"]=="boss":
		for fraction in [.30,.70]:
			var at:=Vector2(_room_size().x*fraction,_room_floor())
			result.append({"kind":"launcher","pos":at,"used":false,"hurt":0.0,"launch_left":0.0,"launch_cooldown":0.0})
	if room.get("fountain",false) and layout.has("fountain_pos"):result.append({"kind":"fountain","pos":layout["fountain_pos"],"used":false,"hurt":0.0,"water_cd":0.0})
	if room["type"] in ["combat","elite"] and not room.get("spring",false):
		for reward:Dictionary in layout.get("dead_end_rewards",[]):
			var cell:Vector2i=reward["cell"];var at:=(Vector2(cell)+Vector2(.5,1))*Scale.CELL_SIZE
			result.append({"kind":"chest","pos":at,"used":false,"hurt":0.0,"dead_end_length":reward["length"]})
		for at:Vector2 in layout.get("navigation_plan",{}).get("launchers",[]):
			result.append({"kind":"launcher","pos":at,"used":false,"hurt":0.0,"launch_left":0.0,"launch_cooldown":0.0,"navigation":true})
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
	if not perf_log.active:
		_update_props_profiled_body(delta);return
	var measured:int=Time.get_ticks_usec()
	_update_props_profiled_body(delta)
	perf_log.span("physics.props",Time.get_ticks_usec()-measured)

func _update_props_profiled_body(delta:float) -> void:
	for prop in props:
		prop["hurt"]=maxf(0,float(prop["hurt"])-delta)
		for timer in ["break_left","event_left","launch_left","launch_cooldown","launch_hit_cooldown"]:prop[timer]=maxf(0,float(prop.get(timer,0))-delta)
		if prop.has("open_left"):prop["open_left"]=maxf(0,float(prop["open_left"])-delta)
		if prop["kind"]=="stone":
			if not prop["asleep"] and not prop.get("used",false):_step_stone(prop,delta*world_speed)
			continue
		if prop["kind"]=="spikes":
			if _body_box(p["pos"]).intersects(prop["rect"]):_hurt_player(1,prop["pos"])
			continue
		if prop["kind"]=="launcher":
			var body:Rect2=LaunchArt.body_box(prop,str(_ecology()["id"]))
			var proximity:float=body.position.y-Vector2(p["pos"]).y
			prop["compression"]=2 if proximity<35 else 1
			if proximity<0 or proximity>100 or absf(p["pos"].x-body.get_center().x)>60 or p["vel"].y<=0:prop["compression"]=0
			var feet:Vector2=p["pos"]
			var on_cap:bool=absf(feet.y-body.position.y)<.15 and feet.x+17>body.position.x and feet.x-17<body.end.x
			if float(prop.get("launch_cooldown",0))<=0 and float(p["vel"].y)>=0.0 and on_cap:_launch_from_object(prop,Vector2.ZERO)
		prop["water_cd"]=maxf(0,float(prop.get("water_cd",0))-delta)
		if prop["kind"] in ["spring","fountain"] and _in_bath():
			_restore_vital("hp",delta)
			_restore_vital("energy",delta*2)

func _step_stone(stone:Dictionary,delta:float) -> void:
	var speed:Vector2=stone["vel"]
	var damage:float=stone["damage"]
	var bounds:Vector2=_room_size()
	var edges:Array[Rect2]=[Rect2(-64,-80,64,bounds.y+144),Rect2(bounds.x,-80,64,bounds.y+144),Rect2(0,bounds.y,bounds.x,64)]
	var path:PackedVector2Array=Stones.step(stone,delta,solids+platforms+edges)
	var next:Vector2=Stones.center(stone)
	if path.size()>1:
		for index in range(1,path.size()):
			ProjectileReadability.record(stone,path[index-1],path[index],delta/(path.size()-1))
	if next.y>bounds.y or next.x<0.0 or next.x>bounds.x:
		var radius:float=Stones.radius(stone)
		stone["pos"]=next.clamp(Vector2(radius,-64),bounds-Vector2.ONE*radius)+Vector2(0,radius)
		stone["vel"]=Vector2.ZERO
		stone["asleep"]=true
		stone["damage"]=0.0
		return
	if speed.length_squared()<130.0*130.0 or damage<=0:return
	var radius:float=Stones.radius(stone)
	var hits:Dictionary=stone["hits"]
	for enemy:Dictionary in enemies:
		if enemy["hp"]<=0 or hits.has(enemy["uid"]):continue
		var target:Rect2=_enemy_body_box(enemy)
		for i:int in range(1,path.size()):
			var from:Vector2=path[i-1]
			var to:Vector2=path[i]
			if Coll.swept_circle_rect(from,to,radius,target)==INF:continue
			hits[enemy["uid"]]=true
			_hit_enemy(enemy,damage,Color("e1c5a0"),90.0 if stone["large"] else 55.0,from,from.direction_to(to))
			break

func _prop_strike_direction(source:Vector2,at:Vector2) -> Vector2:
	var direction:Vector2=source.direction_to(at) if source.is_finite() else _attack_direction(p_attack.attack)
	return Vector2(float(p["face"]),0) if direction.is_zero_approx() else direction.normalized()

func _prop_impact(prop:Dictionary,at:Vector2,direction:Vector2,break_apart:bool=true,flash:bool=true) -> void:
	if flash:
		if effects.size()>=MAX_PARTICLES:effects.pop_front()
		effects.append({"prop_flash":true,"pos":at,"dir":direction,"at":at,"color":Color.WHITE,"life":PropStrike.STRAIGHT_SECONDS,"max":PropStrike.STRAIGHT_SECONDS,"ring":false,"radius":0.0,"vel":Vector2.ZERO})
	if not break_apart or prop.get("gothic_broken",false):return
	var art:Array=GothicProps.entry(prop,str(_ecology()["id"]))
	if art.is_empty():return
	prop["gothic_broken"]=true
	var cue:String=str({"coin_urn":"prop_ceramic","ecology_object":"prop_plant","grass":"prop_plant","energy":"prop_plant","energy_infinite":"prop_plant","health":"prop_plant","launcher":"","fountain":"water_splash","spring":"water_splash","home_projector":"","chest":""}.get(prop["kind"],"prop_wood"))
	_sound(cue)
	if static_props!=null:static_props.invalidate()
	_room_fragments().append({"art":art,"pos":at,"vel":direction*270.0+Vector2(0,-230.0),"radius":14.0,"restitution":.53})

func _room_fragments() -> Array:
	if screen=="hub":return home_fragments
	if not room.has("prop_fragments"):room["prop_fragments"]=[]
	return room["prop_fragments"]

func _step_fragments(delta:float) -> void:
	var fragments:Array=_room_fragments()
	if fragments.is_empty():return
	var surfaces:Array=solids+platforms
	var top:float=HomeArt.CEILING_Y-60.0 if screen=="hub" else -60.0
	var bounds:=Rect2(Vector2(0,top),Vector2(_room_size().x,_room_size().y-top))
	for fragment:Dictionary in fragments:
		if fragment.get("sleeping",false):continue
		Coins.step(fragment,delta,surfaces,bounds)

func _draw_fragments() -> void:
	for fragment:Dictionary in _room_fragments():
		var at:Vector2=fragment["pos"]
		if not view_rect.grow(24).has_point(at):continue
		draw_set_transform_matrix(world_transform*Transform2D(float(fragment.get("rotation",0.0)),at))
		GothicProps.draw_region(self,fragment["art"],2,Rect2(-16,-16,32,32))
	draw_set_transform_matrix(world_transform)

func _draw_prop_impact(e:Dictionary) -> bool:
	if not e.has("prop_flash"):return false
	PropStrike.draw(self,e,world_transform,155.0*world_transform.get_scale().x)
	return true

func _hit_props(box:Rect2,damage:float,attack_id:int=-1,source:Vector2=Vector2.INF,projectile_hits:Variant=null) -> void:
	if damage<=0.0:return
	for i in props.size():
		var prop:Dictionary=props[i]
		if prop["kind"]=="stone":
			if damage<=0 or prop.get("used",false):continue
			var center:Vector2=Stones.center(prop)
			var radius:float=Stones.radius(prop)
			var struck:bool=Coll.circle_overlaps_rect(center,radius,box)
			if projectile_hits!=null:
				struck=Coll.segment_circle(source,box.get_center(),center,radius+box.size.x*.5)<INF
			if not struck:continue
			var key:int=-10000-i
			if attack_id<0 and p_attack.is_active() and not p_attack.mark_hit(key):continue
			if projectile_hits!=null and projectile_hits.has(key):continue
			if projectile_hits!=null:projectile_hits[key]=true
			var direction:=Vector2(float(p["face"]),0)
			if attack_id<0:direction=_attack_direction(p_attack.attack)
			elif source.is_finite():direction=(center-source).normalized()
			if direction.is_zero_approx():direction=Vector2(float(p["face"]),0)
			if attack_id<0 and prop.has("pile_slot"):
				for member_index in props.size():
					var member:Dictionary=props[member_index]
					if member["kind"]!="stone" or not member.has("pile_slot") or member.get("used",false):continue
					if p_attack.is_active():p_attack.mark_hit(-10000-member_index)
					if not member.has("gothic_base"):member["gothic_base"]=member["pos"]
					Stones.scatter(member,direction,damage)
			else:
				if not prop.has("gothic_base"):prop["gothic_base"]=prop["pos"]
				Stones.launch(prop,direction,damage)
			_prop_impact(prop,center,direction,false)
			_particles(center,Color("bca58d"),6,100)
			_sound("prop_stone")
			continue
		if prop["kind"]=="home_projector":
			if not prop["used"] and damage>0:
				var center:Vector2=HomeArt.lamp_center(prop,clock)
				if box.intersects(Rect2(center-Vector2(21,27),Vector2(42,54))):
					if attack_id<0 and p_attack.is_active() and not p_attack.mark_hit(-10000-i):continue
					prop["hits"]=int(prop["hits"])+1
					prop["hit_point"]=center
					prop["hit_at"]=clock
					if int(prop["hits"])>=3:
						prop["break_origin"]=center;prop["broken_at"]=clock;prop["used"]=true
					_prop_impact(prop,center,_prop_strike_direction(source,center),prop["used"])
					_sound("prop_stone")
			continue
		if prop["kind"]=="spikes":
			if attack_id<0 and p_attack.attack.get("direction","")=="down" and box.intersects(prop["rect"]) and p_attack.mark_hit(-10000-i):
				_pogo()
				if p.get("_motion_step",false):p["launch_pending_velocity"]=p["vel"]
			continue
		if prop.get("used",false) or GothicProps.entry(prop,str(_ecology()["id"])).is_empty():continue
		if prop["kind"]=="fountain":
			if box.intersects(preload("res://scripts/spring_v33.gd").body(prop["pos"])) and float(prop.get("water_cd",0))<=0:
				var at:Vector2=prop["pos"]-Vector2(0,28)
				_prop_impact(prop,at,_prop_strike_direction(source,at))
				prop["water_cd"]=.12;spring_particles.splash(preload("res://scripts/spring_v33.gd").water_at(prop["pos"],str(_ecology()["id"])),str(_ecology()["id"]),_aim_vector())
			continue
		if prop["kind"]=="launcher":
			if attack_id>=0:continue # Remote projectiles do not teleport recoil to the player.
			if box.intersects(LaunchArt.body_box(prop,str(_ecology()["id"]))) and float(prop.get("launch_hit_cooldown",0))<=0:
				if attack_id<0 and not p_attack.mark_hit(-10000-i):continue
				var strike:Vector2=_attack_direction(p_attack.attack)
				_prop_impact(prop,LaunchArt.body_box(prop).get_center(),strike,false)
				_launch_from_object(prop,strike)
			continue
		var prop_size:Vector2=BiomeArt.object_size(prop.get("variant",0)) if prop["kind"]=="ecology_object" else GothicProps.SIZES.get(prop["kind"],Vector2(46,60))
		if not box.intersects(Rect2(prop["pos"]-Vector2(prop_size.x*.5,prop_size.y),prop_size)):continue
		if attack_id<0 and not (p_attack.mark_timed_hit(-10000-i,.5,3) if p_attack.attack.get("charged",false) else p_attack.mark_hit(-10000-i)):continue
		var contact:Vector2=prop["pos"]-Vector2(0,prop_size.y*.55)
		_prop_impact(prop,contact,_prop_strike_direction(source,contact))
		if prop["kind"]=="chest":_open_chest(prop);continue
		if prop["kind"]=="coin_urn":
			prop["used"]=true;prop["break_left"]=.6;static_props.invalidate();_drop("coin",prop["pos"]-Vector2(0,32),int(prop["coins"]));_hit_flash(prop["pos"]-Vector2(0,30),damage,Color("ffdf94"));continue
		if prop["kind"] in ["grass","ecology_object"]:
			prop["used"]=true;static_props.invalidate();prop["hp"]=0;prop["break_left"]=BiomeArt.CUT_DURATION if prop["kind"]=="ecology_object" else .45
			combat_feedback.grass_hit(prop["pos"]-Vector2(0,18),Vector2(float(p["face"]),0),str(p_attack.attack.get("style","quick")))
			_particles(prop["pos"]-Vector2(0,15),Color("a9c6a0"),7,80);continue
		prop["hurt"]=.3
		if prop["kind"] in ["dummy","shop_dummy"]:combat_feedback.hit({},prop["pos"]-Vector2(0,35),_aim_vector())
		if prop["kind"]=="health":p["hp"]=p["max_hp"];prop["used"]=true;prop["break_left"]=.5;p["hp_recovery"]=0.0;_toast("生命已回滿")
		elif prop["kind"] in ["energy","energy_infinite"]:_restore_vital("energy",2);prop["used"]=prop["kind"]=="energy";prop["break_left"]=.5 if prop["used"] else 0
		elif prop["kind"] in ["dummy","shop_dummy"]:
			_restore_vital("energy",1)
			_float(prop["pos"]-Vector2(0,80),"%.0f"%damage,Color.WHITE)
			pass # Training props never apply recoil to the player.
	if not feather.is_empty() and int(feather["room"])==current_room and box.intersects(Rect2(feather["pos"]-Vector2(80,132),Vector2(160,132))):_recover_feather()

func _random_rune_index(major_chance:float=.15) -> int:
	return Data.RUNES.size()+rng.randi_range(0,Data.STRONG_RUNES.size()-1) if rng.randf()<major_chance else rng.randi_range(0,Data.RUNES.size()-1)

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
			candidate.erase("cleared")
			candidate.erase("boss_defeated")
			if candidate.has("props"):
				# Clear rewards are earned again when the newly spawned elites fall.
				candidate["props"]=candidate["props"].filter(func(prop:Dictionary)->bool:return not (prop["kind"]=="chest" and prop.get("guaranteed_strong",false)))
				for prop:Dictionary in candidate["props"]:
					if prop["kind"]=="chest":prop["used"]=false
	var checkpoint:int=last_checkpoint if last_checkpoint>=0 else int(tower["maps"][0]["start_id"])
	tower["rooms"][checkpoint]["refresh_gift"]=true
	# Room entry saves the outgoing arrays. Detach them before entering so the
	# old enemies cannot overwrite the freshly reset room state.
	room={};enemies=[];drops=[];corpses=[];projectiles.clear();hazards.clear();effects.clear();hitstop=0
	combat_feedback.clear()
	_reset_player(Vector2(230,FLOOR_Y));_sync_vitals();p["hp"]=p["max_hp"];p["energy"]=3
	_enter_room(checkpoint);p["invul"]=2
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
	return _player_strike_box(def)

func _projectile_explosion(pr:Dictionary) -> void:
	if pr.get("ground_fire",false) and not pr.get("fire_created",false):
		pr["fire_created"]=true
		var at:Vector2=_trap_surface(pr)
		var fire:Dictionary={"pos":at,"from_player":true,"elapsed":0.0,"arming_time":0.0,"lifetime":4.0,"damage":pr["damage"],"size":float(pr.get("fire_size",100)),"fire":true,"hp":1.0,"hits":{},"next_hit":{},"max_hits":8,"hit_interval":.5,"color":pr["color"]}
		if hazards.size()<40:hazards.append(fire);_sound("fire_land")
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
		_hit_props(Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),damage,1,at)
		_damage_traps(Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),damage)
	elif not exclude.has(-1) and _body_box(p["pos"]).get_center().distance_to(at)<=radius:
		var shielded:bool=int(p["shield_cells"])>0
		if _hurt_player(damage,at,false,true) and not shielded:p["recoil_left"]=.18;p["recoil_velocity"]=Vector2(signf(p["pos"].x-at.x)*knockback/.18,0);p["knockback_t"]=0

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
	_sound("trap_land")

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

func _draw_props(focus:Dictionary={}) -> void:
	var biome:String=str(_ecology()["id"])
	var accent:Color=_ecology()["accent"]
	var prop_base:Transform2D=preload("res://scripts/world_placement_v27.gd").prop_base(world_transform)
	if room.get("type","")=="merchant":
		for prop:Dictionary in props:
			if prop["kind"]=="merchant_table" and view_rect.grow(170).has_point(prop["pos"]):GothicProps.draw_prop(self,prop,biome,prop_base)
		var local_stock:Array=room.get("stock",[]).duplicate(true)
		for item:Dictionary in local_stock:item["pos"]-=_furniture_offset()
		SanctuaryArt.market(self,local_stock,p["pos"]-_furniture_offset(),clock,prop_base*Transform2D(0,_furniture_offset()),font)
		draw_set_transform_matrix(world_transform)
	if room.get("type","")=="reward":_draw_rewards()
	for prop in props:
		var at:Vector2=prop["pos"];var kind:String=prop["kind"]
		if kind=="stone":
			var art:Array=GothicProps.entry(prop,biome)
			var extent:Vector2=Stones.size(prop)
			if prop.has("gothic_base") and view_rect.grow(70).has_point(prop["gothic_base"]):
				var feet:Vector2=prop["gothic_base"]
				draw_set_transform_matrix(world_transform)
				GothicProps.draw_region(self,art,1,Rect2(feet-Vector2(extent.x*.5,extent.y),extent))
			if prop.get("used",false) or not view_rect.grow(70).has_point(at):continue
			if not prop["asleep"]:ProjectileReadability.draw_trail(self,prop,world_transform,low_effects)
			draw_set_transform_matrix(world_transform*Transform2D(float(prop.get("rotation",0)),Stones.center(prop)))
			GothicProps.draw_region(self,art,2 if prop.has("gothic_base") else 0,Rect2(-extent*.5,extent))
			draw_set_transform_matrix(world_transform)
			if show_hitboxes:draw_arc(Stones.center(prop),Stones.radius(prop),0,TAU,32,Color("ffdf94"),1,true)
			continue
		if not view_rect.grow(140).has_point(at):continue
		if kind=="launcher":
			LaunchArt.draw(self,prop,biome,prop_base)
			draw_set_transform_matrix(world_transform)
			continue
		if kind=="spikes":
			HazardRoom.draw_spikes(self,prop["rect"]);continue
		if kind in ["ecology_object","coin_urn","merchant_table"]:continue
		if kind=="merchant":Adventure.merchant(self,at,clock,prop_base)
		var retained:bool=_is_start() and kind in ["aid","forge","reforge","mail","energy_infinite","wardrobe"]
		var extent:=Vector2.ZERO
		if kind=="spring":
			var wet:Rect2=layout.get("pool",Rect2())
			if wet.has_area():extent=Vector2(wet.size.x+50,105)
		if not retained and not GothicProps.draw_prop(self,prop,biome,prop_base,extent):
			if prop.get("used",false):continue
			EnvArt.prop(self,prop,biome,clock,prop_base,weapon_index)
		draw_set_transform_matrix(world_transform)
		if kind in ["launcher","grass","shop_dummy"] or prop.get("tutorial_fixture",false):continue
		var label:String={"wardrobe":"披風換裝站","gift_pedestal":"免費附武器展示台","forge":"藍圖鍛造台","reforge":"符文重鑄台","aid":"急救站","mail":"倉庫","dummy":"試打假人","energy_infinite":"無限能量花","energy":"砍破回能量","health":"砍破回滿生命","spring":"溫泉 · 回復生命與能量","chest":"寶箱","merchant":"貓頭鷹商人"}.get(kind,kind)
		var label_height:float=132 if kind in ["forge","reforge","mail","wardrobe"] else 92
		if _is_start() and kind in ["aid","forge","reforge","mail","energy_infinite","wardrobe","dummy"]:
			# One expanded prompt follows the same nearest-station target as interaction.
			var focused:bool=kind==focus.get("kind","")
			var short_label:String={"aid":"急救","forge":"鍛造","reforge":"重鑄","mail":"倉庫","energy_infinite":"能量","wardrobe":"披風","dummy":"試打"}.get(kind,label)
			var caption:String=label if focused else short_label
			var text_width:float=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
			_text(at-Vector2(text_width*.5,label_height),caption,14,Color("fff0c6") if focused else Color("b0c2b3"))
		else:_text(at-Vector2(40,label_height),label,14,accent)
	draw_set_transform_matrix(world_transform)
	if _rune_effect("orbit_shield")>0 or float(p.get("shield_item_left",0))>0:
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
	var factor:float=(.8 if injured else 1.0)*Tuning.value("move_speed")*(1.0+_rune_effect("run_speed"))
	if charge_timer>.15 and _key("attack"):factor*=.8
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
	return false # World stations use the interact-up action.

func _refresh_checkpoint_gift() -> void:
	room.erase("refresh_gift")
	room["gift_given"]=true
	var rack:Vector2=_furniture_offset()+Vector2(620,1050)
	if not props.any(func(prop:Dictionary)->bool:return prop["kind"]=="gift_pedestal"):
		props.append({"kind":"gift_pedestal","pos":rack,"used":false,"hurt":0.0})
		room["props"]=props
	drops=drops.filter(func(drop:Dictionary)->bool:return not drop.get("gift",false))
	var display:Vector2=rack-Vector2(0,90)
	drops.append({"kind":"weapon","pos":display,"value":Arsenal.random_index(rng),"seed":0.0,"taken":false,"gift":true,"display_only":true,"display_anchor":display})
	room["drops"]=drops

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
			hazard["hp"]=0.0;_sound("trap_break");_contact_fx("block",hazard["pos"]-Vector2(0,15));_particles(hazard["pos"],Color("d0e9c8"),8,100)
			if mode=="musou" and gain_dream and damage>0:dream.hit()
	for pr in projectiles:
		if not pr.get("trap_carrier",false) or pr.get("from_player",false) or float(pr["life"])<=0:continue
		if box.has_point(pr["pos"]):
			pr["life"]=0;pr["destroyed"]=true;_sound("trap_break");_contact_fx("block",pr["pos"])
			if mode=="musou" and gain_dream and damage>0:dream.hit()

func _open_chest(chest:Dictionary) -> void:
	if chest.get("used",false):return
	_prop_impact(chest,Vector2(chest["pos"])-Vector2(0,39),Vector2.UP,true,false)
	chest["used"]=true
	chest["open_left"]=preload("res://scripts/chest_art_v59.gd").DURATION
	var at:Vector2=chest["pos"]
	_drop("coin",at-Vector2(0,25),rng.randi_range(12,28))
	_drop("item",at-Vector2(35,30),rng.randi_range(0,Data.ITEMS.size()-1))
	if chest.get("guaranteed_strong",false):_drop("rune",at+Vector2(35,-30),Data.RUNES.size()+rng.randi_range(0,Data.STRONG_RUNES.size()-1))
	elif rng.randf()<.5:_drop("rune",at+Vector2(35,-30),_random_rune_index())
	else:_drop("weapon",at+Vector2(35,-30),Arsenal.random_index(rng))
	_feather_burst(at-Vector2(0,25),12);_sound("chest_open");_toast("寶箱已開啟！")

func _show_merchant(index:int=-1) -> void:
	if room.get("type","")!="merchant":return
	_sound("merchant_greet")
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
	_close_panel();_sound("coin_collect");_toast("購買完成，商品已正式加入行囊");_update_hud()

func _adapt_boss(en:Dictionary) -> void:
	if en.get("adapted",false) or float(en.get("hp",0))<=0:return
	en["adapted"]=true
	_sound(AudioCues.actor_cue(en,"phase","boss_phase"))
	en["attacks"].append(Combat.boss_phase_two(en))
	en["adaptations"]=["新攻擊"]
	_float(en["pos"]-Vector2(0,110),"首領覺醒",Color("ffbd89"));_toast(str(en["name"])+"進入第二階段：新招式已解放")

func _cast_special(at:Vector2,dir:Vector2,def:Dictionary) -> void:
	var kind:String=def["weapon_kind"]
	if kind=="laser":
		var direction:Vector2=dir.normalized()
		var beam_width:float=float(def.get("size",ProjectileReadability.BASE_RADIUS))*2.40
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

func _show_records() -> void:
	var rows:Array[Dictionary]=[{"text":"光榮返巢的冒險會在此保存武器組合、擊殺數與死亡次數，最多保留30次。"}]
	for record in meta.get("records",[]):
		var weapons:String=str(record["primary"])+" ＋ "+"／".join(record.get("secondary",[]))
		rows.append({"heading":str(record.get("date",""))+" · "+("無雙夢境" if record.get("mode","")=="musou" else "Roguelike"),"text":weapons+"\n擊殺 %d · 死亡 %d · 種子 %d"%[int(record["kills"]),int(record["deaths"]),int(record["seed"])]})
	if meta.get("records",[]).is_empty():rows.append({"text":"還沒有通關紀錄。選擇模式門，開始你的遠行。"})
	_panel("冒險紀錄",rows)

func _lab_button(label:String,callback:Callable) -> Button:
	var button:=Button.new();button.text=label;button.custom_minimum_size=Vector2(156,42);button.add_theme_font_override("font",font);button.add_theme_font_size_override("font_size",18)
	ui.style_button(button,UI.GOLD,7);button.pressed.connect(callback);return button
func _setup_home_credits() -> void:
	home_credits=HBoxContainer.new()
	home_credits.name="HomeCredits"
	home_credits.mouse_filter=Control.MOUSE_FILTER_IGNORE
	home_credits.add_theme_constant_override("separation",10)
	var version:=Label.new()
	version.text=PerfLog.VERSION
	version.add_theme_color_override("font_color",Color("b9cdc4"))
	version.add_theme_font_size_override("font_size",14)
	home_credits.add_child(version)
	var repository:=LinkButton.new()
	repository.text="GitHub"
	repository.uri=PROJECT_URL
	repository.tooltip_text="github.com/sai99claw/HollowLike"
	repository.add_theme_font_size_override("font_size",14)
	repository.add_theme_color_override("font_color",Color("ffe1a6"))
	home_credits.add_child(repository)
	ui.ui_root.add_child(home_credits)
	home_credits.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT,Control.PRESET_MODE_MINSIZE,12)

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
	var layer:=CanvasLayer.new();layer.layer=60;layer.transform=_safe_canvas_transform();add_child(layer)
	rd_view=RD.new();layer.add_child(rd_view)
	rd_view.closed.connect(func()->void:lab_mode="";layer.queue_free();rd_view=null;_clear_keys();_invalidate_scene())
func _enter_practice(tutorial:bool=false) -> void:
	room_clear_slow_left=0.0
	if screen!="hub":return
	Tuning.activate(meta.get("rd_tuning",{}))
	lab_meta=meta.duplicate(true)
	if tutorial:tutorial_previous_practice=practice_mode
	lab_mode="tutorial" if tutorial else "practice";lab_ai=true;practice_mode=true;practice_page="rooms"
	_close_panel();_clear_keys();bag_weapons.clear();bag_runes.clear();rune_slots.clear();strong_slots.clear();bag_items.clear();sub_growth.clear()
	for id:String in Arsenal.IDS:bag_weapons.append(Data.secondary_attack(Arsenal.index_of(id)))
	if not tutorial:
		for rune in Data.all_runes():bag_runes[rune["id"]]=99;meta["runes"][rune["id"]]=99
		for i in Data.ITEMS.size():bag_items[str(i)]=99
	secondary_index=0;weapon_index=1;run_coins=9999;mode="rogue";screen="game";room={};current_room=-1;injured=false;life_event.clear();feather.clear()
	tower={"seed":160016,"rooms":[{"id":0,"map_index":2,"type":"start","laboratory":true,"width":25,"height":15,"neighbors":{},"doors_config":{},"coord":Vector2i.ZERO,"visited":false,"initialized":false}],"maps":[]}
	if tutorial:
		var tutorial_room:Dictionary=tower["rooms"][0]
		tutorial_room["layout"]=_tutorial_layout()
		tutorial_room["width"]=24
		tutorial_room["height"]=9
	_reset_player(Vector2(300,896));_enter_room(0)
	if tutorial:
		upgrades={"count":0,"power":0.0,"reach":0.0,"haste":0.0,"charge":0.0,"shots":0,"subpower":0.0}
		run_coins=0
		for i in layout["one_way"].size():
			var ledge:Rect2=layout["one_way"][i]
			var anchor:=Vector2(ledge.get_center().x,ledge.position.y)
			var target:Dictionary=MonsterRoster.regular("trunk",[0,1,4][i])
			var patrol_x:float=ledge.size.x*.5-MonsterMotion.body_size(target).x*.5-12.0
			_add_tutorial_target(target,anchor,Vector2(patrol_x,0))
		var flyer:Dictionary=MonsterRoster.regular("trunk",MonsterRoster.REGULAR_COUNT-1)
		_add_tutorial_target(flyer,Vector2(1745,425),Vector2(155,36))
		_update_hud()
	else:_toast("練習房：全部武器、符文與怪物。能量無限，角色無敵。")

func _add_tutorial_target(target:Dictionary,anchor:Vector2,patrol:Vector2) -> void:
	if not _spawn_space_clear(anchor,MonsterMotion.body_size(target)):return
	target.merge({"uid":enemies.size()+1,"pos":anchor,"anchor":anchor,"vel":Vector2.ZERO,
		"face":-1.0,"hurt":0.0,"stun":0.0,"cooldown":0.0,"attack":Attack.new(),
		"contact_damage":0.0,"max_hp":target["hp"],"tutorial_respawn":0.0,"tutorial_patrol":patrol},true)
	enemies.append(target)

const TUTORIAL_STATIONS=["附武器試用","符文領取","動作與特效"]
const TutorialArt=preload("res://scripts/tutorial_art_v62.gd")

func _tutorial_layout() -> Dictionary:
	var floor_rect:=Rect2(0,768,2304,96)
	var ledges:Array[Rect2]=[Rect2(1280,675,192,18),Rect2(1570,592,192,18),Rect2(1870,645,224,18)]
	var collision_platforms:Array[Rect2]=[floor_rect]
	collision_platforms.append_array(ledges)
	var walls:Array[Rect2]=[floor_rect,Rect2(0,0,96,768),Rect2(2208,0,96,768),Rect2(0,0,2304,96)]
	return {"size":Vector2(2304,864),"floor_y":768.0,"ceiling_y":96.0,"seed":160016,"platforms":collision_platforms,"one_way":ledges,"platform_art_runs":ledges,"solids":walls,"spawn_positions":{"center":Vector2(175,768)}}

func _tutorial_key(action:String) -> String:
	return Bindings.label(int(key_bindings[action]))

func _tutorial_station_position(index:int) -> Vector2:
	return Vector2(360+index*235,_room_floor())

func _nearby_tutorial_station() -> int:
	for i in TUTORIAL_STATIONS.size():
		if Vector2(p["pos"]).distance_squared_to(_tutorial_station_position(i))<85.0*85.0:return i
	return -1

func _show_tutorial_station(index:int) -> void:
	if lab_mode!="tutorial" or index<0 or index>=TUTORIAL_STATIONS.size():return
	if index==2:
		_show_tutorial()
		return
	var entries:Array[Dictionary]=[]
	if index==0:
		for i in bag_weapons.size():
			var weapon:Dictionary=bag_weapons[i]
			var detail:String="%s\n傷害 %.1f · 投射物 %d · 能量 1"%[weapon["description"],weapon["damage"],int(weapon.get("count",1))]
			entries.append({"name":weapon["name"],"detail":detail,"icon":UI.Icons.secondary(weapon),"color":weapon.get("color",UI.MINT),"action":"lab_secondary","payload":i,"selected":i==secondary_index})
		_panel(TUTORIAL_STATIONS[index],[])
		ui.show_tutorial_items("%s 切換附武器，%s 出招。選好後到右邊的平台試打。"%[_tutorial_key("cycle"),_tutorial_key("sub")],entries,false)
	else:
		for rune in Data.all_runes():
			var strong:bool=rune.get("strong",false)
			entries.append({"name":rune["name"],"detail":rune["description"],"icon":UI.Icons.rune(rune["id"],strong),"color":UI.GOLD if strong else UI.Inventory.PURPLE,"action":"tutorial_rune","payload":rune["id"]})
		_panel(TUTORIAL_STATIONS[index],[])
		ui.show_tutorial_items("每次領取一枚，可重複領取。符文只用於本次教學。",entries,true)

func _show_tutorial() -> void:
	if lab_mode!="tutorial":return
	var jump:String=_tutorial_key("jump")
	var dash:String=_tutorial_key("dash")
	var attack:String=_tutorial_key("attack")
	var down:String=_tutorial_key("down")
	var sub:String=_tutorial_key("sub")
	var hold:float=_charge_threshold()
	var lessons:Array[Dictionary]=[
		{"id":"jump","name":"跳躍","detail":"地面按 %s。短按跳得低，長按跳得高；貼牆後可蹬牆。"%jump,"duration":1.7,"events":[[.55,"按下 %s"%jump],[.86,"放開 %s"%jump]]},
		{"id":"double_jump","name":"二段跳","detail":"離地後再按一次 %s，可在空中補一段高度。"%jump,"duration":2.1,"events":[[.55,"按下 %s"%jump],[.85,"空中再按 %s"%jump]]},
		{"id":"dash","name":"短衝刺","detail":"單按 %s，朝面向方向短衝。"%dash,"duration":1.5,"events":[[.55,"按下 %s"%dash]]},
		{"id":"pierce","name":"雙衝穿刺","detail":"第一次 %s 後半秒內再按一次，化成風向前穿刺。"%dash,"duration":1.8,"events":[[.55,"第一次 %s"%dash],[.79,"第二次 %s"%dash]]},
		{"id":"slam","name":"下砸","detail":"在空中按住 %s，半秒內連按兩次 %s，直落地面。"%[down,dash],"duration":1.9,"events":[[.25,"按住 %s"%down],[.55,"%s ＋ 第一次 %s"%[down,dash]],[.79,"%s ＋ 第二次 %s"%[down,dash]],[1.18,"落地衝擊"]]},
		{"id":"attack","name":"普通攻擊","detail":"按 %s 揮刀，可搭配方向鍵改變攻擊方向。"%attack,"duration":1.5,"events":[[.55,"按下 %s"%attack]]},
		{"id":"down_attack","name":"下劈","detail":"空中按住 %s 再按 %s，向下攻擊。"%[down,attack],"duration":1.7,"events":[[.30,"按住 %s"%down],[.55,"%s ＋ %s"%[down,attack]]]},
		{"id":"charged","name":"集氣拔刀斬","detail":"長按 %s 約 %.1f 秒，集氣完成後放開。"%[attack,hold],"duration":1.5+hold,"hold":hold,"events":[[.55,"按住 %s"%attack],[.55+hold,"放開 %s"%attack]]},
		{"id":"sub","name":"附武器","detail":"按 %s 使用目前裝備的附武器，空中也能施放。"%sub,"duration":1.9,"events":[[.55,"按下 %s"%sub]]},
	]
	_panel("動作與特效",[])
	ui.show_tutorial_lessons(lessons,str(_secondary()["id"]),"%s／%s 移動。選擇左側項目，右側會循環展示。"%[_tutorial_key("left"),_tutorial_key("right")])

func _tutorial_demo(action:String) -> void:
	_close_panel()
	_clear_keys()
	p_attack.cancel();pending_attack.clear();p["dash_t"]=0;dash_chain_open=false
	match action:
		"jump","double_jump":
			p["jump_buffer_left"]=.1;p["jump_released"]=false
			if action=="double_jump":
				p["pos"].y-=65;p["grounded"]=false;p["coyote_left"]=0;p["jumps"]=1
			else:
				p["grounded"]=true
		"dash":_dash_pressed()
		"pierce":_begin_dash_followup(Vector2(float(p["face"]),0))
		"slam":
			p["pos"].y-=145;p["grounded"]=false
			_begin_dash_followup(Vector2.DOWN)
		"attack","charged","down_attack":
			var direction:String="right" if float(p["face"])>0 else "left"
			if action=="down_attack":
				p["pos"].y-=135;p["grounded"]=false
				direction="down"
			_begin_primary({"dir":direction,"charged":action=="charged"})
		"sub":_begin_secondary()

func _draw_tutorial_stations(focus:Dictionary) -> void:
	var index:int=int(focus.get("index",-1)) if focus.get("kind","")=="tutorial" else -1
	if index>=0:
		var at:Vector2=_tutorial_station_position(index)+Vector2(0,14)
		var prompt:String="%s · 按 %s 互動"%[TUTORIAL_STATIONS[index],_tutorial_key("up")]
		var width:float=font.get_string_size(prompt,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
		draw_rect(Rect2(at-Vector2(width*.5+9,0),Vector2(width+18,25)),Color("#101c1aee"))
		_text(at+Vector2(-width*.5,17),prompt,15,Color("edf8de"))
	for en in enemies:
		if en.has("tutorial_respawn") and float(en["hp"])<=0:
			_text(Vector2(en["anchor"])-Vector2(37,24),"%.1f 秒"%float(en["tutorial_respawn"]),16,Color("b9f5d6"))

func _leave_lab() -> void:
	if lab_mode in ["rd","tuning"]:return
	if lab_mode in ["practice","tutorial"]:meta=lab_meta.duplicate(true);lab_meta.clear()
	practice_mode=tutorial_previous_practice if lab_mode=="tutorial" else false
	lab_mode="";lab_ai=true;freeze_timer=0;_close_panel();_ui_action("hub",null);_update_hud()

func _open_practice_rd() -> void:
	if lab_mode!="practice" or practice_rd_panel!=null:return
	_close_panel();_clear_keys()
	var layer:=CanvasLayer.new();layer.layer=61;layer.transform=_safe_canvas_transform();add_child(layer)
	practice_rd_panel=PracticeRD.new();layer.add_child(practice_rd_panel);practice_rd_panel.setup(practice_rd_settings)
	practice_rd_panel.regenerate.connect(_regenerate_practice)
	practice_rd_panel.closed.connect(func()->void:practice_rd_panel=null;layer.queue_free();_clear_keys();_invalidate_scene())

func _regenerate_practice(parameters:Dictionary) -> void:
	if lab_mode!="practice":return
	practice_rd_settings=PracticeRD.DEFAULTS.duplicate();practice_rd_settings.merge(parameters,true)
	var kind:String=practice_rd_settings["room_kind"]
	if not parameters.has("room_kind") and parameters.get("arena",false):kind="arena"
	if not PracticeRD.ROOM_TYPES.any(func(option:Array)->bool:return option[1]==kind):kind="combat"
	practice_rd_settings["room_kind"]=kind
	var actual_type:String=kind if kind in ["elite","boss","start","merchant","reward"] else "combat"
	var forced_hazard:String=kind if kind in ["spike_islands","mushroom_air"] else ""
	var options:Dictionary=practice_rd_settings;var seed_value:int=int(options["seed"])
	if seed_value<=0:seed_value=rng.randi_range(1,2000000000)
	var biome:String=str(options["biome"]);var stage:int={"underground":0,"trunk":2,"sky":4}.get(biome,2)
	var definition:Dictionary={"id":0,"map_index":stage,"type":actual_type,"laboratory":true,"practice_hazard":forced_hazard,"practice_arena":kind=="arena","practice_density":float(options["enemy_density"]),"layout_profile":str(options["profile"]),"plaza_scale":float(options["plaza_scale"]),"maze_config":{"straight_bias":float(options["straight_bias"]),"braid_rate":float(options["braid_rate"]),"corridor_width_mode":"random","dead_end_chance":clampf(float(options.get("dead_end_chance",.25)),.2,1)},"maze_seed":seed_value,"width":clampi(int(options["width"])|1,17,25),"height":clampi(int(options["height"])|1,11,17),"neighbors":{},"doors_config":{},"coord":Vector2i.ZERO,"visited":false,"initialized":false}
	# This is an isolated laboratory room; keep the current loadout and bag.
	room={};enemies=[];drops=[];corpses=[];props=[];current_room=-1;life_event.clear();feather.clear()
	tower={"seed":seed_value,"rooms":[definition],"maps":[]}
	_clear_keys();p_attack.cancel();_reset_player(Vector2(300,896));_enter_room(0)
	_toast("練習房已重生 · "+_ecology()["name"]+" · 種子 %d"%seed_value)
func _show_practice() -> void:
	if lab_mode!="practice":return
	var tabs:Array[Dictionary]=[]
	for entry in [["rooms","房型生成"],["monsters","怪物召喚"],["equipment","武器與符文"],["controls","測試控制"]]:
		tabs.append({"label":("◆ " if practice_page==entry[0] else "")+entry[1],"action":"lab_page","payload":entry[0]})
	var sections:Array[Dictionary]=[{"buttons":tabs}]
	match practice_page:
		"rooms":
			var room_buttons:Array[Dictionary]=[]
			for entry:Array in PracticeRD.ROOM_TYPES:
				room_buttons.append({"label":entry[0],"action":"lab_room","payload":entry[1]})
			sections.append({"heading":"選擇並生成房型","text":"會清空目前房間內的怪物與掉落物，保留你的裝備。","buttons":room_buttons})
			sections.append({"buttons":[{"label":"生態、地形與種子","action":"lab_terrain"}]})
		"monsters":
			var names:Array[String]=_lab_monsters()
			var regular:Array[Dictionary]=[];var elites:Array[Dictionary]=[];var bosses:Array[Dictionary]=[]
			for index in names.size():
				var button:Dictionary={"label":names[index],"action":"lab_monster","payload":index}
				if names[index].begins_with("Boss"):bosses.append(button)
				elif names[index].begins_with("菁英"):elites.append(button)
				else:regular.append(button)
			sections.append({"heading":"小怪","buttons":regular})
			sections.append({"heading":"菁英怪","buttons":elites})
			sections.append({"heading":"首領","buttons":bosses})
		"equipment":
			sections.append({"heading":"武器與符文","buttons":[{"label":"符文配置","action":"lab_runes"}]})
			for i in bag_weapons.size():
				sections.append({"text":bag_weapons[i]["description"],"buttons":[{"label":"裝備 "+str(bag_weapons[i]["name"]),"action":"lab_secondary","payload":i}]})
		"controls":
			sections.append({"heading":"測試控制","buttons":[{"label":"清空怪物與彈體","action":"lab_clear"},{"label":"怪物 AI："+("開" if lab_ai else "停"),"action":"lab_ai"}]})
	_panel("練習工具",sections)
func _lab_monsters() -> Array[String]:
	var names:Array[String]=[]
	for i in 5:names.append(MonsterRoster.regular("underground",i)["name"])
	for i in 5:names.append("菁英："+str(MonsterRoster.elite(i)["name"]))
	names.append("可愛遊盪者")
	for biome:String in ["underground","grass","trunk","branches","canopy","sky"]:names.append("Boss："+str(Combat.boss(biome)["name"]))
	for biome:String in ["trunk","sky"]:
		for i in 5:names.append(MonsterRoster.regular(biome,i)["name"])
	names.append("菁英："+str(MonsterRoster.elite(5)["name"]))
	for biome:String in ["underground","trunk","sky"]:
		for row in 5:
			names.append(("菁英：" if row>=3 else "")+str(NewRoster.create(biome,row,0)["name"]))
	for biome:String in Ecology.IDS:names.append(MonsterRoster.regular(biome,MonsterRoster.REGULAR_COUNT-1)["name"])
	return names
func _summon_monster(index:int,anchor:Vector2=Vector2.INF) -> void:
	if lab_mode not in ["practice","tutorial"] or index<0 or index>=_lab_monsters().size():return
	var definition:Dictionary
	if index>=43:definition=MonsterRoster.regular(Ecology.IDS[index-43],MonsterRoster.REGULAR_COUNT-1)
	elif index>=28:
		var offset:int=index-28
		var family:int=offset/5
		definition=NewRoster.create(["underground","trunk","sky"][family],offset%5,family*2)
	elif index>=11 and index<=16:definition=Combat.boss(["underground","grass","trunk","branches","canopy","sky"][index-11])
	elif index==10:definition=Arms.cute_wanderer(rng)
	elif index<5:definition=MonsterRoster.regular("underground",index)
	elif index<10:definition=MonsterRoster.elite(index-5)
	elif index==27:definition=MonsterRoster.elite(5)
	else:definition=MonsterRoster.regular("trunk" if index<22 else "sky",index-17)
	if definition.get("elite",false):definition["hp"]*=3.0
	definition["hp"]*=Tuning.value("enemy_hp");definition["speed"]*=Tuning.value("enemy_speed")
	spawn_serial+=1
	var at:=anchor if anchor.is_finite() else Vector2(clampf(p["pos"].x+float(p["face"])*240,260,_room_size().x-260),_room_floor())
	if definition.get("spawn_surface")=="flight":at.y-=180
	definition.merge({"uid":100000+spawn_serial,"pos":at,"anchor":at,"spawn_platform":0,"biome":definition.get("biome",_ecology()["id"]),"ecology_id":_ecology()["id"],"vel":Vector2.ZERO,"face":-1.0,"hurt":0.0,"stun":0.0,"cooldown":1.0,"attack":Attack.new(),"contact_damage":float(definition.get("contact_damage",1.0)),"max_hp":definition["hp"]},true)
	var placement:Vector2=_enemy_spawn(definition)
	if not placement.is_finite():_toast("附近沒有足夠空間，請換個位置召喚這隻怪物");return
	definition["pos"]=placement;definition["anchor"]=placement;definition["spawn_home"]=placement
	enemies.append(definition);_toast("召喚："+_lab_monsters()[index])

func _paint_static_props(c:CanvasItem) -> void:
	if screen!="game":return
	for prop:Dictionary in props:
		var kind:String=prop["kind"]
		if (_is_start() and kind in ["aid","forge","reforge","mail","energy_infinite","wardrobe"]) or kind in ["ecology_object","coin_urn"]:
			var extent:Vector2=BiomeArt.object_size(prop.get("variant",0)) if kind=="ecology_object" else Vector2.ZERO
			GothicProps.draw_prop(c,prop,str(_ecology()["id"]),preload("res://scripts/world_placement_v27.gd").prop_base(),extent)

func _enemy_pose_clock(en:Dictionary) -> float:
	return float(en["frost_pose_clock"]) if float(en.get("frost_left",0))>0 else (float(en["impact_pose_clock"]) if float(en.get("impact_freeze_left",0))>0 else draw_clock)

func _paint_enemy_body(canvas:CanvasItem,en:Dictionary) -> void:
	if en.get("training",false):
		GothicProps.draw_prop(canvas,{"kind":"dummy","pos":en["pos"],"gothic_broken":en.get("gothic_broken",false)},str(_ecology()["id"]),Transform2D.IDENTITY,MonsterMotion.body_size(en))
		return
	_paint_enemy_actor(canvas,en)
	var melt:float=clampf(float(en.get("frost_left",0))/2.0,0.0,1.0)
	if melt<=0:return
	var ice:Rect2=_enemy_body_box(en).grow(6)
	var height:float=ice.size.y*lerpf(.15,1.25,melt)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
	canvas.draw_texture_rect(preload("res://assets/v55/effects/frost.svg"),Rect2(Vector2(ice.position.x-4,ice.end.y-height),Vector2(ice.size.x+8,height)),false,Color(1,1,1,.50))

func _paint_enemy_actor(canvas:CanvasItem,en:Dictionary) -> void:
	var pose_clock:float=_enemy_pose_clock(en)
	if NewMonsterArt.draw_actor(canvas,en,pose_clock,Transform2D.IDENTITY):return
	var atk=en["attack"]
	var kind:String={0:"melee",1:"ranged",2:"fly",3:"elite",4:"boss",5:"elite"}.get(int(en["model"]),"melee")
	if int(en["model"])==4:BossVisual.draw(canvas,en,pose_clock,Transform2D.IDENTITY)
	elif not MonsterDesign.draw_actor(canvas,en,pose_clock,Transform2D.IDENTITY):
		var phase:String="hurt" if float(en["hurt"])>0 else atk.phase
		var progress:float=1-float(en["hurt"])/.2 if phase=="hurt" else atk.progress()
		if phase=="idle" and str(en.get("visual_movement",""))=="dash":
			if float(en.get("motion_dash_wait",0))<0:phase="prepare";progress=1+float(en["motion_dash_wait"])/float(en.get("dash_windup",.5))
			elif float(en.get("motion_dash_wait",0))>0:phase="brake";progress=1-float(en["motion_dash_wait"])/.9
		if phase=="idle" and str(en.get("visual_movement",""))=="drift" and float(en.get("turn_left",0))>0:phase="turn";progress=1-float(en["turn_left"])/.25
		var clip:String=FX.enemy_clip(en,phase)
		if not FX.actor(canvas,clip,progress,en["pos"],Transform2D.IDENTITY,float(en["face"]),float(en["scale"]),Color.WHITE,phase,pose_clock if phase=="idle" else -1,str(en.get("visual_movement",en.get("movements",["walk"])[0])) in ["hover","drift"]):
			Sprites.enemy(canvas,en["pos"],float(en["face"]),pose_clock,kind,phase,atk.progress(),Transform2D.IDENTITY,not bool(atk.attack.get("primary",true)),float(en["scale"]))
		if en.get("elite",false):
			var weapon:String=str(en["attacks"][1].get("weapon_visual","weapon_heavy"))
			if not FX.frame(canvas,weapon,0,en["pos"]+Vector2(float(en["face"])*23,-28),Transform2D.IDENTITY,float(en["face"]),46):
				canvas.draw_line(en["pos"]+Vector2(20,-5),en["pos"]+Vector2(35,-55),Color("dfc2a5"),5)
			_text_on(canvas,en["pos"]-Vector2(20,75),"菁英",12,Color("ffd7a1"))

func _sync_enemy_canvases() -> void:
	if not perf_log.active:
		_sync_enemy_canvases_profiled_body();return
	var measured:int=Time.get_ticks_usec()
	_sync_enemy_canvases_profiled_body()
	perf_log.span("process.actor_sync",Time.get_ticks_usec()-measured)

func _sync_enemy_canvases_profiled_body() -> void:
	var alive:Dictionary={}
	for en:Dictionary in enemies:
		if float(en["hp"])<=0 and float(en.get("flash_left",0))<=0:continue
		var id:int=int(en["uid"]);alive[id]=true
		var enabled:bool=screen=="game" and view_rect.intersects(_enemy_body_box(en).grow(24))
		if not enemy_canvases.has(id):
			if not enabled and float(en.get("flash_left",0))<=0:continue
			var fresh=EnemyCanvas.new();fresh.profiler=perf_log;fresh.local_origin=true;fresh.toon=not en.get("training",false);fresh.paint=_paint_enemy_body;add_child(fresh);enemy_canvases[id]=fresh
		var sprite=enemy_canvases[id];sprite.actor=en
		var attack=en["attack"]
		var pose_clock:float=_enemy_pose_clock(en)
		var signature:Array=[int(pose_clock*30),en.get("face",1),attack.phase,int(attack.progress()*60),int(float(en.get("hurt",0))*60),en.get("scale",1),int(float(en.get("turn_left",0))*60)]
		if en.has("roster_id") and not en.get("training",false):
			var sample:Dictionary=NewMonsterArt.actor_sample(en,pose_clock) if en.has("v55_row") else preload("res://scripts/monster_art_v36.gd").actor_sample(en,pose_clock)
			signature=[sample["sheet"],sample["row"],sample["column"],en.get("face",1),float(en.get("hurt",0))>0,en.get("scale",1)]
		signature.append(ceili(float(en.get("frost_left",0))*15))
		signature.append(en.get("gothic_broken",false))
		var base:Transform2D=world_transform if en.get("training",false) else world_transform.translated_local(Vector2(0,5))
		sprite.refresh(base,enabled,signature)
		if enabled and sprite.toon:sprite.transform*=Juice.enemy_pose(en,draw_clock)
	for id in enemy_canvases.keys():
		if not alive.has(id):enemy_canvases[id].queue_free();enemy_canvases.erase(id)

func _start_player_slash() -> void:
	var def:Dictionary=p_attack.attack
	if not def.get("primary",false) or (def.get("charged",false) and not def.get("great_spin_release",false)):return
	while not player_slashes.is_empty() and (draw_clock-float(player_slashes[0]["start"]))*float(player_slashes[0]["definition"].get("animation_rate",1.0))>=SlashArt.DURATION:
		player_slashes.pop_front()
	if player_slashes.size()>=8:player_slashes.pop_front()
	var definition:Dictionary=def.duplicate()
	if not definition.has("direction"):definition["direction"]="right" if p["face"]>0 else "left"
	player_slashes.append({"definition":definition,"start":draw_clock})

func _paint_player_slash(canvas:CanvasItem) -> void:
	if screen not in ["game","hub"]:return
	for slash:Dictionary in player_slashes:
		var definition:Dictionary=slash["definition"]
		SlashArt.draw(canvas,_player_strike_box(definition),definition,(draw_clock-float(slash["start"]))*float(definition.get("animation_rate",1.0)),world_transform)

func _pogo() -> void:
	p["jump_cut_allowed"]=false;p["recoil_left"]=0;p["wall_kick_left"]=0
	p["vel"].y=-PlayerMotion.POGO_SPEED;p["grounded"]=false
	p["air_dash"]=false;p["jumps"]=1;p["invul"]=maxf(.14,float(p["invul"]))

func _melee_hitstop() -> void:
	if not p_attack.is_active() or not p_attack.attack.get("primary",false):return
	var style:String=str(p_attack.attack.get("style","foot"))
	hitstop=maxf(hitstop,{"foot":.05,"quick":4.0/60,"heavy":.08}.get(style,.05))

func _charge_threshold() -> float:
	return Tuning.value("charge_seconds")*maxf(.25,1.0-_rune_effect("charge_cut"))/(1+float(upgrades["charge"])*.08)

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
	var layer:=CanvasLayer.new();layer.layer=60;layer.transform=_safe_canvas_transform();add_child(layer)
	tuning_view=TuningPanel.new();layer.add_child(tuning_view);tuning_view.setup(meta.get("rd_tuning",{}))
	tuning_view.saved.connect(func(parameters:Dictionary)->void:meta["rd_tuning"]=parameters;_save_meta())
	tuning_view.closed.connect(func()->void:lab_mode="";layer.queue_free();tuning_view=null;_clear_keys();_invalidate_scene())

func _update_corpses(delta:float) -> void:
	if not perf_log.active:
		_update_corpses_profiled_body(delta);return
	var measured:int=Time.get_ticks_usec()
	_update_corpses_profiled_body(delta)
	perf_log.span("physics.corpses",Time.get_ticks_usec()-measured)

func _update_corpses_profiled_body(delta:float) -> void:
	var changed:bool=false
	for body:Dictionary in corpses:
		if CorpseField.step(body,delta,solids,platforms,_room_size()):changed=true
	if changed and corpse_layer!=null:corpse_layer.invalidate()

func _paint_corpses(canvas:CanvasItem) -> void:
	if screen!="game":return
	for body:Dictionary in corpses:
		if float(body.get("hit_actor",{}).get("flash_left",0))<=0:CorpseField.draw(canvas,body)

func _paint_edge_background(canvas:CanvasItem) -> void:
	if screen=="game":NewBiome.draw_details(canvas,str(_ecology()["id"]),layout,-1,terrain_region)

func _paint_edge_foreground(canvas:CanvasItem) -> void:
	if screen=="game":NewBiome.draw_details(canvas,str(_ecology()["id"]),layout,1,terrain_region)

func _paint_player_flash(canvas:CanvasItem,_actor:Dictionary) -> void:
	Art.draw_pigeon(canvas,p["pos"],float(p["face"]),clock,"hurt",Color.WHITE,1.0,1-float(p.get("hurt",0))/.25,Transform2D.IDENTITY,str(Data.PRIMARY[weapon_index]["style"]),p_attack.attack)

func _mushroom_bodies() -> Array[Rect2]:
	var bodies:Array[Rect2]=[]
	for prop:Dictionary in props:
		if prop["kind"]=="launcher":bodies.append(LaunchArt.body_box(prop))
	return bodies

func _launch_from_object(prop:Dictionary,strike:Vector2) -> void:
	if _wind_form_active():p_attack.cancel()
	var down_cut:bool=strike.y>.5
	var side_cut:bool=absf(strike.x)>.5
	var normal_speed:float=JUMP_SPEED*(1+_rune_effect("wing"))*Tuning.value("jump_speed")
	var lateral:float=-signf(strike.x)*480.0 if side_cut else float(p["vel"].x)
	p["vel"]=Vector2(lateral,-normal_speed*sqrt(3.0) if down_cut else -normal_speed*.38)
	# Swept down-slam contacts happen inside the AABB step. Preserve the new
	# impulse after its local collision result is committed at step end.
	if p.get("_motion_step",false):p["launch_pending_velocity"]=p["vel"]
	p["grounded"]=false;p["wall"]=0;p["dash_t"]=0;p["slam"]=false
	p["recoil_left"]=.16 if side_cut else 0.0
	p["recoil_velocity"]=Vector2(lateral,0)
	p["recoil_base_y"]=p["vel"].y
	p["knockback_t"]=0;p["jump_cut_allowed"]=false
	p["jump_buffer_left"]=0;p["coyote_left"]=0;p["landing_left"]=0;p["heavy_land_left"]=0;p["fall_distance"]=0
	_restore_ground_movement()
	prop["launch_left"]=.625;prop["launch_cooldown"]=.45
	if not strike.is_zero_approx():prop["launch_hit_cooldown"]=.15
	_sound("mushroom_pogo" if down_cut else ("mushroom_side" if side_cut else "mushroom_bounce"))

func _unlock_blueprint(id:String) -> void:
	if Arsenal.index_of(id)<0:return
	if not meta.has("blueprints"):meta["blueprints"]=[]
	if not meta["blueprints"].has(id):meta["blueprints"].append(id)

func _acquire_weapon(weapon:Dictionary) -> String:
	_unlock_blueprint(str(weapon.get("id","")))
	if lab_mode.is_empty():_collect_trophy("weapons",str(weapon.get("id","")))
	var result:String
	if mode=="rogue" and lab_mode.is_empty() and not bag_weapons.is_empty():
		var held:Dictionary=bag_weapons[posmod(secondary_index,bag_weapons.size())]
		var bonus:int=int(held.get("duplicate_bonus",0))
		result="max" if bonus>=Arsenal.MAX_DUPLICATES else "upgrade"
		held["duplicate_bonus"]=mini(bonus+1,Arsenal.MAX_DUPLICATES)
		weapon=held
	else:result=Arsenal.acquire(bag_weapons,weapon,mode)
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
	_sound("heavy_land")
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


func _setup_performance_log() -> void:
	atmosphere.profiler=perf_log
	for entry:Array in [[backdrop,"background"],[terrain,"terrain"],[static_props,"props"],[edge_background,"edge_back"],[edge_foreground,"edge_front"],[corpse_layer,"corpses"],[minimap,"minimap"],[slash_canvas,"slash"],[atmosphere.middle,"middle"],[atmosphere.middle_objects,"middle_objects"],[atmosphere.near_layer,"near"]]:
		entry[0].profiler=perf_log;entry[0].profile_name="draw.cache."+str(entry[1])
	player_flash_layer.profiler=perf_log
	if OS.has_feature("web"):
		perf_bridge=JavaScriptBridge.get_interface("PigeonPerf")
		if perf_bridge!=null:
			perf_callback=JavaScriptBridge.create_callback(_performance_command)
			perf_bridge.register(perf_callback)

func _performance_context() -> Dictionary:
	var measured:int=Time.get_ticks_usec()
	var alive:int=0;var seen:int=0;var training:int=0;var passive:int=0
	for en:Dictionary in enemies:
		if float(en.get("hp",0))<=0:continue
		if en.get("training",false):training+=1;continue
		if en.get("passive",false):passive+=1;continue
		alive+=1
		if view_rect.has_point(en.get("pos",Vector2.ZERO)):seen+=1
	var emitters:int=0;var amount:int=0
	for node in find_children("*","CPUParticles2D",true,false):
		if node.emitting and node.is_visible_in_tree() and node.process_mode!=Node.PROCESS_MODE_DISABLED:emitters+=1;amount+=node.amount
	var context:Dictionary={"screen":screen,"mode":mode,"room":current_room,"map":int(room.get("map_index",-1))+1,"type":room.get("type","hub"),"paused":perf_paused or ui.is_panel_open() or minimap_open or not life_event.is_empty() or practice_rd_panel!=null,"hitstop":hitstop>0,"lab":lab_mode,"zoom":snappedf(_view_zoom(),.01),"low_fx":low_effects,"enemy_alive":alive,"enemy_visible":seen,"training":training,"passive":passive,"solids":solids.size(),"platforms":platforms.size(),"corners":layout.get("art_corners_v21",[]).size(),"edge_decor":layout.get("edge_details_v23",[]).size(),"middle_objects":atmosphere.middle_structures.size(),"projectiles":projectiles.size(),"hazards":hazards.size(),"drops":drops.size(),"props":props.size(),"effects":effects.size(),"emitters":emitters,"particle_budget":amount,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"engine_process_ms":snappedf(Performance.get_monitor(Performance.TIME_PROCESS)*1000,.001),"engine_physics_ms":snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,.001),"static_mib":snappedf(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,.01),"vram_mib":snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,.01),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"render_size":str(get_viewport().get_texture().get_size()),"window_size":str(get_window().size),"stretch_mode":get_window().content_scale_mode}
	if perf_bridge!=null:context["browser"]=JSON.parse_string(str(perf_bridge.sample()))
	if perf_log.active:perf_log.span("recorder.snapshot",Time.get_ticks_usec()-measured)
	return context

func _performance_pause() -> void:
	perf_paused=true;_clear_keys()

func _performance_resume() -> void:
	perf_paused=false;_clear_keys()

func _performance_command(arguments:Array) -> void:
	if arguments.is_empty():return
	match str(arguments[0]):
		"panel":_performance_pause()
		"resume":_performance_resume()
		"start":
			_performance_resume()
			if ui.is_panel_open():_close_panel()
			var info:Dictionary={"version":PerfLog.VERSION,"utc":Time.get_datetime_string_from_system(true),"godot":Engine.get_version_info().get("string",""),"platform":OS.get_name(),"debug_build":OS.is_debug_build(),"max_fps":Engine.max_fps,"vsync_mode":DisplayServer.window_get_vsync_mode(),"renderer":ProjectSettings.get_setting("rendering/renderer/rendering_method")}
			if perf_bridge!=null:info["browser"]=JSON.parse_string(str(perf_bridge.environment()))
			perf_log.start(info,_performance_context())
			if perf_bridge!=null:perf_bridge.status(true)
		"mark":perf_log.mark(_performance_context())
		"stop":
			perf_log.stop(_performance_context());_show_performance_report()

func _show_performance_report() -> void:
	_performance_pause()
	if perf_bridge!=null:perf_bridge.status(false);perf_bridge.show_report(perf_log.last_report)
	else:
		var output:=FileAccess.open("user://pigeon-perf-last.txt",FileAccess.WRITE)
		if output!=null:output.store_string(perf_log.last_report)
