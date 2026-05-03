extends Node

func _ready() -> void:
	Auralog.init({
		"api_key": "aura_your_key",
		"environment": "production",
		"capture_console": true,
		"capture_errors": true,
		"capture_crashes": true,
		"global_metadata": func() -> Dictionary:
			return {
				"scene": get_tree().current_scene.scene_file_path
			}
	})

	Auralog.info("level started", {"level": 1})
	print("this print is captured by the Godot Logger hook")
	push_warning("this warning is captured through Logger._log_error")
