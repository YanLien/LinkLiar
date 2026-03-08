//! Vendor database for OUI (MAC prefix) to vendor name lookup.
//!
//! The database maps OUI prefixes to manufacturer names.
//! Popular vendors are hardcoded for fast lookup without loading the full database.

use crate::{MAC, OUI};
use std::collections::HashMap;

/// Vendor database for OUI lookup
pub struct VendorDatabase {
    oui_to_name: HashMap<String, String>,
    popular_vendors: HashMap<String, VendorInfo>,
}

/// Vendor information
#[derive(Debug, Clone)]
pub struct VendorInfo {
    pub id: String,
    pub name: String,
    pub prefix_count: usize,
    pub prefixes: Vec<OUI>,
}

impl VendorDatabase {
    /// Create an empty database
    pub fn new() -> Self {
        Self {
            oui_to_name: HashMap::new(),
            popular_vendors: HashMap::new(),
        }
    }

    /// Create database from JSON (oui.json format)
    pub fn from_json(json: &str) -> Result<Self, serde_json::Error> {
        let oui_to_name: HashMap<String, String> = serde_json::from_str(json)?;
        Ok(Self {
            oui_to_name,
            popular_vendors: HashMap::new(),
        })
    }

    /// Load popular vendors (hardcoded for performance)
    pub fn load_popular_vendors(&mut self) {
        let vendors = vec![
            ("apple", "Apple", vec![
                OUI::parse("000393").unwrap(),
                OUI::parse("000502").unwrap(),
                OUI::parse("000A27").unwrap(),
                OUI::parse("000A95").unwrap(),
                OUI::parse("000D93").unwrap(),
            ]),
            ("cisco", "Cisco", vec![
                OUI::parse("00000C").unwrap(),
                OUI::parse("000142").unwrap(),
                OUI::parse("000143").unwrap(),
            ]),
            ("google", "Google", vec![
                OUI::parse("001A11").unwrap(),
                OUI::parse("00F620").unwrap(),
                OUI::parse("089E08").unwrap(),
            ]),
            ("samsung", "Samsung", vec![
                OUI::parse("0000F0").unwrap(),
                OUI::parse("0007AB").unwrap(),
                OUI::parse("001247").unwrap(),
            ]),
        ];

        for (id, name, prefixes) in vendors {
            // Also populate oui_to_name for lookup
            for prefix in &prefixes {
                self.oui_to_name.insert(prefix.to_string_hex(), name.to_string());
            }
            let vendor = VendorInfo {
                id: id.to_string(),
                name: name.to_string(),
                prefix_count: prefixes.len(),
                prefixes,
            };
            self.popular_vendors.insert(id.to_string(), vendor);
        }
    }

    /// Lookup vendor name by OUI
    pub fn lookup(&self, oui: &OUI) -> Option<&str> {
        let key = oui.to_string_hex();
        self.oui_to_name.get(&key).map(|s| s.as_str())
    }

    /// Lookup vendor name by MAC address
    pub fn lookup_by_mac(&self, mac: &MAC) -> Option<&str> {
        let oui = OUI::new(mac.oui());
        self.lookup(&oui)
    }

    /// Get popular vendor by ID
    pub fn get_vendor(&self, id: &str) -> Option<&VendorInfo> {
        self.popular_vendors.get(id)
    }

    /// Get all popular vendors
    pub fn all_vendors(&self) -> Vec<&VendorInfo> {
        let mut vendors: Vec<_> = self.popular_vendors.values().collect();
        vendors.sort_by(|a, b| a.name.cmp(&b.name));
        vendors
    }

    /// Generate a random MAC address for a specific vendor
    pub fn random_mac_for_vendor(&self, vendor_id: &str) -> Option<MAC> {
        let vendor = self.get_vendor(vendor_id)?;
        
        if vendor.prefixes.is_empty() {
            return None;
        }

        // Pick a random OUI from the vendor
        use rand::seq::SliceRandom;
        let oui = vendor.prefixes.choose(&mut rand::thread_rng())?;
        
        // Generate random NIC part
        Some(MAC::random_with_oui(oui.as_bytes().clone()))
    }

    /// Get the number of OUI entries
    pub fn len(&self) -> usize {
        self.oui_to_name.len()
    }

    /// Check if database is empty
    pub fn is_empty(&self) -> bool {
        self.oui_to_name.is_empty()
    }
}

impl Default for VendorDatabase {
    fn default() -> Self {
        let mut db = Self::new();
        db.load_popular_vendors();
        db
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_lookup() {
        let mut db = VendorDatabase::new();
        db.oui_to_name.insert("000393".to_string(), "Apple".to_string());
        
        let oui = OUI::parse("00:03:93").unwrap();
        assert_eq!(db.lookup(&oui), Some("Apple"));
    }

    #[test]
    fn test_popular_vendors() {
        let db = VendorDatabase::default();
        
        let apple = db.get_vendor("apple").unwrap();
        assert_eq!(apple.name, "Apple");
        assert!(apple.prefixes.len() > 0);
    }

    #[test]
    fn test_random_mac_for_vendor() {
        let db = VendorDatabase::default();
        
        let mac = db.random_mac_for_vendor("apple").unwrap();
        assert!(mac.is_unicast());
    }
}
