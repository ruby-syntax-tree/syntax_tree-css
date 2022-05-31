# frozen_string_literal: true

require "simplecov"
SimpleCov.start

$:.unshift File.expand_path("../lib", __dir__)
require "syntax_tree/css"

require "json"
require "minitest/autorun"

module CSSParsingTests
  class ConvertVisitor < SyntaxTree::CSS::Visitor
    attr_reader :source

    def initialize(source)
      @source = source
    end

    # A special visit method that filters out tokens that map to nothing in the
    # output. This is used to make comments disappear.
    def visit_tokens(tokens)
      tokens.filter_map { |token| visit(token) }
    end

    def visit_at_keyword_token(node)
      ["at-keyword", node.value]
    end

    def visit_at_rule(node)
      block = node.block
      block = visit(block).tap(&:shift) if block

      ["at-rule", node.name, visit_tokens(node.prelude), block]
    end

    def visit_bad_string_token(node)
      ["error", "bad-string"]
    end

    def visit_bad_url_token(node)
      ["error", "bad-url"]
    end

    def visit_cdc_token(node)
      "-->"
    end

    def visit_cdo_token(node)
      "<!--"
    end

    def visit_close_paren_token(node)
      ["error", ")"]
    end

    def visit_close_square_token(node)
      ["error", "]"]
    end

    def visit_colon_token(node)
      ":"
    end

    def visit_comma_token(node)
      ","
    end

    def visit_comment_token(node)
    end

    def visit_declaration(node)
      ["declaration", node.name, visit_tokens(node.value), node.important?]
    end

    def visit_delim_token(node)
      node.value
    end

    def visit_dimension_token(node)
      ["dimension", source[node.location.to_range], node.value, node.type, node.unit]
    end

    def visit_function(node)
      ["function", node.name] + visit_tokens(node.value)
    end

    def visit_hash_token(node)
      ["hash", node.value, node.type]
    end

    def visit_ident_token(node)
      ["ident", node.value]
    end

    def visit_number_token(node)
      ["number", source[node.location.to_range], node.value, node.type]
    end

    def visit_percentage_token(node)
      ["percentage", source[node.location.to_range].chomp("%"), node.value, node.type]
    end

    def visit_qualified_rule(node)
      ["qualified rule", visit_tokens(node.prelude), visit(node.block).tap(&:shift)]
    end

    def visit_semicolon_token(node)
      ";"
    end

    def visit_simple_block(node)
      opening = node.token
      closing = { "(" => ")", "[" => "]", "{" => "}" }[opening]

      ["#{opening}#{closing}"] + visit_tokens(node.value)
    end

    def visit_string_token(node)
      ["string", node.value.gsub("\n", "")]
    end

    def visit_urange(node)
      ["unicode-range", node.start_value, node.end_value]
    end

    def visit_url_token(node)
      ["url", node.value]
    end

    def visit_whitespace_token(node)
      " "
    end
  end

  # Yield each test for a given fixture filename to the block.
  def self.each_test(filename)
    filepath = "css-parsing-tests/#{filename}"
    contents = File.read(File.expand_path(filepath, __dir__))

    JSON.parse(contents).each_slice(2).with_index(1) do |(source, expected), index|
      yield source, expected, index
    end
  end
end
