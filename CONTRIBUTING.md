# Contributing

Thanks for contributing to `flutter_ed448`.

## Development Setup

1. Install a current stable Dart SDK, or Flutter if you plan to test from a Flutter app.
2. Clone the repository.
3. Install dependencies:

```sh
dart pub get
```

## Before Opening a Pull Request

Run the same checks that the release and CI workflows expect:

```sh
dart format .
dart analyze
dart test
dart --enable-asserts run test/all.dart
dart pub publish --dry-run
```

## Contribution Guidelines

- Keep changes focused and well-scoped.
- Add or update tests when behavior changes.
- Update `README.md`, `CHANGELOG.md`, or related docs when the public API, package behavior, or release process changes.
- Preserve the repository's existing file style where practical. This repository prefers tabs instead of spaces for indentation when the file format supports it.
- Do not commit secrets, tokens, or private keys.

## Releases

Tagged releases are handled through GitHub Actions.

Use the current package version from `pubspec.yaml` and create a matching Git tag:

```sh
git tag <version>
git push origin <version>
```

Then publish a GitHub release for the same tag.

If the package name is being published to pub.dev for the first time, the first release must be performed manually before automated publishing can be used.

## Reporting Issues

- Use GitHub Issues for bugs, regressions, and feature requests.
- If you believe you have found a security issue, report it privately through GitHub security advisories instead of opening a public issue.
