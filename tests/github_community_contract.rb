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

puts("PASS: GitHub community reporting contract")
