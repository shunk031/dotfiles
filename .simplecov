# frozen_string_literal: true

require "simplecov"
require "simplecov-cobertura"
require "simplecov-html"

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter,
  ]
)

SimpleCov.start do
  coverage_dir "coverage"

  add_filter "/tests/"
  add_filter "/coverage/"
end
