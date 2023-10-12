# Preview

## Rock Paper Scissors

Here's a trivial example of MLStyle.jl in action:

```julia
using MLStyle
@data Shape begin # Define an algebraic data type Shape
    Rock()
    Paper()
    Scissors()
end

# Determine who wins a game of rock paper scissors with pattern matching
play(a::Shape, b::Shape) = @match (a, b) begin
    (Paper(),    Rock())      => "Paper Wins!";
    (Rock(),     Scissors())  => "Rock Wins!";
    (Scissors(), Paper())     => "Scissors Wins!";
    (a, b)                => a == b ? "Tie!" : play(b, a)
end
```

For a pattern like `A()`, there's a chance for them to get used with `A`:

```julia
# use pattern `A()` with the syntax `A`
MLStyle.is_enum(::Type{Rock}) = true
MLStyle.is_enum(::Type{Paper}) = true
MLStyle.is_enum(::Type{Scissors}) = true

play(a::Shape, b::Shape) = @match (a, b) begin
    (Paper,    Rock)      => "Paper Wins!";
    (Rock,     Scissors)  => "Rock Wins!";
    (Scissors, Paper)     => "Scissors Wins!";
    (a, b)                => a == b ? "Tie!" : play(b, a)
end
```

## Homoiconic pattern matching for Julia ASTs
Here's a less trivial use of MLStyle.jl for deconstructing and pattern matching Julia code. 
```julia
rmlines = @λ begin
    e :: Expr           => Expr(e.head, filter(x -> x !== :magic_symbol_oh_really, map(rmlines, e.args))...)
      :: LineNumberNode => :magic_symbol_oh_really
    a                   => a
end
expr = quote
    struct S{T}
        a :: Int
        b :: T
    end
end |> rmlines

@match expr begin
    quote
        struct $name{$tvar}
            $f1 :: $t1
            $f2 :: $t2
        end
    end =>
    quote
        struct $name{$tvar}
            $f1 :: $t1
            $f2 :: $t2
        end
    end |> rmlines == expr
end
```

## Generalized Algebraic Data Types

 ```julia
@use GADT

@data public Exp{T} begin
    Sym{A}    :: Symbol                           => Exp{A}
    Val{A}    :: A                                => Exp{A}
    Lam{A, B} :: (Symbol, Exp{B})                 => Exp{Fun{A, B}}
    If{A}     :: (Exp{Bool}, Exp{A}, Exp{A})      => Exp{A}
    App{A, B, A′<:A} :: (Exp{Fun{A, B}}, Exp{A′}) => Exp{B}
end
```

A simple interpreter implemented via GADTs could be found at `test/untyped_lam.jl`.


## Active Patterns

Currently, MLStyle does not have [fully featured](https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/active-patterns) active patterns, but the subset of parametric active patterns that are implemented are very powerful.

```julia
@active Re{r :: Regex}(x) begin
    ret = match(r, x)
    ret !== nothing && return Some(ret)
end

@match "123" begin
    Re{r"\d+"}(x) => x
    _ => @error ""
end # RegexMatch("123")

@active IsEven(x) begin
    x % 2 == 0
end

@match (1, 2, 3) begin
    (1, IsEven, a) => a
end # => 3
```