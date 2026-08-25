import Foundation
import XCTest

@testable import Toolbox

final class ReleaseUpdateCheckerTests: XCTestCase {
  func testLatestVersionUsesOnlyPublicReleaseEndpoint() async throws {
    let session = UpdateSessionStub(
      data: Data(#"{"tag_name":"v2.1.3"}"#.utf8), statusCode: 200)
    let checker = ReleaseUpdateChecker(session: session)

    let version = try await checker.latestVersion()
    let request = await session.request

    XCTAssertEqual(version, SemanticVersion(major: 2, minor: 1, patch: 3))
    XCTAssertEqual(
      request?.url?.absoluteString,
      "https://api.github.com/repos/thangldw/toolbox/releases/latest")
    XCTAssertNil(request?.httpBody)
  }

  func testSemanticVersionRejectsInvalidComponents() {
    XCTAssertNil(SemanticVersion("v2.invalid.1"))
    XCTAssertNil(SemanticVersion("2.1"))
  }
}

private actor UpdateSessionStub: URLSessionProtocol {
  let data: Data
  let statusCode: Int
  private(set) var request: URLRequest?

  init(data: Data, statusCode: Int) {
    self.data = data
    self.statusCode = statusCode
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    self.request = request
    return (
      data,
      HTTPURLResponse(
        url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
    )
  }
}
