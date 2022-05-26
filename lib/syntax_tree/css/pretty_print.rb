# frozen_string_literal: true

module SyntaxTree
  module CSS
    # A pretty-print visitor.
    class PrettyPrint < Visitor
      attr_reader :q

      def initialize(q)
        @q = q
      end

      # Visit a Token node.
      def visit_token(node)
        q.group do
          q.text("(#{node.type}")
          q.nest(2) do
            q.breakable
            q.pp(node.value)

            if node.flags.any?
              q.breakable
              q.seplist(node.flags) do |key, value|
                q.text(key)
                q.text("=")
                q.pp(value)
              end
            end
          end

          q.breakable("")
          q.text(")")
        end
      end

      # Visit a StyleSheet node.
      def visit_stylesheet(node)
        q.group do
          q.text("(styleshet")
          q.nest(2) do
            q.breakable
            q.seplist(node.rules) { |rule| q.pp(rule) }
          end

          q.breakable("")
          q.text(")")
        end
      end

      # Visit a CSSStyleSheet node.
      def visit_css_stylesheet(node)
        q.group do
          q.text("(css-styleshet")
          q.nest(2) do
            q.breakable
            q.seplist(node.rules) { |rule| q.pp(rule) }
          end

          q.breakable("")
          q.text(")")
        end
      end

      # Visit an AtRule node.
      def visit_at_rule(node)
        q.group do
          q.text("(at-rule")
          q.nest(2) do
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

          q.breakable("")
          q.text(")")
        end
      end

      # Visit a QualifiedRule node.
      def visit_qualified_rule(node)
        q.group do
          q.text("(qualified-rule")
          q.nest(2) do
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

          q.breakable("")
          q.text(")")
        end
      end

      # Visit a Declaration node.
      def visit_declaration(node)
        q.group do
          q.text("(declaration")
          q.nest(2) do
            q.breakable

            q.text(node.name)
            q.breakable

            if node.important?
              q.text("!important")
              q.breakable
            end

            q.seplist(node.value) { |token| q.pp(token) }
          end

          q.breakable("")
          q.text(")")
        end
      end

      # Visit a SimpleBlock node.
      def visit_simple_block(node)
        q.group do
          q.text("(simple-block")
          q.nest(2) do
            q.breakable
            q.pp(node.token)

            q.breakable
            q.seplist(node.value) { |val| q.pp(val) }
          end

          q.breakable("")
          q.text(")")
        end
      end

      # Visit a StyleRule node.
      def visit_style_rule(node)
        q.group do
          q.text("(style-rule")
          q.nest(2) do
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
            q.nest(2) do
              q.breakable
              q.seplist(node.declarations) { |token| q.pp(token) }
            end

            q.breakable("")
            q.text(")")
          end

          q.breakable("")
          q.text(")")
        end
      end

      # Visit a Function node.
      def visit_function(node)
        q.group do
          q.text("(function")
          q.nest(2) do
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

          q.breakable("")
          q.text(")")
        end
      end

      #-------------------------------------------------------------------------
      # Selectors
      #-------------------------------------------------------------------------

      # Visit a Selectors::WqName node.
      def visit_wqname(node)
        q.group do
          q.text("(wqname")

          q.nest(2) do
            if node.prefix
              q.breakable
              q.pp(node.prefix)
            end

            q.breakable
            q.pp(node.name)
          end

          q.breakable("")
          q.text(")")
        end
      end

      # Visit a Selectors::ClassSelector node.
      def visit_class_selector(node)
        q.group do
          q.text("(class-selector")

          q.nest(2) do
            q.breakable
            q.pp(node.value)
          end

          q.breakable("")
          q.text(")")
        end
      end

      # Visit a Selectors::IdSelector node.
      def visit_id_selector(node)
        q.group do
          q.text("(id-selector")

          q.nest(2) do
            q.breakable
            q.pp(node.value)
          end

          q.breakable("")
          q.text(")")
        end
      end
    end
  end
end
