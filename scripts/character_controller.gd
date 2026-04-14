## Character controller for Sabby.
## Handles movement between waypoints and animation direction.
extends CharacterBody2D
class_name SabbyCharacter

signal arrived_at_target
signal action_started(action_name: String)
signal action_finished(action_name: String)

@export var move_speed: float = 80.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

enum Direction { DOWN, LEFT, RIGHT, UP }
var current_direction: Direction = Direction.DOWN

var _is_moving: bool = false
var _current_action: String = ""

func _ready() -> void:
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	_play_idle()

func _physics_process(_delta: float) -> void:
	if not _is_moving:
		return
	
	if nav_agent.is_navigation_finished():
		_is_moving = false
		velocity = Vector2.ZERO
		_play_idle()
		arrived_at_target.emit()
		return
	
	var next_pos := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_pos)
	var desired_velocity := direction * move_speed
	
	# Use avoidance if available, otherwise move directly
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(desired_velocity)
	else:
		_on_velocity_computed(desired_velocity)
	
	_update_direction(direction)
	_play_walk()

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

## Move to a world position using navigation
func move_to(target_pos: Vector2) -> void:
	nav_agent.target_position = target_pos
	_is_moving = true

## Stop moving immediately
func stop() -> void:
	_is_moving = false
	velocity = Vector2.ZERO
	_play_idle()

## Play a named action animation (sit, type, coffee, etc.)
func play_action(action_name: String) -> void:
	_current_action = action_name
	_is_moving = false
	velocity = Vector2.ZERO
	
	var anim_name := _get_action_anim(action_name)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
		action_started.emit(action_name)
	else:
		# Fallback to idle if animation doesn't exist yet
		_play_idle()
		action_started.emit(action_name)

func finish_action() -> void:
	var action := _current_action
	_current_action = ""
	_play_idle()
	action_finished.emit(action)

func is_moving() -> bool:
	return _is_moving

func is_acting() -> bool:
	return _current_action != ""

func _update_direction(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		current_direction = Direction.RIGHT if dir.x > 0 else Direction.LEFT
	else:
		current_direction = Direction.DOWN if dir.y > 0 else Direction.UP

func _direction_suffix() -> String:
	match current_direction:
		Direction.DOWN: return "down"
		Direction.LEFT: return "left"
		Direction.RIGHT: return "right"
		Direction.UP: return "up"
	return "down"

func _play_walk() -> void:
	var anim := "walk_" + _direction_suffix()
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		if sprite.animation != anim:
			sprite.play(anim)
	elif sprite.sprite_frames and sprite.sprite_frames.has_animation("walk_down"):
		if sprite.animation != "walk_down":
			sprite.play("walk_down")

func _play_idle() -> void:
	var anim := "idle_" + _direction_suffix()
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		if sprite.animation != anim:
			sprite.play(anim)
	elif sprite.sprite_frames and sprite.sprite_frames.has_animation("idle_down"):
		sprite.play("idle_down")
	elif sprite.sprite_frames and sprite.sprite_frames.has_animation("default"):
		sprite.play("default")

func _get_action_anim(action_name: String) -> String:
	# Map behavior actions to animation names
	var suffix := _direction_suffix()
	return action_name + "_" + suffix
