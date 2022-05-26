# frozen_string_literal: true

module SyntaxTree
  module CSS
    # A visitor that walks through the tree.
    class Visitor
      def visit(node)
        node&.accept(self)
      end

      def visit_all(nodes)
        nodes.map { |node| visit(node) }
      end

      def visit_child_nodes(node)
        visit_all(node.child_nodes)
      end

      # Visit a Token node.
      alias visit_token visit_child_nodes

      # Visit a StyleSheet node.
      alias visit_stylesheet visit_child_nodes

      # Visit a CSSStyleSheet node.
      alias visit_css_stylesheet visit_child_nodes

      # Visit an AtRule node.
      alias visit_at_rule visit_child_nodes

      # Visit a QualifiedRule node.
      alias visit_qualified_rule visit_child_nodes

      # Visit a Declaration node.
      alias visit_declaration visit_child_nodes

      # Visit a SimpleBlock node.
      alias visit_simple_block visit_child_nodes

      # Visit a Function node.
      alias visit_function visit_child_nodes

      # Visit a StyleRule node.
      alias visit_style_rule visit_child_nodes

      #-------------------------------------------------------------------------
      # Selectors
      #-------------------------------------------------------------------------

      # Visit a Selectors::WqName node.
      alias visit_wqname visit_child_nodes

      # Visit a Selectors::ClassSelector node.
      alias visit_class_selector visit_child_nodes

      # Visit a Selectors::IdSelector node.
      alias visit_id_selector visit_child_nodes
    end
  end
end
