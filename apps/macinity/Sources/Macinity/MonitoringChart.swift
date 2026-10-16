import MacinityCore
import MacinityMonitoring
import SwiftUI

struct ChartDatum: Identifiable, Equatable {
  var id: Double { time.monotonic }
  let time: SampleTime
  let value: Double?
  let generation: Int
  init(time: SampleTime, value: Double?, generation: Int = 0) {
    self.time = time
    self.value = value
    self.generation = generation
  }
}

private struct ChartMark: Identifiable {
  var id: Double { time.monotonic }
  let time: SampleTime
  let value: Double
  let segment: Int
}

struct MonitoringChart: View {
  @Environment(\.locale) private var locale
  let title: String
  let unit: String
  let data: [ChartDatum]
  var percentScale = false
  var embedded = false
  var height: CGFloat = 150
  var windowSeconds: Double = 60
  var maximumGap: Double = 6
  @State private var inspectedTime: Double?

  private var points: [ChartMark] {
    var segment = 0
    var previous: Double?
    var generation: Int?
    return data.compactMap { point in
      defer {
        previous = point.time.monotonic
        generation = point.generation
      }
      if let generation, generation != point.generation { segment += 1 }
      guard let value = point.value, value.isFinite else {
        segment += 1
        return nil
      }
      if let previous, point.time.monotonic - previous > maximumGap { segment += 1 }
      return ChartMark(time: point.time, value: value, segment: segment)
    }
  }
  private var index: Int {
    data.firstIndex { $0.id == inspectedTime } ?? max(0, data.count - 1)
  }
  private var latest: Double { data.last?.time.monotonic ?? 0 }

  var body: some View {
    let timeAxisTitle = L10n.text("Seconds before latest sample")
    return VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.title2.weight(.semibold))
      plot
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(summary)
      Text(timeAxisTitle).font(.caption).foregroundStyle(MacinityTheme.secondary)
      if !data.isEmpty {
        HStack {
          Button(L10n.text("Previous sample")) { inspectedTime = data[max(0, index - 1)].id }
            .disabled(index == 0)
          Button(L10n.text("Next sample")) {
            inspectedTime = data[min(data.count - 1, index + 1)].id
          }
          .disabled(index == data.count - 1)
          Text(data[index].time.wall.formatted(.dateTime.hour().minute().locale(locale)))
          Text(
            data[index].value.map {
              monitoringNumber($0, digits: 1) + " " + unit
            } ?? L10n.text("Unavailable")
          )
          .monospacedDigit()
        }.font(.caption)
      } else {
        Text(L10n.text("No samples yet.")).font(.caption).foregroundStyle(.secondary)
      }
    }
    .padding(embedded ? 0 : 20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      embedded ? Color.clear : MacinityTheme.surface, in: RoundedRectangle(cornerRadius: 16)
    )
    .overlay {
      if !embedded {
        RoundedRectangle(cornerRadius: 16).stroke(MacinityTheme.border, lineWidth: 1)
          .allowsHitTesting(
            false)
      }
    }
  }

  // A bounded, linear Canvas avoids rebuilding a framework mark tree every sample.
  // Each contiguous segment gets its own path, so missing samples never become a line.
  private var plot: some View {
    let marks = points
    let last = latest
    let upper = percentScale ? 100 : max(1, (marks.map(\.value).max() ?? 1) * 1.1)
    return Canvas { context, size in
      let bounds = CGRect(
        x: 8, y: 24, width: max(1, size.width - 46),
        height: max(1, size.height - 48))
      for tick in 0...4 {
        let fraction = CGFloat(tick) / 4
        let y = bounds.maxY - fraction * bounds.height
        var grid = Path()
        grid.move(to: CGPoint(x: bounds.minX, y: y))
        grid.addLine(to: CGPoint(x: bounds.maxX, y: y))
        context.stroke(grid, with: .color(MacinityTheme.border), lineWidth: 1)
        context.draw(
          Text(
            monitoringNumber(Double(fraction) * upper, digits: upper < 2 ? 2 : (upper < 10 ? 1 : 0))
          )
          .font(.caption).foregroundColor(MacinityTheme.secondary),
          at: CGPoint(x: bounds.maxX + 8, y: y), anchor: .leading)
      }
      for fraction in [0.0, 1.0 / 3, 2.0 / 3, 1.0] {
        let seconds = Int((fraction - 1) * windowSeconds)
        let x = bounds.minX + CGFloat(fraction) * bounds.width
        var grid = Path()
        grid.move(to: CGPoint(x: x, y: bounds.minY))
        grid.addLine(to: CGPoint(x: x, y: bounds.maxY))
        context.stroke(
          grid, with: .color(MacinityTheme.border),
          style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        context.draw(
          Text(String(seconds)).font(.caption).foregroundColor(MacinityTheme.secondary),
          at: CGPoint(x: x, y: bounds.maxY + 8),
          anchor: fraction == 0 ? .topLeading : (fraction == 1 ? .topTrailing : .top))
      }
      context.draw(
        Text(unit).font(.caption).foregroundColor(MacinityTheme.secondary),
        at: CGPoint(x: bounds.maxX + 8, y: 0), anchor: .topLeading)
      for segment in Dictionary(grouping: marks, by: \.segment).values {
        let coordinates = segment.compactMap { mark -> CGPoint? in
          let seconds = mark.time.monotonic - last
          guard seconds >= -windowSeconds, seconds <= 0 else { return nil }
          return CGPoint(
            x: bounds.minX + CGFloat((seconds + windowSeconds) / windowSeconds) * bounds.width,
            y: bounds.maxY - CGFloat(min(upper, max(0, mark.value)) / upper) * bounds.height)
        }
        guard let first = coordinates.first, let final = coordinates.last else { continue }
        var line = Path()
        line.move(to: first)
        for coordinate in coordinates.dropFirst() { line.addLine(to: coordinate) }
        if coordinates.count == 1 {
          context.fill(
            Path(ellipseIn: CGRect(x: first.x - 2, y: first.y - 2, width: 4, height: 4)),
            with: .color(MacinityTheme.accent))
        } else {
          var area = line
          area.addLine(to: CGPoint(x: final.x, y: bounds.maxY))
          area.addLine(to: CGPoint(x: first.x, y: bounds.maxY))
          area.closeSubpath()
          context.fill(area, with: .color(MacinityTheme.accent.opacity(0.10)))
          context.stroke(line, with: .color(MacinityTheme.accent), lineWidth: 2)
        }
      }
    }
  }

  private var summary: String {
    guard let minimum = points.map(\.value).min(), let maximum = points.map(\.value).max() else {
      return L10n.text("No samples yet.")
    }
    return String(
      format: L10n.text(
        "%d valid samples. Minimum %.1f, maximum %.1f %@. Missing samples are gaps."),
      locale: locale, points.count,
      minimum, maximum, unit)
  }
}
