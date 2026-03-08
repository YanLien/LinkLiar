// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import XCTest
@testable import LinkLiar

/// Test suite for Rust-integrated MAC functionality
final class RustIntegrationTests: XCTestCase {

  // MARK: - MAC Parsing Tests

  func testMACParsingStandardFormat() {
    let mac = MAC("00:03:93:12:34:56")
    XCTAssertNotNil(mac)
    XCTAssertEqual(mac?.address, "00:03:93:12:34:56")
  }

  func testMACParsingHyphenFormat() {
    let mac = MAC("00-03-93-12-34-56")
    XCTAssertNotNil(mac)
    XCTAssertEqual(mac?.address, "00:03:93:12:34:56")
  }

  func testMACParsingCiscoFormat() {
    let mac = MAC("0003.9312.3456")
    XCTAssertNotNil(mac)
    XCTAssertEqual(mac?.address, "00:03:93:12:34:56")
  }

  func testMACParsingMixedFormat() {
    let mac = MAC("00:03-93:12:34-56")
    XCTAssertNotNil(mac)
    XCTAssertEqual(mac?.address, "00:03:93:12:34:56")
  }

  func testMACParsingInvalid() {
    let mac = MAC("invalid-mac")
    XCTAssertNil(mac)
  }

  func testMACParsingWrongLength() {
    let mac = MAC("00:03:93:12:34:56:78")  // Too long
    XCTAssertNil(mac)
  }

  // MARK: - Vendor Lookup Tests

  func testVendorLookupApple() {
    let mac = MAC("00:03:93:12:34:56")
    XCTAssertEqual(mac?.vendorName(), "Apple")
  }

  func testVendorLookupCisco() {
    let mac = MAC("00:00:0c:12:34:56")
    XCTAssertEqual(mac?.vendorName(), "Cisco")
  }

  func testVendorLookupUnknown() {
    let mac = MAC("ff:ff:ff:ff:ff:ff")
    XCTAssertNil(mac?.vendorName())
  }

  // MARK: - MAC Anonymization Tests

  func testMACAnonymization() {
    let mac = MAC("00:03:93:12:34:56")
    let anonymous = mac?.anonymous(true)
    
    XCTAssertNotNil(anonymous)
    XCTAssertTrue(anonymous!.contains(":"))
    
    // OUI should be preserved
    XCTAssertTrue(anonymous!.hasPrefix("00:03:93"))
  }

  func testMACNoAnonymization() {
    let mac = MAC("00:03:93:12:34:56")
    let notAnonymous = mac?.anonymous(false)
    XCTAssertEqual(notAnonymous, "00:03:93:12:34:56")
  }

  // MARK: - Random MAC Generation Tests

  func testRandomLocalMAC() {
    let mac = RustBridge.shared.randomLocalMAC()
    XCTAssertNotNil(mac)
    
    // Should be valid format
    let components = mac.split(separator: ":")
    XCTAssertEqual(components.count, 6)
    
    // Should be locally administered (bit 1 of first byte is set)
    if let firstByte = UInt8(components.first!, radix: 16) {
      XCTAssertTrue((firstByte & 0x02) != 0, "Should be locally administered")
    } else {
      XCTFail("Invalid first byte")
    }
  }

  func testRandomMACForVendor() {
    let apple = Vendor(id: "apple", name: "Apple", prefixCount: 1133)
    let mac = PopularVendors.randomMAC(for: apple)
    
    XCTAssertNotNil(mac)
    
    // Should have Apple OUI
    XCTAssertTrue(mac!.address.hasPrefix("00:03:93") ||
                  mac!.address.hasPrefix("00:0a:27") ||
                  mac!.address.hasPrefix("00:1b:63"))
  }

  func testRandomMACForUnknownVendor() {
    let unknown = Vendor(id: "unknownvendor", name: "Unknown", prefixCount: 0)
    let mac = PopularVendors.randomMAC(for: unknown)
    XCTAssertNil(mac)
  }

  // MARK: - Popular Vendors Tests

  func testPopularVendorsCount() {
    let vendors = PopularVendors.all
    XCTAssertGreaterThan(vendors.count, 40, "Should have 40+ vendors")
  }

  func testFindVendor() {
    let apple = PopularVendors.find("apple")
    XCTAssertNotNil(apple)
    XCTAssertEqual(apple?.name, "Apple")
    XCTAssertEqual(apple?.prefixCount, 1133)
  }

  func testFindMultipleVendors() {
    let vendors = PopularVendors.find(["apple", "cisco", "samsung"])
    XCTAssertEqual(vendors.count, 3)
    XCTAssertTrue(vendors.contains { $0.id == "apple" })
    XCTAssertTrue(vendors.contains { $0.id == "cisco" })
    XCTAssertTrue(vendors.contains { $0.id == "samsung" })
  }

  // MARK: - Performance Tests

  func testMACParsingPerformance() {
    measure {
      for _ in 0..<1000 {
        _ = MAC("00:03:93:12:34:56")
      }
    }
  }

  func testVendorLookupPerformance() {
    let mac = MAC("00:03:93:12:34:56")!
    measure {
      for _ in 0..<1000 {
        _ = mac.vendorName()
      }
    }
  }

  func testRandomMACGenerationPerformance() {
    measure {
      for _ in 0..<100 {
        _ = RustBridge.shared.randomLocalMAC()
      }
    }
  }

  // MARK: - Edge Cases

  func testEmptyMAC() {
    let mac = MAC("")
    XCTAssertNil(mac)
  }

  func testMACWithSpaces() {
    let mac = MAC("00:03:93:12:34:56 ")
    XCTAssertNil(mac, "Should not accept MAC with trailing space")
  }

  func testMACPrefix() {
    let mac = MAC("00:03:93:12:34:56")
    XCTAssertEqual(mac?.prefix, "00:03:93")
  }

  func testMACIntegers() {
    let mac = MAC("00:03:93:12:34:56")
    let ints = mac?.integers
    XCTAssertEqual(ints?.count, 6)
    XCTAssertEqual(ints?[0], 0x00)
    XCTAssertEqual(ints?[1], 0x03)
    XCTAssertEqual(ints?[2], 0x93)
    XCTAssertEqual(ints?[3], 0x12)
    XCTAssertEqual(ints?[4], 0x34)
    XCTAssertEqual(ints?[5], 0x56)
  }

  // MARK: - Comparison Tests

  func testMACEquality() {
    let mac1 = MAC("00:03:93:12:34:56")
    let mac2 = MAC("00-03-93-12-34-56")
    XCTAssertEqual(mac1, mac2, "MACs should be equal regardless of input format")
  }

  func testMACComparison() {
    let mac1 = MAC("00:03:93:12:34:56")!
    let mac2 = MAC("00:03:93:12:34:57")!
    XCTAssertLessThan(mac1, mac2)
  }
}
