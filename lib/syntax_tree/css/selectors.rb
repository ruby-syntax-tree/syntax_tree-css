# frozen_string_literal: true

module SyntaxTree
  module CSS
    # Parses selectors according to https://www.w3.org/TR/selectors-4 from the
    # version dated 7 May 2022.
    class Selectors
      class ParseError < StandardError
      end

      class MissingTokenError < ParseError
      end

      # A custom enumerator around the list of tokens. This allows us to save a
      # reference to where we are when we're looking at the stream and rollback
      # to that point if we need to.
      class TokenEnumerator
        class Rollback < StandardError
        end

        attr_reader :tokens, :index

        def initialize(tokens)
          @tokens = tokens
          @index = 0
        end

        def next
          @tokens[@index].tap { @index += 1}
        end

        def peek
          @tokens[@index]
        end

        def transaction
          saved = @index
          yield
        rescue Rollback
          @index = saved
          nil
        end
      end

      AttributeSelector = Struct.new(:wq_name, :matcher, keyword_init: true)
      AttributeSelectorMatcher = Struct.new(:attr_matcher, :token, :modifier, keyword_init: true)
      AttrMatcher = Struct.new(:prefix, keyword_init: true)
      AttrModifier = Struct.new(:value, keyword_init: true)

      # The class of an element, e.g., .foo
      # https://www.w3.org/TR/selectors-4/#typedef-class-selector
      class ClassSelector < Node
        attr_reader :value

        def initialize(value:)
          @value = value
        end

        def accept(visitor)
          visitor.visit_class_selector(self)
        end

        def child_nodes
          [value]
        end

        alias deconstruct child_nodes

        def deconstruct_keys(keys)
          { value: value }
        end
      end

      class Combinator < Node
        attr_reader :value

        def initialize(value:)
          @value = value
        end

        def accept(visitor)
          visitor.visit_combinator(self)
        end

        def child_nodes
          [value]
        end

        alias deconstruct child_nodes

        def deconstruct_keys(keys)
          { value: value }
        end
      end

      class ComplexSelector < Node
        attr_reader :left, :combinator, :right

        def initialize(left:, combinator:, right:)
          @left = left
          @combinator = combinator
          @right = right
        end

        def accept(visitor)
          visitor.visit_complex_selector(self)
        end

        def child_nodes
          [left, combinator, right]
        end

        alias deconstruct child_nodes

        def deconstruct_keys(keys)
          { left: left, combinator: combinator, right: right }
        end
      end

      class CompoundSelector < Node
        attr_reader :type, :subclasses, :pseudo_elements

        def initialize(type:, subclasses:, pseudo_elements:)
          @type = type
          @subclasses = subclasses
          @pseudo_elements = pseudo_elements
        end

        def accept(visitor)
          visitor.visit_compound_selector(self)
        end

        def child_nodes
          [type, subclasses, pseudo_elements].flatten
        end

        alias deconstruct child_nodes

        def deconstruct_keys(keys)
          {
            type: type,
            subclasses: subclasses,
            pseudo_elements: pseudo_elements
          }
        end
      end

      # The ID of an element, e.g., #foo
      # https://www.w3.org/TR/selectors-4/#typedef-id-selector
      class IdSelector < Node
        attr_reader :value

        def initialize(value:)
          @value = value
        end

        def accept(visitor)
          visitor.visit_id_selector(self)
        end

        def child_nodes
          [value]
        end

        alias deconstruct child_nodes

        def deconstruct_keys(keys)
          { value: value }
        end
      end

      NsPrefix = Struct.new(:value, keyword_init: true)

      # A pseudo class function call, like :nth-child.
      class PseudoClassFunction < Node
        attr_reader :name, :arguments

        def initialize(name:, arguments:)
          @name = name
          @arguments = arguments
        end

        def accept(visitor)
          visitor.visit_pseudo_class_function(self)
        end

        def child_nodes
          arguments
        end

        alias deconstruct child_nodes

        def deconstruct_keys(keys)
          { name: name, arguments: arguments }
        end
      end

      # A pseudo class selector, like :hover.
      # https://www.w3.org/TR/selectors-4/#typedef-pseudo-class-selector
      class PseudoClassSelector < Node
        attr_reader :value

        def initialize(value:)
          @value = value
        end

        def accept(visitor)
          visitor.visit_pseudo_class_selector(self)
        end

        def child_nodes
          [value]
        end

        alias deconstruct child_nodes

        def deconstruct_keys(keys)
          { value: value }
        end
      end

      # A pseudo element selector, like ::before.
      # https://www.w3.org/TR/selectors-4/#typedef-pseudo-element-selector
      class PseudoElementSelector < Node
        attr_reader :value

        def initialize(value:)
          @value = value
        end

        def accept(visitor)
          visitor.visit_pseudo_element_selector(self)
        end

        def child_nodes
          [value]
        end

        alias deconstruct child_nodes

        def deconstruct_keys(keys)
          { value: value }
        end
      end

      RelativeSelector = Struct.new(:combinator, :complex_selector, keyword_init: true)

      # A selector for a specific tag name.
      # https://www.w3.org/TR/selectors-4/#typedef-type-selector
      class TypeSelector < Node
        attr_reader :prefix, :value

        def initialize(prefix:, value:)
          @prefix = prefix
          @value = value
        end

        def accept(visitor)
          visitor.visit_type_selector(self)
        end

        def child_nodes
          [prefix, value]
        end

        alias deconstruct child_nodes

        def deconstruct_keys(keys)
          { prefix: prefix, value: value }
        end
      end

      # The name of an element, e.g., foo
      class WqName < Node
        attr_reader :prefix, :name

        def initialize(prefix:, name:)
          @prefix = prefix
          @name = name
        end

        def accept(visitor)
          visitor.visit_wqname(self)
        end

        def child_nodes
          [prefix, name]
        end

        alias deconstruct child_nodes

        def deconstruct_keys(keys)
          { prefix: prefix, name: name }
        end
      end

      attr_reader :tokens

      def initialize(tokens)
        @tokens = TokenEnumerator.new(tokens)
      end

      def parse
        selector_list
      end

      private

      #-------------------------------------------------------------------------
      # Parsing methods
      #-------------------------------------------------------------------------

      # <selector-list> = <complex-selector-list>
      def selector_list
        complex_selector_list
      end

      # <complex-selector-list> = <complex-selector>#
      def complex_selector_list
        one_or_more { complex_selector }
      end

      # <compound-selector-list> = <compound-selector>#
      def compound_selector_list
        one_or_more { compound_selector }
      end

      # <simple-selector-list> = <simple-selector>#
      def simple_selector_list
        one_or_more { simple_selector }
      end

      # <relative-selector-list> = <relative-selector>#
      def relative_selector_list
        one_or_more { relative_selector }
      end

      # <complex-selector> = <compound-selector> [ <combinator>? <compound-selector> ]*
      def complex_selector
        consume_whitespace

        left = compound_selector

        if (c = maybe { combinator })
          ComplexSelector.new(left: left, combinator: c, right: complex_selector)
        elsif (right = maybe { complex_selector })
          ComplexSelector.new(left: left, combinator: nil, right: right)
        else
          left
        end
      end

      # <relative-selector> = <combinator>? <complex-selector>
      def relative_selector
        if (c = maybe { combinator })
          RelativeSelector.new(combinator: c, complex_selector: complex_selector)
        else
          complex_selector
        end
      end

      # <compound-selector> = [ <type-selector>? <subclass-selector>*
      #   [ <pseudo-element-selector> <pseudo-class-selector>* ]* ]!
      def compound_selector
        type = maybe { type_selector }
        subclasses = []

        while (subclass = maybe { subclass_selector })
          subclasses << subclass
        end

        pseudo_elements = []
        while (pseudo_element = maybe { pseudo_element_selector })
          pseudo_classes = []

          while (pseudo_class = maybe { pseudo_class_selector })
            pseudo_classes << pseudo_class
          end

          pseudo_elements << [pseudo_element, pseudo_classes]
        end

        if type.nil? && subclasses.empty? && pseudo_elements.empty?
          raise MissingTokenError, "Expected compound selector to produce something"
        elsif type && subclasses.empty? && pseudo_elements.empty?
          type
        elsif type.nil? && subclasses.one? && pseudo_elements.empty?
          subclasses.first
        else
          CompoundSelector.new(type: type, subclasses: subclasses, pseudo_elements: pseudo_elements)
        end
      end

      # <simple-selector> = <type-selector> | <subclass-selector>
      def simple_selector
        options { maybe { type_selector } || maybe { subclass_selector } }
      end

      # <combinator> = '>' | '+' | '~' | [ '|' '|' ]
      def combinator
        consume_whitespace

        value =
          options do
            maybe { consume(">") } ||
              maybe { consume("+") } ||
              maybe { consume("~") } ||
              maybe { consume("|", "|") }
          end

        Combinator.new(value: value)
      end

      # <type-selector> = <wq-name> | <ns-prefix>? '*'
      def type_selector
        selector = maybe { wq_name }
        return TypeSelector.new(prefix: nil, value: selector) if selector

        prefix = maybe { ns_prefix }
        TypeSelector.new(prefix: prefix, value: consume("*"))
      end

      # <ns-prefix> = [ <ident-token> | '*' ]? '|'
      def ns_prefix
        value = maybe { consume(IdentToken) } || maybe { consume("*") }
        consume("|")

        NsPrefix.new(value: value)
      end

      # <wq-name> = <ns-prefix>? <ident-token>
      def wq_name
        prefix = maybe { ns_prefix }
        name = consume(IdentToken)

        WqName.new(prefix: prefix, name: name)
      end

      # <subclass-selector> = <id-selector> | <class-selector> |
      #                 <attribute-selector> | <pseudo-class-selector>
      def subclass_selector
        options do
          maybe { id_selector } ||
            maybe { class_selector } ||
            maybe { attribute_selector } ||
            maybe { pseudo_class_selector }
        end
      end

      # <id-selector> = <hash-token>
      def id_selector
        IdSelector.new(value: consume(HashToken))
      end

      # <class-selector> = '.' <ident-token>
      def class_selector
        consume(".")
        ClassSelector.new(value: consume(IdentToken))
      end

      # <attribute-selector> = '[' <wq-name> ']' |
      #                  '[' <wq-name> <attr-matcher> [ <string-token> | <ident-token> ] <attr-modifier>? ']'
      def attribute_selector
        consume(OpenSquareToken)

        name = wq_name
        matcher =
          maybe do
            AttributeSelectorMatcher.new(
              attr_matcher: attr_matcher,
              token: options { maybe { consume(StringToken) } || maybe { consume(IdentToken) } },
              modifier: maybe { attr_modifier }
            )
          end

        consume(CloseSquareToken)
        AttributeSelector.new(wq_name: name, matcher: matcher)
      end

      # <attr-matcher> = [ '~' | '|' | '^' | '$' | '*' ]? '='
      def attr_matcher
        prefix =
          maybe { consume("~") } ||
            maybe { consume("|") } ||
            maybe { consume("^") } ||
            maybe { consume("$") } ||
            maybe { consume("*") }

        consume("=")
        AttrMatcher.new(prefix: prefix)
      end

      # <attr-modifier> = i | s
      def attr_modifier
        value = options { maybe { consume("i") } || maybe { consume("s") } }
        AttrModifier.new(value: value)
      end

      # <pseudo-class-selector> = ':' <ident-token> |
      #                     ':' <function-token> <any-value> ')'
      def pseudo_class_selector
        consume(ColonToken)

        case tokens.peek
        in IdentToken
          PseudoClassSelector.new(value: consume(IdentToken))
        in Function
          node = consume(Function)
          function = PseudoClassFunction.new(name: node.name, arguments: node.value)
          PseudoClassSelector.new(value: function)
        else
          raise MissingTokenError, "Expected pseudo class selector to produce something"
        end
      end

      # <pseudo-element-selector> = ':' <pseudo-class-selector>
      def pseudo_element_selector
        consume(ColonToken)
        PseudoElementSelector.new(value: pseudo_class_selector)
      end

      #-------------------------------------------------------------------------
      # Helper methods
      #-------------------------------------------------------------------------

      def consume_whitespace
        loop do
          case tokens.peek
          in CommentToken | WhitespaceToken
            tokens.next
          else
            return
          end
        end
      end

      def one_or_more
        items = []

        consume_whitespace
        items << yield

        loop do
          consume_whitespace
          if maybe { consume(CommaToken) }
            consume_whitespace
            items << yield
          else
            return items
          end
        end
      end

      def consume(*values)
        result =
          values.map do |value|
            case [value, tokens.peek]
            in [String, DelimToken[value: token_value]] if value == token_value
              tokens.next
            in [Class, token] if token.is_a?(value)
              tokens.next
            in [_, token]
              raise MissingTokenError, "Expected #{value} but got #{token.inspect}"
            end
          end

        result.size == 1 ? result.first : result
      end

      def maybe
        tokens.transaction do
          begin
            yield
          rescue MissingTokenError
            raise TokenEnumerator::Rollback
          end
        end
      end

      def options
        value = yield
        raise MissingTokenError, "Expected one of many to match" if value.nil?
        value
      end
    end
  end
end
