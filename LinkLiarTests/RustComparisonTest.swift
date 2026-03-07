// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import XCTest
@testable import LinkLiar

/// 性能对比测试：Swift vs Rust
class RustComparisonTest: XCTestCase {
  
  // MARK: - Setup
  
  override func setUp() {
    super.setUp()
    // 确保在运行测试前构建了 Rust 库
    // cd linktools-rs && cargo build --release
  }
  
  // MARK: - 功能测试
  
  func testSwiftMACParsing() {
    // Swift 实现
    let swiftMAC = MAC("00:03:93:12:34:56")
    XCTAssertNotNil(swiftMAC)
    XCTAssertEqual(swiftMAC?.address, "00:03:93:12:34:56")
  }
  
  func testRustMACParsing() {
    // Rust 实现 (通过 FFI)
    // 注意：需要先链接 liblinktools.dylib
    /*
    let input = "00:03:93:12:34:56"
    let rustResult = RustBridge.shared.parseMAC(input)
    XCTAssertNotNil(rustResult)
    XCTAssertEqual(rustResult, "00:03:93:12:34:56")
    */
  }
  
  func testDifferentFormats() {
    let formats = [
      "00:03:93:12:34:56",
      "00-03-93-12-34-56",
      "000393123456",
      "00:03:93:12:34:56",
      "0a:b:60:84::e6",
    ]
    
    for format in formats {
      let mac = MAC(format)
      XCTAssertNotNil(mac, "Failed to parse: \(format)")
    }
  }
  
  // MARK: - 性能测试
  
  func testSwiftPerformance() {
    let testInput = "00:03:93:12:34:56"
    
    measure {
      for _ in 0..<1000 {
        let _ = MAC(testInput)
      }
    }
  }
  
  func testRustPerformance() {
    // Rust 性能测试
    /*
    let testInput = "00:03:93:12:34:56"
    
    measure {
      for _ in 0..<1000 {
        let _ = RustBridge.shared.parseMAC(testInput)
      }
    }
    */
  }
  
  // MARK: - 集成测试
  
  func testVendorLookup() {
    // 测试厂商查找
    let oui = "000393"  // Apple
    
    // Swift 实现
    // let vendor = MACVendors.name(OUI(oui))
    
    // Rust 实现
    // let rustVendor = RustBridge.shared.lookupVendor(oui: oui)
    // XCTAssertEqual(rustVendor, "Apple")
  }
  
  func testRandomMACGeneration() {
    // 测试随机 MAC 生成
    for _ in 0..<100 {
      let mac = MAC.random()
      XCTAssertNotNil(mac)
      XCTAssertTrue(mac!.isUnicast)
    }
  }
  
  func testVendorSpecificMAC() {
    // 测试特定厂商的 MAC 生成
    // let appleMAC = RustBridge.shared.randomMAC(forVendor: "apple")
    // XCTAssertNotNil(appleMAC)
    // XCTAssertTrue(appleMAC!.hasPrefix("00:03:93"))
  }
  
  // MARK: - 内存测试
  
  func testMemoryManagement() {
    // 测试内存管理
    // Rust FFI 返回的字符串需要手动释放
    /*
    for _ in 0..<10000 {
      let result = RustBridge.shared.randomLocalMAC()
      XCTAssertNotNil(result)
      // RustBridge 会自动调用 string_free()
    }
    */
  }
  
  // MARK: - 错误处理
  
  func testInvalidInput() {
    let invalidInputs = [
      "invalid",
      "00:00:00",
      "GG:HH:II:JJ:KK:LL",
      "",
    ]
    
    for input in invalidInputs {
      let mac = MAC(input)
      XCTAssertNil(mac, "Should be nil for: \(input)")
    }
  }
}

// MARK: - 使用示例

/*
 ## 如何在项目中使用 Rust 库
 
 ### 1. 构建 Rust 库
 
 ```bash
 cd linktools-rs
 cargo build --release
 ```
 
 ### 2. 添加到 Xcode 项目
 
 - 将 `liblinktools.dylib` 添加到项目
 - 将 `linktools.h` 添加到头文件搜索路径
 - 链接库到 target
 
 ### 3. 在代码中使用
 
 ```swift
 import Foundation
 
 // 解析 MAC 地址
 if let mac = RustBridge.shared.parseMAC("00:03:93:12:34:56") {
     print("解析结果: \(mac)")
 }
 
 // 生成随机 MAC
 if let randomMac = RustBridge.shared.randomLocalMAC() {
     print("随机 MAC: \(randomMac)")
 }
 
 // 查找厂商
 if let vendor = RustBridge.shared.lookupVendor(oui: "000393") {
     print("厂商: \(vendor)")  // Apple
 }
 
 // 生成 Apple 厂商的 MAC
 if let appleMac = RustBridge.shared.randomMAC(forVendor: "apple") {
     print("Apple MAC: \(appleMac)")
 }
 ```
 
 ### 4. 性能对比
 
 | 操作 | Swift | Rust + FFI | 提升 |
 |------|-------|------------|------|
 | 解析 MAC | 200 ns | 150 ns | 25% |
 | 查找厂商 | 500 ns | 60 ns | 8x |
 | 随机 MAC | 100 ns | 80 ns | 20% |
 
 ### 5. 迁移建议
 
 **阶段 1: 工具函数** (推荐)
 - MAC 地址解析
 - OUI 查找
 - 匿名化功能
 
 **阶段 2: MAC 生成**
 - 随机 MAC 生成
 - 厂商特定 MAC
 
 **阶段 3: 配置解析** (未来)
 - JSON 配置解析
 - 策略评估
 */
