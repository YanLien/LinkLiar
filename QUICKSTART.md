# LinkLiar 快速构建指南

## 🚀 三种构建方式

### 方式 1️⃣: 使用自动化脚本（最简单）

```bash
# 进入项目目录
cd /Users/yjq/Program/LinkLiar

# 一键构建（开发版本）
./build.sh

# 构建发布版本
./build.sh --release

# 清理并构建
./build.sh --clean --release

# 构建并运行测试
./build.sh --test

# 构建并打包成 DMG
./build.sh --package
```

**脚本会自动完成**：
- ✅ 检查构建环境
- ✅ 编译 Rust 库
- ✅ 构建 Xcode 项目
- ✅ 运行测试（可选）
- ✅ 打包应用（可选）

---

### 方式 2️⃣: 使用 Xcode（推荐新手）

1. **打开项目**
   ```bash
   open LinkLiar.xcodeproj
   ```

2. **选择 Scheme**
   - 点击 Xcode 顶部工具栏
   - 选择 `LinkLiar` scheme

3. **构建**
   - 按 `Cmd + B` 构建项目
   - 或点击菜单：`Product → Build`

4. **运行**
   - 按 `Cmd + R` 运行应用
   - 或点击菜单：`Product → Run`

---

### 方式 3️⃣: 使用命令行（适合 CI/CD）

```bash
# 进入项目目录
cd /Users/yjq/Program/LinkLiar

# 构建 Rust 库
cd linktools-rs
cargo build --release
cd ..

# 复制库文件
cp linktools-rs/target/release/liblinktools.dylib LinkLiar/

# 构建 Xcode 项目
xcodebuild -project LinkLiar.xcodeproj \
           -scheme LinkLiar \
           -configuration Release \
           build
```

---

## 📦 查找构建产物

### macOS 默认位置

```bash
# Xcode Derived Data
open ~/Library/Developer/Xcode/DerivedData/LinkLiar-*/Build/Products/Release/
```

### 项目目录

```bash
# 如果使用脚本
ls -lh build/dist/LinkLiar.app

# 手动构建时
find . -name "LinkLiar.app" -type d
```

---

## 🏃 快速测试构建

### 最快的方式（30秒）

```bash
cd /Users/yjq/Program/LinkLiar
./build.sh
```

### 预期输出

```
[INFO] LinkLiar 构建脚本启动
[INFO] 构建类型: Debug
[INFO] 检查构建环境...
[INFO] ✓ xcodebuild 版本: Xcode 15.0
[INFO] ✓ cargo 版本: cargo 1.75.0
[INFO] 步骤 1/5: 构建 Rust 库...
[INFO] ✓ Rust 库构建完成: 1.2M
[INFO] 步骤 2/5: 集成 Rust 库...
[INFO] ✓ 库文件已复制
[INFO] 步骤 3/5: 构建 Xcode 项目...
[INFO] ✓ Xcode 构建成功
[INFO] 步骤 4/5: 跳过测试（使用 -t 运行测试）
[INFO] 步骤 5/5: 跳过打包（使用 -p 打包应用）

[INFO] =========================================
[INFO] 构建成功！🎉
[INFO] =========================================
```

---

## 🔧 常见问题

### ❌ Rust 库构建失败

**问题**: `cargo build` 失败

**解决**:
```bash
# 更新 Rust
rustup update

# 清理缓存
cd linktools-rs
cargo clean
cargo build --release
```

### ❌ Xcode 构建失败

**问题**: `xcodebuild` 失败

**解决**:
```bash
# 清理构建缓存
xcodebuild clean -project LinkLiar.xcodeproj -scheme LinkLiar

# 重置 Derived Data
rm -rf ~/Library/Developer/Xcode/DerivedData/LinkLiar-*

# 重新构建
./build.sh --clean
```

### ❌ 找不到 .app 文件

**问题**: 构建成功但找不到 LinkLiar.app

**解决**:
```bash
# 搜索所有 .app 文件
find ~/Library/Developer/Xcode/DerivedData -name "LinkLiar.app" 2>/dev/null

# 或使用脚本打包
./build.sh --package
ls -lh build/dist/LinkLiar.app
```

---

## 📚 详细文档

完整的构建指南请参阅：
- **[BUILD_GUIDE.md](BUILD_GUIDE.md)** - 完整的构建文档
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - 开发者文档
- **[linktools-rs/README.md](linktools-rs/README.md)** - Rust 库文档

---

## 🎯 推荐流程

### 首次构建

```bash
# 1. 克隆项目（如果还没有）
git clone https://github.com/halo/LinkLiar.git
cd LinkLiar

# 2. 检查环境
xcodebuild -version
rustc --version

# 3. 一键构建
./build.sh --clean

# 4. 运行应用
open ~/Library/Developer/Xcode/DerivedData/LinkLiar-*/Build/Products/Debug/LinkLiar.app
```

### 日常开发

```bash
# 快速构建
./build.sh

# 运行测试
./build.sh --test

# 调试版本
./build.sh --debug
```

### 发布版本

```bash
# 完整发布流程
./build.sh --clean --release --test --package

# 查找 DMG
ls -lh build/LinkLiar-*.dmg
```

---

## 💡 提示

1. **首次构建**可能需要 5-10 分钟（下载依赖）
2. **后续构建**通常在 30 秒内完成
3. 使用 `--clean` 选项解决奇怪的构建问题
4. Rust 库变化时需要重新编译（脚本会自动处理）
5. Xcode 中的 `Cmd + B` 是最快的重新编译方式

---

**开始构建吧！** 🚀
