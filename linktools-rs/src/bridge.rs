//! Swift-Rust Bridge definitions using swift-bridge
//!
//! This module defines the interface between Rust and Swift.
//! swift-bridge will generate the necessary Swift and C glue code.

#[swift_bridge::bridge]
mod ffi {
    // Error type for operations
    enum LinkError {
        InvalidFormat,
    }

    // Export Rust types and functions for Swift to use
    extern "Rust" {
        type MACAddress;

        #[swift_bridge(init)]
        fn parse(input: &str) -> Result<MACAddress, LinkError>;

        fn to_string(&self) -> String;

        fn anonymize(&self) -> String;

        fn to_oui(&self) -> Oui;

        fn lookup_vendor(&self) -> Option<String>;
    }

    extern "Rust" {
        type Oui;

        #[swift_bridge(init)]
        fn parse(input: &str) -> Result<Oui, LinkError>;

        fn to_string(&self) -> String;

        fn lookup_vendor(&self) -> Option<String>;

        fn to_hex_string(&self) -> String;
    }

    // BSSID type
    extern "Rust" {
        type Bssid;

        #[swift_bridge(init)]
        fn parse(input: &str) -> Result<Bssid, LinkError>;

        fn to_string(&self) -> String;

        fn to_mac(&self) -> MACAddress;

        fn is_hidden_ssid_indicator(&self) -> bool;
    }

    // SSID type
    extern "Rust" {
        type Ssid;

        #[swift_bridge(init)]
        fn parse(input: &str) -> Result<Ssid, LinkError>;

        fn to_string(&self) -> String;

        fn is_hidden(&self) -> bool;

        fn is_valid(&self) -> bool;

        fn is_carrier_wifi(&self) -> bool;

        fn is_public_hotspot(&self) -> bool;
    }

    // Standalone functions for MAC operations
    extern "Rust" {
        fn mac_random_local() -> MACAddress;

        fn mac_random_with_vendor(vendor_id: &str) -> Option<MACAddress>;

        // Batch operations - simplified return types
        fn batch_validate_macs(addrs: Vec<String>) -> Vec<bool>;

        fn batch_normalize_macs(addrs: Vec<String>) -> Vec<String>;

        fn batch_anonymize_macs(addrs: Vec<String>) -> Vec<String>;

        fn batch_generate_local_macs(count: usize) -> Vec<String>;

        fn batch_generate_vendor_macs(vendor_id: &str, count: usize) -> Vec<String>;

        // Similarity operations
        fn mac_similarity_score(mac1: &str, mac2: &str) -> Option<f64>;

        fn mac_are_same_vendor(mac1: &str, mac2: &str) -> bool;
    }
}

// Rust implementations

pub struct MACAddress {
    mac: crate::mac::MAC,
}

pub struct Oui {
    oui: crate::oui::OUI,
}

pub struct Bssid {
    bssid: crate::bssid::BSSID,
}

pub struct Ssid {
    ssid: crate::ssid::SSID,
}

// Implement functions declared in the bridge
impl MACAddress {
    fn parse(input: &str) -> Result<MACAddress, ffi::LinkError> {
        crate::mac::MAC::parse(input)
            .map(|mac| MACAddress { mac })
            .map_err(|_| ffi::LinkError::InvalidFormat)
    }

    fn to_string(&self) -> String {
        self.mac.to_string_colon()
    }

    fn anonymize(&self) -> String {
        self.mac.anonymize()
    }

    fn to_oui(&self) -> Oui {
        Oui {
            oui: self.mac.to_oui(),
        }
    }

    fn lookup_vendor(&self) -> Option<String> {
        let oui = self.mac.oui();
        crate::vendor::VendorDatabase::default()
            .lookup(&crate::oui::OUI::new(oui))
            .map(|v| v.to_string())
    }
}

impl Oui {
    fn parse(input: &str) -> Result<Oui, ffi::LinkError> {
        crate::oui::OUI::parse(input)
            .map(|oui| Oui { oui })
            .map_err(|_| ffi::LinkError::InvalidFormat)
    }

    fn to_string(&self) -> String {
        self.oui.to_string_colon()
    }

    fn lookup_vendor(&self) -> Option<String> {
        crate::vendor::VendorDatabase::default()
            .lookup(&self.oui)
            .map(|v| v.to_string())
    }

    fn to_hex_string(&self) -> String {
        self.oui.to_string_hex()
    }
}

impl Bssid {
    fn parse(input: &str) -> Result<Bssid, ffi::LinkError> {
        crate::bssid::BSSID::parse(input)
            .map(|bssid| Bssid { bssid })
            .map_err(|_| ffi::LinkError::InvalidFormat)
    }

    fn to_string(&self) -> String {
        self.bssid.to_string_colon()
    }

    fn to_mac(&self) -> MACAddress {
        MACAddress {
            mac: self.bssid.mac(),
        }
    }

    fn is_hidden_ssid_indicator(&self) -> bool {
        self.bssid.is_hidden_ssid_indicator()
    }
}

impl Ssid {
    fn parse(input: &str) -> Result<Ssid, ffi::LinkError> {
        crate::ssid::SSID::parse(input)
            .map(|ssid| Ssid { ssid })
            .map_err(|_| ffi::LinkError::InvalidFormat)
    }

    fn to_string(&self) -> String {
        self.ssid.to_string()
    }

    fn is_hidden(&self) -> bool {
        self.ssid.is_hidden()
    }

    fn is_valid(&self) -> bool {
        self.ssid.is_valid()
    }

    fn is_carrier_wifi(&self) -> bool {
        self.ssid.is_carrier_wifi()
    }

    fn is_public_hotspot(&self) -> bool {
        self.ssid.is_public_hotspot()
    }
}

// Standalone functions
fn mac_random_local() -> MACAddress {
    MACAddress {
        mac: crate::mac::MAC::random_local(),
    }
}

fn mac_random_with_vendor(vendor_id: &str) -> Option<MACAddress> {
    crate::vendor::VendorDatabase::default()
        .random_mac_for_vendor(vendor_id)
        .map(|mac| MACAddress { mac })
}

// Batch operations
fn batch_validate_macs(addrs: Vec<String>) -> Vec<bool> {
    crate::batch::MacBatch::validate_multiple(addrs)
}

fn batch_normalize_macs(addrs: Vec<String>) -> Vec<String> {
    crate::batch::MacBatch::normalize_multiple(addrs)
}

fn batch_anonymize_macs(addrs: Vec<String>) -> Vec<String> {
    crate::batch::MacBatch::anonymize_multiple(addrs)
}

fn batch_generate_local_macs(count: usize) -> Vec<String> {
    crate::batch::RandomBatch::generate_local_multiple(count)
}

fn batch_generate_vendor_macs(vendor_id: &str, count: usize) -> Vec<String> {
    crate::batch::RandomBatch::generate_for_vendor_multiple(vendor_id, count)
}

fn mac_similarity_score(mac1: &str, mac2: &str) -> Option<f64> {
    crate::batch::MacSimilarity::score(mac1, mac2)
}

fn mac_are_same_vendor(mac1: &str, mac2: &str) -> bool {
    crate::batch::MacSimilarity::are_same_vendor(mac1, mac2)
}
