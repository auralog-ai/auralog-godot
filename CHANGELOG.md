# Changelog

All notable changes to `auralog-godot` are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-05-03

### Added

- Initial Godot 4.5+ SDK scaffold.
- Autoload singleton with `init`, `debug`, `info`, `warn`, `error`, `fatal`, `flush`, `shutdown`, global metadata, and trace ID helpers.
- Godot `Logger` integration via `OS.add_logger()` for best-effort automatic log and error capture.
- Batched HTTP transport targeting Auralog ingest endpoints.
- Previous-session crash log detection and deduplication.
- Godot `Variant` serializer for JSON-safe metadata.
- Editor plugin to register the Auralog Autoload and project settings.
