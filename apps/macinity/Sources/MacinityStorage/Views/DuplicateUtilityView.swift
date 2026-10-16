import SwiftUI

public struct DuplicateUtilityView: View {
  @StateObject private var model = DuplicateViewModel()
  public init() {}
  public var body: some View { DuplicateFilesView(model: model) }
}
