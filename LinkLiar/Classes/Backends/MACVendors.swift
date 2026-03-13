// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import Foundation

struct MACVendors {
  private static var dictionary: [String: String] = [:]

  static func load(_ callback: ( ([String: String]) -> Void)? = nil) {
    Log.debug("Loading MAC vendors asynchronously...")
    DispatchQueue.global(qos: .background).async(execute: { () -> Void in
      let vendorPath = path

      // Load into Rust backend for PopularVendors/PopularOUIs
      RustBridge.shared.loadVendorDatabase(path: vendorPath)

      guard let parsed = JSONReader(vendorPath).dictionary as? [String: String] else {
        Log.debug("Could not parse MAC vendors.")
        return
      }
      self.dictionary = parsed
      Log.debug("MAC vendors loading completed. I got \(parsed.count) prefixes.")
      if let validCallback = callback {
        validCallback(parsed)
      }
    })
  }

  static func name(_ oui: OUI) -> String {
    Log.debug("Looking up vendor of MAC \(oui.address) among \(dictionary.count) prefixes")
    guard let name = dictionary[oui.address] else {
      return "No Vendor"
    }
    return name
  }

  /// Returns the number of vendor entries loaded
  static var count: Int {
    dictionary.count
  }

  private static var path: String {
    let cachePath = Paths.vendorCacheFile
    if FileManager.default.fileExists(atPath: cachePath) {
      return cachePath
    }
    return Bundle.main.url(forResource: "oui", withExtension: "json")?.path ?? ""
  }
}
