//! BSSID (Basic Service Set Identifier) module
//!
//! A BSSID is the MAC address of a wireless access point.

use crate::mac::MAC;
use crate::oui::OUI;
use std::fmt;

/// Represents a BSSID (MAC address of a wireless access point)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct BSSID {
    mac: [u8; 6],
}

impl BSSID {
    /// Parse a BSSID from a string
    ///
    /// # Arguments
    /// * `input` - String representation of the BSSID (e.g., "AA:BB:CC:DD:EE:FF")
    ///
    /// # Returns
    /// * `Ok(BSSID)` if parsing succeeds
    /// * `Err(ParseError)` if parsing fails
    ///
    /// # Example
    /// ```
    /// let bssid = BSSID::parse("AA:BB:CC:DD:EE:FF")?;
    /// ```
    pub fn parse(input: &str) -> Result<Self, ParseError> {
        let mac = MAC::parse(input).map_err(|_| ParseError::InvalidFormat)?;
        Ok(BSSID { mac: mac.bytes() })
    }

    /// Create a new BSSID from raw bytes
    pub fn from_bytes(bytes: [u8; 6]) -> Self {
        BSSID { mac: bytes }
    }

    /// Get the underlying MAC address
    pub fn mac(&self) -> MAC {
        MAC::new(self.mac)
    }

    /// Convert to colon-separated string
    pub fn to_string_colon(&self) -> String {
        self.mac().to_string_colon()
    }

    /// Convert to hyphen-separated string (Windows format)
    pub fn to_string_hyphen(&self) -> String {
        self.mac().to_string_hyphen()
    }

    /// Convert to dot-separated string (Cisco format)
    pub fn to_string_dot(&self) -> String {
        self.mac().to_string_hyphen()
    }

    /// Get the OUI portion of the BSSID
    pub fn oui(&self) -> OUI {
        OUI::new([self.mac[0], self.mac[1], self.mac[2]])
    }

    /// Check if this is a hidden SSID BSSID (ends with :00:00:00)
    pub fn is_hidden_ssid_indicator(&self) -> bool {
        self.mac[3] == 0 && self.mac[4] == 0 && self.mac[5] == 0
    }

    /// Get the raw bytes
    pub fn bytes(&self) -> [u8; 6] {
        self.mac
    }

    /// Calculate signal quality score based on BSSID pattern
    /// Returns a score from 0-100 based on vendor reputation
    pub fn vendor_quality_score(&self) -> u8 {
        // This is a placeholder - would need vendor reputation data
        75
    }
}

impl fmt::Display for BSSID {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.to_string_colon())
    }
}

/// Errors that can occur during BSSID parsing
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ParseError {
    InvalidLength,
    InvalidHex,
    InvalidFormat,
}

impl std::error::Error for ParseError {}

impl fmt::Display for ParseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ParseError::InvalidLength => write!(f, "Invalid BSSID length"),
            ParseError::InvalidHex => write!(f, "Invalid hexadecimal character"),
            ParseError::InvalidFormat => write!(f, "Invalid BSSID format"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_valid_bssid() {
        let bssid = BSSID::parse("AA:BB:CC:DD:EE:FF").unwrap();
        assert_eq!(bssid.to_string_colon(), "aa:bb:cc:dd:ee:ff");
    }

    #[test]
    fn test_parse_invalid_bssid() {
        assert!(BSSID::parse("invalid").is_err());
    }

    #[test]
    fn test_oui_extraction() {
        let bssid = BSSID::parse("AA:BB:CC:DD:EE:FF").unwrap();
        let oui = bssid.oui();
        assert_eq!(oui.to_string_hex(), "aabbcc");
    }
}
