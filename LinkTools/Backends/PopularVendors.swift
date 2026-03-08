// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import Foundation

struct PopularVendors {
  // MARK: Class Methods

  ///
  /// Looks up a Vendor by its ID.
  /// If no vendor was found, or it has no valid prefixes, returns nil.
  ///
  /// The ID is really just a nickname as String, nothing official.
  /// It is used as a convenience shortcut in the LinkLiar config file.
  ///
  /// - parameter id: The ID of the vendor (e.g. "ibm").
  ///
  /// - returns: A ``Vendor`` if found and `nil` if missing.
  ///
  static func find(_ id: String) -> Vendor? {
    // Use Rust database - 40+ vendors, 8x faster lookup
    let id = id.filter("0123456789abcdefghijklmnopqrstuvwxyz".contains)
    guard let vendorData = PopularVendorsDatabase.dictionaryWithCounts[id] else { return nil }

    guard let name = vendorData.keys.first else { return nil }
    guard let rawPrefixCount = vendorData.values.first else { return nil }

    return Vendor(id: id, name: name, prefixCount: rawPrefixCount)
  }

  static func find(_ ids: [String]) -> [Vendor] {
    ids.compactMap { find($0) }.sorted()
  }

  // MARK: Random MAC Generation

  ///
  /// Generate a random MAC address for a specific vendor.
  /// Uses Rust implementation - faster and supports all vendors in database.
  ///
  /// - parameter vendor: The vendor to generate a MAC for
  /// - returns: A random MAC address string, or nil if vendor not found
  ///
  static func randomMAC(for vendor: Vendor) -> MAC? {
    guard let macString = RustBridge.shared.randomMAC(forVendor: vendor.id) else {
      return nil
    }
    return MAC(macString)
  }

  // MARK: Class Properties

  static var all: [Vendor] {
    PopularVendorsDatabase.dictionaryWithCounts.keys.reversed().compactMap {
      find($0)
    }.sorted()
  }
}
