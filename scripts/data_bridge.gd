## Data bridge — polls the local Flask server for live data from OpenClaw.
## Weather, Sabby status, time-of-day, and any other data feeds.
extends Node
class_name DataBridge

signal data_updated(data: Dictionary)
signal connection_lost
signal connection_restored

@export var poll_url: String = "http://localhost:5113/status"
@export var poll_interval: float = 30.0  ## seconds between polls
@export var timeout: float = 5.0

var _http_request: HTTPRequest
var _timer: float = 0.0
var _connected: bool = false
var _last_data: Dictionary = {}

## Cached data accessors
var weather: Dictionary:
	get: return _last_data.get("weather", {})

var time_info: Dictionary:
	get: return _last_data.get("time", {})

var sabby_status: Dictionary:
	get: return _last_data.get("status", {})

func _ready() -> void:
	_http_request = HTTPRequest.new()
	_http_request.timeout = timeout
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	# Do an immediate poll
	_poll()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= poll_interval:
		_timer = 0.0
		_poll()

func _poll() -> void:
	if _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return  # Already requesting
	_http_request.request(poll_url)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		if _connected:
			_connected = false
			connection_lost.emit()
		return
	
	var json := JSON.new()
	var parse_result := json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		return
	
	var data: Dictionary = json.get_data()
	if not data is Dictionary:
		return
	
	if not _connected:
		_connected = true
		connection_restored.emit()
	
	_last_data = data
	data_updated.emit(data)

## Force an immediate poll (e.g., after user interaction)
func force_poll() -> void:
	_timer = 0.0
	_poll()

## Check if we have any data at all
func has_data() -> bool:
	return not _last_data.is_empty()

func is_bridge_connected() -> bool:
	return _connected
