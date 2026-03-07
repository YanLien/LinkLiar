use std::collections::HashMap;
use serde::{Deserialize, Serialize};

/// Configuration for LinkLiar
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub version: u32,
    #[serde(default)]
    pub general: GeneralConfig,
    #[serde(flatten)]
    pub interfaces: HashMap<String, InterfaceConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct GeneralConfig {
    #[serde(default)]
    pub restricted_daemon: bool,
    #[serde(default)]
    pub randomize_timer_seconds: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InterfaceConfig {
    pub action: Option<String>,
    pub address: Option<String>,
    pub except: Option<String>,
    #[serde(default)]
    pub ssids: HashMap<String, String>,
}

impl Config {
    /// Load configuration from JSON file
    pub fn from_json(json: &str) -> Result<Self, serde_json::Error> {
        serde_json::from_str(json)
    }

    /// Convert to JSON string
    pub fn to_json(&self) -> Result<String, serde_json::Error> {
        serde_json::to_string_pretty(self)
    }

    /// Get configuration for a specific interface (by MAC address)
    pub fn get_interface(&self, mac: &str) -> Option<&InterfaceConfig> {
        self.interfaces.get(mac)
    }

    /// Set configuration for an interface
    pub fn set_interface(&mut self, mac: String, config: InterfaceConfig) {
        self.interfaces.insert(mac, config);
    }

    /// Create a default configuration
    pub fn default_config() -> Self {
        let mut general = GeneralConfig::default();
        general.restricted_daemon = false;
        general.randomize_timer_seconds = 0;
        
        Self {
            version: 4,
            general,
            interfaces: HashMap::new(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = Config::default_config();
        assert_eq!(config.version, 4);
        assert!(!config.general.restricted_daemon);
    }

    #[test]
    fn test_json_roundtrip() {
        let mut config = Config::default_config();
        
        let interface_config = InterfaceConfig {
            action: Some("random".to_string()),
            address: None,
            except: None,
            ssids: HashMap::new(),
        };
        config.set_interface("00:03:93:12:34:56".to_string(), interface_config);
        
        let json = config.to_json().unwrap();
        let parsed = Config::from_json(&json).unwrap();
        
        assert_eq!(config.version, parsed.version);
    }

    #[test]
    fn test_parse_json() {
        let json = r#"
        {
            "version": 4,
            "general": {
                "restricted_daemon": false,
                "randomize_timer_seconds": 0
            },
            "00:03:93:12:34:56": {
                "action": "random"
            }
        }
        "#;
        
        let config = Config::from_json(json).unwrap();
        assert_eq!(config.version, 4);
        assert!(config.get_interface("00:03:93:12:34:56").is_some());
    }
}
