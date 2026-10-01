# Contributing to fancy_collection

Thanks for considering a contribution. This package is maintained by
[Dualware Software Service Inc.](https://www.dualware.com)

## Reporting issues

Open an issue at
[github.com/Dualware/fancy_collection/issues](https://github.com/Dualware/fancy_collection/issues).
Please include:

- The package version (`pubspec.lock` entry for `fancy_collection`) and
  Flutter/Dart SDK version (`flutter --version`).
- A minimal reproduction — a short snippet showing the `FancyList`/`FancyMap`
  usage that triggers the bug is far more useful than a description alone.
- What you expected to happen vs. what happened.

## Contributing code

1. Fork the repository and create a branch off `main`.
2. Make your change. Keep unrelated changes out of the PR.
3. Run the checks below before opening the PR.
4. Open a pull request against `main` describing what changed and why.
   Link the issue it addresses, if any.

All pull requests are reviewed before merging — for a change of any size,
consider opening an issue first to discuss the approach.

### Checks to run locally

```sh
flutter pub get
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed .
```

### Guidelines

- Add or update tests for any behavior change.
- Update `CHANGELOG.md` under an `Unreleased` heading.
- Update `README.md` if the change affects public API or documented
  behavior.
- Keep the public API documented with dartdoc comments.

## Code of conduct

Be respectful and constructive. Disagreements about approach are fine;
personal attacks are not.
