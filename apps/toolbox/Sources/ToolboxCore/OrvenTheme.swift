import AppKit
import SwiftUI

/// Shared native appearance for monitoring and legacy management workspaces.
public enum OrvenTheme {
  public static let canvas: Color = adaptive(light: 0xF5F7FA, dark: 0x14283B)
  public static let surface: Color = adaptive(light: 0xFFFFFF, dark: 0x1C3247)
  public static let sidebar: Color = adaptive(light: 0xF0F4F9, dark: 0x172C40)
  public static let accent: Color = adaptive(light: 0x2464DF, dark: 0x73A8FF)
  public static var action: Color { Color(red: 36.0 / 255, green: 100.0 / 255, blue: 223.0 / 255) }
  public static let ink: Color = adaptive(light: 0x17263C, dark: 0xE5EDF7)
  public static let secondary: Color = adaptive(light: 0x586D8A, dark: 0xB0C0D6)
  public static let border: Color = adaptive(light: 0xE2E8F1, dark: 0x375069)

  private static func adaptive(light: UInt32, dark: UInt32) -> Color {
    Color(
      nsColor: NSColor(name: nil) { appearance in
        let hex = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        return NSColor(
          calibratedRed: Double((hex >> 16) & 255) / 255,
          green: Double((hex >> 8) & 255) / 255,
          blue: Double(hex & 255) / 255, alpha: 1)
      })
  }
}

extension View {
  public func orvenSurface(padding: CGFloat = 20) -> some View {
    self.padding(padding)
      .background(OrvenTheme.surface, in: RoundedRectangle(cornerRadius: 16))
      .overlay {
        RoundedRectangle(cornerRadius: 16).stroke(OrvenTheme.border, lineWidth: 1)
          .allowsHitTesting(false)
      }
  }
}

public enum AppAppearance: String, CaseIterable, Identifiable {
  case system, light, dark
  public static let storageKey = "toolbox.appearance"
  public var id: String { rawValue }
  public var scheme: ColorScheme? {
    switch self {
    case .system: nil
    case .light: .light
    case .dark: .dark
    }
  }
  public var title: String {
    switch self {
    case .system: L10n.text("System")
    case .light: L10n.text("Light")
    case .dark: L10n.text("Dark")
    }
  }
}
