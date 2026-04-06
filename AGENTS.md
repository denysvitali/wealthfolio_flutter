# Wealthfolio Flutter

## Workflow

- Always finish changes by committing them.
- Always push the branch after committing.
- Always update `AGENTS.md` when the user adds a standing workflow rule.
- Always check GitHub Actions after pushing, wait for the run to finish, and make sure it passes before closing the task.

## Build

```sh
devenv shell -- flutter pub get
devenv shell -- flutter analyze --no-fatal-infos --no-fatal-warnings
devenv shell -- flutter test --exclude-tags=golden
devenv shell -- flutter build apk --debug --target-platform android-arm64
devenv shell -- flutter build web --release
```
