import AppKit
import Foundation
import SwiftUI
import XCTest

@testable import Macinity

final class ActionWorkflowTests: XCTestCase {
  @MainActor
  func testPopulatedActionSummaryFitsNarrowContent() {
    let view = NSHostingView(
      rootView: ActionSummaryButton(
        title: String(repeating: "Long profile name · ", count: 12),
        detail: "September 17, 2026 at 10:38 PM · "
          + String(repeating: "completed step ", count: 20),
        action: {}
      ).frame(width: 600, alignment: .leading))
    view.frame = NSRect(x: 0, y: 0, width: 600, height: 300)
    view.layoutSubtreeIfNeeded()
    XCTAssertLessThanOrEqual(view.fittingSize.width, 600)
    XCTAssertGreaterThan(view.fittingSize.height, 40)
  }
  private func metric(
    _ id: String = "cpu", _ value: Double? = 85, time: Double = 100, available: Bool = true
  ) -> DiagnosticMetric {
    .init(
      id: id, value: value, observedAt: Date(timeIntervalSince1970: time), monotonic: time,
      source: "fixture", available: available)
  }
  func testUnavailableStaleFutureAndNonfiniteEvidenceNeverPasses() {
    for metric in [
      metric(available: false), metric(time: 80), metric(time: 101), metric("cpu", .nan),
      metric("cpu", nil),
    ] {
      let report = SmartDiagnostics.report(topic: .slow, metrics: [metric], now: 100)
      XCTAssertTrue(report.findings.allSatisfy { $0.level == .unknown })
      XCTAssertEqual(report.attentionCount, 0)
    }
    XCTAssertNil(metric().freshValue(at: .nan))
    XCTAssertEqual(metric(time: 85).freshValue(at: 100), 85)
  }
  func testTriageThresholdsAndMissingMetricsRemainDistinct() {
    for (topic, id, value) in [
      (DiagnosticTopic.slow, "cpu", 80.0), (.hot, "thermal", 2), (.battery, "battery", 20),
      (.storage, "free", 10), (.network, "rssi", -75), (.network, "gateway", 0),
    ] {
      let report = SmartDiagnostics.report(topic: topic, metrics: [metric(id, value)], now: 100)
      XCTAssertEqual(report.attentionCount, 1, id)
      XCTAssertEqual(report.findings.filter { $0.level == .unknown }.count, topic.keys.count - 1)
    }
    let report = SmartDiagnostics.report(
      topic: .slow, metrics: [metric("cpu", 79.9), metric("pressure", 0)], now: 100)
    XCTAssertTrue(report.findings.allSatisfy { $0.level == .observation })
  }
  func testComparisonRequiresSameTopicAndNewFreshObservations() {
    let before = SmartDiagnostics.report(topic: .slow, metrics: [metric()], now: 100)
    let unchanged = SmartDiagnostics.report(topic: .slow, metrics: [metric()], now: 101)
    XCTAssertTrue(SmartDiagnostics.comparison(unchanged, before).isEmpty)
    let after = SmartDiagnostics.report(
      topic: .slow, metrics: [metric("cpu", 40, time: 101)], now: 101)
    XCTAssertEqual(SmartDiagnostics.comparison(after, before).first?.1, -45)
    let stale = SmartDiagnostics.report(
      topic: .slow, metrics: [metric("cpu", 40, time: 101)], now: 120)
    XCTAssertTrue(SmartDiagnostics.comparison(stale, before).isEmpty)
    let other = SmartDiagnostics.report(
      topic: .hot, metrics: [metric("cpu", 40, time: 101)], now: 101)
    XCTAssertTrue(SmartDiagnostics.comparison(other, before).isEmpty)
  }
  @MainActor
  func testFavoritesPersistNormalizeAndBoundCatalog() {
    let suite = "MacinityActionTests." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(
      ["home", "unknown", "diagnostics", "diagnostics", "workspaces"],
      forKey: "orven.actionFavorites")
    let model = ActionFavorites(defaults: defaults)
    XCTAssertEqual(model.sections, [.diagnostics, .workspaces])
    model.toggle(.diagnostics)
    XCTAssertEqual(ActionFavorites(defaults: defaults).sections, [.workspaces])
    for section in MacinitySection.allCases where !model.sections.contains(section) {
      model.toggle(section)
    }
    XCTAssertEqual(model.sections.count, 8)
    XCTAssertFalse(model.sections.contains(.home))
  }
  func testLegacyPresetDecodesWithoutOptionsAndRoundTripsNewOptions() throws {
    let original = WorkspacePreset(
      id: UUID(), name: "Legacy", applications: [], folders: [], windows: [], capturedAt: Date())
    let legacyData = try JSONEncoder().encode(original)
    XCTAssertNil(try JSONDecoder().decode(WorkspacePreset.self, from: legacyData).options)
    var updated = original
    updated.options = .init(
      restoreWindows: false, awakeMinutes: 30, audioOutput: .init(uid: "test", name: "fixture"))
    XCTAssertEqual(
      try JSONDecoder().decode(WorkspacePreset.self, from: JSONEncoder().encode(updated)).options,
      updated.options)
  }
  @MainActor
  func testInvalidOptionsDoNotRunAndMissingItemsReportPartialResults() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let model = WorkspacePresets(directory: directory)
    var preset = WorkspacePreset(
      id: UUID(), name: "Fixture",
      applications: [
        .init(
          bundleID: "missing", path: directory.appendingPathComponent("Missing.app").path,
          name: "Missing")
      ], folders: [directory.appendingPathComponent("missing").path], windows: [],
      capturedAt: Date(), options: .init(restoreWindows: false, awakeMinutes: 1))
    await model.restore(preset)
    XCTAssertTrue(model.steps.isEmpty)
    XCTAssertEqual(model.status, "Invalid work profile options")
    preset.options = .init(restoreWindows: false)
    await model.restore(preset)
    XCTAssertEqual(model.steps.count, 2)
    XCTAssertTrue(model.steps.allSatisfy { $0.outcome == .failed })
    XCTAssertEqual(model.status, "Workspace partially restored")
    XCTAssertEqual(model.runs.count, 1)
    XCTAssertEqual(model.inspectedRunID, model.runs.first?.id)
    XCTAssertFalse(model.busy)
    XCTAssertNil(model.runningName)
  }
  @MainActor
  func testUnreadablePresetFileIsNotOverwritten() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = directory.appendingPathComponent("workspace-presets-v1.json")
    let data = Data("invalid fixture".utf8)
    try data.write(to: file)
    let model = WorkspacePresets(directory: directory)
    await model.save(
      name: "New", selected: [], folders: [],
      options: .init(restoreWindows: false, awakeMinutes: 15))
    XCTAssertEqual(try Data(contentsOf: file), data)
    XCTAssertTrue(model.presets.isEmpty)
  }
  func testMissingAudioDeviceFailsBeforeChangingSystemDefaults() {
    XCTAssertThrowsError(
      try WorkProfileAudio.setDefault(
        uid: "macinity-missing-fixture-" + UUID().uuidString, role: .output))
  }
}
