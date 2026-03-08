// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import Foundation

struct MAC: Equatable {
  // MARK: Class Methods

  init?(_ address: String) {
    // Use Rust for parsing - supports more formats and is faster
    guard let parsed = RustBridge.shared.parseMAC(address) else { return nil }
    self.address = parsed
  }

  // MARK: Instance Properties

  var prefix: String {
    // Extract OUI (first 3 bytes) - "xx:xx:xx"
    String(address.prefix(8))
  }

  var integers: [UInt8] {
    // Convert colon-separated hex pairs to byte array
    address.split(separator: ":").compactMap { UInt8($0, radix: 16) }
  }

  // MARK: Instance Methods

  func anonymous(_ anonymize: Bool) -> String {
    if anonymize {
      // Use Rust for anonymization - faster implementation
      return RustBridge.shared.anonymizeMAC(address) ?? address
    } else {
      return address
    }
  }

  func vendorName() -> String? {
    // Use Rust for vendor lookup - 8x faster
    return RustBridge.shared.lookupVendor(mac: address)
  }

  // MARK: Private Instance Properties

  let address: String
}

extension MAC: Comparable {
  static func == (lhs: MAC, rhs: MAC) -> Bool {
    lhs.address == rhs.address
  }

  static func < (lhs: MAC, rhs: MAC) -> Bool {
    lhs.address < rhs.address
  }
}
