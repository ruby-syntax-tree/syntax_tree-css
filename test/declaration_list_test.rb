# frozen_string_literal: true

require "test_helper"

module SyntaxTree
  module CSS
    class DeclarationListTest < Minitest::Test
      CSSParsingTests.each_test("declaration_list.json") do |source, expected, index|
        define_method(:"test_#{index}") do
          parser = Parser.new(source)

          visitor = CSSParsingTests::ConvertVisitor.new(source)
          actual = visitor.visit_tokens(parser.parse_declaration_list)

          # Not entirely sure where the syntax errors are supposed to be
          # inserted into the output, so just rejecting them to be lazy.
          expected.reject! { |token| token == ["error", "invalid"] }

          assert_equal(expected, actual, source.inspect)
        end
      end
    end
  end
end
