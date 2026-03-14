// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import Foundation
import ServiceManagement

class Radio {
  static func version(state: LinkState, reply: @escaping (Version?) -> Void) {
    transceive(state: state, block: { listener in
      listener.version(reply: { rawVersion in
        Log.debug("The helper responded with its version \(rawVersion)")
        let version = Version(rawVersion)
        state.daemonVersion = version
        state.xpcStatus = .connected
        reply(version)
      })
    })
  }

  //  static func uninstallDaemon(reply: @escaping (Bool) -> Void) {
  //    usingHelper(block: { helper in
  //      helper.uninstallDaemon(reply: { success in
  //        Log.debug("Helper worked on daemon uninstallation")
  //        reply(success)
  //      })
  //    })
  //  }

  static func install(state: LinkState, reply: @escaping (Bool) -> Void) {
    transceive(state: state, block: { helper in
      helper.createConfigDirectory(reply: { success in
        Log.debug("Helper worked on installation")
        state.xpcStatus = .connected
        reply(success)
      })
    })
  }

  static func uninstall(state: LinkState, reply: @escaping (Bool) -> Void) {
    transceive(state: state, block: { helper in
      helper.removeConfigDirectory(reply: { success in
        Log.debug("Helper worked on uninstallation")
        state.xpcStatus = .connected
        reply(success)
      })
    })
  }

  /// Force the daemon to immediately run a synchronization
  static func forceRun(state: LinkState, completion: @escaping () -> Void = {}) {
    transceive(state: state, block: { listener in
      listener.forceRun(reply: { success in
        Log.debug("Daemon forceRun completed successfully: \(success)")
        state.xpcStatus = .connected
        completion()
      })
    })
  }

//  static func uninstallDaemon(reply: @escaping (Bool) -> Void) {
//    usingHelper(block: { helper in
//      helper.uninstallDaemon(reply: { success in
//        Log.debug("Helper worked on daemon uninstallation")
//        reply(success)
//      })
//    })
//  }
//
//  static func createConfigDir(reply: @escaping (Bool) -> Void) {
//    usingHelper(block: { helper in
//      helper.createConfigDirectory(reply: { success in
//        Log.debug("Helper worked on config dir creation")
//        reply(success)
//      })
//    })
//  }
//
//  static func removeConfigDir(reply: @escaping (Bool) -> Void) {
//    usingHelper(block: { helper in
//      helper.removeConfigDirectory(reply: { success in
//        Log.debug("Helper worked on config dir deletion")
//        reply(success)
//      })
//    })
//  }
//
//  static func installDaemon(reply: @escaping (Bool) -> Void) {
//    Log.debug("Asking Helper to install daemon")
//    usingHelper(block: { helper in
//      helper.installDaemon(pristineDaemonExecutablePath: Paths.daemonPristineExecutablePath, reply: { success in
//        Log.debug("Helper worked on the establishment of the daemon")
//        reply(success)
//      })
//    })
//  }
//
//  static func activateDaemon(reply: @escaping (Bool) -> Void) {
//    Log.debug("Asking Helper to activate daemon")
//    usingHelper(block: { helper in
//      helper.activateDaemon(reply: { success in
//        Log.debug("Helper worked on the activation of the daemon")
//        reply(success)
//      })
//    })
//  }
//
//  static func deactivateDaemon(reply: @escaping (Bool) -> Void) {
//    Log.debug("Asking Helper to deactivate daemon")
//    usingHelper(block: { helper in
//      helper.deactivateDaemon(reply: { success in
//        Log.debug("Helper worked on the deactivation of the daemon")
//        reply(success)
//      })
//    })
//  }
//
//  static func uninstallHelper(reply: @escaping (Bool) -> Void) {
//    usingHelper(block: { helper in
//      helper.uninstallHelper(reply: { success in
//        Log.debug("Helper worked on the imploding")
//        reply(success)
//      })
//    })
//  }

  // MARK: Private Properties

  private static var xpcConnection: NSXPCConnection?

  // MARK: Private Functions

  /// Build an NSXPCInterface with explicit allowed classes for all methods,
  /// avoiding the default [NSObject] that triggers the NSSecureCoding warning.
  private static func configuredInterface() -> NSXPCInterface {
    let interface = NSXPCInterface(with: ListenerProtocol.self)
    let stringClasses = NSSet(array: [NSString.self]) as Set
    let numberClasses = NSSet(array: [NSNumber.self]) as Set

    // version(reply: (String) -> Void) — reply argument 0 is a String
    interface.setClasses(stringClasses,
                         for: #selector(ListenerProtocol.version(reply:)),
                         argumentIndex: 0, ofReply: true)
    // createConfigDirectory(reply: (Bool) -> Void)
    interface.setClasses(numberClasses,
                         for: #selector(ListenerProtocol.createConfigDirectory(reply:)),
                         argumentIndex: 0, ofReply: true)
    // removeConfigDirectory(reply: (Bool) -> Void)
    interface.setClasses(numberClasses,
                         for: #selector(ListenerProtocol.removeConfigDirectory(reply:)),
                         argumentIndex: 0, ofReply: true)
    // forceRun(reply: (Bool) -> Void)
    interface.setClasses(numberClasses,
                         for: #selector(ListenerProtocol.forceRun(reply:)),
                         argumentIndex: 0, ofReply: true)
    return interface
  }

  private static func transceive(state: LinkState, block: @escaping (ListenerProtocol) -> Void) {
    // swiftlint:disable force_cast
    let helper = connection(state: state)?.remoteObjectProxyWithErrorHandler({ error in
      Log.debug("Oh no, no connection to helper: \(error.localizedDescription)")
    }) as! ListenerProtocol
    // swiftlint:enable force_cast
    block(helper)
  }

  private static func connection(state: LinkState) -> NSXPCConnection? {
    if xpcConnection != nil {
      return xpcConnection
    }

    Log.debug(Identifiers.daemon.rawValue)
    xpcConnection = NSXPCConnection(machServiceName: Identifiers.daemon.rawValue, options: NSXPCConnection.Options.privileged)
    Log.debug("xpcConnection: \(xpcConnection!.description)")
    xpcConnection!.remoteObjectInterface = Self.configuredInterface()

    xpcConnection!.interruptionHandler = {
      xpcConnection?.interruptionHandler = nil

      // I actually don't know why this is supposed to be wrapped in an `OperationQueue`.
      OperationQueue.main.addOperation {
        xpcConnection = nil
        Log.debug("XPC Connection interrupted - the Helper probably crashed.")
        Log.debug("You mght find a crash report at /Library/Logs/DiagnosticReports")
        state.xpcStatus = .interrupted
      }
    }

    xpcConnection!.invalidationHandler = {
      xpcConnection?.invalidationHandler = nil

      OperationQueue.main.addOperation {
        xpcConnection = nil
        Log.debug("XPC Connection Invalidated")
        state.xpcStatus = .invalidated
      }
    }

    xpcConnection?.resume()
    return xpcConnection
  }
}
