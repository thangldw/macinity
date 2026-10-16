import XCTest

@testable import Macinity

final class CrossModuleContractTests: XCTestCase {
  func testReviewStorageRoutePreservesCanonicalPath() {
    let route = MacinityRoute.reviewStorage(path: "/tmp/project/../project/.build")

    XCTAssertEqual(route.storagePath, "/tmp/project/.build")
  }
}
