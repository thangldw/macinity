import AppKit
import MacinityCore
import SwiftUI

/// A bounded presence check, not a package database or a shell environment resolver.
struct DeveloperToolInventory: Sendable {
  struct Entry: Identifiable, Sendable, Equatable {
    let name: String
    let path: String
    var id: String { path }
  }

  static let names = [
    "brew", "mise", "nix", "python3", "node", "npm", "go", "rustc", "cargo", "java",
    "git", "docker", "podman", "orb", "duckdb", "uv", "bun", "deno", "terraform", "kubectl",
  ]

  static func scan(
    home: String = FileManager.default.homeDirectoryForCurrentUser.path,
    executable: (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) },
    directory: (String) -> Bool = { path in
      var isDirectory: ObjCBool = false
      return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        && isDirectory.boolValue
    }
  ) -> [Entry] {
    let roots = [
      "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/nix/var/nix/profiles/default/bin",
      home + "/.local/bin", home + "/.cargo/bin", home + "/.bun/bin",
      home + "/.deno/bin", home + "/.nix-profile/bin", home + "/.local/share/mise/shims",
    ]
    return names.flatMap { name in
      roots.compactMap { root -> Entry? in
        let path = root + "/" + name
        guard executable(path), !directory(path) else { return nil }
        return Entry(name: name, path: path)
      }
    }
  }
}

struct DeveloperToolsView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @State private var selected: DeveloperToolInventory.Entry?
  @State private var entries: [DeveloperToolInventory.Entry] = []
  @State private var scannedAt: Date?
  @State private var scanning = false
  @State private var scanGeneration = 0
  @State private var query = ""

  private var filtered: [DeveloperToolInventory.Entry] {
    entries.filter { query.isEmpty || ($0.name + " " + $0.path).localizedStandardContains(query) }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(L10n.text("Developer Tools")).font(.largeTitle.bold())
        Spacer()
        Button(L10n.text("Choose Python environment")) {
          let panel = NSOpenPanel()
          panel.canChooseDirectories = false
          panel.canChooseFiles = true
          if panel.runModal() == .OK, let url = panel.url, url.lastPathComponent == "python3" {
            selected = .init(name: "python3", path: url.path)
          }
        }
        Button(L10n.text("Refresh")) { scanGeneration += 1 }.disabled(scanning)
      }
      Text(L10n.text("Discover runtimes and command-line tools in common installation folders."))
        .foregroundStyle(MacinityTheme.secondary)
      Text(
        L10n.text(
          "Discovery checks paths only. Select a tool to explicitly read its version or packages. Multiple installations are kept separate; the active shell environment is not inferred."
        )
      )
      .font(.callout).foregroundStyle(MacinityTheme.secondary)
      .fixedSize(horizontal: false, vertical: true)
      TextField(L10n.text("Filter by name or path"), text: $query).textFieldStyle(.roundedBorder)
      if scanning {
        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if filtered.isEmpty {
        Text(L10n.text("No tools found in this view. Custom installation folders are not scanned."))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(filtered) { entry in
          HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
              Text(entry.name).font(.headline)
              Text(entry.path).font(.system(.callout, design: .monospaced))
                .foregroundStyle(MacinityTheme.secondary).textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(L10n.text("Inspect tool")) { selected = entry }
            Button(L10n.text("Show in Finder")) {
              NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: entry.path)])
            }.accessibilityLabel(L10n.text("Show in Finder") + ": " + entry.path)
          }.padding(.vertical, 6)
        }.scrollContentBackground(.hidden)
      }
      if let scannedAt {
        HStack {
          Text(L10n.text("Last checked"))
          Text(scannedAt, style: .time)
          Spacer()
          Text("\(entries.count)")
        }.font(.caption).foregroundStyle(MacinityTheme.secondary)
      }
    }
    .padding(28).foregroundStyle(MacinityTheme.ink).background(MacinityTheme.canvas)
    .sheet(item: $selected) { entry in
      PackageManagerView(executable: entry.path, tool: entry.name).padding(24).frame(
        width: 580, height: 600)
    }
    .task(id: scanGeneration) {
      scanning = true
      let worker = Task.detached(priority: .utility) { DeveloperToolInventory.scan() }
      let result = await worker.value
      guard !Task.isCancelled else { return }
      entries = result
      scannedAt = Date()
      scanning = false
    }
  }
}
