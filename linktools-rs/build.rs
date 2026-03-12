fn main() {
    // Parse Swift bridge modules and generate Swift/C headers
    swift_bridge_build::parse_bridges(vec!["src/bridge.rs"]);
}
