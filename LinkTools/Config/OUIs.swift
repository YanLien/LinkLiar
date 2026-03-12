// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

extension Config {
  struct OUIs {

    // MARK: Public Instance Properties

    var dictionary: [String: Any]

    // MARK: Private Instance Properties

    private var useRustBackend: Bool {
      // Rust backend integration is pending Xcode project configuration
      // Set to false for now to use Swift implementation
      dictionary["useRustBackend"] as? Bool ?? false
    }

    // MARK: Public Instance Properties

    // Proxy them, so that the state is observed.
    var popular: [OUI] {
      useRustBackend ? RustOUIs.all : PopularOUIs.all
    }

    var chosenPopular: [OUI] {
      guard let chosenIDs = dictionary[Config.Key.vendors.rawValue] as? [String] else {
        return useRustBackend ? RustOUIs.find(Config.Key.apple.rawValue) : PopularOUIs.find(Config.Key.apple.rawValue)
      }

      let vendors = Set(chosenIDs).flatMap { vendorId -> [OUI] in
        useRustBackend ? RustOUIs.find(vendorId) : PopularOUIs.find(vendorId)
      }

      return Array(vendors).sorted()
    }
  }
}
