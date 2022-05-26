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
        rules = consume_list_of_rules(tokens, top_level: true)

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
      def parse_list_of_rules(tokens)
        consume_list_of_rules(tokens, top_level: false)
      end

      private

      #-------------------------------------------------------------------------
      # 3. Tokenizing and Parsing CSS
      # https://www.w3.org/TR/css-syntax-3/#tokenizing-and-parsing
      #-------------------------------------------------------------------------

      # 3.3. Preprocessing the input stream
      # https://www.w3.org/TR/css-syntax-3/#input-preprocessing
      def preprocess(input)
        input.gsub(/\r\n?|\f/, "\n")
        # .gsub(/\x00|[\u{D800}-\u{DFFF}]/, "\u{FFFD}")
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

          enum << Token.eof(index)
        end
      end

      # 4.3.1. Consume a token
      # https://www.w3.org/TR/css-syntax-3/#consume-token
      def consume_token(index)
        case source[index..]
        when %r{\A/\*}
          consume_comment(index)
        when /\A#{WHITESPACE}+/o
          State.new(Token.new(:whitespace, $&, index...(index + $&.length)), index + $&.length)
        when /\A[\(\)\[\]{}]/
          State.new(Token.new($&.to_sym, $&, index...(index + 1)), index + 1)
        when /\A["']/
          consume_string(index, $&)
        when /\A#/
          if ident?(source[index + 1]) || valid_escape?(source[index + 1], source[index + 2])
            state = consume_ident_sequence(index + 1)

            State.new(
              Token.new(
                :hash,
                state.value,
                index...state.index,
                type: start_ident_sequence?(index + 1) ? "id" : nil
              ),
              state.index
            )
          else
            State.new(Token.new(:delim, $&, index...(index + 1)), index + 1)
          end
        when /\A\+/
          if start_number?(index + 1)
            consume_numeric(index)
          else
            State.new(Token.new(:delim, $&, index...(index + 1)), index + 1)
          end
        when /\A,/
          State.new(Token.new(:comma, $&, index...(index + 1)), index + 1)
        when /\A-/
          if start_number?(index)
            consume_numeric(index)
          elsif source[index + 1] == "-" && source[index + 2] == ">"
            State.new(Token.new(:CDC, "-->", index...(index + 3)), index + 3)
          elsif start_ident_sequence?(index)
            consume_ident_like(index)
          else
            State.new(Token.new(:delim, $&, index...(index + 1)), index + 1)
          end
        when /\A\./
          if start_number?(index)
            consume_numeric(index)
          else
            State.new(Token.new(:delim, $&, index...(index + 1)), index + 1)
          end
        when /\A:/
          State.new(Token.new(:colon, $&, index...(index + 1)), index + 1)
        when /\A;/
          State.new(Token.new(:semicolon, $&, index...(index + 1)), index + 1)
        when /\A</
          if source[index...(index + 4)] == "<!--"
            State.new(Token.new(:CDO, "<!--", index...(index + 4)), index + 4)
          else
            State.new(Token.new(:delim, $&, index...(index + 1)), index + 1)
          end
        when /\A@/
          if start_ident_sequence?(index + 1)
            state = consume_ident_sequence(index + 1)
            State.new(Token.new(:at_keyword, state.value, index...state.index), state.index)
          else
            State.new(Token.new(:delim, $&, index...(index + 1)), index + 1)
          end
        when %r{\A\\}
          if valid_escape?(source[index], source[index + 1])
            consume_ident_like(index)
          else
            errors << ParseError.new("invalid escape at #{index}")
            State.new(Token.new(:delim, $&, index...(index + 1)), index + 1)
          end
        when /\A#{DIGIT}/o
          consume_numeric(index)
        when /\A#{IDENT_START}/o
          consume_ident_like(index)
        when nil
          State.new(Token.eof(index), index)
        else
          State.new(Token.new(:delim, $&, index...(index + 1)), index + 1)
        end
      end

      # 4.3.2. Consume comments
      # https://www.w3.org/TR/css-syntax-3/#consume-comments
      def consume_comment(index)
        ending = source.index("*/", index + 2)

        if ending.nil?
          errors << ParseError.new("unterminated comment starting at #{index}")
          State.new(Token.new(:comment, source[index..], index...source.length), source.length)
        else
          location = index...(ending + 2)
          State.new(Token.new(:comment, source[location], location), ending + 2)
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
          token = Token.new(:dimension, value, start...index, type: type)
          state = consume_ident_sequence(index)

          token.flags[:unit] = state.value
          State.new(token, state.index)
        elsif source[index] == "%"
          index += 1
          State.new(Token.new(:percentage, value, start...index, type: type), index)
        else
          State.new(Token.new(:number, value, start...index, type: type), index)
        end
      end

      # 4.3.4. Consume an ident-like token
      # https://www.w3.org/TR/css-syntax-3/#consume-ident-like-token
      def consume_ident_like(index)
        start = index
        state = consume_ident_sequence(index)

        index = state.index
        string = state.value

        if string.casecmp("url") == 0 && source[index] == "("
          index += 1 while whitespace?(source[index])

          if /["']/.match?(source[index])
            State.new(Token.new(:function, string, start...index), index)
          else
            consume_url(start)
          end
        elsif source[index] == "("
          index += 1
          State.new(Token.new(:function, string, start...index), index)
        else
          State.new(Token.new(:ident, string, start...index), index)
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
            return State.new(Token.new(:string, value, start...(index + 1)), index + 1)
          when nil
            errors << ParseError.new("unterminated string at #{start}")
            return State.new(Token.new(:string, value, start...index), index)
          when "\n"
            errors << ParseError.new("newline in string at #{index}")
            return State.new(Token.new(:bad_string, value, start...index), index)
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
        value +""

        # 2.
        start = index
        index += 4 # url(
        index += 1 while whitespace?(source[index])

        # 3.
        while index <= source.length
          case source[index..]
          when /\A\)/
            return State.new(Token.new(:url, value, start...(index + 1)), index + 1)
          when nil
            errors << ParseError.new("unterminated url at #{start}")
            return State.new(Token.new(:url, value, start...index), index)
          when /\A#{WHITESPACE}+/o
            index += $&.length

            case source[index]
            when ")"
              return State.new(Token.new(:url, value, start...(index + 1)), index + 1)
            when nil
              errors << ParseError.new("unterminated url at #{start}")
              return State.new(Token.new(:url, value, start...index), index)
            else
              errors << ParseError.new("invalid url at #{start}")
              state = consume_bad_url_remnants(index)
              return State.new(Token.new(:bad_url, value + state.value, start...state.index), state.index)
            end
          when /\A["'(]|#{NON_PRINTABLE}/o
            errors << ParseError.new("invalid character in url at #{index}")
            state = consume_bad_url_remnants(index)
            return State.new(Token.new(:bad_url, value + state.value, start...state.index), state.index)
          when %r{\A\\}
            if valid_escape?(source[index], source[index + 1])
              state = consume_escaped_code_point(index)
              value << state.value
              index = state.index
            else
              errors << ParseError.new("invalid escape at #{index}")
              state = consume_bad_url_remnants(index)
              return State.new(Token.new(:bad_url, value + state.value, start...state.index), state.index)
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
        first, second, third = source[index...(index + 3)]

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
        first, second, third = source[index...(index + 3)]

        case first
        when /[+-]/
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
          when nil
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
      def consume_list_of_rules(tokens, top_level: true)
        rules = []

        loop do
          case tokens.peek
          in { type: :whitespace }
            tokens.next
          in { type: :EOF }
            return rules
          in { type: :CDO | :CDC }
            unless top_level
              rule = consume_qualified_rule(tokens)
              rules << rule if rule
            end
          in { type: :at_keyword }
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
          in { type: :semicolon, location: }
            return AtRule.new(name: name_token.value, prelude: prelude, block: block, location: name_token.location.to(location))
          in { type: :EOF, location: }
            errors << ParseError.new("Unexpected EOF while parsing at-rule")
            return AtRule.new(name: name_token.value, prelude: prelude, block: block, location: name_token.location.to(location))
          in { type: :"(" }
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
          in { type: :EOF }
            return nil
          in { type: :"{" }
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
          in { type: :whitespace | :semicolon }
            tokens.next
          in { type: :EOF }
            tokens.next
            return declarations + rules
          in { type: :at_keyword }
            rules << consume_at_rule(tokens)
          in { type: :ident }
            list = [tokens.next]

            loop do
              case tokens.peek
              in { type: :semicolon | :EOF }
                list << tokens.next
                list << Token.eof(list.last.location.end_char) if list.last.type != :EOF
                break
              else
                list << consume_component_value(tokens)
              end
            end

            declaration = consume_declaration(list.to_enum)
            declarations << declaration if declaration
          in { type: :delim, value: "&" }
            rule = consume_qualified_rule(tokens)
            rules << rule if rule
          in { location: }
            errors << ParseError.new("Unexpected token while parsing style block at #{locations.start_char}")

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
          in { type: :whitespace | :semicolon }
            # do nothing
          in { type: :EOF }
            return declarations
          in { type: :at_keyword }
            declarations << consume_at_rule(tokens)
          in { type: :ident }
            list = [tokens.next]
            until %i[semicolon EOF].include?(tokens.peek.type)
              list << consume_component_value(tokens)
            end

            list << tokens.next
            list << Token.eof(list.last.location.end_char) if list.last.type != :EOF

            declaration = consume_declaration(list.to_enum)
            declarations << declaration if declaration
          else
            errors << ParseError.new("Unexpected token while parsing declaration list at #{tokens.peek.location.start_char}")

            until %i[semicolon EOF].include?(tokens.peek.type)
              consume_component_value(tokens)
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
          in { type: :whitespace }
            tokens.next
          else
            break
          end
        end

        # 2.
        if tokens.peek.type == :colon
          tokens.next
        else
          errors << ParseError.new("Expected colon at #{tokens.peek.location.start_char}")
          return
        end

        # 3.
        loop do
          case tokens.peek
          in { type: :whitespace }
            tokens.next
          else
            break
          end
        end

        # 4.
        loop do
          case tokens.peek
          in { type: :EOF }
            break
          else
            value << consume_component_value(tokens)
          end
        end

        # 5.
        case value.select { |token| token.is_a?(Token) && token.type != :whitespace }[-2..]
        in [{ type: :delim, value: "!" }, { type: :ident, value: /\Aimportant\z/i }]
          value.pop(2)
          important = true
        else
        end

        # 6.
        value.pop while value[-1].type == :whitespace

        # 7.
        Declaration.new(name: name.value, value: value, important: important, location: name.location.to(value.last.location))
      end

      # 5.4.7. Consume a component value
      # https://www.w3.org/TR/css-syntax-3/#consume-component-value
      def consume_component_value(tokens)
        case tokens.peek
        in { type: :"{" | :"[" | :"(" }
          consume_simple_block(tokens)
        in { type: :function }
          consume_function(tokens)
        else
          tokens.next
        end
      end

      # 5.4.8. Consume a simple block
      # https://www.w3.org/TR/css-syntax-3/#consume-simple-block
      def consume_simple_block(tokens)
        token = tokens.next
        ending = { "(": :")", "[": :"]", "{": :"}" }[token.type]
        value = []

        loop do
          peek = tokens.peek

          case peek.type
          when ending
            location = token.location.to(tokens.next.location)
            return SimpleBlock.new(token: token.value, value: value, location: location)
          when :EOF
            errors << ParseError.new("Unexpected EOF while parsing simple block at #{token.location.start_char}")
            return SimpleBlock.new(token: token.value, value: value, location: token.location.to(peek.location))
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
          in { type: :")", location: }
            return Function.new(name: name_token.value, value: value, location: name_token.location.to(location))
          in { type: :EOF, location: }
            errors << ParseError.new("Unexpected EOF while parsing function at #{name_token.location.start_char}")
            return Function.new(name: name_token.value, value: value, location: name_token.location.to(location))
          else
            value << consume_component_value(tokens)
          end
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
        slct_tokens = [*rule.prelude, Token.eof(rule.location.end_char)]
        decl_tokens = [*rule.block.value, Token.eof(rule.location.end_char)]

        StyleRule.new(
          selectors: Selectors.new(slct_tokens).parse,
          declarations: consume_style_block_contents(decl_tokens.to_enum),
          location: rule.location
        )
      end
    end
  end
end
