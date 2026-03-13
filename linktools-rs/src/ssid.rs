//! SSID (Service Set Identifier) module
//!
//! An SSID is the name of a wireless network.

use std::fmt;

/// Represents an SSID (network name)
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct SSID {
    name: String,
}

impl SSID {
    /// Parse an SSID from a string
    ///
    /// # Arguments
    /// * `input` - SSID string
    ///
    /// # Returns
    /// * `Ok(SSID)` if valid
    /// * `Err(ParseError)` if invalid
    pub fn parse(input: &str) -> Result<Self, ParseError> {
        if input.is_empty() {
            return Ok(SSID { name: String::new() });
        }

        // SSID can be 1-32 bytes (UTF-8 encoded)
        if input.len() > 32 {
            return Err(ParseError::TooLong);
        }

        // Check for valid UTF-8
        if !input.is_char_boundary(input.len()) {
            return Err(ParseError::InvalidUtf8);
        }

        Ok(SSID {
            name: input.to_string(),
        })
    }

    /// Create a new SSID
    pub fn new(name: String) -> Self {
        SSID { name }
    }

    /// Get the SSID name
    pub fn as_str(&self) -> &str {
        &self.name
    }

    /// Convert to string
    pub fn to_string(&self) -> String {
        self.name.clone()
    }

    /// Check if this is a hidden SSID (empty name)
    pub fn is_hidden(&self) -> bool {
        self.name.is_empty()
    }

    /// Check if SSID is valid
    pub fn is_valid(&self) -> bool {
        !self.name.is_empty() && self.name.len() <= 32
    }

    /// Get the length in bytes
    pub fn len(&self) -> usize {
        self.name.len()
    }

    /// Check if empty
    pub fn is_empty(&self) -> bool {
        self.name.is_empty()
    }

    /// Get SSID as bytes
    pub fn as_bytes(&self) -> &[u8] {
        self.name.as_bytes()
    }

    /// Calculate signal strength indicator based on SSID properties
    /// Returns a score from 0-100
    pub fn signal_quality_score(&self) -> u8 {
        if self.is_hidden() {
            return 50; // Hidden networks get lower score
        }

        let mut score = 70;

        // Bonus for longer names (often indicates better setup)
        if self.len() >= 8 {
            score += 10;
        }

        // Penalty for very short names
        if self.len() < 3 {
            score -= 20;
        }

        score.min(100)
    }

    /// Check if this looks like a carrier/ISP WiFi (heuristic)
    pub fn is_carrier_wifi(&self) -> bool {
        let lower = self.name.to_lowercase();
        let carriers = [
            "att", "at&t", "verizon", "comcast", "xfinity", "spectrum",
            "cox", "optimum", "tim", "vodafone", "telekom", "orange",
            "sfr", "bouygues", "free", "proximus", "telenet",
        ];

        carriers.iter().any(|&carrier| lower.contains(carrier))
    }

    /// Check if this looks like a public hotspot (heuristic)
    pub fn is_public_hotspot(&self) -> bool {
        let lower = self.name.to_lowercase();
        let hotspot_keywords = [
            "guest", "public", "visitor", "open", "free", "wifi",
            "hotspot", "_5G", "extension",
        ];

        hotspot_keywords.iter().any(|&keyword| lower.contains(keyword))
    }
}

impl fmt::Display for SSID {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if self.is_hidden() {
            write!(f, "<Hidden>")
        } else {
            write!(f, "{}", self.name)
        }
    }
}

/// Errors that can occur during SSID parsing
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ParseError {
    TooLong,
    InvalidUtf8,
}

impl std::error::Error for ParseError {}

impl fmt::Display for ParseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ParseError::TooLong => write!(f, "SSID too long (max 32 bytes)"),
            ParseError::InvalidUtf8 => write!(f, "Invalid UTF-8 in SSID"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_valid_ssid() {
        let ssid = SSID::parse("MyNetwork").unwrap();
        assert_eq!(ssid.as_str(), "MyNetwork");
    }

    #[test]
    fn test_parse_too_long_ssid() {
        assert!(SSID::parse(&"a".repeat(33)).is_err());
    }

    #[test]
    fn test_hidden_ssid() {
        let ssid = SSID::parse("").unwrap();
        assert!(ssid.is_hidden());
    }

    #[test]
    fn test_is_carrier_wifi() {
        let ssid = SSID::parse("ATT-WiFi").unwrap();
        assert!(ssid.is_carrier_wifi());
    }

    #[test]
    fn test_is_public_hotspot() {
        let ssid = SSID::parse("Hotel_Guest").unwrap();
        assert!(ssid.is_public_hotspot());
    }
}
