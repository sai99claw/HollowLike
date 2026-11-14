class_name EnemyMotion
extends RefCounted
## Stable steering plus an explicit, locked-direction charge state machine.
const GRAVITY:float=1250.0
const Flight=preload("res://scripts/flight_navigation.gd")

static func prepare(en:Dictionary) -> void:
	if en.has("motion_index"):return
	en["motion_index"]=0;en["motion_left"]=float(en.get("movement_period",2.8));en["motion_clock"]=0.0
	en["motion_anchor"]=en["pos"];en["home"]=en.get("home",en["pos"])
	en["roam_target"]=en["pos"];en["roam_left"]=0.0;en["motion_stopped"]=false
	en["jump_left"]=0.65;en["motion_dash_left"]=0.0;en["motion_dash_wait"]=0.0
	en["motion_dash_dir"]=float(en.get("face",1));en["charge_vector"]=Vector2.RIGHT
	en["charge_phase"]="idle";en["charge_left"]=0.0;en["charge_cooldown"]=0.0
	en["facing_candidate"]=float(en.get("face",1));en["facing_left"]=0.0

static func current(en:Dictionary) -> String:
	var options:Array=en.get("movements",["drift"] if en.get("move","walk")=="fly" else ["walk"])
	if options.is_empty():return "walk"
	return str(options[int(en.get("motion_index",0))%options.size()])

static func airborne(en:Dictionary) -> bool:
	return current(en) in ["hover","drift"] or (current(en)=="dash" and en.get("move","")=="fly")

static func update_facing(en:Dictionary,target_x:float,delta:float) -> float:
	var face:float=float(en.get("face",1))
	if str(en.get("charge_phase","idle")) in ["windup","active"]:return face
	if en.has("attack") and en["attack"].is_busy():return face
	var distance:float=target_x-float(en["pos"].x)
	if absf(distance)<float(en.get("facing_deadzone",28)):
		en["facing_left"]=0.0;return face
	var candidate:float=signf(distance)
	if candidate==face:en["facing_left"]=0.0;return face
	if float(en.get("facing_candidate",face))!=candidate:
		en["facing_candidate"]=candidate;en["facing_left"]=0.0
	en["facing_left"]=float(en.get("facing_left",0))+delta
	if float(en["facing_left"])>=float(en.get("turn_delay",.18)):
		en["face"]=candidate;en["facing_left"]=0.0;en["turn_left"]=.16
	return float(en.get("face",face))

static func can_attack(en:Dictionary) -> bool:
	if str(en.get("charge_phase","idle")) in ["windup","active","recovery"]:return false
	return not (current(en)=="dash" and float(en.get("charge_cooldown",0))<=0)

static func _finish_charge(en:Dictionary) -> void:
	en["charge_phase"]="recovery";en["charge_left"]=float(en.get("dash_recovery",.65))
	en["motion_dash_left"]=0.0;en["motion_dash_wait"]=float(en["charge_left"])
	en["charge_cooldown"]=float(en.get("dash_cooldown",3.4))

static func resolve_collision(en:Dictionary,requested_velocity:Vector2,resolved_velocity:Vector2) -> void:
	if en.get("charge_phase","")!="active":return
	var wall:bool=absf(requested_velocity.x)>80 and absf(resolved_velocity.x)<absf(requested_velocity.x)*.25
	var ceiling:bool=airborne(en) and absf(requested_velocity.y)>80 and absf(resolved_velocity.y)<absf(requested_velocity.y)*.25
	if wall or ceiling:
		en["charge_hit_wall"]=true;_finish_charge(en)

static func _charge_velocity(en:Dictionary,target:Vector2,delta:float,flying:bool) -> Vector2:
	var phase:String=en.get("charge_phase","idle")
	if phase=="idle" and float(en["charge_cooldown"])<=0:
		var vector:Vector2=target-en["pos"]
		if not flying:vector.y=0
		if vector.length()<1:vector=Vector2(float(en.get("face",1)),0)
		en["charge_vector"]=vector.normalized();en["motion_dash_dir"]=signf(vector.x) if absf(vector.x)>1 else float(en.get("face",1))
		en["face"]=en["motion_dash_dir"];en["charge_phase"]="windup";en["charge_hit_wall"]=false
		en["charge_left"]=float(en.get("dash_windup",.6));phase="windup"
	var velocity:Vector2=en["vel"]
	if phase=="windup":
		velocity.x=move_toward(velocity.x,0,delta*1500)
		if flying:velocity.y=move_toward(velocity.y,0,delta*1500)
		en["charge_left"]=maxf(0,float(en["charge_left"])-delta)
		en["motion_dash_wait"]=-maxf(.00001,float(en["charge_left"]))
		if float(en["charge_left"])<=0:
			en["charge_phase"]="active";en["charge_left"]=float(en.get("dash_duration",.4));en["motion_dash_left"]=en["charge_left"];en["motion_dash_wait"]=0.0
	elif phase=="active":
		var burst:Vector2=en["charge_vector"]*float(en.get("dash_speed",380))
		velocity=velocity.move_toward(burst,float(en["dash_accel"])*delta) if en.has("dash_accel") else burst
		en["charge_left"]=maxf(0,float(en["charge_left"])-delta);en["motion_dash_left"]=en["charge_left"]
		if float(en["charge_left"])<=0:_finish_charge(en)
	elif phase=="recovery":
		velocity.x=move_toward(velocity.x,0,delta*1800)
		if flying:velocity.y=move_toward(velocity.y,0,delta*1800)
		en["charge_left"]=maxf(0,float(en["charge_left"])-delta);en["motion_dash_wait"]=en["charge_left"]
		if float(en["charge_left"])<=0:en["charge_phase"]="idle"
	else:
		velocity.x=move_toward(velocity.x,0,delta*600);en["motion_dash_wait"]=maxf(0,float(en["charge_cooldown"]))
	if not flying:velocity.y=minf(800,velocity.y+GRAVITY*delta)
	return velocity

static func velocity(en:Dictionary,player:Vector2,delta:float,rng:RandomNumberGenerator,grounded:bool,obstacles:Array=[],body_size:Vector2=Vector2(34,42),engaged:bool=true,support:Rect2=Rect2(),obstacle_index:RefCounted=null) -> Vector2:
	prepare(en)
	en["motion_clock"]+=delta;en["motion_left"]-=delta
	en["charge_cooldown"]=maxf(0,float(en["charge_cooldown"])-delta)
	en["turn_left"]=maxf(0,float(en.get("turn_left",0))-delta)
	var result:Vector2=en["vel"]
	var busy:bool=en.has("attack") and en["attack"].is_busy()
	var charging:bool=str(en["charge_phase"]) in ["windup","active","recovery"]
	if not engaged and charging:
		en["charge_phase"]="idle";en["charge_left"]=0.0;en["motion_dash_left"]=0.0;en["motion_dash_wait"]=0.0
		charging=false
	if en["motion_left"]<=0 and not busy and not charging:
		en["motion_index"]+=1;en["motion_left"]=float(en.get("movement_period",2.8));en["motion_anchor"]=en["pos"]
	var flying:bool=airborne(en)
	if busy and not flying and not charging:
		result.x=move_toward(result.x,0,delta*600);result.y=minf(800,result.y+GRAVITY*delta);return result
	var target:Vector2=player
	var roaming:bool=not engaged or (not en.get("elite",false) and en.get("movement_logic","approach")=="roam")
	if roaming and not charging:
		en["roam_left"]-=delta
		if en["roam_left"]<=0:
			en["roam_left"]=rng.randf_range(2.4,4.0)
			var radius:float=float(en.get("roam_radius",230))
			var direction:float=-1.0 if rng.randf()<.5 else 1.0
			var anchor:Vector2=en["home"] if engaged else en["pos"]
			var horizontal:float=anchor.x+direction*rng.randf_range(radius*.55,radius)
			if not flying and support.has_area():
				var margin:float=maxf(body_size.x*.5,20.0*float(en.get("scale",1)))
				var inset:float=minf(margin+2.0,support.size.x*.5)
				var low:float=support.position.x+inset
				var high:float=support.end.x-inset
				horizontal=clampf(horizontal,low,high)
				if absf(horizontal-float(en["pos"].x))<28.0:
					horizontal=clampf(float(en["pos"].x)-direction*radius,low,high)
			en["roam_target"]=Vector2(horizontal,anchor.y+(rng.randf_range(-radius*.45,radius*.3) if flying else 0.0))
		target=en["roam_target"]
	var lunge_target:Vector2=player+Vector2(0,body_size.y*.5-21.0)
	var in_lunge_range:bool=en.get("air_lunge",false) and float(en["charge_cooldown"])<=0 and lunge_target.distance_squared_to(en["pos"])<=pow(float(en.get("dash_trigger",205.0)),2)
	if engaged and (current(en)=="dash" or charging or in_lunge_range):
		return _charge_velocity(en,lunge_target if en.get("air_lunge",false) else player,delta,flying)
	var flight_target:Vector2=target if roaming else target-Vector2(0,float(en.get("hover_height",85)))
	var toward:Vector2=target-en["pos"]
	update_facing(en,target.x,delta)
	var stop:float=18.0 if roaming else float(en.get("stop_radius",48.0))
	if roaming and toward.length()<24.0:en["roam_left"]=0.0
	if absf(toward.x)<=stop:en["motion_stopped"]=true
	elif absf(toward.x)>=stop+float(en.get("resume_margin",24)):en["motion_stopped"]=false
	var direction:float=0.0 if en["motion_stopped"] else signf(toward.x)
	var speed:float=float(en.get("speed",70))
	match current(en):
		"hover","drift":result=(flight_target-en["pos"]).limit_length(speed*.65 if current(en)=="hover" else speed)
		"jump":
			en["jump_left"]-=delta;result.x=move_toward(result.x,direction*speed,delta*320);result.y=minf(800,result.y+GRAVITY*delta)
			if grounded and en["jump_left"]<=0 and not en["motion_stopped"]:result.y=-float(en.get("jump_speed",540));en["jump_left"]=1.7
		_:
			result.x=move_toward(result.x,direction*speed,delta*300);result.y=minf(800,result.y+GRAVITY*delta)
	if flying:return Flight.steer(en,flight_target,(flight_target-en["pos"]).limit_length(speed) if current(en)=="dash" else result,body_size,obstacles,delta,obstacle_index)
	return result
