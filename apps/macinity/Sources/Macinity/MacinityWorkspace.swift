import AppKit
import MacinityCore
import MacinityMonitoring
import SwiftUI

struct MacinityPageHeader: View {
  let title: String
  var subtitle: String? = nil
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.system(size: 36, weight: .bold)).foregroundStyle(MacinityTheme.ink)
        .fixedSize(horizontal: false, vertical: true)
      if let subtitle {
        Text(subtitle).font(.callout).foregroundStyle(MacinityTheme.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct MacinitySamplingStatus: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject var model: MonitoringViewModel
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: model.samplingMode == .paused ? "pause.circle" : "waveform.path.ecg")
        .foregroundStyle(model.samplingMode == .paused ? Color.secondary : MacinityTheme.accent)
      Text(L10n.text(model.samplingMode == .paused ? "Sampling paused" : "Live monitoring"))
      if let snapshot = model.snapshot {
        Text(snapshot.time.wall, style: .time).monospacedDigit()
      }
      Spacer(minLength: 0)
      Text(L10n.text("Read-only")).font(.caption)
    }.font(.callout).foregroundStyle(MacinityTheme.secondary)
      .environment(
        \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
  }
}

struct MacinityProcessIcon: View {
  let process: ProcessSample
  var size: CGFloat = 36
  private var icon: NSImage? {
    guard let identity = process.identity,
      let app = NSRunningApplication(processIdentifier: identity.pid),
      let launch = app.launchDate, abs(launch.timeIntervalSince(identity.startDate)) < 1
    else { return nil }
    return app.icon
  }
  var body: some View {
    Group {
      if let icon {
        Image(nsImage: icon).resizable().scaledToFit()
      } else {
        Image(systemName: "app").resizable().scaledToFit().foregroundStyle(MacinityTheme.secondary)
          .padding(5)
      }
    }.frame(width: size, height: size).accessibilityHidden(true)
  }
}
