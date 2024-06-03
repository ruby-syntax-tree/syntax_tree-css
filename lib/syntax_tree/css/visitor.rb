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

      #-------------------------------------------------------------------------
      # CSS3 nodes
      #-------------------------------------------------------------------------

      # Visit an AtKeywordToken node.
      alias visit_at_keyword visit_child_nodes

      # Visit an AtRule node.
      alias visit_at_rule visit_child_nodes

      # Visit a BadStringToken node.
      alias visit_bad_string_token visit_child_nodes

      # Visit a BadURLToken node.
      alias visit_bad_url_token visit_child_nodes

      # Visit a CDCToken node.
      alias visit_cdc_token visit_child_nodes

      # Visit a CDOToken node.
      alias visit_cdo_token visit_child_nodes

      # Visit a CloseCurlyToken node.
      alias visit_close_curly_token visit_child_nodes

      # Visit a CloseParenToken node.
      alias visit_close_paren_token visit_child_nodes

      # Visit a CloseSquareToken node.
      alias visit_close_square_token visit_child_nodes

      # Visit a ColonToken node.
      alias visit_colon_token visit_child_nodes

      # Visit a CommentToken node.
      alias visit_comment_token visit_child_nodes

      # Visit a CommaToken node.
      alias visit_comma_token visit_child_nodes

      # Visit a CSSStyleSheet node.
      alias visit_css_stylesheet visit_child_nodes

      # Visit a Declaration node.
      alias visit_declaration visit_child_nodes

      # Visit a DelimToken node.
      alias visit_delim_token visit_child_nodes

      # Visit a DimensionToken node.
      alias visit_dimension_token visit_child_nodes

      # Visit an EOFToken node.
      alias visit_eof_token visit_child_nodes

      # Visit a Function node.
      alias visit_function visit_child_nodes

      # Visit a FunctionToken node.
      alias visit_function_token visit_child_nodes

      # Visit a HashToken node.
      alias visit_hash_token visit_child_nodes

      # Visit an IdentToken node.
      alias visit_ident_token visit_child_nodes

      # Visit a NumberToken node.
      alias visit_number_token visit_child_nodes

      # Visit an OpenCurlyToken node.
      alias visit_open_curly_token visit_child_nodes

      # Visit an OpenParenToken node.
      alias visit_open_paren_token visit_child_nodes

      # Visit an OpenSquareToken node.
      alias visit_open_square_token visit_child_nodes

      # Visit a PercentageToken node.
      alias visit_percentage_token visit_child_nodes

      # Visit a QualifiedRule node.
      alias visit_qualified_rule visit_child_nodes

      # Visit a SemicolonToken node.
      alias visit_semicolon_token visit_child_nodes

      # Visit a SimpleBlock node.
      alias visit_simple_block visit_child_nodes

      # Visit a StringToken node.
      alias visit_string_token visit_child_nodes

      # Visit a StyleRule node.
      alias visit_style_rule visit_child_nodes

      # Visit a StyleSheet node.
      alias visit_stylesheet visit_child_nodes

      # Visit a URange node.
      alias visit_urange visit_child_nodes

      # Visit a URLToken node.
      alias visit_url_token visit_child_nodes

      # Visit a WhitespaceToken node.
      alias visit_whitespace_token visit_child_nodes

      #-------------------------------------------------------------------------
      # Selector nodes
      #-------------------------------------------------------------------------

      # Visit a Selectors::ClassSelector node.
      alias visit_class_selector visit_child_nodes

      # Visit a Selectors::Combinator node.
      alias visit_combinator visit_child_nodes

      # Visit a Selectors::ComplexSelector node.
      alias visit_complex_selector visit_child_nodes

      # Visit a Selectors::CompoundSelector node.
      alias visit_compound_selector visit_child_nodes

      # Visit a Selectors::IdSelector node.
      alias visit_id_selector visit_child_nodes

      # Visit a Selectors::PseudoClassFunction node.
      alias visit_pseudo_class_function visit_child_nodes

      # Visit a Selectors::PseudoClassSelector node.
      alias visit_pseudo_class_selector visit_child_nodes

      # Visit a Selectors::PseudoElementSelector node.
      alias visit_pseudo_element_selector visit_child_nodes

      # Visit a Selectors::TypeSelector node.
      alias visit_type_selector visit_child_nodes

      # Visit a Selectors::WqName node.
      alias visit_wqname visit_child_nodes
    end
  end
end
