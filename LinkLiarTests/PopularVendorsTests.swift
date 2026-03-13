// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import XCTest
@testable import LinkLiar

class PopularVendorsTests: XCTestCase {
  func testFind() {
    let vendor = PopularVendors.find("apple")
    XCTAssertNotNil(vendor)
    XCTAssertEqual("Apple", vendor?.name)
    XCTAssertGreaterThan(vendor?.prefixCount ?? 0, 0)
  }
}
