extends SceneTree
const Data=preload("res://scripts/game_data.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func reset(game) -> void:
	game.life_event.clear();game._close_panel();game._clear_keys();game.p_attack.cancel();game._reset_player(Vector2(700,1050));game.hitstop=0;game.room_cooldown=999
	game.enemies.clear();game.props.clear();game.doors.clear();game.effects.clear();game.projectiles.clear();game.hazards.clear();game.solids.clear();game.injured=false
	game.layout={"size":Vector2(1500,1120),"floor_y":1050.0};game.platforms.assign([Rect2(0,1050,1500,70)]);game.world_speed=1;game.p["invul"]=0;game.ui.clear_attack_feedback()
func keyboard(game,key:int,pressed:bool=true,echo:bool=false) -> void:
	var event:=InputEventKey.new();event.physical_keycode=key;event.pressed=pressed;event.echo=echo;game._input(event)
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false)
	game.practice_mode=true;game.new_run("rogue",202020)
	# Death blocks input until the rune choice; soul returns to the checkpoint.
	reset(game);var seed_before:int=int(game.tower["seed"]);game.revive_used=true;game._death();keyboard(game,KEY_X,true,true);keyboard(game,KEY_X)
	check(game.life_event.get("kind","")=="death" and not game.p_attack.is_busy(),"Death animation blocks keyboard attacks")
	for frame in 300:
		game._physics_process(1.0/60)
		if game.life_event.get("kind")=="await_choice":break
	check(game.life_event.get("kind")=="await_choice" and game.ui.is_panel_open(),"Death reaches rune selection after landing")
	game._choose_soul_rune("");game._update_life_event(1.41)
	check(game.life_event.is_empty() and int(game.tower["seed"])==seed_before and not game.ui.is_panel_open(),"Soul returns to the same adventure after selection")
	reset(game);game.life_event={"kind":"injury"};game._set_action("attack",true);check(not game.p_attack.is_busy(),"Injury flight still blocks attack input")
	reset(game);game.p["dash_t"]=.16;game._set_action("attack",true);game._set_action("attack",false);game.p_attack.tick(.161);game._update_hud()
	check(game.ui.phase_label.is_visible_in_tree() and game.ui.phase_bar.is_visible_in_tree() and "後搖" in game.ui.phase_label.text and "1.9" in game.ui.phase_label.text,"Heavy recovery shows an actual remaining duration")
	check("C 可取消" in game.ui.phase_label.text,"Recovery explains the mapped dash cancel")
	game.key_bindings["dash"]=KEY_V;game._update_hud();check("V 可取消" in game.ui.phase_label.text,"Recovery prompt follows rebound controls");game.key_bindings["dash"]=KEY_C
	var id:int=game.p_attack.attack_id;game._set_action("attack",true);game._set_action("attack",false)
	check(game.ui.attack_feedback_reason=="busy" and "尚未就緒" in game.ui.phase_label.text,"Rejected recovery press gives immediate feedback")
	await process_frame
	check(game.ui.header.get_global_rect().end.y<game.ui.prep_button.position.y and game.ui.header.get_global_rect().end.x<800,"Recovery feedback stays clear of room and top controls")
	game.p_attack.tick(4);game._physics_process(.016)
	check(game.p_attack.attack_id==id and not game.p_attack.is_busy() and game.pending_attack.is_empty(),"Rejected attack is discarded, never queued")
	game._set_action("attack",true);game._set_action("attack",false);game.p_attack.tick(.161);game.clock=10;game.ui.reject_attack("busy");game._dash_pressed();game._update_hud()
	check(not game.p_attack.is_busy() and "可出擊" in game.ui.phase_label.text,"Dash really cancels the displayed recovery")
	reset(game);game.bag_weapons.assign([Data.secondary_attack(0)]);game.p["energy"]=0;var before:int=game.p_attack.attack_id
	game._set_action("sub",true);game._set_action("sub",false)
	check(game.ui.attack_feedback_reason=="energy" and "能量不足" in game.ui.phase_label.text and "近戰命中" in game.ui.message_label.text,"Empty energy names the reason and the way to recover")
	check(game.p_attack.attack_id==before and not game.p_attack.is_busy() and game.p["energy"]==0 and game.projectiles.is_empty(),"Empty sidearm input spends nothing and creates no hidden cast")
	game.ui._process(.05);check(game.ui.energy_label.modulate!=Color.WHITE and game.ui.energy_cells.modulate!=Color.WHITE,"Empty energy pulses both the number and cells")
	game.ui._process(1);check(game.ui.energy_label.modulate==Color.WHITE,"Energy warning expires without leaving a permanent tint")
	game.p["energy"]=2;game._set_action("sub",true);check(game.p_attack.is_busy() and game.p["energy"]==1 and game.ui.attack_feedback_reason.is_empty(),"A fresh funded cast clears rejection and spends exactly one cell")
	reset(game);game.bag_weapons.clear();game._set_action("sub",true)
	check(game.ui.attack_feedback_reason=="no_weapon" and "免費副武器" in game.ui.message_label.text,"Missing equipment has its own explanation")
	game.queue_free();await process_frame;print("v20 input and feedback: ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
