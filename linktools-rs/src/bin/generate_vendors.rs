//! Fetches MAC vendor data from mac2vendor.com and generates:
//! - LinkTools/Backends/PopularVendorsDatabase.swift
//! - LinkLiar/oui.json
//!
//! Replaces the Ruby bin/vendors + lib/macs/* toolchain.
//!
//! Usage: cargo run --bin generate-vendors (from linktools-rs/)

use std::collections::BTreeMap;
use std::fs;
use std::path::Path;

const DATA_URL: &str = "https://mac2vendor.com/download/vendorMacs.prop";

/// Name normalization: maps raw names to shorter display names.
fn normalize_name(raw: &str) -> &str {
    match raw {
        "Cisco Systems" => "Cisco",
        "Huawei Technologies" => "Huawei",
        "Samsung Electronics" => "Samsung",
        "Hewlett Packard" => "HP",
        "TP-LINK Technologies" => "TP-Link",
        "Lg Electronics Mobile Communications" => "LG",
        "Vivo Mobile Communication" => "Vivo",
        "Asustek Computer" => "Asustek",
        "Sony Mobile Communications" => "Sony",
        "Motorola Mobility Llc A Lenovo Company" => "Motorola",
        "D-link International" => "D-link",
        "Xiaomi Communications" => "Xiaomi",
        _ => raw,
    }
}

/// Vendor names that should be excluded (not consumer devices).
const DENYLIST: &[&str] = &[
    "Arris",
    "IEEE",
    "Foxconn",
    "Juniper",
    "Fiberhome",
    "Sagemcom",
    "Private",
    "Guangdong",
    "Nortel",
    "Amazon",
    "Ruckus",
    "Technicolor",
    "Liteon",
    "Avaya",
    "Espressif",
];

/// Special vendors to always include regardless of prefix count.
const ALWAYS_INCLUDE: &[&str] = &[
    "Coca Cola Company",
    "Nintendo",
    "3com",
    "HTC",
    "Ibm",
    "Ericsson",
];

struct Vendor {
    name: String,
    prefixes: Vec<String>,
}

impl Vendor {
    fn id(&self) -> String {
        if self.name.contains("Coca") {
            return "cocacola".to_string();
        }
        // Keep only alphanumeric + space, lowercase, take first word
        let cleaned: String = self.name.chars()
            .filter(|c| c.is_alphanumeric() || *c == ' ')
            .collect::<String>()
            .to_lowercase();
        cleaned.split_whitespace().next().unwrap_or("unknown").to_string()
    }

    fn is_popular(&self) -> bool {
        if ALWAYS_INCLUDE.iter().any(|&s| s == self.name) {
            return true;
        }
        if self.name == "Huawei Device" {
            return false;
        }
        if DENYLIST.iter().any(|d| self.name.contains(d)) {
            return false;
        }
        self.prefixes.len() > 50
    }
}

fn fetch_vendor_data() -> Result<String, Box<dyn std::error::Error>> {
    eprintln!("Fetching vendor data from {DATA_URL}...");
    let body = ureq::get(DATA_URL).call()?.into_string()?;
    eprintln!("Downloaded {} bytes", body.len());
    Ok(body)
}

fn parse_rows(data: &str) -> Vec<(String, String)> {
    data.lines()
        .filter(|line| !line.starts_with('*') && !line.is_empty())
        .filter_map(|line| {
            let (prefix, name) = line.split_once('=')?;
            Some((prefix.trim().to_string(), name.trim().to_string()))
        })
        .collect()
}

fn generate_swift(vendors: &[(&str, &str, &[String])]) -> String {
    let mut out = String::new();

    out.push_str("// Copyright (c) halo https://github.com/halo/LinkLiar\n");
    out.push_str("// SPDX-License-Identifier: MIT\n");
    out.push_str("\n");
    out.push_str("// This file was auto-generated using `cargo run --bin generate-vendors`.\n");
    out.push_str("// If this file changes, don't forget to restart the daemon for the changes to take effect.\n");
    out.push_str("\n");
    out.push_str("struct PopularVendorsDatabase {\n");

    // dictionaryWithCounts
    out.push_str("  static var dictionaryWithCounts: [String: [String: Int]] {\n");
    out.push_str("    [\n");
    for (id, name, prefixes) in vendors {
        out.push_str(&format!("      \"{id}\": [\"{name}\": {count}],\n", count = prefixes.len()));
    }
    out.push_str("    ]\n");
    out.push_str("  }\n");
    out.push_str("\n");

    // dictionaryWithOUIs
    out.push_str("  // swiftlint:disable line_length\n");
    out.push_str("  static var dictionaryWithOUIs: [String: [String: [UInt32]]] {\n");
    out.push_str("    [\n");
    for (id, name, prefixes) in vendors {
        let hex_list: Vec<String> = prefixes.iter()
            .filter_map(|p| u32::from_str_radix(p, 16).ok())
            .map(|v| format!("0x{v:06x}"))
            .collect();
        out.push_str(&format!("      \"{id}\": [\"{name}\": [{hexes}]],\n", hexes = hex_list.join(", ")));
    }
    out.push_str("    ]\n");
    out.push_str("  }\n");
    out.push_str("  // swiftlint:enable line_length\n");
    out.push_str("}\n");

    out
}

fn generate_oui_json(rows: &[(String, String)]) -> String {
    let mut map = BTreeMap::new();
    for (prefix, name) in rows {
        let p = prefix.to_lowercase();
        if p.len() >= 6 {
            let oui = format!("{}:{}:{}", &p[0..2], &p[2..4], &p[4..6]);
            map.insert(oui, name.clone());
        }
    }
    serde_json::to_string(&map).unwrap()
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let data = fetch_vendor_data()?;
    let rows = parse_rows(&data);
    eprintln!("Parsed {} OUI entries", rows.len());

    // Group by normalized vendor name
    let mut vendor_map: BTreeMap<String, Vendor> = BTreeMap::new();
    for (prefix, raw_name) in &rows {
        let name = normalize_name(raw_name).to_string();
        let vendor = vendor_map.entry(name.clone()).or_insert_with(|| Vendor {
            name,
            prefixes: Vec::new(),
        });
        vendor.prefixes.push(prefix.to_lowercase());
    }

    // Filter popular vendors, sort by prefix count descending
    let mut popular: Vec<&Vendor> = vendor_map.values()
        .filter(|v| v.is_popular())
        .collect();
    popular.sort_by(|a, b| b.prefixes.len().cmp(&a.prefixes.len()));

    eprintln!("Found {} popular vendors", popular.len());

    // Prepare data for Swift generation
    let swift_data: Vec<(&str, &str, &[String])> = popular.iter()
        .map(|v| (v.id().leak() as &str, v.name.as_str(), v.prefixes.as_slice()))
        .collect();

    let swift_code = generate_swift(&swift_data);
    let oui_json = generate_oui_json(&rows);

    // Write files (paths relative to project root, run from linktools-rs/)
    let swift_path = Path::new("../LinkTools/Backends/PopularVendorsDatabase.swift");
    let json_path = Path::new("../LinkLiar/oui.json");

    fs::write(swift_path, &swift_code)?;
    eprintln!("Written {}", swift_path.display());

    fs::write(json_path, &oui_json)?;
    eprintln!("Written {}", json_path.display());

    Ok(())
}
