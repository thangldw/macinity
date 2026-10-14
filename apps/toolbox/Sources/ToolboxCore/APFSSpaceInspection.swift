import CoreFoundation
import Foundation

public enum APFSStartupVolume: String, CaseIterable, Identifiable, Sendable {
  case data, system
  public var id: String { rawValue }
}

public struct APFSSnapshotEntry: Identifiable, Sendable {
  public let id: String
  public let name: String
  public let purgeable: Bool?
}

public struct APFSVolumeUsage: Identifiable, Sendable {
  public let id: String
  public let name: String
  public let roles: [String]
  public let bytes: Int64?
}

public struct APFSSpaceInspection: Sendable {
  public let observedAt: Date
  public let containerTotal: Int64?
  public let containerFree: Int64?
  public let volumeUsed: Int64?
  public let snapshots: [APFSSnapshotEntry]
  public let omitted: Int
  public let volumes: [APFSVolumeUsage]
  public let containerRemainder: Int64?
  public let omittedVolumes: Int

  public static func read(volume: APFSStartupVolume = .data) throws -> APFSSpaceInspection {
    let info = try (volume == .data ? SystemInspectionRead.dataVolumeInfo : .systemVolumeInfo)
      .read()
    let snapshots = try
      (volume == .data ? SystemInspectionRead.dataVolumeSnapshots : .systemVolumeSnapshots).read()
    let containers = try SystemInspectionRead.apfsContainers.read()
    return try parse(info: info, snapshots: snapshots, containers: containers)
  }

  public static func parse(info: Data, snapshots: Data, containers: Data? = nil) throws
    -> APFSSpaceInspection
  {
    guard
      let volume = try PropertyListSerialization.propertyList(from: info, format: nil)
        as? [String: Any],
      let snapshotData = try PropertyListSerialization.propertyList(from: snapshots, format: nil)
        as? [String: Any], let entries = snapshotData["Snapshots"] as? [[String: Any]]
    else { throw CocoaError(.propertyListReadCorrupt) }
    func numberBytes(_ value: Any?) -> Int64? {
      guard let number = value as? NSNumber,
        CFGetTypeID(number) != CFBooleanGetTypeID(),
        let value = Int64(number.stringValue), value >= 0
      else { return nil }
      return value
    }
    var container: [String: Any]?
    if let containers {
      guard
        let document = try PropertyListSerialization.propertyList(from: containers, format: nil)
          as? [String: Any], let rows = document["Containers"] as? [[String: Any]]
      else {
        throw CocoaError(.propertyListReadCorrupt)
      }
      if let reference = volume["APFSContainerReference"] as? String {
        container = rows.first { $0["ContainerReference"] as? String == reference }
      }
    }
    let total =
      numberBytes(container?["CapacityCeiling"]) ?? numberBytes(volume["APFSContainerSize"])
    let free = numberBytes(container?["CapacityFree"]) ?? numberBytes(volume["APFSContainerFree"])
    let allVolumes = container?["Volumes"] as? [[String: Any]]
    var omittedVolumes = max((allVolumes?.count ?? 0) - 64, 0)
    let volumes = (allVolumes ?? []).prefix(64).enumerated().compactMap {
      index, item -> APFSVolumeUsage? in
      guard let name = item["Name"] as? String, name.count <= 256 else {
        omittedVolumes += 1
        return nil
      }
      let id = item["DeviceIdentifier"] as? String ?? String(index)
      return APFSVolumeUsage(
        id: id + ":" + String(index), name: name,
        roles: Array((item["Roles"] as? [String] ?? []).prefix(8)),
        bytes: numberBytes(item["CapacityInUse"]))
    }
    var remainder: Int64?
    if allVolumes != nil, !volumes.isEmpty, omittedVolumes == 0,
      volumes.allSatisfy({ $0.bytes != nil }), let total, let free, free <= total
    {
      var used: Int64 = 0
      var overflow = false
      for item in volumes {
        let sum = used.addingReportingOverflow(item.bytes ?? 0)
        used = sum.partialValue
        overflow = overflow || sum.overflow
      }
      if !overflow, used <= total - free { remainder = total - free - used }
    }
    let validFree = total.flatMap { total in free.flatMap { $0 <= total ? $0 : nil } }
    var omitted = max(entries.count - 256, 0)
    let rows = entries.prefix(256).enumerated().compactMap { index, item -> APFSSnapshotEntry? in
      guard let name = (item["SnapshotName"] ?? item["Name"]) as? String, !name.isEmpty,
        name.count <= 2048
      else {
        omitted += 1
        return nil
      }
      let uuid = item["SnapshotUUID"] as? String ?? item["UUID"] as? String
      let purgeable: Bool?
      if let number = item["Purgeable"] as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() {
        purgeable = number.boolValue
      } else {
        purgeable = nil
      }
      return APFSSnapshotEntry(id: "\(uuid ?? name):\(index)", name: name, purgeable: purgeable)
    }
    return APFSSpaceInspection(
      observedAt: Date(), containerTotal: total,
      containerFree: validFree, volumeUsed: numberBytes(volume["CapacityInUse"]), snapshots: rows,
      omitted: omitted, volumes: volumes, containerRemainder: remainder,
      omittedVolumes: omittedVolumes)
  }
}
