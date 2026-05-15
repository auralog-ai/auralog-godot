extends GutTest

func test_utc_timestamp_includes_milliseconds_and_z_suffix() -> void:
	var client = load("res://addons/auralogs/auralogs.gd").new()
	add_child_autofree(client)
	var timestamp: String = client.call("_utc_timestamp")

	assert_eq(timestamp.length(), 24)
	assert_eq(timestamp.substr(19, 1), ".")
	assert_eq(timestamp.substr(23, 1), "Z")
	assert_true(timestamp.substr(20, 3).is_valid_int())
