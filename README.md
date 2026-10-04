# LintKit

A Swift and Bash tool for extracting localizable strings and checking XLIFF translation files.
The command-line executable is named `swiftloc`.

## Build

Use macOS 13 or later with Swift 5.9 or later.

```sh
bash swiftloc.sh build
```

## Use

```sh
bash swiftloc.sh extract --source ./MyApp --output ./en.xliff
bash swiftloc.sh validate --xliff ./fr.xliff --source ./MyApp --all
bash swiftloc.sh report --xliff ./fr.xliff --format json
```

Replace the example paths with your Swift source and translation files.
Run `swift test` for the existing test suite.

## Limits

String extraction uses pattern matching and can miss unusual Swift expressions.
Optional Ollama checks suggest translation issues; they do not replace a human translator.
The aim is to find missing strings before your users do.

