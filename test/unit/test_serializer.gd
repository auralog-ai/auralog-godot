extends GutTest

func test_sanitizes_common_godot_values() -> void:
	var sanitized: Dictionary = AuralogsSerializer.sanitize_dictionary({
		"position": Vector2(3.0, 4.0),
		"color": Color.RED,
		"path": ^"Player/Camera"
	})

	assert_eq(sanitized["position"], {"x": 3.0, "y": 4.0})
	assert_eq(sanitized["color"]["html"], "ff0000ff")
	assert_eq(sanitized["path"], "Player/Camera")

func test_sanitizes_packed_byte_array_without_comma_joining() -> void:
	var sanitized: Dictionary = AuralogsSerializer.sanitize(PackedByteArray([1, 2, 3]))

	assert_eq(sanitized["type"], "PackedByteArray")
	assert_eq(sanitized["size"], 3)
	assert_eq(sanitized["base64"], "AQID")

func test_limits_recursive_dictionaries() -> void:
	var data: Dictionary = {}
	data["self"] = data

	var sanitized: Dictionary = AuralogsSerializer.sanitize_dictionary(data)

	assert_eq(sanitized["self"], {"$circular": true})
