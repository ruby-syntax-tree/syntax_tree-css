# frozen_string_literal: true

require "test_helper"

module SyntaxTree
  module CSS
    class StylesheetTest < Minitest::Test
      CSSParsingTests.each_test("stylesheet.json") do |source, expected, index|
        define_method(:"test_#{index}") do
          parser = Parser.new(source)

          visitor = CSSParsingTests::ConvertVisitor.new(source)
          actual = visitor.visit(parser.parse_stylesheet)

          if parser.errors.any? { |error| error.message.include?("parsing qualified rule") }
            actual << ["error", "invalid"]
          end

          assert_equal(expected, actual, source.inspect)
        end
      end
    end
  end
end
