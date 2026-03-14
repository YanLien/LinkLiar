import Foundation

/// Rust library bridge for LinkLiar
/// Provides high-performance MAC address and vendor database operations
class RustBridge {

    // MARK: - Singletons

    static let shared = RustBridge()
    private init() {}

    // MARK: - MAC Address Operations

    /// Parse and validate a MAC address
    /// - Parameter input: MAC address string (various formats supported)
    /// - Returns: Formatted MAC address (XX:XX:XX:XX:XX:XX) or nil
    func parseMAC(_ input: String) -> String? {
        guard let cInput = input.cString(using: .utf8) else { return nil }
        guard let result = mac_parse(cInput) else { return nil }
        defer { string_free(result) }
        return String(cString: result)
    }

    /// Generate a random locally administered MAC address
    /// - Returns: Random MAC address with locally administered bit set
    func randomLocalMAC() -> String? {
        guard let result = mac_random_local() else { return nil }
        defer { string_free(result) }
        return String(cString: result)
    }

    /// Generate a random MAC address for a specific vendor
    /// - Parameter vendorId: Vendor identifier (e.g., "apple", "cisco")
    /// - Returns: Random MAC with vendor's OUI prefix
    func randomMAC(forVendor vendorId: String) -> String? {
        guard let cInput = vendorId.cString(using: .utf8) else { return nil }
        guard let result = mac_random_for_vendor(cInput) else { return nil }
        defer { string_free(result) }
        return String(cString: result)
    }

    /// Anonymize a MAC address (show only OUI prefix)
    /// - Parameter mac: MAC address string
    /// - Returns: Anonymized MAC (XX:XX:XX:XX:XX:XX → XX:XX:XX:XX:XX:XX)
    func anonymizeMAC(_ mac: String) -> String? {
        guard let cInput = mac.cString(using: .utf8) else { return nil }
        guard let result = mac_anonymize(cInput) else { return nil }
        defer { string_free(result) }
        return String(cString: result)
    }

    // MARK: - Vendor Operations

    /// Lookup vendor name for an OUI
    /// - Parameter oui: OUI string (e.g., "000393" or "00:03:93")
    /// - Returns: Vendor name or nil
    func lookupVendor(oui: String) -> String? {
        guard let cInput = oui.cString(using: .utf8) else { return nil }
        guard let result = oui_lookup(cInput) else { return nil }
        defer { string_free(result) }
        return String(cString: result)
    }

    /// Lookup vendor for a MAC address
    /// - Parameter mac: MAC address string
    /// - Returns: Vendor name or nil
    func lookupVendor(mac: String) -> String? {
        guard let formatted = parseMAC(mac) else { return nil }
        let oui = String(formatted.prefix(8))  // "XX:XX:XX"
        return lookupVendor(oui: oui)
    }

    // MARK: - Vendor Database Operations

    /// Load vendor database from an oui.json file
    /// - Parameter path: Path to the oui.json file
    /// - Returns: Number of entries loaded, or -1 on error
    @discardableResult
    func loadVendorDatabase(path: String) -> Int {
        guard let cPath = path.cString(using: .utf8) else { return -1 }
        return Int(vendor_load_database(cPath))
    }

    /// Download vendor data, parse, save as oui.json, and reload the database
    /// - Parameters:
    ///   - url: URL to download vendor data from
    ///   - outputPath: Path where oui.json will be saved
    /// - Returns: Number of entries, or -1 on error
    @discardableResult
    func updateVendorDatabase(url: String, outputPath: String) -> Int {
        guard let cUrl = url.cString(using: .utf8),
              let cPath = outputPath.cString(using: .utf8) else { return -1 }
        return Int(vendor_update_database(cUrl, cPath))
    }

    /// Get popular vendors from the loaded database
    /// - Parameter minCount: Minimum number of OUI prefixes for a vendor to be considered popular
    /// - Returns: Array of VendorInfo
    func getPopularVendors(minCount: Int = 50) -> [VendorInfo] {
        guard let result = vendor_get_popular_json(Int32(minCount)) else { return [] }
        defer { string_free(result) }

        let jsonString = String(cString: result)
        guard let data = jsonString.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([VendorInfo].self, from: data)) ?? []
    }

    /// Get all OUI prefixes for a vendor
    /// - Parameter vendorId: Vendor identifier (e.g., "apple")
    /// - Returns: Array of OUI strings in "xx:xx:xx" format
    func getVendorOUIs(vendorId: String) -> [String] {
        guard let cInput = vendorId.cString(using: .utf8) else { return [] }
        guard let result = vendor_get_vendor_ouis_json(cInput) else { return [] }
        defer { string_free(result) }

        let jsonString = String(cString: result)
        guard let data = jsonString.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
}
