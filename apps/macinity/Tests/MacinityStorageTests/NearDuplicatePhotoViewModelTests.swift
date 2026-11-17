import XCTest

@testable import MacinityStorage

@MainActor
final class NearDuplicatePhotoViewModelTests: XCTestCase {
  private func photo(_ path: String, side: Int, bytes: Int64) -> SimilarPhoto {
    SimilarPhoto(
      url: URL(fileURLWithPath: path), bytes: bytes, capturedAt: .distantPast, pixelWidth: side,
      pixelHeight: side, sharpnessScore: 1)
  }

  /// Group 1 in /x (distance 0.05, keep a1); group 2 in /y (distance 0.15, keep b1).
  private func loadedModel() -> NearDuplicatePhotoViewModel {
    let model = NearDuplicatePhotoViewModel()
    model.load(
      snapshot: NearDuplicateSnapshot(
        photos: [
          photo("/x/a1", side: 200, bytes: 500), photo("/x/a2", side: 100, bytes: 100),
          photo("/y/b1", side: 200, bytes: 300), photo("/y/b2", side: 100, bytes: 50),
        ],
        pairs: [
          PhotoPairDistance(first: 0, second: 1, distance: 0.05),
          PhotoPairDistance(first: 2, second: 3, distance: 0.15),
        ], scannedCount: 4, cachedCount: 0, skippedCount: 0, skippedPhotos: 0))
    return model
  }

  func testSuggestionsArePrefilledOnLoad() {
    let model = loadedModel()
    XCTAssertEqual(model.minimumSimilarity, 0.90, accuracy: 1e-9)
    XCTAssertEqual(model.groups.count, 1)
    XCTAssertEqual(model.deleteIDs, ["/x/a2"])
  }

  func testCannotMarkEveryPhotoOfAGroupForDeletion() throws {
    let model = loadedModel()
    let keep = try XCTUnwrap(model.groups.first?.photos.first)
    XCTAssertFalse(model.setDelete(keep, true))
    XCTAssertEqual(model.deleteIDs, ["/x/a2"])
  }

  func testSwitchingKeepPhotoIsAllowed() throws {
    let model = loadedModel()
    let photos = try XCTUnwrap(model.groups.first?.photos)
    XCTAssertTrue(model.setDelete(photos[1], false))
    XCTAssertTrue(model.setDelete(photos[0], true))
    XCTAssertEqual(model.deleteIDs, ["/x/a1"])
  }

  func testSlidingThresholdRegroupsAndKeepsUserOverrides() throws {
    let model = loadedModel()
    let a2 = try XCTUnwrap(model.groups.first?.photos.last)
    XCTAssertTrue(model.setDelete(a2, false))
    model.setMinimumSimilarity(0.80)
    XCTAssertEqual(model.groups.count, 2)
    XCTAssertEqual(model.deleteIDs, ["/y/b2"])
    model.setMinimumSimilarity(0.90)
    XCTAssertEqual(model.groups.count, 1)
    XCTAssertTrue(model.deleteIDs.isEmpty)
  }

  func testSimilarityIsClampedToSliderRange() {
    let model = loadedModel()
    model.setMinimumSimilarity(0.10)
    XCTAssertEqual(model.minimumSimilarity, 0.80, accuracy: 1e-9)
    model.setMinimumSimilarity(5)
    XCTAssertEqual(model.minimumSimilarity, 1.0, accuracy: 1e-9)
  }

  func testSummaryCountsFollowDecisions() {
    let model = loadedModel()
    model.setMinimumSimilarity(0.80)
    XCTAssertEqual(model.keepCount, 2)
    XCTAssertEqual(model.deleteCount, 2)
    XCTAssertEqual(model.bytesFreed, 150)
  }

  func testFolderFilterShowsOnlyGroupsTouchingFolderAndScopesSummary() {
    let model = loadedModel()
    model.setMinimumSimilarity(0.80)
    XCTAssertEqual(model.folders, ["/x", "/y"])
    model.folderFilter = "/x"
    XCTAssertEqual(model.groups.count, 1)
    XCTAssertEqual(model.deleteCount, 1)
    XCTAssertEqual(model.bytesFreed, 100)
  }

  func testApplySuggestionsResetsDecisions() throws {
    let model = loadedModel()
    let a2 = try XCTUnwrap(model.groups.first?.photos.last)
    XCTAssertTrue(model.setDelete(a2, false))
    model.applySuggestions()
    XCTAssertEqual(model.deleteIDs, ["/x/a2"])
  }

  // MARK: chained groups

  func testPhotosWithoutDirectLinkToKeeperAreNotPreMarkedRemove() throws {
    let model = NearDuplicatePhotoViewModel()
    model.load(
      snapshot: NearDuplicateSnapshot(
        photos: [
          photo("/x/a", side: 300, bytes: 500), photo("/x/b", side: 200, bytes: 300),
          photo("/x/c", side: 100, bytes: 100),
        ],
        pairs: [
          PhotoPairDistance(first: 0, second: 1, distance: 0.05),
          PhotoPairDistance(first: 1, second: 2, distance: 0.09),
        ], scannedCount: 3, cachedCount: 0, skippedCount: 0, skippedPhotos: 0))
    let group = try XCTUnwrap(model.groups.first)
    XCTAssertEqual(group.photos.count, 3)
    XCTAssertEqual(model.deleteIDs, ["/x/b"])
    let b = try XCTUnwrap(group.photos.first { $0.id == "/x/b" })
    let c = try XCTUnwrap(group.photos.first { $0.id == "/x/c" })
    XCTAssertEqual(try XCTUnwrap(model.similarityToKeeper(b, in: group)), 0.95, accuracy: 1e-6)
    XCTAssertNil(model.similarityToKeeper(c, in: group))
  }

  // MARK: trashing

  private var temporaryDirectory: URL!

  private func realPhoto(_ name: String, side: Int, bytes: Int64) throws -> SimilarPhoto {
    let url = temporaryDirectory.appendingPathComponent(name)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("x".utf8).write(to: url)
    return SimilarPhoto(
      url: url, bytes: bytes, capturedAt: .distantPast, pixelWidth: side, pixelHeight: side,
      sharpnessScore: 1)
  }

  private func model(
    photos: [SimilarPhoto], pairs: [PhotoPairDistance],
    trasher: @escaping NearDuplicatePhotoViewModel.Trasher
  ) -> NearDuplicatePhotoViewModel {
    let model = NearDuplicatePhotoViewModel(trasher: trasher)
    model.rootURL = temporaryDirectory
    model.load(
      snapshot: NearDuplicateSnapshot(
        photos: photos, pairs: pairs, scannedCount: photos.count, cachedCount: 0,
        skippedCount: 0, skippedPhotos: 0))
    return model
  }

  override func setUp() async throws {
    temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString)
  }
  override func tearDown() async throws {
    try? FileManager.default.removeItem(at: temporaryDirectory)
  }

  func testTrashedPhotosLeaveResultsWithoutRescanAndGroupDisappears() async throws {
    let keep = try realPhoto("x/keep.jpg", side: 200, bytes: 500)
    let drop = try realPhoto("x/drop.jpg", side: 100, bytes: 100)
    var received: [String] = []
    let model = model(
      photos: [keep, drop], pairs: [PhotoPairDistance(first: 0, second: 1, distance: 0.02)]
    ) { photos, _, _ in
      received = photos.map(\.id)
      for photo in photos { try? FileManager.default.removeItem(at: photo.url) }
      return []
    }
    await model.trashSelectedAsync()
    XCTAssertEqual(received, [drop.id])
    XCTAssertTrue(model.groups.isEmpty)
    XCTAssertTrue(model.trashErrors.isEmpty)
  }

  func testGroupWhoseKeeperIsGoneFromDiskIsNotTrashed() async throws {
    let keep = try realPhoto("x/keep.jpg", side: 200, bytes: 500)
    let drop = try realPhoto("x/drop.jpg", side: 100, bytes: 100)
    var called = false
    let model = model(
      photos: [keep, drop], pairs: [PhotoPairDistance(first: 0, second: 1, distance: 0.02)]
    ) { _, _, _ in
      called = true
      return []
    }
    try FileManager.default.removeItem(at: keep.url)
    await model.trashSelectedAsync()
    XCTAssertFalse(called)
    XCTAssertEqual(model.trashErrors.count, 1)
    XCTAssertEqual(model.groups.count, 1)
  }

  func testPerFileTrashErrorsSurviveAndFailedPhotosStayListed() async throws {
    let keep = try realPhoto("x/keep.jpg", side: 200, bytes: 500)
    let drop = try realPhoto("x/drop.jpg", side: 100, bytes: 100)
    let model = model(
      photos: [keep, drop], pairs: [PhotoPairDistance(first: 0, second: 1, distance: 0.02)]
    ) { _, _, _ in ["drop.jpg: permission denied"] }
    await model.trashSelectedAsync()
    XCTAssertEqual(model.trashErrors, ["drop.jpg: permission denied"])
    XCTAssertEqual(model.groups.count, 1)
    XCTAssertEqual(model.deleteIDs, [drop.id])
  }

  func testOnlyVisibleFolderIsTrashed() async throws {
    let a1 = try realPhoto("x/a1.jpg", side: 200, bytes: 500)
    let a2 = try realPhoto("x/a2.jpg", side: 100, bytes: 100)
    let b1 = try realPhoto("y/b1.jpg", side: 200, bytes: 500)
    let b2 = try realPhoto("y/b2.jpg", side: 100, bytes: 100)
    var received: [String] = []
    let model = model(
      photos: [a1, a2, b1, b2],
      pairs: [
        PhotoPairDistance(first: 0, second: 1, distance: 0.02),
        PhotoPairDistance(first: 2, second: 3, distance: 0.02),
      ]
    ) { photos, _, _ in
      received = photos.map(\.id)
      return []
    }
    model.folderFilter = a1.url.deletingLastPathComponent().path
    await model.trashSelectedAsync()
    XCTAssertEqual(received, [a2.id])
  }

  // MARK: review-pass additions

  func testRefusedChangeExplainsWhyAndSuccessClearsTheHint() throws {
    let model = loadedModel()
    let keep = try XCTUnwrap(model.groups.first?.photos.first)
    XCTAssertNil(model.hint)
    XCTAssertFalse(model.setDelete(keep, true))
    XCTAssertNotNil(model.hint)
    let other = try XCTUnwrap(model.groups.first?.photos.last)
    XCTAssertTrue(model.setDelete(other, false))
    XCTAssertNil(model.hint)
  }

  func testCompareUsesThePhotoCurrentlyKept() throws {
    let model = loadedModel()
    let group = try XCTUnwrap(model.groups.first)
    let (a1, a2) = (group.photos[0], group.photos[1])
    XCTAssertEqual(model.keptPhoto(for: a2, in: group)?.id, a1.id)
    XCTAssertTrue(model.setDelete(a2, false))
    XCTAssertTrue(model.setDelete(a1, true))
    XCTAssertEqual(model.keptPhoto(for: a1, in: model.groups[0])?.id, a2.id)
  }

  func testTrashUsesTheRootThatWasScanned() async throws {
    let keep = try realPhoto("x/keep.jpg", side: 200, bytes: 500)
    let drop = try realPhoto("x/drop.jpg", side: 100, bytes: 100)
    var receivedRoot: URL?
    let model = NearDuplicatePhotoViewModel { _, root, _ in
      receivedRoot = root
      return []
    }
    model.load(
      snapshot: NearDuplicateSnapshot(
        photos: [keep, drop], pairs: [PhotoPairDistance(first: 0, second: 1, distance: 0.02)],
        scannedCount: 2, cachedCount: 0, skippedCount: 0, skippedPhotos: 0),
      root: temporaryDirectory)
    model.rootURL = URL(fileURLWithPath: "/somewhere/else")
    await model.trashSelectedAsync()
    XCTAssertEqual(receivedRoot, temporaryDirectory)
  }

  func testStopIsNotOfferedWhileTrashing() async throws {
    let keep = try realPhoto("x/keep.jpg", side: 200, bytes: 500)
    let drop = try realPhoto("x/drop.jpg", side: 100, bytes: 100)
    var holder: NearDuplicatePhotoViewModel?
    var trashingDuringCall = false
    let model = model(
      photos: [keep, drop], pairs: [PhotoPairDistance(first: 0, second: 1, distance: 0.02)]
    ) { _, _, _ in
      trashingDuringCall = holder?.isTrashing == true
      return []
    }
    holder = model
    XCTAssertFalse(model.isTrashing)
    await model.trashSelectedAsync()
    XCTAssertTrue(trashingDuringCall)
    XCTAssertFalse(model.isTrashing)
  }

  func testOverlappingScansEndWithLatestResultAndIdleState() async throws {
    let original = PhotoFixtures.structured(width: 800, height: 600)
    PhotoFixtures.write(original, to: temporaryDirectory.appendingPathComponent("a.png"))
    PhotoFixtures.write(
      PhotoFixtures.resized(original, width: 400, height: 300),
      to: temporaryDirectory.appendingPathComponent("sub/a-small.png"))
    let model = NearDuplicatePhotoViewModel(
      cacheURL: temporaryDirectory.appendingPathComponent("cache.json"))
    model.rootURL = temporaryDirectory
    let first = model.scan()
    let second = model.scan()
    await first.value
    await second.value
    XCTAssertFalse(model.isWorking)
    XCTAssertEqual(model.groups.count, 1)
  }
}
