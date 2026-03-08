#!/bin/bash

# Build script for Rust library integration
# This script compiles the Rust library and copies it to the Swift project

set -e

echo "🦀 Building linktools-rs Rust library..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}❌ Error: Rust/Cargo not found${NC}"
    echo "Please install Rust from https://rustup.rs/"
    exit 1
fi

# Change to Rust library directory
cd "$(dirname "$0")/linktools-rs"

echo "📦 Compiling Rust library..."
cargo build --release

echo "✅ Rust library compiled successfully!"

# The compiled library will be in:
# - macOS: target/release/liblinktools_rs.dylib
# - Linux: target/release/liblinktools_rs.so

echo ""
echo "📝 Next steps:"
echo "1. Make sure the Rust library is in the Frameworks search path"
echo "2. Link the library in Xcode: Build Phases → Link Binary With Libraries"
echo "3. Add the library search path in Build Settings"
echo ""
echo "For macOS, add to Build Settings → Library Search Paths:"
echo "  \$(PROJECT_DIR)/linktools-rs/target/release"
echo ""
echo "For the Swift module, the library will be loaded at runtime."
