# frozen_string_literal: true

require "prettier_print"
require "syntax_tree"

require_relative "css/nodes"
require_relative "css/parser"
require_relative "css/selectors"

require_relative "css/basic_visitor"
require_relative "css/format"
require_relative "css/visitor"
require_relative "css/pretty_print"

module SyntaxTree
  module CSS
    def self.format(source, maxwidth = 80)
      PrettierPrint.format(+"", maxwidth) { |q| parse(source).format(q) }
    end

    def self.parse(source)
      Parser.new(source).parse
    end

    def self.read(filepath)
      File.read(filepath)
    end
  end

  register_handler(".css", CSS)
end
