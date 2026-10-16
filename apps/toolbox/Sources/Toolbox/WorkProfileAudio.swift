import CoreAudio
import Foundation

struct WorkAudioDevice: Identifiable, Sendable, Equatable {
  var id: String { uid }
  let uid: String
  let name: String
}
enum WorkAudioRole: String, CaseIterable, Sendable { case output, input }

enum WorkProfileAudio {
  private static func selector(_ role: WorkAudioRole) -> AudioObjectPropertySelector {
    role == .input
      ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice
  }
  private static func string(_ device: AudioObjectID, _ selector: AudioObjectPropertySelector)
    -> String?
  {
    var address = AudioObjectPropertyAddress(
      mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain)
    // CoreAudio transfers ownership of the CFString returned by these selectors.
    var value: Unmanaged<CFString>?
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr else {
      return nil
    }
    return value?.takeRetainedValue() as String?
  }
  static func devices(_ role: WorkAudioRole) throws -> [WorkAudioDevice] {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    guard
      AudioObjectGetPropertyDataSize(
        AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr,
      size <= 1024 * MemoryLayout<AudioObjectID>.size
    else { throw CocoaError(.fileReadUnknown) }
    guard size > 0 else { return [] }
    var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    let status = ids.withUnsafeMutableBytes {
      AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, $0.baseAddress!)
    }
    guard status == noErr else { throw CocoaError(.fileReadUnknown) }
    var seen: Set<String> = []
    return ids.compactMap { device in
      var streams = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyStreams,
        mScope: role == .input ? kAudioObjectPropertyScopeInput : kAudioObjectPropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain)
      var bytes: UInt32 = 0
      guard AudioObjectGetPropertyDataSize(device, &streams, 0, nil, &bytes) == noErr, bytes > 0,
        let uid = string(device, kAudioDevicePropertyDeviceUID), seen.insert(uid).inserted,
        let name = string(device, kAudioObjectPropertyName)
      else { return nil }
      return .init(uid: uid, name: name)
    }.sorted { $0.name < $1.name }
  }
  static func setDefault(uid: String, role: WorkAudioRole) throws {
    guard try devices(role).contains(where: { $0.uid == uid }) else {
      throw CocoaError(.fileNoSuchFile)
    }
    var device: AudioObjectID = 0
    let cfUID = uid as CFString
    var property = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDeviceForUID, mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain)
    var input = cfUID
    let result = withUnsafeMutablePointer(to: &input) { inputPointer in
      withUnsafeMutablePointer(to: &device) { outputPointer in
        var translation = AudioValueTranslation(
          mInputData: UnsafeMutableRawPointer(inputPointer),
          mInputDataSize: UInt32(MemoryLayout<CFString>.size),
          mOutputData: UnsafeMutableRawPointer(outputPointer),
          mOutputDataSize: UInt32(MemoryLayout<AudioObjectID>.size))
        var size = UInt32(MemoryLayout<AudioValueTranslation>.size)
        return AudioObjectGetPropertyData(
          AudioObjectID(kAudioObjectSystemObject), &property, 0, nil, &size, &translation)
      }
    }
    guard result == noErr, device != 0, string(device, kAudioDevicePropertyDeviceUID) == uid else {
      throw CocoaError(.fileReadUnknown)
    }
    var address = AudioObjectPropertyAddress(
      mSelector: selector(role), mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain)
    var settable: DarwinBoolean = false
    guard
      AudioObjectIsPropertySettable(AudioObjectID(kAudioObjectSystemObject), &address, &settable)
        == noErr, settable.boolValue,
      AudioObjectSetPropertyData(
        AudioObjectID(kAudioObjectSystemObject), &address, 0, nil,
        UInt32(MemoryLayout<AudioObjectID>.size), &device) == noErr
    else { throw CocoaError(.fileWriteUnknown) }
    var actual: AudioObjectID = 0
    var size = UInt32(MemoryLayout<AudioObjectID>.size)
    guard
      AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &actual) == noErr,
      string(actual, kAudioDevicePropertyDeviceUID) == uid
    else { throw CocoaError(.fileWriteUnknown) }
  }
}
