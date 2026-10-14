import Darwin
import Foundation
import ToolboxCore

public struct NetworkSocket: Identifiable, Sendable {
  public let id: String
  public let pid: Int32
  public let processName: String
  public let transport: String
  public let endpoint: String
  public let state: String
  public let identity: ProcessIdentity?
}

public struct NetworkInspection: Sendable {
  public let observedAt: Date
  public let sockets: [NetworkSocket]
  public let omitted: Int

  public static func read() throws -> NetworkInspection {
    let access = SystemProcessAccess()
    var pids = [Int32](repeating: 0, count: 4096)
    let bytes = pids.withUnsafeMutableBytes {
      proc_listpids(UInt32(PROC_ALL_PIDS), 0, $0.baseAddress, Int32($0.count))
    }
    var before: [Int32: ProcessIdentity] = [:]
    if bytes > 0 {
      for pid in pids.prefix(min(Int(bytes) / MemoryLayout<Int32>.size, pids.count)) where pid > 0 {
        try Task.checkCancellation()
        before[pid] = try? access.metadata(pid: pid).identity
      }
    }
    let text = String(decoding: try SystemInspectionRead.networkSockets.read(), as: UTF8.self)
    let parsed = parse(text)
    var verified: [Int32: ProcessIdentity] = [:]
    for pid in Set(parsed.sockets.map(\.pid)) {
      if let expected = before[pid], (try? access.metadata(pid: pid).identity) == expected {
        verified[pid] = expected
      }
    }
    return NetworkInspection(
      observedAt: Date(),
      sockets: parsed.sockets.map {
        NetworkSocket(
          id: $0.id, pid: $0.pid, processName: $0.processName,
          transport: $0.transport, endpoint: $0.endpoint, state: $0.state,
          identity: verified[$0.pid])
      }, omitted: parsed.omitted)
  }

  /// lsof field output preserves spaces and IPv6 addresses; a socket starts at each f field.
  public static func parse(_ text: String) -> NetworkInspection {
    var sockets: [NetworkSocket] = []
    var pid: Int32 = 0
    var name = ""
    var fd: String?
    var transport = ""
    var endpoint = ""
    var state = ""
    var omitted = 0
    func flush() {
      guard let fd, pid > 0, !endpoint.isEmpty, transport == "TCP" || transport == "UDP" else {
        return
      }
      guard sockets.count < 1024 else {
        omitted += 1
        return
      }
      sockets.append(
        .init(
          id: "\(pid):\(fd):\(sockets.count)", pid: pid,
          processName: name, transport: transport, endpoint: endpoint,
          state: state.isEmpty ? "Unknown" : state, identity: nil))
    }
    for line in text.split(separator: "\n") {
      guard let field = line.first else { continue }
      let value = String(line.dropFirst().prefix(2048))
      switch field {
      case "p":
        flush()
        fd = nil
        pid = Int32(value) ?? 0
        name = ""
      case "c": name = value
      case "f":
        flush()
        fd = value
        transport = ""
        endpoint = ""
        state = ""
      case "P": transport = value
      case "n": endpoint = value
      case "T": if value.hasPrefix("ST=") { state = String(value.dropFirst(3)) }
      default: break
      }
    }
    flush()
    return NetworkInspection(observedAt: Date(), sockets: sockets, omitted: omitted)
  }
}
