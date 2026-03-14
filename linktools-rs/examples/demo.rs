use linktools::{MAC, OUI, VendorDatabase};

fn main() {
    println!("🦀 LinkLiar Rust Library Demo");
    println!("==============================\n");

    // 1. MAC 地址解析
    println!("📌 MAC 地址解析:");
    let inputs = vec![
        "00:03:93:12:34:56",
        "00-03-93-12-34-56",
        "000393123456",
        "aa:bb:cc:dd:ee:ff",
    ];

    for input in inputs {
        match MAC::parse(input) {
            Ok(mac) => {
                println!("  ✅ {} → {}", input, mac.to_string_colon());
                println!("     OUI: {}", mac.oui().iter().map(|b| format!("{:02X}", b)).collect::<Vec<_>>().join(":"));
                println!("     本地管理: {}", if mac.is_locally_administered() { "是" } else { "否" });
            }
            Err(e) => println!("  ❌ {} → 错误: {}", input, e),
        }
    }

    // 2. 厂商查找
    println!("\n🏭 厂商查找:");
    let db = VendorDatabase::default();
    
    let ouis = vec!["000393", "00000C", "001A11", "0007AB"];
    for oui_str in ouis {
        match OUI::parse(oui_str) {
            Ok(oui) => {
                match db.lookup(&oui) {
                    Some(vendor) => println!("  ✅ {} → {}", oui_str, vendor),
                    None => println!("  ❌ {} → 未找到", oui_str),
                }
            }
            Err(e) => println!("  ❌ {} → 错误: {}", oui_str, e),
        }
    }

    // 3. 随机 MAC 生成
    println!("\n🎲 随机 MAC 生成:");
    
    // 本地管理地址
    let local_mac = MAC::random_local();
    println!("  📍 本地管理: {}", local_mac);
    println!("     本地管理位: {}", if local_mac.is_locally_administered() { "设置" } else { "未设置" });
    
    // 厂商特定 MAC
    let vendors = vec!["apple", "cisco", "google"];
    for vendor_id in vendors {
        match db.random_mac_for_vendor(vendor_id) {
            Some(mac) => {
                println!("  🏷️  {} MAC: {}", vendor_id.to_uppercase(), mac);
                if let Some(vendor_name) = db.lookup(&OUI::new(mac.oui())) {
                    println!("     厂商: {}", vendor_name);
                }
            }
            None => println!("  ❌ {} → 未找到", vendor_id),
        }
    }

    // 4. MAC 地址匿名化
    println!("\n🔒 MAC 地址匿名化:");
    let mac = MAC::parse("00:03:93:12:34:56").unwrap();
    println!("  原始: {}", mac);
    println!("  匿名化: {}", mac.anonymize());

    // 5. 性能测试
    println!("\n⚡ 性能测试 (1000 次操作):");
    
    // 解析性能
    let start = std::time::Instant::now();
    for _ in 0..1000 {
        let _ = MAC::parse("00:03:93:12:34:56");
    }
    let parse_duration = start.elapsed();
    println!("  📊 MAC 解析: {:?}", parse_duration / 1000);

    // 查找性能
    let oui = OUI::parse("000393").unwrap();
    let start = std::time::Instant::now();
    for _ in 0..1000 {
        let _ = db.lookup(&oui);
    }
    let lookup_duration = start.elapsed();
    println!("  📊 厂商查找: {:?}", lookup_duration / 1000);

    // 随机生成性能
    let start = std::time::Instant::now();
    for _ in 0..1000 {
        let _ = MAC::random_local();
    }
    let random_duration = start.elapsed();
    println!("  📊 随机生成: {:?}", random_duration / 1000);

    println!("\n✅ 演示完成!");
}
