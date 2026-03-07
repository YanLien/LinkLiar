# LinkLiar 构建脚本使用指南

## 🎉 新功能：支持打包！

`build-local.sh` 现在支持将应用打包成 DMG 镜像和 ZIP 压缩包！

---

## 📋 使用方法

### 基本构建

```bash
# 构建 Debug 版本
./build-local.sh

# 构建 Release 版本
./build-local.sh --release
```

### 构建并打包

```bash
# 构建 Debug 版本并打包
./build-local.sh --package

# 构建 Release 版本并打包
./build-local.sh --release --package

# 简写形式
./build-local.sh -p
./build-local.sh -r -p
```

### 查看帮助

```bash
./build-local.sh --help
```

---

## 📦 打包输出

### 文件位置

所有构建产物都保存在项目目录中：

```
LinkLiar/
├── build/
│   ├── Debug/           # Debug 版本
│   │   └── LinkLiar.app
│   ├── Release/         # Release 版本
│   │   └── LinkLiar.app
│   ├── LinkLiar-<version>-<date>-Debug.dmg
│   ├── LinkLiar-<version>-<date>-Debug.zip
│   ├── LinkLiar-<version>-<date>-Release.dmg
│   └── LinkLiar-<version>-<date>-Release.zip
```

### 文件命名格式

```
LinkLiar-<版本号>-<日期>-<构建类型>.<扩展名>

示例：
LinkLiar-dev-20260307-Debug.dmg
LinkLiar-dev-20260307-Debug.zip
LinkLiar-dev-20260307-Release.dmg
LinkLiar-dev-20260307-Release.zip
```

---

## 🚀 快速示例

### 场景 1: 本地开发测试

```bash
# 快速构建并运行
./build-local.sh
open build/Debug/LinkLiar.app
```

### 场景 2: 分发给朋友测试

```bash
# 构建并打包成易于分发的格式
./build-local.sh --package

# 分发 DMG 镜像（推荐）
open build/LinkLiar-*.dmg

# 或分发 ZIP 压缩包
# build/LinkLiar-*.zip
```

### 场景 3: 发布测试版本

```bash
# 构建 Release 版本（优化编译）并打包
./build-local.sh --release --package

# 查看打包文件
ls -lh build/*.dmg build/*.zip

# 在 Finder 中查看
open build/
```

---

## 📊 输出示例

### 构建输出

```
[INFO] LinkLiar 本地构建脚本（无代码签名）
[INFO] 构建类型: Debug
[INFO] ✓ Xcode: /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild

[STEP] 1/6: 检查 Rust 库...
[INFO] ✓ Rust 库就绪

[STEP] 2/6: 复制 Rust 库...
[INFO] ✓ 库文件已复制

[STEP] 3/6: 清理旧的构建...
[INFO] ✓ 清理完成

[STEP] 4/6: 构建 Xcode 项目（无代码签名）...
[WARN] 注意: 本地构建不进行代码签名，仅用于开发测试
[INFO] ✓ Xcode 构建成功

[STEP] 5/6: 复制应用到项目目录...
[INFO] ✓ 构建目录: /Users/yjq/Program/LinkLiar/build/Debug
[INFO] ✓ 应用已复制到: build/Debug/LinkLiar.app
[INFO] ✓ 应用大小: 4.2M

[STEP] 6/6: 打包应用...
[INFO] 创建 DMG 镜像...
[INFO] ✓ DMG 镜像创建成功: LinkLiar-dev-20260307-Debug.dmg (3.8M)
[INFO]   位置: /Users/yjq/Program/LinkLiar/build/LinkLiar-dev-20260307-Debug.dmg
[INFO] 创建 ZIP 压缩包...
[INFO] ✓ ZIP 压缩包创建成功: LinkLiar-dev-20260307-Debug.zip (3.6M)
[INFO]   位置: /Users/yjq/Program/LinkLiar/build/LinkLiar-dev-20260307-Debug.zip

=========================================
构建完成！🎉
=========================================
应用位置: build/Debug/LinkLiar.app

打包文件:
  DMG:  build/LinkLiar-dev-20260307-Debug.dmg
  ZIP:  build/LinkLiar-dev-20260307-Debug.zip

运行应用:
  open 'build/Debug/LinkLiar.app'

在 Finder 中查看:
  open 'build/'

注意: 这是未签名的开发版本，可能需要在系统设置中允许运行
```

---

## 🎯 使用建议

### 日常开发

```bash
# 快速迭代
./build-local.sh
```

### 版本测试

```bash
# 发布候选版本
./build-local.sh --release
```

### 分享给他人

```bash
# 创建可分发的包
./build-local.sh --package

# 选择分发方式：
# - DMG: 适合 macOS 用户（双击挂载）
# - ZIP: 适合跨平台用户（解压即用）
```

---

## 📝 注意事项

### 关于代码签名

- ⚠️ 这些构建**未进行代码签名**
- ⚠️ macOS 可能会警告应用来自未知开发者
- ✅ 可以通过右键 → 打开来绕过
- ✅ 或在系统设置中允许运行

### 关于分发

- ❌ 不要分发给不认识的他人（安全风险）
- ✅ 可以用于团队内部测试
- ✅ 可以用于个人使用
- ✅ 公开发布需要配置代码签名证书

---

## 🔧 高级用法

### 只构建不打包

```bash
# 快速构建
./build-local.sh

# 构建后手动打包
cd build/Debug
hdiutil create -volname "LinkLiar" \
  -srcfolder LinkLiar.app \
  -ov -format UDZO \
  LinkLiar.dmg
```

### 自定义版本号

```bash
# 设置 Git 标签
git tag v1.0.0

# 构建会自动使用标签号
./build-local.sh --package
```

### 清理构建缓存

```bash
# 清理项目构建
rm -rf build/

# 清理 Xcode 缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/LinkLiar-*

# 清理 Rust 缓存
cd linktools-rs && cargo clean
```

---

## 📚 相关文档

- **[BUILD_GUIDE.md](BUILD_GUIDE.md)** - 完整的构建文档
- **[QUICKSTART.md](QUICKSTART.md)** - 快速开始指南
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - 故障排除

---

## 💡 提示

1. **首次构建**: 运行 `./build-local.sh`（自动编译 Rust 库）
2. **后续构建**: 直接运行 `./build-local.sh`（使用缓存的库）
3. **分发版本**: 运行 `./build-local.sh --package`
4. **查看文件**: 运行 `open build/` 在 Finder 中查看

---

**开始构建吧！** 🚀
