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

      def to_range
        start_char...end_char
      end

      def self.from(range)
        Location.new(start_char: range.begin, end_char: range.end)
      end
    end

    # A parent class for all of the various nodes in the tree. Provides common
    # functionality between them.
    class Node
      def format(q)
        Format.new(q).visit(self)
      end

      def pretty_print(q)
        PrettyPrint.new(q).visit(self)
      end
    end

    # A parsed token that is an identifier that starts with an @ sign.
    # https://www.w3.org/TR/css-syntax-3/#typedef-at-keyword-token
    class AtKeywordToken < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_at_keyword_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end

    # A rule that starts with an at-keyword and then accepts arbitrary tokens.
    # A common example is an @media rule.
    # https://www.w3.org/TR/css-syntax-3/#at-rule
    class AtRule < Node
      attr_reader :name, :prelude, :block, :location

      def initialize(name:, prelude:, block:, location:)
        @name = name
        @prelude = prelude
        @block = block
        @location = location
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

    # A parsed token that was a quotes string that had a syntax error. It is
    # mostly here for error recovery.
    # https://www.w3.org/TR/css-syntax-3/#typedef-bad-string-token
    class BadStringToken < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_bad_string_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end

    # A parsed token that was a call to "url" that had a syntax error. It is
    # mostly here for error recovery.
    # https://www.w3.org/TR/css-syntax-3/#typedef-bad-url-token
    class BadURLToken < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_bad_url_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end

    # A parsed token containing a CDC (-->).
    # https://www.w3.org/TR/css-syntax-3/#typedef-cdc-token
    class CDCToken < Node
      attr_reader :location

      def initialize(location:)
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_cdc_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end
    end

    # A parsed token containing a CDO (<!--).
    # https://www.w3.org/TR/css-syntax-3/#typedef-cdo-token
    class CDOToken < Node
      attr_reader :location

      def initialize(location:)
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_cdo_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end
    end

    # A parsed token that represents the use of a }.
    # https://www.w3.org/TR/css-syntax-3/#tokendef-close-curly
    class CloseCurlyToken < Node
      attr_reader :location

      def initialize(location:)
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_close_curly_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end

      # Here for convenience for comparing between block types.
      def value
        "}"
      end
    end

    # A parsed token that represents the use of a ).
    # https://www.w3.org/TR/css-syntax-3/#tokendef-close-paren
    class CloseParenToken < Node
      attr_reader :location

      def initialize(location:)
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_close_paren_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end

      # Here for convenience for comparing between block types.
      def value
        ")"
      end
    end

    # A parsed token that represents the use of a ].
    # https://www.w3.org/TR/css-syntax-3/#tokendef-close-square
    class CloseSquareToken < Node
      attr_reader :location

      def initialize(location:)
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_close_square_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end

      # Here for convenience for comparing between block types.
      def value
        "]"
      end
    end

    # A parsed token containing a colon.
    # https://www.w3.org/TR/css-syntax-3/#typedef-colon-token
    class ColonToken < Node
      attr_reader :location

      def initialize(location:)
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_colon_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end
    end

    # A parsed token that contains a comma.
    # https://www.w3.org/TR/css-syntax-3/#typedef-comma-token
    class CommaToken < Node
      attr_reader :location

      def initialize(location:)
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_comma_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end
    end

    # A parsed token that contains a comment. These aren't actually declared in
    # the spec because it assumes you can just drop them. We parse them into
    # tokens, however, so that we can keep track of their location.
    class CommentToken < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_comment_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
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

    # Declarations are a particular instance of associating a property or
    # descriptor name with a value.
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

    # A parsed token that has a value composed of a single code point.
    # https://www.w3.org/TR/css-syntax-3/#typedef-delim-token
    class DelimToken < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_delim_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end

    # A parsed token that contains a numeric value with a dimension.
    # https://www.w3.org/TR/css-syntax-3/#typedef-dimension-token
    class DimensionToken < Node
      attr_reader :value, :unit, :type, :location

      def initialize(value:, unit:, type:, location:)
        @value = value
        @unit = unit
        @type = type
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_dimension_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, type: type, location: location }
      end
    end

    # A conceptual token representing the end of the list of tokens. Whenever
    # the list of tokens is empty, the next input token is always an EOFToken.
    # https://www.w3.org/TR/css-syntax-3/#typedef-eof-token
    class EOFToken < Node
      attr_reader :location

      def initialize(location:)
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_eof_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end

      # Since we create EOFToken objects a lot with ranges that are empty, it's
      # nice to have this convenience method.
      def self.[](index)
        new(location: index...index)
      end
    end

    # A function has a name and a value consisting of a list of component
    # values.
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

    # A parsed token that contains the beginning of a call to a function, e.g.,
    # "url(".
    # https://www.w3.org/TR/css-syntax-3/#typedef-function-token
    class FunctionToken < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_function_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end

    # A parsed token that contains an identifier that starts with a # sign.
    # https://www.w3.org/TR/css-syntax-3/#typedef-hash-token
    class HashToken < Node
      attr_reader :value, :type, :location

      def initialize(value:, type:, location:)
        @value = value
        @type = type
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_hash_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, type: type, location: location }
      end
    end

    # A parsed token that contains an plaintext identifier.
    # https://www.w3.org/TR/css-syntax-3/#typedef-ident-token
    class IdentToken < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_ident_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end

    # A parsed token that contains a numeric value.
    # https://www.w3.org/TR/css-syntax-3/#typedef-number-token
    class NumberToken < Node
      attr_reader :value, :type, :location

      def initialize(value:, type:, location:)
        @value = value
        @type = type
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_number_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, type: type, location: location }
      end
    end

    # A parsed token that represents the use of a {.
    # https://www.w3.org/TR/css-syntax-3/#tokendef-open-curly
    class OpenCurlyToken < Node
      attr_reader :location

      def initialize(location:)
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_open_curly_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end

      # Here for convenience for comparing between block types.
      def value
        "{"
      end
    end

    # A parsed token that represents the use of a (.
    # https://www.w3.org/TR/css-syntax-3/#tokendef-open-paren
    class OpenParenToken < Node
      attr_reader :location

      def initialize(location:)
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_open_paren_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end

      # Here for convenience for comparing between block types.
      def value
        "("
      end
    end

    # A parsed token that represents the use of a [.
    # https://www.w3.org/TR/css-syntax-3/#tokendef-open-square
    class OpenSquareToken < Node
      attr_reader :location

      def initialize(location:)
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_open_square_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end

      # Here for convenience for comparing between block types.
      def value
        "["
      end
    end

    # A parsed token that contains a numeric value with a percentage sign.
    # https://www.w3.org/TR/css-syntax-3/#typedef-percentage-token
    class PercentageToken < Node
      attr_reader :value, :type, :location

      def initialize(value:, type:, location:)
        @value = value
        @type = type
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_percentage_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, type: type, location: location }
      end
    end

    # Associates a prelude consisting of a list of component values with a block
    # consisting of a simple {} block.
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

    # A parsed token that contains a comma.
    # https://www.w3.org/TR/css-syntax-3/#typedef-semicolon-token
    class SemicolonToken < Node
      attr_reader :location

      def initialize(location:)
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_semicolon_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end
    end

    # A simple block has an associated token (either a <[-token>, <(-token>, or
    # <{-token>) and a value consisting of a list of component values.
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

    # A parsed token that contains a quoted string.
    # https://www.w3.org/TR/css-syntax-3/#typedef-string-token
    class StringToken < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_string_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end

    # A style rule is a qualified rule that associates a selector list with a
    # list of property declarations and possibly a list of nested rules.
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

    # This node represents the use of the urange micro syntax, e.g. U+1F601.
    # https://www.w3.org/TR/css-syntax-3/#typedef-urange
    class URange < Node
      attr_reader :start_value, :end_value, :location

      def initialize(start_value:, end_value:, location:)
        @start_value = start_value
        @end_value = end_value
        @location = location
      end

      def accept(visitor)
        visitor.visit_urange(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { start_value: start_value, end_value: end_value, location: location }
      end
    end

    # A parsed token that contains a URL. Note that this is different from a
    # function call to the "url" function only if quotes aren't used.
    # https://www.w3.org/TR/css-syntax-3/#typedef-url-token
    class URLToken < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_url_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end

    # A parsed token that contains only whitespace.
    # https://www.w3.org/TR/css-syntax-3/#typedef-whitespace-token
    class WhitespaceToken < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = Location.from(location)
      end

      def accept(visitor)
        visitor.visit_whitespace_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end
  end
end
