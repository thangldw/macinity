import Foundation
import MacinityCore

/// Actions reachable through the `macinity://` URL scheme (usable from Shortcuts "Open URLs").
/// Deliberately limited to non-destructive operations: navigation and Keep Awake.
enum MacinityURLAction: Equatable {
  case open(MacinitySection)
  case keepAwake(minutes: Int)
  case stopKeepAwake

  static let scheme = "macinity"
  static let allowedKeepAwakeMinutes = [15, 30, 60]

  /// - `macinity://open/<section>` (section raw value, for example `diagnostics`)
  /// - `macinity://keep-awake?minutes=15|30|60`
  /// - `macinity://keep-awake/stop`
  static func parse(_ url: URL) -> MacinityURLAction? {
    guard url.scheme?.lowercased() == scheme, let host = url.host?.lowercased() else { return nil }
    let components = url.pathComponents.filter { $0 != "/" }
    switch host {
    case "open":
      guard components.count == 1, let section = MacinitySection(rawValue: components[0]) else {
        return nil
      }
      return .open(section)
    case "keep-awake":
      if components == ["stop"] { return .stopKeepAwake }
      guard components.isEmpty,
        let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
          .first(where: { $0.name == "minutes" })?.value,
        let minutes = Int(value), allowedKeepAwakeMinutes.contains(minutes)
      else { return nil }
      return .keepAwake(minutes: minutes)
    default:
      return nil
    }
  }

  @MainActor func perform(
    keepAwake: KeepAwakeController = .shared,
    navigation: MacinityCoordinator = MacinityRuntime.shared.navigation
  ) {
    switch self {
    case .open(let section): navigation.open(.section(section))
    case .keepAwake(let minutes): keepAwake.start(minutes: minutes, pid: nil)
    case .stopKeepAwake: keepAwake.stop()
    }
  }
}
