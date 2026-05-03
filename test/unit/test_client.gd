extends GutTest

func test_trace_id_is_uuid_v4_shape() -> void:
	var client = load("res://addons/auralog/auralog.gd").new()
	add_child_autofree(client)
	var trace_id: String = client.get_trace_id()

	assert_eq(trace_id.length(), 36)
	assert_eq(trace_id.substr(14, 1), "4")
	assert_true(["8", "9", "a", "b"].has(trace_id.substr(19, 1)))

func test_transport_queues_error_separately_from_batch_logs() -> void:
	var transport := AuralogTransport.new()
	add_child_autofree(transport)

	transport.send({"level": "info", "message": "one"})
	transport.send({"level": "error", "message": "two"})

	assert_eq(transport.pending_count(), 2)
