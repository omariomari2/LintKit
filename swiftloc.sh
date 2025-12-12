#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.build/release"
EXECUTABLE="$BUILD_DIR/swiftloc"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════╗"
    echo "║          SwiftLoc - L10n Engine           ║"
    echo "║   Extraction & Validation for Swift       ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_usage() {
    echo "Usage: swiftloc.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  build              Build the SwiftLoc tool"
    echo "  extract            Extract localized strings from Swift files"
    echo "  validate           Validate XLIFF files"
    echo "  report             Generate translation coverage reports"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./swiftloc.sh build"
    echo "  ./swiftloc.sh extract --source ./MyApp --output ./l10n/en.xliff"
    echo "  ./swiftloc.sh validate --xliff ./l10n/fr.xliff --all"
    echo "  ./swiftloc.sh report --xliff ./l10n/fr.xliff --format json"
}

build_tool() {
    echo -e "${YELLOW}Building SwiftLoc...${NC}"
    cd "$SCRIPT_DIR"
    swift build -c release
    echo -e "${GREEN}Build complete!${NC}"
    echo "Executable: $EXECUTABLE"
}

ensure_built() {
    if [ ! -f "$EXECUTABLE" ]; then
        echo -e "${YELLOW}SwiftLoc not built. Building now...${NC}"
        build_tool
    fi
}

run_extract() {
    ensure_built
    "$EXECUTABLE" extract "$@"
}

run_validate() {
    ensure_built
    "$EXECUTABLE" validate "$@"
}

run_report() {
    ensure_built
    "$EXECUTABLE" report "$@"
}

find_swift_files() {
    local dir="$1"
    echo -e "${BLUE}Swift files in $dir:${NC}"
    find "$dir" -name "*.swift" -type f 2>/dev/null | head -20
    local count=$(find "$dir" -name "*.swift" -type f 2>/dev/null | wc -l)
    echo -e "${GREEN}Total: $count Swift file(s)${NC}"
}

case "${1:-help}" in
    build)
        print_header
        build_tool
        ;;
    extract)
        shift
        run_extract "$@"
        ;;
    validate)
        shift
        run_validate "$@"
        ;;
    report)
        shift
        run_report "$@"
        ;;
    scan)
        shift
        find_swift_files "${1:-.}"
        ;;
    help|--help|-h)
        print_header
        print_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        print_usage
        exit 1
        ;;
esac

