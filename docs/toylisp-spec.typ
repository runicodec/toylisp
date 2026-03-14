// ─────────────────────────────────────────────
//  ToyLisp Language Specification
//  Compile with: typst compile toylisp-spec.typ
// ─────────────────────────────────────────────

#set document(title: "ToyLisp Language Specification", author: "")
#set page(
  paper: "a4",
  margin: (x: 2.8cm, y: 2.8cm),
  numbering: "1",
  header: context {
    if counter(page).get().first() > 1 [
      #set text(size: 9pt, fill: luma(160))
      #grid(
        columns: (1fr, 1fr),
        align: (left, right),
        [ToyLisp Language Specification],
        [v1.0],
      )
      #line(length: 100%, stroke: 0.5pt + luma(210))
    ]
  },
)

#set text(font: "New Computer Modern", size: 11pt, lang: "en")
#set par(justify: true, leading: 0.75em)
#set heading(numbering: "1.")

#show heading.where(level: 1): it => {
  v(1.2em)
  text(size: 14pt, weight: "bold")[#it]
  v(0.4em)
}

#show heading.where(level: 2): it => {
  v(0.8em)
  text(size: 12pt, weight: "bold")[#it]
  v(0.3em)
}

#show raw: it => {
  if it.block {
    block(
      fill: luma(248),
      stroke: 0.5pt + luma(210),
      radius: 4pt,
      inset: (x: 12pt, y: 10pt),
      width: 100%,
    )[#text(font: "New Computer Modern Mono", size: 9.5pt)[#it]]
  } else {
    box(
      fill: luma(248),
      stroke: 0.5pt + luma(220),
      radius: 2pt,
      inset: (x: 3pt, y: 1pt),
    )[#text(font: "New Computer Modern Mono", size: 9.5pt)[#it]]
  }
}

// ── Title page ────────────────────────────────
#align(center)[
  #v(3cm)
  #text(size: 28pt, weight: "bold")[ToyLisp]
  #v(0.5em)
  #text(size: 13pt, fill: luma(100))[Language Specification · v1.0]
  #v(1.5em)
  #line(length: 8cm, stroke: 1pt + luma(200))
  #v(1em)
  #text(size: 11pt, fill: luma(120))[
    A minimal Lisp dialect — enough to be Turing-complete \
    and actually fun to implement.
  ]
  #v(3cm)
]

#pagebreak()

// ── Table of contents ─────────────────────────
#outline(
  title: [Contents],
  indent: 1.5em,
  depth: 2,
)

#pagebreak()

// ─────────────────────────────────────────────
= Types
// ─────────────────────────────────────────────

ToyLisp has eight first-class types. There is no implicit coercion between types; passing the wrong type to a built-in function raises a `TypeError`.

#v(0.6em)

#table(
  columns: (1fr, 2fr, 2.5fr),
  stroke: (x, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  fill: (_, y) => if y == 0 { luma(245) } else { none },
  inset: (x: 8pt, y: 7pt),
  align: (left, left, left),

  [*Type*], [*Literals / examples*], [*Notes*],

  [Number],  [`42`, `3.14`, `-7`],
  [64-bit float. No integer/float distinction.],

  [Symbol],  [`x`, `foo`, `zero?`],
  [Interned string. Evaluates by environment lookup.],

  [String],  [`"hello"`, `"world"`],
  [UTF-8 string literal. Immutable.],

  [Boolean], [`#t`, `#f`],
  [Only `#f` is falsy; every other value (including `0` and `""`) is truthy.],

  [Nil],     [`nil`, `()`],
  [The empty list. Also used as "no value". Falsy.],

  [Pair],    [`(cons 1 2)`],
  [A cons cell with `car` and `cdr`. Lists are nested pairs ending in `nil`.],

  [Lambda],  [`(lambda (x) x)`],
  [First-class closure. Captures its definition environment.],

  [Builtin], [`+`, `car`, `eq?`],
  [Native function implemented in the host language.],
)

// ─────────────────────────────────────────────
= Special Forms
// ─────────────────────────────────────────────

Special forms are evaluated directly by the interpreter. Unlike function calls, their arguments are *not* pre-evaluated unless the form explicitly says so.

== `quote`

```
(quote <expr>)
'<expr>          ; shorthand
```

Returns `expr` unevaluated. The reader expands `'x` to `(quote x)`.

```scheme
'(1 2 3)  ; → (1 2 3)
'foo      ; → foo
```

== `if`

```
(if <cond> <then>)
(if <cond> <then> <else>)
```

Evaluates `cond`. If the result is truthy, evaluates and returns `then`; otherwise evaluates and returns `else`. When the `else` branch is omitted and `cond` is falsy, returns `nil`.

```scheme
(if #t 1 2)        ; → 1
(if #f 1 2)        ; → 2
(if #f "never")    ; → nil
```

== `define`

```
(define <sym> <expr>)
```

Evaluates `expr` and binds the result to `sym` in the current environment. Returns the symbol. Used at the top level to define globals, and inside a `begin` or lambda body to create local definitions.

```scheme
(define x 42)          ; → x
(define square
  (lambda (n) (* n n))) ; → square
```

== `lambda`

```
(lambda (<param> ...) <body-expr> ...)
```

Creates a closure over the current environment. The body may contain multiple expressions; all are evaluated in order and the last value is returned (implicit `begin`).

```scheme
(lambda (x y) (+ x y))
(lambda (x) (define y (* x 2)) y)  ; two-expr body
```

== `begin`

```
(begin <expr> ...)
```

Evaluates each expression in order; returns the value of the last one.

```scheme
(begin (define x 1) (+ x 1))  ; → 2
```

== `set!`

```
(set! <sym> <expr>)
```

Mutates an existing binding by walking up the environment chain and updating the frame where `sym` is found. Raises `SetError` if the symbol is not bound anywhere in the chain.

```scheme
(define counter 0)
(set! counter (+ counter 1))  ; counter → 1
```

== `and`

```
(and <expr> ...)
```

Short-circuiting conjunction. Evaluates expressions left-to-right. Returns the first falsy value encountered, or the last value if all are truthy. With zero arguments, returns `#t`.

```scheme
(and 1 2 3)    ; → 3
(and 1 #f 3)   ; → #f  (3 is never evaluated)
(and)          ; → #t
```

== `or`

```
(or <expr> ...)
```

Short-circuiting disjunction. Returns the first truthy value, or the last value if all are falsy. With zero arguments, returns `#f`.

```scheme
(or #f #f 7)   ; → 7
(or #f #f)     ; → #f
(or)           ; → #f
```

== `cond`

```
(cond (<test> <expr>) ... (else <expr>))
```

Multi-branch conditional. Tests are evaluated in order; the expression of the first truthy test is returned. The `else` clause is optional — if no test passes and there is no `else`, returns `nil`.

```scheme
(cond
  ((= x 1) "one")
  ((= x 2) "two")
  (else    "other"))
```

== `let`

```
(let ((<sym> <val>) ...) <body-expr> ...)
```

Evaluates all `val` expressions in the *current* environment (so bindings do not see each other), then evaluates the body in a new child environment with those bindings. Desugars to an immediately-applied lambda.

```scheme
(let ((x 2) (y 3))
  (+ x y))   ; → 5
```

// ─────────────────────────────────────────────
= Built-in Functions
// ─────────────────────────────────────────────

== Arithmetic

#table(
  columns: (1.8fr, 3fr),
  stroke: (_, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  fill: (_, y) => if y == 0 { luma(245) } else { none },
  inset: (x: 8pt, y: 6pt),
  [*Function*], [*Description*],
  [`(+ n ...)`],   [Sum of zero or more numbers. `(+)` → `0`.],
  [`(- n m ...)`], [Subtract. Unary form `(- n)` negates.],
  [`(* n ...)`],   [Product. `(*)` → `1`.],
  [`(/ n m)`],     [Divide. Raises `DivisionByZero` if `m` is `0`.],
  [`(mod n m)`],   [Remainder. Same sign as `n`.],
  [`(abs n)`],     [Absolute value.],
  [`(max n ...)`], [Maximum of one or more numbers.],
  [`(min n ...)`], [Minimum of one or more numbers.],
  [`(floor n)`],   [Round toward negative infinity.],
  [`(ceil n)`],    [Round toward positive infinity.],
  [`(sqrt n)`],    [Square root. Returns a number.],
)

== Comparison

#table(
  columns: (1.8fr, 3fr),
  stroke: (_, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  fill: (_, y) => if y == 0 { luma(245) } else { none },
  inset: (x: 8pt, y: 6pt),
  [*Function*], [*Description*],
  [`(= n m)`],     [Numeric equality.],
  [`(< n m)`],     [Less than.],
  [`(> n m)`],     [Greater than.],
  [`(<= n m)`],    [Less than or equal.],
  [`(>= n m)`],    [Greater than or equal.],
  [`(eq? a b)`],   [Identity (pointer) equality.],
  [`(equal? a b)`],[Deep structural equality.],
)

== Lists and Pairs

#table(
  columns: (2fr, 3fr),
  stroke: (_, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  fill: (_, y) => if y == 0 { luma(245) } else { none },
  inset: (x: 8pt, y: 6pt),
  [*Function*], [*Description*],
  [`(cons a d)`],       [Create a pair. `(cons 1 '(2 3))` → `(1 2 3)`.],
  [`(car p)`],          [Head of a pair / first element of a list.],
  [`(cdr p)`],          [Tail of a pair / rest of a list.],
  [`(list v ...)`],     [Construct a proper list from arguments.],
  [`(length lst)`],     [Number of elements in a proper list.],
  [`(append lst ...)`], [Concatenate lists. Returns a new list.],
  [`(reverse lst)`],    [Return a new reversed list.],
  [`(map f lst)`],      [Apply `f` to each element; return new list.],
  [`(filter f lst)`],   [Keep elements where `(f elem)` is truthy.],
  [`(for-each f lst)`], [Apply `f` for side effects; returns `nil`.],
  [`(apply f lst)`],    [`(apply + '(1 2 3))` → `6`.],
)

== Predicates

#table(
  columns: (1.8fr, 3fr),
  stroke: (_, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  fill: (_, y) => if y == 0 { luma(245) } else { none },
  inset: (x: 8pt, y: 6pt),
  [*Function*], [*Description*],
  [`(null? v)`],      [`#t` if `v` is `nil` / `()`.],
  [`(pair? v)`],      [`#t` if `v` is a cons cell.],
  [`(number? v)`],    [`#t` if `v` is a number.],
  [`(symbol? v)`],    [`#t` if `v` is a symbol.],
  [`(string? v)`],    [`#t` if `v` is a string.],
  [`(boolean? v)`],   [`#t` if `v` is `#t` or `#f`.],
  [`(procedure? v)`], [`#t` if `v` is a lambda or builtin.],
  [`(not v)`],        [`#t` if `v` is falsy; `#f` otherwise.],
)

== Strings

#table(
  columns: (2.2fr, 3fr),
  stroke: (_, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  fill: (_, y) => if y == 0 { luma(245) } else { none },
  inset: (x: 8pt, y: 6pt),
  [*Function*], [*Description*],
  [`(string-append s ...)`],   [Concatenate strings.],
  [`(string-length s)`],       [Number of characters.],
  [`(substring s i j)`],       [Characters from index `i` (inclusive) to `j` (exclusive).],
  [`(number->string n)`],      [Convert number to its string representation.],
  [`(string->number s)`],      [Parse a numeric string; returns `#f` on failure.],
  [`(string=? a b)`],          [String equality.],
)

== I/O

#table(
  columns: (1.8fr, 3fr),
  stroke: (_, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  fill: (_, y) => if y == 0 { luma(245) } else { none },
  inset: (x: 8pt, y: 6pt),
  [*Function*], [*Description*],
  [`(display v)`],    [Print `v` to stdout without a trailing newline.],
  [`(newline)`],      [Print a newline character.],
  [`(read)`],         [Read and parse one expression from stdin.],
  [`(error msg)`],    [Raise a `UserError` with the given message string.],
)

// ─────────────────────────────────────────────
= Evaluation Rules
// ─────────────────────────────────────────────

== Core rules

The evaluator is a recursive function `eval(expr, env)` → `value`. The rules below are exhaustive.

#table(
  columns: (2fr, 3.5fr),
  stroke: (_, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  fill: (_, y) => if y == 0 { luma(245) } else { none },
  inset: (x: 8pt, y: 7pt),
  [*Expression*], [*Result*],

  [Number / String / Boolean / Nil],
  [Self-evaluating — returns itself unchanged.],

  [Symbol `s`],
  [Look up `s` in `env`, walking up parent frames. Raise `UnboundSymbol` if not found.],

  [`(quote x)`],
  [Return `x` without evaluating it.],

  [`(if c t e)`],
  [Evaluate `c`. If truthy, evaluate and return `t`; otherwise evaluate and return `e` (or `nil` if omitted).],

  [`(lambda (p...) b...)`],
  [Capture the current `env`, the parameter list, and the body. Return a closure. The body is *not* evaluated yet.],

  [`(define s e)`],
  [Evaluate `e`. Bind the result to `s` in the *current* (innermost) environment frame. Return `s`.],

  [`(set! s e)`],
  [Evaluate `e`. Walk up the environment chain to find the frame where `s` is bound; update it. Raise `SetError` if not found.],

  [`(begin e...)`],
  [Evaluate each expression in order. Return the value of the last.],

  [`(f a...)`],
  [Evaluate `f`, then evaluate each argument left-to-right. Apply the resulting procedure to the resulting values. Raise `NotCallable` if `f` is not a procedure.],
)

== Applying a closure

When a closure is applied to a list of argument values:

+ Create a new environment whose parent is the closure's *captured* environment (not the call site).
+ Bind each parameter to its corresponding argument value. Raise `ArityError` if the counts differ.
+ Evaluate the body expressions in order in this new environment.
+ Return the value of the last body expression.

== Applying a builtin

Call the host-language implementation directly with the evaluated arguments. Type checking and arity checking are the builtin's responsibility.

== Environment model

An environment is a map from symbol to value plus a pointer to a parent environment. The global environment is the root; its parent is `null`.

- `define` always writes in the *current* (innermost) frame.
- `set!` walks up to find an existing binding and mutates that frame.
- Lookup walks up the chain until a binding is found or the root is exhausted.

// ─────────────────────────────────────────────
= Grammar
// ─────────────────────────────────────────────

```
; BNF — whitespace and comments are ignored between tokens

program  ::= expr*

expr     ::= atom
           | list
           | ' expr          ; quote shorthand: 'x → (quote x)

atom     ::= number
           | symbol
           | string
           | boolean
           | nil

list     ::= '(' expr* ')'
           | '(' expr+ '.' expr ')'   ; dotted pair

number   ::= [-]? [0-9]+ ('.' [0-9]+)?

symbol   ::= [a-zA-Z_+\-*/=<>?!] [a-zA-Z0-9_+\-*/=<>?!]*

string   ::= '"' strchar* '"'
strchar  ::= <any char except " and \>
           | \" | \\ | \n | \t

boolean  ::= '#t' | '#f'

nil      ::= 'nil' | '()'

; Comments: semicolon to end of line
; Whitespace: space, tab, \n, \r
```

#v(0.5em)
*Symbol character set.* Symbols may contain `+`, `-`, `*`, `/`, `=`, `<`, `>`, `?`, `!` in addition to alphanumerics and underscores. This enables idiomatic names like `zero?`, `set!`, `string->number`, and `my-helper`. The sole ambiguity: a lone `-` or `+` token is parsed as a symbol, not a number.

// ─────────────────────────────────────────────
= Error Types
// ─────────────────────────────────────────────

All errors must carry: the error type name, a human-readable message, and, where available, the source span (line:col) where the error was detected.

#table(
  columns: (2fr, 4fr),
  stroke: (_, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  fill: (_, y) => if y == 0 { luma(245) } else { none },
  inset: (x: 8pt, y: 7pt),
  [*Error*], [*When raised*],

  [`UnboundSymbol`],
  [A symbol was evaluated but not found in any environment frame.],

  [`TypeError`],
  [A value of the wrong type was passed to a built-in or operator. Example: `(+ 1 "a")`.],

  [`ArityError`],
  [Wrong number of arguments passed to a lambda or built-in.],

  [`NotCallable`],
  [The operator position of a call form evaluated to a non-procedure. Example: `(1 2 3)`.],

  [`DivisionByZero`],
  [The divisor in `/` or `mod` was `0`.],

  [`ParseError`],
  [Unmatched parentheses, an invalid token, or a malformed string literal.],

  [`SetError`],
  [`set!` was called with a symbol that is not bound in any environment frame.],

  [`UserError`],
  [Raised explicitly via `(error "message")`. Used for domain-level failures.],
)

// ─────────────────────────────────────────────
= Example Program
// ─────────────────────────────────────────────

The following program exercises the key features of ToyLisp: recursion, higher-order functions, closures with mutable state, and the standard list builtins.

```scheme
;; Fibonacci — iterative style using a local helper lambda
(define fib
  (lambda (n)
    (let ((loop (lambda (i a b)
                  (if (= i 0) a
                    (loop (- i 1) b (+ a b))))))
      (loop n 0 1))))

(display (fib 10))   ; → 55
(newline)

;; Higher-order: map and filter over a list
(define nums '(1 2 3 4 5 6))

(define evens
  (filter (lambda (x) (= (mod x 2) 0)) nums))

(define doubled
  (map (lambda (x) (* x 2)) evens))

(display doubled)    ; → (4 8 12)
(newline)

;; Closures: make-counter captures a mutable variable
(define make-counter
  (lambda ()
    (let ((n 0))
      (lambda ()
        (set! n (+ n 1))
        n))))

(define c (make-counter))
(display (c))   ; → 1
(display (c))   ; → 2
(display (c))   ; → 3
(newline)

;; apply: call a function with an argument list
(display (apply + '(1 2 3 4 5)))  ; → 15
(newline)

;; Recursive list processing
(define my-length
  (lambda (lst)
    (if (null? lst)
      0
      (+ 1 (my-length (cdr lst))))))

(display (my-length '(a b c d)))  ; → 4
(newline)
```
