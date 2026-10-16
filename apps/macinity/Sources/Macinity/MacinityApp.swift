import AppKit
import MacinityCore
import MacinityStorage
import SwiftUI

@main
struct MacinityApp: App {
  @NSApplicationDelegateAdaptor(MacinityAppDelegate.self) private var appDelegate

  @AppStorage(AppAppearance.storageKey) private var appearanceCode = AppAppearance.system.rawValue
  private var preferredScheme: ColorScheme? {
    (AppAppearance(rawValue: appearanceCode) ?? .system).scheme
  }

  @StateObject private var monitoring = MacinityRuntime.shared.monitoring
  private var menuBarInsertion: Binding<Bool> {
    Binding(
      get: {
        monitoring.menuBarEnabled && !ProcessInfo.processInfo.arguments.contains("--scheduled-scan")
      },
      set: { if monitoring.menuBarEnabled != $0 { monitoring.menuBarEnabled = $0 } })
  }

  var body: some Scene {
    WindowGroup(AppMetadata.displayName) {
      MacinityShellView()
        .preferredColorScheme(preferredScheme)
        .environment(
          \.monitoringDisplayState,
          MonitoringDisplayState(
            paused: monitoring.samplingMode == .paused,
            minimumMaximumAge: monitoring.samplingMode == .menuBar ? 15 : 0))
    }
    .windowStyle(.titleBar)
    .defaultSize(width: 1_320, height: 900)
    .commands {
      CommandGroup(replacing: .appInfo) {
        Button(L10n.text("About Macinity")) { showAboutPanel() }
      }
      CommandGroup(replacing: .newItem) {}
    }

    Settings { SettingsView().preferredColorScheme(preferredScheme) }

    MenuBarExtra(isInserted: menuBarInsertion) {
      MenuBarDiagnosticsView(model: monitoring).preferredColorScheme(preferredScheme)
    } label: {
      HStack(spacing: 4) {
        Image(nsImage: AppBrand.menuIcon).accessibilityLabel(AppMetadata.displayName)
        Text(monitoring.menuBarTitle).monospacedDigit()
      }
    }
    .menuBarExtraStyle(.window)
  }

  private func showAboutPanel() {
    NSApp.orderFrontStandardAboutPanel(options: [
      .applicationName: AppMetadata.displayName,
      .applicationVersion: AppMetadata.version,
      .version: "Build \(AppMetadata.build)",
      .credits: NSAttributedString(string: L10n.text(AppMetadata.tagline)),
    ])
    NSApp.activate(ignoringOtherApps: true)
  }
}

@MainActor
final class MacinityAppDelegate: NSObject, NSApplicationDelegate {
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
    MacinityRuntime.shared.monitoring.start()
    let center = NSWorkspace.shared.notificationCenter
    center.addObserver(
      self, selector: #selector(willSleep), name: NSWorkspace.willSleepNotification, object: nil)
    center.addObserver(
      self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
    for name in [
      NSWindow.willCloseNotification, NSWindow.didMiniaturizeNotification,
      NSWindow.didDeminiaturizeNotification, NSWindow.didBecomeKeyNotification,
      NSWindow.didResignKeyNotification,
    ] {
      NotificationCenter.default.addObserver(
        self, selector: #selector(windowActivityChanged), name: name, object: nil)
    }
    MacinityRuntime.shared.monitoring.setActive(NSApp.isActive)
    ensureMainWindow()
  }

  @objc private func windowActivityChanged(_ notification: Notification) {
    DispatchQueue.main.async { self.refreshWindowVisibility() }
  }

  private func refreshWindowVisibility() {
    MacinityRuntime.shared.monitoring.setMainWindowVisible(
      NSApp.windows.contains {
        $0.identifier?.rawValue == "macinity-main" && monitoringWindowInUse($0)
      })
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
  {
    guard !isScheduledScan else { return false }
    ensureMainWindow()
    return true
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    guard !isScheduledScan else { return }
    MacinityRuntime.shared.monitoring.setActive(true)
  }

  func applicationDidResignActive(_ notification: Notification) {
    guard !isScheduledScan else { return }
    MacinityRuntime.shared.monitoring.setActive(false)
  }

  @objc private func willSleep() { MacinityRuntime.shared.monitoring.setSleeping(true) }
  @objc private func didWake() { MacinityRuntime.shared.monitoring.setSleeping(false) }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    guard !isScheduledScan else { return .terminateNow }
    Task {
      await MacinityRuntime.shared.monitoring.stop()
      NSWorkspace.shared.notificationCenter.removeObserver(self)
      NotificationCenter.default.removeObserver(self)
      sender.reply(toApplicationShouldTerminate: true)
    }
    return .terminateLater
  }

  private func ensureMainWindow() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
      if let window = NSApp.windows.first(where: {
        $0.identifier?.rawValue == "macinity-main"
      }) {
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

      let hostingController = NSHostingController(rootView: MacinityFallbackRootView())
      let window = NSWindow(contentViewController: hostingController)
      window.title = AppMetadata.displayName
      window.identifier = NSUserInterfaceItemIdentifier("macinity-main")
      window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
      window.setContentSize(NSSize(width: 1_320, height: 900))
      window.contentMinSize = NSSize(width: 960, height: 640)
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
