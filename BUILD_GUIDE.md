# LinkLiar 应用构建指南

本指南将帮助你从源代码构建 LinkLiar macOS 应用程序。

## 📋 前置要求

### 必需软件
- **Xcode**: 14.0 或更高版本
- **macOS**: 10.12 (Sierra) 或更高版本
- **Rust**: 1.70 或更高版本（用于编译 Rust 库）
- **Xcode Command Line Tools**: 已安装

### 安装检查
```bash
# 检查 Xcode 版本
xcodebuild -version

# 检查 Rust 版本
rustc --version

# 检查 Cargo 版本
cargo --version
```

---

## 🚀 快速开始

### 方法 1: 使用 Xcode（推荐）

1. **打开项目**
   ```bash
   cd /Users/yjq/Program/LinkLiar
   open LinkLiar.xcodeproj
   ```

2. **选择 Scheme**
   - 点击 Xcode 顶部工具栏的 Scheme 选择器
   - 选择 `LinkLiar`

3. **构建应用**
   - 按 `Cmd + B` 或点击菜单 `Product → Build`

4. **运行应用**
   - 按 `Cmd + R` 或点击菜单 `Product → Run`

### 方法 2: 使用命令行

```bash
# 进入项目目录
cd /Users/yjq/Program/LinkLiar

# 构建 LinkLiar 应用
xcodebuild -project LinkLiar.xcodeproj -scheme LinkLiar build

# 构建并运行
xcodebuild -project LinkLiar.xcodeproj -scheme LinkLiar build
open build/Release/LinkLiar.app
```

---

## 🔧 完整构建流程

### 步骤 1: 构建 Rust 库

```bash
# 进入 Rust 库目录
cd linktools-rs

# 构建动态库
cargo build --release

# 验证构建产物
ls -lh target/release/liblinktools.dylib
```

**预期输出**:
```
-rwxr-xr-x  1 user  staff   1.2M Mar  7 22:47 liblinktools.dylib
```

### 步骤 2: 准备 Xcode 项目

1. **生成 C 头文件**
   ```bash
   cd linktools-rs
   cbindgen --lang C --output include/linktools.h
   ```

2. **复制库文件到 Xcode 项目**
   ```bash
   # 复制动态库
   cp target/release/liblinktools.dylib ../LinkLiar/
   
   # 或使用项目提供的脚本
   ./integrate.sh
   ```

### 步骤 3: 配置 Xcode 项目

#### 3.1 添加 Copy Files Phase

在 Xcode 中：
1. 选择 `LinkLiar` target
2. 进入 `Build Phases` 标签
3. 点击 `+` 按钮
4. 选择 `New Copy Files Phase`
5. 添加以下内容：
   - **Destination**: `Executables`
   - **Subpath**: (留空)
   - **Files to add**: `liblinktools.dylib`

#### 3.2 配置 Header Search Paths

1. 进入 `Build Settings` 标签
2. 搜索 `Header Search Paths`
3. 添加路径：
   ```
   $(SRCROOT)/LinkLiar/Classes/Backends/RustBindings
   ```

#### 3.3 链接动态库

1. 在 `Build Phases` → `Link Binary With Libraries`
2. 点击 `+` 添加 `liblinktools.dylib`

### 步骤 4: 构建应用

```bash
# 使用 Xcode 命令行工具
xcodebuild -project LinkLiar.xcodeproj \
           -scheme LinkLiar \
           -configuration Release \
           build

# 或者在 Xcode 中按 Cmd+B
```

### 步骤 5: 查找构建产物

```bash
# 查看 .app 文件位置
open build/Release/

# 或使用 Xcode 的默认位置
open ~/Library/Developer/Xcode/DerivedData/LinkLiar-*/Build/Products/Release/
```

---

## 🧪 运行测试

### Swift 单元测试

```bash
# 运行所有测试
xcodebuild test -scheme LinkLiar -destination 'platform=macOS'

# 运行特定测试
xcodebuild test -scheme LinkLiar \
  -only-testing:LinkLiarTests/MACParserTest
```

### Rust 单元测试

```bash
cd linktools-rs

# 运行所有测试
cargo test

# 运行特定测试
cargo test test_mac_parse

# 显示测试输出
cargo test -- --nocapture
```

### 性能基准测试

```bash
cd linktools-rs

# 运行基准测试
cargo bench
```

---

## 📦 打包发布版本

### 创建可分发的 .app 文件

1. **Archive 构建**
   ```bash
   xcodebuild archive \
     -project LinkLiar.xcodeproj \
     -scheme LinkLiar \
     -archivePath build/LinkLiar.xcarchive
   ```

2. **导出 .app**
   ```bash
   xcodebuild -exportArchive \
     -archivePath build/LinkLiar.xcarchive \
     -exportPath build/Release \
     -exportOptionsPlist ExportOptions.plist
   ```

3. **创建 DMG 镜像** (可选)
   ```bash
   # 创建临时目录
   mkdir -p dmg-root
   
   # 复制 .app 文件
   cp -R build/Release/LinkLiar.app dmg-root/
   
   # 创建 DMG
   hdiutil create -volname "LinkLiar" \
     -srcfolder dmg-root \
     -ov -format UDZO \
     LinkLiar.dmg
   ```

---

## 🔐 代码签名

### 开发者签名

```bash
# 查看可用的签名证书
security find-identity -v -p codesigning

# 签名应用
codesign --force --deep --sign "Developer ID Application: Your Name" \
  build/Release/LinkLiar.app

# 验证签名
codesign -dv build/Release/LinkLiar.app
```

### 公发布签名

对于公开发布，需要：
1. Apple Developer 账号
2. Developer ID 证书
3. 公证（Notarization）

---

## 🐛 调试技巧

### 启用日志

```bash
# 创建日志文件
sudo touch "/Library/Application Support/LinkLiar/linkliar.log"

# 查看日志
tail -f "/Library/Application Support/LinkLiar/linkliar.log"
```

### Xcode 调试

1. **设置断点**
   - 在代码行号左侧点击设置断点
   - 按 `Cmd + \` 切换断点

2. **查看变量**
   - 调试时悬停在变量上查看值
   - 使用 `lldb` 控制台输入 `print variable_name`

3. **内存调试**
   ```bash
   # 启用内存图形
   Product → Scheme → Edit Scheme → Run → Diagnostics
   勾选 "Memory Management"
   ```

### 常见问题

#### 问题 1: Rust 库未找到

**症状**: 运行时报错 `dyld: Library not loaded: @rpath/liblinktools.dylib`

**解决方案**:
```bash
# 确认库在 Copy Files phase 中
# 确认 @rpath 在 Runpath Search Paths 中
# 重新构建
xcodebuild clean build
```

#### 问题 2: 代码签名错误

**症状**: `code object is not signed at all`

**解决方案**:
```bash
# 清理构建缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 重新签名
codesign --force --deep --sign - build/Release/LinkLiar.app
```

#### 问题 3: 权限被拒绝

**症状**: 需要管理员权限但无法获取

**解决方案**:
```bash
# 确保 LinkDaemon 有正确的 entitlements
# 检查 LinkLiar.entitlements 文件
codesign -d --entitlements - build/Release/LinkLiar.app
```

---

## 📚 构建配置说明

### Xcode Scheme

项目包含 3 个 schemes：

1. **LinkLiar** - 主应用（GUI）
   - 包含菜单栏应用
   - 设置界面
   - 用户交互

2. **linkdaemon** - 后台守护进程
   - 需要 root 权限
   - 实际修改 MAC 地址
   - 与主应用通信

3. **LinkLiarTests** - 测试套件
   - 单元测试
   - 集成测试
   - 性能测试

### Build Configuration

| 配置 | 说明 | 优化 | 调试信息 |
|------|------|------|----------|
| **Debug** | 开发调试 | ❌ 无优化 | ✅ 完整 |
| **Release** | 发布版本 | ✅ 最大优化 | ⚠️ 有限 |
| **Profile** | 性能分析 | ✅ 适度优化 | ✅ 完整 |

---

## 🎯 下一步

构建完成后，你可以：

1. **运行应用**
   ```bash
   open build/Release/LinkLiar.app
   ```

2. **安装到系统**
   ```bash
   cp -R build/Release/LinkLiar.app /Applications/
   ```

3. **分享给他人**
   - 创建 DMG 镜像
   - 上传到 GitHub Releases
   - 提交到 Homebrew Cask

4. **提交代码**
   ```bash
   git add .
   git commit -m "Build: successful compile on macOS"
   git push
   ```

---

## 📖 参考资源

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Rust FFI Documentation](https://doc.rust-lang.org/nomicon/ffi.html)
- [macOS Code Signing Guide](https://developer.apple.com/support/code-signing/)

---

## 💡 提示

- 首次构建可能需要较长时间（下载依赖）
- 使用 `Cmd + Shift + K` 清理构建缓存
- 使用 `Cmd + B` 快速重新编译
- 遇到问题先查看 Xcode 的 Issue Navigator

---

**构建愉快！** 🎉
