# frozen_string_literal: true

module SyntaxTree
  module CSS
    # A formatting visitor.
    class Format < BasicVisitor
      attr_reader :q

      def initialize(q)
        @q = q
      end
    end
  end
end
