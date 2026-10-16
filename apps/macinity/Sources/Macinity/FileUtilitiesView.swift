import AppKit
import MacinityCore
import MacinityStorage
import SwiftUI

struct FileUtilitiesView: View {
  @State private var tab = "SHA-256"
  @State private var files: [URL] = []
  @State private var first: URL?
  @State private var second: URL?
  @State private var expected = ""
  @State private var find = ""
  @State private var replacement = ""
  @State private var prefix = ""
  @State private var plan: [RenameItem] = []
  @State private var recovery: [RenameItem] = []
  @State private var confirmsRename = false
  @State private var confirmsUndo = false
  @State private var output = ""
  @State private var busy = false
  @State private var work: Task<Void, Never>?
  private var journalRoot: URL {
    AppMetadata.applicationSupportDirectory().appendingPathComponent("rename-journals")
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      MacinityPageHeader(title: L10n.text("File Utilities"))
      MacinityChoicePicker(
        L10n.text("File utility"), selection: $tab,
        options: ["SHA-256", "Batch Rename", "Compare Folders", "Duplicate Files"].map {
          ($0, L10n.text($0))
        }, minimumWidth: 140)
      if tab == "Duplicate Files" {
        DuplicateUtilityView()
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 14) {
            Text(
              L10n.text(
                "Selected files only. Symlinks are excluded. Hashing is bounded to 16 GiB per file and two minutes per operation. Folder comparison excludes package contents and stops rather than claiming completeness when limits or read errors occur."
              )
            )
            .font(.caption).foregroundStyle(.secondary)
            if tab == "Compare Folders" {
              HStack {
                Button(L10n.text("Choose first folder")) { first = choose(directory: true).first }
                Button(L10n.text("Choose second folder")) { second = choose(directory: true).first }
              }.disabled(busy)
              Text(first?.path ?? "—").font(.caption)
              Text(second?.path ?? "—").font(.caption)
              Button(L10n.text("Compare contents")) { compare() }.disabled(
                first == nil || second == nil || busy)
            } else {
              Button(L10n.text("Choose files")) {
                files = choose(directory: false)
                plan = []
                output = ""
              }.disabled(busy)
              Text("\(files.count) " + L10n.text("selected files")).font(.caption)
              if tab == "SHA-256" {
                TextField(L10n.text("Expected SHA-256 (optional, one file)"), text: $expected)
                  .textFieldStyle(.roundedBorder)
                Button(L10n.text("Calculate checksum")) { checksum() }.disabled(
                  files.isEmpty || busy)
              } else {
                TextField(L10n.text("Find in filename"), text: $find).textFieldStyle(.roundedBorder)
                TextField(L10n.text("Replace with"), text: $replacement).textFieldStyle(
                  .roundedBorder)
                TextField(L10n.text("Add prefix"), text: $prefix).textFieldStyle(.roundedBorder)
                Button(L10n.text("Preview rename")) {
                  do {
                    plan = try FileUtilityOperations.renamePlan(
                      files, find: find, replace: replacement, prefix: prefix)
                    output = ""
                  } catch {
                    plan = []
                    output = L10n.text("Invalid names, changed files or destination conflicts")
                  }
                }.disabled(files.isEmpty || busy)
                ForEach(plan) { item in
                  Text(
                    URL(fileURLWithPath: item.source).lastPathComponent + " → "
                      + URL(fileURLWithPath: item.destination).lastPathComponent
                  ).font(.caption)
                }
                if !plan.isEmpty {
                  Button(L10n.text("Apply reviewed rename")) { confirmsRename = true }.disabled(
                    busy)
                }
                if !recovery.isEmpty {
                  Text(L10n.text("Last rename recovery preview")).font(.headline)
                  ForEach(recovery) { item in
                    Text(item.destination + " → " + item.source).font(.caption).textSelection(
                      .enabled)
                  }
                  Button(L10n.text("Review undo last rename")) { confirmsUndo = true }.disabled(
                    busy)
                }
                Button(L10n.text("Show recovery journals")) {
                  NSWorkspace.shared.activateFileViewerSelecting([journalRoot])
                }
              }
            }
            if busy {
              HStack {
                ProgressView()
                Button(L10n.text("Cancel")) { work?.cancel() }
              }
            }
            if !output.isEmpty {
              Text(output).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
        }
      }
    }.padding(28)
      .onChange(of: find) { _ in plan = [] }.onChange(of: replacement) { _ in plan = [] }.onChange(
        of: prefix
      ) { _ in plan = [] }
      .onChange(of: tab) { _ in
        work?.cancel()
        output = ""
      }
      .onDisappear { work?.cancel() }
      .onAppear { loadRecovery() }
      .confirmationDialog(
        L10n.text("Apply the displayed rename plan? Existing files will never be overwritten."),
        isPresented: $confirmsRename
      ) {
        Button(L10n.text("Apply")) { rename() }
      }
      .confirmationDialog(
        L10n.text(
          "Restore original names from the latest journal? Changed files and conflicts will be left untouched."
        ), isPresented: $confirmsUndo
      ) {
        Button(L10n.text("Undo rename")) { undo() }
      }
  }
  private func choose(directory: Bool) -> [URL] {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = directory
    panel.canChooseFiles = !directory
    panel.allowsMultipleSelection = !directory
    return panel.runModal() == .OK ? panel.urls : []
  }
  private func run(_ operation: @escaping @Sendable () throws -> String) {
    guard !busy else { return }
    busy = true
    output = ""
    let worker = Task.detached(priority: .utility) { try operation() }
    work = Task {
      do {
        let value = try await withTaskCancellationHandler(
          operation: { try await worker.value }, onCancel: { worker.cancel() })
        if !Task.isCancelled { output = value }
      } catch {
        output =
          L10n.text("Operation stopped or failed; no complete result is available") + "\n"
          + error.localizedDescription
      }
      busy = false
      loadRecovery()
    }
  }
  private func checksum() {
    let files = files
    let expected = expected.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let match = L10n.text("Checksum matches")
    let mismatch = L10n.text("Checksum differs")
    run {
      guard files.count <= 2000,
        expected.isEmpty
          || (files.count == 1 && expected.count == 64 && expected.allSatisfy(\.isHexDigit))
      else { throw CocoaError(.validationMissingMandatoryProperty) }
      let end = Date().addingTimeInterval(120)
      return try files.map { url in
        let hash = try FileChecksum.sha256(url, deadline: end)
        return url.path + "\n" + hash
          + (expected.isEmpty ? "" : "\n" + (hash == expected ? match : mismatch))
      }.joined(separator: "\n\n")
    }
  }
  private func compare() {
    guard let first, let second else { return }
    let onlyA = L10n.text("Only in first")
    let onlyB = L10n.text("Only in second")
    let changed = L10n.text("Different content")
    let same = L10n.text("Same content")
    run {
      let end = Date().addingTimeInterval(120)
      let a = try FileUtilityOperations.tree(first, deadline: end)
      let b = try FileUtilityOperations.tree(second, deadline: end)
      return Set(a.keys).union(b.keys).sorted().map { key in
        let state =
          a[key] == nil ? onlyB : b[key] == nil ? onlyA : a[key] == b[key] ? same : changed
        return state + " · " + key
      }.joined(separator: "\n")
    }
  }
  private func rename() {
    let items = plan
    let journal = journalRoot.appendingPathComponent(UUID().uuidString + ".json")
    let done = L10n.text("Rename completed. Recovery journal retained.")
    plan = []
    run {
      try FileUtilityOperations.applyRename(items, journal: journal)
      return done
    }
  }
  private func undo() {
    let items = recovery
    let done = L10n.text("Original names restored")
    run {
      try FileUtilityOperations.undoRename(items)
      return done
    }
  }
  private func loadRecovery() {
    let urls =
      (try? FileManager.default.contentsOfDirectory(
        at: journalRoot, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
    let latest = urls.filter { $0.pathExtension == "json" }.sorted {
      ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
        ?? .distantPast)
        > ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
          ?? .distantPast)
    }.first
    if let latest, let data = try? Data(contentsOf: latest), data.count < 2_000_000 {
      recovery = (try? JSONDecoder().decode([RenameItem].self, from: data)) ?? []
    }
  }
}
