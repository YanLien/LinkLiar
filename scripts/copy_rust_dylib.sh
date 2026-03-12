#!/bin/bash
# Build script to copy Rust dylib to LinkLiar app bundle

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RUST_TARGET="$PROJECT_DIR/linktools-rs/target/release"
DYLIB_NAME="liblinktools.dylib"

echo "Building Rust library..."
cd "$PROJECT_DIR/linktools-rs"
cargo build --release

echo "Copying dylib to LinkLiar..."
cp "$RUST_TARGET/$DYLIB_NAME" "$PROJECT_DIR/LinkLiar/"

echo "Done! dylib has been copied."
echo "Make sure to add the dylib to the Xcode project's 'Copy Files' build phase."
