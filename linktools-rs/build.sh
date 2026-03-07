#!/bin/bash
set -e

# Build the Rust library
echo "Building Rust library..."
cargo build --release

# Create Swift bindings directory
SWIFT_BINDINGS_DIR="../LinkLiar/Classes/Backends/RustBindings"
mkdir -p "$SWIFT_BINDINGS_DIR"

# Copy the header file
cp include/linktools.h "$SWIFT_BINDINGS_DIR/"

# Copy the built library
LIB_NAME="liblinktools.dylib"
cp target/release/liblinktools.dylib "../LinkLiar/"

echo "Build complete!"
echo "Library: LinkLiar/liblinktools.dylib"
echo "Header: $SWIFT_BINDINGS_DIR/linktools.h"
