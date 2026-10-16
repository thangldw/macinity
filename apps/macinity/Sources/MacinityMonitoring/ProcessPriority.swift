import Darwin
import Foundation

public enum ProcessPriority {
  /// Interactive, same-user, one-way reduction only. No signals, throttling loop or elevated helper.
  public static func lower(_ identity: ProcessIdentity) throws -> Int32 {
    let access = SystemProcessAccess()
    guard identity.pid > 1, identity.pid != getpid(), identity.pid != getppid(),
      try access.metadata(pid: identity.pid).identity == identity
    else { throw ProcessReadError.identityChanged }
    var info = proc_bsdinfo()
    let size = Int32(MemoryLayout<proc_bsdinfo>.size)
    guard proc_pidinfo(identity.pid, PROC_PIDTBSDINFO, 0, &info, size) == size,
      info.pbi_uid == getuid(), info.pbi_ruid == getuid()
    else { throw ProcessReadError.permissionRequired }
    errno = 0
    let previous = getpriority(PRIO_PROCESS, UInt32(identity.pid))
    guard errno == 0 else { throw ProcessReadError.unavailable }
    guard try access.metadata(pid: identity.pid).identity == identity else {
      throw ProcessReadError.identityChanged
    }
    // Increasing nice lowers priority; never raise an already lower-priority process.
    let desired = max(previous, 10)
    guard setpriority(PRIO_PROCESS, UInt32(identity.pid), desired) == 0 else {
      throw ProcessReadError.permissionRequired
    }
    guard try access.metadata(pid: identity.pid).identity == identity else {
      throw ProcessReadError.identityChanged
    }
    errno = 0
    let observed = getpriority(PRIO_PROCESS, UInt32(identity.pid))
    guard errno == 0, observed >= desired else { throw ProcessReadError.unavailable }
    return observed
  }
}
