import Foundation

public struct NetworkChange: Identifiable, Sendable {
  public let id = UUID()
  public let observedAt: Date
  public let kind: String
  public let socket: NetworkSocket
  public let previousState: String?
}

public struct NetworkChangeTracker: Sendable {
  private struct Key: Hashable, Sendable {
    let identity: ProcessIdentity
    let transport: String
    let endpoint: String
  }
  private var previous: [Key: NetworkSocket]?
  private var observedAt: Date?
  public private(set) var events: [NetworkChange] = []
  public private(set) var omittedEvents = 0
  public private(set) var unverifiedSockets = 0
  public private(set) var baselineEstablished = false
  public init() {}
  public mutating func invalidate() {
    previous = nil
    observedAt = nil
    baselineEstablished = false
  }

  public mutating func update(_ inspection: NetworkInspection) {
    unverifiedSockets = inspection.sockets.filter { $0.identity == nil }.count
    guard inspection.omitted == 0 else {
      invalidate()
      return
    }
    var next: [Key: NetworkSocket] = [:]
    for socket in inspection.sockets {
      guard let identity = socket.identity else { continue }
      let key = Key(identity: identity, transport: socket.transport, endpoint: socket.endpoint)
      // Multiple descriptors for one endpoint are coalesced; conflicting states are unknown.
      if let other = next[key], other.state != socket.state {
        next[key] = NetworkSocket(
          id: socket.id, pid: socket.pid, processName: socket.processName,
          transport: socket.transport, endpoint: socket.endpoint, state: "Unknown",
          identity: identity)
      } else {
        next[key] = socket
      }
    }
    if let previous, let observedAt, inspection.observedAt > observedAt,
      inspection.observedAt.timeIntervalSince(observedAt) <= 600
    {
      var changes: [NetworkChange] = []
      for (key, socket) in next {
        if let old = previous[key] {
          if old.state != socket.state {
            changes.append(
              NetworkChange(
                observedAt: inspection.observedAt, kind: "State changed",
                socket: socket, previousState: old.state))
          }
        } else {
          changes.append(
            NetworkChange(
              observedAt: inspection.observedAt, kind: "Newly observed",
              socket: socket, previousState: nil))
        }
      }
      for (key, socket) in previous where next[key] == nil {
        changes.append(
          NetworkChange(
            observedAt: inspection.observedAt, kind: "No longer observed",
            socket: socket, previousState: nil))
      }
      changes.sort {
        ($0.socket.pid, $0.socket.endpoint, $0.kind) < ($1.socket.pid, $1.socket.endpoint, $1.kind)
      }
      let combined = changes + events
      omittedEvents += max(0, combined.count - 200)
      events = Array(combined.prefix(200))
    }
    previous = next
    observedAt = inspection.observedAt
    baselineEstablished = true
  }
  public mutating func clear() { self = NetworkChangeTracker() }
}
