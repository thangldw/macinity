import CoreServices
import Foundation

final class FSEventJournal: @unchecked Sendable {
  private let lock = NSLock()
  private var stream: FSEventStreamRef?
  private var recordedEvents: [FileSystemEvent] = []
  private let maximumEvents: Int

  init(maximumEvents: Int = 20_000) {
    self.maximumEvents = maximumEvents
  }

  func start(paths: [URL]) {
    _ = stop()
    lock.withLock { recordedEvents = [] }
    let uniquePaths = Array(Set(paths.map { $0.standardizedFileURL.path })).sorted()
    guard !uniquePaths.isEmpty else { return }
    var context = FSEventStreamContext(
      version: 0,
      info: Unmanaged.passUnretained(self).toOpaque(),
      retain: nil,
      release: nil,
      copyDescription: nil)
    let callback: FSEventStreamCallback = { _, info, count, eventPaths, flags, _ in
      guard let info else { return }
      let journal = Unmanaged<FSEventJournal>.fromOpaque(info).takeUnretainedValue()
      let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] ?? []
      journal.append(paths: Array(paths.prefix(count)), flags: flags, count: count)
    }
    guard
      let created = FSEventStreamCreate(
        nil, callback, &context, uniquePaths as CFArray,
        FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.25,
        FSEventStreamCreateFlags(
          kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes
            | kFSEventStreamCreateFlagWatchRoot))
    else { return }
    stream = created
    FSEventStreamSetDispatchQueue(created, DispatchQueue(label: "com.thang.changeora.fsevents"))
    FSEventStreamStart(created)
  }

  func stop() -> [FileSystemEvent] {
    if let stream {
      FSEventStreamStop(stream)
      FSEventStreamInvalidate(stream)
      FSEventStreamRelease(stream)
      self.stream = nil
    }
    return events()
  }

  func events() -> [FileSystemEvent] {
    lock.withLock { recordedEvents }
  }

  private func append(
    paths: [String], flags: UnsafePointer<FSEventStreamEventFlags>, count: Int
  ) {
    lock.withLock {
      guard recordedEvents.count < maximumEvents else { return }
      for index in 0..<min(count, paths.count) {
        recordedEvents.append(
          FileSystemEvent(path: paths[index], flags: UInt32(flags[index])))
        if recordedEvents.count >= maximumEvents { break }
      }
    }
  }

  deinit {
    _ = stop()
  }
}
