import XCTest

@testable import Macinity

final class ClipboardSnippetsTests: XCTestCase {
  func testHistoryDedupesBoundsAndRejectsBlankOrHuge() {
    var history = ClipboardHistory()
    XCTAssertFalse(history.add("   \n"))
    XCTAssertFalse(history.add(String(repeating: "a", count: ClipboardHistory.maxBytes + 1)))
    history.add("one")
    history.add("two")
    history.add("one")
    XCTAssertEqual(history.items.map(\.text), ["one", "two"])
    for index in 0..<100 { history.add("item \(index)") }
    XCTAssertEqual(history.items.count, ClipboardHistory.maxItems)
    XCTAssertEqual(history.items.first?.text, "item 99")
  }

  func testSensitivePasteboardTypesAreSkipped() {
    XCTAssertTrue(ClipboardHistory.isSensitive(types: ["public.utf8-plain-text", "org.nspasteboard.ConcealedType"]))
    XCTAssertFalse(ClipboardHistory.isSensitive(types: ["public.utf8-plain-text"]))
  }

  func testFilterMatchesAllWords() {
    var history = ClipboardHistory()
    history.add("hello world")
    history.add("hello there")
    XCTAssertEqual(history.filtered("hello world").count, 1)
    XCTAssertEqual(history.filtered("").count, 2)
  }

  func testSnippetLimitsAndValidation() {
    var library = SnippetLibrary()
    XCTAssertFalse(library.add(name: " ", text: "x"))
    XCTAssertFalse(library.add(name: "n", text: ""))
    XCTAssertTrue(library.add(name: "greeting", text: "hi"))
    for index in 0..<200 { library.add(name: "s\(index)", text: "t") }
    XCTAssertEqual(library.snippets.count, SnippetLibrary.maxSnippets)
  }

  @MainActor func testSnippetsPersistAndHistoryStaysOutOfDisk() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let model = ClipboardModel(directory: directory, defaults: defaults)
    model.saveSnippet(name: "sig", text: "Best regards")
    let reloaded = ClipboardModel(directory: directory, defaults: defaults)
    XCTAssertEqual(reloaded.library.snippets.map(\.name), ["sig"])
    XCTAssertFalse(reloaded.recording)
    XCTAssertTrue(reloaded.history.items.isEmpty)
  }
}
