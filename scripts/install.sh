#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="${1:-/usr/local/bin}"

echo "Building SwiftLoc..."
cd "$SCRIPT_DIR"
swift build -c release

echo "Installing to $INSTALL_DIR..."
if [ -w "$INSTALL_DIR" ]; then
    cp .build/release/swiftloc "$INSTALL_DIR/"
else
    sudo cp .build/release/swiftloc "$INSTALL_DIR/"
fi

echo "SwiftLoc installed successfully!"
echo "Run 'swiftloc --help' to get started."

