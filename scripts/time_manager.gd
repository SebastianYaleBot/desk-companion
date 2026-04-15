## Time-of-day manager — drives ambient lighting and behavior scheduling.
## Syncs with real wall-clock time for organic day/night cycles.
extends Node
class_name TimeManager

signal time_period_changed(period: String)

enum Period { MORNING, MIDDAY, AFTERNOON, EVENING, NIGHT }

var current_period: Period = Period.MIDDAY
var _last_hour: int = -1

## Colors for ambient lighting by time period
var period_colors: Dictionary = {
	Period.MORNING: Color(1.0, 0.95, 0.85, 1.0),    # warm sunrise
	Period.MIDDAY: Color(1.0, 1.0, 1.0, 1.0),        # neutral daylight
	Period.AFTERNOON: Color(1.0, 0.98, 0.92, 1.0),    # warm afternoon
	Period.EVENING: Color(0.85, 0.8, 0.9, 1.0),       # cool twilight
	Period.NIGHT: Color(0.5, 0.5, 0.65, 1.0),         # blue night
}

func _ready() -> void:
	_update_period()

func _process(_delta: float) -> void:
	var time_dict: Dictionary = Time.get_time_dict_from_system()
	var hour: int = int(time_dict["hour"])
	if hour != _last_hour:
		_last_hour = hour
		_update_period()

func _update_period() -> void:
	var time_dict: Dictionary = Time.get_time_dict_from_system()
	var hour: int = int(time_dict["hour"])
	var old_period := current_period
	
	if hour >= 6 and hour < 10:
		current_period = Period.MORNING
	elif hour >= 10 and hour < 14:
		current_period = Period.MIDDAY
	elif hour >= 14 and hour < 17:
		current_period = Period.AFTERNOON
	elif hour >= 17 and hour < 21:
		current_period = Period.EVENING
	else:
		current_period = Period.NIGHT
	
	if current_period != old_period:
		time_period_changed.emit(get_period_name())

func get_period_name() -> String:
	match current_period:
		Period.MORNING: return "morning"
		Period.MIDDAY: return "midday"
		Period.AFTERNOON: return "afternoon"
		Period.EVENING: return "evening"
		Period.NIGHT: return "night"
	return "midday"

func get_ambient_color() -> Color:
	return period_colors.get(current_period, Color.WHITE)

func get_hour() -> int:
	return Time.get_time_dict_from_system()["hour"]

func get_minute() -> int:
	return Time.get_time_dict_from_system()["minute"]

func is_work_hours() -> bool:
	var h := get_hour()
	return h >= 8 and h < 18
