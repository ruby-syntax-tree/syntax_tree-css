# frozen_string_literal: true

require "test_helper"

module SyntaxTree
  module CSS
    class SelectorsTest < Minitest::Spec
      it "parses a simple class selector" do
        actual = parse_selectors(".flex")

        assert_pattern do
          actual => [Selectors::ClassSelector[value: { value: "flex" }]]
        end
      end

      it "parses a compound class selector" do
        actual = parse_selectors(".flex.text-xl")

        assert_pattern do
          actual => [
            Selectors::CompoundSelector[
              subclasses: [
                Selectors::ClassSelector[value: { value: "flex" }],
                Selectors::ClassSelector[value: { value: "text-xl" }]
              ]
            ]
          ]
        end
      end

      it "parses a compound selector" do
        actual = parse_selectors("div.flex")

        assert_pattern do
          actual => [
            Selectors::CompoundSelector[
              type: { value: { name: { value: "div" } } },
              subclasses: [Selectors::ClassSelector[value: { value: "flex" }]],
              pseudo_elements: []
            ]
          ]
        end
      end

      it "parses a compound selector with a pseudo-element" do
        actual = parse_selectors("div.flex::first-line")

        assert_pattern do
          actual => [
            Selectors::CompoundSelector[
              type: { value: { name: { value: "div" } } },
              subclasses: [Selectors::ClassSelector[value: { value: "flex" }]],
              pseudo_elements: [
                [
                  Selectors::PseudoElementSelector[
                    Selectors::PseudoClassSelector[
                      value: { value: "first-line" }
                    ]
                  ],
                  []
                ]
              ]
            ]
          ]
        end
      end

      private

      def parse_selectors(selectors)
        css = selectors + " {}"
        Parser.new(css).parse.rules.first.selectors
      end
    end
  end
end
