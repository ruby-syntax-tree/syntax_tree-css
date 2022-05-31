# frozen_string_literal: true

require "test_helper"

module SyntaxTree
  module CSS
    class RuleListTest < Minitest::Test
      CSSParsingTests.each_test("rule_list.json") do |source, expected, index|
        define_method(:"test_#{index}") do
          parser = Parser.new(source)

          visitor = CSSParsingTests::ConvertVisitor.new(source)
          actual = visitor.visit_tokens(parser.parse_rule_list)

          if parser.errors.any? { |error| error.message.include?("qualified rule") }
            actual << ["error", "invalid"]
          end

          assert_equal(expected, actual, source.inspect)
        end
      end
    end
  end
end
