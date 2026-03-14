// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

extension Config {
  struct OUIs {

    // MARK: Public Instance Properties

    var dictionary: [String: Any]

    // MARK: Public Instance Properties

    // Proxy them, so that the state is observed.
    var popular: [OUI] {
      PopularOUIs.all
    }

    var chosenPopular: [OUI] {
      guard let chosenIDs = dictionary[Config.Key.vendors.rawValue] as? [String] else {
        return PopularOUIs.find(Config.Key.apple.rawValue)
      }

      let vendors = Set(chosenIDs).flatMap { vendorId -> [OUI] in
        PopularOUIs.find(vendorId)
      }

      return Array(vendors).sorted()
    }
  }
}
