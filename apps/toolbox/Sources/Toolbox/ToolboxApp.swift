import AppKit
import SwiftUI
import ToolboxCore

@main
struct ToolboxApp: App {
  var body: some Scene {
    WindowGroup("Toolbox", id: "main") {
      ToolboxShellView()
    }
    .windowStyle(.titleBar)
    .defaultSize(width: 1_120, height: 760)
    .commands {
      CommandGroup(replacing: .appInfo) {
        Button(L10n.text("About Toolbox")) { showAboutPanel() }
      }
      CommandGroup(replacing: .newItem) {}
    }
  }

  private func showAboutPanel() {
    NSApp.orderFrontStandardAboutPanel(options: [
      .applicationName: AppMetadata.name,
      .applicationVersion: AppMetadata.version,
      .version: "Build \(AppMetadata.build)",
      .credits: NSAttributedString(string: L10n.text(AppMetadata.tagline)),
    ])
    NSApp.activate(ignoringOtherApps: true)
  }
}
