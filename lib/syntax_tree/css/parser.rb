# frozen_string_literal: true

module SyntaxTree
  module CSS
    # Parses CSS3 stylesheets according to https://www.w3.org/TR/css-syntax-3
    # from the version dated 24 December 2021.
    class Parser
      # Represents any kind of error that occurs during parsing.
      class ParseError < StandardError
      end

      # This is used to communicate between the various tokenization algorithms.
      # It transports a value along with the new index.
      class State
        attr_reader :value, :index

        def initialize(value, index)
          @value = value
          @index = index
        end
      end

      # https://www.w3.org/TR/css-syntax-3/#digit
      DIGIT = "[0-9]"

      # https://www.w3.org/TR/css-syntax-3/#uppercase-letter
      UPPERCASE_LETTER = "[A-Z]"

      # https://www.w3.org/TR/css-syntax-3/#lowercase-letter
      LOWERCASE_LETTER = "[a-z]"

      # https://www.w3.org/TR/css-syntax-3/#letter
      LETTER = "[#{UPPERCASE_LETTER}#{LOWERCASE_LETTER}]"

      # https://www.w3.org/TR/css-syntax-3/#non-ascii-code-point
      NONASCII = "[\u{80}-\u{10FFFF}]"

      # https://www.w3.org/TR/css-syntax-3/#ident-start-code-point
      IDENT_START = "[#{LETTER}#{NONASCII}_]"

      # https://www.w3.org/TR/css-syntax-3/#ident-code-point
      IDENT = "[#{IDENT_START}#{DIGIT}-]"

      # https://www.w3.org/TR/css-syntax-3/#non-printable-code-point
      NON_PRINTABLE = "[\x00-\x08\x0B\x0E-\x1F\x7F]"

      # https://www.w3.org/TR/css-syntax-3/#whitespace
      WHITESPACE = "[\n\t ]"

      attr_reader :source, :errors

      def initialize(source)
        @source = preprocess(source)
        @errors = []
      end

      def error?
        errors.any?
      end

      #-------------------------------------------------------------------------
      # 5.3. Parser Entry Points
      # https://www.w3.org/TR/css-syntax-3/#parser-entry-points
      #-------------------------------------------------------------------------

      # 5.3.1. Parse something according to a CSS grammar
      # https://www.w3.org/TR/css-syntax-3/#parse-grammar
      def parse(grammar: :stylesheet)
        case grammar
        in :stylesheet
          parse_css_stylesheet
        else
          raise ArgumentError, "Unsupported grammar: #{grammar}"
        end
      end

      # 5.3.3. Parse a stylesheet
      # https://www.w3.org/TR/css-syntax-3/#parse-stylesheet
      def parse_stylesheet
        tokens = tokenize
        rules = consume_rule_list(tokens, top_level: true)

        location =
          if rules.any?
            rules.first.location.to(rules.last.location)
          else
            tokens.reverse_each.first.location
          end

        StyleSheet.new(rules: rules, location: location)
      end

      # 5.3.4. Parse a list of rules
      # https://www.w3.org/TR/css-syntax-3/#parse-list-of-rules
      def parse_rule_list
        consume_rule_list(tokenize, top_level: false)
      end

      # 5.3.5. Parse a rule
      # https://www.w3.org/TR/css-syntax-3/#parse-rule
      def parse_rule
        # 1.
        tokens = tokenize

        # 2.
        loop do
          case tokens.peek
          in CommentToken | WhitespaceToken
            tokens.next
          else
            break
          end
        end

        # 3.
        rule = nil

        case tokens.peek
        in EOFToken
          return ParseError.new("Unexpected end of input parsing rule")
        in AtKeywordToken
          rule = consume_at_rule(tokens)
        else
          rule = consume_qualified_rule(tokens)
          return ParseError.new("Expected a rule at #{tokens.peek.location.start_char}") unless rule
        end

        # 4.
        loop do
          case tokens.peek
          in CommentToken | WhitespaceToken
            tokens.next
          else
            break
          end
        end

        # 5.
        case tokens.peek
        in EOFToken
          rule
        else
          ParseError.new("Expected end of input parsing rule")
        end
      end

      # 5.3.6. Parse a declaration
      # https://www.w3.org/TR/css-syntax-3/#parse-declaration
      def parse_declaration
        # 1.
        tokens = tokenize

        # 2.
        loop do
          case tokens.peek
          in CommentToken | WhitespaceToken
            tokens.next
          else
            break
          end
        end

        # 3.
        case tokens.peek
        in IdentToken
          # do nothing
        in EOFToken
          return ParseError.new("Unexpected end of input parsing declaration")
        else
          return ParseError.new("Expected an identifier at #{tokens.peek.location.start_char}")
        end

        # 4.
        if (declaration = consume_declaration(tokens))
          declaration
        else
          ParseError.new("Expected a declaration at #{tokens.peek.location.start_char}")
        end
      end

      # 5.3.8. Parse a list of declarations
      # https://www.w3.org/TR/css-syntax-3/#parse-list-of-declarations
      def parse_declaration_list
        consume_declaration_list(tokenize)
      end

      # 5.3.9. Parse a component value
      # https://www.w3.org/TR/css-syntax-3/#parse-component-value
      def parse_component_value
        # 1.
        tokens = tokenize

        # 2.
        loop do
          case tokens.peek
          in CommentToken | WhitespaceToken
            tokens.next
          else
            break
          end
        end

        # 3.
        if tokens.peek.is_a?(EOFToken)
          return ParseError.new("Unexpected end of input parsing component value")
        end

        # 4.
        value = consume_component_value(tokens)

        # 5.
        loop do
          case tokens.peek
          in CommentToken | WhitespaceToken
            tokens.next
          else
            break
          end
        end

        # 6.
        if tokens.peek.is_a?(EOFToken)
          value
        else
          ParseError.new("Expected end of input parsing component value")
        end
      end

      # 5.3.10. Parse a list of component values
      # https://www.w3.org/TR/css-syntax-3/#parse-list-of-component-values
      def parse_component_values
        tokens = tokenize
        values = []

        values << consume_component_value(tokens) until tokens.peek.is_a?(EOFToken)
        values
      end

      private

      #-------------------------------------------------------------------------
      # 3. Tokenizing and Parsing CSS
      # https://www.w3.org/TR/css-syntax-3/#tokenizing-and-parsing
      #-------------------------------------------------------------------------

      # 3.3. Preprocessing the input stream
      # https://www.w3.org/TR/css-syntax-3/#input-preprocessing
      def preprocess(input)
        input.gsub(/\r\n?|\f/, "\n").gsub(/\x00/, "\u{FFFD}")

        # We should also be replacing surrogate characters in the input stream
        # with the replacement character, but it's not entirely possible to do
        # that if the string is already UTF-8 encoded. Until we dive further
        # into encoding and handle fallback encodings, we'll just skip this.
        # .gsub(/[\u{D800}-\u{DFFF}]/, "\u{FFFD}")
      end

      #-------------------------------------------------------------------------
      # 4. Tokenization
      # https://www.w3.org/TR/css-syntax-3/#tokenization
      #-------------------------------------------------------------------------

      # Create an enumerator of tokens from the source.
      def tokenize
        Enumerator.new do |enum|
          index = 0

          while index < source.length
            state = consume_token(index)

            enum << state.value
            index = state.index
          end

          enum << EOFToken[index]
        end
      end

      # 4.3.1. Consume a token
      # https://www.w3.org/TR/css-syntax-3/#consume-token
      def consume_token(index)
        case source[index..]
        when %r{\A/\*}
          consume_comment(index)
        when /\A#{WHITESPACE}+/o
          State.new(WhitespaceToken.new(value: $&, location: index...(index + $&.length)), index + $&.length)
        when /\A["']/
          consume_string(index, $&)
        when /\A#/
          if ident?(source[index + 1]) || valid_escape?(source[index + 1], source[index + 2])
            state = consume_ident_sequence(index + 1)

            State.new(
              HashToken.new(
                value: state.value,
                type: start_ident_sequence?(index + 1) ? "id" : "unrestricted",
                location: index...state.index
              ),
              state.index
            )
          else
            State.new(DelimToken.new(value: "#", location: index...(index + 1)), index + 1)
          end
        when /\A\(/
          State.new(OpenParenToken.new(location: index...(index + 1)), index + 1)
        when /\A\)/
          State.new(CloseParenToken.new(location: index...(index + 1)), index + 1)
        when /\A\+/
          if start_number?(index + 1)
            consume_numeric(index)
          else
            State.new(DelimToken.new(value: "+", location: index...(index + 1)), index + 1)
          end
        when /\A,/
          State.new(CommaToken.new(location: index...(index + 1)), index + 1)
        when /\A-/
          if start_number?(index)
            consume_numeric(index)
          elsif source[index + 1] == "-" && source[index + 2] == ">"
            State.new(CDCToken.new(location: index...(index + 3)), index + 3)
          elsif start_ident_sequence?(index)
            consume_ident_like(index)
          else
            State.new(DelimToken.new(value: "-", location: index...(index + 1)), index + 1)
          end
        when /\A\./
          if start_number?(index)
            consume_numeric(index)
          else
            State.new(DelimToken.new(value: ".", location: index...(index + 1)), index + 1)
          end
        when /\A:/
          State.new(ColonToken.new(location: index...(index + 1)), index + 1)
        when /\A;/
          State.new(SemicolonToken.new(location: index...(index + 1)), index + 1)
        when /\A</
          if source[index...(index + 4)] == "<!--"
            State.new(CDOToken.new(location: index...(index + 4)), index + 4)
          else
            State.new(DelimToken.new(value: "<", location: index...(index + 1)), index + 1)
          end
        when /\A@/
          if start_ident_sequence?(index + 1)
            state = consume_ident_sequence(index + 1)
            State.new(AtKeywordToken.new(value: state.value, location: index...state.index), state.index)
          else
            State.new(DelimToken.new(value: "@", location: index...(index + 1)), index + 1)
          end
        when /\A\[/
          State.new(OpenSquareToken.new(location: index...(index + 1)), index + 1)
        when %r{\A\\}
          if valid_escape?(source[index], source[index + 1])
            consume_ident_like(index)
          else
            errors << ParseError.new("invalid escape at #{index}")
            State.new(DelimToken.new(value: "\\", location: index...(index + 1)), index + 1)
          end
        when /\A\]/
          State.new(CloseSquareToken.new(location: index...(index + 1)), index + 1)
        when /\A\{/
          State.new(OpenCurlyToken.new(location: index...(index + 1)), index + 1)
        when /\A\}/
          State.new(CloseCurlyToken.new(location: index...(index + 1)), index + 1)
        when /\A#{DIGIT}/o
          consume_numeric(index)
        when /\A#{IDENT_START}/o
          consume_ident_like(index)
        when "", nil
          State.new(EOFToken[index], index)
        else
          State.new(DelimToken.new(value: source[index], location: index...(index + 1)), index + 1)
        end
      end

      # 4.3.2. Consume comments
      # https://www.w3.org/TR/css-syntax-3/#consume-comments
      def consume_comment(index)
        ending = source.index("*/", index + 2)

        if ending.nil?
          errors << ParseError.new("unterminated comment starting at #{index}")
          location = index...source.length
          State.new(CommentToken.new(value: source[location], location: location), source.length)
        else
          location = index...(ending + 2)
          State.new(CommentToken.new(value: source[location], location: location), ending + 2)
        end
      end

      # 4.3.3. Consume a numeric token
      # https://www.w3.org/TR/css-syntax-3/#consume-numeric-token
      def consume_numeric(index)
        start = index
        state = consume_number(index)

        value, type = state.value
        index = state.index

        if start_ident_sequence?(index)
          state = consume_ident_sequence(index)
          State.new(DimensionToken.new(value: value, unit: state.value, type: type, location: start...index), state.index)
        elsif source[index] == "%"
          index += 1
          State.new(PercentageToken.new(value: value, type: type, location: start...index), index)
        else
          State.new(NumberToken.new(value: value, type: type, location: start...index), index)
        end
      end

      # 4.3.4. Consume an ident-like token
      # https://www.w3.org/TR/css-syntax-3/#consume-ident-like-token
      def consume_ident_like(index)
        start = index
        state = consume_ident_sequence(index)

        index = state.index
        string = state.value

        if (string.casecmp("url") == 0) && (source[index] == "(")
          index += 1 # (

          # While the next two input code points are whitespace, consume the
          # next input code point.
          while whitespace?(source[index]) && whitespace?(source[index + 1])
            index += 1
          end

          if /["']/.match?(source[index]) || (whitespace?(source[index]) && /["']/.match?(source[index + 1]))
            State.new(FunctionToken.new(value: string, location: start...index), index)
          else
            consume_url(start)
          end
        elsif source[index] == "("
          index += 1
          State.new(FunctionToken.new(value: string, location: start...index), index)
        elsif (string.casecmp("u") == 0) && (state = consume_urange(index - 1))
          state
        else
          State.new(IdentToken.new(value: string, location: start...index), index)
        end
      end

      # 4.3.5. Consume a string token
      # https://www.w3.org/TR/css-syntax-3/#consume-string-token
      def consume_string(index, quote)
        start = index
        index += 1
        value = +""

        while index <= source.length
          case source[index]
          when quote
            return State.new(StringToken.new(value: value, location: start...(index + 1)), index + 1)
          when nil
            errors << ParseError.new("unterminated string at #{start}")
            return State.new(StringToken.new(value: value, location: start...index), index)
          when "\n"
            errors << ParseError.new("newline in string at #{index}")
            return State.new(BadStringToken.new(value: value, location: start...index), index)
          when "\\"
            index += 1

            if index == source.length
              next
            elsif source[index] == "\n"
              value << source[index]
              index += 1
            else
              state = consume_escaped_code_point(index)
              value << state.value
              index = state.index
            end
          else
            value << source[index]
            index += 1
          end
        end
      end

      # 4.3.6. Consume a url token
      # https://www.w3.org/TR/css-syntax-3/#consume-url-token
      def consume_url(index)
        # 1.
        value = +""

        # 2.
        start = index
        index += 4 # url(
        index += 1 while whitespace?(source[index])

        # 3.
        while index <= source.length
          case source[index..]
          when /\A\)/
            return State.new(URLToken.new(value: value, location: start...(index + 1)), index + 1)
          when "", nil
            errors << ParseError.new("unterminated url at #{start}")
            return State.new(URLToken.new(value: value, location: start...index), index)
          when /\A#{WHITESPACE}+/o
            index += $&.length

            case source[index]
            when ")"
              return State.new(URLToken.new(value: value, location: start...(index + 1)), index + 1)
            when nil
              errors << ParseError.new("unterminated url at #{start}")
              return State.new(URLToken.new(value: value, location: start...index), index)
            else
              errors << ParseError.new("invalid url at #{start}")
              state = consume_bad_url_remnants(index)
              return State.new(BadURLToken.new(value: value + state.value, location: start...state.index), state.index)
            end
          when /\A["'(]|#{NON_PRINTABLE}/o
            errors << ParseError.new("invalid character in url at #{index}")
            state = consume_bad_url_remnants(index)
            return State.new(BadURLToken.new(value: value + state.value, location: start...state.index), state.index)
          when %r{\A\\}
            if valid_escape?(source[index], source[index + 1])
              state = consume_escaped_code_point(index + 1)
              value << state.value
              index = state.index
            else
              errors << ParseError.new("invalid escape at #{index}")
              state = consume_bad_url_remnants(index)
              return State.new(BadURLToken.new(value: value + state.value, location: start...state.index), state.index)
            end
          else
            value << source[index]
            index += 1
          end
        end
      end

      # 4.3.7. Consume an escaped code point
      # https://www.w3.org/TR/css-syntax-3/#consume-escaped-code-point
      def consume_escaped_code_point(index)
        replacement = "\u{FFFD}"

        if /\A(\h{1,6})#{WHITESPACE}?/o =~ source[index..]
          ord = $1.to_i(16)

          if ord == 0 || (0xD800..0xDFFF).cover?(ord) || ord > 0x10FFFF
            State.new(replacement, index + $&.length)
          else
            State.new(ord.chr(Encoding::UTF_8), index + $&.length)
          end
        elsif index == source.length
          State.new(replacement, index)
        else
          State.new(source[index], index + 1)
        end
      end

      # 4.3.8. Check if two code points are a valid escape
      # https://www.w3.org/TR/css-syntax-3/#starts-with-a-valid-escape
      def valid_escape?(left, right)
        (left == "\\") && (right != "\n")
      end

      # 4.3.9. Check if three code points would start an ident sequence
      # https://www.w3.org/TR/css-syntax-3/#would-start-an-identifier
      def start_ident_sequence?(index)
        first, second, third = source[index...(index + 3)].chars

        case first
        when "-"
          (/#{IDENT_START}/o.match?(second) || (second == "-")) ||
            valid_escape?(second, third)
        when /#{IDENT_START}/o
          true
        when "\\"
          valid_escape?(first, second)
        else
          false
        end
      end

      # 4.3.10. Check if three code points would start a number
      # https://www.w3.org/TR/css-syntax-3/#starts-with-a-number
      def start_number?(index)
        first, second, third = source[index...(index + 3)].chars

        case first
        when "+", "-"
          digit?(second) || (second == "." && digit?(third))
        when "."
          digit?(second)
        when /#{DIGIT}/o
          true
        else
          false
        end
      end

      # 4.3.11. Consume an ident sequence
      # https://www.w3.org/TR/css-syntax-3/#consume-an-ident-sequence
      def consume_ident_sequence(index)
        result = +""

        while index <= source.length
          if ident?(source[index])
            result << source[index]
            index += 1
          elsif valid_escape?(source[index], source[index + 1])
            state = consume_escaped_code_point(index + 1)
            result << state.value
            index = state.index
          else
            return State.new(result, index)
          end
        end
      end

      # 4.3.12. Consume a number
      # https://www.w3.org/TR/css-syntax-3/#consume-a-number
      def consume_number(index)
        # 1.
        repr = +""
        type = "integer"

        # 2.
        if /[+-]/.match?(source[index])
          repr << source[index]
          index += 1
        end

        # 3.
        while digit?(source[index])
          repr << source[index]
          index += 1
        end

        # 4.
        if source[index] == "." && digit?(source[index + 1])
          repr += source[index..(index + 1)]
          index += 2
          type = "number"

          while digit?(source[index])
            repr << source[index]
            index += 1
          end
        end

        # 5.
        if /\A[Ee][+-]?#{DIGIT}+/o =~ source[index..]
          repr += $&
          index += $&.length
          type = "number"
        end

        # 6., 7.
        State.new([convert_to_number(repr), type], index)
      end

      # 4.3.13. Convert a string to a number
      # https://www.w3.org/TR/css-syntax-3/#convert-a-string-to-a-number
      def convert_to_number(value)
        pattern = %r{
          \A
          (?<sign>[+-]?)
          (?<integer>#{DIGIT}*)
          (?<decimal>\.?)
          (?<fractional>#{DIGIT}*)
          (?<exponent_indicator>[Ee]?)
          (?<exponent_sign>[+-]?)
          (?<exponent>#{DIGIT}*)
          \z
        }ox

        if (match = pattern.match(value))
          s = match[:sign] == "-" ? -1 : 1
          i = match[:integer].to_i
          f = 0
          d = 0

          unless match[:fractional].empty?
            f = match[:fractional].to_i
            d = match[:fractional].length
          end

          t = match[:exponent_sign] == "-" ? -1 : 1
          e = match[:exponent].to_i

          s * (i + f * 10**(-d)) * 10**(t * e)
        else
          raise ParseError, "convert_to_number called with invalid value: #{value}"
        end
      end

      # 4.3.14. Consume the remnants of a bad url
      # https://www.w3.org/TR/css-syntax-3/#consume-remnants-of-bad-url
      def consume_bad_url_remnants(index)
        value = +""

        while index <= source.length
          case source[index..]
          when "", nil
            return State.new(value, index)
          when /\A\)/
            value << ")"
            return State.new(value, index + 1)
          else
            if valid_escape?(source[index], source[index + 1])
              state = consume_escaped_code_point(index)
              value << state.value
              index = state.index
            else
              value << source[index]
              index += 1
            end
          end
        end
      end

      # https://www.w3.org/TR/css-syntax-3/#digit
      def digit?(value)
        /#{DIGIT}/o.match?(value)
      end

      # https://www.w3.org/TR/css-syntax-3/#ident-code-point
      def ident?(value)
        /#{IDENT}/o.match?(value)
      end

      # https://www.w3.org/TR/css-syntax-3/#whitespace
      def whitespace?(value)
        /#{WHITESPACE}/o.match?(value)
      end

      #-------------------------------------------------------------------------
      # 5. Parsing
      # https://www.w3.org/TR/css-syntax-3/#parsing
      #-------------------------------------------------------------------------

      # 5.4.1. Consume a list of rules
      # https://www.w3.org/TR/css-syntax-3/#consume-list-of-rules
      def consume_rule_list(tokens, top_level: true)
        rules = []

        loop do
          case tokens.peek
          in CommentToken | WhitespaceToken
            tokens.next
          in EOFToken
            return rules
          in CDCToken | CDOToken
            if top_level
              tokens.next
            else
              rule = consume_qualified_rule(tokens)
              rules << rule if rule
            end
          in AtKeywordToken
            rules << consume_at_rule(tokens)
          else
            rule = consume_qualified_rule(tokens)
            rules << rule if rule
          end
        end
      end

      # 5.4.2. Consume an at-rule
      # https://www.w3.org/TR/css-syntax-3/#consume-at-rule
      def consume_at_rule(tokens)
        name_token = tokens.next
        prelude = []
        block = nil

        loop do
          case tokens.peek
          in SemicolonToken[location:]
            tokens.next
            return AtRule.new(name: name_token.value, prelude: prelude, block: block, location: name_token.location.to(location))
          in EOFToken[location:]
            errors << ParseError.new("Unexpected EOF while parsing at-rule")
            return AtRule.new(name: name_token.value, prelude: prelude, block: block, location: name_token.location.to(location))
          in OpenCurlyToken
            block = consume_simple_block(tokens)
            return AtRule.new(name: name_token.value, prelude: prelude, block: block, location: name_token.location.to(block.location))
          else
            prelude << consume_component_value(tokens)
          end
        end
      end

      # 5.4.3. Consume a qualified rule
      # https://www.w3.org/TR/css-syntax-3/#consume-qualified-rule
      def consume_qualified_rule(tokens)
        prelude = []
        block = nil

        loop do
          case tokens.peek
          in EOFToken
            errors << ParseError.new("Unexpected EOF while parsing qualified rule")
            return nil
          in OpenCurlyToken
            block = consume_simple_block(tokens)
            location = prelude.any? ? prelude.first.location.to(block.location) : block.location
            return QualifiedRule.new(prelude: prelude, block: block, location: location)
          else
            prelude << consume_component_value(tokens)
          end
        end
      end

      # 5.4.4. Consume a style block’s contents
      # https://www.w3.org/TR/css-syntax-3/#consume-style-block
      def consume_style_block_contents(tokens)
        declarations = []
        rules = []

        loop do
          case tokens.peek
          in SemicolonToken | WhitespaceToken
            tokens.next
          in EOFToken
            tokens.next
            return declarations + rules
          in AtKeywordToken
            rules << consume_at_rule(tokens)
          in IdentToken
            list = [tokens.next]

            loop do
              case tokens.peek
              in EOFToken
                list << tokens.next
                break
              in SemicolonToken
                list << tokens.next
                list << EOFToken[list.last.location.end_char]
                break
              else
                list << consume_component_value(tokens)
              end
            end

            declaration = consume_declaration(list.to_enum)
            declarations << declaration if declaration
          in DelimToken[value: "&"]
            rule = consume_qualified_rule(tokens)
            rules << rule if rule
          in { location: }
            errors << ParseError.new("Unexpected token while parsing style block at #{location.start_char}")

            until %i[semicolon EOF].include?(tokens.peek.type)
              consume_component_value(tokens)
            end
          end
        end
      end

      # 5.4.5. Consume a list of declarations
      # https://www.w3.org/TR/css-syntax-3/#consume-list-of-declarations
      def consume_declaration_list(tokens)
        declarations = []

        loop do
          case tokens.peek
          in SemicolonToken | WhitespaceToken
            tokens.next
          in EOFToken
            tokens.next
            return declarations
          in AtKeywordToken
            declarations << consume_at_rule(tokens)
          in IdentToken
            list = [tokens.next]

            loop do
              case tokens.peek
              in EOFToken | SemicolonToken
                break
              else
                list << consume_component_value(tokens)
              end
            end

            if tokens.peek.is_a?(EOFToken)
              list << tokens.next

              declaration = consume_declaration(list.to_enum)
              declarations << declaration if declaration

              return declarations
            else
              tokens.next
              list << EOFToken[list.last.location.end_char]
  
              declaration = consume_declaration(list.to_enum)
              declarations << declaration if declaration  
            end
          else
            errors << ParseError.new("Unexpected token while parsing declaration list at #{tokens.peek.location.start_char}")

            loop do
              case tokens.peek
              in EOFToken | SemicolonToken
                break
              else
                consume_component_value(tokens)
              end
            end
          end
        end
      end

      # 5.4.6. Consume a declaration
      # https://www.w3.org/TR/css-syntax-3/#consume-declaration
      def consume_declaration(tokens)
        name = tokens.next
        value = []
        important = false

        # 1.
        loop do
          case tokens.peek
          in CommentToken | WhitespaceToken
            tokens.next
          else
            break
          end
        end

        # 2.
        case tokens.peek
        in ColonToken
          tokens.next
        else
          errors << ParseError.new("Expected colon at #{tokens.peek.location.start_char}")
          return
        end

        # 3.
        loop do
          case tokens.peek
          in CommentToken | WhitespaceToken
            tokens.next
          else
            break
          end
        end

        # 4.
        value << consume_component_value(tokens) until tokens.peek.is_a?(EOFToken)

        # 5.
        case value.reject { |token| token.is_a?(WhitespaceToken) || token.is_a?(CommentToken) }[-2..]
        in [DelimToken[value: "!"] => first, IdentToken[value: /\Aimportant\z/i] => second]
          value.delete(first)
          value.delete(second)
          important = true
        else
        end

        # 6.
        loop do
          case value[-1]
          in CommentToken | WhitespaceToken
            value.pop
          else
            break
          end
        end

        # 7.
        location = name.location
        location = location.to(value.last.location) if value.any?
        Declaration.new(name: name.value, value: value, important: important, location: location)
      end

      # 5.4.7. Consume a component value
      # https://www.w3.org/TR/css-syntax-3/#consume-component-value
      def consume_component_value(tokens)
        case tokens.peek
        in OpenCurlyToken | OpenSquareToken | OpenParenToken
          consume_simple_block(tokens)
        in FunctionToken
          consume_function(tokens)
        else
          tokens.next
        end
      end

      # 5.4.8. Consume a simple block
      # https://www.w3.org/TR/css-syntax-3/#consume-simple-block
      def consume_simple_block(tokens)
        token = tokens.next
        ending = {
          OpenParenToken => CloseParenToken,
          OpenSquareToken => CloseSquareToken,
          OpenCurlyToken => CloseCurlyToken
        }[token.class]

        value = []

        loop do
          case tokens.peek
          when ending
            location = token.location.to(tokens.next.location)
            return SimpleBlock.new(token: token.value, value: value, location: location)
          when EOFToken
            errors << ParseError.new("Unexpected EOF while parsing simple block at #{token.location.start_char}")
            return SimpleBlock.new(token: token.value, value: value, location: token.location.to(tokens.peek.location))
          else
            value << consume_component_value(tokens)
          end
        end
      end

      # 5.4.9. Consume a function
      # https://www.w3.org/TR/css-syntax-3/#consume-function
      def consume_function(tokens)
        name_token = tokens.next
        value = []

        loop do
          case tokens.peek
          in CloseParenToken[location:]
            tokens.next
            return Function.new(name: name_token.value, value: value, location: name_token.location.to(location))
          in EOFToken[location:]
            errors << ParseError.new("Unexpected EOF while parsing function at #{name_token.location.start_char}")
            return Function.new(name: name_token.value, value: value, location: name_token.location.to(location))
          else
            value << consume_component_value(tokens)
          end
        end
      end

      #-------------------------------------------------------------------------
      # 7. The Unicode-Range microsyntax
      # https://www.w3.org/TR/css-syntax-3/#urange
      #-------------------------------------------------------------------------

      # 7.1. The <urange> type
      # https://www.w3.org/TR/css-syntax-3/#urange-syntax
      def consume_urange(index)
        start = index
        index += 1 # to move past the "u"

        # At this point we've already consumed the "u". We need to gather up a
        # couple of component values to see if it matches the grammar first,
        # before we concatenate all of the representations together.
        #
        # To do this, we're going to build a little state machine. It's going to
        # walk through with each input. If we receive an input for which there
        # isn't a transition from the current state and the current state is not
        # a final state, then we exit. Otherwise if it is a final state, we
        # attempt to parse a urange token from the concatenation of the values
        # of the tokens.
        #
        #     ┌───┐          ┌───┐ ── ? ──────> ┌───┐ ──┐
        # ──> │ 1 │ ── + ──> │ 2 │ ── ident ──> │|3|│   ?
        #     └───┘          └───┘        ┌───> └───┘ <─┘
        #      ││                         │
        #      │└─── dimension ───────────┘
        #      └──── number ─────> ┌───┐          ┌───┐ ──┐
        #       ┌─── dimension ─── │|4|│ ── ? ──> │|5|│   ?
        #       │     ┌── number ─ └───┘          └───┘ <─┘
        #       V     V
        #     ┌───┐ ┌───┐
        #     │|6|│ │|7|│
        #     └───┘ └───┘
        #
        tokens = []
        box = 1

        loop do
          state = consume_token(index)
          box =
            case [box, state.value]
            in [1, DelimToken[value: "+"]] then 2
            in [1, DimensionToken]         then 3
            in [1, NumberToken]            then 4
            in [2, DelimToken[value: "?"]] then 3
            in [2, IdentToken]             then 3
            in [3, DelimToken[value: "?"]] then 3
            in [4, DelimToken[value: "?"]] then 5
            in [4, DimensionToken]         then 6
            in [4, NumberToken]            then 7
            in [5, DelimToken[value: "?"]] then 5
            else
              if [3, 4, 5, 6, 7].include?(box)
                break # final states
              else
                return
              end
            end

          tokens << state.value
          index = state.index
        end

        # 2.
        text = "u" + tokens.map { |token| source[token.location.to_range] }.join
        return if text[1] != "+"
        index = 2

        # 3.
        match = text[index..].match(/\A\h*\?*/)
        return unless match

        value = match[0]
        return unless (1..6).cover?(value.length)

        index += value.length
        start_value, end_value =
          if value.end_with?("?")
            return if index != text.length
            [value.gsub("?", "0").hex, value.gsub("?", "F").hex]
          else
            [value.hex, value.hex]
          end

        # 4.
        if index == text.length
          return unless valid_urange?(start_value, end_value)

          ending = start + text.length
          return State.new(URange.new(start_value: start_value, end_value: end_value, location: start...ending), ending)
        end

        # 5.
        return if text[index] != "-"
        index += 1

        # 6.
        match = text[index..].match(/\A\h*/)
        return if !match || match[0].length > 6

        end_value = match[0].hex
        index += match[0].length
        return if index != text.length

        # 7.
        return unless valid_urange?(start_value, end_value)

        ending = start + text.length
        State.new(URange.new(start_value: start_value, end_value: end_value, location: start...ending), ending)
      end

      # Checks that the start and end value of a urange are valid.
      def valid_urange?(start_value, end_value)
        if end_value > 0x10FFFF
          errors << ParseError.new("Invalid urange. #{end_value} greater than 0x10FFFF")
          false
        elsif start_value > end_value
          errors << ParseError.new("Invalid urange. #{start_value} greater than #{end_value}")
          false
        else
          true
        end
      end

      #-------------------------------------------------------------------------
      # 9. CSS stylesheets
      # https://www.w3.org/TR/css-syntax-3/#css-stylesheets
      #-------------------------------------------------------------------------

      # https://www.w3.org/TR/css-syntax-3/#parse-a-css-stylesheet
      def parse_css_stylesheet
        stylesheet = parse_stylesheet
        rules =
          stylesheet.rules.map do |rule|
            rule.is_a?(QualifiedRule) ? create_style_rule(rule) : rule
          end

        CSSStyleSheet.new(rules: rules, location: stylesheet.location)
      end

      # 9.1. Style rules
      # https://www.w3.org/TR/css-syntax-3/#style-rules
      def create_style_rule(rule)
        slct_tokens = [*rule.prelude, EOFToken[rule.location.end_char]]
        decl_tokens = [*rule.block.value, EOFToken[rule.location.end_char]]

        StyleRule.new(
          selectors: Selectors.new(slct_tokens).parse,
          declarations: consume_style_block_contents(decl_tokens.to_enum),
          location: rule.location
        )
      end
    end
  end
end
