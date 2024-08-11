package recurse

import "core:fmt"
import "core:strings"
import "core:unicode"

EBNF_Grammar := `
    syntax     = {production}.
    production = identifier "=" expression ".".
    expression = term {"|" term}.
    term       = factor {factor}.
    factor     = identifier | literal | "(" expression ")" | "[" expression "]" | "{" expression "}".
`

Grammar :: struct {
  productions: [dynamic]Production
}

Production :: struct {
  name: string,
  expr: Expression,
}

Expression :: struct {
  terms: [dynamic]Term
}

Term :: struct {
  factors: [dynamic]Factor,
}

Factor_Type :: enum{ Identifier, Literal, Optional, Repetition, Grouping }

Factor :: struct {
  type: Factor_Type,
  value: union { string, Expression },
}

Parser :: struct {
  char: u8,
  symbol: Symbol,
  identifier: string,

  source: string,
  position: int,
  last_error_position: int,
}

Symbol :: enum {
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
  Unknown,
  EOF,
}

parser: Parser

read_char :: proc() {
  if parser.position+1 >= len(parser.source) {
    return;
  }

  parser.char = parser.source[parser.position+1]
  parser.position = parser.position+1
}

skip_whitespace :: proc() {
  for parser.position+1 < len(parser.source) && unicode.is_white_space(rune(parser.char)) {
    read_char()
  }
}

get_symbol :: proc() {
  parser.identifier = ""
  parser.symbol = .Unknown
  if parser.position == len(parser.source) {
    parser.symbol = .EOF
    return
  }

  skip_whitespace()
  if unicode.is_alpha(rune(parser.char)) {
    parser.symbol = .Identifier
    identifier_start := parser.position
    read_char()
    for unicode.is_alpha(rune(parser.char)) { read_char(); }
    parser.identifier = parser.source[identifier_start:parser.position]
    return
  }
  switch parser.char {
    case '"':
      parser.symbol = .Literal
      read_char()
      identifier_start := parser.position
      for parser.char != '"' { read_char() }
      parser.identifier = parser.source[identifier_start:parser.position]
    case '=': parser.symbol = .Equal
    case '(': parser.symbol = .Left_Paren
    case ')': parser.symbol = .Right_Paren
    case '[': parser.symbol = .Left_Bracket
    case ']': parser.symbol = .Right_Bracket
    case '{': parser.symbol = .Left_Brace
    case '}': parser.symbol = .Right_Brace
    case '|': parser.symbol = .Bar
    case '.': parser.symbol = .Period
    case:     parser.symbol = .Unknown
  }
  read_char()
}

error :: proc(message: string) {
  if parser.position > parser.last_error_position+4 {
    fmt.println(message)
    fmt.printf("%v\n", parser)
    parser.last_error_position = parser.position
  }
}

expect :: proc(expected_symbol: Symbol) {
  if parser.symbol == expected_symbol {
    get_symbol()
  } else {
    error(fmt.tprintf("Expected %s, but got %s", expected_symbol, parser.symbol))
  }
}

parse_factor :: proc() -> Factor {
  factor: Factor
  #partial switch parser.symbol {
    case .Identifier:
      factor = Factor{
        type = .Identifier,
        value = parser.identifier
      }
      get_symbol()
    case .Literal:
      factor = Factor{
        type = .Literal,
        value = parser.identifier
      }
      get_symbol()
    case .Left_Paren:
      get_symbol()
      factor = Factor{
        type = .Grouping,
        value = parse_expression()
      }
      expect(.Right_Paren)
    case .Left_Bracket:
      get_symbol()
      factor = Factor{
        type = .Optional,
        value = parse_expression()
      }
      expect(.Right_Bracket)
    case .Left_Brace:
      get_symbol()
      factor = Factor{
        type = .Repetition,
        value = parse_expression()
      }
      expect(.Right_Brace)
    case:
      error(fmt.tprintf("Unexpected symbol: %s", parser.symbol))
  }

  return factor
}

parse_term :: proc() -> Term {
  factors := make([dynamic]Factor)
  append(&factors, parse_factor())
  for parser.symbol < .Bar {
    append(&factors, parse_factor())
  }
  return Term{ factors=factors }
}

parse_expression :: proc() -> Expression {
  terms := make([dynamic]Term)
  append(&terms, parse_term())
  for parser.symbol == .Bar {
    get_symbol()
    append(&terms, parse_term())
  }
  return Expression{terms=terms}
}

parse_production :: proc() -> Production {
  name := parser.identifier
  get_symbol()
  expect(.Equal)
  expr := parse_expression()
  expect(.Period)

  return Production{name=name, expr=expr}
}

parse :: proc(source: string) -> Grammar {
  if len(source) == 0 {
    return Grammar{}
  }

  productions := make([dynamic]Production)
  parser = Parser {}
  parser.source = source
  parser.position = 0
  parser.char = source[0]

  get_symbol()
  if parser.symbol != .Identifier {
    fmt.printf("Couldn't find initial identifier: %s\n", source)
    return Grammar{}
  }

  for parser.symbol == .Identifier {
    append(&productions, parse_production())
  }

  return Grammar{
    productions = productions
  }
}

tprint_factor :: proc(factor: Factor) -> string {
  switch factor.type {
    case .Identifier: return factor.value.(string)
    case .Literal:    return fmt.tprintf("\"%s\"", factor.value.(string))
    case .Grouping:   return fmt.tprintf("(%s)",   tprint(factor.value.(Expression)))
    case .Optional:   return fmt.tprintf("[%s]",   tprint(factor.value.(Expression)))
    case .Repetition: return fmt.tprintf("{{%s}}", tprint(factor.value.(Expression)))
  } 
  return ""
}

tprint_term :: proc(term: Term) -> string {
  factors_str := make([dynamic]string)
  defer delete(factors_str)

  for factor in term.factors {
    append(&factors_str, tprint(factor))
  }
  return strings.join(factors_str[:], " ")
}

tprint_expression :: proc(expr: Expression) -> string {
  terms_str := make([dynamic]string)
  defer delete(terms_str)

  for term in expr.terms {
    append(&terms_str, tprint(term))
  }
  return strings.join(terms_str[:], " | ")
}

tprint_production :: proc(production: Production) -> string {
  return fmt.tprintf("%s = %s.", production.name, tprint(production.expr)) 
}

tprint_grammar :: proc(grammar: Grammar) -> string {
  productions_str := make([dynamic]string)
  defer delete(productions_str)

  for production in grammar.productions {
    append(&productions_str, tprint(production))
  }
  return strings.join(productions_str[:], "\n")
}

tprint :: proc{ tprint_grammar, tprint_production, tprint_expression, tprint_term, tprint_factor }

run_ebnf :: proc() {
  grammar := parse(EBNF_Grammar)
  fmt.println(tprint(grammar))
}