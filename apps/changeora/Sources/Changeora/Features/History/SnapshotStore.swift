import Foundation

struct SnapshotStore: Sendable {
  private let directory: URL
  private let sessionsURL: URL
  private let activeURL: URL
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init(directory: URL = AppMetadata.applicationSupportDirectory()) {
    self.directory = directory
    sessionsURL = directory.appendingPathComponent("sessions.json")
    activeURL = directory.appendingPathComponent("active-snapshot.json")
    encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    decoder = JSONDecoder()
  }

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
}
