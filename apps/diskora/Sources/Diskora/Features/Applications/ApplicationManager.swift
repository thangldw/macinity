import AppKit
import Foundation

struct InstalledApplication: Identifiable, Sendable {
  let url: URL
  let name: String
  let bundleIdentifier: String?
  let bytes: Int64
  let leftovers: [StorageEntry]
  var id: String { url.path }
  var totalBytes: Int64 { bytes + leftovers.reduce(0) { $0 + $1.bytes } }
}

struct ApplicationScanner: Sendable {
  func scan() -> [InstalledApplication] {
    let manager = FileManager()
    let home = manager.homeDirectoryForCurrentUser
    let roots = [
      URL(fileURLWithPath: "/Applications"), home.appendingPathComponent("Applications"),
    ]
    let service = CleanerService(homeURL: home)
    var apps: [InstalledApplication] = []
    for root in roots {
      guard
        let contents = try? manager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
      else { continue }
      for url in contents where url.pathExtension.lowercased() == "app" {
        if Task.isCancelled { return apps }
        let name = url.deletingPathExtension().lastPathComponent
        let bundleID = Bundle(url: url)?.bundleIdentifier
        apps.append(
          .init(
            url: url,
            name: name,
            bundleIdentifier: bundleID,
            bytes: (try? service.size(of: url)) ?? 0,
            leftovers: findLeftovers(name: name, bundleID: bundleID, home: home, service: service)
          ))
      }
    }
    return apps.sorted { $0.totalBytes > $1.totalBytes }
  }

  func uninstall(_ app: InstalledApplication, includeLeftovers: Bool) -> TrashResult {
    let manager = FileManager()
    var moved = 0
    var bytes: Int64 = 0
    var errors: [String] = []
    let targets =
      [StorageEntry(url: app.url, bytes: app.bytes, modifiedAt: nil)]
      + (includeLeftovers ? app.leftovers : [])
    for target in targets {
      do {
        try manager.trashItem(at: target.url, resultingItemURL: nil)
        moved += 1
        bytes += target.bytes
      } catch { errors.append("\(target.url.lastPathComponent): \(error.localizedDescription)") }
    }
    return TrashResult(movedCount: moved, movedBytes: bytes, errors: errors, reportURL: nil)
  }

  private func findLeftovers(name: String, bundleID: String?, home: URL, service: CleanerService)
    -> [StorageEntry]
  {
    let roots = [
      "Library/Application Support", "Library/Caches", "Library/Preferences", "Library/Logs",
      "Library/Saved Application State", "Library/Containers",
    ].map { home.appendingPathComponent($0) }
    let normalizedName = name.lowercased().replacingOccurrences(of: " ", with: "")
    guard normalizedName.count >= 4 else { return [] }
    var output: [StorageEntry] = []
    for root in roots {
      guard
        let contents = try? FileManager.default.contentsOfDirectory(
          at: root, includingPropertiesForKeys: [.contentModificationDateKey])
      else { continue }
      for url in contents {
        let candidate = url.lastPathComponent.lowercased().replacingOccurrences(of: " ", with: "")
        let bundleMatch =
          bundleID.map {
            candidate == $0.lowercased() || candidate.hasPrefix($0.lowercased() + ".")
          } ?? false
        guard bundleMatch || candidate.contains(normalizedName) else { continue }
        output.append(
          StorageEntry(url: url, bytes: (try? service.size(of: url)) ?? 0, modifiedAt: nil))
      }
    }
    return output.sorted { $0.bytes > $1.bytes }
  }
}

@MainActor
final class ApplicationViewModel: ObservableObject {
  @Published var applications: [InstalledApplication] = []
  @Published var isWorking = false
  @Published var status = "Quét ứng dụng để tìm dữ liệu còn sót"
  @Published var errorMessage: String?
  private let scanner = ApplicationScanner()
  private let history = HistoryStore()

  func scan() {
    isWorking = true
    status = "Đang phân tích ứng dụng và dữ liệu liên quan…"
    let scanner = self.scanner
    Task {
      applications = await Task.detached { scanner.scan() }.value
      isWorking = false
      status = "Tìm thấy \(applications.count) ứng dụng"
    }
  }

  func uninstall(_ app: InstalledApplication, includeLeftovers: Bool) {
    isWorking = true
    let scanner = self.scanner
    let history = self.history
    Task {
      let result = await Task.detached {
        scanner.uninstall(app, includeLeftovers: includeLeftovers)
      }.value
      history.record(
        action: "Gỡ ứng dụng: \(app.name)",
        paths: [app.url.path] + app.leftovers.map { $0.url.path }, bytes: result.movedBytes,
        recoverable: true, note: "Đã chuyển vào Trash")
      errorMessage = result.errors.isEmpty ? nil : result.errors.joined(separator: "\n")
      isWorking = false
      scan()
    }
  }

  func reveal(_ url: URL) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
}
