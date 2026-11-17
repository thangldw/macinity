import XCTest

@testable import MacinityStorage

final class CancellableWorkTests: XCTestCase {
  func testCancellingTheCallerStopsDetachedWork() async {
    let outer = Task { () throws -> Int in
      try await CancellableWork.run {
        while !Task.isCancelled { usleep(1_000) }
        throw CancellationError()
      }
    }
    try? await Task.sleep(for: .milliseconds(100))
    outer.cancel()
    let result = await outer.result
    XCTAssertThrowsError(try result.get()) { XCTAssertTrue($0 is CancellationError) }
  }

  func testReturnsValueWhenNotCancelled() async throws {
    let value = try await CancellableWork.run { 42 }
    XCTAssertEqual(value, 42)
  }
}
