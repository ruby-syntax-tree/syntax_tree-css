# frozen_string_literal: true

require "test_helper"

module SyntaxTree
  module CSS
    class OneRuleTest < Minitest::Test
      CSSParsingTests.each_test("one_rule.json") do |source, expected, index|
        define_method(:"test_#{index}") do
          parser = Parser.new(source)

          token = parser.parse_rule
          actual =
            if token.is_a?(Parser::ParseError)
              case token.message
              in /Unexpected end of input/
                ["error", "empty"]
              in /Expected end of input/
                ["error", "extra-input"]
              in /Expected a rule/
                ["error", "invalid"]
              end
            else
              CSSParsingTests::ConvertVisitor.new(source).visit(token)
            end

          assert_equal(expected, actual, source.inspect)
        end
      end
    end
  end
end
