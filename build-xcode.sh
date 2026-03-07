#!/bin/bash

# LinkLiar Xcode 构建脚本（使用完整路径）

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Xcode 路径
XCODEBUILD_PATH="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"

print_info "使用完整路径的 Xcode 构建工具"

# 检查 Xcode
if [ ! -f "$XCODEBUILD_PATH" ]; then
    print_error "未找到 Xcode，请确认安装路径"
    exit 1
fi

print_info "✓ 找到 Xcode: $XCODEBUILD_PATH"

# 构建 Rust 库
print_info "步骤 1/3: 构建 Rust 库..."
cd linktools-rs

if [ ! -f "target/release/liblinktools.dylib" ]; then
    print_info "编译 Rust 库..."
    cargo build --release
else
    print_info "✓ Rust 库已存在"
fi

cd ..
print_info "✓ Rust 库准备完成"

# 复制库文件
print_info "步骤 2/3: 集成 Rust 库..."
cp linktools-rs/target/release/liblinktools.dylib LinkLiar/
print_info "✓ 库文件已复制"

# 使用完整路径构建（禁用代码签名）
print_info "步骤 3/3: 构建 Xcode 项目..."
BUILD_OUTPUT=$(mktemp)

"$XCODEBUILD_PATH" -project LinkLiar.xcodeproj \
                -scheme LinkLiar \
                -configuration Debug \
                CODE_SIGN_IDENTITY="" \
                CODE_SIGNING_REQUIRED=NO \
                CODE_SIGNING_ALLOWED=NO \
                build 2>&1 | tee "$BUILD_OUTPUT" | grep -E "BUILD (SUCCEEDED|FAILED)" || true

if grep -q "BUILD SUCCEEDED" "$BUILD_OUTPUT"; then
    print_info "✓ 构建成功！"
    
    # 查找 .app 文件
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/LinkLiar-*/Build/Products/Debug -name "LinkLiar.app" -maxdepth 1 2>/dev/null | head -n 1)
    
    if [ -n "$APP_PATH" ]; then
        echo ""
        print_info "========================================="
        print_info "构建完成！🎉"
        print_info "========================================="
        print_info "应用位置: $APP_PATH"
        print_info ""
        print_info "要运行应用，执行:"
        print_info "  open '$APP_PATH'"
        print_info ""
    fi
else
    print_error "构建失败"
    cat "$BUILD_OUTPUT"
    exit 1
fi

rm -f "$BUILD_OUTPUT"
exit 0
