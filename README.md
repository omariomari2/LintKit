# SwiftLoc

**Automated Localization Extraction & Validation Engine for Swift**

SwiftLoc is a hybrid Swift + Bash CLI tool that automates the extraction, generation, and validation of localization files in Swift projects. It generates Apple-compliant XLIFF 1.2 files and catches translation errors before they cause runtime crashes.

---

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Supported Patterns](#supported-patterns)
- [Validation Rules](#validation-rules)
- [Output Formats](#output-formats)
- [CI/CD Integration](#cicd-integration)
- [Project Structure](#project-structure)
- [License](#license)

---

## Features

| Feature | Description |
|---------|-------------|
| **String Extraction** | Parses Swift source code using regex to identify `NSLocalizedString`, `String(localized:)`, and `LocalizedStringResource` calls |
| **XLIFF Generation** | Generates Apple-compliant XLIFF 1.2 files with proper XML encoding |
| **Merge-Safe Updates** | Adds new keys without overwriting existing translations |
| **Missing Key Detection** | Flags strings in code that are absent from translation files |
| **Placeholder Validation** | Ensures format specifiers match between source and target languages |
| **JSON Reports** | Outputs machine-readable validation reports for CI/CD pipelines |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        swiftloc.sh                              │
│                    (Bash Orchestration)                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Swift Processing Engine                      │
├─────────────────┬─────────────────┬─────────────────────────────┤
│ StringExtractor │ XLIFFGenerator  │ PlaceholderValidator        │
│                 │                 │ MissingKeyValidator         │
└─────────────────┴─────────────────┴─────────────────────────────┘
        │                  │                      │
        ▼                  ▼                      ▼
   .swift files      .xliff files         validation_report.json
```

---

## Requirements

- macOS 13.0+
- Swift 5.9+
- Xcode Command Line Tools

---

## Installation

### Build from Source

```bash
git clone <repository>
cd SwiftLoc
./swiftloc.sh build
```

### Install Globally

```bash
./scripts/install.sh
```

This installs the `swiftloc` binary to `/usr/local/bin`.

---

## Quick Start

**1. Extract strings from your Swift project:**

```bash
./swiftloc.sh extract --source ./MyApp --output ./Localizations/en.xliff
```

**2. After translating, validate the translation file:**

```bash
./swiftloc.sh validate --xliff ./Localizations/fr.xliff --source ./MyApp --all
```

**3. Generate a coverage report:**

```bash
./swiftloc.sh report --xliff ./Localizations/fr.xliff
```

---

## Commands

### extract

Extract localized strings from Swift source files.

```bash
./swiftloc.sh extract --source <path> --output <path> [options]
```

| Option | Description |
|--------|-------------|
| `--source, -s` | Path to source directory or file |
| `--output, -o` | Output XLIFF file path |
| `--source-language` | Source language code (default: `en`) |
| `--target-language` | Target language code (default: `fr`) |
| `--merge` | Merge with existing XLIFF instead of overwriting |
| `--json` | Output extraction results as JSON |

### validate

Validate XLIFF files against source code.

```bash
./swiftloc.sh validate --xliff <path> [options]
```

| Option | Description |
|--------|-------------|
| `--xliff, -x` | Path to XLIFF file |
| `--source, -s` | Path to source directory (required for missing key detection) |
| `--placeholders` | Check for placeholder mismatches |
| `--missing-keys` | Check for missing keys in XLIFF |
| `--quality` | Run AI-powered quality checks using Ollama |
| `--model` | Ollama model to use (default: `llama3.2`) |
| `--all` | Run all validation checks (excludes AI quality) |
| `--json` | Output validation results as JSON |

### report

Generate translation coverage reports.

```bash
./swiftloc.sh report --xliff <path> [options]
```

| Option | Description |
|--------|-------------|
| `--xliff, -x` | Path to XLIFF file |
| `--format, -f` | Output format: `json` or `text` (default: `text`) |
| `--output, -o` | Output file path (stdout if not specified) |

---

## Supported Patterns

SwiftLoc extracts strings from these Swift localization patterns:

```swift
NSLocalizedString("key", comment: "description")

NSLocalizedString("key", tableName: "Table", comment: "description")

String(localized: "key")

String(localized: "key", defaultValue: "Default", comment: "description")

LocalizedStringResource("key")
```

---

## AI Quality Validation

SwiftLoc integrates with local Ollama models to perform semantic quality checks on translations.

### Prerequisites

1. Install Ollama: https://ollama.ai
2. Pull a model: `ollama pull llama3.2`
3. Ensure Ollama is running: `ollama serve`

### Usage

```bash
./swiftloc.sh validate --xliff ./fr.xliff --quality --model llama3.2
```

### What AI Validates

| Check | Description |
|-------|-------------|
| Semantic Equivalence | Does the translation convey the same meaning? |
| Tone Preservation | Is the formality/casualness maintained? |
| Completeness | Is any information missing or added? |

### Quality Report Output

```json
{
  "qualityResults": [
    {
      "key": "greeting_casual",
      "source": "Hey there!",
      "target": "Bonjour Monsieur",
      "scores": {
        "meaning": 4,
        "tone": 2,
        "completeness": 5
      },
      "issues": ["Tone mismatch: source is casual, target is formal"]
    }
  ],
  "averageScore": 3.7,
  "flaggedTranslations": 1
}
```

---

## Validation Rules

### Placeholder Matching

SwiftLoc validates that format specifiers match between source and translated strings:

| Specifier | Type | Example |
|-----------|------|---------|
| `%@` | Object/String | `"Hello, %@"` |
| `%d`, `%i` | Integer | `"Count: %d"` |
| `%f` | Float/Double | `"Price: %.2f"` |
| `%ld` | Long | `"ID: %ld"` |
| `%lld` | Long Long | `"Timestamp: %lld"` |
| `%%` | Literal % | `"100%% complete"` |
| `%1$@` | Positional | `"%2$@ owes %1$@"` |

**Error Example:**

```
Source: "You have %d items"
Target: "Vous avez %@ articles"
Error:  Type mismatch - source has %d, target has %@
```

This mismatch would cause a runtime crash when the app attempts to format an integer as an object.

---

## Output Formats

### XLIFF 1.2

SwiftLoc generates Apple-compliant XLIFF 1.2 files:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xliff xmlns="urn:oasis:names:tc:xliff:document:1.2" version="1.2">
  <file original="Localizable.strings" source-language="en" target-language="fr" datatype="plaintext">
    <body>
      <trans-unit id="greeting_key">
        <source>Hello, %@!</source>
        <target>Bonjour, %@!</target>
        <note>Greeting shown on home screen</note>
      </trans-unit>
    </body>
  </file>
</xliff>
```

### JSON Validation Report

```json
{
  "missingKeys": [
    {
      "key": "welcome_message",
      "file": "ContentView.swift",
      "line": 42
    }
  ],
  "placeholderErrors": [
    {
      "key": "items_count",
      "source": "You have %d items",
      "target": "Vous avez %@ articles",
      "error": "Type mismatch: source has %d, target has %@"
    }
  ],
  "sourceLanguage": "en",
  "targetLanguage": "fr",
  "validatedAt": "2025-12-12T10:30:00Z"
}
```

---

## CI/CD Integration

Add SwiftLoc to your build pipeline to catch localization errors before deployment:

```yaml
# GitHub Actions Example
- name: Validate Localizations
  run: |
    ./swiftloc.sh validate \
      --xliff ./Localizations/fr.xliff \
      --source ./Sources \
      --all \
      --json > validation_report.json
```

**Exit Codes:**

| Code | Meaning |
|------|---------|
| `0` | Validation passed |
| `1` | Validation errors found |

---

## Project Structure

```
SwiftLoc/
├── Package.swift                 # Swift Package Manager manifest
├── swiftloc.sh                   # Bash CLI entry point
├── README.md
├── scripts/
│   └── install.sh                # Global installation script
├── Sources/
│   └── SwiftLoc/
│       ├── main.swift            # CLI commands (ArgumentParser)
│       ├── Models/
│       │   ├── LocalizedString.swift
│       │   ├── XLIFFDocument.swift
│       │   └── QualityReport.swift
│       ├── Extractors/
│       │   └── StringExtractor.swift
│       ├── Generators/
│       │   └── XLIFFGenerator.swift
│       ├── Validators/
│       │   ├── MissingKeyValidator.swift
│       │   └── PlaceholderValidator.swift
│       └── AI/
│           ├── OllamaClient.swift
│           ├── PromptBuilder.swift
│           └── QualityValidator.swift
└── Tests/
    └── SwiftLocTests/
        ├── StringExtractorTests.swift
        └── PlaceholderValidatorTests.swift
```

---

## License

MIT License
