#!/bin/bash

# LinkLiar 简化构建脚本（本地开发版本）
# 用于本地测试，不需要代码签名

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 解析命令行参数
PACKAGE=false
BUILD_TYPE="Debug"

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--package)
            PACKAGE=true
            shift
            ;;
        -r|--release)
            BUILD_TYPE="Release"
            shift
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  -p, --package    打包成 DMG 镜像"
            echo "  -r, --release    构建 Release 版本"
            echo "  -h, --help       显示此帮助信息"
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            echo "使用 -h 查看帮助"
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

print_info "LinkLiar 本地构建脚本（无代码签名）"
print_info "构建类型: $BUILD_TYPE"

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
# 创建构建输出目录
BUILD_DIR="$SCRIPT_DIR/build"
APP_DIR="$BUILD_DIR/Debug"
mkdir -p "$APP_DIR"

print_info "✓ 构建目录: $APP_DIR"

# 构建完成，复制 .app 到项目目录
print_info "复制应用到项目目录..."

# 查找 Xcode 构建的 .app
XCODE_APP=$(find ~/Library/Developer/Xcode/DerivedData/LinkLiar-*/Build/Products/Debug -name "LinkLiar.app" -maxdepth 1 2>/dev/null | head -n 1)

if [ -n "$XCODE_APP" ] && [ -d "$XCODE_APP" ]; then
    # 删除旧的构建
    rm -rf "$APP_DIR/LinkLiar.app"
    
    # 复制新的 .app
    cp -R "$XCODE_APP" "$APP_DIR/"
    
    # 重新签名（使用 ad-hoc）
    print_info "重新签名应用（ad-hoc）..."
    codesign --force --deep -s - "$APP_DIR/LinkLiar.app" 2>/dev/null || print_warn "重新签名失败，但可能不影响使用"
    
    echo ""
    print_info "========================================="
    print_info "构建完成！🎉"
    print_info "========================================="
    print_info "应用位置: $APP_DIR/LinkLiar.app"
    print_info ""
    print_info "运行应用:"
    print_info "  open '$APP_DIR/LinkLiar.app'"
    print_info ""
    print_info "或者从 Finder 打开:"
    print_info "  open '$APP_DIR'"
    print_info ""
    print_info "注意: 这是未签名的开发版本，可能需要在系统设置中允许运行"
    print_info ""
else
    print_warn "构建成功但未找到 .app 文件"
fi

rm -f "$BUILD_LOG"
exit 0
