//! # linktools-rs
//!
//! Core library for MAC address manipulation and vendor lookup.
//! This library is compiled as a dynamic library (dylib) and exposed to Swift via FFI.
//!
//! ## Modules
//! - [`MAC`] - MAC address parsing, formatting, and generation
//! - [`OUI`] - Organizationally Unique Identifier (first 3 bytes of MAC)
//! - [`BSSID`] - Basic Service Set Identifier (WiFi access point MAC)
//! - [`SSID`] - Service Set Identifier (WiFi network name)
//! - [`VendorDatabase`] - OUI to vendor name lookup
//! - [`Config`] - Application configuration management
//! - [`MacBatch`] - Batch operations for multiple MAC addresses
//! - [`OuiBatch`] - Batch OUI lookups
//! - [`MacSimilarity`] - MAC address similarity comparison
//!
//! ## Usage
//! ```rust
//! use linktools::{MAC, OUI, VendorDatabase};
//!
//! let mac = MAC::parse("AA:BB:CC:DD:EE:FF")?;
//! let oui = mac.oui();
//! println!("OUI: {}", oui.to_string_colon());
//! ```

mod mac;
mod oui;
mod vendor;
mod config;
mod ffi;
mod bssid;
mod ssid;
mod batch;

pub use mac::MAC;
pub use oui::OUI;
pub use vendor::{VendorDatabase, PopularVendorInfo};
pub use config::Config;
pub use bssid::BSSID;
pub use ssid::SSID;
