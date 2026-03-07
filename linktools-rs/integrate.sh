#!/bin/bash
set -e

echo "🔨 Building Rust library..."
cd linktools-rs
cargo build --release

echo ""
echo "✅ Build successful!"
echo ""
echo "📦 Library files:"
ls -lh target/release/liblinktools.* | head -5

echo ""
echo "📝 Next steps:"
echo "1. Add liblinktools.dylib to Xcode project:"
echo "   - In Xcode: File → Add Files to \"LinkLiar\""
echo "   - Select: linktools-rs/target/release/liblinktools.dylib"
echo "   - Add to \"Copy Files\" build phase"
echo ""
echo "2. Add RustBridge.swift to your project:"
echo "   - File already created at: LinkLiar/Classes/Backends/RustBindings/RustBridge.swift"
echo ""
echo "3. Add header search path in Xcode:"
echo "   - Build Settings → Search Paths → Header Search Paths"
echo "   - Add: \$(SRCROOT)/LinkLiar/Classes/Backends/RustBindings"
echo ""
echo "4. Link the library:"
echo "   - Build Phases → Link Binary With Libraries"
echo "   - Add: liblinktools.dylib"
echo ""
echo "5. Run tests:"
echo "   cd .. && xcodebuild test -scheme LinkLiar"
echo ""
