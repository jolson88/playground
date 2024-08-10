package recurse

import "core:fmt"

EBNF_Grammar := `
    syntax     = {production}.
    production = identifier "=" expression ".".
    expression = term {"|" term}.
    term       = factor {factor}.
    factor     = identifier | string | "(" expression ")" | "[" expression "]" | "{" expression "}".
`

symbol: Symbol
identifier: string
source: string
position := 0

Symbol :: enum {
  Unknown,
  Identifier,
  Literal,
  Left_Paren,
  Left_Bracket,
  Left_Brace,
  Bar,
  Equal,
  Right_Paren,
  Right_Bracket,
  Right_Brace,
  Period,
}

get_symbol :: proc() {
  symbol = .Unknown
}

error :: proc(expectation: string) {
  fmt.println("%s, but got %s", expectation, symbol)
}

expect :: proc(expected_symbol: Symbol) {
  if symbol == expected_symbol {
    get_symbol()
  } else {
    error(fmt.tprintf("Expected %s", expected_symbol))
  }
}

parse_expression :: proc() {

}

parse_production :: proc() {
  get_symbol()
  expect(.Equal)
  parse_expression()
  expect(.Period)
}

parse_syntax :: proc(src: string) {
  source = src
  position = 0
  get_symbol()
  if symbol != .Identifier {
    fmt.printf("Couldn't find initial identifier: %s\n", src)
    return
  }

  for symbol == .Identifier {
    parse_production()
  }
}

run_ebnf :: proc() {
  parse_syntax("lang ()")
}