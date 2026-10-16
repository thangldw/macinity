import Foundation

public struct DeviceEntry: Sendable, Identifiable, Equatable {
  public let id: String
  public let category: String
  public let name: String
  public let fields: [String]
}
public struct DeviceInventory: Sendable {
  public let entries: [DeviceEntry]
  public let observedAt: Date
  public let truncated: Bool
  public static func read() throws -> Self {
    let result = try UtilityCommand.profileDevices.read()
    guard result.status == 0 else { throw CocoaError(.fileReadUnknown) }
    return try parse(Data(result.text.utf8))
  }
  public static func parse(_ data: Data) throws -> Self {
    guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw CocoaError(.fileReadCorruptFile)
    }
    var result: [DeviceEntry] = []
    var truncated = false
    let accepted = [
      "manufacturer", "vendor", "product", "speed", "current", "power", "battery", "resolution",
      "connected", "transport", "sample_rate", "channels", "online", "interface", "version",
    ]
    func walk(_ object: Any, category: String, path: String, depth: Int) {
      guard depth <= 12, result.count < 500 else {
        truncated = true
        return
      }
      if let array = object as? [Any] {
        for (index, child) in array.prefix(500).enumerated() {
          walk(child, category: category, path: path + "/\(index)", depth: depth + 1)
        }
        if array.count > 500 { truncated = true }
      } else if let dictionary = object as? [String: Any] {
        let name = dictionary["_name"] as? String
        var fields = dictionary.keys.sorted().compactMap { key -> String? in
          let lower = key.lowercased()
          guard !lower.contains("serial"), !lower.contains("address"), !lower.contains("uuid"),
            accepted.contains(where: { lower.contains($0) }), let value = dictionary[key],
            value is String || value is NSNumber
          else { return nil }
          var label = key
          for prefix in ["_spdisplays_", "spdisplays_", "controller_", "device_", "sppci_"] {
            if label.hasPrefix(prefix) { label = String(label.dropFirst(prefix.count)) }
          }
          label =
            label.replacingOccurrences(
              of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression
            ).replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
            .capitalized
          var display = String(String(describing: value).prefix(200))
          for prefix in ["spdisplays_", "sppci_vendor_"] {
            if display.hasPrefix(prefix) { display = String(display.dropFirst(prefix.count)) }
          }
          if display == "yes" { display = "Yes" }
          if display == "no" { display = "No" }
          return label + ": " + display
        }
        if category == "SPBluetoothDataType",
          name != nil || !fields.isEmpty
            || dictionary.keys.contains(where: {
              $0.hasPrefix("device_") && $0 != "device_connected" && $0 != "device_not_connected"
            })
        {
          if path.contains("device_not_connected") {
            fields.insert("Connection: Not connected", at: 0)
          } else if path.contains("device_connected") {
            fields.insert("Connection: Connected", at: 0)
          }
        }
        if let name, !name.isEmpty {
          result.append(
            .init(
              id: category + path + "/" + name, category: category, name: String(name.prefix(200)),
              fields: Array(fields.prefix(24))))
        } else if !fields.isEmpty {
          result.append(
            .init(
              id: category + path, category: category,
              name: (path.components(separatedBy: "/").last ?? category).replacingOccurrences(
                of: "_", with: " "
              ).capitalized,
              fields: Array(fields.prefix(24))))
        }
        for key in dictionary.keys.sorted() {
          if dictionary[key] is [Any] || dictionary[key] is [String: Any] {
            walk(dictionary[key]!, category: category, path: path + "/" + key, depth: depth + 1)
          }
        }
      }
    }
    for key in [
      "SPUSBDataType", "SPThunderboltDataType", "SPDisplaysDataType", "SPAudioDataType",
      "SPBluetoothDataType",
    ] {
      if let value = root[key] { walk(value, category: key, path: "", depth: 0) }
    }
    return .init(entries: result, observedAt: Date(), truncated: truncated)
  }
}
