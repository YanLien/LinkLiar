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
  
  // MARK: - Private Properties
  
  private let session: URLSession
  private var dataTask: URLSessionDataTask?
  
  // MARK: - Initialization
  
  private init() {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    self.session = URLSession(configuration: config)
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
  
  /// Update vendor database from remote source
  func updateVendors() async {
    await MainActor.run {
      isUpdating = true
      errorMessage = nil
      downloadProgress = 0
    }
    
    do {
      // Download vendor data
      let data = try await downloadVendorData()
      
      await MainActor.run {
        downloadProgress = 0.3
      }
      
      // Parse and convert to JSON format
      let (ouiDict, popularVendors) = parseVendorData(data)
      
      await MainActor.run {
        downloadProgress = 0.6
      }
      
      // Save OUI database
      try saveVendorCache(ouiDict)
      
      // Save popular vendors data
      try savePopularVendors(popularVendors)
      
      // Update metadata
      let count = ouiDict.count
      try saveMetadata(count: count)
      
      await MainActor.run {
        downloadProgress = 0.9
      }
      
      // Reload MACVendors and notify observers
      await MainActor.run {
        MACVendors.load()
        self.entryCount = count
        self.lastUpdateDate = Date()
        self.isUpdating = false
        self.downloadProgress = 1.0
        
        // Post notification to refresh UI
        NotificationCenter.default.post(name: .vendorDatabaseDidUpdate, object: nil)
      }
      
    } catch {
      await MainActor.run {
        self.errorMessage = error.localizedDescription
        self.isUpdating = false
        self.downloadProgress = 0
      }
    }
  }
  
  /// Cancel ongoing update
  func cancelUpdate() {
    dataTask?.cancel()
    dataTask = nil
    isUpdating = false
    downloadProgress = 0
  }
  
  /// Remove cached vendor database
  func clearCache() throws {
    if FileManager.default.fileExists(atPath: Paths.vendorCacheFile) {
      try FileManager.default.removeItem(atPath: Paths.vendorCacheFile)
    }
    if FileManager.default.fileExists(atPath: Paths.vendorMetadataFile) {
      try FileManager.default.removeItem(atPath: Paths.vendorMetadataFile)
    }
    if FileManager.default.fileExists(atPath: Paths.popularVendorsFile) {
      try FileManager.default.removeItem(atPath: Paths.popularVendorsFile)
    }
    lastUpdateDate = nil
    entryCount = 0
    
    // Post notification to refresh UI
    NotificationCenter.default.post(name: .vendorDatabaseDidUpdate, object: nil)
  }
  
  // MARK: - Private Methods
  
  private func downloadVendorData() async throws -> String {
    guard let url = URL(string: Paths.vendorDataURL) else {
      throw VendorError.invalidURL
    }
    
    let (data, response) = try await session.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
      throw VendorError.downloadFailed
    }
    
    guard let content = String(data: data, encoding: .utf8) else {
      throw VendorError.invalidData
    }
    
    return content
  }
  
  /// Parse vendor data and return both OUI dict and popular vendors info
  private func parseVendorData(_ content: String) -> (ouiDict: [String: String], popularVendors: [VendorInfo]) {
    var ouiDict: [String: String] = [:]
    // Pre-allocate with estimated capacity for better performance
    ouiDict.reserveCapacity(50000)
    
    // Track vendor name and count only (not storing individual OUIs to save memory)
    var vendorCounts: [String: Int] = [:]
    vendorCounts.reserveCapacity(1000)
    
    // Pre-compute normalization map
    let normalizations: [String: String] = [
      "Cisco Systems": "Cisco",
      "Huawei Technologies": "Huawei",
      "Samsung Electronics": "Samsung",
      "Hewlett Packard": "HP",
      "TP-LINK Technologies": "TP-Link",
      "Lg Electronics Mobile Communications": "LG",
      "Vivo Mobile Communication": "Vivo",
      "Asustek Computer": "Asustek",
      "Sony Mobile Communications": "Sony",
      "Motorola Mobility Llc A Lenovo Company": "Motorola",
      "D-link International": "D-link",
      "Xiaomi Communications": "Xiaomi",
    ]
    
    let denylist = ["Arris", "IEEE", "Foxconn", "Juniper", "Fiberhome", 
                    "Sagemcom", "Private", "Guangdong", "Nortel", "Amazon",
                    "Ruckus", "Technicolor", "Liteon", "Avaya", "Espressif"]
    
    // Process line by line using Substring to avoid string copies
    for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
      // Skip comment lines
      if line.hasPrefix("*") { continue }
      
      // Parse "PREFIX=Vendor Name" format
      guard let eqIndex = line.firstIndex(of: "=") else { continue }
      
      let prefix = line[..<eqIndex].trimmingCharacters(in: .whitespaces)
      var name = line[line.index(after: eqIndex)...].trimmingCharacters(in: .whitespaces)
      
      // Normalize vendor name
      name = normalizations[name] ?? name
      
      // Skip denylisted vendors
      if denylist.contains(where: { name.localizedCaseInsensitiveContains($0) }) { continue }
      
      // Convert prefix to OUI format (e.g., "000393" -> "00:03:93")
      let normalized = prefix.lowercased()
      let hexChars = normalized.filter { $0.isHexDigit }
      if hexChars.count >= 6 {
        let index = hexChars.index(hexChars.startIndex, offsetBy: 2)
        let index2 = hexChars.index(index, offsetBy: 2)
        let oui = "\(hexChars[..<index]):\(hexChars[index..<index2]):\(hexChars[index2..<hexChars.index(index2, offsetBy: 2)])"
        
        ouiDict[String(oui)] = name
        
        // Track count only (not storing OUIs)
        let vendorKey = name.lowercased()
        vendorCounts[vendorKey, default: 0] += 1
      }
    }
    
    // Build popular vendors list (vendors with >50 prefixes)
    var popularVendors: [VendorInfo] = []
    popularVendors.reserveCapacity(100)
    
    for (vendorKey, count) in vendorCounts {
      guard count >= 50 else { continue }
      
      // Find the actual name from ouiDict (use first match)
      let actualName = ouiDict.values.first { $0.lowercased() == vendorKey } ?? vendorKey.capitalized
      
      let vendorInfo = VendorInfo(
        id: Self.vendorId(from: actualName),
        name: actualName,
        prefixCount: count
      )
      popularVendors.append(vendorInfo)
    }
    
    popularVendors.sort { $0.prefixCount > $1.prefixCount }
    
    return (ouiDict, popularVendors)
  }
  
  /// Generate vendor ID from name
  private static func vendorId(from name: String) -> String {
    let cleaned = name.lowercased().filter { $0.isLetter || $0.isNumber || $0 == " " }
    return cleaned.split(separator: " ").first.map(String.init) ?? "unknown"
  }
  
  private func saveVendorCache(_ dict: [String: String]) throws {
    // Ensure config directory exists
    let dirPath = Paths.configDirectory
    if !FileManager.default.fileExists(atPath: dirPath) {
      try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
    }
    
    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .sortedKeys)
    try jsonData.write(to: Paths.vendorCacheFileURL)
  }
  
  private func savePopularVendors(_ vendors: [VendorInfo]) throws {
    // Handle duplicate IDs by keeping the one with higher prefixCount
    var dict: [String: VendorInfo] = [:]
    for vendor in vendors {
      if let existing = dict[vendor.id] {
        // Keep the one with more prefixes
        if vendor.prefixCount > existing.prefixCount {
          dict[vendor.id] = vendor
        }
      } else {
        dict[vendor.id] = vendor
      }
    }
    let data = try JSONEncoder().encode(dict)
    try data.write(to: URL(fileURLWithPath: Paths.popularVendorsFile))
  }
  
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
