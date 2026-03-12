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
          Config.Writer(state).resetExceptionAddress(interface: interface)

          // Trigger daemon to run immediately via XPC
          var hasCompleted = false
          Radio.forceRun(state: state) {
            guard !hasCompleted else { return }
            hasCompleted = true
            Log.debug("Daemon forceRun completed, triggering UI refresh")
            // After daemon runs, trigger UI refresh multiple times
            for delay in [0.2, 0.5, 0.8, 1.2] {
              DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                Log.debug("Triggering UI refresh")
                NotificationCenter.default.post(name: .manualTrigger, object: nil)
              }
            }
          }
          
          // Fallback: If XPC doesn't respond within 3 seconds, refresh anyway
          DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard !hasCompleted else { return }
            hasCompleted = true
            Log.debug("XPC timeout, triggering fallback UI refresh")
            for delay in [0.0, 0.3, 0.6] {
              DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NotificationCenter.default.post(name: .manualTrigger, object: nil)
              }
            }
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
