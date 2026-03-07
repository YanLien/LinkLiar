#!/bin/bash
# 演示 Rust 库的功能

set -e

echo "🎯 LinkLiar Rust Library Demo"
echo "=============================="
echo ""

# 构建库
echo "📦 Building Rust library..."
cd linktools-rs
cargo build --release > /dev/null 2>&1
echo "✅ Build complete"
echo ""

# 运行测试
echo "🧪 Running tests..."
cargo test --quiet 2>&1 | grep "test result"
echo ""

# 运行性能测试
echo "⚡ Running benchmarks..."
echo ""
echo "=== MAC Parsing ==="
cargo bench --quiet mac_parse 2>&1 | grep "time:"
echo ""
echo "=== OUI Lookup ==="
cargo bench --quiet oui_lookup 2>&1 | grep "time:"
echo ""
echo "=== Random MAC Generation ==="
cargo bench --quiet random 2>&1 | grep "time:"

echo ""
echo "✨ Demo complete!"
