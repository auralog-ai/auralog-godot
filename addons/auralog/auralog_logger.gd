class_name AuralogGodotLogger
extends Logger

var _buffer: Array[Dictionary] = []
var _mutex := Mutex.new()
var _suppressed := false

func set_suppressed(value: bool) -> void:
	_mutex.lock()
	_suppressed = value
	_mutex.unlock()

func drain() -> Array[Dictionary]:
	_mutex.lock()
	var records := _buffer
	_buffer = []
	_mutex.unlock()
	return records

func _log_message(message: String, error: bool) -> void:
	_push({
		"kind": "message",
		"level": "error" if error else "info",
		"message": message,
		"metadata": {
			"source": "godot_log",
			"stream": "stderr" if error else "stdout"
		}
	})

func _log_error(
	function: String,
	file: String,
	line: int,
	code: String,
	rationale: String,
	editor_notify: bool,
	error_type: int,
	script_backtraces: Array[ScriptBacktrace]
) -> void:
	_push({
		"kind": "error",
		"level": _level_for_error_type(error_type),
		"message": rationale,
		"metadata": {
			"source": "godot_error",
			"function": function,
			"file": file,
			"line": line,
			"code": code,
			"editor_notify": editor_notify,
			"error_type": error_type,
			"script_backtraces": _serialize_backtraces(script_backtraces)
		}
	})

func _push(record: Dictionary) -> void:
	_mutex.lock()
	if not _suppressed:
		_buffer.append(record)
	_mutex.unlock()

func _level_for_error_type(error_type: int) -> String:
	if error_type == Logger.ERROR_TYPE_WARNING:
		return "warn"
	return "error"

func _serialize_backtraces(script_backtraces: Array[ScriptBacktrace]) -> Array:
	var out := []
	for backtrace in script_backtraces:
		var frames := []
		for index in range(backtrace.get_frame_count()):
			frames.append({
				"file": backtrace.get_frame_file(index),
				"function": backtrace.get_frame_function(index),
				"line": backtrace.get_frame_line(index)
			})
		out.append({
			"language": backtrace.get_language_name(),
			"frames": frames
		})
	return out
