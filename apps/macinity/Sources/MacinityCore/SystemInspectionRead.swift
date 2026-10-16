import Darwin
import Foundation

/// Fixed read-only OS helpers. No shell or caller-supplied executable/arguments.
public enum SystemInspectionRead: Sendable {
  case backgroundItems, networkSockets, dataVolumeInfo, dataVolumeSnapshots, systemVolumeInfo,
    systemVolumeSnapshots, apfsContainers

  public func read() throws -> Data {
    let process = Process()
    let pipe = Pipe()
    switch self {
    case .backgroundItems:
      process.executableURL = URL(fileURLWithPath: "/usr/bin/sfltool")
      process.arguments = ["dumpbtm"]
    case .networkSockets:
      process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
      process.arguments = ["-nP", "-i", "-FpcfPntT"]
    case .dataVolumeInfo:
      process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
      process.arguments = ["info", "-plist", "/System/Volumes/Data"]
    case .dataVolumeSnapshots:
      process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
      process.arguments = ["apfs", "listSnapshots", "/System/Volumes/Data", "-plist"]
    case .apfsContainers:
      process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
      process.arguments = ["apfs", "list", "-plist"]
    case .systemVolumeInfo:
      process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
      process.arguments = ["info", "-plist", "/"]
    case .systemVolumeSnapshots:
      process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
      process.arguments = ["apfs", "listSnapshots", "/", "-plist"]
    }
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    defer {
      if process.isRunning {
        process.terminate()
        // Only this owned helper is eligible for escalation; never an inspected process.
        let end = ProcessInfo.processInfo.systemUptime + 0.25
        while process.isRunning && ProcessInfo.processInfo.systemUptime < end {
          Thread.sleep(forTimeInterval: 0.01)
        }
        if process.isRunning { _ = kill(process.processIdentifier, SIGKILL) }
      }
      try? pipe.fileHandleForReading.close()
      try? pipe.fileHandleForWriting.close()
    }
    try process.run()
    try pipe.fileHandleForWriting.close()
    let descriptor = pipe.fileHandleForReading.fileDescriptor
    let flags = fcntl(descriptor, F_GETFL)
    guard flags >= 0, fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) == 0 else {
      throw CocoaError(.fileReadUnknown)
    }
    let deadline = ProcessInfo.processInfo.systemUptime + 10
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 65_536)
    while ProcessInfo.processInfo.systemUptime < deadline {
      try Task.checkCancellation()
      let count = buffer.withUnsafeMutableBytes {
        Darwin.read(descriptor, $0.baseAddress, $0.count)
      }
      if count > 0 {
        guard data.count + count <= 8_000_000 else { throw CocoaError(.fileReadTooLarge) }
        data.append(contentsOf: buffer.prefix(count))
      } else if !process.isRunning {
        guard
          process.terminationStatus == 0
            || (self == .networkSockets && process.terminationStatus == 1 && data.isEmpty)
        else { throw CocoaError(.fileReadUnknown) }
        return data
      } else if count < 0 && errno != EAGAIN && errno != EINTR {
        throw CocoaError(.fileReadUnknown)
      } else {
        Thread.sleep(forTimeInterval: 0.02)
      }
    }
    throw CocoaError(.fileReadUnknown)
  }
}
