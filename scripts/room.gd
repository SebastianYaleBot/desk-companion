## Generic room controller.
## Every room scene (room_desk.tscn, room_snack.tscn, etc.) uses this script
## as its root and exposes a consistent API to the app-level manager.
##
## Responsibilities:
##   - Hold tile layers (floor/walls/furniture/above-char)
##   - Hold waypoints, interactive zones, nav region
##   - Expose lookup API to the app manager
##
## This script is intentionally passive — rooms do not drive behavior.
## The app-level BehaviorStateMachine + CharacterController do that.
extends Node2D
class_name Room

## Stable identifier used when switching rooms programmatically.
@export var room_id: String = ""

## Human-readable name (can appear in the status sidebar).
@export var room_display_name: String = ""

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var furniture_layer: TileMapLayer = $FurnitureLayer
@onready var above_char_layer: TileMapLayer = $AboveCharLayer
@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var waypoints: Node2D = $Waypoints
@onready var interactive_zones: Node2D = $InteractiveZones
@onready var spawn_point: Marker2D = get_node_or_null("SpawnPoint") as Marker2D

func _ready() -> void:
	print("[Room] Loaded: ", room_id if room_id != "" else name)

## Return the Node2D containing all Marker2D waypoints for this room.
func get_waypoints_node() -> Node2D:
	return waypoints

## Return the world position a character should spawn at when entering.
func get_spawn_position() -> Vector2:
	if spawn_point:
		return spawn_point.global_position
	return global_position

## Return the NavigationRegion2D for pathfinding.
func get_nav_region() -> NavigationRegion2D:
	return nav_region
