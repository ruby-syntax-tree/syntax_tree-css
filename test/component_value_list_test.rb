# frozen_string_literal: true

require "test_helper"

module SyntaxTree
  module CSS
    class ComponentValueListTest < Minitest::Test
      CSSParsingTests.each_test("component_value_list.json") do |source, expected, index|
        # There are a couple of cases where css-parsing-tests considers things
        # to be urange tokens and we don't. This includes places where the start
        # is greater than the end, where the end is greater than the maximum
        # code point, or when the tokenizer for ours determines that a ? belongs
        # to the urange while their tokenizer does not. In this case we're going
        # to modify or skip the tests to match our expected behavior.
        case source
        when "u+? u+1? U+10? U+100? U+1000? U+10000? U+100000?"
          source = source[0...-("U+100000?".length)]
          expected.pop(2)
        when "u+??? U+1??? U+10??? U+100??? U+1000???"
          source = source[0...-("U+100000?".length)]
          expected.pop(2)
        when "u+????? U+1????? U+10?????"
          source = source[0...-("U+1????? U+10?????".length)]
          expected.pop(4)
        when "u+?? U+1?? U+10?? U+100?? U+1000?? U+10000??"
          source = source[0...-("U+10000??".length)]
          expected.pop(2)
        when "u+???? U+1???? U+10???? U+100????"
          source = source[0...-("U+100????".length)]
          expected.pop(2)
        when "u+1 U+10 U+100 U+1000 U+10000 U+100000 U+1000000"
          source = source[0...-("U+1000000".length)]
          expected.pop(2)
        when "u+1-2 U+100000-2 U+1000000-2 U+10-200000"
          source = source[0..("u+1-2".length)]
          expected = expected[0..1]
        when "u+?????? U+1??????"
          next
        end

        # There are a couple of tests where css-parsing-tests is attempting to
        # parse operators in selectors, which is not actually part of the CSS
        # parsing spec. So we skip or modify those tests here.
        case source
        when "~=|=^=$=*=||<!------> |/**/| ~/**/="
          next
        when "a:not([href^=http\\:],  [href ^=\t'https\\:'\n]) { color: rgba(0%, 100%, 50%); }"
          source.gsub!("^=", "=")
          deep_map = ->(token) do
            case token
            when "^="
              "="
            when Array
              token.map(&deep_map)
            else
              token
            end
          end

          expected.map!(&deep_map)
        end

        define_method(:"test_#{index}") do
          parser = Parser.new(source)

          visitor = CSSParsingTests::ConvertVisitor.new(source)
          actual = visitor.visit_tokens(parser.parse_component_values)

          target = actual
          target = target.last while (target.last in ["function", *])

          parser.errors.each do |error|
            case error.message
            when /unterminated string/
              target << ["error", "eof-in-string"]
            when /unterminated url/
              target << ["error", "eof-in-url"]
            end
          end

          assert_equal(expected, actual, source.inspect)
        end
      end
    end
  end
end
