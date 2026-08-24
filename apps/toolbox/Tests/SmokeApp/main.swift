import Foundation

actor SmokeUpdateSession: URLSessionProtocol {
  private(set) var request: URLRequest?

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    self.request = request
    let response = HTTPURLResponse(
      url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
    return (Data(#"{"tag_name":"v2.1.3"}"#.utf8), response)
  }
}

@main
struct SmokeApp {
  static func main() async throws {
    let session = SmokeUpdateSession()
    let version = try await ReleaseUpdateChecker(session: session).latestVersion()
    guard version == SemanticVersion(major: 2, minor: 1, patch: 3) else {
      fatalError("Release version parsing failed")
    }
    guard SemanticVersion("v2.invalid.1") == nil else {
      fatalError("Invalid release version was accepted")
    }
    let request = await session.request
    guard
      request?.url?.absoluteString
        == "https://api.github.com/repos/thangldw/toolbox/releases/latest",
      request?.httpBody == nil
    else {
      fatalError("Update request leaked fields or used the wrong endpoint")
    }
    print("PASS: user-initiated update request contract")
  }
}
