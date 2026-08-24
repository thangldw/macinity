import XCTest

@testable import Toolbox

final class CrossModuleContractTests: XCTestCase {
  func testReviewStorageRoutePreservesCanonicalPath() {
    let route = ToolboxRoute.reviewStorage(path: "/tmp/project/../project/.build")

    XCTAssertEqual(route.storagePath, "/tmp/project/.build")
  }
}
