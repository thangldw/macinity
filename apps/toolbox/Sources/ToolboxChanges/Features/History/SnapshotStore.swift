import Foundation
import ToolboxCore

struct SnapshotStore: Sendable {
  private let directory: URL
  private let sessionsURL: URL
  private let activeURL: URL
  private let activeTraceMetadataURL: URL
  private let baselineURL: URL
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init(directory: URL = AppMetadata.applicationSupportDirectory()) {
    self.directory = directory
    sessionsURL = directory.appendingPathComponent("sessions.json")
    activeURL = directory.appendingPathComponent("active-snapshot.json")
    activeTraceMetadataURL = directory.appendingPathComponent("active-trace-metadata.json")
    baselineURL = directory.appendingPathComponent("trusted-baseline.json")
    encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    decoder = JSONDecoder()
  }

  var directoryURL: URL { directory }

  func loadSessions() -> [WatchSession] {
    guard let data = try? Data(contentsOf: sessionsURL) else { return [] }
    return (try? decoder.decode([WatchSession].self, from: data)) ?? []
  }

  func saveSessions(_ sessions: [WatchSession]) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try encoder.encode(sessions).write(to: sessionsURL, options: .atomic)
  }

  func loadActiveSnapshot() -> SystemSnapshot? {
    guard let data = try? Data(contentsOf: activeURL) else { return nil }
    return try? decoder.decode(SystemSnapshot.self, from: data)
  }

  func saveActiveSnapshot(_ snapshot: SystemSnapshot) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try encoder.encode(snapshot).write(to: activeURL, options: .atomic)
  }

  func clearActiveSnapshot() throws {
    guard FileManager.default.fileExists(atPath: activeURL.path) else { return }
    try FileManager.default.removeItem(at: activeURL)
  }

  func loadActiveTraceMetadata() -> InstallerMetadata? {
    guard let data = try? Data(contentsOf: activeTraceMetadataURL) else { return nil }
    return try? decoder.decode(InstallerMetadata.self, from: data)
  }

  func saveActiveTraceMetadata(_ metadata: InstallerMetadata) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try encoder.encode(metadata).write(to: activeTraceMetadataURL, options: .atomic)
  }

  func clearActiveTraceMetadata() throws {
    guard FileManager.default.fileExists(atPath: activeTraceMetadataURL.path) else { return }
    try FileManager.default.removeItem(at: activeTraceMetadataURL)
  }

  func loadBaseline() -> SystemSnapshot? {
    guard let data = try? Data(contentsOf: baselineURL) else { return nil }
    return try? decoder.decode(SystemSnapshot.self, from: data)
  }

  func saveBaseline(_ snapshot: SystemSnapshot) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try encoder.encode(snapshot).write(to: baselineURL, options: .atomic)
  }

  func clearBaseline() throws {
    guard FileManager.default.fileExists(atPath: baselineURL.path) else { return }
    try FileManager.default.removeItem(at: baselineURL)
  }
}
