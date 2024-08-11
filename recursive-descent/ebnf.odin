package recurse

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:unicode"

EBNF_Grammar :: `
  syntax     = {production}.
  production = identifier "=" expression ".".
  expression = term {"|" term}.
  term       = factor {factor}.
  factor     = identifier | literal | "(" expression ")" | "[" expression "]" | "{" expression "}".
`

Node_Location :: struct {
  start: Source_Location,
  end:   Source_Location
}

Grammar :: struct {
  productions: [dynamic]Production
}

Production :: struct {
  loc: Node_Location,
  name: string,
  expr: Expression
}

Expression :: struct {
  loc: Node_Location,
  terms: [dynamic]Term
}

Term :: struct {
  loc: Node_Location,
  factors: [dynamic]Factor
}

Factor_Type :: enum{ Identifier, Literal, Optional, Repetition, Grouping }

Factor :: struct {
  loc: Node_Location,
  type: Factor_Type,
  value: union { string, Expression },
}

Source_Location :: struct {
  line: int,
  col: int,
  index: int,
}

Parser :: struct {
  char: u8,
  sym: Symbol,
  ident: string,

  src: string,
  loc: Source_Location,
  last_error_loc: Source_Location,
}

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
  EOF,
}

parser: Parser

read_char :: proc() {
  if parser.loc.index+1 >= len(parser.src) {
    return;
  }

  parser.char = parser.src[parser.loc.index+1]
  parser.loc.index = parser.loc.index+1
  parser.loc.col   = parser.loc.col+1
}

skip_whitespace :: proc() {
  for parser.loc.index+1 < len(parser.src) && unicode.is_white_space(rune(parser.char)) {
    if parser.char == '\n' {
      parser.loc.line = parser.loc.line+1
      parser.loc.col = -1 // So the +1 in read_char() results in a col of 0 of this next line
    }
    read_char()
  }
}

get_symbol :: proc() {
  parser.ident = ""
  parser.sym = .Unknown
  if parser.loc.index == len(parser.src) {
    parser.sym = .EOF
    return
  }

  skip_whitespace()
  if unicode.is_alpha(rune(parser.char)) {
    parser.sym = .Identifier
    identifier_start := parser.loc.index
    read_char()
    for unicode.is_alpha(rune(parser.char)) { read_char(); }
    parser.ident = parser.src[identifier_start:parser.loc.index]
    return
  }
  switch parser.char {
    case '"':
      parser.sym = .Literal
      read_char()
      identifier_start := parser.loc.index
      for parser.char != '"' { read_char() }
      parser.ident = parser.src[identifier_start:parser.loc.index]
    case '=': parser.sym = .Equal
    case '(': parser.sym = .Left_Paren
    case ')': parser.sym = .Right_Paren
    case '[': parser.sym = .Left_Bracket
    case ']': parser.sym = .Right_Bracket
    case '{': parser.sym = .Left_Brace
    case '}': parser.sym = .Right_Brace
    case '|': parser.sym = .Bar
    case '.': parser.sym = .Period
    case:     parser.sym = .Unknown
  }
  read_char()
}

error :: proc(message: string) {
  if parser.loc.index > parser.last_error_loc.index+4 {
    parser.last_error_loc = parser.loc
    fmt.println(message)
    fmt.printf("%#v\n", parser.last_error_loc)
  }
}

expect :: proc(expected_symbol: Symbol) {
  if parser.sym == expected_symbol {
    get_symbol()
  } else {
    error(fmt.tprintf("Expected %s, but got %s", expected_symbol, parser.sym))
  }
}

parse_factor :: proc(allocator := context.allocator) -> Factor {
  factor := Factor{ loc=Node_Location{ start=parser.loc } }
  #partial switch parser.sym {
    case .Identifier:
      factor = Factor{
        type = .Identifier,
        value = parser.ident
      }
      get_symbol()
    case .Literal:
      factor = Factor{
        type = .Literal,
        value = parser.ident
      }
      get_symbol()
    case .Left_Paren:
      get_symbol()
      factor = Factor{
        type = .Grouping,
        value = parse_expression(allocator)
      }
      expect(.Right_Paren)
    case .Left_Bracket:
      get_symbol()
      factor = Factor{
        type = .Optional,
        value = parse_expression(allocator)
      }
      expect(.Right_Bracket)
    case .Left_Brace:
      get_symbol()
      factor = Factor{
        type = .Repetition,
        value = parse_expression(allocator)
      }
      expect(.Right_Brace)
    case:
      error(fmt.tprintf("Unexpected symbol: %s", parser.sym))
  }

  factor.loc.end = parser.loc
  return factor
}

parse_term :: proc(allocator := context.allocator) -> Term {
  loc := Node_Location{ start=parser.loc }
  factors := make([dynamic]Factor, allocator)
  append(&factors, parse_factor(allocator))
  for parser.sym < .Bar {
    append(&factors, parse_factor(allocator))
  }

  loc.end = parser.loc
  return Term{ factors=factors, loc=loc }
}

parse_expression :: proc(allocator := context.allocator) -> Expression {
  loc := Node_Location{ start=parser.loc }
  terms := make([dynamic]Term, allocator)
  append(&terms, parse_term(allocator))
  for parser.sym == .Bar {
    get_symbol()
    append(&terms, parse_term(allocator))
  }

  loc.end = parser.loc
  return Expression{ terms=terms, loc=loc }
}

parse_production :: proc(allocator := context.allocator) -> Production {
  loc  := Node_Location{ start=parser.loc }
  name := parser.ident

  get_symbol()
  expect(.Equal)
  expr := parse_expression(allocator)
  expect(.Period)

  loc.end = parser.loc
  return Production{name=name, expr=expr, loc=loc}
}

parse :: proc(source: string, allocator := context.allocator) -> Grammar {
  if len(source) == 0 {
    return Grammar{}
  }

  productions := make([dynamic]Production, allocator)
  parser = Parser {}
  parser.src = source
  parser.char = source[0]
  parser.loc = Source_Location{
    line  = 1,
    col   = 0,
    index = 0
  }

  get_symbol()
  if parser.sym != .Identifier {
    fmt.printf("Couldn't find initial identifier: %s\n", source)
    return Grammar{}
  }

  for parser.sym == .Identifier {
    append(&productions, parse_production(allocator))
  }

  return Grammar{
    productions = productions
  }
}

tprint_factor :: proc(factor: Factor, allocator := context.allocator) -> string {
  switch factor.type {
    case .Identifier: {
      val, ok := factor.value.(string)
      if !ok {
        return ""
      }
      return val
    }
    case .Literal:    return fmt.tprintf("\"%s\"", factor.value.(string))
    case .Grouping:   return fmt.tprintf("(%s)",   tprint(factor.value.(Expression), allocator))
    case .Optional:   return fmt.tprintf("[%s]",   tprint(factor.value.(Expression), allocator))
    case .Repetition: return fmt.tprintf("{{%s}}", tprint(factor.value.(Expression), allocator))
  } 
  return ""
}

tprint_term :: proc(term: Term, allocator := context.allocator) -> string {
  factors_str := make([dynamic]string, allocator)
  defer delete(factors_str)

  for factor in term.factors {
    append(&factors_str, tprint(factor, allocator))
  }
  return strings.join(factors_str[:], " ", allocator)
}

tprint_expression :: proc(expr: Expression, allocator := context.allocator) -> string {
  terms_str := make([dynamic]string, allocator)
  defer delete(terms_str)

  for term in expr.terms {
    append(&terms_str, tprint(term, allocator))
  }
  return strings.join(terms_str[:], " | ", allocator)
}

tprint_production :: proc(production: Production, allocator := context.allocator) -> string {
  return fmt.tprintf("%s = %s.", production.name, tprint(production.expr, allocator)) 
}

tprint_grammar :: proc(grammar: Grammar, allocator := context.allocator) -> string {
  productions_str := make([dynamic]string, allocator)
  defer delete(productions_str)

  for production in grammar.productions {
    append(&productions_str, tprint(production, allocator))
  }
  return strings.join(productions_str[:], "\n", allocator)
}

tprint :: proc{ tprint_grammar, tprint_production, tprint_expression, tprint_term, tprint_factor }

run_ebnf :: proc() {
  arena_buffer := make([dynamic]u8, 4 * mem.Megabyte)
  defer delete(arena_buffer)
  arena: mem.Arena
  mem.arena_init(&arena, arena_buffer[:])
  arena_allocator := mem.arena_allocator(&arena)

  grammar := parse(EBNF_Grammar, arena_allocator)
  serialized_grammar := tprint(grammar, arena_allocator)

  fmt.println(serialized_grammar)
  fmt.printf("\nPeak used memory: %fKB\n", f32(arena.peak_used) / 1024)
}