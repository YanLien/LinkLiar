// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import Foundation

// Note: BSSID is already defined as a typealias to MAC in BSSID.swift
// We use that type instead of defining our own.

/// Swift wrapper for SSID (Service Set Identifier) operations.
///
/// This provides a Swift-friendly interface for working with WiFi network names.
///
struct NetworkSSID: Equatable, ExpressibleByStringLiteral {
  let name: String

  init(_ name: String) {
    self.name = name
  }

  init(stringLiteral value: String) {
    self.name = value
  }

  var isHidden: Bool {
    name.isEmpty
  }

  var isValid: Bool {
    !isEmpty && name.count <= 32
  }

  var isEmpty: Bool {
    name.isEmpty
  }

  /// Check if this looks like a carrier/ISP WiFi (heuristic)
  var isCarrierWiFi: Bool {
    let lower = name.lowercased()
    let carriers = [
      "att", "at&t", "verizon", "comcast", "xfinity", "spectrum",
      "cox", "optimum", "tim", "vodafone", "telekom", "orange",
      "sfr", "bouygues", "free", "proximus", "telenet",
    ]

    return carriers.contains { lower.contains($0) }
  }

  /// Check if this looks like a public hotspot (heuristic)
  var isPublicHotspot: Bool {
    let lower = name.lowercased()
    let hotspotKeywords = [
      "guest", "public", "visitor", "open", "free", "wifi",
      "hotspot", "_5g", "extension",
    ]

    return hotspotKeywords.contains { lower.contains($0) }
  }
}

/// Access Point information combining BSSID and SSID.
///
struct AccessPointInfo: Equatable, Identifiable {
  var id: String { bssid.address }
  let bssid: BSSID
  let ssid: NetworkSSID
  let signalStrength: Int?
  let channel: Int?

  var vendor: String? {
    MACParser.lookupVendor(oui: bssid.prefix.replacingOccurrences(of: ":", with: ""))
  }
}

/// WiFi scanner for detecting nearby access points.
///
enum WiFiScanner {

  /// Get current SSID
  static func currentSSID() -> NetworkSSID? {
    // This would need to call macOS CoreWiFi or airport command
    // For now, return nil
    nil
  }

  /// Get current BSSID
  static func currentBSSID() -> BSSID? {
    // This would need to call macOS CoreWiFi or airport command
    // For now, return nil
    nil
  }

  /// Scan for access points (placeholder)
  static func scanAccessPoints() -> [AccessPointInfo] {
    // This would need to call macOS airport scanner
    // For now, return empty array
    []
  }
}

// MARK: - BSSID Extensions

extension BSSID {

  /// Check if this BSSID indicates a hidden SSID (ends with :00:00:00)
  var isHiddenSSIDIndicator: Bool {
    address.hasSuffix(":00:00:00")
  }
}
