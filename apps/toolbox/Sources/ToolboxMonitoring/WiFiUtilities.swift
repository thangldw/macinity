import CoreWLAN
import Foundation

public struct SavedWiFiNetwork: Sendable, Identifiable {
  public let id: String
  public let name: String?
  public let security: String
  public let interface: String
}
public enum WiFiUtilities {
  public static func security(_ value: CWSecurity) -> String {
    switch value {
    case .none: "Open"
    case .WEP, .dynamicWEP: "WEP"
    case .wpaPersonal, .wpaEnterprise: "WPA"
    case .wpaPersonalMixed, .wpaEnterpriseMixed: "WPA/WPA2"
    case .wpa2Personal, .wpa2Enterprise: "WPA2"
    case .wpa3Personal, .wpa3Enterprise: "WPA3"
    case .wpa3Transition: "WPA2/WPA3"
    case .OWE, .oweTransition: "OWE"
    default: "Unknown"
    }
  }
  public static func scanSecurity(_ network: CWNetwork) -> String {
    for value: CWSecurity in [
      .wpa3Transition, .wpa3Personal, .wpa3Enterprise, .wpa2Personal,
      .wpa2Enterprise, .wpaPersonalMixed, .wpaEnterpriseMixed,
      .wpaPersonal, .wpaEnterprise, .WEP, .dynamicWEP, .OWE, .oweTransition, .none,
    ] {
      if network.supportsSecurity(value) { return security(value) }
    }
    return "Unknown"
  }
  public static func saved() throws -> [SavedWiFiNetwork] {
    guard let interfaces = CWWiFiClient.shared().interfaces(), !interfaces.isEmpty else {
      throw CocoaError(.featureUnsupported)
    }
    var result: [SavedWiFiNetwork] = []
    for interface in interfaces.prefix(8) {
      try Task.checkCancellation()
      guard let profiles = interface.configuration()?.networkProfiles.array as? [CWNetworkProfile]
      else { continue }
      for (index, profile) in profiles.prefix(512).enumerated() {
        result.append(
          .init(
            id: "\(interface.interfaceName ?? "wifi"):\(index)", name: profile.ssid,
            security: security(profile.security), interface: interface.interfaceName ?? "Wi-Fi"))
      }
    }
    return result
  }
  public static func qrPayload(ssid: String, password: String, open: Bool, hidden: Bool) throws
    -> String
  {
    guard !ssid.isEmpty, ssid.utf8.count <= 32,
      !ssid.contains(where: { $0.isNewline || $0 == "\0" }),
      password.utf8.count <= 128, !password.contains(where: { $0.isNewline || $0 == "\0" }),
      open || !password.isEmpty
    else { throw CocoaError(.validationMissingMandatoryProperty) }
    func escape(_ value: String) -> String {
      value.reduce(into: "") { output, character in
        if "\\;,:\"".contains(character) { output.append("\\") }
        output.append(character)
      }
    }
    return
      "WIFI:T:\(open ? "nopass" : "WPA");S:\(escape(ssid));P:\(open ? "" : escape(password));H:\(hidden ? "true" : "false");;"
  }
}
