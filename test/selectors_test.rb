# frozen_string_literal: true

require "test_helper"

module SyntaxTree
  module CSS
    class SelectorsTest < Minitest::Spec
      describe "parsing" do
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

          assert_pattern do
            actual => [
              Selectors::CompoundSelector[
                Selectors::ClassSelector[value: { value: "flex" }],
                Selectors::ClassSelector[value: { value: "text-xl" }]
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

          assert_pattern do
            actual => [
              Selectors::CompoundSelector[
                Selectors::TypeSelector[value: { name: { value: "div" } } ],
                Selectors::ClassSelector[value: { value: "flex" }],
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
                      value: { value: { value: "first-line" } }
                    ],
                    []
                  ]
                ]
              ]
            ]
          end
        end

        it "parses a compound selector with a pseudo-class" do
          actual = parse_selectors("div.flex:hover")

          assert_pattern do
            actual => [
              Selectors::CompoundSelector[
                type: { value: { name: { value: "div" } } },
                subclasses: [
                  Selectors::ClassSelector[value: { value: "flex" }],
                  Selectors::PseudoClassSelector[value: { value: "hover" }],
                ],
              ]
            ]
          end
        end

        it "parses a compound selector with pseudo-elements and pseudo-classes" do
          actual = parse_selectors("div.flex:hover::first-line:last-child:active::first-letter")

          assert_pattern do
            actual => [
              Selectors::CompoundSelector[
                type: { value: { name: { value: "div" } } },
                subclasses: [
                  Selectors::ClassSelector[value: { value: "flex" }],
                  Selectors::PseudoClassSelector[value: { value: "hover" }],
                ],
                pseudo_elements: [
                  [
                    Selectors::PseudoElementSelector[value: { value: { value: "first-line" } }],
                    [
                      Selectors::PseudoClassSelector[value: { value: "last-child" }],
                      Selectors::PseudoClassSelector[value: { value: "active" }],
                    ],
                  ],
                  [
                    Selectors::PseudoElementSelector[value: { value: { value: "first-letter" } }],
                    [],
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
                child_nodes: [
                  Selectors::TypeSelector[value: { name: { value: "section" } }],
                  Selectors::Combinator[value: { value: ">" }],
                  Selectors::TypeSelector[value: { name: { value: "table" } }]
                ]
              ]
            ]
          end
        end

        it "parses a complex selector with many selectors" do
          actual = parse_selectors("section>table>tr")

          assert_pattern do
            actual => [
              Selectors::ComplexSelector[
                child_nodes: [
                  Selectors::TypeSelector[value: { name: { value: "section" } }],
                  Selectors::Combinator[value: { value: ">" }],
                  Selectors::TypeSelector[value: { name: { value: "table" } }],
                  Selectors::Combinator[value: { value: ">" }],
                  Selectors::TypeSelector[value: { name: { value: "tr" } }],
                ]
              ]
            ]
          end
        end

        it "parses a complex selector with whitespace" do
          actual = parse_selectors("section > table")

          assert_pattern do
            actual => [
              Selectors::ComplexSelector[
                child_nodes: [
                  Selectors::TypeSelector[value: { name: { value: "section" } }],
                  Selectors::Combinator[value: { value: ">" }],
                  Selectors::TypeSelector[value: { name: { value: "table" } }],
                ]
              ]
            ]
          end
        end

        it "parses a complex selector with implicit descendant combinator" do
          actual = parse_selectors("section table")

          assert_pattern do
            actual => [
              Selectors::ComplexSelector[
                child_nodes: [
                  Selectors::TypeSelector[value: { name: { value: "section" } }],
                  Selectors::TypeSelector[value: { name: { value: "table" } }],
                ]
              ]
            ]
          end
        end

        it "parses a complex complex selector" do
          actual = parse_selectors("section > table tr")

          assert_pattern do
            actual => [
              Selectors::ComplexSelector[
                child_nodes: [
                  Selectors::TypeSelector[value: { name: { value: "section" } }],
                  Selectors::Combinator[value: { value: ">" }],
                  Selectors::TypeSelector[value: { name: { value: "table" } }],
                  Selectors::TypeSelector[value: { name: { value: "tr" } }]
                ]
              ]
            ]
          end
        end

      end

      describe "formatting" do
        it "formats complex selectors" do
          assert_selector_format(".outer section.foo>table.bar   tr", ".outer section.foo > table.bar tr")
        end

        private

        def assert_selector_format(selectors, expected)
          selectors = parse_selectors(selectors)

          io = StringIO.new
          selectors.each do |selector|
            selector.format(::PrettyPrint.new(io))
            assert_equal(expected, io.string)
          end
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
