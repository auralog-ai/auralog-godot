class_name AuralogConfig
extends RefCounted

const DEFAULT_ENDPOINT := "https://ingest.auralog.ai"
const DEFAULT_FLUSH_INTERVAL := 5.0
const DEFAULT_MAX_BATCH_SIZE := 50
const DEFAULT_MAX_QUEUE_SIZE := 1000
const DEFAULT_MAX_RETRY_ATTEMPTS := 5
const DEFAULT_RETRY_INITIAL_DELAY := 1.0
const DEFAULT_RETRY_MAX_DELAY := 30.0

var api_key := ""
var environment := "production"
var endpoint := DEFAULT_ENDPOINT
var flush_interval := DEFAULT_FLUSH_INTERVAL
var max_batch_size := DEFAULT_MAX_BATCH_SIZE
var max_queue_size := DEFAULT_MAX_QUEUE_SIZE
var capture_console := true
var capture_errors := true
var capture_crashes := true
var max_retry_attempts := DEFAULT_MAX_RETRY_ATTEMPTS
var retry_initial_delay := DEFAULT_RETRY_INITIAL_DELAY
var retry_max_delay := DEFAULT_RETRY_MAX_DELAY
var global_metadata = {}
var trace_id := ""
var allow_insecure_endpoint := false

static func from_dictionary(values: Dictionary) -> AuralogConfig:
	var config := AuralogConfig.new()
	config.api_key = str(values.get("api_key", ProjectSettings.get_setting("auralog/api_key", config.api_key)))
	config.environment = str(values.get("environment", ProjectSettings.get_setting("auralog/environment", config.environment)))
	config.endpoint = str(values.get("endpoint", ProjectSettings.get_setting("auralog/endpoint", config.endpoint))).trim_suffix("/")
	config.flush_interval = float(values.get("flush_interval", ProjectSettings.get_setting("auralog/flush_interval", config.flush_interval)))
	config.max_batch_size = int(values.get("max_batch_size", ProjectSettings.get_setting("auralog/max_batch_size", config.max_batch_size)))
	config.max_queue_size = int(values.get("max_queue_size", ProjectSettings.get_setting("auralog/max_queue_size", config.max_queue_size)))
	config.capture_console = bool(values.get("capture_console", values.get("capture_logs", ProjectSettings.get_setting("auralog/capture_console", config.capture_console))))
	config.capture_errors = bool(values.get("capture_errors", ProjectSettings.get_setting("auralog/capture_errors", config.capture_errors)))
	config.capture_crashes = bool(values.get("capture_crashes", ProjectSettings.get_setting("auralog/capture_crashes", config.capture_crashes)))
	config.max_retry_attempts = int(values.get("max_retry_attempts", ProjectSettings.get_setting("auralog/max_retry_attempts", config.max_retry_attempts)))
	config.retry_initial_delay = float(values.get("retry_initial_delay", ProjectSettings.get_setting("auralog/retry_initial_delay", config.retry_initial_delay)))
	config.retry_max_delay = float(values.get("retry_max_delay", ProjectSettings.get_setting("auralog/retry_max_delay", config.retry_max_delay)))
	config.global_metadata = values.get("global_metadata", config.global_metadata)
	config.trace_id = str(values.get("trace_id", config.trace_id))
	config.allow_insecure_endpoint = bool(values.get("allow_insecure_endpoint", ProjectSettings.get_setting("auralog/allow_insecure_endpoint", config.allow_insecure_endpoint)))
	return config

func is_valid() -> bool:
	return validation_error().is_empty()

func validation_error() -> String:
	if api_key.is_empty():
		return "api_key is required"
	if environment.is_empty():
		return "environment is required"
	if endpoint.is_empty():
		return "endpoint is required"
	if not allow_insecure_endpoint and not endpoint.begins_with("https://"):
		return "endpoint must use https:// (set allow_insecure_endpoint=true to override)"
	return ""
