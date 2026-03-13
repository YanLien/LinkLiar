//! Vendor database for OUI (MAC prefix) to vendor name lookup.
//!
//! The database maps OUI prefixes to manufacturer names.
//! Popular vendors are dynamically computed from the loaded database.

use crate::{MAC, OUI};
use std::collections::{BTreeMap, HashMap};

/// Name normalization: maps raw names to shorter display names.
const NORMALIZE_MAP: &[(&str, &str)] = &[
    ("Cisco Systems", "Cisco"),
    ("Huawei Technologies", "Huawei"),
    ("Samsung Electronics", "Samsung"),
    ("Hewlett Packard", "HP"),
    ("TP-LINK Technologies", "TP-Link"),
    ("Lg Electronics Mobile Communications", "LG"),
    ("Vivo Mobile Communication", "Vivo"),
    ("Asustek Computer", "Asustek"),
    ("Sony Mobile Communications", "Sony"),
    ("Motorola Mobility Llc A Lenovo Company", "Motorola"),
    ("D-link International", "D-link"),
    ("Xiaomi Communications", "Xiaomi"),
];

/// Vendor names excluded from popular vendors (not consumer devices).
const DENYLIST: &[&str] = &[
    "Arris",
    "IEEE",
    "Foxconn",
    "Juniper",
    "Fiberhome",
    "Sagemcom",
    "Private",
    "Guangdong",
    "Nortel",
    "Amazon",
    "Ruckus",
    "Technicolor",
    "Liteon",
    "Avaya",
    "Espressif",
];

/// Special vendors to always include regardless of prefix count.
const ALWAYS_INCLUDE: &[&str] = &[
    "Coca Cola Company",
    "Nintendo",
    "3com",
    "HTC",
    "Ibm",
    "Ericsson",
];

/// Apply name normalization to a raw vendor name.
pub fn normalize_name(raw: &str) -> &str {
    for &(from, to) in NORMALIZE_MAP {
        if raw == from {
            return to;
        }
    }
    raw
}

/// Generate a vendor ID from a vendor name.
pub fn vendor_id_from_name(name: &str) -> String {
    if name.contains("Coca") {
        return "cocacola".to_string();
    }
    let cleaned: String = name
        .chars()
        .filter(|c| c.is_alphanumeric() || *c == ' ')
        .collect::<String>()
        .to_lowercase();
    cleaned
        .split_whitespace()
        .next()
        .unwrap_or("unknown")
        .to_string()
}

/// Vendor database for OUI lookup
pub struct VendorDatabase {
    oui_to_name: HashMap<String, String>,
}

/// Popular vendor information (for FFI)
#[derive(Debug, Clone, serde::Serialize)]
pub struct PopularVendorInfo {
    pub id: String,
    pub name: String,
    #[serde(rename = "prefixCount")]
    pub prefix_count: usize,
}

impl VendorDatabase {
    /// Create an empty database
    pub fn new() -> Self {
        Self {
            oui_to_name: HashMap::new(),
        }
    }

    /// Create database from JSON (oui.json format: {"xx:xx:xx": "Vendor", ...})
    pub fn from_json(json: &str) -> Result<Self, serde_json::Error> {
        let oui_to_name: HashMap<String, String> = serde_json::from_str(json)?;
        Ok(Self { oui_to_name })
    }

    /// Create database from mac2vendor.com PREFIX=Vendor format.
    /// Applies name normalization but not denylist (denylist is for popular filtering only).
    pub fn from_vendor_props(data: &str) -> Self {
        let mut oui_to_name = HashMap::new();

        for line in data.lines() {
            if line.starts_with('*') || line.is_empty() {
                continue;
            }

            let Some((prefix, raw_name)) = line.split_once('=') else {
                continue;
            };

            let name = normalize_name(raw_name.trim()).to_string();

            let hex: String = prefix
                .trim()
                .chars()
                .filter(|c| c.is_ascii_hexdigit())
                .collect::<String>()
                .to_lowercase();

            if hex.len() >= 6 {
                let oui = format!("{}:{}:{}", &hex[0..2], &hex[2..4], &hex[4..6]);
                oui_to_name.insert(oui, name);
            }
        }

        Self { oui_to_name }
    }

    /// Download vendor data from URL, parse, save as oui.json, return new database and entry count.
    pub fn fetch_and_save(
        url: &str,
        output_path: &str,
    ) -> Result<(Self, usize), Box<dyn std::error::Error>> {
        let body = ureq::get(url).call()?.into_string()?;
        let db = Self::from_vendor_props(&body);
        let json = db.to_oui_json();

        // Ensure parent directory exists
        if let Some(parent) = std::path::Path::new(output_path).parent() {
            std::fs::create_dir_all(parent)?;
        }

        std::fs::write(output_path, &json)?;
        let count = db.len();
        Ok((db, count))
    }

    /// Dynamically compute popular vendors by counting OUIs per vendor.
    /// Returns vendors with at least `min_count` OUI prefixes (plus always-included vendors).
    pub fn popular_vendors(&self, min_count: usize) -> Vec<PopularVendorInfo> {
        // Count OUIs per vendor name
        let mut name_counts: HashMap<&str, usize> = HashMap::new();
        for name in self.oui_to_name.values() {
            *name_counts.entry(name.as_str()).or_default() += 1;
        }

        // Filter and group by vendor ID
        let mut id_map: HashMap<String, PopularVendorInfo> = HashMap::new();

        for (name, &count) in &name_counts {
            // Skip "Huawei Device" special case
            if *name == "Huawei Device" {
                continue;
            }

            let is_always_include = ALWAYS_INCLUDE.iter().any(|s| *s == *name);
            let is_denied = DENYLIST.iter().any(|d| name.contains(d));

            if !is_always_include && (is_denied || count < min_count) {
                continue;
            }

            let id = vendor_id_from_name(name);

            let entry = id_map
                .entry(id.clone())
                .or_insert_with(|| PopularVendorInfo {
                    id,
                    name: name.to_string(),
                    prefix_count: 0,
                });
            entry.prefix_count += count;
        }

        let mut result: Vec<PopularVendorInfo> = id_map.into_values().collect();
        result.sort_by(|a, b| b.prefix_count.cmp(&a.prefix_count));
        result
    }

    /// Get all OUI prefixes for a given vendor ID.
    pub fn vendor_ouis(&self, target_vendor_id: &str) -> Vec<OUI> {
        let mut ouis: Vec<OUI> = self
            .oui_to_name
            .iter()
            .filter(|(_, name)| vendor_id_from_name(name) == target_vendor_id)
            .filter_map(|(oui_str, _)| OUI::parse(oui_str).ok())
            .collect();
        ouis.sort();
        ouis
    }

    /// Serialize database to oui.json format.
    pub fn to_oui_json(&self) -> String {
        let sorted: BTreeMap<&str, &str> = self
            .oui_to_name
            .iter()
            .map(|(k, v)| (k.as_str(), v.as_str()))
            .collect();
        serde_json::to_string(&sorted).unwrap()
    }

    /// Lookup vendor name by OUI
    pub fn lookup(&self, oui: &OUI) -> Option<&str> {
        let key = oui.to_string_colon();
        self.oui_to_name.get(&key).map(|s| s.as_str())
    }

    /// Lookup vendor name by MAC address
    pub fn lookup_by_mac(&self, mac: &MAC) -> Option<&str> {
        let oui = OUI::new(mac.oui());
        self.lookup(&oui)
    }

    /// Generate a random MAC address for a specific vendor
    pub fn random_mac_for_vendor(&self, vendor_id: &str) -> Option<MAC> {
        let ouis = self.vendor_ouis(vendor_id);
        if ouis.is_empty() {
            return None;
        }

        use rand::seq::SliceRandom;
        let oui = ouis.choose(&mut rand::thread_rng())?;
        Some(MAC::random_with_oui(oui.bytes()))
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
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_normalize_name() {
        assert_eq!(normalize_name("Cisco Systems"), "Cisco");
        assert_eq!(normalize_name("Samsung Electronics"), "Samsung");
        assert_eq!(normalize_name("Apple"), "Apple");
    }

    #[test]
    fn test_vendor_id_from_name() {
        assert_eq!(vendor_id_from_name("Apple"), "apple");
        assert_eq!(vendor_id_from_name("Cisco"), "cisco");
        assert_eq!(vendor_id_from_name("Coca Cola Company"), "cocacola");
        assert_eq!(vendor_id_from_name("Texas Instruments"), "texas");
    }

    #[test]
    fn test_lookup() {
        let json = r#"{"00:03:93":"Apple","00:00:0c":"Cisco"}"#;
        let db = VendorDatabase::from_json(json).unwrap();

        let oui = OUI::parse("00:03:93").unwrap();
        assert_eq!(db.lookup(&oui), Some("Apple"));

        let oui2 = OUI::parse("00:00:0c").unwrap();
        assert_eq!(db.lookup(&oui2), Some("Cisco"));
    }

    #[test]
    fn test_from_vendor_props() {
        let data = "000393=Apple\n000502=Apple\n00000C=Cisco Systems\n";
        let db = VendorDatabase::from_vendor_props(data);

        let oui = OUI::parse("00:03:93").unwrap();
        assert_eq!(db.lookup(&oui), Some("Apple"));

        // Cisco Systems should be normalized to Cisco
        let cisco_oui = OUI::parse("00:00:0C").unwrap();
        assert_eq!(db.lookup(&cisco_oui), Some("Cisco"));

        assert_eq!(db.len(), 3);
    }

    #[test]
    fn test_from_vendor_props_skips_comments() {
        let data = "* This is a comment\n000393=Apple\n\n000502=Apple\n";
        let db = VendorDatabase::from_vendor_props(data);
        assert_eq!(db.len(), 2);
    }

    #[test]
    fn test_popular_vendors() {
        // Build a database with enough entries for Apple to be "popular"
        let mut entries = Vec::new();
        for i in 0..60 {
            entries.push(format!("{:06x}=Apple", i));
        }
        for i in 100..110 {
            entries.push(format!("{:06x}=SmallVendor", i));
        }
        let data = entries.join("\n");
        let db = VendorDatabase::from_vendor_props(&data);

        let popular = db.popular_vendors(50);
        assert_eq!(popular.len(), 1);
        assert_eq!(popular[0].name, "Apple");
        assert_eq!(popular[0].prefix_count, 60);
    }

    #[test]
    fn test_popular_vendors_always_include() {
        // Nintendo should be included even with few prefixes
        let data = "000001=Nintendo\n000002=Nintendo\n";
        let db = VendorDatabase::from_vendor_props(&data);

        let popular = db.popular_vendors(50);
        assert!(popular.iter().any(|v| v.name == "Nintendo"));
    }

    #[test]
    fn test_popular_vendors_denylist() {
        // Build enough prefixes for Foxconn, but it should be excluded
        let mut entries = Vec::new();
        for i in 0..60 {
            entries.push(format!("{:06x}=Foxconn", i));
        }
        let data = entries.join("\n");
        let db = VendorDatabase::from_vendor_props(&data);

        let popular = db.popular_vendors(50);
        assert!(popular.is_empty());
    }

    #[test]
    fn test_vendor_ouis() {
        let data = "000393=Apple\n000502=Apple\n00000C=Cisco\n";
        let db = VendorDatabase::from_vendor_props(&data);

        let apple_ouis = db.vendor_ouis("apple");
        assert_eq!(apple_ouis.len(), 2);

        let cisco_ouis = db.vendor_ouis("cisco");
        assert_eq!(cisco_ouis.len(), 1);
    }

    #[test]
    fn test_to_oui_json() {
        let data = "000393=Apple\n00000C=Cisco Systems\n";
        let db = VendorDatabase::from_vendor_props(&data);

        let json = db.to_oui_json();
        let parsed: HashMap<String, String> = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed.get("00:03:93"), Some(&"Apple".to_string()));
        assert_eq!(parsed.get("00:00:0c"), Some(&"Cisco".to_string()));
    }

    #[test]
    fn test_random_mac_for_vendor() {
        let data = "000393=Apple\n000502=Apple\n";
        let db = VendorDatabase::from_vendor_props(&data);

        let mac = db.random_mac_for_vendor("apple");
        assert!(mac.is_some());

        let mac = mac.unwrap();
        let oui_hex = format!(
            "{:02x}:{:02x}:{:02x}",
            mac.bytes()[0],
            mac.bytes()[1],
            mac.bytes()[2]
        );
        // Should be one of Apple's OUIs
        assert!(oui_hex == "00:03:93" || oui_hex == "00:05:02");
    }

    #[test]
    fn test_random_mac_for_unknown_vendor() {
        let db = VendorDatabase::new();
        assert!(db.random_mac_for_vendor("unknown").is_none());
    }
}
