# SyntaxTree::CSS

[![Build Status](https://github.com/ruby-syntax-tree/syntax_tree-css/actions/workflows/main.yml/badge.svg)](https://github.com/ruby-syntax-tree/syntax_tree-css/actions/workflows/main.yml)
[![Gem Version](https://img.shields.io/gem/v/syntax_tree-css.svg)](https://rubygems.org/gems/syntax_tree-css)

[Syntax Tree](https://github.com/ruby-syntax-tree/syntax_tree) support for CSS.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "syntax_tree-css"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install syntax_tree-css

## Usage

From code:

```ruby
require "syntax_tree/css"

pp SyntaxTree::CSS.parse(source) # print out the AST
puts SyntaxTree::CSS.format(source) # format the AST
```

From the CLI:

```sh
$ stree ast --plugins=css file.css
(css-stylesheet
  (style-rule
    (selectors
      (type-selector (delim-token "*"))
    )
    (declarations
      (declaration hello (ident-token "world"), (semicolon-token))
    )
  )
)
```

or

```sh
$ stree format --plugins=css file.css
* {
  hello: world;
}
```

or

```sh
$ stree write --plugins=css file.css
file.css 1ms
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby-syntax-tree/syntax_tree-css.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
