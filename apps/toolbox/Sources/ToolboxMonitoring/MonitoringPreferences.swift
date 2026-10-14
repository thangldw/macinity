import Foundation

public enum MenuBarIndicator: String, Sendable, CaseIterable {
  case cpu, memory, network
}

public enum SamplingPolicy {
  public static func mode(
    appActive: Bool, mainWindowVisible: Bool, sleeping: Bool, menuBarEnabled: Bool
  ) -> MonitoringMode {
    if sleeping { return .paused }
    if appActive && mainWindowVisible { return .active }
    return menuBarEnabled ? .menuBar : .paused
  }
}
