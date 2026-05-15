# Auralogs Godot Addon

Godot 4.5+ addon for Auralogs automatic log/error capture.

Add `res://addons/auralogs/auralogs.gd` as an Autoload named `Auralogs`, then call:

```gdscript
Auralogs.init({
	"api_key": "aura_your_key",
	"environment": "production",
	"capture_console": true,
	"capture_errors": true
})
```

See the repository README for full configuration and release notes.

`global_metadata` callables must be synchronous, cheap, and side-effect-free. GDScript cannot catch exceptions from user callables, so callable errors interrupt the log path.
