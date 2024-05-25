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

      it "parses a complex selector" do
        actual = parse_selectors("section>table")

        assert_pattern do
          actual => [
            Selectors::ComplexSelector[
              left: Selectors::TypeSelector[value: { name: { value: "section" } }],
              combinator: { value: { value: ">" } },
              right: Selectors::TypeSelector[value: { name: { value: "table" } }]
            ]
          ]
        end
      end

      it "parses a complex selector with many selectors" do
        actual = parse_selectors("section>table>tr")

        assert_pattern do
          actual => [
            Selectors::ComplexSelector[
              left: Selectors::TypeSelector[value: { name: { value: "section" } }],
              combinator: { value: { value: ">" } },
              right: Selectors::ComplexSelector[
                left: Selectors::TypeSelector[value: { name: { value: "table" } }],
                combinator: { value: { value: ">" } },
                right: Selectors::TypeSelector[value: { name: { value: "tr" } }]
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
