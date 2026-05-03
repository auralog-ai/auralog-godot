# Contributing to auralog-godot

This repo is the **Godot SDK** only. For issues with the Auralog service itself, head to [auralog.ai](https://auralog.ai) or [docs.auralog.ai](https://docs.auralog.ai).

## Reporting Bugs

Open a bug report and include:

- SDK version
- Godot version
- Platform/export target
- Minimal reproduction
- What you expected vs. what happened

## Development Setup

Requirements:

- Godot 4.5 or later
- Node 20 or later for repository checks

```bash
npm test
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --quit
```

## Making a Change

1. Fork the repo and create a branch from `main`.
2. Keep PRs focused.
3. Add or update tests/checks for behavior changes.
4. Run the full check locally before opening a PR.
5. Open a PR against `main`.

## Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation only
- `test:` — tests only
- `refactor:` — code change that neither fixes a bug nor adds a feature
- `build:` — build system, CI, dependencies
- `chore:` — other housekeeping

## Releases

Maintainers publish releases through GitHub Releases. Godot Asset Library publishing is manual until an automated release flow is added.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](./LICENSE).
