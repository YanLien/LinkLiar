//! Batch operations for MAC addresses and OUI lookups
//!
//! This module provides high-performance batch operations for processing
//! multiple MAC addresses or OUI lookups at once.

use crate::mac::MAC;
use crate::oui::OUI;
use crate::vendor::VendorDatabase;

/// Batch operations for MAC addresses
pub struct MacBatch;

impl MacBatch {
    /// Validate multiple MAC addresses at once
    ///
    /// # Arguments
    /// * `addrs` - Vector of MAC address strings to validate
    ///
    /// # Returns
    /// Vector of booleans indicating validity (same order as input)
    ///
    /// # Example
    /// ```
    /// let results = MacBatch::validate_multiple(vec![
    ///     "AA:BB:CC:DD:EE:FF",
    ///     "invalid",
    /// ]);
    /// // Returns: vec![true, false]
    /// ```
    pub fn validate_multiple(addrs: Vec<String>) -> Vec<bool> {
        addrs.into_iter()
            .map(|addr| MAC::parse(&addr).is_ok())
            .collect()
    }

    /// Normalize multiple MAC addresses at once
    ///
    /// # Arguments
    /// * `addrs` - Vector of MAC address strings to normalize
    ///
    /// # Returns
    /// Vector of normalized MAC addresses (or empty strings if invalid)
    ///
    /// # Example
    /// ```
    /// let results = MacBatch::normalize_multiple(vec![
    ///     "aa-bb-cc-dd-ee-ff",
    ///     "aabbccddeeff",
    /// ]);
    /// // Returns: vec!["aa:bb:cc:dd:ee:ff", "aa:bb:cc:dd:ee:ff"]
    /// ```
    pub fn normalize_multiple(addrs: Vec<String>) -> Vec<String> {
        addrs.into_iter()
            .map(|addr| {
                MAC::parse(&addr)
                    .map(|mac| mac.to_string_colon())
                    .unwrap_or_default()
            })
            .collect()
    }

    /// Anonymize multiple MAC addresses at once
    ///
    /// # Arguments
    /// * `addrs` - Vector of MAC address strings to anonymize
    ///
    /// # Returns
    /// Vector of anonymized MAC addresses (format: "AA:BB:CC:XX:XX:XX")
    pub fn anonymize_multiple(addrs: Vec<String>) -> Vec<String> {
        addrs.into_iter()
            .map(|addr| {
                MAC::parse(&addr)
                    .map(|mac| mac.anonymize())
                    .unwrap_or_default()
            })
            .collect()
    }

    /// Extract OUIs from multiple MAC addresses at once
    ///
    /// # Arguments
    /// * `addrs` - Vector of MAC address strings
    ///
    /// # Returns
    /// Vector of OUI hex strings (or empty strings if invalid)
    pub fn extract_ouis_multiple(addrs: Vec<String>) -> Vec<String> {
        addrs.into_iter()
            .map(|addr| {
                MAC::parse(&addr)
                    .map(|mac| OUI::new(mac.oui()).to_string_hex())
                    .unwrap_or_default()
            })
            .collect()
    }
}

/// Batch operations for OUI lookups
pub struct OuiBatch;

impl OuiBatch {
    /// Lookup vendors for multiple OUIs at once
    ///
    /// # Arguments
    /// * `oui_hex_strings` - Vector of OUI hex strings (6 hex digits)
    ///
    /// # Returns
    /// Vector of optional vendor names (None if not found)
    ///
    /// # Example
    /// ```
    /// let results = OuiBatch::lookup_multiple(vec![
    ///     "00393e",  // Apple
    ///     "000000",  // Xerox
    /// ]);
    /// // Returns: vec![Some("Apple"), Some("Xerox")]
    /// ```
    pub fn lookup_multiple(oui_hex_strings: Vec<String>) -> Vec<Option<String>> {
        let db = VendorDatabase::default();

        oui_hex_strings.into_iter()
            .map(|hex| {
                OUI::parse(&hex)
                    .ok()
                    .and_then(|oui| db.lookup(&oui).map(|v| v.to_string()))
            })
            .collect()
    }

    /// Lookup vendors for multiple MAC addresses at once
    ///
    /// # Arguments
    /// * `mac_addrs` - Vector of MAC address strings
    ///
    /// # Returns
    /// Vector of optional vendor names (None if invalid or not found)
    pub fn lookup_by_mac_multiple(mac_addrs: Vec<String>) -> Vec<Option<String>> {
        let db = VendorDatabase::default();

        mac_addrs.into_iter()
            .map(|addr| {
                MAC::parse(&addr)
                    .ok()
                    .and_then(|mac| {
                        let oui_bytes = mac.oui();
                        let oui = OUI::new(oui_bytes);
                        db.lookup(&oui).map(|v| v.to_string())
                    })
            })
            .collect()
    }

    /// Count OUIs per vendor from a list of MAC addresses
    ///
    /// # Arguments
    /// * `mac_addrs` - Vector of MAC address strings
    ///
    /// # Returns
    /// Vector of (vendor_name, count) tuples, sorted by count descending
    pub fn count_vendors(mac_addrs: Vec<String>) -> Vec<(String, usize)> {
        use std::collections::HashMap;

        let db = VendorDatabase::default();
        let mut counts: HashMap<String, usize> = HashMap::new();

        for addr in mac_addrs {
            if let Ok(mac) = MAC::parse(&addr) {
                let oui_bytes = mac.oui();
                let oui = OUI::new(oui_bytes);
                if let Some(vendor) = db.lookup(&oui) {
                    let vendor_name = vendor.to_string();
                    *counts.entry(vendor_name).or_insert(0) += 1;
                }
            }
        }

        let mut result: Vec<(String, usize)> = counts.into_iter().collect();
        result.sort_by(|a, b| b.1.cmp(&a.1));
        result
    }
}

/// Batch operations for generating random MAC addresses
pub struct RandomBatch;

impl RandomBatch {
    /// Generate multiple random local MAC addresses
    ///
    /// # Arguments
    /// * `count` - Number of MAC addresses to generate
    ///
    /// # Returns
    /// Vector of random MAC address strings
    pub fn generate_local_multiple(count: usize) -> Vec<String> {
        (0..count)
            .map(|_| MAC::random_local().to_string_colon())
            .collect()
    }

    /// Generate multiple random MAC addresses for a specific vendor
    ///
    /// # Arguments
    /// * `vendor_id` - Vendor identifier
    /// * `count` - Number of MAC addresses to generate
    ///
    /// # Returns
    /// Vector of random MAC address strings for that vendor
    ///
    /// # Example
    /// ```
    /// let macs = RandomBatch::generate_for_vendor_multiple("apple", 5);
    /// // Returns 5 random MAC addresses with Apple OUI
    /// ```
    pub fn generate_for_vendor_multiple(vendor_id: &str, count: usize) -> Vec<String> {
        let db = VendorDatabase::default();

        (0..count)
            .filter_map(|_| {
                db.random_mac_for_vendor(vendor_id)
                    .map(|mac| mac.to_string_colon())
            })
            .collect()
    }

    /// Generate random MAC addresses for multiple vendors
    ///
    /// # Arguments
    /// * `vendor_ids` - Vector of vendor identifiers
    /// * `per_vendor` - Number of MAC addresses to generate per vendor
    ///
    /// # Returns
    /// Vector of (vendor_id, mac_address) tuples
    pub fn generate_for_multiple_vendors(
        vendor_ids: Vec<String>,
        per_vendor: usize,
    ) -> Vec<(String, String)> {
        let db = VendorDatabase::default();
        let mut result = Vec::new();

        for vendor_id in vendor_ids {
            for _ in 0..per_vendor {
                if let Some(mac) = db.random_mac_for_vendor(&vendor_id) {
                    result.push((vendor_id.clone(), mac.to_string_colon()));
                }
            }
        }

        result
    }
}

/// Utility for calculating MAC address similarity
pub struct MacSimilarity;

impl MacSimilarity {
    /// Calculate similarity score between two MAC addresses
    ///
    /// Returns a value from 0.0 (completely different) to 1.0 (identical)
    ///
    /// # Arguments
    /// * `mac1` - First MAC address string
    /// * `mac2` - Second MAC address string
    ///
    /// # Returns
    /// Similarity score as f64, or None if either MAC is invalid
    pub fn score(mac1: &str, mac2: &str) -> Option<f64> {
        let m1 = MAC::parse(mac1).ok()?;
        let m2 = MAC::parse(mac2).ok()?;

        let b1 = m1.bytes();
        let b2 = m2.bytes();

        // Calculate byte-by-byte similarity
        let matching_bytes = b1.iter()
            .zip(b2.iter())
            .filter(|(a, b)| a == b)
            .count();

        // Each matching byte contributes 1/6 to the score
        Some(matching_bytes as f64 / 6.0)
    }

    /// Check if two MAC addresses belong to the same vendor (same OUI)
    ///
    /// # Arguments
    /// * `mac1` - First MAC address string
    /// * `mac2` - Second MAC address string
    ///
    /// # Returns
    /// true if both MACs have the same OUI
    pub fn are_same_vendor(mac1: &str, mac2: &str) -> bool {
        if let (Ok(m1), Ok(m2)) = (MAC::parse(mac1), MAC::parse(mac2)) {
            m1.oui() == m2.oui()
        } else {
            false
        }
    }

    /// Find MAC addresses that are "near" a given MAC (same vendor)
    ///
    /// # Arguments
    /// * `target_mac` - Target MAC address
    /// * `candidates` - List of candidate MAC addresses
    /// * `threshold` - Minimum similarity threshold (0.0-1.0)
    ///
    /// # Returns
    /// Vector of (mac_address, similarity_score) tuples that meet the threshold
    pub fn find_nearby(
        target_mac: &str,
        candidates: Vec<String>,
        threshold: f64,
    ) -> Vec<(String, f64)> {
        let mut result = Vec::new();

        for candidate in candidates {
            if let Some(score) = Self::score(target_mac, &candidate) {
                if score >= threshold {
                    result.push((candidate, score));
                }
            }
        }

        result.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        result
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_multiple() {
        let results = MacBatch::validate_multiple(vec![
            "AA:BB:CC:DD:EE:FF".to_string(),
            "invalid".to_string(),
            "00:11:22:33:44:55".to_string(),
        ]);
        assert_eq!(results, vec![true, false, true]);
    }

    #[test]
    fn test_normalize_multiple() {
        let results = MacBatch::normalize_multiple(vec![
            "aa-bb-cc-dd-ee-ff".to_string(),
            "AABBCCDDEEFF".to_string(),
        ]);
        assert_eq!(results, vec!["aa:bb:cc:dd:ee:ff", "aa:bb:cc:dd:ee:ff"]);
    }

    #[test]
    fn test_similarity_score() {
        let score = MacSimilarity::score("AA:BB:CC:DD:EE:FF", "AA:BB:CC:11:22:33").unwrap();
        assert!((score - 0.5).abs() < 0.01); // First 3 bytes match
    }

    #[test]
    fn test_are_same_vendor() {
        assert!(MacSimilarity::are_same_vendor(
            "AA:BB:CC:DD:EE:FF",
            "AA:BB:CC:11:22:33"
        ));
        assert!(!MacSimilarity::are_same_vendor(
            "AA:BB:CC:DD:EE:FF",
            "11:22:33:DD:EE:FF"
        ));
    }
}
