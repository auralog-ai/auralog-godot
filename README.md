# auralogs-godot (Beta)

Godot 4.5+ SDK for [Auralogs](https://auralogs.ai) — agentic logging and application awareness.

Auralogs acts as an on-call engineer — powered by your choice of model (Claude, OpenAI, or any MCP-compatible LLM) — monitoring your logs and errors, alerting you when something's wrong, and opening fix PRs automatically.

[![license](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

## Install

Copy `addons/auralogs` into your Godot project, enable the Auralogs plugin, then click **Auralogs: Install Autoload** in the editor toolbar.

You can also add the Autoload manually:

| Name | Path |
|---|---|
| `Auralogs` | `res://addons/auralogs/auralogs.gd` |

## Quick start

```gdscript
func _ready() -> void:
	Auralogs.init({
		"api_key": "aura_your_key",
		"environment": "production",
		"capture_console": true,
		"capture_errors": true,
		"capture_crashes": true,
		"global_metadata": func() -> Dictionary:
			return {
				"user_id": GameSession.user_id,
				"scene": get_tree().current_scene.scene_file_path
			}
	})

	Auralogs.info("level started", {"level": 3})
	Auralogs.error("save failed", {"slot": 1})
```

With `capture_console` and `capture_errors` enabled, Auralogs registers a Godot `Logger` via `OS.add_logger()` and captures normal prints, stderr messages, warnings, script errors, shader errors, and engine errors as much as Godot exposes them.

## Requirements

- Godot 4.5 or later.
- File logging enabled if you want previous-session crash reporting.
- `debug/settings/gdscript/always_track_call_stacks=true` for useful GDScript backtraces in release exports.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `api_key` | `String` | _required_ | Your Auralogs project API key |
| `environment` | `String` | `"production"` | e.g. `"production"`, `"staging"`, `"dev"` |
| `endpoint` | `String` | `https://ingest.auralogs.ai` | Ingest endpoint override. Must use `https://` unless `allow_insecure_endpoint` is `true`. |
| `allow_insecure_endpoint` | `bool` | `false` | Allow `http://` endpoints. Off by default so a misconfigured `endpoint` cannot silently downgrade every POST to plaintext. |
| `flush_interval` | `float` | `5.0` | Seconds between batched flushes |
| `max_batch_size` | `int` | `50` | Maximum logs per request |
| `max_queue_size` | `int` | `1000` | Maximum pending logs retained in memory |
| `capture_console` | `bool` | `true` | Capture `print()`, `printerr()`, and related output. `capture_logs` is accepted as a deprecated alias. |
| `capture_errors` | `bool` | `true` | Capture `push_warning()`, `push_error()`, script, shader, and engine errors |
| `capture_crashes` | `bool` | `true` | Report previous-session crash logs on next launch |
| `max_retry_attempts` | `int` | `5` | Drop a failed log after this many failed send attempts |
| `retry_initial_delay` | `float` | `1.0` | First retry delay in seconds |
| `retry_max_delay` | `float` | `30.0` | Maximum retry delay in seconds |
| `global_metadata` | `Dictionary` or `Callable` | `{}` | Fields merged into every emitted log |
| `trace_id` | `String` | _auto-generated_ | Custom trace ID for distributed tracing |

## Global Metadata

`global_metadata` can be a static `Dictionary` or a synchronous `Callable` that returns a `Dictionary`. The callable runs on each log emission, so keep it cheap and side-effect-free. GDScript does not provide exception handling, so errors inside your callable will interrupt the log path; read already-cached state rather than doing I/O or calling fragile game logic.

## Automatic Capture

Godot 4.5 introduced custom loggers. This SDK uses that hook, but a few engine constraints matter:

- The logger is installed when the Autoload initializes, so very early engine startup messages are not available.
- Logger callbacks can run on non-main threads. Auralogs only buffers records inside those callbacks and sends HTTP later from the Autoload node.
- Calling `print()`, `push_error()`, or `push_warning()` inside a logger callback is not supported by Godot and can trigger recursion protection.
- Hard crashes cannot be reported during the crashing session because scripting has stopped. Auralogs reads rotated Godot log files on the next launch and reports crash blocks once.

## Metadata

Every log gets baseline Godot context:

- SDK name/version
- Godot version
- debug/editor flags
- OS name/version
- project name
- current scene path
- viewport size
- FPS

Godot `Variant` values are sanitized for JSON, including vectors, colors, transforms, resources, nodes, arrays, dictionaries, depth limits, and circular-reference protection.

## Development

Requirements: Node 20+ for repository checks, and Godot 4.5+ for runtime validation. `package.json` exists only to run maintainer checks; this SDK has no npm runtime package.

```bash
npm test
```

For a local parse check with Godot:

```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --quit
```

GUT tests live in `test/unit`. Install GUT 9.x into `addons/gut`, then run:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -d --path "$PWD" -gdir=res://test/unit -ginclude_subdirs -gexit
```

## Documentation

Full docs at [docs.auralogs.ai](https://docs.auralogs.ai).

## Security

Found a vulnerability? See [SECURITY.md](./SECURITY.md) for how to report it.

## License

[MIT](./LICENSE) © James Thomas
