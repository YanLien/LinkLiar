// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import Foundation
import Combine

/// Notification sent when vendor database is updated
extension Notification.Name {
  static let vendorDatabaseDidUpdate = Notification.Name("vendorDatabaseDidUpdate")
}

/// Manages vendor database updates
class VendorUpdater: ObservableObject {
  // MARK: - Published Properties

  @Published var isUpdating = false
  @Published var lastUpdateDate: Date?
  @Published var entryCount: Int = 0
  @Published var errorMessage: String?
  @Published var downloadProgress: Double = 0

  // MARK: - Static Properties

  static let shared = VendorUpdater()

  // MARK: - Initialization

  private init() {
    loadMetadata()
  }

  // MARK: - Public Methods

  /// Check if a cached vendor database exists
  var hasCache: Bool {
    FileManager.default.fileExists(atPath: Paths.vendorCacheFile)
  }

  /// Get the path to the vendor database (cached or bundled)
  var currentVendorPath: String {
    if hasCache {
      return Paths.vendorCacheFile
    }
    return Bundle.main.url(forResource: "oui", withExtension: "json")?.path ?? ""
  }

  /// Update vendor database from remote source (Rust handles download + parse + save)
  func updateVendors() async {
    await MainActor.run {
      isUpdating = true
      errorMessage = nil
      downloadProgress = 0
    }

    // Ensure config directory exists
    let dirPath = Paths.configDirectory
    if !FileManager.default.fileExists(atPath: dirPath) {
      try? FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
    }

    await MainActor.run {
      downloadProgress = 0.1
    }

    // Rust handles download, parse, and save in one call
    let count = RustBridge.shared.updateVendorDatabase(
      url: Paths.vendorDataURL,
      outputPath: Paths.vendorCacheFile
    )

    if count >= 0 {
      // Save metadata
      try? saveMetadata(count: count)

      await MainActor.run {
        downloadProgress = 0.9
      }

      // Reload MACVendors and notify observers
      await MainActor.run {
        MACVendors.load()
        PopularVendors.reloadDatabase()
        self.entryCount = count
        self.lastUpdateDate = Date()
        self.isUpdating = false
        self.downloadProgress = 1.0

        // Post notification to refresh UI
        NotificationCenter.default.post(name: .vendorDatabaseDidUpdate, object: nil)
      }
    } else {
      await MainActor.run {
        self.errorMessage = "Failed to download or parse vendor data"
        self.isUpdating = false
        self.downloadProgress = 0
      }
    }
  }

  /// Remove cached vendor database
  func clearCache() throws {
    if FileManager.default.fileExists(atPath: Paths.vendorCacheFile) {
      try FileManager.default.removeItem(atPath: Paths.vendorCacheFile)
    }
    if FileManager.default.fileExists(atPath: Paths.vendorMetadataFile) {
      try FileManager.default.removeItem(atPath: Paths.vendorMetadataFile)
    }
    lastUpdateDate = nil
    entryCount = 0

    // Reload from bundled database
    PopularVendors.reloadDatabase()

    // Post notification to refresh UI
    NotificationCenter.default.post(name: .vendorDatabaseDidUpdate, object: nil)
  }

  // MARK: - Private Methods

  private func saveMetadata(count: Int) throws {
    let metadata: [String: Any] = [
      "lastUpdate": ISO8601DateFormatter().string(from: Date()),
      "entryCount": count,
      "source": Paths.vendorDataURL
    ]

    let data = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
    try data.write(to: URL(fileURLWithPath: Paths.vendorMetadataFile))
  }

  private func loadMetadata() {
    guard FileManager.default.fileExists(atPath: Paths.vendorMetadataFile),
          let data = try? Data(contentsOf: URL(fileURLWithPath: Paths.vendorMetadataFile)),
          let metadata = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      // No metadata file, count entries in cache or bundle
      countExistingEntries()
      return
    }

    if let dateString = metadata["lastUpdate"] as? String {
      lastUpdateDate = ISO8601DateFormatter().date(from: dateString)
    }

    if let count = metadata["entryCount"] as? Int {
      entryCount = count
    }
  }

  private func countExistingEntries() {
    let path = currentVendorPath
    guard !path.isEmpty,
          let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
          let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      entryCount = 0
      return
    }

    entryCount = dict.count
  }
}

// MARK: - Error Types

enum VendorError: LocalizedError {
  case invalidURL
  case downloadFailed
  case invalidData
  case parseError
  case saveError

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid vendor data URL"
    case .downloadFailed:
      return "Failed to download vendor data"
    case .invalidData:
      return "Invalid vendor data format"
    case .parseError:
      return "Failed to parse vendor data"
    case .saveError:
      return "Failed to save vendor database"
    }
  }
}
