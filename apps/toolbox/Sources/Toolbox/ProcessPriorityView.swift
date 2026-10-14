import SwiftUI
import ToolboxCore
import ToolboxMonitoring

struct ProcessPriorityView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  let identity: ProcessIdentity
  let name: String
  @State private var confirming = false
  @State private var working = false
  @State private var result: String?
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(L10n.text("CPU scheduling")).font(.headline)
      Text(
        L10n.text(
          "Lower priority raises nice to at least 10 for this same-user process. It is not a CPU percentage cap. Raising priority back may require privileges; relaunch the app to reset. Child processes are not individually controlled."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
      Button(L10n.text("Lower process priority…")) { confirming = true }.disabled(working)
      if let result { Text(L10n.text(result)).font(.caption) }
    }
    .alert(L10n.text("Lower process priority?"), isPresented: $confirming) {
      Button(L10n.text("Cancel"), role: .cancel) {}
      Button(L10n.text("Lower priority")) {
        working = true
        Task {
          defer { working = false }
          let worker = Task.detached { try ProcessPriority.lower(identity) }
          do {
            _ = try await worker.value
            result =
              "Process priority lowered and rechecked. This does not guarantee lower CPU usage."
          } catch {
            result =
              "Priority change could not be verified. The process may have exited, changed identity or denied access. No retry is automatic."
          }
        }
      }
    } message: {
      Text(
        name + " · PID \(identity.pid)\n"
          + L10n.text(
            "This changes scheduling for the selected process. Restoring the previous priority is not guaranteed without relaunching it."
          ))
    }
    .id(identity)
  }
}
