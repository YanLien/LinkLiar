#!/bin/bash
# Build script to compile Rust library and generate Swift bindings

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RUST_DIR="$PROJECT_DIR/linktools-rs"
SWIFT_OUTPUT="$PROJECT_DIR/LinkTools/Backends/Generated"

echo "=== Rust + Swift Bridge Build Script ==="

# Step 1: Build the Rust library
echo "Building Rust library..."
cd "$RUST_DIR"
cargo build --release

# Step 2: Generate Swift bindings using swift-bridge-cli
echo "Generating Swift bindings..."
mkdir -p "$SWIFT_OUTPUT"

swift-bridge-cli parse-bridges \
    --crate-name linktools \
    --file "$RUST_DIR/src/bridge.rs" \
    --output "$SWIFT_OUTPUT"

# Step 3: Copy dylib to LinkLiar
echo "Copying dylib..."
cp "$RUST_DIR/target/release/liblinktools.dylib" "$PROJECT_DIR/LinkLiar/"

echo "=== Build Complete ==="
echo "Generated files:"
ls -la "$SWIFT_OUTPUT"
echo ""
echo "dylib location: $PROJECT_DIR/LinkLiar/liblinktools.dylib"
