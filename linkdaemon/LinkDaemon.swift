// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import Cocoa

class LinkDaemon: NSObject {
  // MARK: Class Methods
  override init() {
    super.init()
    Log.debug("Daemon \(version.formatted) says hello")
    subscribe()

    // Start XPC listener for receiving commands from GUI
    startXPCListener()

    RunLoop.main.run()
  }

  // MARK: Private Instance Properties
  private var configFileObserver: FileObserver?
  private var networkObserver: NetworkObserver?
  private var intervalTimer: IntervalTimer?
  private var xpcListener: NSXPCListener?

  /// Holds the raw configuration file as Dictionary.
  var configDictionary: [String: Any] = [:]

  // MARK: Private Instance Methods
  private func subscribe() {
    ConfigDirectory.ensure()

    // Start observing the config file.
    configFileObserver = FileObserver(path: Paths.configFile, callback: configFileChanged)

    // Load config file once.
    configFileChanged()

    intervalTimer = IntervalTimer(callback: intervalElapsed)

    // Start observing changes of ethernet interfaces
    networkObserver = NetworkObserver(callback: networkConditionsChanged)

    NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(willPowerOff),
                                                      name: NSWorkspace.willPowerOffNotification, object: nil)
    NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(willSleep(_:)),
                                                      name: NSWorkspace.willSleepNotification, object: nil)
    NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(didWake(_:)),
                                                      name: NSWorkspace.didWakeNotification, object: nil)
  }

  private func startXPCListener() {
    Log.debug("Starting XPC listener for daemon commands")
    let listener = NSXPCListener(machServiceName: Identifiers.daemon.rawValue)
    listener.delegate = self
    listener.resume()
    self.xpcListener = listener
  }

  private func intervalElapsed() {
    Log.debug("Interval elapsed, acting upon it")
    executor.run()
  }

  private func configFileChanged() {
    Log.debug("Config file change detected, acting upon it")
    executor.run()
  }

  private func networkConditionsChanged() {
    Log.debug("Network change detected, acting upon it")
    executor.run()
  }

  @objc func willPowerOff(_ _: Notification) {
    Log.debug("Logging out...")
    executor.mayReRandomize()
  }

  @objc func willSleep(_ _: Notification) {
    Log.debug("Going to sleep...")
    // It's safe to randomize here, loosing Wi-Fi is not tragic while
    // closing the lid of your MacBook.
    executor.mayReRandomize()
  }

  @objc func didWake(_ _: Notification) {
    Log.debug("Woke up...")
    // Cannot re-randomize here because it's too late.
    // Wi-Fi will loose connection when opening the lid of your MacBook.
  }

  // MARK: Instance Properties
  lazy var version: Version = {
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
      return Version(version)
    }
    return Version("?.?.?")
  }()

  // MARK: Public Instance Methods

  /// Force the daemon to run a synchronization immediately
  /// Called from XPC when GUI requests a forced run
  func forceRunSynchronization() {
    Log.debug("Force run synchronization requested via XPC")
    executor.run()
  }

  // MARK: Private Instance Properties
  lazy var executor: Executor = {
    Executor()
  }()
}

// MARK: - NSXPCListenerDelegate

extension LinkDaemon: NSXPCListenerDelegate {
  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
    Log.debug("XPC: New connection accepted")

    newConnection.exportedInterface = Self.configuredInterface()
    newConnection.exportedObject = self

    newConnection.invalidationHandler = {
      Log.debug("XPC: Connection invalidated")
    }

    newConnection.resume()
    return true
  }

  /// Build an NSXPCInterface with explicit allowed classes for all methods.
  private static func configuredInterface() -> NSXPCInterface {
    let interface = NSXPCInterface(with: ListenerProtocol.self)
    let stringClasses = NSSet(array: [NSString.self]) as Set
    let numberClasses = NSSet(array: [NSNumber.self]) as Set

    interface.setClasses(stringClasses,
                         for: #selector(ListenerProtocol.version(reply:)),
                         argumentIndex: 0, ofReply: true)
    interface.setClasses(numberClasses,
                         for: #selector(ListenerProtocol.createConfigDirectory(reply:)),
                         argumentIndex: 0, ofReply: true)
    interface.setClasses(numberClasses,
                         for: #selector(ListenerProtocol.removeConfigDirectory(reply:)),
                         argumentIndex: 0, ofReply: true)
    interface.setClasses(numberClasses,
                         for: #selector(ListenerProtocol.forceRun(reply:)),
                         argumentIndex: 0, ofReply: true)
    return interface
  }
}

// MARK: - ListenerProtocol Implementation

extension LinkDaemon: ListenerProtocol {
  func version(reply: @escaping (String) -> Void) {
    let versionString = version.formatted
    Log.debug("XPC: Version requested, returning \(versionString)")
    reply(versionString)
  }

  func createConfigDirectory(reply: @escaping (Bool) -> Void) {
    Log.debug("XPC: createConfigDirectory called")
    ConfigDirectory.ensure()
    reply(true)
  }

  func removeConfigDirectory(reply: @escaping (Bool) -> Void) {
    Log.debug("XPC: removeConfigDirectory called")
    reply(true)
  }

  func forceRun(reply: @escaping (Bool) -> Void) {
    Log.debug("XPC: forceRun called - triggering synchronization")

    // Trigger synchronization asynchronously
    DispatchQueue.global(qos: .userInitiated).async {
      Log.debug("XPC: Starting forceRunSynchronization")
      self.forceRunSynchronization()
      Log.debug("XPC: forceRunSynchronization finished")
    }

    // Reply immediately - we've initiated the sync
    reply(true)
  }
}
