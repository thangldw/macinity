import AppKit
import SwiftUI

@main
struct DiskoraApp: App {
  private let isScheduledScan = ProcessInfo.processInfo.arguments.contains("--scheduled-scan")

  var body: some Scene {
    WindowGroup {
      if isScheduledScan {
        ScheduledScanRunnerView()
      } else {
        ContentView()
      }
    }
    .windowStyle(.titleBar)
    .commands {
      CommandGroup(replacing: .appInfo) {
        Button(L10n.text("Giới thiệu Diskora")) {
          showAboutPanel()
        }
      }
      CommandGroup(replacing: .newItem) {}
    }
  }

  private func showAboutPanel() {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let credits = NSAttributedString(
      string:
        "\(L10n.text(AppMetadata.tagline))\n\n\(L10n.text(AppMetadata.summary))\n\n\(L10n.text("Tác giả")): \(AppMetadata.author)\n\n\(L10n.text("Phân tích dung lượng • Tệp trùng lặp • Dọn dẹp Developer"))",
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

private struct ScheduledScanRunnerView: View {
  var body: some View {
    ProgressView().frame(width: 1, height: 1)
      .task {
        await ScheduledScanService().runNow()
        NSApp.terminate(nil)
      }
  }
}
