#!/bin/bash

# LinkLiar 简化构建脚本（本地开发版本）
# 用于本地测试，不需要代码签名

set -e

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

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

print_info "LinkLiar 本地构建脚本（无代码签名）"

# Xcode 路径
XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"

# 检查 Xcode
if [ ! -f "$XCODEBUILD" ]; then
    print_error "未找到 Xcode"
    exit 1
fi

print_info "✓ Xcode: $XCODEBUILD"

# 步骤 1: Rust 库
print_info "步骤 1/4: 检查 Rust 库..."
if [ ! -f "linktools-rs/target/release/liblinktools.dylib" ]; then
    print_info "编译 Rust 库..."
    cd linktools-rs
    cargo build --release
    cd ..
fi
print_info "✓ Rust 库就绪"

# 步骤 2: 复制库
print_info "步骤 2/4: 复制 Rust 库..."
cp -f linktools-rs/target/release/liblinktools.dylib LinkLiar/
print_info "✓ 库文件已复制"

# 步骤 3: 清理旧的构建
print_info "步骤 3/4: 清理旧的构建..."
rm -rf ~/Library/Developer/Xcode/DerivedData/LinkLiar-*/Build/Products/Debug/

# 步骤 4: 构建（禁用代码签名）
print_info "步骤 4/4: 构建 Xcode 项目（无代码签名）..."
print_warn "注意: 本地构建不进行代码签名，仅用于开发测试"

BUILD_LOG=$(mktemp)

"$XCODEBUILD" -project LinkLiar.xcodeproj \
            -scheme LinkLiar \
            -configuration Debug \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            AD_HOC_CODE_SIGNING_ALLOWED=YES \
            build 2>&1 | tee "$BUILD_LOG"

# 检查构建结果
if grep -q "BUILD SUCCEEDED" "$BUILD_LOG"; then
    print_info "✓ 构建成功！"
    
    # 查找 .app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/LinkLiar-*/Build/Products/Debug -name "LinkLiar.app" -maxdepth 1 2>/dev/null | head -n 1)
    
    if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
        # 重新签名（使用 ad-hoc）
        print_info "重新签名应用（ad-hoc）..."
        codesign --force --deep -s - "$APP_PATH" 2>/dev/null || print_warn "重新签名失败，但可能不影响使用"
        
        echo ""
        print_info "========================================="
        print_info "构建完成！🎉"
        print_info "========================================="
        print_info "应用位置: $APP_PATH"
        print_info ""
        print_info "运行应用:"
        print_info "  open '$APP_PATH'"
        print_info ""
        print_info "注意: 这是未签名的开发版本，可能需要在系统设置中允许运行"
        print_info ""
    else
        print_warn "构建成功但未找到 .app 文件"
    fi
else
    print_error "构建失败"
    echo ""
    print_info "查看完整日志:"
    print_info "  cat $BUILD_LOG"
    echo ""
    exit 1
fi

rm -f "$BUILD_LOG"
exit 0
