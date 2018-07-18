# frozen_string_literal: true

module Rouge
  module Lexers
    class Ebnf < RegexLexer
      title 'EBNF'
      desc 'Tokenizer for EBNF'
      tag 'ebnf'
      filenames '*.ebnf'
      mimetypes 'text/x-ebnf'

      state :root do
        rule(/\s+/m, Text::Whitespace)
        rule(/\(\*.*\*\)/, Comment::Single)
        rule(/"[^"]*"/, Str::Double)
        rule(/'[^']*'/, Str::Single)
        rule(/\?[^\?]*\?/, Comment::Preproc)

        rule(/\|/, Name::Function)
        rule(/=|;|-|,|\\/, Punctuation)
        rule(/\[|\]|\{|\}|\(|\)/, Operator)
        rule(/(\w+)\b/, Text)
      end
    end
  end
end
