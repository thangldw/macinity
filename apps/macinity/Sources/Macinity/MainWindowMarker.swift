import AppKit
import MacinityCore
import MacinityMonitoring
import SwiftUI

struct MainWindowMarker: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView { MarkedMainWindowView() }
  func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class MarkedMainWindowView: NSView {
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    guard let window else { return }
    window.identifier = NSUserInterfaceItemIdentifier("macinity-main")
    MacinityRuntime.shared.monitoring.setMainWindowVisible(
      monitoringWindowInUse(window))
  }
}

@MainActor
func monitoringWindowInUse(_ window: NSWindow) -> Bool {
  // An attached inspector/export sheet remains part of the monitoring workspace.
  // An independent Settings window does not create monitoring demand.
  window.isVisible && !window.isMiniaturized
    && (window.isKeyWindow || window.attachedSheet?.isKeyWindow == true)
}

struct MonitoringDisplayState: Equatable {
  var paused = false
  var minimumMaximumAge = 0.0

  func availability<Value>(
    of sample: MetricSample<Value>, at now: Double, maximumAge: Double
  ) -> MetricAvailability {
    let state = sample.freshness(at: now, maximumAge: max(maximumAge, minimumMaximumAge))
    return paused && state == .available ? .stale : state
  }
}

private struct MonitoringDisplayStateKey: EnvironmentKey {
  static let defaultValue = MonitoringDisplayState()
}

extension EnvironmentValues {
  var monitoringDisplayState: MonitoringDisplayState {
    get { self[MonitoringDisplayStateKey.self] }
    set { self[MonitoringDisplayStateKey.self] = newValue }
  }
}

struct MacinityFallbackRootView: View {
  @AppStorage(AppAppearance.storageKey) private var appearanceCode = AppAppearance.system.rawValue
  @ObservedObject private var monitoring = MacinityRuntime.shared.monitoring
  var body: some View {
    MacinityShellView()
      .preferredColorScheme((AppAppearance(rawValue: appearanceCode) ?? .system).scheme)
      .environment(
        \.monitoringDisplayState,
        MonitoringDisplayState(
          paused: monitoring.samplingMode == .paused,
          minimumMaximumAge: monitoring.samplingMode == .menuBar ? 15 : 0))
  }
}
