import Darwin
import Foundation

public struct NetworkAdapter: Identifiable, Sendable {
  public var id: String { name }
  public let name: String
  public let kind: String
  public let active: Bool
  public let addresses: [String]
  public let mtu: Int
  public let received: UInt64?
  public let sent: UInt64?
  public let inputPackets: UInt64?
  public let outputPackets: UInt64?
  public let inputErrors: UInt64?
  public let outputErrors: UInt64?
  public let drops: UInt64?
  public let media: String?
  public let carrier: String?
}

public struct WiFiReading: Sendable {
  public let interface: String
  public let ssid: String?
  public let bssid: String?
  public let rssi: Int?
  public let noise: Int?
  public let channel: Int?
  public let band: String?
  public let widthMHz: Int?
  public let transmitMbps: Double?
  public var snr: Int? {
    guard let rssi, let noise else { return nil }
    return rssi - noise
  }
}

public struct NetworkOverview: Sendable {
  public let observedAt: Date
  public let adapters: [NetworkAdapter]
  public let primary: String?
  public let gateway4: String?
  public let gateway6: String?
  public let dns: [String]
  public let wifi: [WiFiReading]
  public let omittedAdapters: Int
}

public struct NearbyWiFi: Identifiable, Sendable {
  public var security: String = "Unknown"
  public let id: String
  public let ssid: String?
  public let bssid: String?
  public let channel: Int?
  public let band: String?
  public let rssi: Int?
  public let noise: Int?
}

public struct NearbyWiFiScan: Sendable {
  public let observedAt: Date
  public let networks: [NearbyWiFi]
  public let omitted: Int
}

public enum NetworkTarget {
  public static func isNumericIP(_ host: String) -> Bool {
    var v4 = in_addr()
    var v6 = in6_addr()
    let unscoped = String(host.split(separator: "%", omittingEmptySubsequences: false).first ?? "")
    return inet_pton(AF_INET, host, &v4) == 1 || inet_pton(AF_INET6, unscoped, &v6) == 1
  }
  /// One host argument, not a URL, executable option, credential or shell expression.
  public static func validate(_ raw: String) -> String? {
    let host = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !host.isEmpty, host.utf8.count <= 253, !host.hasPrefix("-"),
      host.unicodeScalars.allSatisfy({
        CharacterSet(
          charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-:%_"
        ).contains($0)
      }), !host.contains("..")
    else { return nil }
    // Reject malformed port/IPv6 mixtures; a colon-bearing target must be numeric IPv6.
    if host.contains(":") {
      let numeric = host.split(separator: "%", omittingEmptySubsequences: false)
      var address = in6_addr()
      guard numeric.count <= 2, inet_pton(AF_INET6, String(numeric[0]), &address) == 1,
        numeric.count == 1 || !numeric[1].isEmpty, numeric[0].contains(":"),
        numeric[0].allSatisfy({ $0.isHexDigit || $0 == ":" })
      else { return nil }
    } else {
      guard
        host.split(separator: ".", omittingEmptySubsequences: false).allSatisfy({
          !$0.isEmpty && !$0.hasPrefix("-") && !$0.hasSuffix("-") && $0.count <= 63
        })
      else { return nil }
    }
    return host
  }
}

public struct LatencySample: Identifiable, Sendable {
  public var id: Int { sequence }
  public let sequence: Int
  public let milliseconds: Double?
}

public struct LatencyReport: Sendable {
  public let target: String
  public let observedAt: Date
  public let samples: [LatencySample]
  public let transmitted: Int?
  public let received: Int?
  public let exitStatus: Int32
  public var lossPercent: Double? {
    guard let transmitted, let received, transmitted > 0, received <= transmitted else {
      return nil
    }
    return Double(transmitted - received) * 100 / Double(transmitted)
  }
  public var meanMilliseconds: Double? {
    let values = samples.compactMap(\.milliseconds)
    return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
  }
  /// Mean absolute difference of successive received samples; a timeout breaks adjacency.
  public var jitterMilliseconds: Double? {
    let deltas = zip(samples, samples.dropFirst()).compactMap { a, b -> Double? in
      guard b.sequence == a.sequence + 1, let av = a.milliseconds, let bv = b.milliseconds else {
        return nil
      }
      return abs(bv - av)
    }
    return deltas.isEmpty ? nil : deltas.reduce(0, +) / Double(deltas.count)
  }

  public static func parse(_ text: String, target: String, exitStatus: Int32) -> Self {
    var receivedValues: [Int: Double] = [:]
    var transmitted: Int?
    var received: Int?
    for line in text.split(separator: "\n") {
      if let sequenceRange = line.range(of: "icmp_seq="),
        let sequence = Int(line[sequenceRange.upperBound...].prefix(while: { $0.isNumber })),
        sequence >= 0, sequence < 20,
        let timeRange = line.range(of: "time="),
        let value = Double(
          line[timeRange.upperBound...].prefix(while: { $0.isNumber || $0 == "." })),
        value.isFinite, value >= 0
      {
        if receivedValues[sequence] == nil { receivedValues[sequence] = value }
      }
      if line.contains("packets transmitted"), line.contains("packets received") {
        let fields = line.split(separator: ",")
        transmitted = fields.first.flatMap {
          Int($0.trimmingCharacters(in: .whitespaces).split(separator: " ").first ?? "")
        }
        received = fields.dropFirst().first.flatMap {
          Int($0.trimmingCharacters(in: .whitespaces).split(separator: " ").first ?? "")
        }
      }
    }
    let count = min(20, max(0, transmitted ?? ((receivedValues.keys.max() ?? -1) + 1)))
    return Self(
      target: target, observedAt: Date(),
      samples: (0..<count).map {
        LatencySample(sequence: $0, milliseconds: receivedValues[$0])
      }, transmitted: transmitted, received: received, exitStatus: exitStatus)
  }
}

public struct ConnectionCheck: Identifiable, Sendable {
  public let id: String
  public let target: String
  public let succeeded: Bool?
  public let observedAt = Date()
  public let durationMilliseconds: Double
  public let detail: String
}

public struct NetworkObservationChange: Identifiable, Sendable {
  public let id = UUID()
  public let observedAt: Date
  public let field: String
  public let before: String
  public let after: String
}

public struct NetworkOverviewChanges: Sendable {
  public private(set) var events: [NetworkObservationChange] = []
  public private(set) var omitted = 0
  private var previous: [String: String]?
  private var previousAt: Date?
  public init() {}
  public mutating func reset() {
    previous = nil
    previousAt = nil
  }
  public mutating func clear() {
    reset()
    events = []
    omitted = 0
  }
  public mutating func consume(_ value: NetworkOverview) {
    guard value.omittedAdapters == 0 else {
      reset()
      return
    }
    var fields: [String: String] = [
      "Primary interface": value.primary ?? "Unavailable",
      "IPv4 gateway": value.gateway4 ?? "Unavailable",
      "IPv6 gateway": value.gateway6 ?? "Unavailable",
      "DNS servers": value.dns.sorted().joined(separator: ", "),
    ]
    for adapter in value.adapters {
      fields[adapter.name + " • Interface flags"] = adapter.active ? "Active" : "Inactive"
      if let carrier = adapter.carrier, carrier == "active" || carrier == "inactive" {
        fields[adapter.name + " • Carrier state"] =
          carrier == "active" ? "Link detected" : "No link detected"
      }
      fields[adapter.name + " • IP addresses"] = adapter.addresses.sorted().joined(separator: ", ")
    }
    for wifi in value.wifi {
      // A redacted identity is unknown, not evidence of disconnection or roaming.
      if let ssid = wifi.ssid { fields[wifi.interface + " • SSID"] = ssid }
      if let bssid = wifi.bssid { fields[wifi.interface + " • BSSID"] = bssid }
    }
    defer {
      previous = fields
      previousAt = value.observedAt
    }
    guard let previous, let previousAt, value.observedAt.timeIntervalSince(previousAt) >= 0,
      value.observedAt.timeIntervalSince(previousAt) <= 600, value.omittedAdapters == 0
    else { return }
    for key in fields.keys.sorted() {
      if let old = previous[key], let new = fields[key], old != new {
        events.append(.init(observedAt: value.observedAt, field: key, before: old, after: new))
      }
    }
    if events.count > 200 {
      omitted += events.count - 200
      events.removeFirst(events.count - 200)
    }
  }
}
