//! # linktools-rs
//!
//! Core library for MAC address manipulation and vendor lookup.
//! This library is compiled as a dynamic library (dylib) and exposed to Swift via FFI.
//!
//! ## Modules
//! - [`MAC`] - MAC address parsing, formatting, and generation
//! - [`OUI`] - Organizationally Unique Identifier (first 3 bytes of MAC)
//! - [`VendorDatabase`] - OUI to vendor name lookup
//! - [`Config`] - Application configuration management
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

pub use mac::MAC;
pub use oui::OUI;
pub use vendor::VendorDatabase;
pub use config::Config;
