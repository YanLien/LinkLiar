import Foundation

/// Rust library bridge for LinkLiar
/// Provides high-performance MAC address operations
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
}

// MARK: - Usage Examples

/*
 // Example 1: Parse MAC address
 let bridge = RustBridge.shared
 
 if let mac = bridge.parseMAC("00:03:93:12:34:56") {
     print("Parsed MAC: \(mac)")  // "00:03:93:12:34:56"
 }
 
 // Example 2: Generate random local MAC
 if let randomMac = bridge.randomLocalMAC() {
     print("Random local MAC: \(randomMac)")
 }
 
 // Example 3: Generate Apple MAC
 if let appleMac = bridge.randomMAC(forVendor: "apple") {
     print("Random Apple MAC: \(appleMac)")
 }
 
 // Example 4: Lookup vendor
 if let vendor = bridge.lookupVendor(oui: "000393") {
     print("Vendor: \(vendor)")  // "Apple"
 }
 
 // Example 5: Anonymize MAC
 if let anon = bridge.anonymizeMAC("00:03:93:12:34:56") {
     print("Anonymized: \(anon)")  // "00:03:93:XX:XX:XX"
 }
 */
