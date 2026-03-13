//! FFI (Foreign Function Interface) for Swift interoperability.
//!
//! This module exposes Rust functions to Swift via C-compatible ABI.
//! All strings returned from FFI functions are heap-allocated and must be
//! freed by calling `string_free()`.
//!
//! ## Memory Management
//! - Functions returning `*mut c_char` allocate memory that caller must free
//! - Use `string_free()` to deallocate strings returned from FFI calls
//! - All `*const c_char` input parameters are borrowed and not freed by Rust

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::sync::{LazyLock, RwLock};

use crate::mac::MAC;
use crate::oui::OUI;
use crate::vendor::VendorDatabase;

/// FFI interface for Swift interoperability

/// Vendor database (starts empty, loaded via vendor_load_database or vendor_update_database)
static VENDOR_DB: LazyLock<RwLock<VendorDatabase>> =
    LazyLock::new(|| RwLock::new(VendorDatabase::new()));

/// Helper: convert a Rust string to a C string, returning null on failure
fn to_c_string(s: String) -> *mut c_char {
    match CString::new(s) {
        Ok(cs) => cs.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

/// Helper: read a C string pointer into a &str
unsafe fn read_c_str<'a>(ptr: *const c_char) -> Option<&'a str> {
    if ptr.is_null() {
        return None;
    }
    unsafe { CStr::from_ptr(ptr) }.to_str().ok()
}

/// Parse MAC address
/// Returns null-terminated string that must be freed by caller
#[unsafe(no_mangle)]
pub extern "C" fn mac_parse(input: *const c_char) -> *mut c_char {
    let Some(input) = (unsafe { read_c_str(input) }) else {
        return std::ptr::null_mut();
    };

    match MAC::parse(input) {
        Ok(mac) => to_c_string(mac.to_string_colon()),
        Err(_) => std::ptr::null_mut(),
    }
}

/// Free a string returned from FFI
#[unsafe(no_mangle)]
pub extern "C" fn string_free(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    let _ = unsafe { CString::from_raw(s) };
}

/// Lookup vendor for OUI
/// Returns null-terminated string that must be freed by caller
#[unsafe(no_mangle)]
pub extern "C" fn oui_lookup(oui_str: *const c_char) -> *mut c_char {
    let Some(input) = (unsafe { read_c_str(oui_str) }) else {
        return std::ptr::null_mut();
    };

    let oui = match OUI::parse(input) {
        Ok(oui) => oui,
        Err(_) => return std::ptr::null_mut(),
    };

    let db = VENDOR_DB.read().unwrap();
    match db.lookup(&oui) {
        Some(vendor) => to_c_string(vendor.to_string()),
        None => std::ptr::null_mut(),
    }
}

/// Generate random MAC address
/// Returns null-terminated string that must be freed by caller
#[unsafe(no_mangle)]
pub extern "C" fn mac_random_local() -> *mut c_char {
    let mac = MAC::random_local();
    to_c_string(mac.to_string_colon())
}

/// Generate random MAC for specific vendor
/// Returns null-terminated string that must be freed by caller
#[unsafe(no_mangle)]
pub extern "C" fn mac_random_for_vendor(vendor_id: *const c_char) -> *mut c_char {
    let Some(vendor_id) = (unsafe { read_c_str(vendor_id) }) else {
        return std::ptr::null_mut();
    };

    let db = VENDOR_DB.read().unwrap();
    match db.random_mac_for_vendor(vendor_id) {
        Some(mac) => to_c_string(mac.to_string_colon()),
        None => std::ptr::null_mut(),
    }
}

/// Anonymize MAC address
/// Returns null-terminated string that must be freed by caller
#[unsafe(no_mangle)]
pub extern "C" fn mac_anonymize(mac_str: *const c_char) -> *mut c_char {
    let Some(input) = (unsafe { read_c_str(mac_str) }) else {
        return std::ptr::null_mut();
    };

    match MAC::parse(input) {
        Ok(mac) => to_c_string(mac.anonymize()),
        Err(_) => std::ptr::null_mut(),
    }
}

// --- New vendor database FFI functions ---

/// Load vendor database from an oui.json file.
/// Returns the number of entries loaded, or -1 on error.
#[unsafe(no_mangle)]
pub extern "C" fn vendor_load_database(path: *const c_char) -> i32 {
    let Some(path) = (unsafe { read_c_str(path) }) else {
        return -1;
    };

    let json = match std::fs::read_to_string(path) {
        Ok(j) => j,
        Err(_) => return -1,
    };

    let db = match VendorDatabase::from_json(&json) {
        Ok(db) => db,
        Err(_) => return -1,
    };

    let count = db.len() as i32;
    *VENDOR_DB.write().unwrap() = db;
    count
}

/// Download vendor data from URL, parse, save as oui.json, and reload the database.
/// Returns the number of entries, or -1 on error.
#[unsafe(no_mangle)]
pub extern "C" fn vendor_update_database(
    url: *const c_char,
    output_path: *const c_char,
) -> i32 {
    let Some(url) = (unsafe { read_c_str(url) }) else {
        return -1;
    };
    let Some(output_path) = (unsafe { read_c_str(output_path) }) else {
        return -1;
    };

    match VendorDatabase::fetch_and_save(url, output_path) {
        Ok((db, count)) => {
            *VENDOR_DB.write().unwrap() = db;
            count as i32
        }
        Err(_) => -1,
    }
}

/// Get popular vendors as a JSON array.
/// Returns a JSON string like [{"id":"apple","name":"Apple","prefixCount":1133}, ...].
/// Must be freed by caller with string_free().
#[unsafe(no_mangle)]
pub extern "C" fn vendor_get_popular_json(min_count: i32) -> *mut c_char {
    let db = VENDOR_DB.read().unwrap();
    let popular = db.popular_vendors(min_count.max(0) as usize);

    match serde_json::to_string(&popular) {
        Ok(json) => to_c_string(json),
        Err(_) => std::ptr::null_mut(),
    }
}

/// Get all OUI prefixes for a vendor as a JSON array.
/// Returns a JSON string like ["00:03:93","00:05:02", ...].
/// Must be freed by caller with string_free().
#[unsafe(no_mangle)]
pub extern "C" fn vendor_get_vendor_ouis_json(vendor_id: *const c_char) -> *mut c_char {
    let Some(vendor_id) = (unsafe { read_c_str(vendor_id) }) else {
        return std::ptr::null_mut();
    };

    let db = VENDOR_DB.read().unwrap();
    let ouis: Vec<String> = db
        .vendor_ouis(vendor_id)
        .iter()
        .map(|oui| oui.to_string_colon())
        .collect();

    match serde_json::to_string(&ouis) {
        Ok(json) => to_c_string(json),
        Err(_) => std::ptr::null_mut(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CStr;

    #[test]
    fn test_ffi_mac_parse() {
        let input = CString::new("00:03:93:12:34:56").unwrap();
        let result = mac_parse(input.as_ptr());

        assert!(!result.is_null());

        let result_str = unsafe { CStr::from_ptr(result) };
        assert_eq!(result_str.to_str().unwrap(), "00:03:93:12:34:56");

        string_free(result);
    }

    #[test]
    fn test_ffi_mac_random_local() {
        let result = mac_random_local();

        assert!(!result.is_null());

        let result_str = unsafe { CStr::from_ptr(result) };
        let s = result_str.to_str().unwrap();
        assert_eq!(s.len(), 17); // "XX:XX:XX:XX:XX:XX"

        string_free(result);
    }

    #[test]
    fn test_ffi_vendor_load_database() {
        let json = r#"{"00:03:93":"Apple","00:00:0c":"Cisco"}"#;
        let path = std::env::temp_dir().join("test_vendor_load.json");
        std::fs::write(&path, json).unwrap();

        let c_path = CString::new(path.to_str().unwrap()).unwrap();
        let result = vendor_load_database(c_path.as_ptr());
        assert_eq!(result, 2);

        // Verify invalid path returns -1
        let bad_path = CString::new("/nonexistent/path.json").unwrap();
        let bad_result = vendor_load_database(bad_path.as_ptr());
        assert_eq!(bad_result, -1);

        std::fs::remove_file(path).ok();
    }

    #[test]
    fn test_ffi_vendor_get_popular_json() {
        // Load a test database first
        let mut entries: Vec<String> = Vec::new();
        for i in 0..60 {
            entries.push(format!("\"{}:{}:{:02x}\":\"TestVendor\"", "aa", "bb", i));
        }
        let json = format!("{{{}}}", entries.join(","));
        let path = std::env::temp_dir().join("test_popular.json");
        std::fs::write(&path, &json).unwrap();

        let c_path = CString::new(path.to_str().unwrap()).unwrap();
        vendor_load_database(c_path.as_ptr());

        let result = vendor_get_popular_json(50);
        assert!(!result.is_null());

        let result_str = unsafe { CStr::from_ptr(result) };
        let s = result_str.to_str().unwrap();
        assert!(s.contains("TestVendor"));
        string_free(result);

        std::fs::remove_file(path).ok();
    }

    #[test]
    fn test_ffi_vendor_get_vendor_ouis_json() {
        let json = r#"{"00:03:93":"Apple","00:05:02":"Apple","00:00:0c":"Cisco"}"#;
        let path = std::env::temp_dir().join("test_ouis.json");
        std::fs::write(&path, json).unwrap();

        let c_path = CString::new(path.to_str().unwrap()).unwrap();
        vendor_load_database(c_path.as_ptr());

        let vendor_id = CString::new("apple").unwrap();
        let result = vendor_get_vendor_ouis_json(vendor_id.as_ptr());
        assert!(!result.is_null());

        let result_str = unsafe { CStr::from_ptr(result) };
        let s = result_str.to_str().unwrap();
        assert!(s.contains("00:03:93"));
        assert!(s.contains("00:05:02"));
        string_free(result);

        std::fs::remove_file(path).ok();
    }
}
