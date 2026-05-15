class_name AuralogsSerializer
extends RefCounted

const MAX_DEPTH := 8
const MAX_STRING_LENGTH := 4096
const MAX_ARRAY_LENGTH := 100
const MAX_DICTIONARY_KEYS := 100

static func sanitize(value, depth := 0, seen := []) -> Variant:
	if depth > MAX_DEPTH:
		return "[MaxDepth]"

	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT:
			return value
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			return _truncate(str(value))
		TYPE_PACKED_BYTE_ARRAY:
			return {"type": "PackedByteArray", "size": value.size(), "base64": Marshalls.raw_to_base64(value)}
		TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY:
			return _sanitize_packed_array(value)
		TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_VECTOR4_ARRAY, TYPE_PACKED_COLOR_ARRAY:
			return _sanitize_packed_array(value, depth, seen)
		TYPE_ARRAY:
			return _sanitize_array(value, depth, seen)
		TYPE_DICTIONARY:
			return _sanitize_dictionary(value, depth, seen)
		TYPE_VECTOR2:
			return {"x": value.x, "y": value.y}
		TYPE_VECTOR2I:
			return {"x": value.x, "y": value.y}
		TYPE_RECT2:
			return {"position": sanitize(value.position, depth + 1, seen), "size": sanitize(value.size, depth + 1, seen)}
		TYPE_RECT2I:
			return {"position": sanitize(value.position, depth + 1, seen), "size": sanitize(value.size, depth + 1, seen)}
		TYPE_VECTOR3:
			return {"x": value.x, "y": value.y, "z": value.z}
		TYPE_VECTOR3I:
			return {"x": value.x, "y": value.y, "z": value.z}
		TYPE_TRANSFORM2D:
			return {"x": sanitize(value.x, depth + 1, seen), "y": sanitize(value.y, depth + 1, seen), "origin": sanitize(value.origin, depth + 1, seen)}
		TYPE_VECTOR4:
			return {"x": value.x, "y": value.y, "z": value.z, "w": value.w}
		TYPE_VECTOR4I:
			return {"x": value.x, "y": value.y, "z": value.z, "w": value.w}
		TYPE_PLANE:
			return {"normal": sanitize(value.normal, depth + 1, seen), "d": value.d}
		TYPE_QUATERNION:
			return {"x": value.x, "y": value.y, "z": value.z, "w": value.w}
		TYPE_AABB:
			return {"position": sanitize(value.position, depth + 1, seen), "size": sanitize(value.size, depth + 1, seen)}
		TYPE_BASIS:
			return {"x": sanitize(value.x, depth + 1, seen), "y": sanitize(value.y, depth + 1, seen), "z": sanitize(value.z, depth + 1, seen)}
		TYPE_TRANSFORM3D:
			return {"basis": sanitize(value.basis, depth + 1, seen), "origin": sanitize(value.origin, depth + 1, seen)}
		TYPE_PROJECTION:
			return {"x": sanitize(value.x, depth + 1, seen), "y": sanitize(value.y, depth + 1, seen), "z": sanitize(value.z, depth + 1, seen), "w": sanitize(value.w, depth + 1, seen)}
		TYPE_COLOR:
			return {"r": value.r, "g": value.g, "b": value.b, "a": value.a, "html": value.to_html()}
		TYPE_OBJECT:
			return _sanitize_object(value)
		TYPE_CALLABLE:
			return {"type": "Callable", "repr": _truncate(str(value))}
		TYPE_SIGNAL:
			return {"type": "Signal", "repr": _truncate(str(value))}
		TYPE_RID:
			return {"type": "RID", "id": value.get_id()}
		_:
			return {"type": type_string(typeof(value)), "repr": _truncate(str(value))}

static func sanitize_dictionary(value: Dictionary) -> Dictionary:
	return sanitize(value) as Dictionary

static func _sanitize_array(value: Array, depth: int, seen: Array) -> Array:
	if seen.has(value):
		return ["[Circular]"]
	var next_seen := seen.duplicate()
	next_seen.append(value)
	var out := []
	var limit = min(value.size(), MAX_ARRAY_LENGTH)
	for index in range(limit):
		out.append(sanitize(value[index], depth + 1, next_seen))
	if value.size() > limit:
		out.append("[Truncated %d items]" % (value.size() - limit))
	return out

static func _sanitize_dictionary(value: Dictionary, depth: int, seen: Array) -> Dictionary:
	if seen.has(value):
		return {"$circular": true}
	var next_seen := seen.duplicate()
	next_seen.append(value)
	var out := {}
	var count := 0
	for key in value.keys():
		if count >= MAX_DICTIONARY_KEYS:
			out["$truncated_keys"] = value.size() - count
			break
		out[_truncate(str(key))] = sanitize(value[key], depth + 1, next_seen)
		count += 1
	return out

static func _sanitize_packed_array(value, depth := 0, seen := []) -> Dictionary:
	var items := []
	var limit = min(value.size(), MAX_ARRAY_LENGTH)
	for index in range(limit):
		items.append(sanitize(value[index], depth + 1, seen))
	return {
		"type": type_string(typeof(value)),
		"size": value.size(),
		"items": items,
		"truncated": value.size() > limit
	}

static func _sanitize_object(value: Object) -> Dictionary:
	if value == null:
		return {}
	var out := {"type": value.get_class()}
	if value is Node:
		out["name"] = value.name
		out["path"] = str(value.get_path())
		out["scene_file_path"] = value.scene_file_path
	elif value is Resource:
		out["resource_path"] = value.resource_path
	return out

static func _truncate(value: String) -> String:
	if value.length() <= MAX_STRING_LENGTH:
		return value
	return value.substr(0, MAX_STRING_LENGTH) + "...[truncated]"
