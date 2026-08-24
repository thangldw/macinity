import AppKit
import SwiftUI
import ToolboxCore
import ToolboxStorage

@main
struct ToolboxApp: App {
  @NSApplicationDelegateAdaptor(ToolboxAppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup("Toolbox") {
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

    Settings {
      SettingsView()
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

@MainActor
final class ToolboxAppDelegate: NSObject, NSApplicationDelegate {
  private var fallbackWindowController: NSWindowController?
  private let isScheduledScan = ProcessInfo.processInfo.arguments.contains("--scheduled-scan")

  func applicationDidFinishLaunching(_ notification: Notification) {
    if isScheduledScan {
      NSApp.setActivationPolicy(.accessory)
      for window in NSApp.windows { window.orderOut(nil) }
      Task {
        await ScheduledScanService().runNow()
        NSApp.terminate(nil)
      }
      return
    }
    NSApp.setActivationPolicy(.regular)
    ensureMainWindow()
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
  {
    guard !isScheduledScan else { return false }
    ensureMainWindow()
    return true
  }

  private func ensureMainWindow() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
      if let window = NSApp.windows.first(where: { $0.isVisible }) {
        window.isRestorable = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
      }

      if let controller = self?.fallbackWindowController {
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
      }

      let hostingController = NSHostingController(rootView: ToolboxShellView())
      let window = NSWindow(contentViewController: hostingController)
      window.title = "Toolbox"
      window.identifier = NSUserInterfaceItemIdentifier("toolbox-fallback-main")
      window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
      window.setContentSize(NSSize(width: 1_120, height: 760))
      window.minSize = NSSize(width: 960, height: 640)
      window.isRestorable = false
      window.center()

      let controller = NSWindowController(window: window)
      self?.fallbackWindowController = controller
      controller.showWindow(nil)
      window.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
    }
  }
}
