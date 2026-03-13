//! Fetches MAC vendor data from mac2vendor.com and generates:
//! - LinkLiar/oui.json
//!
//! Usage: cargo run --bin generate-vendors (from linktools-rs/)

use linktools::VendorDatabase;
use std::path::Path;

const DATA_URL: &str = "https://mac2vendor.com/download/vendorMacs.prop";

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let output_path = Path::new("../LinkLiar/oui.json");
    let output_str = output_path.to_str().expect("invalid output path");

    eprintln!("Fetching vendor data from {DATA_URL}...");
    let (db, count) = VendorDatabase::fetch_and_save(DATA_URL, output_str)?;
    eprintln!("Written {} ({count} OUI entries)", output_path.display());

    let popular = db.popular_vendors(50);
    eprintln!("Found {} popular vendors", popular.len());

    Ok(())
}
