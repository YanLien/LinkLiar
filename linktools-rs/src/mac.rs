//! MAC address parsing, formatting, and generation.
//!
//! Supports multiple input formats:
//! - Colon-separated: `AA:BB:CC:DD:EE:FF`
//! - Hyphen-separated: `AA-BB-CC-DD-EE-FF`
//! - Dot-separated: `AABB.CCDD.EEFF`
//! - No separator: `AABBCCDDEEFF`

use std::fmt;
use std::str::FromStr;

/// Represents a 48-bit MAC address
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct MAC {
    bytes: [u8; 6],
}

impl MAC {
    /// Create a new MAC address from bytes
    pub fn new(bytes: [u8; 6]) -> Self {
        Self { bytes }
    }

    /// Parse a MAC address from string
    /// Supports formats: "AA:BB:CC:DD:EE:FF", "AA-BB-CC-DD-EE-FF", "AABB.CCDD.EEFF"
    pub fn parse(input: &str) -> Result<Self, MACError> {
        let cleaned: String = input
            .chars()
            .filter(|c| c.is_ascii_alphanumeric())
            .collect();

        if cleaned.len() != 12 {
            return Err(MACError::InvalidLength(cleaned.len()));
        }

        let bytes = Self::parse_hex_bytes(&cleaned)?;
        Ok(Self { bytes })
    }

    /// Get the OUI prefix (first 3 bytes)
    pub fn oui(&self) -> [u8; 3] {
        [self.bytes[0], self.bytes[1], self.bytes[2]]
    }

    /// Get the OUI as an OUI object
    pub fn to_oui(&self) -> crate::oui::OUI {
        crate::oui::OUI::new(self.oui())
    }

    /// Get the NIC suffix (last 3 bytes)
    pub fn nic(&self) -> [u8; 3] {
        [self.bytes[3], self.bytes[4], self.bytes[5]]
    }

    /// Get formatted address with colon separator
    pub fn to_string_colon(&self) -> String {
        format!(
            "{:02X}:{:02X}:{:02X}:{:02X}:{:02X}:{:02X}",
            self.bytes[0], self.bytes[1], self.bytes[2],
            self.bytes[3], self.bytes[4], self.bytes[5]
        )
    }

    /// Get formatted address with hyphen separator
    pub fn to_string_hyphen(&self) -> String {
        format!(
            "{:02X}-{:02X}-{:02X}-{:02X}-{:02X}-{:02X}",
            self.bytes[0], self.bytes[1], self.bytes[2],
            self.bytes[3], self.bytes[4], self.bytes[5]
        )
    }

    /// Check if this is a locally administered address
    pub fn is_locally_administered(&self) -> bool {
        (self.bytes[0] & 0x02) != 0
    }

    /// Check if this is a unicast address
    pub fn is_unicast(&self) -> bool {
        (self.bytes[0] & 0x01) == 0
    }

    /// Generate a random MAC address with specific OUI
    pub fn random_with_oui(oui: [u8; 3]) -> Self {
        use rand::Rng;
        let mut rng = rand::thread_rng();
        
        Self {
            bytes: [
                oui[0],
                oui[1],
                oui[2],
                rng.r#gen(),
                rng.r#gen(),
                rng.r#gen(),
            ],
        }
    }

    /// Generate a random locally administered MAC address
    pub fn random_local() -> Self {
        use rand::Rng;
        let mut rng = rand::thread_rng();
        
        // Set locally administered bit (bit 1 of first byte)
        // Clear multicast bit (bit 0 of first byte)
        let first_byte = (rng.r#gen::<u8>() & 0xFC) | 0x02;
        
        Self {
            bytes: [
                first_byte,
                rng.r#gen(),
                rng.r#gen(),
                rng.r#gen(),
                rng.r#gen(),
                rng.r#gen(),
            ],
        }
    }

    /// Anonymize MAC address (show only prefix)
    pub fn anonymize(&self) -> String {
        format!(
            "{:02X}:{:02X}:{:02X}:XX:XX:XX",
            self.bytes[0], self.bytes[1], self.bytes[2]
        )
    }

    /// Get raw bytes
    pub fn as_bytes(&self) -> &[u8; 6] {
        &self.bytes
    }

    /// Get raw bytes as owned array
    pub fn bytes(&self) -> [u8; 6] {
        self.bytes
    }

    fn parse_hex_bytes(hex: &str) -> Result<[u8; 6], MACError> {
        let mut bytes = [0u8; 6];
        
        for i in 0..6 {
            let start = i * 2;
            let byte_str = &hex[start..start + 2];
            bytes[i] = u8::from_str_radix(byte_str, 16)
                .map_err(|_| MACError::InvalidHex(byte_str.to_string()))?;
        }
        
        Ok(bytes)
    }
}

impl fmt::Display for MAC {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.to_string_colon())
    }
}

impl FromStr for MAC {
    type Err = MACError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Self::parse(s)
    }
}

impl From<[u8; 6]> for MAC {
    fn from(bytes: [u8; 6]) -> Self {
        Self::new(bytes)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MACError {
    InvalidLength(usize),
    InvalidHex(String),
}

impl fmt::Display for MACError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            MACError::InvalidLength(len) => {
                write!(f, "Invalid MAC address length: {} (expected 12 hex chars)", len)
            }
            MACError::InvalidHex(s) => {
                write!(f, "Invalid hex string: {}", s)
            }
        }
    }
}

impl std::error::Error for MACError {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_colon() {
        let mac = MAC::parse("00:03:93:12:34:56").unwrap();
        assert_eq!(mac.to_string_colon(), "00:03:93:12:34:56");
    }

    #[test]
    fn test_parse_hyphen() {
        let mac = MAC::parse("00-03-93-12-34-56").unwrap();
        assert_eq!(mac.to_string_colon(), "00:03:93:12:34:56");
    }

    #[test]
    fn test_parse_no_separator() {
        let mac = MAC::parse("000393123456").unwrap();
        assert_eq!(mac.to_string_colon(), "00:03:93:12:34:56");
    }

    #[test]
    fn test_oui() {
        let mac = MAC::parse("00:03:93:12:34:56").unwrap();
        assert_eq!(mac.oui(), [0x00, 0x03, 0x93]);
    }

    #[test]
    fn test_locally_administered() {
        let mac = MAC::parse("02:00:00:00:00:00").unwrap();
        assert!(mac.is_locally_administered());
        
        let mac = MAC::parse("00:00:00:00:00:00").unwrap();
        assert!(!mac.is_locally_administered());
    }

    #[test]
    fn test_random_local() {
        let mac = MAC::random_local();
        assert!(mac.is_locally_administered());
        assert!(mac.is_unicast());
    }

    #[test]
    fn test_anonymize() {
        let mac = MAC::parse("00:03:93:12:34:56").unwrap();
        assert_eq!(mac.anonymize(), "00:03:93:XX:XX:XX");
    }

    #[test]
    fn test_invalid_length() {
        assert!(MAC::parse("00:03:93").is_err());
    }
}
