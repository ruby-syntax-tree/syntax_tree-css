# frozen_string_literal: true

module SyntaxTree
  module CSS
    # A formatting visitor.
    class Format < BasicVisitor
      attr_reader :q

      def initialize(q)
        @q = q
      end

      #-------------------------------------------------------------------------
      # CSS3 nodes
      #-------------------------------------------------------------------------

      # Visit a CSSStyleSheet node.
      def visit_css_stylesheet(node)
        q.seplist(node.rules, -> { q.breakable(force: true) }) do |rule|
          rule.format(q)
        end
        q.breakable(force: true)
      end

      # Visit a Declaration node.
      def visit_declaration(node)
        q.group do
          q.text(node.name)
          q.text(": ")

          node.value.each do |value|
            value.format(q)
          end

          q.text(" !important") if node.important?
          q.text(";")
        end
      end

      # Visit a DelimToken node.
      def visit_delim_token(node)
        q.text(node.value)
      end

      # Visit an IdentToken node.
      def visit_ident_token(node)
        q.text(node.value)
      end

      # Visit a HashToken node.
      def visit_hash_token(node)
        q.text(node.value)
      end

      # Visit a StyleRule node.
      def visit_style_rule(node)
        q.group do
          q.seplist(node.selectors) { |selector| selector.format(q) }
          q.text(" {")

          q.indent do
            q.breakable(force: true)
            q.seplist(node.declarations, -> { q.breakable }) do |declaration|
              declaration.format(q)
            end
          end

          q.breakable(force: true)
          q.text("}")
        end
      end

      #-------------------------------------------------------------------------
      # Selector nodes
      #-------------------------------------------------------------------------

      # Visit a Selectors::TypeSelector node.
      def visit_type_selector(node)
        q.group do
          node.prefix.format(q) if node.prefix
          node.value.format(q)
        end
      end

      # Visit a Selectors::IdSelector node.
      def visit_id_selector(node)
        q.text("#")
        node.value.format(q)
      end

      # Visit a Selectors::ClassSelector node.
      def visit_class_selector(node)
        q.text(".")
        node.value.format(q)
      end

      # Visit a Selectors::PseudoClassSelector node.
      def visit_pseudo_class_selector(node)
        q.text(":")
        node.value.format(q)
      end

      # Visit a Selectors::PseudoClassFunction node.
      def visit_pseudo_class_function(node)
        q.text(node.name)
        q.text("(")
        q.seplist(node.arguments, -> { q.text(", ") }) do |selector|
          selector.format(q)
        end
        q.text(")")
      end

      # Visit a Selectors::PseudoElementSelector node.
      def visit_pseudo_element_selector(node)
        q.text(":")
        node.value.format(q)
      end

      # Visit a Selectors::Combinator node.
      def visit_combinator(node)
        case node.value
        when WhitespaceToken
          q.text(" ")
        when Array
          q.text(" ")
          node.value.each { |val| val.format(q) }
          q.text(" ")
        else
          q.text(" ")
          node.value.format(q)
          q.text(" ")
        end
      end

      # Visit a Selectors::ComplexSelector node.
      def visit_complex_selector(node)
        q.group do
          node.child_nodes.each_with_index do |child_node, j|
            child_node.format(q)
          end
        end
      end

      # Visit a Selectors::CompoundSelector node.
      def visit_compound_selector(node)
        q.group do
          node.child_nodes.each do |node_|
            node_.format(q)
          end
        end
      end

      def visit_wqname(node)
        node.prefix.format(q) if node.prefix
        node.name.format(q)
      end
    end
  end
end
