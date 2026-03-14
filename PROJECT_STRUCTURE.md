# LinkLiar 项目结构

本文档介绍项目中每个目录和文件的用途。

## 根目录

| 文件 | 说明 |
|------|------|
| `build.sh` | 主构建脚本（Rust + Xcode） |
| `CHANGELOG.md` | 版本历史和发布说明 |
| `LICENSE.txt` | MIT 许可证 |
| `README.md` | 项目概述和安装说明 |
| `PROJECT_STRUCTURE.md` | 本文档，项目结构说明 |
| `liblinktools.dylib` | Rust 编译的动态链接库（构建产物） |
| `.copywrite.hcl` | HashiCorp Copywrite 版权头配置 |
| `.gitattributes` | Git 属性配置 |
| `.gitignore` | Git 忽略规则 |
| `.swiftlint.yml` | SwiftLint 代码规范检查配置 |

---

## `bin/` - 开发脚本

| 文件 | 说明 |
|------|-------------|
| `copyright` | 使用 HashiCorp Copywrite 添加版权头 |
| `docs` | 生成帮助文档（Jekyll 构建） |
| `docserve` | 启动本地 Jekyll 服务器预览文档 |
| `logs` | 查看应用日志（带彩色输出） |
| `test` | 运行 Xcode 测试套件 |

---

## `docs/` - 生成的文档

由 Jekyll 从 `LinkLiarHelp/` 生成的静态 HTML 文档。

| 文件 | 说明 |
|------|-------------|
| `index.html` | 文档首页 |
| `installation.html` | 安装指南 |
| `usage.html` | 使用说明 |
| `settings.html` | 设置配置 |
| `development.html` | 开发指南 |
| `uninstall.html` | 卸载说明 |
| `application.css` | 文档样式 |

---

## `LinkLiar/` - SwiftUI 主应用

macOS 状态栏应用程序（图形界面）。

### 根目录文件

| 文件 | 说明 |
|------|-------------|
| `LinkLiarApp.swift` | SwiftUI 应用入口（`@main`） |
| `LinkLiar.entitlements` | 应用沙盒和安全权限配置 |
| `io.github.halo.LinkLiar.linkdaemon.plist` | LaunchDaemon 属性列表 |
| `oui.json` | OUI 到厂商的映射数据库 |

### `LinkLiar/Classes/` - 核心类

| 文件 | 说明 |
|------|-------------|
| `Controller.swift` | 应用控制器 - 守护进程注册、接口查询 |
| `LinkState.swift` | SwiftUI 可观察状态管理 |
| `JSONWriter.swift` | 将配置写入 JSON 文件 |
| `MACAddressFormatter.swift` | SwiftUI TextField 的 MAC 地址格式化器 |
| `Radio.swift` | 表示网络接口（Wi-Fi/以太网） |
| `CGKeyCode+optionKeyPressed.swift` | 键盘事件处理扩展 |

#### `LinkLiar/Classes/Config/`

| 文件 | 说明 |
|------|-------------|
| `Builder.swift` | 构建配置对象 |
| `Writer.swift` | 将配置写入磁盘 |

#### `LinkLiar/Classes/Backends/`

| 文件 | 说明 |
|------|-------------|
| `MACVendors.swift` | 厂商查询（纯 Swift，基于 oui.json） |
| `RustBindings/` | Rust FFI 函数的 Swift 封装 |

### `LinkLiar/Views/` - SwiftUI 视图

#### `LinkLiar/Views/Menu/`

| 文件 | 说明 |
|------|-------------|
| `MenuView.swift` | 主菜单栏下拉视图 |
| `InterfacesView.swift` | 网络接口列表 |
| `InterfaceView.swift` | 菜单中的单个接口行 |
| `ApplyRecommendationsView.swift` | 应用 MAC 推荐对话框 |
| `ApproveDaemonView.swift` | 守护进程批准提示 |
| `ConfirmQuittingView.swift` | 退出确认对话框 |
| `RegisterDaemonView.swift` | 向 macOS 注册守护进程 |

#### `LinkLiar/Views/Settings/`

| 文件 | 说明 |
|------|-------------|
| `SettingsView.swift` | 主设置窗口（NavigationSplitView 导航） |
| `SettingsDetailView.swift` | 设置详情面板（路由到各子页面） |
| `SettingsInterfaceHeadlineView.swift` | 接口区域标题 |
| `AccessPointsView.swift` | 已知 Wi-Fi 接入点列表 |
| `DiagnoseInterfaceView.swift` | 接口诊断视图 |
| `InterfacePrefixesView.swift` | 接口的厂商 OUI 前缀 |
| `PolicyActionView.swift` | MAC 操作策略选择器 |
| `PolicyDefaultOrCustomView.swift` | 默认或自定义 MAC 策略 |
| `PolicyHideOrIgnoreView.swift` | 隐藏或忽略接口策略 |
| `PolicyIgnoreOrDefaultView.swift` | 忽略或使用默认策略 |

#### `LinkLiar/Views/Settings/Sections/`

| 文件 | 说明 |
|------|-------------|
| `CommunityView.swift` | 社区和帮助链接 |
| `FallbackPolicyView.swift` | 默认/回退策略设置 |
| `FaqView.swift` | 常见问题解答 |
| `InterfacePolicyView.swift` | 接口策略设置 |
| `PreferencesView.swift` | 应用偏好设置 |
| `TroubleshootView.swift` | 故障排除指南 |
| `UninstallView.swift` | 卸载说明 |
| `VendorsView.swift` | 厂商数据库信息 |
| `WelcomeView.swift` | 欢迎页面 |

### `LinkLiar/Assets.xcassets/`

Xcode 资源目录，包含应用图标和菜单栏图标。

---

## `LinkTools/` - Swift 共享库

GUI 应用和守护进程共用的代码。

### 根目录文件

| 文件 | 说明 |
|------|-------------|
| `Command.swift` | Shell 命令执行封装 |
| `JSONReader.swift` | 读取和解析 JSON 配置 |
| `ListenerProtocol.swift` | 守护进程通信协议 |
| `Log.swift` | 日志工具 |

### `LinkTools/Backends/`

| 文件 | 说明 |
|------|-------------|
| `Ifconfig.Reader.swift` | 使用 ifconfig 读取接口信息 |
| `Interfaces.swift` | 网络接口枚举 |
| `LocationManager.swift` | macOS 定位服务集成 |
| `PopularOUIs.swift` | 热门 OUI 前缀查询 |
| `PopularVendors.swift` | 热门厂商列表 |
| `PopularVendorsDatabase.swift` | 热门厂商数据库 |

### `LinkTools/Config/`

| 文件 | 说明 |
|------|-------------|
| `AccessPointPolicy.swift` | 每个接入点的 MAC 策略 |
| `Arbiter.swift` | 根据策略决定使用哪个 MAC |
| `General.swift` | 通用应用设置 |
| `OUIs.swift` | OUI 前缀管理 |
| `Policy.swift` | MAC 地址策略定义 |
| `Reader.swift` | 从磁盘读取配置 |
| `Vendors.swift` | 厂商信息 |

### `LinkTools/Constants/`

| 文件 | 说明 |
|------|-------------|
| `Identifiers.swift` | Bundle ID 和守护进程标识符 |
| `Notifications.swift` | 通知名称常量 |
| `Paths.swift` | 配置、日志等文件路径 |
| `Stage.swift` | 开发/生产环境检测 |
| `Urls.swift` | 帮助、支持等 URL |

### `LinkTools/Extensions/`

| 文件 | 说明 |
|------|-------------|
| `CFArray+Sequence.swift` | 使 CFArray 可迭代 |
| `Collection+safeSubscript.swift` | 安全数组下标（返回 nil 而非崩溃） |

### `LinkTools/Models/`

| 文件 | 说明 |
|------|-------------|
| `AccessPoint.swift` | Wi-Fi 接入点模型 |
| `BSD.swift` | BSD 接口名表示 |
| `BSSID.swift` | BSSID（接入点 MAC）模型 |
| `Interface.swift` | 网络接口模型 |
| `MAC.swift` | MAC 地址模型 |
| `MACParser.swift` | 从字符串解析 MAC 地址 |
| `OUI.swift` | OUI 前缀模型 |
| `SSID.swift` | Wi-Fi 网络名模型 |
| `Vendor.swift` | 厂商/制造商模型 |
| `Version.swift` | 应用版本处理 |

### `LinkTools/Observers/`

| 文件 | 说明 |
|------|-------------|
| `FileObserver.swift` | 监听文件变更（配置文件） |
| `NetworkObserver.swift` | 监听网络接口变更 |
| `TimeObserver.swift` | 定时器，用于计划任务 |

---

## `linkdaemon/` - 特权守护进程

以 root 权限运行，用于修改 MAC 地址（需要提升权限）。

### 根目录文件

| 文件 | 说明 |
|------|-------------|
| `main.swift` | 守护进程入口 |
| `LinkDaemon.swift` | 主守护进程类 |
| `linkdaemon.entitlements` | 守护进程安全权限 |

### `linkdaemon/Classes/`

| 文件 | 说明 |
|------|-------------|
| `Advisor.swift` | 根据策略推荐 MAC 地址 |
| `ConfigDirectory.swift` | 监听配置目录变更 |
| `Executor.swift` | 执行 MAC 地址修改 |
| `Ifconfig.Setter.swift` | 使用 ifconfig 命令设置 MAC |
| `Listener.swift` | 监听 GUI 应用命令 |
| `Synchronization.swift` | 与 GUI 应用同步状态 |
| `WifiState.swift` | 监控 Wi-Fi 连接状态 |

### `linkdaemon/Classes/Backends/`

| 文件 | 说明 |
|------|-------------|
| `Airport.Scanner.swift` | 使用 airport 工具扫描 Wi-Fi 网络 |

---

## `linktools-rs/` - Rust 核心库

高性能 MAC 地址操作，通过 FFI 暴露给 Swift。

### 根目录文件

| 文件 | 说明 |
|------|-------------|
| `Cargo.toml` | Rust 包清单 |
| `README.md` | Rust 库文档 |
| `demo.sh` | 测试演示脚本 |

### `linktools-rs/src/`

| 文件 | 说明 |
|------|-------------|
| `lib.rs` | 库入口，公开导出 |
| `mac.rs` | MAC 地址解析、格式化、生成 |
| `oui.rs` | OUI（MAC 前 3 字节）处理 |
| `vendor.rs` | 厂商数据库和查询 |
| `config.rs` | 配置管理 |
| `ffi.rs` | C FFI 接口，供 Swift 调用 |

---

## `LinkLiarTests/` - 单元测试

| 文件 | 说明 |
|------|-------------|
| `LinkLiarTests.swift` | 测试套件设置 |
| `AdvisorTests.swift` | MAC 推荐逻辑测试 |
| `ConfigTests.swift` | 配置解析测试 |
| `ConfigBuilderTests.swift` | 配置构建器测试 |
| `ConfigurationPolicyTests.swift` | 策略决策测试 |
| `InterfaceTest.swift` | 接口模型测试 |
| `MACTest.swift` | MAC 地址模型测试 |
| `MACParserTest.swift` | MAC 解析测试 |
| `MACVendorsTest.swift` | 厂商查询测试 |
| `PathsTests.swift` | 文件路径测试 |
| `PopularVendorsTests.swift` | 厂商数据库测试 |
| `RustComparisonTest.swift` | Rust 与 Swift 实现对比 |
| `RustIntegrationTests.swift` | Rust FFI 测试 |
| `StageTests.swift` | 环境检测测试 |
| `AirportConnectionTests.swift` | Wi-Fi 检测测试 |
| `AirportScannerTests.swift` | 网络扫描测试 |
| `BSDTest.swift` | BSD 接口名测试 |

---

## `LinkLiarUITests/` - UI 测试

| 文件 | 说明 |
|------|-------------|
| `LinkLiarUITests.swift` | UI 测试用例 |
| `LinkLiarUITestsLaunchTests.swift` | 应用启动性能测试 |

---

## `LinkLiarHelp/` - 帮助文档源码

用于生成 macOS 帮助书的 Jekyll 源码。

| 目录 | 说明 |
|-----------|-------------|
| `_config.yml` | Jekyll 配置 |
| `_layouts/` | HTML 布局模板 |
| `_includes/` | 可复用 HTML 组件 |
| `_sass/` | SCSS 样式表 |
| `en.lproj/` | 英文本地化 |
| `_site/` | 生成的 HTML 输出 |

---

## `LinkLiar.xcodeproj/` - Xcode 工程

| 文件 | 说明 |
|------|-------------|
| `project.pbxproj` | Xcode 工程配置 |
| `xcshareddata/` | CI 共享 scheme |
| `project.xcworkspace/` | Xcode 工作区 |

---

## `.github/workflows/` - CI/CD

| 文件 | 说明 |
|------|-------------|
| `tests.yml` | GitHub Actions 工作流，运行 Rust 和 Xcode 测试 |

---

## 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                     LinkLiar (SwiftUI)                      │
│                   状态栏菜单 + 设置窗口                       │
└─────────────────────────┬───────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  LinkTools  │   │ linktools-rs│   │  linkdaemon │
│   (Swift)   │   │   (Rust)    │   │   (root)    │
│   共享库    │    │ MAC操作 FFI │   │  MAC 修改   │
└─────────────┘   └─────────────┘   └─────────────┘
```
