## App-level manager for the Desk Companion.
## This is the root orchestrator, attached to main.tscn.
##
## Responsibilities:
##   - Load the active room scene into RoomHolder
##   - Re-parent Sabby + re-wire the BehaviorStateMachine waypoints on room change
##   - Drive the status sidebar (clock, weather, current behavior)
##   - Hold TimeManager, DataBridge (app-level, not room-specific)
##
## Rooms are dumb containers (see scripts/room.gd).
## Behavior and character state persist across room transitions.
extends Node2D

## The room that loads on startup.
@export var starting_room: PackedScene

@onready var room_holder: Node2D = $RoomHolder
@onready var character: SabbyCharacter = get_node_or_null("Sabby") as SabbyCharacter
@onready var behavior: BehaviorStateMachine = $BehaviorStateMachine
@onready var time_mgr: TimeManager = $TimeManager
@onready var data_bridge: DataBridge = $DataBridge
@onready var ambient_light: CanvasModulate = $AmbientLight
@onready var time_label: Label = $StatusBar/TimeLabel
@onready var weather_label: Label = $StatusBar/WeatherLabel
@onready var behavior_label: Label = $StatusBar/BehaviorLabel
@onready var room_label: Label = get_node_or_null("StatusBar/RoomLabel") as Label

var current_room: Room = null

func _ready() -> void:
	# Wire up signals
	time_mgr.time_period_changed.connect(_on_time_changed)
	data_bridge.data_updated.connect(_on_data_updated)
	behavior.behavior_changed.connect(_on_behavior_changed)

	# Defensively (re-)bind the character reference. The scene file already
	# sets behavior.character via NodePath, but Godot's typed @export
	# resolution has been flaky on first project load — this guarantees it.
	if character:
		behavior.set_character(character)
	else:
		push_error("[App] Sabby not found under AppRoot — behaviors will be inert.")

	# Load the starting room
	if starting_room:
		load_room(starting_room)
	else:
		push_warning("[App] No starting_room assigned on AppRoot — scene will be empty.")

	_update_ambient()
	print("[App] Desk Companion started — ", time_mgr.get_period_name())


## Load a new room scene, replacing the current one.
## Re-parents Sabby to the new room's nav region and rewires the behavior
## state machine to the new waypoints.
func load_room(room_scene: PackedScene) -> void:
	# Clear any existing room
	for child in room_holder.get_children():
		child.queue_free()

	var new_room: Room = room_scene.instantiate() as Room
	if new_room == null:
		push_error("[App] Room scene does not use room.gd as root — cannot load.")
		return
	room_holder.add_child(new_room)
	current_room = new_room

	# Move Sabby into the new room's nav region and position at spawn point
	if character:
		var old_parent := character.get_parent()
		if old_parent:
			old_parent.remove_child(character)
		var nav_reg = new_room.get_nav_region()
		if nav_reg:
			nav_reg.add_child(character)
		else:
			push_warning("[App] Room ", new_room.room_id, " has no NavigationRegion2D. Sabby will be parented directly to room.")
			new_room.add_child(character)
		character.global_position = new_room.get_spawn_position()

	# Point the behavior state machine at the new room's waypoints
	behavior.set_waypoints(new_room.get_waypoints_node())

	if room_label:
		room_label.text = "Room: " + (new_room.room_display_name if new_room.room_display_name != "" else new_room.room_id)

	print("[App] Loaded room: ", new_room.room_id)


func _on_time_changed(period: String) -> void:
	print("[App] Time period: ", period)
	_update_ambient()
	_adjust_behaviors_for_time()

func _on_data_updated(data: Dictionary) -> void:
	var weather: Dictionary = data.get("weather", {})
	if weather.has("condition"):
		_react_to_weather(weather["condition"])

func _process(_delta: float) -> void:
	if time_label:
		var h: int = time_mgr.get_hour()
		var m: int = time_mgr.get_minute()
		var ampm: String = "AM" if h < 12 else "PM"
		var display_h: int = h % 12
		if display_h == 0:
			display_h = 12
		time_label.text = "Time: %d:%02d %s" % [display_h, m, ampm]

func _on_behavior_changed(old_state: String, new_state: String) -> void:
	if behavior_label:
		var display_name: String = new_state.replace("_", " ").capitalize()
		behavior_label.text = "Sabby: " + display_name
	if old_state != "":
		print("[Behavior] ", old_state, " → ", new_state)
	else:
		print("[Behavior] Starting: ", new_state)

func _update_ambient() -> void:
	if ambient_light:
		var target_color := time_mgr.get_ambient_color()
		var tween := create_tween()
		tween.tween_property(ambient_light, "color", target_color, 2.0)

func _adjust_behaviors_for_time() -> void:
	if time_mgr.is_work_hours():
		behavior.set_behavior_weight("sit_at_desk", 35)
		behavior.set_behavior_weight("type_at_desk", 30)
		behavior.set_behavior_weight("look_at_window", 5)
		behavior.set_behavior_weight("stretch", 8)
	else:
		behavior.set_behavior_weight("sit_at_desk", 15)
		behavior.set_behavior_weight("type_at_desk", 10)
		behavior.set_behavior_weight("look_at_window", 20)
		behavior.set_behavior_weight("walk_around", 20)
		behavior.set_behavior_weight("stretch", 10)

func _react_to_weather(condition: String) -> void:
	match condition:
		"rain", "drizzle", "thunderstorm":
			behavior.set_behavior_weight("look_at_window", 20)
		"clear", "sunny":
			behavior.set_behavior_weight("look_at_window", 8)
