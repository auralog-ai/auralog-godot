class_name AuralogTransport
extends Node

signal flushed(success: bool, entries: Array[Dictionary])

var api_key := ""
var endpoint := AuralogConfig.DEFAULT_ENDPOINT
var max_batch_size := AuralogConfig.DEFAULT_MAX_BATCH_SIZE
var max_queue_size := AuralogConfig.DEFAULT_MAX_QUEUE_SIZE
var max_retry_attempts := AuralogConfig.DEFAULT_MAX_RETRY_ATTEMPTS
var retry_initial_delay := AuralogConfig.DEFAULT_RETRY_INITIAL_DELAY
var retry_max_delay := AuralogConfig.DEFAULT_RETRY_MAX_DELAY
var _batch_queue: Array[Dictionary] = []
var _single_queue: Array[Dictionary] = []
var _http: HTTPRequest
var _retry_timer: Timer
var _in_flight := false
var _active_payload := {}
var _active_entries: Array[Dictionary] = []
var _active_single := false
var _consecutive_failures := 0

func configure(config: AuralogConfig) -> void:
	api_key = config.api_key
	endpoint = config.endpoint.trim_suffix("/")
	max_batch_size = config.max_batch_size
	max_queue_size = config.max_queue_size
	max_retry_attempts = config.max_retry_attempts
	retry_initial_delay = config.retry_initial_delay
	retry_max_delay = config.retry_max_delay
	if _http == null:
		_http = HTTPRequest.new()
		_http.name = "AuralogHTTPRequest"
		# Disable redirect following: the API key is in the POST body, and Godot
		# replays the body on 307/308. A hijacked redirect would exfiltrate keys.
		_http.set_max_redirects(0)
		add_child(_http)
		_http.request_completed.connect(_on_request_completed)
	if _retry_timer == null:
		_retry_timer = Timer.new()
		_retry_timer.name = "AuralogRetryTimer"
		_retry_timer.one_shot = true
		_retry_timer.timeout.connect(flush)
		add_child(_retry_timer)

func send(entry: Dictionary, immediate := false) -> void:
	_trim_for_capacity()
	if _is_error_level(str(entry.get("level", "info"))):
		_single_queue.append(entry)
	else:
		_batch_queue.append(entry)
	if immediate:
		flush()

func flush() -> void:
	if _in_flight or api_key.is_empty() or (_single_queue.is_empty() and _batch_queue.is_empty()):
		return

	var entries := []
	var single := not _single_queue.is_empty()
	if single:
		entries.append(_single_queue.pop_front())
	else:
		var limit = min(_batch_queue.size(), max_batch_size)
		for _index in range(limit):
			entries.append(_batch_queue.pop_front())

	var path := "/v1/logs/single" if single else "/v1/logs"
	var wire_entries := _wire_entries(entries)
	var body := {"projectApiKey": api_key, "log": wire_entries[0]} if single else {"projectApiKey": api_key, "logs": wire_entries}
	var headers := PackedStringArray(["Content-Type: application/json"])
	_active_payload = body
	_active_entries = entries
	_active_single = single
	_in_flight = true
	var err := _http.request(endpoint + path, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_in_flight = false
		_active_payload = {}
		_active_entries = []
		_active_single = false
		_requeue_or_drop(entries, single)
		flushed.emit(false, entries)
		_schedule_retry()
		return

func shutdown() -> void:
	flush()

func pending_count() -> int:
	return _batch_queue.size() + _single_queue.size() + _active_entries.size()

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var success := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
	var completed_entries := _active_entries
	var completed_single := _active_single
	_in_flight = false
	_active_payload = {}
	_active_entries = []
	_active_single = false
	if success:
		_consecutive_failures = 0
	else:
		_requeue_or_drop(completed_entries, completed_single)
	flushed.emit(success, completed_entries)
	if success and (not _single_queue.is_empty() or not _batch_queue.is_empty()):
		flush()
	elif not success:
		_schedule_retry()

func _is_error_level(level: String) -> bool:
	return level == "error" or level == "fatal"

func _trim_for_capacity() -> void:
	while _batch_queue.size() + _single_queue.size() >= max_queue_size:
		if not _batch_queue.is_empty():
			_batch_queue.pop_front()
		elif not _single_queue.is_empty():
			_single_queue.pop_front()
		else:
			return

func _requeue_or_drop(entries: Array[Dictionary], single: bool) -> void:
	var retryable := []
	for entry in entries:
		var attempts := int(entry.get("_auralog_attempts", 0)) + 1
		entry["_auralog_attempts"] = attempts
		if attempts < max_retry_attempts:
			retryable.append(entry)
	if retryable.is_empty():
		return
	if single:
		_single_queue = retryable + _single_queue
	else:
		_batch_queue = retryable + _batch_queue

func _schedule_retry() -> void:
	if _retry_timer == null or (_single_queue.is_empty() and _batch_queue.is_empty()):
		return
	_consecutive_failures += 1
	var delay = min(retry_max_delay, retry_initial_delay * pow(2.0, max(0, _consecutive_failures - 1)))
	_retry_timer.start(delay)

func _wire_entries(entries: Array[Dictionary]) -> Array:
	var out := []
	for entry in entries:
		var wire_entry := {}
		for key in entry.keys():
			if not str(key).begins_with("_auralog_"):
				wire_entry[key] = entry[key]
		out.append(wire_entry)
	return out
