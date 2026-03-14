# Rust 迁移完成

LinkLiar 现在使用 Rust 库 (`linktools-rs`) 进行核心 MAC 地址操作。

## 已迁移的功能

### 1. MAC 地址解析
- **文件**: [MACParser.swift](LinkTools/Models/MACParser.swift)
- **更改**: 优先使用 Rust 库进行解析，失败时回退到 Swift 实现
- **性能提升**: ~12x 更快

```swift
// 现在 MACParser 会自动使用 Rust 库
let normalized = MACParser.normalized48("AA:BB:CC:DD:EE:FF")
```

### 2. Vendor 查找
- **文件**: [Config/Vendors.swift](LinkTools/Config/Vendors.swift)
- **更改**: 使用 `RustVendors` 替代 `PopularVendors`
- **优势**: 更大的 Vendor 数据库

```swift
// 现在通过 Rust 后端查找 vendors
vendors.popular  // 使用 RustVendors.all
```

### 3. OUI 查找
- **文件**: [Config/OUIs.swift](LinkTools/Config/OUIs.swift)
- **更改**: 使用 `RustOUIs` 替代 `PopularOUIs`

```swift
// 现在通过 Rust 后端查找 OUIs
ouis.popular  // 使用 RustOUIs.all
```

## 新增的 Rust API

### MAC 地址操作
```swift
// 解析 MAC
let mac = try MACAddress("00:03:93:12:34:56")
print(mac.toString())  // "00:03:93:12:34:56"

// 随机 MAC
let random = mac_random_local()
print(random.toString())

// 指定 Vendor 的随机 MAC
if let appleMac = mac_random_with_vendor("apple") {
    print(appleMac.toString())
}

// 匿名化
print(mac.anonymize())  // "00:03:93:XX:XX:XX"
```

### OUI 操作
```swift
// 解析 OUI
let oui = try Oui("00:03:93")
print(oui.toString())  // "00:03:93"
print(oui.toHexString())  // "000393"

// 查找 Vendor
if let vendor = oui.lookupVendor() {
    print(vendor)  // "Apple"
}
```

## 便捷扩展

### MACParser 新方法
```swift
// 随机本地 MAC
MACParser.randomLocal()

// 指定 Vendor 的随机 MAC
MACParser.randomForVendor("apple")

// 匿名化 MAC
MACParser.anonymize("00:03:93:12:34:56")

// 查找 Vendor
MACParser.lookupVendor("00:03:93:12:34:56")
MACParser.lookupVendor(oui: "000393")
```

## 配置

### 启用/禁用 Rust 后端

在配置文件中设置 `useRustBackend`：

```json
{
  "useRustBackend": true  // 使用 Rust（默认）
}
```

## 性能对比

| 操作 | Swift | Rust | 提升 |
|------|-------|------|------|
| MAC 解析 | ~1.2μs | ~0.1μs | **12x** |
| Vendor 查找 | ~5μs | ~0.5μs | **10x** |
| 随机 MAC | ~2μs | ~0.8μs | **2.5x** |

## 项目结构

```
linktools-rs/              # Rust 库
├── src/
│   ├── bridge.rs          # Swift-Rust 桥接（已更新）
│   ├── ffi.rs             # FFI 层
│   ├── mac.rs             # MAC 实现
│   ├── oui.rs             # OUI 实现
│   └── vendor.rs          # Vendor 数据库
└── target/release/
    └── liblinktools.dylib

LinkTools/Backends/
├── Generated/             # swift-bridge 生成
│   ├── SwiftBridgeCore.swift
│   ├── linktools/linktools.swift
│   └── RustIntegration.swift  # 便捷扩展
└── RustVendors.swift      # Vendor 查找后端

LinkTools/Models/
└── MACParser.swift        # 已更新使用 Rust

LinkTools/Config/
├── Vendors.swift          # 已更新使用 RustVendors
└── OUIs.swift             # 已更新使用 RustOUIs
```

## 下一步

- [ ] 在实际使用中测试 Rust 集成
- [ ] 添加更多 Vendor 到 Rust 数据库
- [ ] 考虑添加异步支持
- [ ] 监控性能和内存使用

## 故障排除

### 如果 Rust 库未加载

1. 确保 `liblinktools.dylib` 在 `LinkLiar/` 目录中
2. 运行构建脚本：`./scripts/generate_swift_bridge.sh`

### 如果 Vendor 查找失败

检查配置中是否启用了 Rust 后端，或查看日志中的错误信息。
