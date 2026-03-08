[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/YanLien/LinkLiar/blob/master/LICENSE.md)
[![CI](https://github.com/YanLien/LinkLiar/actions/workflows/tests.yml/badge.svg)](https://github.com/YanLien/LinkLiar/actions)

## Prevent your Mac from leaking MACs

An intuitive macOS status bar application written in **Swift + Rust** to help you spoof the MAC addresses of your Wi-Fi and Ethernet interfaces. Free and open-source.

[How do I install this?](#installation)

## Architecture

```
LinkLiar (SwiftUI)          -- GUI, status bar menu, settings
  └─ RustBridge (FFI)       -- Swift <-> Rust interop
      └─ linktools-rs       -- MAC parsing, vendor lookup, random generation
LinkTools                   -- shared models, config, observers
linkdaemon                  -- privileged background daemon (runs as root)
```

Core MAC address operations are implemented in Rust (`linktools-rs/`) and exposed to Swift via C FFI, providing better performance and format support.

## Requirements

* macOS Ventura (13.0) or later
* Administrator privileges (you will be asked for your root password *once*)
* Xcode 15.0+ and Rust toolchain (for building from source)

## Installation

If you have [Homebrew](https://brew.sh), just run `brew install --cask linkliar`.

To install it manually, follow [these instructions](http://halo.github.io/LinkLiar/installation.html) in the documentation.

## Building from Source

**Prerequisites**: Xcode 15.0+, Rust toolchain (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)

```bash
# Quick build
./build.sh

# Release build
./build.sh -r

# Clean, build release, and run tests
./build.sh -c -r -t

# Package as .app / .dmg
./build.sh -r -p
```

The build script will:
1. Compile the Rust library (`linktools-rs`)
2. Copy `liblinktools.dylib` into the app bundle
3. Build the Xcode project
4. Optionally run tests and package

## Documentation

End-user documentation is at [halo.github.io/LinkLiar](http://halo.github.io/LinkLiar).

To update the HelpBook, change the source files in [LinkLiarHelp/en.lproj](https://github.com/halo/LinkLiar/tree/master/LinkLiarHelp/en.lproj) and then generate the output with `bin/docs`.

## Limitations

* When Wi-Fi is turned off, its MAC address cannot be changed. Turn it on first.
* Changing a MAC address while connected will briefly drop the connection.
* As of macOS 12.3+, the interface must be disassociated from a network before modifying its MAC address. LinkLiar handles this automatically.
* `System Preferences` will still show the original hardware MAC address. This is normal; actual network traffic uses the spoofed address.

## Troubleshooting

Enable logging:

```bash
touch "/Library/Application Support/LinkLiar/linkliar.log"
```

Delete the log file to silence logging. For live colorful output:

```bash
/Applications/LinkLiar.app/Contents/Resources/logs
```

Hold the Option key while the menu is visible for advanced options.

## Thanks

* Original project by [halo](https://github.com/halo/LinkLiar)
* Icon from [Iconmonstr](http://iconmonstr.com)

## License

MIT. See [LICENSE.md](https://github.com/halo/LinkLiar/blob/master/LICENSE.md).
