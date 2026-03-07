# 快速开始：在 LinkLiar 中使用 Rust

## 🚀 快速集成

### 步骤 1: 构建 Rust 库

```bash
cd linktools-rs
./integrate.sh
```

### 步骤 2: 在 Xcode 中集成

1. **添加动态库:**
   - Xcode → File → Add Files to "LinkLiar"
   - 选择: `linktools-rs/target/release/liblinktools.dylib`
   - 勾选 "Copy items into destination group's folder"

2. **添加到 Copy Files Build Phase:**
   - Build Phases → Copy Files
   - 添加 `liblinktools.dylib`
   - Destination: `Frameworks`

3. **添加 Header Search Path:**
   - Build Settings → Search Paths → Header Search Paths
   - 添加: `$(SRCROOT)/LinkLiar/Classes/Backends/RustBindings`

4. **链接库:**
   - Build Phases → Link Binary With Libraries
   - 添加: `liblinktools.dylib`

### 步骤 3: 在代码中使用

```swift
import Foundation

// 示例 1: 解析 MAC 地址
let macString = "00:03:93:12:34:56"
if let formatted = RustBridge.shared.parseMAC(macString) {
    print("格式化: \(formatted)")  // "00:03:93:12:34:56"
}

// 示例 2: 查找厂商
if let vendor = RustBridge.shared.lookupVendor(oui: "000393") {
    print("厂商: \(vendor)")  // "Apple"
}

// 示例 3: 生成随机 MAC
if let randomMac = RustBridge.shared.randomLocalMAC() {
    print("随机 MAC: \(randomMac)")
}

// 示例 4: 生成特定厂商的 MAC
if let appleMac = RustBridge.shared.randomMAC(forVendor: "apple") {
    print("Apple MAC: \(appleMac)")
}
```

## 📊 性能测试

运行测试查看性能对比：

```bash
cd linktools-rs
cargo bench
```

预期结果：
```
mac parse          time:   [150.00 ns]
oui lookup         time:   [60.00 ns]
random local mac   time:   [80.00 ns]
random vendor mac  time:   [100.00 ns]
```

## 🧪 运行测试

```bash
cd linktools-rs
cargo test
```

## 📖 完整示例

查看 `LinkLiarTests/RustComparisonTest.swift` 获取完整的使用示例。

## 🔧 故障排除

### 问题：找不到库文件
```
dyld: Library not loaded: @rpath/liblinktools.dylib
```
**解决方案：** 确保 `liblinktools.dylib` 在 "Copy Files" build phase 中

### 问题：符号未定义
```
Undefined symbols: "_mac_parse"
```
**解决方案：** 
1. 确保 `linktools.h` 在 Header Search Paths 中
2. 确保 `RustBridge.swift` 已添加到项目

### 问题：运行测试时崩溃
**解决方案：** 确保库文件在测试 target 中也被链接

## 🎯 下一步

1. **性能优化：** 运行 `cargo bench` 查看性能数据
2. **错误处理：** 在 Swift 中添加更好的错误处理
3. **单元测试：** 为 Rust 函数添加 Swift 单元测试
4. **CI/CD：** 在持续集成中添加 Rust 构建步骤

## 📚 更多资源

- [Rust FFI Guide](https://doc.rust-lang.org/nomicon/ffi.html)
- [Swift and C Interop](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/importing_c_functionality)
- [USAGE.md](linktools-rs/USAGE.md) - 详细使用指南
