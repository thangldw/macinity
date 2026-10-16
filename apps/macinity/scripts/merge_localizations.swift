#!/usr/bin/env swift
import Foundation

guard CommandLine.arguments.count == 3 else {
  fputs("usage: merge_localizations.swift <source.lproj> <output.strings>\n", stderr)
  exit(2)
}

let sourceDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let inputNames = ["Storage.strings", "Changes.strings", "Localizable.strings"]
var merged: [String: String] = [:]

for name in inputNames {
  let url = sourceDirectory.appendingPathComponent(name)
  guard let dictionary = NSDictionary(contentsOf: url) as? [String: String] else {
    fputs("invalid strings file: \(url.path)\n", stderr)
    exit(1)
  }
  merged.merge(dictionary) { _, latest in latest }
}

func escaped(_ value: String) -> String {
  value
    .replacingOccurrences(of: "\\", with: "\\\\")
    .replacingOccurrences(of: "\"", with: "\\\"")
    .replacingOccurrences(of: "\n", with: "\\n")
}

let output =
  merged.keys.sorted().map { key in
    "\"\(escaped(key))\" = \"\(escaped(merged[key]!))\";"
  }.joined(separator: "\n") + "\n"
try output.write(to: outputURL, atomically: true, encoding: .utf8)
