import Darwin
import Foundation

/// Only bounded network reads/probes. Arguments are passed directly, never through a shell.
enum NetworkToolsProcess {
  enum Operation {
    case media(String)
    case dns(String)
    case ping(String, Int)
    case tcp(String, Int)
  }
  struct Result {
    let text: String
    let status: Int32
  }
  static func read(_ operation: Operation) throws -> Result {
    let process = Process()
    let pipe = Pipe()
    let duration: Double
    switch operation {
    case .media(let name):
      guard name.utf8.count <= 32, name.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) })
      else { throw CocoaError(.validationMissingMandatoryProperty) }
      process.executableURL = URL(fileURLWithPath: "/sbin/ifconfig")
      process.arguments = [name]
      duration = 3
    case .dns(let host):
      guard NetworkTarget.validate(host) == host else {
        throw CocoaError(.validationMissingMandatoryProperty)
      }
      process.executableURL = URL(fileURLWithPath: "/usr/bin/dscacheutil")
      process.arguments = ["-q", "host", "-a", "name", host]
      duration = 8
    case .ping(let host, let count):
      guard NetworkTarget.validate(host) == host, (1...20).contains(count) else {
        throw CocoaError(.validationMissingMandatoryProperty)
      }
      process.executableURL = URL(
        fileURLWithPath: host.contains(":") ? "/sbin/ping6" : "/sbin/ping")
      process.arguments =
        host.contains(":")
        ? ["-n", "-c", String(count), "-i", "1", host]
        : ["-n", "-c", String(count), "-i", "1", "-W", "1000", host]
      duration = Double(count) + 8
    case .tcp(let host, let port):
      guard NetworkTarget.validate(host) == host, (1...65535).contains(port) else {
        throw CocoaError(.validationMissingMandatoryProperty)
      }
      process.executableURL = URL(fileURLWithPath: "/usr/bin/nc")
      process.arguments = ["-n", "-G", "3", "-w", "3", "-z", host, String(port)]
      // Numeric-only nc would fail DNS names. Resolve through nc for this explicit TCP probe.
      if !host.contains(":") && host.contains(where: { $0.isLetter }) {
        process.arguments?.removeFirst()
      }
      duration = 8
    }
    process.environment = ["LC_ALL": "C", "LANG": "C", "PATH": "/usr/bin:/bin:/usr/sbin:/sbin"]
    process.standardOutput = pipe
    process.standardError = pipe
    defer {
      if process.isRunning {
        process.terminate()
        let end = ProcessInfo.processInfo.systemUptime + 0.25
        while process.isRunning && ProcessInfo.processInfo.systemUptime < end {
          Thread.sleep(forTimeInterval: 0.01)
        }
        if process.isRunning { _ = kill(process.processIdentifier, SIGKILL) }
      }
      try? pipe.fileHandleForReading.close()
      try? pipe.fileHandleForWriting.close()
    }
    try Task.checkCancellation()
    try process.run()
    try pipe.fileHandleForWriting.close()
    let descriptor = pipe.fileHandleForReading.fileDescriptor
    let flags = fcntl(descriptor, F_GETFL)
    guard flags >= 0, fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) == 0 else {
      throw CocoaError(.fileReadUnknown)
    }
    let deadline = ProcessInfo.processInfo.systemUptime + duration
    var bytes = Data()
    var buffer = [UInt8](repeating: 0, count: 16384)
    var ended = false
    while ProcessInfo.processInfo.systemUptime < deadline {
      try Task.checkCancellation()
      let count = buffer.withUnsafeMutableBytes {
        Darwin.read(descriptor, $0.baseAddress, $0.count)
      }
      if count > 0 {
        guard bytes.count + count <= 512 * 1024 else { throw CocoaError(.fileReadTooLarge) }
        bytes.append(contentsOf: buffer.prefix(count))
      } else if count == 0 {
        ended = true
      } else if errno != EAGAIN && errno != EINTR {
        throw CocoaError(.fileReadUnknown)
      }
      if !process.isRunning && ended {
        return Result(
          text: String(decoding: bytes, as: UTF8.self), status: process.terminationStatus)
      }
      Thread.sleep(forTimeInterval: 0.02)
    }
    throw CocoaError(.fileReadUnknown)
  }
}

public enum NetworkDiagnostics {
  public static func latency(target: String, count: Int = 20) throws -> LatencyReport {
    let result = try NetworkToolsProcess.read(.ping(target, count))
    return LatencyReport.parse(result.text, target: target, exitStatus: result.status)
  }
  public static func connection(target: String, gateway: String?) throws -> [ConnectionCheck] {
    guard NetworkTarget.validate(target) == target else {
      throw CocoaError(.validationMissingMandatoryProperty)
    }
    var results: [ConnectionCheck] = []
    let operations: [(String, String, NetworkToolsProcess.Operation?)] = [
      ("Gateway ICMP", gateway ?? "Unavailable", gateway.map { .ping($0, 3) }),
      ("DNS resolution", target, NetworkTarget.isNumericIP(target) ? nil : .dns(target)),
      ("TCP connection", target + ":443", .tcp(target, 443)),
    ]
    for (label, destination, operation) in operations {
      try Task.checkCancellation()
      let start = ProcessInfo.processInfo.systemUptime
      guard let operation else {
        results.append(
          .init(
            id: label, target: destination, succeeded: nil, durationMilliseconds: 0,
            detail: label == "DNS resolution" ? "Not applicable to a numeric IP" : "Unavailable"))
        continue
      }
      do {
        let result = try NetworkToolsProcess.read(operation)
        let success =
          label == "DNS resolution"
          ? result.status == 0
            && (result.text.contains("ip_address:") || result.text.contains("ipv6_address:"))
          : result.status == 0
        results.append(
          .init(
            id: label, target: destination, succeeded: success,
            durationMilliseconds: (ProcessInfo.processInfo.systemUptime - start) * 1000,
            detail: success ? "Succeeded" : "Failed or blocked"))
      } catch is CancellationError { throw CancellationError() } catch {
        results.append(
          .init(
            id: label, target: destination, succeeded: false,
            durationMilliseconds: (ProcessInfo.processInfo.systemUptime - start) * 1000,
            detail: "Timed out or unavailable"))
      }
    }
    return results
  }
}
