#!/bin/bash

# LinkLiar 应用构建脚本
# 用途：从源代码自动构建 LinkLiar macOS 应用

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 打印使用说明
print_usage() {
    cat << EOF
LinkLiar 构建脚本

用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -c, --clean         清理构建缓存
    -r, --release       构建 Release 版本（默认 Debug）
    -t, --test          运行测试
    -p, --package       打包 .app 文件
    -d, --debug         显示详细调试信息

示例:
    $0                  # 构建开发版本
    $0 -r              # 构建发布版本
    $0 -c -r           # 清理并构建发布版本
    $0 -t              # 运行测试
    $0 -p              # 打包应用

EOF
}

# 默认值
BUILD_TYPE="Debug"
RUN_TESTS=false
PACKAGE=false
CLEAN=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -r|--release)
            BUILD_TYPE="Release"
            shift
            ;;
        -t|--test)
            RUN_TESTS=true
            shift
            ;;
        -p|--package)
            PACKAGE=true
            shift
            ;;
        -d|--debug)
            set -x
            shift
            ;;
        *)
            print_error "未知选项: $1"
            print_usage
            exit 1
            ;;
    esac
done

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

print_info "LinkLiar 构建脚本启动"
print_info "构建类型: $BUILD_TYPE"

# 检查必需工具
print_info "检查构建环境..."

if ! command -v xcodebuild &> /dev/null; then
    print_error "未找到 xcodebuild。请安装 Xcode Command Line Tools。"
    exit 1
fi

if ! command -v cargo &> /dev/null; then
    print_error "未找到 cargo。请安装 Rust。"
    exit 1
fi

print_info "✓ xcodebuild 版本: $(xcodebuild -version | head -n 1)"
print_info "✓ cargo 版本: $(cargo --version)"

# 清理构建缓存
if [ "$CLEAN" = true ]; then
    print_info "清理构建缓存..."
    rm -rf build/
    rm -rf ~/Library/Developer/Xcode/DerivedData/LinkLiar-*
    xcodebuild clean -project LinkLiar.xcodeproj -scheme LinkLiar
    print_info "✓ 清理完成"
fi

# 步骤 1: 构建 Rust 库
print_info "步骤 1/5: 构建 Rust 库..."
cd linktools-rs

if [ ! -d "target/release" ] || [ ! -f "target/release/liblinktools.dylib" ]; then
    print_info "编译 Rust 库..."
    cargo build --release
    
    if [ $? -ne 0 ]; then
        print_error "Rust 库构建失败"
        exit 1
    fi
else
    print_info "✓ Rust 库已存在，跳过编译"
fi

# 检查构建产物
if [ ! -f "target/release/liblinktools.dylib" ]; then
    print_error "未找到 liblinktools.dylib"
    exit 1
fi

print_info "✓ Rust 库构建完成: $(du -h target/release/liblinktools.dylib | cut -f1)"

cd ..

# 步骤 2: 复制 Rust 库到主项目
print_info "步骤 2/5: 集成 Rust 库..."
cp linktools-rs/target/release/liblinktools.dylib LinkLiar/
print_info "✓ 库文件已复制"

# 步骤 3: 构建 Xcode 项目
print_info "步骤 3/5: 构建 Xcode 项目..."
BUILD_OUTPUT=$(mktemp)

xcodebuild -project LinkLiar.xcodeproj \
           -scheme LinkLiar \
           -configuration "$BUILD_TYPE" \
           build 2>&1 | tee "$BUILD_OUTPUT" | grep -E "BUILD (SUCCEEDED|FAILED)" || true

if grep -q "BUILD SUCCEEDED" "$BUILD_OUTPUT"; then
    print_info "✓ Xcode 构建成功"
else
    print_error "Xcode 构建失败"
    cat "$BUILD_OUTPUT"
    exit 1
fi

rm -f "$BUILD_OUTPUT"

# 步骤 4: 运行测试
if [ "$RUN_TESTS" = true ]; then
    print_info "步骤 4/5: 运行测试..."
    
    # Swift 测试
    print_info "运行 Swift 单元测试..."
    if xcodebuild test -scheme LinkLiar -destination 'platform=macOS' 2>&1 | grep -q "Test Suite 'All tests' passed"; then
        print_info "✓ Swift 测试通过"
    else
        print_warn "Swift 测试有失败，但继续构建"
    fi
    
    # Rust 测试
    print_info "运行 Rust 单元测试..."
    cd linktools-rs
    if cargo test --lib 2>&1 | grep -q "test result: ok"; then
        print_info "✓ Rust 测试通过"
    else
        print_warn "Rust 测试有失败，但继续构建"
    fi
    cd ..
else
    print_info "步骤 4/5: 跳过测试（使用 -t 运行测试）"
fi

# 步骤 5: 打包应用
if [ "$PACKAGE" = true ]; then
    print_info "步骤 5/5: 打包应用..."
    
    # 查找构建的 .app 文件
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/LinkLiar-*/Build/Products/"$BUILD_TYPE" -name "LinkLiar.app" -maxdepth 1 2>/dev/null | head -n 1)
    
    if [ -z "$APP_PATH" ]; then
        print_warn "未找到 LinkLiar.app，尝试使用 build/ 目录"
        APP_PATH="build/$BUILD_TYPE/LinkLiar.app"
    fi
    
    if [ -d "$APP_PATH" ]; then
        # 创建输出目录
        mkdir -p build/dist
        
        # 复制 .app 文件
        cp -R "$APP_PATH" build/dist/
        
        # 获取版本号
        VERSION=$(git describe --tags --always 2>/dev/null || echo "unknown")
        
        # 创建 DMG 镜像
        print_info "创建 DMG 镜像..."
        hdiutil create -volname "LinkLiar" \
                      -srcfolder build/dist \
                      -ov -format UDZO \
                      "build/LinkLiar-$VERSION.dmg" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            DMG_SIZE=$(du -h "build/LinkLiar-$VERSION.dmg" | cut -f1)
            print_info "✓ DMG 镜像创建成功: LinkLiar-$VERSION.dmg ($DMG_SIZE)"
        else
            print_warn "DMG 创建失败，但 .app 文件可用"
        fi
        
        print_info "✓ 应用打包完成"
        print_info "位置: build/dist/LinkLiar.app"
    else
        print_error "未找到 LinkLiar.app 文件"
        exit 1
    fi
else
    print_info "步骤 5/5: 跳过打包（使用 -p 打包应用）"
fi

# 构建成功总结
echo ""
print_info "========================================="
print_info "构建成功！🎉"
print_info "========================================="
print_info "构建类型: $BUILD_TYPE"
print_info "构建时间: $(date '+%Y-%m-%d %H:%M:%S')"

if [ "$PACKAGE" = true ]; then
    print_info "应用位置: build/dist/LinkLiar.app"
    print_info ""
    print_info "要运行应用，执行:"
    print_info "  open build/dist/LinkLiar.app"
fi

if [ "$PACKAGE" = false ]; then
    print_info ""
    print_info "要查找构建的 .app 文件，执行:"
    print_info "  find ~/Library/Developer/Xcode/DerivedData/LinkLiar-*/Build/Products/$BUILD_TYPE -name 'LinkLiar.app'"
fi

print_info ""
print_info "要运行测试，执行:"
print_info "  $0 -t"
print_info ""
print_info "要打包应用，执行:"
print_info "  $0 -p"
print_info ""

exit 0
