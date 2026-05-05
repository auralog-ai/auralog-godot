extends GutTest

func test_defaults_match_public_contract() -> void:
	var config := AuralogConfig.from_dictionary({"api_key": "aura_test"})

	assert_eq(config.api_key, "aura_test")
	assert_eq(config.environment, "production")
	assert_eq(config.endpoint, "https://ingest.auralog.ai")
	assert_eq(config.flush_interval, 5.0)
	assert_eq(config.max_batch_size, 50)
	assert_eq(config.max_queue_size, 1000)
	assert_true(config.capture_console)
	assert_true(config.capture_errors)
	assert_true(config.capture_crashes)
	assert_eq(config.max_retry_attempts, 5)

func test_capture_logs_alias_maps_to_capture_console() -> void:
	var config := AuralogConfig.from_dictionary({
		"api_key": "aura_test",
		"capture_logs": false
	})

	assert_false(config.capture_console)

func test_https_endpoint_is_valid() -> void:
	var config := AuralogConfig.from_dictionary({
		"api_key": "aura_test",
		"endpoint": "https://example.com"
	})

	assert_true(config.is_valid())

func test_http_endpoint_is_rejected_by_default() -> void:
	var config := AuralogConfig.from_dictionary({
		"api_key": "aura_test",
		"endpoint": "http://example.com"
	})

	assert_false(config.is_valid())
	assert_true(config.validation_error().contains("https"))

func test_http_endpoint_allowed_with_explicit_opt_in() -> void:
	var config := AuralogConfig.from_dictionary({
		"api_key": "aura_test",
		"endpoint": "http://localhost:8080",
		"allow_insecure_endpoint": true
	})

	assert_true(config.is_valid())
