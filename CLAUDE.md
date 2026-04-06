# Wealthfolio Flutter

Flutter mobile/web client for Wealthfolio portfolio tracker.

## Architecture

- Single `AppController` (ChangeNotifier) for state management — no external packages
- Dio HTTP client with per-request instances
- Constructor-injected services, no service locator
- Imperative navigation with `Navigator.push()`
- Material 3 with Flexoki-inspired warm color palette

## Code Style

- Strict mode: `strict-casts`, `strict-inference`, `strict-raw-types`
- Single quotes required
- No barrel/index files — use direct imports
- Top-level functions preferred over utility classes
- Defensive JSON parsing via `json_parsing.dart` helpers

## Testing

- Hand-written fakes in `test/test_helpers.dart`
- No mocking frameworks
- Golden tests tagged with `@Tags(['golden'])`
- Widget tests wrap in `MaterialApp(theme: ..., home: ...)`

## Build

```sh
devenv shell -- flutter pub get
devenv shell -- flutter analyze --no-fatal-infos --no-fatal-warnings
devenv shell -- flutter test --exclude-tags=golden
devenv shell -- flutter build apk --debug --target-platform android-arm64
devenv shell -- flutter build web --release
```
