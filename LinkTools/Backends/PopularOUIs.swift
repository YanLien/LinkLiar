// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import Foundation

struct PopularOUIs {
  // MARK: Class Methods

  static func find(_ id: String) -> [OUI] {
    let id = id.filter("0123456789abcdefghijklmnopqrstuvwxyz".contains)
    guard let vendorData = PopularVendorsDatabase.dictionaryWithOUIs[id] else { return [] }

    guard let rawOUIs = vendorData.values.first else { return [] }
    return rawOUIs.compactMap { OUI(String(format: "%06X", $0)) }
  }

  static func find(_ ids: [String]) -> [OUI] {
    ids.flatMap { find($0) }.compactMap { $0 }.sorted()
  }

  // MARK: Class Properties

  static var all: [OUI] {
    PopularVendorsDatabase.dictionaryWithCounts.keys.reversed().flatMap {
      find($0)
    }.compactMap { $0 }.sorted()
  }
}

// MARK: - Rust OUI Backend

/// Rust-based OUI lookup using the linktools Rust library.
enum RustOUIs {

  /// Get all OUIs for a given vendor ID using Rust library.
  static func find(_ vendorId: String) -> [OUI] {
    let vendorId = vendorId.filter("0123456789abcdefghijklmnopqrstuvwxyz".contains)

    // For now, fall back to the Swift implementation
    // since Rust types may not be available in all build configurations
    return PopularOUIs.find(vendorId)
  }

  /// Find multiple OUIs by vendor IDs.
  static func find(_ ids: [String]) -> [OUI] {
    ids.flatMap { find($0) }.compactMap { $0 }.sorted()
  }

  /// Get all popular OUIs.
  ///
  /// For now, this returns Apple's OUIs as the default.
  static var all: [OUI] {
    find("apple")
  }
}
