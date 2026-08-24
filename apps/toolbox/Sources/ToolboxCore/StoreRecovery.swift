import Foundation

struct StoreEnvelope<Value: Codable>: Codable {
  let schemaVersion: Int
  var values: [Value]
}

public enum PersistentStoreError: Error, Equatable, Sendable {
  case corruptStore(originalPath: String, quarantinedPath: String, reason: String)
  case unsupportedSchema(path: String, found: Int, supported: Int)
}

public enum StoreRecovery {
  public static func quarantine(_ fileURL: URL) throws -> URL {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd'T'HHmmssSSS'Z'"

    let extensionSuffix = fileURL.pathExtension.isEmpty ? "" : ".\(fileURL.pathExtension)"
    let stem = fileURL.deletingPathExtension().lastPathComponent
    let quarantineName =
      "\(stem).corrupt-\(formatter.string(from: Date()))-\(UUID().uuidString)\(extensionSuffix)"
    let destination = fileURL.deletingLastPathComponent().appendingPathComponent(quarantineName)
    try FileManager.default.moveItem(at: fileURL, to: destination)
    return destination
  }

  static func load<Value: Codable>(
    _ type: Value.Type, from fileURL: URL, schemaVersion: Int
  ) throws -> [Value] {
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }

    let data = try Data(contentsOf: fileURL)
    let envelope: StoreEnvelope<Value>
    do {
      envelope = try JSONDecoder().decode(StoreEnvelope<Value>.self, from: data)
    } catch {
      let quarantined = try quarantine(fileURL)
      throw PersistentStoreError.corruptStore(
        originalPath: fileURL.path, quarantinedPath: quarantined.path,
        reason: error.localizedDescription)
    }

    guard envelope.schemaVersion == schemaVersion else {
      throw PersistentStoreError.unsupportedSchema(
        path: fileURL.path, found: envelope.schemaVersion, supported: schemaVersion)
    }
    return envelope.values
  }

  static func save<Value: Codable>(
    _ values: [Value], to fileURL: URL, schemaVersion: Int
  ) throws {
    try FileManager.default.createDirectory(
      at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(StoreEnvelope(schemaVersion: schemaVersion, values: values))
    try data.write(to: fileURL, options: .atomic)
  }
}
