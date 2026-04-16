## Autonomous behavior state machine for Sabby.
## Drives idle behaviors inspired by Johnny Castaway — 
## Sabby does things on their own whether you're watching or not.
extends Node
class_name BehaviorStateMachine

signal behavior_changed(old_state: String, new_state: String)

@export var character: SabbyCharacter
@export var waypoints: Node2D  ## Parent node containing Marker2D waypoints

## How long (seconds) Sabby stays in each action before transitioning
@export var min_action_duration: float = 4.0
@export var max_action_duration: float = 15.0

## Behaviors and their relative weights (higher = more likely)
var behavior_weights: Dictionary = {
	"sit_at_desk": 30,
	"type_at_desk": 25,
	"look_at_window": 10,
	"get_coffee": 8,
	"walk_around": 10,
	"check_phone": 8,
	"stretch": 5,
	"look_around": 4,
}

enum State { IDLE, WALKING, ACTING, WAITING }
var current_state: State = State.IDLE
var current_behavior: String = ""
var _action_timer: float = 0.0
var _wait_timer: float = 0.0
var _wait_duration: float = 0.0

## Waypoint name → position mapping
var _waypoint_map: Dictionary = {}

## Which waypoint each behavior targets
var behavior_waypoints: Dictionary = {
	"sit_at_desk": "desk",
	"type_at_desk": "desk",
	"look_at_window": "window",
	"get_coffee": "coffee_machine",
	"walk_around": "",  # random waypoint
	"check_phone": "desk",
	"stretch": "",  # in place
	"look_around": "",  # in place
}

func _ready() -> void:
	_build_waypoint_map()
	if character:
		character.arrived_at_target.connect(_on_arrived)
	# Start first behavior after a short delay
	_wait_and_pick(1.0)

## Swap the active waypoints node (called when a new room loads).
## Safe to call at runtime. Current behavior is allowed to finish naturally.
func set_waypoints(new_waypoints: Node2D) -> void:
	waypoints = new_waypoints
	_build_waypoint_map()

func _process(delta: float) -> void:
	match current_state:
		State.WAITING:
			_wait_timer += delta
			if _wait_timer >= _wait_duration:
				_pick_next_behavior()
		State.ACTING:
			_action_timer += delta
			var duration := randf_range(min_action_duration, max_action_duration)
			if _action_timer >= duration:
				_finish_current_action()

func _build_waypoint_map() -> void:
	_waypoint_map.clear()
	if not waypoints:
		return
	for child in waypoints.get_children():
		if child is Marker2D:
			_waypoint_map[child.name.to_lower()] = child.global_position

func _wait_and_pick(duration: float) -> void:
	current_state = State.WAITING
	_wait_timer = 0.0
	_wait_duration = duration

func _pick_next_behavior() -> void:
	var old := current_behavior
	current_behavior = _weighted_random_pick()
	behavior_changed.emit(old, current_behavior)
	
	var waypoint_name: String = behavior_waypoints.get(current_behavior, "")
	
	if waypoint_name == "":
		# In-place action or random walk
		if current_behavior == "walk_around":
			_walk_to_random_waypoint()
		else:
			_start_action()
	else:
		var target_pos: Vector2 = _waypoint_map.get(waypoint_name, Vector2.ZERO)
		if target_pos != Vector2.ZERO:
			current_state = State.WALKING
			character.move_to(target_pos)
		else:
			# Waypoint not found, just do action in place
			_start_action()

func _walk_to_random_waypoint() -> void:
	if _waypoint_map.is_empty():
		_start_action()
		return
	var keys := _waypoint_map.keys()
	var target_name: String = keys[randi() % keys.size()]
	current_state = State.WALKING
	character.move_to(_waypoint_map[target_name])

func _start_action() -> void:
	current_state = State.ACTING
	_action_timer = 0.0
	character.play_action(current_behavior)

func _finish_current_action() -> void:
	character.finish_action()
	# Brief pause before next behavior
	_wait_and_pick(randf_range(1.0, 3.0))

func _on_arrived() -> void:
	if current_state == State.WALKING:
		_start_action()

func _weighted_random_pick() -> String:
	var total_weight: int = 0
	for w in behavior_weights.values():
		total_weight += w
	
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	for behavior_name in behavior_weights:
		cumulative += behavior_weights[behavior_name]
		if roll < cumulative:
			return behavior_name
	
	return behavior_weights.keys()[0]

## Add or update a behavior at runtime
func set_behavior_weight(behavior_name: String, weight: int) -> void:
	behavior_weights[behavior_name] = weight

## Remove a behavior
func remove_behavior(behavior_name: String) -> void:
	behavior_weights.erase(behavior_name)
	behavior_waypoints.erase(behavior_name)
