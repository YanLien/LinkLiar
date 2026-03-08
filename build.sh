#!/bin/bash

# LinkLiar Build Script
# Usage: ./build.sh [options]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_usage() {
    cat << EOF
Usage: $0 [options]

Options:
    -h, --help       Show this help
    -c, --clean      Clean build caches
    -r, --release    Build Release (default: Debug)
    -t, --test       Run tests (Rust + Swift)
    -p, --package    Package .app and .dmg
    -n, --no-sign    Build without code signing (local dev)
    -v, --verbose    Verbose output

Examples:
    $0               # Debug build
    $0 -r            # Release build
    $0 -c -r -t      # Clean, release build, run tests
    $0 -n            # Local dev build (no signing)
    $0 -r -p         # Release build + package DMG
EOF
}

# Defaults
BUILD_CONFIG="Debug"
RUN_TESTS=false
PACKAGE=false
CLEAN=false
NO_SIGN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)    print_usage; exit 0 ;;
        -c|--clean)   CLEAN=true; shift ;;
        -r|--release) BUILD_CONFIG="Release"; shift ;;
        -t|--test)    RUN_TESTS=true; shift ;;
        -p|--package) PACKAGE=true; shift ;;
        -n|--no-sign) NO_SIGN=true; shift ;;
        -v|--verbose) set -x; shift ;;
        *) error "Unknown option: $1"; print_usage; exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

info "LinkLiar build started (config=$BUILD_CONFIG)"

# ── Check prerequisites ──────────────────────────────────────

if ! command -v xcodebuild &> /dev/null; then
    error "xcodebuild not found. Install Xcode Command Line Tools."
    exit 1
fi

if ! command -v cargo &> /dev/null; then
    error "cargo not found. Install Rust: https://rustup.rs"
    exit 1
fi

info "xcodebuild: $(xcodebuild -version | head -n 1)"
info "cargo: $(cargo --version)"

# ── Clean ─────────────────────────────────────────────────────

if [ "$CLEAN" = true ]; then
    info "Cleaning build caches..."
    rm -rf build/
    rm -rf ~/Library/Developer/Xcode/DerivedData/LinkLiar-*
    cd linktools-rs && cargo clean && cd ..
    xcodebuild clean -project LinkLiar.xcodeproj -scheme LinkLiar -quiet
    info "Clean done"
fi

# ── Step 1: Build Rust library ────────────────────────────────

info "[1/3] Building Rust library..."
cd linktools-rs

if [ ! -f "target/release/liblinktools.dylib" ]; then
    cargo build --release
else
    info "Rust library up to date, skipping"
fi

if [ ! -f "target/release/liblinktools.dylib" ]; then
    error "liblinktools.dylib not found after build"
    exit 1
fi

info "Rust library ready ($(du -h target/release/liblinktools.dylib | cut -f1))"
cd ..

# ── Step 2: Copy dylib into app bundle ────────────────────────

info "[2/3] Integrating Rust library..."
cp linktools-rs/target/release/liblinktools.dylib LinkLiar/
info "Library copied"

# ── Step 3: Build Xcode project ───────────────────────────────

info "[3/3] Building Xcode project..."
BUILD_OUTPUT=$(mktemp)

SIGN_FLAGS=()
if [ "$NO_SIGN" = true ]; then
    warn "Code signing disabled (local dev build)"
    SIGN_FLAGS=(
        CODE_SIGN_IDENTITY=""
        CODE_SIGNING_REQUIRED=NO
        CODE_SIGNING_ALLOWED=NO
    )
fi

xcodebuild -project LinkLiar.xcodeproj \
           -scheme LinkLiar \
           -configuration "$BUILD_CONFIG" \
           "${SIGN_FLAGS[@]}" \
           build 2>&1 | tee "$BUILD_OUTPUT" | grep -E "BUILD (SUCCEEDED|FAILED)" || true

if grep -q "BUILD SUCCEEDED" "$BUILD_OUTPUT"; then
    info "Xcode build succeeded"
else
    error "Xcode build failed"
    cat "$BUILD_OUTPUT"
    rm -f "$BUILD_OUTPUT"
    exit 1
fi

rm -f "$BUILD_OUTPUT"

# ── Tests ─────────────────────────────────────────────────────

if [ "$RUN_TESTS" = true ]; then
    info "Running Rust tests..."
    cd linktools-rs
    cargo test --lib
    cd ..

    info "Running Swift tests..."
    xcodebuild test -scheme LinkLiar -destination 'platform=macOS' \
        "${SIGN_FLAGS[@]}" 2>&1 | tail -5
fi

# ── Package ───────────────────────────────────────────────────

if [ "$PACKAGE" = true ]; then
    info "Packaging..."

    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/LinkLiar-*/Build/Products/"$BUILD_CONFIG" \
        -name "LinkLiar.app" -maxdepth 1 2>/dev/null | head -n 1)

    if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
        error "LinkLiar.app not found"
        exit 1
    fi

    mkdir -p build/dist
    cp -R "$APP_PATH" build/dist/

    if [ "$NO_SIGN" = true ]; then
        info "Ad-hoc signing..."
        codesign --force --deep -s - "build/dist/LinkLiar.app" 2>/dev/null || warn "Ad-hoc signing failed"
    fi

    VERSION=$(git describe --tags --always 2>/dev/null || echo "dev")

    info "Creating DMG..."
    if hdiutil create -volname "LinkLiar" \
                      -srcfolder build/dist \
                      -ov -format UDZO \
                      "build/LinkLiar-$VERSION.dmg" 2>/dev/null; then
        info "DMG created: build/LinkLiar-$VERSION.dmg ($(du -h "build/LinkLiar-$VERSION.dmg" | cut -f1))"
    else
        warn "DMG creation failed, .app is still available at build/dist/LinkLiar.app"
    fi
fi

# ── Summary ───────────────────────────────────────────────────

echo ""
info "========================================="
info "Build succeeded ($BUILD_CONFIG)"
info "========================================="

if [ "$PACKAGE" = true ]; then
    info "App: build/dist/LinkLiar.app"
    info "Run: open build/dist/LinkLiar.app"
else
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/LinkLiar-*/Build/Products/"$BUILD_CONFIG" \
        -name "LinkLiar.app" -maxdepth 1 2>/dev/null | head -n 1)
    if [ -n "$APP_PATH" ]; then
        info "App: $APP_PATH"
        info "Run: open '$APP_PATH'"
    fi
fi
