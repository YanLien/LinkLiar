//! Organizationally Unique Identifier (OUI) handling.
//!
//! OUI is the first 24 bits (3 bytes) of a MAC address that identifies
//! the vendor/manufacturer. Used for vendor lookup in the database.

use std::fmt;
use std::str::FromStr;

/// Organizationally Unique Identifier (first 3 bytes of MAC)
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct OUI {
    bytes: [u8; 3],
}

impl OUI {
    /// Create a new OUI from bytes
    pub fn new(bytes: [u8; 3]) -> Self {
        Self { bytes }
    }

    /// Parse OUI from string
    /// Supports formats: "00:03:93", "00-03-93", "000393"
    pub fn parse(input: &str) -> Result<Self, OUIError> {
        let cleaned: String = input
            .chars()
            .filter(|c| c.is_ascii_alphanumeric())
            .collect();

        if cleaned.len() != 6 {
            return Err(OUIError::InvalidLength(cleaned.len()));
        }

        let bytes = Self::parse_hex_bytes(&cleaned)?;
        Ok(Self { bytes })
    }

    /// Get formatted string with colon separator
    pub fn to_string_colon(&self) -> String {
        format!("{:02X}:{:02X}:{:02X}", self.bytes[0], self.bytes[1], self.bytes[2])
    }

    /// Get formatted string without separator (6 hex chars)
    pub fn to_string_hex(&self) -> String {
        format!("{:02X}{:02X}{:02X}", self.bytes[0], self.bytes[1], self.bytes[2])
    }

    /// Get raw bytes
    pub fn as_bytes(&self) -> &[u8; 3] {
        &self.bytes
    }

    /// Convert to u32
    pub fn to_u32(&self) -> u32 {
        ((self.bytes[0] as u32) << 16) 
            | ((self.bytes[1] as u32) << 8) 
            | (self.bytes[2] as u32)
    }

    /// Create from u32
    pub fn from_u32(value: u32) -> Self {
        Self {
            bytes: [
                ((value >> 16) & 0xFF) as u8,
                ((value >> 8) & 0xFF) as u8,
                (value & 0xFF) as u8,
            ],
        }
    }

    fn parse_hex_bytes(hex: &str) -> Result<[u8; 3], OUIError> {
        let mut bytes = [0u8; 3];
        
        for i in 0..3 {
            let start = i * 2;
            let byte_str = &hex[start..start + 2];
            bytes[i] = u8::from_str_radix(byte_str, 16)
                .map_err(|_| OUIError::InvalidHex(byte_str.to_string()))?;
        }
        
        Ok(bytes)
    }
}

impl fmt::Display for OUI {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.to_string_hex())
    }
}

impl FromStr for OUI {
    type Err = OUIError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Self::parse(s)
    }
}

impl From<[u8; 3]> for OUI {
    fn from(bytes: [u8; 3]) -> Self {
        Self::new(bytes)
    }
}

impl From<OUI> for u32 {
    fn from(oui: OUI) -> u32 {
        oui.to_u32()
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum OUIError {
    InvalidLength(usize),
    InvalidHex(String),
}

impl fmt::Display for OUIError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            OUIError::InvalidLength(len) => {
                write!(f, "Invalid OUI length: {} (expected 6 hex chars)", len)
            }
            OUIError::InvalidHex(s) => {
                write!(f, "Invalid hex string: {}", s)
            }
        }
    }
}

impl std::error::Error for OUIError {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse() {
        let oui = OUI::parse("00:03:93").unwrap();
        assert_eq!(oui.to_string_hex(), "000393");
    }

    #[test]
    fn test_to_u32() {
        let oui = OUI::parse("00:03:93").unwrap();
        assert_eq!(oui.to_u32(), 0x000393);
    }

    #[test]
    fn test_from_u32() {
        let oui = OUI::from_u32(0x000393);
        assert_eq!(oui.to_string_hex(), "000393");
    }
}
