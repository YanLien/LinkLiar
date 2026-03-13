// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import Foundation

struct PopularOUIs {
  // MARK: Class Methods

  static func find(_ id: String) -> [OUI] {
    let id = id.filter("0123456789abcdefghijklmnopqrstuvwxyz".contains)
    PopularVendors.ensureLoaded()
    return RustBridge.shared.getVendorOUIs(vendorId: id).compactMap { OUI($0) }
  }

  static func find(_ ids: [String]) -> [OUI] {
    ids.flatMap { find($0) }.compactMap { $0 }.sorted()
  }

  // MARK: Class Properties

  static var all: [OUI] {
    PopularVendors.ensureLoaded()
    let vendors = RustBridge.shared.getPopularVendors(minCount: 50)
    return vendors.flatMap { vendor in
      RustBridge.shared.getVendorOUIs(vendorId: vendor.id).compactMap { OUI($0) }
    }.sorted()
  }
}
