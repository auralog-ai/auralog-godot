class_name AuralogsClient
extends Node

const SDK_NAME := "auralogs-godot"
const SDK_VERSION := "1.0.0"
const CRASH_MARKER := "Program crashed with signal"

var _config := AuralogsConfig.new()
var _transport := AuralogsTransport.new()
var _timer := Timer.new()
var _godot_logger: AuralogsGodotLogger
var _initialized := false
var _trace_id := ""
var _last_reported_crash_hash := ""
var _warned_non_dictionary_metadata := false
var _draining_captured_logs := false

func _init() -> void:
	_trace_id = _generate_trace_id()
	_transport.name = "AuralogsTransport"
	add_child(_transport)
	_transport.flushed.connect(_on_transport_flushed)
	_timer.name = "AuralogsFlushTimer"
	_timer.one_shot = false
	_timer.timeout.connect(flush)
	add_child(_timer)

func init(options: Dictionary) -> void:
	_config = AuralogsConfig.from_dictionary(options)
	if not _config.trace_id.is_empty():
		_trace_id = _config.trace_id
	var validation_error := _config.validation_error()
	if not validation_error.is_empty():
		if not _config.api_key.is_empty():
			push_warning("auralogs: %s" % validation_error)
		return

	_transport.configure(_config)
	_timer.wait_time = max(0.25, _config.flush_interval)
	_timer.start()
	_initialized = true

	if _config.capture_console or _config.capture_errors:
		_install_logger()
	if _config.capture_crashes:
		_report_previous_crash()

func debug(message: String, metadata := {}) -> void:
	_log("debug", message, metadata)

func info(message: String, metadata := {}) -> void:
	_log("info", message, metadata)

func warn(message: String, metadata := {}) -> void:
	_log("warn", message, metadata)

func error(message: String, metadata := {}, stack_trace := "") -> void:
	_log("error", message, metadata, stack_trace)

func fatal(message: String, metadata := {}, stack_trace := "") -> void:
	_log("fatal", message, metadata, stack_trace)

func set_global_metadata(metadata_or_callable) -> void:
	_config.global_metadata = metadata_or_callable

func get_trace_id() -> String:
	return _trace_id

func set_trace_id(trace_id: String) -> void:
	_trace_id = trace_id

func flush() -> void:
	_drain_captured_logs()
	_transport.flush()

func shutdown() -> void:
	flush()
	_transport.shutdown()
	if _godot_logger != null:
		OS.remove_logger(_godot_logger)
		_godot_logger = null

func pending_count() -> int:
	return _transport.pending_count()

func _process(_delta: float) -> void:
	_drain_captured_logs()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		shutdown()

func _install_logger() -> void:
	if _godot_logger != null:
		return
	_godot_logger = AuralogsGodotLogger.new()
	OS.add_logger(_godot_logger)

func _drain_captured_logs() -> void:
	if not _initialized or _godot_logger == null or _draining_captured_logs:
		return
	_draining_captured_logs = true
	for record in _godot_logger.drain():
		var kind := str(record.get("kind", "message"))
		if kind == "message" and not _config.capture_console:
			continue
		if kind == "error" and not _config.capture_errors:
			continue
		_log(str(record.get("level", "info")), str(record.get("message", "")), record.get("metadata", {}))
	_draining_captured_logs = false

func _log(level: String, message: String, metadata := {}, stack_trace := "") -> void:
	_emit_log(level, message, metadata, stack_trace)

func _emit_log(level: String, message: String, metadata := {}, stack_trace := "", internal := {}) -> void:
	if not _initialized:
		return
	var entry_trace_id := _trace_id
	var effective_metadata = metadata
	if metadata is Dictionary:
		var metadata_copy := metadata.duplicate()
		if metadata_copy.has("traceId"):
			entry_trace_id = str(metadata_copy["traceId"])
			metadata_copy.erase("traceId")
		elif metadata_copy.has("trace_id"):
			entry_trace_id = str(metadata_copy["trace_id"])
			metadata_copy.erase("trace_id")
		effective_metadata = metadata_copy
	elif metadata != null:
		_warn_non_dictionary_metadata_once()
		effective_metadata = {}
	var sanitized_metadata: Dictionary = AuralogsSerializer.sanitize_dictionary(_merge_metadata(effective_metadata))
	var entry := {
		"level": level,
		"message": message,
		"metadata": sanitized_metadata,
		"environment": _config.environment,
		"timestamp": _utc_timestamp(),
		"traceId": entry_trace_id
	}
	if not str(stack_trace).is_empty():
		entry["stackTrace"] = stack_trace
	if internal is Dictionary:
		for key in internal.keys():
			entry["_auralogs_" + str(key)] = internal[key]
	var immediate := level == "error" or level == "fatal"
	_set_logger_suppressed(true)
	_transport.send(entry, immediate)
	_set_logger_suppressed(false)

func _merge_metadata(per_call) -> Dictionary:
	var out := _base_metadata()
	var global := _read_global_metadata()
	for key in global.keys():
		out[key] = global[key]
	if per_call is Dictionary:
		for key in per_call.keys():
			out[key] = per_call[key]
	return out

func _read_global_metadata() -> Dictionary:
	if _config.global_metadata is Callable:
		var value = _config.global_metadata.call()
		if value is Dictionary:
			return value
		return {}
	if _config.global_metadata is Dictionary:
		return _config.global_metadata
	return {}

func _base_metadata() -> Dictionary:
	var scene_path := ""
	var viewport_size := Vector2i.ZERO
	if get_tree() != null:
		var current_scene := get_tree().current_scene
		if current_scene != null:
			scene_path = current_scene.scene_file_path
		var viewport := get_viewport()
		if viewport != null:
			viewport_size = viewport.get_visible_rect().size
	return {
		"auralogs": {"sdk_name": SDK_NAME, "sdk_version": SDK_VERSION},
		"godot": {
			"version": Engine.get_version_info(),
			"debug_build": OS.is_debug_build(),
			"editor_hint": Engine.is_editor_hint()
		},
		"os": {"name": OS.get_name(), "version": OS.get_version()},
		"project": {"name": str(ProjectSettings.get_setting("application/config/name", ""))},
		"scene": {"path": scene_path},
		"viewport": {"size": viewport_size},
		"performance": {"fps": Engine.get_frames_per_second()}
	}

func _report_previous_crash() -> void:
	var log_path := str(ProjectSettings.get_setting("debug/file_logging/log_path", "user://logs/godot.log"))
	var log_dir := log_path.get_base_dir()
	var files := []
	for file_name in DirAccess.get_files_at(log_dir):
		var file_path := log_dir.path_join(file_name)
		files.append({"path": file_path, "modified": FileAccess.get_modified_time(file_path)})
	if files.is_empty():
		return
	files.sort_custom(func(left, right): return int(left["modified"]) > int(right["modified"]))
	var state_path := "user://auralogs_last_crash.txt"
	if FileAccess.file_exists(state_path):
		_last_reported_crash_hash = FileAccess.get_file_as_string(state_path)
	for file in files:
		var file_path := str(file["path"])
		var contents := FileAccess.get_file_as_string(file_path)
		var marker_index := contents.find(CRASH_MARKER)
		if marker_index == -1:
			continue
		var crash_text := contents.substr(marker_index)
		var crash_hash := crash_text.sha256_text()
		if crash_hash == _last_reported_crash_hash:
			return
		_emit_log(
			"error",
			"previous Godot session crashed",
			{"source": "godot_crash_log", "log_file": file_path, "crash": crash_text},
			"",
			{"crash_hash": crash_hash}
		)
		return

func _generate_trace_id() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8),
		hex.substr(8, 4),
		hex.substr(12, 4),
		hex.substr(16, 4),
		hex.substr(20, 12)
	]

func _utc_timestamp() -> String:
	return "%s.%03dZ" % [
		Time.get_datetime_string_from_system(true),
		int(Time.get_unix_time_from_system() * 1000.0) % 1000
	]

func _on_transport_flushed(success: bool, entries: Array[Dictionary]) -> void:
	if not success:
		return
	for entry in entries:
		if entry.has("_auralogs_crash_hash"):
			var state := FileAccess.open("user://auralogs_last_crash.txt", FileAccess.WRITE)
			if state != null:
				state.store_string(str(entry["_auralogs_crash_hash"]))

func _warn_non_dictionary_metadata_once() -> void:
	if _warned_non_dictionary_metadata:
		return
	_warned_non_dictionary_metadata = true
	_set_logger_suppressed(true)
	push_warning("auralogs: metadata must be a Dictionary; non-Dictionary metadata was dropped")
	_set_logger_suppressed(false)

func _set_logger_suppressed(value: bool) -> void:
	if _godot_logger != null:
		_godot_logger.set_suppressed(value)
