# frozen_string_literal: true

module SyntaxTree
  module CSS
    # This represents a location in the source file. It maps constructs like
    # tokens and parse nodes to their original location.
    class Location
      attr_reader :start_char, :end_char

      def initialize(start_char:, end_char:)
        @start_char = start_char
        @end_char = end_char
      end

      def to(other)
        Location.new(start_char: start_char, end_char: other.end_char)
      end
    end

    # A parent class for all of the various nodes in the tree. Provides common
    # functionality between them.
    class Node
      def pretty_print(q)
        PrettyPrint.new(q).visit(self)
      end
    end

    # This represents a token in the source. It contains a type, a value, a
    # location which is a range of indices in the source, and any number of
    # flags that may be relevant to the token.
    class Token < Node
      attr_reader :type, :value, :location, :flags

      def initialize(type, value, location, flags = {})
        @type = type
        @value = value
        @location = Location.new(start_char: location.begin, end_char: location.end)
        @flags = flags
      end

      def self.eof(index)
        Token.new(:EOF, nil, index...index)
      end

      def accept(visitor)
        visitor.visit_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { type: type, value: value, location: location, flags: flags }
      end
    end

    # This is the top node in the tree if it hasn't been converted into a CSS
    # stylesheet.
    class StyleSheet < Node
      attr_reader :rules, :location

      def initialize(rules:, location:)
        @rules = rules
        @location = location
      end

      def accept(visitor)
        visitor.visit_stylesheet(self)
      end

      def child_nodes
        rules
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { rules: rules, location: location }
      end
    end

    # This is the top node in the tree if it has been converted into a CSS
    # stylesheet.
    class CSSStyleSheet < Node
      attr_reader :rules, :location

      def initialize(rules:, location:)
        @rules = rules
        @location = location
      end

      def accept(visitor)
        visitor.visit_css_stylesheet(self)
      end

      def child_nodes
        rules
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { rules: rules, location: location }
      end
    end

    # 9.2. At-rules
    # https://www.w3.org/TR/css-syntax-3/#at-rules
    class AtRule < Node
      attr_reader :name, :prelude, :block, :location

      def initialize(name:, prelude:, block:, location:)
        @name = name
        @prelude = prelude
        @block = block
      end

      def accept(visitor)
        visitor.visit_at_rule(self)
      end

      def child_nodes
        [*prelude, block].compact
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { name: name, prelude: prelude, block: block, location: location }
      end
    end

    # https://www.w3.org/TR/css-syntax-3/#qualified-rule
    class QualifiedRule < Node
      attr_reader :prelude, :block, :location

      def initialize(prelude:, block:, location:)
        @prelude = prelude
        @block = block
        @location = location
      end

      def accept(visitor)
        visitor.visit_qualified_rule(self)
      end

      def child_nodes
        [*prelude, block].compact
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { prelude: prelude, block: block, location: location }
      end
    end

    # https://www.w3.org/TR/css-syntax-3/#declaration
    class Declaration < Node
      attr_reader :name, :value, :location

      def initialize(name:, value:, important:, location:)
        @name = name
        @value = value
        @important = important
        @location = location
      end

      def accept(visitor)
        visitor.visit_declaration(self)
      end

      def child_nodes
        value
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { name: name, value: value, important: important?, location: location }
      end

      def important?
        @important
      end
    end

    # https://www.w3.org/TR/css-syntax-3/#simple-block
    class SimpleBlock < Node
      attr_reader :token, :value, :location

      def initialize(token:, value:, location:)
        @token = token
        @value = value
        @location = location
      end

      def accept(visitor)
        visitor.visit_simple_block(self)
      end

      def child_nodes
        value
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { token: token, value: value, location: location }
      end
    end

    # https://www.w3.org/TR/css-syntax-3/#function
    class Function < Node
      attr_reader :name, :value, :location

      def initialize(name:, value:, location:)
        @name = name
        @value = value
        @location = location
      end

      def accept(visitor)
        visitor.visit_function(self)
      end

      def child_nodes
        value
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { name: name, value: value, location: location }
      end
    end

    # https://www.w3.org/TR/css-syntax-3/#style-rule
    class StyleRule < Node
      attr_reader :selectors, :declarations, :location

      def initialize(selectors:, declarations:, location:)
        @selectors = selectors
        @declarations = declarations
        @location = location
      end

      def accept(visitor)
        visitor.visit_style_rule(self)
      end

      def child_nodes
        [*selectors, *declarations]
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { selectors: selectors, declarations: declarations, location: location }
      end
    end
  end
end
