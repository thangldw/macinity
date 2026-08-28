#!/usr/bin/env ruby

require "fileutils"
require "open3"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
CHECKER = File.join(ROOT, "tests/github_community_contract.rb")
CODE_OF_CONDUCT = File.read(File.join(ROOT, "CODE_OF_CONDUCT.md"))

def replace_in_english(text, pattern, replacement)
  prefix, remainder = text.split("## English", 2)
  english, suffix = remainder.split("## Tiếng Việt", 2)
  mutated = english.sub(pattern, replacement)
  raise "fixture pattern not found" if mutated == english

  "#{prefix}## English#{mutated}## Tiếng Việt#{suffix}"
end

def assert_rejected(name, code_of_conduct, expected_error)
  Dir.mktmpdir("toolbox-community-contract-") do |fixture|
    FileUtils.mkdir_p(File.join(fixture, "tests"))
    FileUtils.cp(CHECKER, File.join(fixture, "tests/github_community_contract.rb"))
    FileUtils.cp_r(File.join(ROOT, ".github"), File.join(fixture, ".github"))
    File.write(File.join(fixture, "CODE_OF_CONDUCT.md"), code_of_conduct)

    _stdout, stderr, status = Open3.capture3(
      "ruby",
      "tests/github_community_contract.rb",
      chdir: fixture
    )
    if status.success?
      warn("FAIL: github community contract accepted #{name}")
      exit(1)
    end
    unless stderr.include?(expected_error)
      warn("FAIL: #{name} produced unexpected error: #{stderr.strip}")
      exit(1)
    end
  end
end

assert_rejected(
  "an English section without the private reporting route",
  replace_in_english(
    CODE_OF_CONDUCT,
    "https://github.com/thangldw/toolbox/security/advisories/new",
    "https://example.invalid/conduct"
  ),
  "English section must use the private reporting channel"
)

assert_rejected(
  "an English section without Contributor Covenant attribution",
  replace_in_english(
    CODE_OF_CONDUCT,
    "https://www.contributor-covenant.org/version/2/0/code_of_conduct.html",
    "https://example.invalid/covenant"
  ),
  "English section must identify the Contributor Covenant template"
)

assert_rejected(
  "an unresolved contact placeholder",
  replace_in_english(CODE_OF_CONDUCT, "Toolbox's private reporting form", "[EMAIL]"),
  "Code of Conduct contains an unresolved contact placeholder"
)

puts("PASS: GitHub community contract regression fixtures")
