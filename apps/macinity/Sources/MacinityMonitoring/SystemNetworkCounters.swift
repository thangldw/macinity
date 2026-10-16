import Darwin
import Foundation

struct NetworkByteCounters: Sendable {
  let input: UInt64
  let output: UInt64
}

enum SystemNetworkCounters {
  static func read() -> [UInt32: NetworkByteCounters]? {
    var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, AF_LINK, NET_RT_IFLIST2, 0]
    var size = 0
    guard sysctl(&mib, UInt32(mib.count), nil, &size, nil, 0) == 0,
      size > 0, size <= 16 * 1024 * 1024
    else { return nil }
    var bytes = Data(count: size)
    let result = bytes.withUnsafeMutableBytes {
      sysctl(&mib, UInt32(mib.count), $0.baseAddress, &size, nil, 0)
    }
    guard result == 0, size <= bytes.count else { return nil }
    bytes.count = size
    return decode(bytes)
  }

  static func decode(_ bytes: Data) -> [UInt32: NetworkByteCounters]? {
    bytes.withUnsafeBytes { raw in
      var offset = 0
      var counters: [UInt32: NetworkByteCounters] = [:]
      while offset < raw.count {
        guard raw.count - offset >= 4 else { return nil }
        let length = Int(raw.loadUnaligned(fromByteOffset: offset, as: UInt16.self))
        guard length >= 4, length <= raw.count - offset else { return nil }
        let type = raw.load(fromByteOffset: offset + 3, as: UInt8.self)
        if type == UInt8(RTM_IFINFO2) {
          guard length >= MemoryLayout<if_msghdr2>.size else { return nil }
          let header = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr2.self)
          let index = UInt32(header.ifm_index)
          guard header.ifm_version == UInt8(RTM_VERSION), index > 0,
            counters[index] == nil
          else { return nil }
          counters[index] = NetworkByteCounters(
            input: header.ifm_data.ifi_ibytes, output: header.ifm_data.ifi_obytes)
        }
        offset += length
      }
      return counters
    }
  }
}
