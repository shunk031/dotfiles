# frozen_string_literal: true

# Core coverage engine (used by bashcov to build SimpleCov::Result).
require "simplecov"
# Export Cobertura XML for Codecov ingestion.
require "simplecov-cobertura"
# Keep local HTML output for debugging artifact inspection.
require "simplecov-html"

# Generate both human-readable and machine-readable outputs in one run:
# - HTML: quick local/manual diagnosis
# - Cobertura XML: CI upload target (`coverage/coverage.xml`)
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter,
  ]
)

SimpleCov.start do
  # CI workflow expects this exact directory and uploads `coverage/coverage.xml`.
  coverage_dir "coverage"

  # Exclude tests themselves from target coverage metrics.
  add_filter "/tests/"
  # Exclude generated coverage artifacts to avoid recursive self-counting.
  add_filter "/coverage/"
end
