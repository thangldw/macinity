import AppKit
import MacinityCore
import SwiftUI

struct DeveloperWorkspaceView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  let report: ProjectScanReport
  @State private var expanded = false
  @StateObject private var analyzer = AnalyzerViewModel()
  var body: some View {
    DisclosureGroup(L10n.text("Developer Workspace"), isExpanded: $expanded) {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          Text(
            L10n.text(
              "Recognized projects within selected roots. Manifest names are evidence of an ecosystem, not proof that its runtime is installed. Source size and runtime versions are not measured."
            )
          )
          .font(.caption).foregroundStyle(.secondary)
          Text(
            String(
              format: L10n.text("%d scan issues; results may be partial."), report.issues.count)
          )
          .font(.caption)
          ForEach(Array((report.inventory ?? []).prefix(100))) { project in
            let artifacts = report.artifacts.filter { $0.projectRoot == project.root }
            VStack(alignment: .leading, spacing: 5) {
              HStack {
                Text(project.root.lastPathComponent).font(.headline)
                Spacer()
                Text(ByteCount.string(artifacts.reduce(0) { $0 + $1.bytes })).monospacedDigit()
                Button(L10n.text("Measure workspace")) {
                  analyzer.rootURL = project.root
                  analyzer.snapshot = nil
                  analyzer.comparison = nil
                  analyzer.scan()
                }.disabled(analyzer.isScanning)
                Button(L10n.text("Show in Finder")) {
                  NSWorkspace.shared.activateFileViewerSelecting([project.root])
                }
              }
              Text(project.root.path).font(.caption).textSelection(.enabled)
              Text(project.ecosystems.map(\.rawValue).joined(separator: " · "))
              Text(project.markers.joined(separator: " · ")).font(.caption.monospaced())
              Text(
                String(
                  format: L10n.text(
                    "%d recognized artifacts; size is observed artifact data only."),
                  artifacts.count)
              )
              .font(.caption).foregroundStyle(.secondary)
            }
            if analyzer.rootURL == project.root {
              if analyzer.isScanning {
                HStack {
                  ProgressView().controlSize(.small)
                  Button(L10n.text("Stop")) { analyzer.cancel() }
                }
              }
              if let snapshot = analyzer.snapshot {
                let usage = WorkspaceUsage(snapshot: snapshot, artifacts: artifacts)
                Text(
                  L10n.text("Observed workspace size") + ": "
                    + ByteCount.string(snapshot.scannedBytes))
                Text(
                  L10n.text("Other observed project data") + ": "
                    + (usage.otherBytes.map(ByteCount.string) ?? L10n.text("Unavailable"))
                )
                .font(.caption)
                Text(snapshot.completedAt, style: .time).font(.caption)
                Text(
                  String(
                    format: L10n.text("%d scan issues; results may be partial."),
                    snapshot.inaccessibleCount)
                )
                .font(.caption)
                if let comparison = analyzer.comparison {
                  Text(L10n.text(comparison.status)).font(.caption)
                  ForEach(comparison.deltas.prefix(5)) { delta in
                    Text(
                      URL(fileURLWithPath: delta.path).lastPathComponent + " · "
                        + (delta.bytes > 0 ? "+" : "−") + ByteCount.string(abs(delta.bytes))
                    )
                    .font(.caption.monospaced())
                  }
                }
              }
              if let error = analyzer.errorMessage { Text(L10n.text(error)).font(.caption) }
            }
            Divider()
          }
          if (report.inventory ?? []).isEmpty {
            Text(L10n.text("No recognized project manifests within scan coverage."))
          }
          if (report.inventory?.count ?? 0) > 100 {
            Text(
              L10n.text(
                "Only the first 100 projects are displayed. Artifact filters remain available below."
              ))
          }
        }.frame(maxWidth: .infinity, alignment: .leading)
      }.frame(maxHeight: 220)
    }.padding(.horizontal, 18).padding(.vertical, 10)
  }
}
