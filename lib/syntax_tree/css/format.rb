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

      # Visit a HashToken node.
      def visit_hash_token(node)
        q.text(node.value)
      end

      # Visit an IdentToken node.
      def visit_ident_token(node)
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

      # Visit a Selectors::SubsequentSiblingCombinator node.
      def visit_subsequent_sibling_combinator(node)
        q.text(" ")
        node.value.format(q)
        q.text(" ")
      end

      #-------------------------------------------------------------------------
      # Selector nodes
      #-------------------------------------------------------------------------

      # Visit a Selectors::ChildCombinator node.
      def visit_child_combinator(node)
        q.text(" ")
        node.value.format(q)
        q.text(" ")
      end

      # Visit a Selectors::ClassSelector node.
      def visit_class_selector(node)
        q.text(".")
        node.value.format(q)
      end

      # Visit a Selectors::ColumnSiblingCombinator node.
      def visit_column_sibling_combinator(node)
        q.text(" ")
        node.value.each { |value| value.format(q) }
        q.text(" ")
      end

      # Visit a Selectors::ComplexSelector node.
      def visit_complex_selector(node)
        q.group do
          node.child_nodes.each do |child_node|
            child_node.format(q)
          end
        end
      end

      # Visit a Selectors::CompoundSelector node.
      def visit_compound_selector(node)
        q.group do
          node.child_nodes.each do |child_node|
            child_node.format(q)
          end
        end
      end

      # Visit a Selectors::DescendantCombinator node.
      def visit_descendant_combinator(node)
        q.text(" ")
      end

      # Visit a Selectors::IdSelector node.
      def visit_id_selector(node)
        q.text("#")
        node.value.format(q)
      end

      # Visit a Selectors::NextSiblingCombinator node.
      def visit_next_sibling_combinator(node)
        q.text(" ")
        node.value.format(q)
        q.text(" ")
      end

      # Visit a Selectors::TypeSelector node.
      def visit_type_selector(node)
        q.group do
          node.prefix&.format(q)
          node.value.format(q)
        end
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

      # Visit a Selectors::WqName node.
      def visit_wqname(node)
        node.prefix&.format(q)
        node.name.format(q)
      end
    end
  end
end
