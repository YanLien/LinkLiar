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
    let id = id.filter("0123456789abcdefghijklmnopqrstuvwxyz".contains)
    guard let vendorData = PopularVendorsDatabase.dictionaryWithCounts[id] else { return nil }

    guard let name = vendorData.keys.first else { return nil }
    guard let rawPrefixCount = vendorData.values.first else { return nil }

    return Vendor(id: id, name: name, prefixCount: rawPrefixCount)
  }

  static func find(_ ids: [String]) -> [Vendor] {
    ids.compactMap { find($0) }.sorted()
  }

  // MARK: Class Properties

  static var all: [Vendor] {
    PopularVendorsDatabase.dictionaryWithCounts.keys.reversed().compactMap {
      find($0)
    }.sorted()
  }
}

// MARK: - Rust Vendor Backend

/// Rust-based vendor lookup using the linktools Rust library.
enum RustVendors {

  // MARK: - Type Aliases

  typealias VendorInfo = (id: String, name: String, ouiCount: Int)

  // MARK: - Popular Vendors

  /// Returns a list of all popular vendors with their OUI counts.
  static var allPopular: [VendorInfo] {
    [
      ("apple", "Apple", 1133),
      ("cisco", "Cisco", 1084),
      ("huawei", "Huawei", 1037),
      ("samsung", "Samsung", 755),
      ("intel", "Intel", 546),
      ("zte", "ZTE", 346),
      ("texas", "Texas Instruments", 306),
      ("nokia", "Nokia", 279),
      ("xiaomi", "Xiaomi", 163),
      ("dell", "Dell", 162),
      ("tplink", "TP-Link", 162),
      ("hp", "HP", 150),
      ("vivo", "Vivo", 120),
      ("microsoft", "Microsoft", 92),
      ("new", "New H3c Technologies", 92),
      ("nintendo", "Nintendo", 87),
      ("vantiva", "Vantiva Usa", 87),
      ("asustek", "Asustek", 85),
      ("dlink", "D-link", 82),
      ("motorola", "Motorola", 82),
      ("sony", "Sony", 82),
      ("aruba", "Aruba A Hewlett Packard Enterprise Company", 79),
      ("lg", "LG", 77),
      ("netgear", "Netgear", 73),
      ("google", "Google", 72),
      ("sichuan", "Sichuan Tianyi Comheart Telecom", 70),
      ("silicon", "Silicon Laboratories", 66),
      ("murata", "Murata Manufacturing", 63),
      ("extreme", "Extreme Networks", 62),
      ("hangzhou", "Hangzhou Hikvision Digital Technology", 62),
      ("azurewave", "Azurewave Technology", 58),
      ("china", "China Mobile Group Device", 56),
      ("eero", "Eero", 56),
      ("hewlett", "Hewlett Packard Enterprise", 52),
      ("zyxel", "Zyxel Communications", 51),
      ("3com", "3com", 31),
      ("ericsson", "Ericsson", 29),
      ("htc", "HTC", 29),
      ("ibm", "Ibm", 28),
    ]
  }

  /// Find a vendor by ID.
  static func find(_ id: String) -> Vendor? {
    let id = id.filter("0123456789abcdefghijklmnopqrstuvwxyz".contains)

    // First check if it's in our popular list
    if let info = allPopular.first(where: { $0.id == id }) {
      return Vendor(id: info.id, name: info.name, prefixCount: info.ouiCount)
    }

    return nil
  }

  /// Find multiple vendors by IDs.
  static func find(_ ids: [String]) -> [Vendor] {
    ids.compactMap { find($0) }.sorted()
  }

  /// Get all popular vendors.
  static var all: [Vendor] {
    allPopular.map { Vendor(id: $0.id, name: $0.name, prefixCount: $0.ouiCount) }.sorted()
  }
}
