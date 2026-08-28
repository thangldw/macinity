#!/usr/bin/env ruby

require "yaml"

ROOT = File.expand_path("..", __dir__)

def fail_contract(message)
  warn("FAIL: #{message}")
  exit(1)
end

def load_yaml(relative_path)
  path = File.join(ROOT, relative_path)
  fail_contract("missing #{relative_path}") unless File.file?(path)

  YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
rescue Psych::SyntaxError => error
  fail_contract("invalid YAML in #{relative_path}: #{error.message}")
end

def validate_form(relative_path, required_ids)
  form = load_yaml(relative_path)
  %w[name description title body].each do |key|
    fail_contract("#{relative_path} missing #{key}") unless form[key]
  end

  body = form["body"]
  fail_contract("#{relative_path} body must be a list") unless body.is_a?(Array)

  ids = body.filter_map { |item| item["id"] }
  fail_contract("#{relative_path} contains duplicate field ids") unless ids.uniq == ids

  missing = required_ids - ids
  fail_contract("#{relative_path} missing fields: #{missing.join(', ')}") unless missing.empty?

  required_ids.each do |id|
    item = body.find { |candidate| candidate["id"] == id }
    validations = item.fetch("validations", {})
    fail_contract("#{relative_path} field #{id} must be required") unless validations["required"] == true
  end
end

validate_form(
  ".github/ISSUE_TEMPLATE/bug_report.yml",
  %w[toolbox-version macos-version architecture workflow observed expected reproduction privacy]
)
validate_form(
  ".github/ISSUE_TEMPLATE/feature_request.yml",
  %w[problem workflow evidence safety privacy]
)

config = load_yaml(".github/ISSUE_TEMPLATE/config.yml")
fail_contract("blank issues must stay disabled") unless config["blank_issues_enabled"] == false

security_link = Array(config["contact_links"]).find do |link|
  link["url"] == "https://github.com/thangldw/toolbox/security/advisories/new"
end
fail_contract("missing private security reporting link") unless security_link

code_of_conduct_path = File.join(ROOT, "CODE_OF_CONDUCT.md")
fail_contract("missing CODE_OF_CONDUCT.md") unless File.file?(code_of_conduct_path)

code_of_conduct = File.read(code_of_conduct_path)
placeholder = /\[(?:INSERT [^\]]+|EMAIL|CONTACT(?: METHOD)?)\]/i
fail_contract("Code of Conduct contains an unresolved contact placeholder") if code_of_conduct.match?(placeholder)

languages = ["English", "Tiếng Việt", "日本語"]
language_matches = languages.map do |language|
  matches = code_of_conduct.enum_for(:scan, /^## #{Regexp.escape(language)}\s*$/).map { Regexp.last_match }
  fail_contract("Code of Conduct must contain exactly one #{language} section") unless matches.length == 1
  matches.first
end

private_reporting_url = "https://github.com/thangldw/toolbox/security/advisories/new"
private_reporting_link = /\[[^\]]+\]\(#{Regexp.escape(private_reporting_url)}\)/
attribution_url = "https://www.contributor-covenant.org/version/2/0/code_of_conduct.html"

languages.each_with_index do |language, index|
  section_start = language_matches[index].end(0)
  section_end = index + 1 < language_matches.length ? language_matches[index + 1].begin(0) : code_of_conduct.length
  section = code_of_conduct[section_start...section_end]

  unless section.scan(private_reporting_link).length == 1
    fail_contract("#{language} section must use the private reporting channel exactly once")
  end
  unless section.scan(attribution_url).length == 1
    fail_contract("#{language} section must identify the Contributor Covenant template exactly once")
  end
end

puts("PASS: GitHub community reporting contract")
