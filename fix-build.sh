#!/bin/bash

# LinkLiar 快速构建修复脚本
# 自动诊断并修复常见的构建问题

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

clear
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   LinkLiar 构建诊断与修复工具                            ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF

echo ""

# 诊断步骤
print_step "1/6: 检查 Xcode 安装..."

if [ -d "/Applications/Xcode.app" ]; then
    print_info "✓ Xcode 已安装"
else
    print_error "✗ 未找到 Xcode"
    echo ""
    echo "请先安装 Xcode："
    echo "  1. 从 App Store 安装 Xcode"
    echo "  2. 或下载: https://developer.apple.com/download/all/"
    exit 1
fi

echo ""
print_step "2/6: 检查开发者工具路径..."

CURRENT_PATH=$(xcode-select --print-path 2>/dev/null || echo "")
XCODE_PATH="/Applications/Xcode.app/Contents/Developer"

if [ "$CURRENT_PATH" = "$XCODE_PATH" ]; then
    print_info "✓ 开发者路径正确: $CURRENT_PATH"
else
    print_warn "✗ 当前路径: $CURRENT_PATH"
    print_warn "应该设置为: $XCODE_PATH"
    echo ""
    read -p "是否要修复? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "正在修复..."
        sudo xcode-select --switch "$XCODE_PATH"
        print_info "✓ 已修复"
    else
        print_error "用户取消"
        exit 1
    fi
fi

echo ""
print_step "3/6: 检查代码签名证书..."

CERTS=$(security find-identity -v -p codesigning 2>/dev/null | grep -c "Apple Development" || true)
if [ $CERTS -gt 0 ]; then
    print_info "✓ 找到 $CERTS 个代码签名证书"
    HAS_CERTS=true
else
    print_warn "✗ 未找到代码签名证书"
    print_warn "将使用本地构建（无签名）"
    HAS_CERTS=false
fi

echo ""
print_step "4/6: 检查 Rust 环境..."

if command -v cargo &> /dev/null; then
    RUST_VERSION=$(cargo --version 2>/dev/null)
    print_info "✓ Rust 已安装: $RUST_VERSION"
else
    print_error "✗ 未找到 Rust"
    echo ""
    echo "请安装 Rust："
    echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

echo ""
print_step "5/6: 检查 Rust 库..."

if [ -f "linktools-rs/target/release/liblinktools.dylib" ]; then
    print_info "✓ Rust 库已编译"
    NEED_RUST_BUILD=false
else
    print_warn "✗ 需要编译 Rust 库"
    NEED_RUST_BUILD=true
fi

echo ""
print_step "6/6: 选择构建方式..."

echo ""
echo "请选择构建方式："
echo ""
if [ "$HAS_CERTS" = true ]; then
    echo "  1) 完整构建（带代码签名）- 推荐"
else
    echo "  1) 完整构建（带代码签名）- 需要证书"
fi
echo "  2) 本地构建（无签名）- 仅用于开发"
echo "  3) 使用 Xcode GUI"
echo "  q) 退出"
echo ""
read -p "请选择 [1-3/q]: " -r -n 1 CHOICE
echo ""

case $CHOICE in
    1)
        if [ "$HAS_CERTS" = false ]; then
            print_error "没有可用的代码签名证书"
            echo ""
            echo "请选择："
            echo "  a) 继续使用本地构建（无签名）"
            echo "  b) 设置证书后重试"
            echo "  q) 退出"
            read -p "请选择 [a/b/q]: " -n 1 -r SUBCHOICE
            echo ""
            
            case $SUBCHOICE in
                a) BUILD_TYPE="local" ;;
                b) 
                    print_info "请先配置代码签名证书，然后重试"
                    exit 0
                    ;;
                q) exit 0 ;;
                *) exit 1 ;;
            esac
        else
            BUILD_TYPE="full"
        fi
        ;;
    2)
        BUILD_TYPE="local"
        ;;
    3)
        print_info "正在打开 Xcode..."
        open LinkLiar.xcodeproj
        print_info "请在 Xcode 中："
        echo "  1. 选择 LinkLiar scheme"
        echo "  2. Product → Build (Cmd+B)"
        echo "  3. Product → Run (Cmd+R)"
        exit 0
        ;;
    q|Q)
        print_info "退出"
        exit 0
        ;;
    *)
        print_error "无效选择"
        exit 1
        ;;
esac

# 执行构建
echo ""
print_info "========================================="
print_info "开始构建: $BUILD_TYPE"
print_info "========================================="
echo ""

# 编译 Rust 库（如果需要）
if [ "$NEED_RUST_BUILD" = true ]; then
    print_info "编译 Rust 库..."
    cd linktools-rs
    if cargo build --release; then
        print_info "✓ Rust 库编译成功"
    else
        print_error "Rust 库编译失败"
        exit 1
    fi
    cd ..
fi

# 复制库文件
print_info "集成 Rust 库..."
cp -f linktools-rs/target/release/liblinktools.dylib LinkLiar/
print_info "✓ 库文件已复制"

# 根据选择构建
if [ "$BUILD_TYPE" = "local" ]; then
    print_info "使用本地构建方式..."
    if [ -f "./build-local.sh" ]; then
        exec ./build-local.sh
    else
        print_error "未找到 build-local.sh"
        exit 1
    fi
elif [ "$BUILD_TYPE" = "full" ]; then
    print_info "使用完整构建方式..."
    if [ -f "./build.sh" ]; then
        exec ./build.sh
    else
        print_error "未找到 build.sh"
        exit 1
    fi
fi

exit 0
