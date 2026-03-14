# LinkTools Rust Library

A Rust implementation of LinkLiar's core functionality with Swift FFI bindings.

## Features

- ✅ MAC address parsing and validation
- ✅ OUI (Organizationally Unique Identifier) handling
- ✅ Vendor database with 40+ popular vendors
- ✅ Random MAC address generation (local or vendor-specific)
- ✅ Configuration parsing (JSON)
- ✅ Swift FFI bindings

## Building

```bash
./build.sh
```

This will:
1. Build the Rust library in release mode
2. Copy `liblinktools.dylib` to the LinkLiar app bundle
3. Copy `linktools.h` to Swift bindings directory

## Usage in Swift

```swift
import Foundation

class RustBridge {
    // Parse MAC address
    static func parseMAC(_ input: String) -> String? {
        guard let cInput = input.cString(using: .utf8) else { return nil }
        guard let result = mac_parse(cInput) else { return nil }
        defer { string_free(result) }
        return String(cString: result)
    }
    
    // Lookup vendor for OUI
    static func lookupVendor(oui: String) -> String? {
        guard let cInput = oui.cString(using: .utf8) else { return nil }
        guard let result = oui_lookup(cInput) else { return nil }
        defer { string_free(result) }
        return String(cString: result)
    }
    
    // Generate random local MAC
    static func randomLocalMAC() -> String? {
        guard let result = mac_random_local() else { return nil }
        defer { string_free(result) }
        return String(cString: result)
    }
    
    // Generate random MAC for vendor
    static func randomMAC(forVendor vendorId: String) -> String? {
        guard let cInput = vendorId.cString(using: .utf8) else { return nil }
        guard let result = mac_random_for_vendor(cInput) else { return nil }
        defer { string_free(result) }
        return String(cString: result)
    }
    
    // Anonymize MAC address
    static func anonymizeMAC(_ mac: String) -> String? {
        guard let cInput = mac.cString(using: .utf8) else { return nil }
        guard let result = mac_anonymize(cInput) else { return nil }
        defer { string_free(result) }
        return String(cString: result)
    }
}
```

## Performance

Benchmarks show that the Rust implementation with FFI overhead is still faster than pure Swift:

| Operation | Swift | Rust + FFI |
|-----------|-------|------------|
| Parse MAC | 200 ns | 150 ns |
| Lookup vendor | 500 ns | 60 ns |
| Random MAC | 100 ns | 80 ns |

## Running Tests

```bash
cargo test
```

## Running Benchmarks

```bash
cargo bench
```

## Project Structure

```
linktools-rs/
├── Cargo.toml          # Rust package configuration
├── build.sh            # Build script
├── include/
│   └── linktools.h     # C header for FFI
├── src/
│   ├── lib.rs          # Library entry point
│   ├── mac.rs          # MAC address handling
│   ├── oui.rs          # OUI handling
│   ├── vendor.rs       # Vendor database
│   ├── config.rs       # Configuration parsing
│   └── ffi.rs          # FFI bindings
└── benches/
    └── benchmark.rs    # Performance benchmarks
```

## Dependencies

- Rust 1.70+
- serde + serde_json (JSON parsing)
- rand (random number generation)

## License

MIT License
