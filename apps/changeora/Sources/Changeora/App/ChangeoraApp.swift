import AppKit
import SwiftUI

@main
struct ChangeoraApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .windowStyle(.titleBar)
    .commands {
      CommandGroup(replacing: .appInfo) {
        Button("Giới thiệu Changeora") { showAboutPanel() }
      }
      CommandGroup(replacing: .newItem) {}
    }
  }

  private func showAboutPanel() {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let credits = NSAttributedString(
      string:
        "\(AppMetadata.tagline)\n\n\(AppMetadata.summary)\n\nTác giả: \(AppMetadata.author)\n\nSnapshot • System diff • Local only",
      attributes: [
        .font: NSFont.systemFont(ofSize: 11),
        .foregroundColor: NSColor.secondaryLabelColor,
        .paragraphStyle: paragraph,
      ]
    )
    NSApp.orderFrontStandardAboutPanel(options: [
      .applicationName: AppMetadata.name,
      .applicationVersion: AppMetadata.version,
      .version: "Build \(AppMetadata.build)",
      .credits: credits,
    ])
    NSApp.activate(ignoringOtherApps: true)
  }
}
