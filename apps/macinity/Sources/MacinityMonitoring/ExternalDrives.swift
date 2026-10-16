import Foundation

public struct ExternalDrive: Sendable, Identifiable {
  public let id: String
  public let name: String
  public let format: String
  public let mount: String?
  public let capacity: Int64?
  public let free: Int64?
  public let uuid: String?
  public let internalDisk: Bool?
  public let protocolName: String
  public var canEject: Bool {
    internalDisk == false && uuid != nil && mount?.hasPrefix("/Volumes/") == true
  }
}
public enum ExternalDriveInspection {
  public static func info(_ id: String) throws -> ExternalDrive {
    let result = try UtilityCommand.diskInfo(id).read()
    guard result.status == 0,
      let object = try PropertyListSerialization.propertyList(
        from: Data(result.text.utf8), format: nil) as? [String: Any],
      object["DeviceIdentifier"] as? String == id
    else { throw CocoaError(.fileReadCorruptFile) }
    return parse(object, id: id)
  }
  static func parse(_ object: [String: Any], id: String) -> ExternalDrive {
    func text(_ key: String) -> String? {
      (object[key] as? String).flatMap { $0.isEmpty ? nil : $0 }
    }
    let mount = text("MountPoint")
    return .init(
      id: id, name: text("VolumeName") ?? text("MediaName") ?? id,
      format: object["FilesystemName"] as? String ?? object["Content"] as? String ?? "Unknown",
      mount: mount,
      capacity: (object["TotalSize"] as? NSNumber)?.int64Value,
      free: mount == nil ? nil : (object["FreeSpace"] as? NSNumber)?.int64Value,
      uuid: text("VolumeUUID"), internalDisk: object["Internal"] as? Bool,
      protocolName: object["BusProtocol"] as? String ?? "Unknown")
  }
  public static func read() throws -> [ExternalDrive] {
    let result = try UtilityCommand.externalDisks.read()
    guard result.status == 0,
      let object = try PropertyListSerialization.propertyList(
        from: Data(result.text.utf8), format: nil) as? [String: Any],
      let ids = object["AllDisks"] as? [String]
    else { throw CocoaError(.fileReadCorruptFile) }
    // A bound is an explicit error, never an apparently complete inventory.
    guard ids.count <= 64 else { throw CocoaError(.fileReadTooLarge) }
    var drives: [ExternalDrive] = []
    for id in ids {
      try Task.checkCancellation()
      let drive = try info(id)
      if drive.protocolName != "Disk Image" { drives.append(drive) }
    }
    return drives
  }
}
