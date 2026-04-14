## Interactive zone — a touchable area in the room that opens overlay content.
## Place as a child of Area2D nodes in the room scene.
extends Area2D
class_name InteractiveZone

signal zone_activated(zone_name: String)
signal zone_deactivated(zone_name: String)

@export var zone_name: String = "default"
@export var zone_label: String = "Touch to interact"
@export var overlay_scene: PackedScene  ## The content scene to show when tapped

var _is_active: bool = false

func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_activate()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_activate()

func _activate() -> void:
	if _is_active:
		_deactivate()
		return
	_is_active = true
	zone_activated.emit(zone_name)

func _deactivate() -> void:
	_is_active = false
	zone_deactivated.emit(zone_name)

func _on_hover_enter() -> void:
	# Could add a highlight effect here
	pass

func _on_hover_exit() -> void:
	pass
