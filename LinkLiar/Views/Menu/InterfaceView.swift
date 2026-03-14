// Copyright (c) halo https://github.com/halo/LinkLiar
// SPDX-License-Identifier: MIT

import SwiftUI

struct InterfaceView: View {
  @Bindable var state: LinkState
  @Bindable var interface: Interface

  var body: some View {
    // Separating Icons and text
    HStack(spacing: 8) {
      if interface.hasOriginalMAC {
        Image("MenuIconLeaking")
      } else {
        // Invisible placeholder in the same size as the leaking icon.
        Image("MenuIconLeaking").opacity(0)
      }

      VStack(alignment: .leading) {
        HStack(spacing: 8) {
          Text(interface.name)
          Text(interface.bsd.name)
            .opacity(0.3)
            .font(.system(.body, design: .monospaced))
        }

        HStack(spacing: 8) {
          Button(action: {
            copy(interface.softMAC?.address ?? "??:??:??:??:??:??")
          }, label: {
            Text(interface.softMAC?.anonymous(state.config.general.isAnonymized) ?? "??:??:??:??:??:??")
              .font(.system(.body, design: .monospaced, weight: .light))
          }).buttonStyle(.plain)
        }

        Text(interface.softOUI.map { MACVendors.name($0) } ?? "No Vendor")
          .font(.system(.footnote, design: .monospaced))
          .opacity(0.5)

        if !interface.hasOriginalMAC {
          HStack(spacing: 0) {
            Text("Originally ")
              .opacity(0.5)
              .font(.system(.footnote))
            Button(action: {
              copy(interface.hardMAC.address)
            }, label: {
              Text(interface.hardMAC.anonymous(state.config.general.isAnonymized))
                .font(.system(.footnote, design: .monospaced))
                .opacity(0.5)
            }).buttonStyle(.plain)
          }
        }
      }

      // Padding parity on the right side (invisible).
      Image("MenuIconLeaking").opacity(0)

    // Without this, only words (captions) are right-clickable. With it, you can click anywhere in this HStack.
    // See https://www.hackingwithswift.com/quick-start/swiftui/how-to-control-the-tappable-area-of-a-view-using-contentshape
    }.contentShape(Rectangle())
    .contextMenu {
      Button("Copy MAC address") { copy(interface.softMAC?.address ?? "??:??:??:??:??:??") }

      // Show randomize button if action is random and daemon is enabled or status is unknown
      if state.config.arbiter(interface.hardMAC).action == .random 
          && (state.daemonRegistration == .enabled || state.daemonRegistration == .unknown) {
        Button("Randomize now") {
          Log.debug("Force randomization...")
          Log.debug("Current softMAC before reset: \(interface.softMAC?.address ?? "nil")")

          // Step 1: Update config to mark current MAC as exception
          Config.Writer(state).resetExceptionAddress(interface: interface)
          Log.debug("Config file updated, current MAC marked as exception")

          // Step 2: Trigger daemon to run immediately via XPC
          var hasCompleted = false
          Radio.forceRun(state: state) {
            guard !hasCompleted else { return }
            hasCompleted = true
            Log.debug("Daemon XPC call completed")

            // Step 3: Wait for daemon to actually change the MAC address
            // Ifconfig.Setter sleeps for 1 second, plus FileObserver processing time
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
              Log.debug("Triggering UI refresh after daemon completed")

              // Re-query the specific interface that was randomized
              interface.querySoftMAC()

              // Then trigger a full UI refresh
              NotificationCenter.default.post(name: .manualTrigger, object: nil)
            }
          }

          // Fallback: If XPC doesn't respond within 5 seconds, refresh anyway
          DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            guard !hasCompleted else { return }
            hasCompleted = true
            Log.debug("XPC timeout, triggering fallback UI refresh")
            NotificationCenter.default.post(name: .manualTrigger, object: nil)
          }
        }
      }
    }
  }

  private func copy(_ content: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
    pasteboard.setString(content, forType: NSPasteboard.PasteboardType.string)
  }
}

#Preview {
  let state = LinkState()
  let interfaces = Interfaces.all(.sync)
  return InterfaceView(state: state, interface: interfaces.first!)
}
