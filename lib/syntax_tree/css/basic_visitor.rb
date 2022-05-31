# frozen_string_literal: true

module SyntaxTree
  module CSS
    # The parent class of all visitors that provides the double dispatch
    # pattern. It doesn't provide any of the aliases so it can't actually be
    # used to visit the tree. It's used to implement visitors that should raise
    # an error if a node that's not implemented is visited.
    class BasicVisitor
      def visit(node)
        node&.accept(self)
      end

      def visit_all(nodes)
        nodes.map { |node| visit(node) }
      end

      def visit_child_nodes(node)
        visit_all(node.child_nodes)
      end
    end
  end
end
