import Foundation
import ToolboxCore

struct SemanticVersion: Comparable, Equatable, Sendable {
  let major: Int
  let minor: Int
  let patch: Int

  init(major: Int, minor: Int, patch: Int) {
    self.major = major
    self.minor = minor
    self.patch = patch
  }

  init?(_ tag: String) {
    var cleanTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
    if cleanTag.hasPrefix("v") { cleanTag.removeFirst() }
    let normalized = cleanTag.split(separator: "-", maxSplits: 1).first.map(String.init) ?? ""
    let components = normalized.split(separator: ".")
    guard components.count == 3 else { return nil }
    let values = components.compactMap { Int($0) }
    guard values.count == components.count else { return nil }
    self.init(major: values[0], minor: values[1], patch: values[2])
  }

  static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
  }

  var description: String { "\(major).\(minor).\(patch)" }
}

protocol URLSessionProtocol: Sendable {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {
  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    try await data(for: request, delegate: nil)
  }
}

enum ReleaseUpdateError: LocalizedError {
  case invalidResponse(Int)

  var errorDescription: String? {
    switch self {
    case .invalidResponse(let status):
      "GitHub release endpoint returned HTTP \(status)."
    }
  }
}

struct ReleaseUpdateChecker: Sendable {
  private struct Release: Decodable { let tagName: String }
  private static let endpoint = URL(
    string: "https://api.github.com/repos/thangldw/toolbox/releases/latest")!
  private let session: any URLSessionProtocol

  init(session: any URLSessionProtocol = URLSession.shared) {
    self.session = session
  }

  func latestVersion() async throws -> SemanticVersion? {
    var request = URLRequest(url: Self.endpoint)
    request.httpMethod = "GET"
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("Toolbox/\(AppMetadata.version)", forHTTPHeaderField: "User-Agent")
    let (data, response) = try await session.data(for: request)
    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
    guard (200..<300).contains(status) else { throw ReleaseUpdateError.invalidResponse(status) }
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return SemanticVersion(try decoder.decode(Release.self, from: data).tagName)
  }
}
