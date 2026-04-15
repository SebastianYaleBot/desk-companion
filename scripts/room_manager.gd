## Room manager — ties together the room, character, behaviors, and data.
## This is the main orchestration script for the desk companion.
extends Node2D

@onready var character: SabbyCharacter = $NavigationRegion2D/Sabby
@onready var behavior: BehaviorStateMachine = $BehaviorStateMachine
@onready var time_mgr: TimeManager = $TimeManager
@onready var data_bridge: DataBridge = $DataBridge
@onready var ambient_light: CanvasModulate = $AmbientLight
@onready var time_label: Label = $StatusBar/TimeLabel
@onready var weather_label: Label = $StatusBar/WeatherLabel
@onready var behavior_label: Label = $StatusBar/BehaviorLabel

func _ready() -> void:
	# Wire up signals
	time_mgr.time_period_changed.connect(_on_time_changed)
	data_bridge.data_updated.connect(_on_data_updated)
	behavior.behavior_changed.connect(_on_behavior_changed)
	
	# Set initial ambient
	_update_ambient()
	
	print("[Room] Desk Companion started — ", time_mgr.get_period_name())

func _on_time_changed(period: String) -> void:
	print("[Room] Time period: ", period)
	_update_ambient()
	_adjust_behaviors_for_time()

func _on_data_updated(data: Dictionary) -> void:
	# React to weather, status, etc.
	var weather: Dictionary = data.get("weather", {})
	if weather.has("condition"):
		_react_to_weather(weather["condition"])

func _process(_delta: float) -> void:
	# Update status bar
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
		# Smooth transition with tween
		var tween := create_tween()
		tween.tween_property(ambient_light, "color", target_color, 2.0)

func _adjust_behaviors_for_time() -> void:
	# During work hours, more desk work; evenings, more relaxed behaviors
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
	# Future: adjust window backdrop, change Sabby's behavior
	# e.g., if raining, Sabby looks at window more often
	match condition:
		"rain", "drizzle", "thunderstorm":
			behavior.set_behavior_weight("look_at_window", 20)
		"clear", "sunny":
			behavior.set_behavior_weight("look_at_window", 8)
