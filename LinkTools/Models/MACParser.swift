// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import Foundation

/// Checks a potential MAC address for validity and normalizes it.
///
struct MACParser {
  // MARK: - Class Methods

  static func normalized24(_ input: String) -> String? {
    self.init(input).normalized24
  }

  static func normalized48(_ input: String) -> String? {
    self.init(input).normalized48
  }

  // MARK: - PrivateClass Methods

  private init(_ input: String) {
    self.input = input
  }

  // MARK: - Instance Properties

  /// OUI prefix size, that is, 24 bits.
  ///
  var normalized24: String? {
    formatted.count == 8 ? formatted : nil
  }

  /// Standard MAC address with 48 bits
  ///
  var normalized48: String? {
    formatted.count == 17 ? formatted : nil
  }

  // MARK: - Private Instance Properties

  private var input: String

  /// Firstly, convert "aa:b::ff" to "aa:0b:00:ff"
  ///
  private var expanded: String {
    input.split(separator: ":", omittingEmptySubsequences: false).map { substring in
      if substring.count > 1 { return substring }
      if substring.count == 1 { return "0\(substring)" }

      return "00"
    }.joined()
  }

  /// Secondly, remove potential non-valid characters.
  ///
  private var stripped: String {
    let nonHexCharacters = CharacterSet(charactersIn: "0123456789abcdef").inverted

    return expanded.lowercased()
                   .components(separatedBy: nonHexCharacters)
                   .joined()
  }

  /// Thirdly, insert ":" for proper formatting.
  ///
  private var formatted: String {
    String(stripped.enumerated().map {
      $0.offset % 2 == 1 ? [$0.element] : [":", $0.element]
    }.joined().dropFirst())
  }
}

// MARK: - Rust Backend Extensions (Reserved for future use)

extension MACParser {

  /// Generate a random local MAC address.
  /// Note: Currently uses Swift implementation. Rust integration pending.
  static func randomLocal() -> String {
    // Swift implementation
    var bytes = [UInt8](repeating: 0, count: 6)
    for i in 0..<6 {
      bytes[i] = UInt8.random(in: 0...0xFF)
    }
    // Set locally administered bit, clear multicast bit
    bytes[0] = (bytes[0] & 0xFC) | 0x02
    return bytes.map { String(format: "%02X", $0) }.joined(separator: ":")
  }

  /// Generate a random MAC address for a specific vendor.
  /// Note: Currently uses Swift implementation. Rust integration pending.
  static func randomForVendor(_ vendorId: String) -> String? {
    // Look up OUIs for this vendor
    let ouis = PopularOUIs.find(vendorId)
    guard let oui = ouis.first else { return nil }

    // Parse OUI to get the prefix bytes
    let prefix = oui.address.replacingOccurrences(of: ":", with: "")
    guard prefix.count == 6 else { return nil }

    var bytes = [UInt8](repeating: 0, count: 6)

    // Parse OUI prefix bytes
    let prefixIndex = prefix.startIndex
    for i in 0..<3 {
      let start = prefix.index(prefixIndex, offsetBy: i * 2)
      let end = prefix.index(start, offsetBy: 2)
      let byteStr = String(prefix[start..<end])
      bytes[i] = UInt8(byteStr, radix: 16) ?? 0
    }

    // Random suffix
    for i in 3..<6 {
      bytes[i] = UInt8.random(in: 0...0xFF)
    }

    return bytes.map { String(format: "%02X", $0) }.joined(separator: ":")
  }

  /// Anonymize a MAC address.
  static func anonymize(_ address: String) -> String? {
    let normalized = normalized48(address)
    guard let normalized else { return nil }
    let parts = normalized.split(separator: ":").prefix(3)
    return parts.joined(separator: ":") + ":XX:XX:XX"
  }

  /// Lookup vendor by MAC address.
  static func lookupVendor(_ address: String) -> String? {
    let normalized = normalized48(address)
    guard let normalized else { return nil }

    let parts = normalized.split(separator: ":").prefix(3)
    let oui = parts.joined(separator: ":")

    // Look up OUI in vendor database
    guard let ouiObj = OUI(oui.replacingOccurrences(of: ":", with: "")) else {
      return nil
    }

    // Try to find vendor by OUI
    for vendor in PopularVendors.all {
      let vendorOUIs = PopularOUIs.find(vendor.id)
      if vendorOUIs.contains(where: { $0.address == ouiObj.address }) {
        return vendor.name
      }
    }

    return nil
  }

  /// Lookup vendor by OUI.
  static func lookupVendor(oui: String) -> String? {
    let normalizedOUI = oui.replacingOccurrences(of: ":", with: "")
    guard let ouiObj = OUI(normalizedOUI) else { return nil }

    // Try to find vendor by OUI
    for vendor in PopularVendors.all {
      let vendorOUIs = PopularOUIs.find(vendor.id)
      if vendorOUIs.contains(where: { $0.address == ouiObj.address }) {
        return vendor.name
      }
    }

    return nil
  }
}
