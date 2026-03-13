// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import Foundation

/// Vendor information for storage and caching
struct VendorInfo: Codable {
  let id: String
  let name: String
  let prefixCount: Int
}

struct PopularVendors {

  // MARK: - Database Loading

  private static let loadLock = NSLock()
  private static var loaded = false

  /// Path to the vendor database (cached or bundled)
  private static var vendorDatabasePath: String {
    let cachePath = Paths.vendorCacheFile
    if FileManager.default.fileExists(atPath: cachePath) {
      return cachePath
    }
    return Bundle.main.url(forResource: "oui", withExtension: "json")?.path ?? ""
  }

  /// Ensure the Rust vendor database is loaded (lazy, thread-safe)
  static func ensureLoaded() {
    loadLock.lock()
    defer { loadLock.unlock() }
    guard !loaded else { return }
    loaded = true
    RustBridge.shared.loadVendorDatabase(path: vendorDatabasePath)
  }

  /// Reload the Rust vendor database (after update or cache clear)
  static func reloadDatabase() {
    loadLock.lock()
    defer { loadLock.unlock() }
    RustBridge.shared.loadVendorDatabase(path: vendorDatabasePath)
    loaded = true
  }

  // MARK: Class Methods

  ///
  /// Looks up a Vendor by its ID.
  /// If no vendor was found, returns nil.
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
    ensureLoaded()

    let vendors = RustBridge.shared.getPopularVendors(minCount: 1)
    guard let info = vendors.first(where: { $0.id == id }) else { return nil }
    return Vendor(id: info.id, name: info.name, prefixCount: info.prefixCount)
  }

  static func find(_ ids: [String]) -> [Vendor] {
    ids.compactMap { find($0) }.sorted()
  }

  // MARK: Class Properties

  static var all: [Vendor] {
    ensureLoaded()
    return RustBridge.shared.getPopularVendors(minCount: 50)
      .map { Vendor(id: $0.id, name: $0.name, prefixCount: $0.prefixCount) }
      .sorted()
  }
}
