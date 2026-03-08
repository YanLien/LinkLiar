use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::sync::OnceLock;

use crate::mac::MAC;
use crate::oui::OUI;
use crate::vendor::VendorDatabase;

/// FFI interface for Swift interoperability

/// Cached vendor database (created once, reused across calls)
static VENDOR_DB: OnceLock<VendorDatabase> = OnceLock::new();

fn vendor_db() -> &'static VendorDatabase {
    VENDOR_DB.get_or_init(VendorDatabase::default)
}

/// Helper: convert a Rust string to a C string, returning null on failure
fn to_c_string(s: String) -> *mut c_char {
    match CString::new(s) {
        Ok(cs) => cs.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

/// Parse MAC address
/// Returns null-terminated string that must be freed by caller
#[unsafe(no_mangle)]
pub extern "C" fn mac_parse(input: *const c_char) -> *mut c_char {
    if input.is_null() {
        return std::ptr::null_mut();
    }

    let input_str = unsafe { CStr::from_ptr(input) };
    let input = match input_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    match MAC::parse(&input) {
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
    if oui_str.is_null() {
        return std::ptr::null_mut();
    }

    let input_str = unsafe { CStr::from_ptr(oui_str) };
    let input = match input_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let oui = match OUI::parse(&input) {
        Ok(oui) => oui,
        Err(_) => return std::ptr::null_mut(),
    };

    match vendor_db().lookup(&oui) {
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
    if vendor_id.is_null() {
        return std::ptr::null_mut();
    }

    let input_str = unsafe { CStr::from_ptr(vendor_id) };
    let vendor_id = match input_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    match vendor_db().random_mac_for_vendor(&vendor_id) {
        Some(mac) => to_c_string(mac.to_string_colon()),
        None => std::ptr::null_mut(),
    }
}

/// Anonymize MAC address
/// Returns null-terminated string that must be freed by caller
#[unsafe(no_mangle)]
pub extern "C" fn mac_anonymize(mac_str: *const c_char) -> *mut c_char {
    if mac_str.is_null() {
        return std::ptr::null_mut();
    }

    let input_str = unsafe { CStr::from_ptr(mac_str) };
    let input = match input_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    match MAC::parse(&input) {
        Ok(mac) => to_c_string(mac.anonymize()),
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
    fn test_ffi_oui_lookup() {
        let input = CString::new("000393").unwrap();
        let result = oui_lookup(input.as_ptr());

        assert!(!result.is_null());

        let result_str = unsafe { CStr::from_ptr(result) };
        assert_eq!(result_str.to_str().unwrap(), "Apple");

        string_free(result);
    }
}
