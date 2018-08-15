

MLStyle.jl
=========================

## Install

This package is not registered yet. Please use the following command in **v0.7+**:

```julia
pkg> add https://github.com/thautwarm/MLStyle.jl.git#master
```


Preview
-------------------


```julia

using MLStyle

abstract type C{T} end

@case C1{T}(a :: T) <: C{T}
@case C2{T}(a :: T, b :: Int) <: C{T}

@match C1(2) begin
    C1(3)         => nothing
    C1(a){a > 2}  =>  nothing
    C1(a){a <= 2} => a
end

# => 2


fn(c:: C) =

    @match c begin

      C2(2, 3){false} => nothing

      C1(a)    |
      C2(a, 3) |
      C2(2, a)        => a

      _               => @error ""
   end

fn(C1(2)) # => 2
fn(C2(2, 5)) # => 5
fn(C2(7, 3)) # => 7
fn(C2(7, 5)) # => error

@match 2 begin
  1 .. 10 in x =>  x == 2
  _       => false
end # => true

```


Available Features
------------------------

- Wild-Match

  ```julia

  @case S(a, b)

  @match S(S(1, 2), S(2, 3)) begin
      S(S(_, _), _) => 1
      ...
  end

  # => 1
  ```
- As-Pattern

  ```julia

  @match <expr> begin
      <pattern> in <name-binding> => <body>
      ...
  end

  ```

  E.g:

  ```julia
  @match (1, 2) begin
    (a, b) in c => a + b == c[0] + c[1]
  end
  # => true
  ```

- ADT

  ```julia

  @case Fn{T, G}(fn :: Function, From :: T, To :: G)

  abstract type Exp{T} end

  @case App{G, T}(fn :: Fn{G, T}, arg :: G) <: Exp{T}

  @case Lam{G, T}{arg :: G, body :: T} <: Exp{T}

  @case IfElse{T}(test::Exp{Bool}, if_true :: T, else_do :: T) <: Exp{T}

  @case Atom{T}(value :: T) <: Exp{T}

  let if_exp =
      IfElse(
          Atom(true),
          Atom("1"),
          Atom("2"))

      @match if_exp begin
          IfElse(Atom(test), v1, v2) =>
              if test
                  v1
              else
                  v2
              end
      end     
  end

  # => Atom{String}("1")

  ```

  Works like a charm?:)

- Fallthrough cases

  ```julia
  @match x begin
      1     |
      2     |
      3     |
      :: Ty |
      S(_, _) => 0

      _       => 1
  end
  ```

- Range Pattern, Tuple Pattern and so on

  ```julia

  @match 1 begin
      0..10 => true
  end # => true

  @match ((1, 2), (3, (5, 6))) begin
      ((a, b), (3, (c, d))) => a + b + c + d
  end # => 14

  ```
- Custom Pattern

  Pattern matching of `Dict` is implemented by this feature.

  It works like the similar feature in `Elixir` but is totally static and much more efficient.

  ```julia

  @match <expr> begin
      Dict(<expr> => <pattern>, ...) => body
      ...
  end
  ```

  E.g:

  ```julia

  dict = Dict(1 => 2, "3" => Dict(4 => 5), 6 => "7")

  @match dict begin
      Dict(1 => 2, "3" => Dict( 4 => a)) => a
      ...
  end # => 5

  ```

  The documentary for this pattern is necessary, for lack of time I cannot finish it immediately. See builtin examples at [Match Extensions](https://github.com/thautwarm/MLStyle.jl/blob/master/src/MatchExt.jl).

  Using custom pattern you can implement active patterns like F#, but remember active pattern is far from the bound. Give me a `SML` solver, you might be able to write codes like
  ```julia
  @match rvalue begin
    x^2 + 2x + 9 => x
  end  
  ```

**The Reason Why I didn't implement List Pattern**:

```julia
  @match [1, 2, 3] begin
      [1 | tail] => sum(tail)
  end
```

First of which is lack of time. Secondly, for `[...]` literal in Julia is dynamic array instead of `LinkedList`, I'm not sure how to choose the implementation.


Incoming Features
======================

- Pattern matching for functions.
  ```julia
  @def f {
     ((a, b), true)   => <body1>
     (nothing, false) => <body2>

     _                => <body3>
  }
  ```
- Numeric dependent types.

- Range pattern(Done).

  ```julia
  @match num begin
     1 .. 10 => #do stuff
  end
  ```

- Various monad utilities.
