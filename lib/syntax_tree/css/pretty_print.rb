# frozen_string_literal: true

module SyntaxTree
  module CSS
    # A pretty-print visitor.
    class PrettyPrint < BasicVisitor
      attr_reader :q

      def initialize(q)
        @q = q
      end

      #-------------------------------------------------------------------------
      # CSS3 nodes
      #-------------------------------------------------------------------------

      # Visit an AtKeywordToken node.
      def visit_at_keyword_token(node)
        token("at-keyword-token") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit an AtRule node.
      def visit_at_rule(node)
        token("at-rule") do
          q.breakable
          q.pp(node.name)

          q.breakable
          q.text("(prelude")
          q.nest(2) do
            q.breakable("")
            q.seplist(node.prelude) { |token| q.pp(token) }
          end

          q.breakable("")
          q.text(")")

          q.breakable
          q.pp(node.block)
        end
      end

      # Visit a BadStringToken node.
      def visit_bad_string_token(node)
        token("bad-string-token") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a BadURLToken node.
      def visit_bad_url_token(node)
        token("bad-url-token") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a CDCToken node.
      def visit_cdc_token(node)
        token("cdc-token")
      end

      # Visit a CDOToken node.
      def visit_cdo_token(node)
        token("cdo-token")
      end

      # Visit a CloseCurlyToken node.
      def visit_close_curly_token(node)
        token("close-curly-token")
      end

      # Visit a CloseParenToken node.
      def visit_close_paren_token(node)
        token("close-paren-token")
      end

      # Visit a CloseSquareToken node.
      def visit_close_square_token(node)
        token("close-square-token")
      end

      # Visit a ColonToken node.
      def visit_colon_token(node)
        token("colon-token")
      end

      # Visit a CommentToken node.
      def visit_comment_token(node)
        token("comment-token") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a CommaToken node.
      def visit_comma_token(node)
        token("comma-token")
      end

      # Visit a CSSStyleSheet node.
      def visit_css_stylesheet(node)
        token("css-stylesheet") do
          if node.rules.any?
            q.breakable
            q.seplist(node.rules) { |rule| q.pp(rule) }
          end
        end
      end

      # Visit a Declaration node.
      def visit_declaration(node)
        token("declaration") do
          q.breakable
          q.text(node.name)

          if node.important?
            q.breakable
            q.text("!important")
          end

          q.breakable
          q.seplist(node.value) { |token| q.pp(token) }
        end
      end

      # Visit a DelimToken node.
      def visit_delim_token(node)
        token("delim-token") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a DimensionToken node.
      def visit_dimension_token(node)
        token("dimension-token") do
          q.breakable
          q.text(node.type)

          q.breakable
          q.pp(node.value)

          q.breakable
          q.text(node.unit)
        end
      end

      # Visit an EOFToken node.
      def visit_eof_token(node)
        token("eof-token")
      end

      # Visit a Function node.
      def visit_function(node)
        token("function") do
          q.breakable
          q.text(node.name)

          q.breakable
          q.text("(value")
          q.nest(2) do
            q.breakable
            q.seplist(node.value) { |token| q.pp(token) }
          end

          q.breakable("")
          q.text(")")
        end
      end

      # Visit a FunctionToken node.
      def visit_function_token(node)
        token("function-token") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit an IdentToken node.
      def visit_ident_token(node)
        token("ident-token") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a HashToken node.
      def visit_hash_token(node)
        token("hash-token") do
          q.breakable
          q.pp(node.value)

          q.breakable
          q.text(node.type)
        end
      end

      # Visit a NumberToken node.
      def visit_number_token(node)
        token("number-token") do
          q.breakable
          q.text(node.type)

          q.breakable
          q.pp(node.value)
        end
      end

      # Visit an OpenCurlyToken node.
      def visit_open_curly_token(node)
        token("open-curly-token")
      end

      # Visit an OpenParenToken node.
      def visit_open_paren_token(node)
        token("open-paren-token")
      end

      # Visit an OpenSquareToken node.
      def visit_open_square_token(node)
        token("open-square-token")
      end

      # Visit a PercentageToken node.
      def visit_percentage_token(node)
        token("percentage-token") do
          q.breakable
          q.text(node.type)

          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a QualifiedRule node.
      def visit_qualified_rule(node)
        token("qualified-rule") do
          q.breakable
          q.text("(prelude")
          q.nest(2) do
            q.breakable("")
            q.seplist(node.prelude) { |token| q.pp(token) }
          end

          q.breakable("")
          q.text(")")

          q.breakable
          q.pp(node.block)
        end
      end

      # Visit a SemicolonToken node.
      def visit_semicolon_token(node)
        token("semicolon-token")
      end

      # Visit a SimpleBlock node.
      def visit_simple_block(node)
        token("simple-block") do
          q.breakable
          q.pp(node.token)

          if node.value.any?
            q.breakable
            q.seplist(node.value) { |val| q.pp(val) }
          end
        end
      end

      # Visit a StringToken node.
      def visit_string_token(node)
        token("string-token") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a StyleRule node.
      def visit_style_rule(node)
        token("style-rule") do
          q.breakable
          q.text("(selectors")
          q.nest(2) do
            q.breakable
            q.seplist(node.selectors) { |token| q.pp(token) }
          end

          q.breakable("")
          q.text(")")

          q.breakable
          q.text("(declarations")

          if node.declarations.any?
            q.nest(2) do
              q.breakable
              q.seplist(node.declarations) { |token| q.pp(token) }
            end

            q.breakable("")
          end

          q.text(")")
        end
      end

      # Visit a StyleSheet node.
      def visit_stylesheet(node)
        token("stylesheet") do
          if node.rules.any?
            q.breakable
            q.seplist(node.rules) { |rule| q.pp(rule) }
          end
        end
      end

      # Visit a URange node.
      def visit_urange(node)
        token("urange") do
          q.breakable
          q.pp(node.start_value)
          q.text("-")
          q.pp(node.end_value)
        end
      end

      # Visit a URLToken node.
      def visit_url_token(node)
        token("url-token") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a WhitespaceToken node.
      def visit_whitespace_token(node)
        token("whitespace-token") do
          q.breakable
          q.pp(node.value)
        end
      end

      #-------------------------------------------------------------------------
      # Selector nodes
      #-------------------------------------------------------------------------

      # Visit a Selectors::ClassSelector node.
      def visit_class_selector(node)
        token("class-selector") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a Selectors::IdSelector node.
      def visit_id_selector(node)
        token("id-selector") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a Selectors::PseudoClassSelector node.
      def visit_pseudo_class_selector(node)
        token("pseudo-class-selector") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a Selectors::PseudoClassFunction node.
      def visit_pseudo_class_function(node)
        token("pseudo-class-function") do
          q.breakable
          q.pp(node.name)

          q.breakable
          q.text("(arguments")

          if node.arguments.any?
            q.nest(2) do
              q.breakable
              q.seplist(node.arguments) { |argument| q.pp(argument) }
            end

            q.breakable("")
          end

          q.text(")")
        end
      end

      # Visit a Selectors::PseudoElementSelector node.
      def visit_pseudo_element_selector(node)
        token("pseudo-element-selector") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a Selectors::TypeSelector node.
      def visit_type_selector(node)
        token("type-selector") do
          if node.prefix
            q.breakable
            q.pp(node.prefix)
          end

          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a Selectors::WqName node.
      def visit_wqname(node)
        token("wqname") do
          if node.prefix
            q.breakable
            q.pp(node.prefix)
          end

          q.breakable
          q.pp(node.name)
        end
      end

      # Visit a Selectors::Combinator node.
      def visit_combinator(node)
        token(node.class::PP_NAME) do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a Selectors::ComplexSelector node.
      def visit_complex_selector(node)
        token("complex-selector") do
          node.child_nodes.each do |child|
            q.breakable
            q.pp(child)
          end
        end
      end

      # Visit a Selectors::CompoundSelector node.
      def visit_compound_selector(node)
        token("compound-selector") do
          q.breakable
          token("type") do
            q.breakable
            q.pp(node.type)
          end

          q.breakable
          q.text("(subclasses")

          if node.subclasses.any?
            q.nest(2) do
              q.breakable
              q.seplist(node.subclasses) { |subclass| q.pp(subclass) }
            end

            q.breakable("")
          end

          q.text(")")

          q.breakable("")
          q.text("(pseudo-elements")

          if node.pseudo_elements.any?
            q.nest(2) do
              q.breakable
              q.seplist(node.pseudo_elements) do |pseudo_element|
                q.pp(pseudo_element)
              end
            end

            q.breakable("")
          end

          q.text(")")
        end
      end

      private

      def token(name)
        q.group do
          q.text("(")
          q.text(name)

          if block_given?
            q.nest(2) { yield }
            q.breakable("")
          end

          q.text(")")
        end
      end
    end
  end
end
