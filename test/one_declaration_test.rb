# frozen_string_literal: true

require "test_helper"

module SyntaxTree
  module CSS
    class OneDeclarationTest < Minitest::Test
      CSSParsingTests.each_test("one_declaration.json") do |source, expected, index|
        define_method(:"test_#{index}") do
          parser = Parser.new(source)

          token = parser.parse_declaration
          actual =
            if token.is_a?(Parser::ParseError)
              case token.message
              in /end of input/
                ["error", "empty"]
              in /Expected an identifier/
                ["error", "invalid"]
              in /Expected a declaration/
                ["error", "invalid"]
              end
            else
              CSSParsingTests::ConvertVisitor.new(source).visit(token)
            end

          # For some reason, the css-parsing-tests repository has a whitespace
          # token before any of the content of the declaration, even though in
          # the spec it's supposed to be consumed. Here we remove that.
          if expected[0] == "declaration"
            expected[2].shift if expected[2][0] == " "
            expected[2].pop if expected[2][-1] == " "
          end

          assert_equal(expected, actual, source.inspect)
        end
      end
    end
  end
end
