import Foundation

struct RuntimeVersion: Identifiable, Sendable {
  let tool: String
  let version: String
  let url: URL
  let bytes: Int64
  let referencedBy: [String]
  var id: String { url.path }
  var isReferenced: Bool { !referencedBy.isEmpty }
}

struct DeveloperRuntimeScanner: Sendable {
  func scan() -> [RuntimeVersion] {
    let manager = FileManager()
    let home = manager.homeDirectoryForCurrentUser
    let service = CleanerService(homeURL: home)
    let references = findReferences(home: home)
    var output: [RuntimeVersion] = []
    func add(tool: String, root: URL, nestedTool: Bool = false) {
      guard let first = try? manager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
      else { return }
      let versions: [(String, URL)] =
        nestedTool
        ? first.flatMap { toolDir in
          ((try? manager.contentsOfDirectory(at: toolDir, includingPropertiesForKeys: nil)) ?? [])
            .map { (toolDir.lastPathComponent + " " + $0.lastPathComponent, $0) }
        } : first.map { ($0.lastPathComponent, $0) }
      for (version, url) in versions {
        let refs = references.filter {
          $0.value.contains(version.split(separator: " ").last.map(String.init) ?? version)
        }.map(\.key)
        output.append(
          .init(
            tool: tool, version: version, url: url, bytes: (try? service.size(of: url)) ?? 0,
            referencedBy: refs))
      }
    }
    add(tool: "Node (nvm)", root: home.appendingPathComponent(".nvm/versions/node"))
    add(tool: "Python (pyenv)", root: home.appendingPathComponent(".pyenv/versions"))
    add(tool: "asdf", root: home.appendingPathComponent(".asdf/installs"), nestedTool: true)
    add(tool: "Conda", root: home.appendingPathComponent(".conda/envs"))
    return output.sorted { $0.bytes > $1.bytes }
  }

  private func findReferences(home: URL) -> [String: String] {
    let manager = FileManager()
    let names = Set([".nvmrc", ".python-version", ".tool-versions", "environment.yml"])
    let roots = ["Documents", "Developer", "Projects", "Desktop"].map {
      home.appendingPathComponent($0)
    }
    var refs: [String: String] = [:]
    for root in roots {
      guard
        let enumerator = manager.enumerator(
          at: root, includingPropertiesForKeys: [.isRegularFileKey],
          options: [.skipsPackageDescendants])
      else { continue }
      for case let url as URL in enumerator where names.contains(url.lastPathComponent) {
        if refs.count >= 200 { break }
        if let data = try? Data(contentsOf: url, options: .mappedIfSafe), data.count < 64_000,
          let text = String(data: data, encoding: .utf8)
        {
          refs[url.path] = text
        }
      }
    }
    return refs
  }
}

@MainActor
final class DeveloperRuntimeViewModel: ObservableObject {
  @Published var versions: [RuntimeVersion] = []
  @Published var isScanning = false
  @Published var status = ""
  @Published var errorMessage: String?
  private let history = HistoryStore()
  func scan() {
    isScanning = true
    status = "Đang đối chiếu file cấu hình dự án…"
    let scanner = DeveloperRuntimeScanner()
    Task {
      versions = await Task.detached { scanner.scan() }.value
      isScanning = false
      status = "Đã kiểm tra \(versions.count) phiên bản"
    }
  }

  func trash(_ runtime: RuntimeVersion) {
    guard !runtime.isReferenced else {
      errorMessage = "Phiên bản này đang được file cấu hình dự án tham chiếu."
      return
    }
    let home = FileManager.default.homeDirectoryForCurrentUser.resolvingSymlinksInPath().path + "/"
    let url = runtime.url.resolvingSymlinksInPath()
    let allowed = [
      "/.nvm/versions/node/", "/.pyenv/versions/", "/.asdf/installs/", "/.conda/envs/",
    ]
    guard url.path.hasPrefix(home), allowed.contains(where: { url.path.contains($0) }) else {
      errorMessage = "Đường dẫn runtime không an toàn."
      return
    }
    do {
      try FileManager.default.trashItem(at: url, resultingItemURL: nil)
      history.record(
        action: "Gỡ runtime \(runtime.tool) \(runtime.version)", paths: [url.path],
        bytes: runtime.bytes, recoverable: true,
        note: "Không tìm thấy file cấu hình dự án tham chiếu; đã chuyển vào Trash")
      status = "Đã chuyển \(runtime.version) vào Trash"
      scan()
    } catch { errorMessage = error.localizedDescription }
  }
}
