# LinkLiar 构建故障排除指南

## 🚨 常见错误及解决方案

### 错误 1: "No signing certificate 'Mac Development' found"

**症状**:
```
error: No signing certificate "Mac Development" found: No "Mac Development" signing certificate matching team ID "B9J4QR64LK" with a private key was found.
```

**原因**: 项目配置了代码签名，但你的系统没有相应的签名证书。

**解决方案**:

#### 方案 A: 使用本地构建脚本（推荐）

```bash
cd /Users/yjq/Program/LinkLiar
./build-local.sh
```

这个脚本会：
- ✅ 禁用代码签名
- ✅ 使用 ad-hoc 签名
- ✅ 适用于本地开发

#### 方案 B: 在 Xcode 中禁用代码签名

1. 打开项目：
   ```bash
   open LinkLiar.xcodeproj
   ```

2. 在 Xcode 中：
   - 选择 `LinkLiar` target
   - 进入 `Signing & Capabilities` 标签
   - 取消勾选 `Automatically manage signing`
   - 将 `Signing Certificate` 设置为 `None`

3. 对 `linkdaemon` target 重复相同操作

4. 重新构建（`Cmd + B`）

#### 方案 C: 创建自签名证书

```bash
# 创建自签名证书
# 打开 Keychain Access
# 菜单: Keychain Access → Certificate Assistant → Create a Certificate
# 名称: Mac Development
# 类型: Code Signing
# 勾选: Let me override defaults
# 证书类型: Code Signing
# 有效期: 3650 天
```

---

### 错误 2: "xcodebuild requires Xcode"

**症状**:
```
xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance
```

**原因**: 系统使用命令行工具而不是完整 Xcode。

**解决方案**:

```bash
# 切换到 Xcode
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# 验证
xcodebuild -version
```

---

### 错误 3: Rust 库编译失败

**症状**:
```
error: linking with cc failed
```

**解决方案**:

```bash
cd linktools-rs

# 清理缓存
cargo clean

# 重新编译
cargo build --release
```

---

### 错误 4: 找不到 .app 文件

**症状**: 构建成功但找不到 LinkLiar.app

**解决方案**:

```bash
# 方法 1: 使用 find 查找
find ~/Library/Developer/Xcode/DerivedData -name "LinkLiar.app"

# 方法 2: 查看 Xcode Derived Data
open ~/Library/Developer/Xcode/DerivedData/

# 方法 3: 使用项目构建目录
ls -lh build/Release/LinkLiar.app
```

---

### 错误 5: 应用无法打开（无法验证开发者）

**症状**: 双击 .app 文件时提示无法验证开发者

**解决方案**:

```bash
# 方法 1: 右键点击 → 打开
# 或

# 方法 2: 允许任何来源
sudo spctl --master-disable

# 运行应用后恢复
sudo spctl --master-enable

# 方法 3: 移除隔离属性
xattr -cr /path/to/LinkLiar.app
```

---

### 错误 6: 权限被拒绝

**症状**: 应用需要 root 权限但无法获取

**解决方案**:

```bash
# 检查 entitlements
codesign -d --entitlements - LinkLiar.app

# 手动签名
codesign --force --deep --sign - LinkLiar.app
```

---

## 🔧 通用调试步骤

### 步骤 1: 清理所有缓存

```bash
# 清理 Xcode 缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/LinkLiar-*

# 清理 Rust 缓存
cd linktools-rs && cargo clean

# 清理项目
xcodebuild clean -project LinkLiar.xcodeproj -scheme LinkLiar
```

### 步骤 2: 检查环境

```bash
# 检查 Xcode
xcodebuild -version

# 检查 Rust
cargo --version

# 检查签名证书
security find-identity -v -p codesigning
```

### 步骤 3: 使用最简单的构建方式

```bash
# 方法 1: 使用 Xcode GUI
open LinkLiar.xcodeproj
# 然后在 Xcode 中：Product → Build (Cmd+B)

# 方法 2: 使用本地脚本
./build-local.sh
```

---

## 📋 构建方式对比

| 方式 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **Xcode GUI** | 最简单，可视化 | 需要手动操作 | 新手，调试 |
| **build-local.sh** | 自动化，无签名要求 | 不能分发 | 本地开发 |
| **build.sh** | 完整功能 | 需要签名证书 | 正式发布 |
| **xcodebuild** | 脚本化 | 配置复杂 | CI/CD |

---

## 🎯 推荐方案

### 对于本地开发测试

```bash
cd /Users/yjq/Program/LinkLiar
./build-local.sh
```

### 对于分发发布

1. 配置签名证书
2. 使用 Xcode GUI 构建
3. 或使用 `build.sh --package`

---

## 💡 预防措施

1. **首次构建前**：
   ```bash
   # 确认 Xcode 路径
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   ```

2. **定期清理**：
   ```bash
   # 每周清理一次
   rm -rf ~/Library/Developer/Xcode/DerivedData/LinkLiar-*
   ```

3. **使用 Git**：
   ```bash
   # 保持代码清洁
   git add .
   git commit -m "Build: successful compile"
   ```

---

## 📞 获取帮助

如果以上方案都无法解决问题：

1. 查看完整构建日志：
   ```bash
   ./build-local.sh 2>&1 | tee build.log
   ```

2. 检查系统日志：
   ```bash
   log show --predicate 'eventMessage contains "xcodebuild"' --last 1h
   ```

3. 查看 Xcode 设置：
   ```bash
   open /Applications/Xcode.app
   # Xcode → Settings → Locations
   ```

---

## ✅ 成功构建的标志

当你看到以下输出时，说明构建成功：

```
[INFO] =========================================
[INFO] 构建完成！🎉
[INFO] =========================================
[INFO] 应用位置: /path/to/LinkLiar.app
[INFO] 
[INFO] 运行应用:
[INFO]   open '/path/to/LinkLiar.app'
```

---

**现在试试运行 `./build-local.sh` 吧！** 🚀
