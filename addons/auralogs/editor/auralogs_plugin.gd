@tool
extends EditorPlugin

const AUTOLOAD_NAME := "Auralogs"
const AUTOLOAD_PATH := "res://addons/auralogs/auralogs.gd"

var _button: Button

func _enter_tree() -> void:
	_ensure_project_settings()
	_button = Button.new()
	_button.text = "Auralogs: Install Autoload"
	_button.tooltip_text = "Register the Auralogs singleton for automatic log and error capture."
	_button.pressed.connect(_install_autoload)
	add_control_to_container(CONTAINER_TOOLBAR, _button)
	_refresh_button()

func _exit_tree() -> void:
	if _button != null:
		remove_control_from_container(CONTAINER_TOOLBAR, _button)
		_button.queue_free()

func _install_autoload() -> void:
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	_refresh_button()

func _refresh_button() -> void:
	if _button == null:
		return
	var installed := ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME)
	_button.disabled = installed
	_button.text = "Auralogs: Autoload Installed" if installed else "Auralogs: Install Autoload"

func _ensure_project_settings() -> void:
	_define_setting("auralogs/api_key", "", TYPE_STRING, PROPERTY_HINT_PASSWORD)
	_define_setting("auralogs/environment", "production", TYPE_STRING)
	_define_setting("auralogs/endpoint", AuralogsConfig.DEFAULT_ENDPOINT, TYPE_STRING)
	_define_setting("auralogs/capture_console", true, TYPE_BOOL)
	_define_setting("auralogs/capture_errors", true, TYPE_BOOL)
	_define_setting("auralogs/capture_crashes", true, TYPE_BOOL)
	_define_setting("auralogs/flush_interval", AuralogsConfig.DEFAULT_FLUSH_INTERVAL, TYPE_FLOAT)
	_define_setting("auralogs/max_batch_size", AuralogsConfig.DEFAULT_MAX_BATCH_SIZE, TYPE_INT)
	_define_setting("auralogs/max_queue_size", AuralogsConfig.DEFAULT_MAX_QUEUE_SIZE, TYPE_INT)
	_define_setting("auralogs/max_retry_attempts", AuralogsConfig.DEFAULT_MAX_RETRY_ATTEMPTS, TYPE_INT)
	_define_setting("auralogs/retry_initial_delay", AuralogsConfig.DEFAULT_RETRY_INITIAL_DELAY, TYPE_FLOAT)
	_define_setting("auralogs/retry_max_delay", AuralogsConfig.DEFAULT_RETRY_MAX_DELAY, TYPE_FLOAT)

func _define_setting(name: String, default_value, type: int, hint := PROPERTY_HINT_NONE) -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default_value)
	ProjectSettings.add_property_info({
		"name": name,
		"type": type,
		"hint": hint
	})
