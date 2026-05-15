# Changelog

All notable changes to `auralogs-godot` are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-15

### Changed

- **BREAKING: Renamed Godot addon** `addons/auralog/` → `addons/auralogs/`. Update your `project.godot` autoload paths.
- **BREAKING: Renamed plugin name** `Auralog` → `Auralogs`.
- Default ingest endpoint updated to `https://ingest.auralogs.ai`.
- Repository moved to https://github.com/auralogs-ai/auralogs-godot.

## [0.1.0] - 2026-05-03

### Added

- Initial Godot 4.5+ SDK scaffold.
- Autoload singleton with `init`, `debug`, `info`, `warn`, `error`, `fatal`, `flush`, `shutdown`, global metadata, and trace ID helpers.
- Godot `Logger` integration via `OS.add_logger()` for best-effort automatic log and error capture.
- Batched HTTP transport targeting Auralogs ingest endpoints.
- Previous-session crash log detection and deduplication.
- Godot `Variant` serializer for JSON-safe metadata.
- Editor plugin to register the Auralogs Autoload and project settings.
