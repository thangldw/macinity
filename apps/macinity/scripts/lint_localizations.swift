#!/usr/bin/env swift
import Foundation

let project = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let sources = project.appendingPathComponent("Sources")
let resources = project.appendingPathComponent("Resources")
let manager = FileManager.default

func strings(at url: URL) throws -> Set<String> {
  let data = try Data(contentsOf: url)
  let dictionary = try PropertyListSerialization.propertyList(from: data, format: nil)
  guard let values = dictionary as? [String: String] else {
    throw NSError(
      domain: "LocalizationLint", code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid strings dictionary: \(url.path)"])
  }
  return Set(values.keys)
}

let englishFiles = ["Localizable.strings", "Storage.strings", "Changes.strings"].map {
  resources.appendingPathComponent("en.lproj/\($0)")
}
let englishKeys = try englishFiles.reduce(into: Set<String>()) { result, url in
  result.formUnion(try strings(at: url))
}
let vietnameseKeys = try strings(
  at: resources.appendingPathComponent("vi.lproj/Localizable.strings"))
let expression = try NSRegularExpression(
  pattern: #"L10n\.text\(\s*\"((?:[^\"\\]|\\.)*)\""#,
  options: [.dotMatchesLineSeparators])
var literalKeys = Set<String>()

let enumerator = manager.enumerator(at: sources, includingPropertiesForKeys: nil)
while let url = enumerator?.nextObject() as? URL {
  guard url.pathExtension == "swift", let source = try? String(contentsOf: url, encoding: .utf8)
  else { continue }
  let range = NSRange(source.startIndex..., in: source)
  for match in expression.matches(in: source, range: range) {
    guard let capture = Range(match.range(at: 1), in: source) else { continue }
    let key = String(source[capture]).replacingOccurrences(of: #"\""#, with: #"""#)
    if !key.contains(#"\("#) { literalKeys.insert(key) }
  }
}

let missingEnglish = literalKeys.subtracting(englishKeys).sorted()
let asciiKeys = literalKeys.filter { $0.unicodeScalars.allSatisfy(\.isASCII) }
let missingVietnamese = Set(asciiKeys).subtracting(vietnameseKeys).sorted()
if !missingEnglish.isEmpty || !missingVietnamese.isEmpty {
  for key in missingEnglish { fputs("Missing English key: \(key)\n", stderr) }
  for key in missingVietnamese { fputs("Missing Vietnamese key: \(key)\n", stderr) }
  exit(1)
}

print("PASS: \(literalKeys.count) literal L10n keys have English and Vietnamese coverage")
