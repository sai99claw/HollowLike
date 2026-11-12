class_name PlayerMotionV18
extends RefCounted
## Shared by the live controller and generated-room traversal verification.
const RISE_GRAVITY:float=1250.0
const JUMP_SPEED:float=530.0
const MOTION_STEP:float=1.0/120.0
# The launch step integrates the full impulse before gravity first applies.
const RISE_STEPS:int=ceili(JUMP_SPEED/(RISE_GRAVITY*MOTION_STEP))
const BASE_JUMP_HEIGHT:float=MOTION_STEP*(RISE_STEPS*JUMP_SPEED-RISE_GRAVITY*MOTION_STEP*RISE_STEPS*(RISE_STEPS-1)*.5)
const FALL_MULTIPLIER:float=2.0
const MAX_FALL_SPEED:float=1000.0
const RELEASE_SPEED:float=140.0
const POGO_SPEED:float=530.0
const GLIDE_FALL_SPEED:float=120.0
const WALL_HOLD_SECONDS:float=.5
const WALL_SLIDE_SPEED:float=36.0*1.2
const SLAM_SPEED_FACTOR:float=1.5
const WALL_APEX_SPEED:float=70.0
static func can_attach(vertical_speed:float,dashing_into_wall:bool,was_attached:bool) -> bool:
	# A normal jump is free through its ascent and apex. A deliberate dash
	# into a real wall may latch immediately, including during ascent.
	return dashing_into_wall or was_attached or vertical_speed>WALL_APEX_SPEED
static func gravity(vertical_speed:float) -> float:
	return RISE_GRAVITY*(FALL_MULTIPLIER if vertical_speed>=0 else 1.0)
static func cut(vertical_speed:float) -> float:
	return maxf(vertical_speed,-RELEASE_SPEED) if vertical_speed<0 else vertical_speed
