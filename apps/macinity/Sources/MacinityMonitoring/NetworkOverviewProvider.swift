import CoreWLAN
import Darwin
import Foundation
import SystemConfiguration

public enum NetworkOverviewProvider {
  public static func read() throws -> NetworkOverview {
    try Task.checkCancellation()
    let store = SCDynamicStoreCreate(nil, "Macinity Network Observation" as CFString, nil, nil)
    func dictionary(_ key: String) -> [String: Any] {
      guard let store else { return [:] }
      return SCDynamicStoreCopyValue(store, key as CFString) as? [String: Any] ?? [:]
    }
    let ipv4 = dictionary("State:/Network/Global/IPv4")
    let ipv6 = dictionary("State:/Network/Global/IPv6")
    let dns = dictionary("State:/Network/Global/DNS")["ServerAddresses"] as? [String] ?? []
    let configured = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] ?? []
    var kinds: [String: String] = [:]
    for interface in configured {
      guard let name = SCNetworkInterfaceGetBSDName(interface) as String? else { continue }
      let type = SCNetworkInterfaceGetInterfaceType(interface) as String?
      kinds[name] =
        type == (kSCNetworkInterfaceTypeIEEE80211 as String)
        ? "Wi-Fi" : type == (kSCNetworkInterfaceTypeEthernet as String) ? "Ethernet" : "Other"
    }
    var linked: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&linked) == 0 else { throw CocoaError(.fileReadUnknown) }
    defer { freeifaddrs(linked) }
    var entries: [String: (flags: UInt32, addresses: [String], data: if_data?)] = [:]
    var cursor = linked
    while let node = cursor {
      defer { cursor = node.pointee.ifa_next }
      let value = node.pointee
      let name = String(cString: value.ifa_name)
      var entry = entries[name] ?? (value.ifa_flags, [], nil)
      guard let address = value.ifa_addr else { continue }
      let family = Int32(address.pointee.sa_family)
      if family == AF_INET || family == AF_INET6 {
        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        if getnameinfo(
          address, socklen_t(address.pointee.sa_len), &host, socklen_t(host.count), nil, 0,
          NI_NUMERICHOST) == 0
        {
          entry.addresses.append(
            String(
              decoding: host.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self
            ))
        }
      } else if family == AF_LINK, let data = value.ifa_data {
        entry.data = data.assumingMemoryBound(to: if_data.self).pointee
      }
      entries[name] = entry
    }
    let byteCounters = SystemNetworkCounters.read()
    let mediaDeadline = ProcessInfo.processInfo.systemUptime + 6
    let names = entries.keys.sorted()
    var adapters: [NetworkAdapter] = []
    var wifi: [WiFiReading] = []
    for name in names.prefix(32) {
      try Task.checkCancellation()
      guard let value = entries[name] else { continue }
      let kind = kinds[name] ?? "Other"
      var media: String?
      var carrier: String?
      if kind == "Ethernet", ProcessInfo.processInfo.systemUptime < mediaDeadline,
        let result = try? NetworkToolsProcess.read(.media(name)), result.status == 0
      {
        carrier = result.text.split(separator: "\n").first(where: {
          $0.trimmingCharacters(in: .whitespaces).hasPrefix("status:")
        }).map {
          String($0.trimmingCharacters(in: .whitespaces).dropFirst(7)).trimmingCharacters(
            in: .whitespaces)
        }
        media = result.text.split(separator: "\n").first(where: {
          $0.trimmingCharacters(in: .whitespaces).hasPrefix("media:")
        }).map {
          String($0.trimmingCharacters(in: .whitespaces).dropFirst(6)).trimmingCharacters(
            in: .whitespaces)
        }
      }
      adapters.append(
        .init(
          name: name, kind: kind,
          active: value.flags & UInt32(IFF_UP) != 0 && value.flags & UInt32(IFF_RUNNING) != 0,
          addresses: Array(Set(value.addresses)).sorted(), mtu: Int(value.data?.ifi_mtu ?? 0),
          received: byteCounters?[if_nametoindex(name)]?.input,
          sent: byteCounters?[if_nametoindex(name)]?.output,
          inputPackets: value.data.map { UInt64($0.ifi_ipackets) },
          outputPackets: value.data.map { UInt64($0.ifi_opackets) },
          inputErrors: value.data.map { UInt64($0.ifi_ierrors) },
          outputErrors: value.data.map { UInt64($0.ifi_oerrors) },
          drops: value.data.map { UInt64($0.ifi_iqdrops) }, media: media, carrier: carrier))
      if kind == "Wi-Fi", let interface = CWWiFiClient.shared().interface(withName: name) {
        let channel = interface.wlanChannel()
        let rssi = interface.rssiValue()
        let noise = interface.noiseMeasurement()
        let rate = interface.transmitRate()
        wifi.append(
          .init(
            interface: name, ssid: interface.ssid(), bssid: interface.bssid(),
            rssi: rssi < 0 ? rssi : nil, noise: noise < 0 ? noise : nil,
            channel: channel.map { Int($0.channelNumber) }, band: channel.map { band($0) },
            widthMHz: channel.flatMap { width($0) },
            transmitMbps: rate > 0 && rate.isFinite ? rate : nil))
      }
    }
    try Task.checkCancellation()
    let primary = ipv4["PrimaryInterface"] as? String ?? ipv6["PrimaryInterface"] as? String
    var gateway6 = ipv6["Router"] as? String
    if let gateway = gateway6, gateway.lowercased().hasPrefix("fe80:"), !gateway.contains("%"),
      let interface = ipv6["PrimaryInterface"] as? String
    {
      gateway6 = gateway + "%" + interface
    }
    return NetworkOverview(
      observedAt: Date(), adapters: adapters,
      primary: primary,
      gateway4: ipv4["Router"] as? String, gateway6: gateway6,
      dns: Array(dns.prefix(32)), wifi: wifi, omittedAdapters: max(0, names.count - 32))
  }
  public static func scan() throws -> NearbyWiFiScan {
    try Task.checkCancellation()
    guard let interface = CWWiFiClient.shared().interface() else {
      throw CocoaError(.featureUnsupported)
    }
    // CoreWLAN owns scan duration. Cancellation suppresses publication after the OS call returns.
    let networks = try interface.scanForNetworks(withSSID: nil)
    try Task.checkCancellation()
    let sorted = networks.sorted { $0.rssiValue > $1.rssiValue }
    return NearbyWiFiScan(
      observedAt: Date(),
      networks: sorted.prefix(128).enumerated().map { index, network in
        NearbyWiFi(
          security: WiFiUtilities.scanSecurity(network), id: String(index), ssid: network.ssid,
          bssid: network.bssid,
          channel: network.wlanChannel.map { Int($0.channelNumber) },
          band: network.wlanChannel.map { band($0) },
          rssi: network.rssiValue < 0 ? network.rssiValue : nil,
          noise: network.noiseMeasurement < 0 ? network.noiseMeasurement : nil)
      }, omitted: max(0, sorted.count - 128))
  }
  private static func band(_ channel: CWChannel) -> String {
    switch channel.channelBand {
    case .band2GHz: "2.4 GHz"
    case .band5GHz: "5 GHz"
    case .band6GHz: "6 GHz"
    default: "Unknown"
    }
  }
  private static func width(_ channel: CWChannel) -> Int? {
    switch channel.channelWidth {
    case .width20MHz: 20
    case .width40MHz: 40
    case .width80MHz: 80
    case .width160MHz: 160
    default: nil
    }
  }
}
