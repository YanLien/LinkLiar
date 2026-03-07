# LinkLiar 开发文档

## 项目概述

LinkLiar 是一个开源的 macOS 状态栏应用程序，使用 Swift 编写，主要功能是帮助用户欺骗 Wi-Fi 和以太网网卡的 MAC 地址（MAC 地址伪装/随机化），防止用户的 MAC 地址被网络服务提供商或其他实体追踪。

## 目录

- [技术栈](#技术栈)
- [架构设计](#架构设计)
- [核心模块](#核心模块)
- [数据模型](#数据模型)
- [配置系统](#配置系统)
- [观察者模式](#观察者模式)
- [开发指南](#开发指南)

---

## 技术栈

### 编程语言
- **Swift 5.x** - 主要开发语言

### 框架和库
| 框架 | 用途 |
|------|------|
| SwiftUI | 现代声明式 UI 框架，用于用户界面 |
| Foundation | 基础框架，提供核心功能 |
| CoreWLAN | Wi-Fi 接口管理 |
| ServiceManagement | 管理守护进程服务 |
| OSLog | 系统日志记录 |

### 开发工具
- **Xcode** - 集成开发环境
- **SwiftLint** - 代码风格检查

---

## 架构设计

```
LinkLiar/
├── LinkLiar/              # 主应用程序 (GUI)
│   ├── LinkLiarApp.swift  # 应用入口
│   ├── Classes/
│   │   ├── Controller.swift       # 主控制器
│   │   └── LinkState.swift        # 状态管理
│   └── Views/
│       ├── Menu/          # 菜单栏视图
│       └── Settings/      # 设置窗口视图
│
├── linkdaemon/            # 后台守护进程
│   ├── LinkDaemon.swift   # 守护进程主类
│   ├── main.swift         # 入口点
│   └── Classes/           # 守护进程类
│
└── LinkTools/             # 共享工具库
    ├── Models/            # 数据模型
    ├── Config/            # 配置管理
    ├── Backends/          # 后端实现
    ├── Observers/         # 观察者模式
    └── Constants/         # 常量定义
```

### 架构原则

1. **关注点分离** - GUI 应用、守护进程、共享工具库分离
2. **模块化设计** - 清晰的功能模块划分
3. **观察者模式** - 响应系统事件和配置变化
4. **配置驱动** - 通过 JSON 配置文件控制行为

---

## 核心模块

### 1. LinkLiarApp (主应用)

[LinkLiarApp.swift](LinkLiar/LinkLiarApp.swift) 是应用程序的入口点。

```swift
@main
struct LinkLiarApp: App {
  @State private var state = LinkState()

  init() {
    // 订阅配置文件变化
    configFileObserver = FileObserver(path: Paths.configFile, callback: configFileChanged)

    // 订阅网络接口变化
    networkObserver = NetworkObserver(callback: networkConditionsChanged)

    // 订阅菜单栏显示事件
    NotificationCenter.default.addObserver(
      forName: .menuBarAppeared, object: nil, queue: nil, using: menuBarAppeared
    )
  }
}
```

**主要职责：**
- 启动时初始化观察者
- 管理应用状态 (`LinkState`)
- 提供菜单栏和设置窗口界面
- 注册守护进程（如果配置为受限模式）

### 2. LinkDaemon (守护进程)

[LinkDaemon.swift](linkdaemon/LinkDaemon.swift) 是后台守护进程，以 root 权限运行。

```swift
class LinkDaemon {
  init() {
    Log.debug("Daemon \(version.formatted) says hello")
    subscribe()
    RunLoop.main.run()
  }

  private func subscribe() {
    // 监控配置文件
    configFileObserver = FileObserver(path: Paths.configFile, callback: configFileChanged)

    // 监控定时器
    intervalTimer = IntervalTimer(callback: intervalElapsed)

    // 监控网络变化
    networkObserver = NetworkObserver(callback: networkConditionsChanged)

    // 监控系统事件
    NSWorkspace.shared.notificationCenter.addObserver(...)
  }
}
```

**主要职责：**
- 以 root 权限执行 MAC 地址修改
- 响应系统事件（休眠、唤醒、关机）
- 定期检查并重新随机化 MAC 地址
- 监控配置文件和网络变化

### 3. Controller (控制器)

[Controller.swift](LinkLiar/Classes/Controller.swift) 是应用的业务逻辑控制器。

**主要职责：**
- 协调 GUI 和守护进程之间的通信
- 查询网络接口状态
- 管理 MAC 地址操作

---

## 数据模型

### Interface (网络接口)

[Interface.swift](LinkTools/Models/Interface.swift) 表示本地网络接口（Wi-Fi、以太网等）。

```swift
@Observable
class Interface: Identifiable {
  let bsd: BSD              // BSD 设备名称 (如 en0)
  let hardMAC: MAC          // 硬件 MAC 地址
  let kind: String          // 接口类型 (Ethernet, IEEE80211)
  var softMAC: MAC?         // 当前软 MAC 地址

  var isSpoofable: Bool {
    // 判断接口是否可伪造 MAC 地址
  }

  var isWifi: Bool {
    // 判断是否为 Wi-Fi 接口
  }
}
```

**支持的接口动作：**
| 动作 | 说明 |
|------|------|
| `hide` | 隐藏接口 |
| `ignore` | 忽略接口 |
| `random` | 使用随机 MAC 地址 |
| `specify` | 使用指定 MAC 地址 |
| `original` | 使用原始硬件 MAC 地址 |

### MAC (MAC 地址)

[MAC.swift](LinkTools/Models/MAC.swift) 表示 MAC 地址。

```swift
struct MAC: Equatable {
  let address: String  // 格式化的 MAC 地址 (xx:xx:xx:xx:xx:xx)

  var prefix: String {
    // 获取 OUI 前缀 (前 3 字节)
  }

  var integers: [UInt8] {
    // 转换为字节数组
  }

  func anonymous(_ anonymize: Bool) -> String {
    // 可选的匿名化显示
  }
}
```

### 其他模型

| 模型 | 文件 | 说明 |
|------|------|------|
| BSD | [BSD.swift](LinkTools/Models/BSD.swift) | BSD 设备名称封装 |
| BSSID | [BSSID.swift](LinkTools/Models/BSSID.swift) | 基站标识符 |
| SSID | [SSID.swift](LinkTools/Models/SSID.swift) | Wi-Fi 网络名称 |
| OUI | [OUI.swift](LinkTools/Models/OUI.swift) | 组织唯一标识符 |
| Vendor | [Vendor.swift](LinkTools/Models/Vendor.swift) | 硬件厂商信息 |
| Version | [Version.swift](LinkTools/Models/Version.swift) | 版本号 |

---

## 配置系统

### 配置文件结构

配置文件位于 `/Library/Application Support/LinkLiar/config.json`：

```json
{
  "version": 4,
  "general": {
    " restricted_daemon": false,
    "randomize_timer_seconds": 0
  },
  "aa:bb:cc:dd:ee:ff": {
    "action": "random",
    "address": "02:00:00:00:00:00",
    "except": "02:00:00:00:00:00",
    "ssids": {
      "My WiFi": "11:22:33:44:55:66"
    }
  }
}
```

### Config.Policy (接口策略)

[Config/Policy.swift](LinkTools/Config/Policy.swift) 提供接口配置查询：

```swift
extension Config {
  struct Policy {
    var action: Interface.Action?     // 获取动作
    var address: MAC?                 // 获取指定地址
    var exceptionAddress: MAC?        // 获取例外地址
    var accessPoints: [AccessPointPolicy]  // 获取接入点策略
  }
}
```

### 配置键 (Config.Key)

| 键 | 说明 |
|------|------|
| `action` | 接口动作 |
| `address` | 指定 MAC 地址 |
| `except` | 例外 MAC 地址 |
| `ssids` | SSID 策略映射 |

---

## 观察者模式

LinkLiar 使用观察者模式响应各种系统事件。

### FileObserver (文件观察者)

[FileObserver.swift](LinkTools/Observers/FileObserver.swift) 监控配置文件变化。

```swift
class FileObserver {
  init(path: String, callback: @escaping () -> Void)
}
```

### NetworkObserver (网络观察者)

[NetworkObserver.swift](LinkTools/Observers/NetworkObserver.swift) 监控网络接口变化。

```swift
class NetworkObserver {
  init(callback: @escaping () -> Void)
}
```

### TimeObserver (时间观察者)

[TimeObserver.swift](LinkTools/Observers/TimeObserver.swift) 定时触发事件。

```swift
class TimeObserver {
  init(seconds: Int, callback: @escaping () -> Void)
}
```

### 系统通知

| 通知 | 触发条件 |
|------|----------|
| `NSWorkspace.willPowerOffNotification` | 系统关机 |
| `NSWorkspace.willSleepNotification` | 系统休眠 |
| `NSWorkspace.didWakeNotification` | 系统唤醒 |
| `.menuBarAppeared` | 菜单栏显示 |
| `.manualTrigger` | 手动触发查询 |

---

## 开发指南

### 环境设置

1. 克隆仓库：
```bash
git clone https://github.com/halo/LinkLiar.git
cd LinkLiar
```

2. 使用 Xcode 打开项目：
```bash
open LinkLiar.xcodeproj
```

### 构建

```bash
# 构建所有 target
xcodebuild -project LinkLiar.xcodeproj -scheme LinkLiar build

# 或使用 Xcode 的快捷键 Cmd+B
```

### 测试

```bash
# 运行测试
xcodebuild test -scheme LinkLiar
```

### 调试

创建日志文件以启用调试：
```bash
touch "/Library/Application Support/LinkLiar/linkliar.log"
```

查看实时日志：
```bash
/Applications/LinkLiar.app/Contents/Resources/logs
```

### 代码风格

项目使用 SwiftLint 进行代码检查：
```bash
swiftlint lint
```

### 更新帮助文档

1. 编辑 [LinkLiarHelp/en.lproj/](LinkLiarHelp/en.lproj/) 中的源文件
2. 运行 `bin/docs` 生成输出

---

## 常量和路径

### 重要路径

| 路径 | 说明 |
|------|------|
| `/Library/Application Support/LinkLiar/` | 配置目录 |
| `/Library/Application Support/LinkLiar/config.json` | 配置文件 |
| `/Library/Application Support/LinkLiar/linkliar.log` | 日志文件 |
| `/Library/PrivilegedHelperTools/com.github.halo.LinkLiar.linkdaemon` | 守护进程 |

### 通知标识符

```swift
extension Notification.Name {
  static let menuBarAppeared = Notification.Name("menuBarAppeared")
  static let manualTrigger = Notification.Name("manualTrigger")
}
```

---

## 已知限制

1. Wi-Fi 关闭时无法更改 MAC 地址
2. 更改 MAC 地址会短暂断开网络连接
3. 2018 年 MacBook 因 macOS bug 无法更改 MAC 地址
4. macOS 12.3+ 需要先断开网络才能修改 MAC 地址

---

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 许可证

MIT License - 详见 [LICENSE.txt](LICENSE.txt)

---

## 核心实现原理

### 1. 修改 MAC 地址的实现

LinkLiar 通过调用 macOS 系统命令 `ifconfig` 来修改网络接口的 MAC 地址。

#### 核心代码

[Ifconfig.Setter.swift](linkdaemon/Classes/Ifconfig.Setter.swift) 是修改 MAC 地址的核心实现：

```swift
func setSoftMAC(_ mac: MAC) {
  let state = WifiState(BSDName)
  state.prepare()  // 断开 Wi-Fi 连接

  Log.info("Setting MAC address of Interface \(BSDName) to <\(mac.address)>...")
  // 核心命令：ifconfig en0 ether xx:xx:xx:xx:xx:xx
  let command = Command(Paths.ifconfigCLI, arguments: [BSDName, "ether", mac.address])
  _ = command.run()

  sleep(1)  // 等待变更生效
}
```

#### 实现步骤

1. **断开 Wi-Fi 连接** - 修改前必须先断开当前 Wi-Fi 连接，否则 `ifconfig` 会拒绝修改
   ```swift
   // WifiState.swift - 使用 CoreWLAN 框架
   interface.disassociate()
   ```

2. **执行 ifconfig 命令** - 使用系统命令设置新的 MAC 地址
   ```bash
   /sbin/ifconfig en0 ether 02:00:00:00:00:00
   ```

3. **等待生效** - 等待 1 秒让网络接口重新初始化

#### 关键路径

| 路径 | 说明 |
|------|------|
| `/sbin/ifconfig` | macOS 系统命令，用于配置网络接口 |

#### 读取当前 MAC 地址

[Ifconfig.Reader.swift](LinkTools/Backends/Ifconfig.Reader.swift) 通过解析 `ifconfig` 输出来获取当前 MAC 地址：

```swift
func softMAC() -> MAC? {
  // 执行 ifconfig en0 ether
  let command = Command.init(Paths.ifconfigCLI, arguments: [BSDName, "ether"])
  let output = command.run()
  // 解析输出中的 MAC 地址
  return parse(output)
}

private func parse(_ stdout: String) -> MAC? {
  // 从 "ether xx:xx:xx:xx:xx:xx" 中提取 MAC 地址
  guard let ether = stdout.components(separatedBy: "ether ").last else { return nil }
  guard let address = ether.components(separatedBy: " ").first else { return nil }
  return MAC(address)
}
```

### 2. 获取其他设备 MAC 地址的实现

LinkLiar 使用 macOS 内置的 `airport` CLI 工具扫描附近的 Wi-Fi 接入点。

#### 核心代码

[Airport.Scanner.swift](linkdaemon/Classes/Backends/Airport.Scanner.swift) 负责扫描 Wi-Fi 网络：

```swift
func accessPoints() -> [AccessPoint] {
  // 检查缓存（1 分钟内有效）
  if let cache = recall() {
    return cache
  }

  // 最多尝试 3 次扫描
  for attempt in (1...3) {
    if let foundAccessPoints = scan() {
      remember(foundAccessPoints)  // 缓存结果
      return foundAccessPoints
    }
    sleep(1)
  }
  return []
}

private func scan() -> [AccessPoint]? {
  // 执行 airport --scan --xml 获取 XML 格式输出
  let command = Command.init(Paths.airportCLI, arguments: ["--scan", "--xml"])
  let output = command.run()

  // 解析 XML 格式的结果
  let codableAccessPoints = try plistDecoder.decode([CodableAccessPoint].self, from: data)
  return codableAccessPoints.compactMap(\.toAccessPoint)
}
```

#### airport 命令

```bash
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport --scan --xml
```

输出示例（XML Property List 格式）：
```xml
<array>
  <dict>
    <key>BSSID</key>
    <string>aa:bb:cc:dd:ee:ff</string>  <!-- 接入点的 MAC 地址 -->
    <key>SSID</key>
    <string>MyWiFiNetwork</string>       <!-- 网络名称 -->
  </dict>
</array>
```

#### 关键路径

| 路径 | 说明 |
|------|------|
| `/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport` | macOS 私有框架中的 Wi-Fi 扫描工具 |

#### 扫描结果模型

```swift
struct CodableAccessPoint: Decodable {
  var bssid: String  // 接入点的 MAC 地址 (Base Station SSID)
  var ssid: String   // 网络名称 (Service Set Identifier)
}
```

#### 缓存机制

- 扫描结果会被缓存 60 秒
- 避免短时间内多次调用 `airport` 命令
- 扫描失败时会重试最多 3 次

### 3. 完整工作流程

```
┌─────────────────────────────────────────────────────────────┐
│                     LinkDaemon (root 权限)                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  1. 监控事件 (配置变化/网络变化/定时器/系统休眠唤醒)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Airport.Scanner 扫描附近 Wi-Fi (获取 BSSID/SSID)         │
│     └─> airport --scan --xml                                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Advisor 根据配置决定目标 MAC 地址                         │
│     - 根据 SSID 选择特定地址                                  │
│     - 或使用随机地址                                          │
│     - 或使用原始硬件地址                                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  4. WifiState.prepare() 断开当前 Wi-Fi 连接                   │
│     └─> CWInterface.disassociate()                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Ifconfig.Setter 执行 MAC 地址修改                         │
│     └─> ifconfig en0 ether xx:xx:xx:xx:xx:xx                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  6. 等待 1 秒后系统自动重连 Wi-Fi                              │
└─────────────────────────────────────────────────────────────┘
```

### 4. 权限要求

| 操作 | 权限要求 | 说明 |
|------|----------|------|
| 读取 MAC 地址 | 普通用户 | `ifconfig en0` 可被任何用户执行 |
| 修改 MAC 地址 | root 权限 | `ifconfig en0 ether xxx` 需要 root |
| 扫描 Wi-Fi | 普通用户 | `airport --scan` 可被任何用户执行 |

这也是为什么 LinkLiar 需要一个以 root 权限运行的守护进程 `linkdaemon`。

### 5. Vendor（厂商）功能实现

LinkLiar 支持根据硬件厂商生成看起来真实的随机 MAC 地址。这通过 **OUI (Organizationally Unique Identifier)** 数据库实现。

#### OUI 原理

MAC 地址的前 3 个字节（24 位）是 OUI，用于标识硬件厂商：

```
MAC 地址:     AA:BB:CC:DD:EE:FF
              ├───┤  ├───┤
              OUI    设备标识
             (厂商)   (NIC)
```

例如：
- `00:03:93` → Apple
- `00:00:0C` → Cisco
- `00:1A:11` → Google

#### 两种数据库

**1. 完整 OUI 数据库** - [oui.json](LinkLiar/oui.json)

```swift
// MACVendors.swift - 加载 OUI 数据库
struct MACVendors {
  private static var dictionary: [String: String] = [:]

  static func load() {
    // 异步加载 oui.json 文件
    DispatchQueue.global(qos: .background).async {
      guard let parsed = JSONReader(path).dictionary as? [String: String] else { return }
      self.dictionary = parsed
    }
  }

  static func name(_ oui: OUI) -> String {
    // 根据 OUI 前缀查找厂商名称
    return dictionary[oui.address] ?? "No Vendor"
  }
}
```

**数据格式示例：**
```json
{
  "000393": "Apple",
  "00000C": "Cisco",
  "001A11": "Google",
  ...
}
```

**2. 流行厂商数据库** - [PopularVendorsDatabase.swift](LinkTools/Backends/PopularVendorsDatabase.swift)

```swift
struct PopularVendorsDatabase {
  // 厂商 ID → [厂商名称: 前缀数量]
  static var dictionaryWithCounts: [String: [String: Int]] {
    [
      "apple": ["Apple": 1133],
      "cisco": ["Cisco": 1084],
      "huawei": ["Huawei": 1037],
      "samsung": ["Samsung": 755],
      "intel": ["Intel": 546],
      ...
    ]
  }

  // 厂商 ID → [厂商名称: OUI 前缀列表]
  static var dictionaryWithOUIs: [String: [String: [UInt32]]] {
    [
      "apple": ["Apple": [0x000393, 0x000502, 0x000A27, ...]],
      "cisco": ["Cisco": [0x00000C, 0x000142, 0x000143, ...]],
      ...
    ]
  }
}
```

#### 核心数据模型

**OUI** - [OUI.swift](LinkTools/Models/OUI.swift)

```swift
struct OUI: Equatable, Hashable {
  let address: String  // MAC 前缀 (如 "000393")

  init?(_ address: String) {
    guard let validAddress = MACParser.normalized24(address) else { return nil }
    self.address = validAddress
  }
}
```

**Vendor** - [Vendor.swift](LinkTools/Models/Vendor.swift)

```swift
class Vendor: Identifiable, Hashable {
  var id: String           // 厂商 ID (如 "apple")
  var name: String         // 厂商名称 (如 "Apple")
  var prefixes: [OUI]      // OUI 前缀列表
  var prefixCount: Int     // 前缀数量

  var title: String {
    [name, " ・ ", String(prefixes.count)].joined()  // "Apple ・ 1133"
  }
}
```

#### 查找厂商

**PopularVendors.swift** - [PopularVendors.swift](LinkTools/Backends/PopularVendors.swift)

```swift
struct PopularVendors {
  // 根据 ID 查找厂商
  static func find(_ id: String) -> Vendor? {
    let id = id.filter("0123456789abcdefghijklmnopqrstuvwxyz".contains)
    guard let vendorData = PopularVendorsDatabase.dictionaryWithCounts[id] else { return nil }

    guard let name = vendorData.keys.first else { return nil }
    guard let rawPrefixCount = vendorData.values.first else { return nil }

    return Vendor(id: id, name: name, prefixCount: rawPrefixCount)
  }

  // 获取所有流行厂商
  static var all: [Vendor] {
    PopularVendorsDatabase.dictionaryWithCounts.keys.reversed().compactMap {
      find($0)
    }.sorted()
  }
}
```

#### 使用场景

1. **生成特定厂商的随机 MAC 地址**
   ```swift
   // 用户选择 "Apple" 厂商
   let vendor = PopularVendors.find("apple")
   // 从 Apple 的 OUI 列表中随机选择一个前缀
   let randomOUI = vendor.prefixes.randomElement()
   // 生成完整的 MAC 地址: AA:BB:CC:XX:XX:XX
   ```

2. **识别 MAC 地址的厂商**
   ```swift
   // 从 MAC 地址提取 OUI
   let mac = MAC("00:03:93:12:34:56")
   let oui = OUI(mac.prefix)  // "000393"
   // 查找厂商
   let vendorName = MACVendors.name(oui)  // "Apple"
   ```

3. **在设置界面选择厂商**
   ```swift
   // Config/Vendors.swift
   struct Config.Vendors {
     var popular: [Vendor] {
       PopularVendors.all  // 返回所有流行厂商列表
     }

     func isChosen(_ vendor: Vendor) -> Bool {
       // 检查用户是否选择了该厂商
     }
   }
   ```

#### 预定义的流行厂商

| 厂商 ID | 名称 | OUI 前缀数量 |
|---------|------|-------------|
| apple | Apple | 1133 |
| cisco | Cisco | 1084 |
| huawei | Huawei | 1037 |
| samsung | Samsung | 755 |
| intel | Intel | 546 |
| xiaomi | Xiaomi | 163 |
| microsoft | Microsoft | 92 |
| google | Google | 72 |
| nintendo | Nintendo | 87 |
| sony | Sony | 82 |

完整列表见 [PopularVendorsDatabase.swift](LinkTools/Backends/PopularVendorsDatabase.swift)。

#### 数据更新

OUI 数据库可以通过运行 `bin/vendors` 脚本更新：

```bash
# 更新流行厂商数据库
./bin/vendors
```

这会从 IEEE 官方数据库下载最新的 OUI 数据并更新 `PopularVendorsDatabase.swift`。
