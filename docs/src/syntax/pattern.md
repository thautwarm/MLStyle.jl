Pattern
=======================

- [Literal Pattern](#Literal-Pattern-1)
- [Capturing pattern](#Capturing-Pattern-1)
- [Type Pattern](#Type-Pattern-1)
- [As-Pattern, And Pattern](#As-Pattern-1)
- [Guard](#Guard-1)
- [Range Pattern](#Range-Pattern-1)
- [Predicate](#Predicate-1)
- [Reference Pattern](#Reference-Pattern-1)
- [Custom Pattern, Dict, Tuple, Array](#Custom-Pattern-1)
- [Or Pattern](#Or-Pattern-1)
- [ADT destructing, GADTs](#ADT-Destructing-1)
- [Advanced Type Pattern](#Advanced-Type-Pattern-1)
- [Side Effect](#Side-Effect-1)
- [Active Pattern](#Active-Pattern-1)
- [Expr Pattern](#Expr-Pattern-1)
- [Ast Pattern](#Ast-Pattern-1)

Patterns provide convenient ways to manipulate data.

Literal Pattern
------------------------

```julia


@match 10 {
    1  => "wrong!"
    2  => "wrong!"
    10 => "right!"
}

# => "right"
```
There are 3 distinct types whose literal data could be used as literal patterns:

- `Number`
- `AbstractString`
- `Symbol`

Capturing Pattern
--------------

```julia

@match 1 begin
    x => x + 1
end
# => 2
```

Type Pattern
-----------------

```julia

@match 1 begin
    ::Float  => nothing
    b :: Int => b
    _        => nothing
end
# => 1
```

There is an advanced version of `Type-Pattern`s, which you can destruct types with fewer limitations. Check [Advanced Type Pattern](#Advanced-Type-Pattern-1).

As-Pattern
----------

`As-Pattern` can be expressed with `And-Pattern`.

```julia
@match (1, 2) begin
    (a, b) && c => c[1] == a && c[2] == b
end
```


Guard
-----

```julia

@match x begin
    x && if x > 5 end => 5 - x # only succeed when x > 5
    _        => 1
end
```

Predicate
---------------

The following has the same semantics as the above snippet.

```julia

function pred(x)
    x > 5
end

@match x begin
    x && function pred end => 5 - x # only succeed when x > 5
    _        => 1
end

@match x begin
    x && function (x) x > 5 end => 5 - x # only succeed when x > 5
    _        => 1
end

```


Range Pattern
--------------------
```julia
@match 1 begin
    0:2:10 => 1
    1:10 => 2
end # 2
```

Reference Pattern
-----------------

This feature is from `Elixir` which could slightly extends ML pattern matching.

```julia
c = ...
@match (x, y) begin
    (&c, _)  => "x equals to c!"
    (_,  &c) => "y equals to c!"
    _        => "none of x and y equal to c"
end
```


Custom Pattern
--------------

Not recommend to do this for it's implementation specific.
If you want to make your own extensions, check [Pervasives.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/src/Pervasives.jl).

Defining your own patterns using the low level APIs is quite easy,
but exposing the implementations would cause compatibilities in future development.



Dict, Tuple, Array
---------------------

- Dict pattern(like `Elixir`'s dictionary matching or ML record matching)

```julia
dict = Dict(1 => 2, "3" => 4, 5 => Dict(6 => 7))
@match dict begin
    Dict("3" => four::Int,
          5  => Dict(6 => sev)) && if four < sev end => sev
end
# => 7
```

- Tuple pattern

```julia

@match (1, 2, (3, 4, (5, ))) begin
    (a, b, (c, d, (5, ))) => (a, b, c, d)

end
# => (1, 2, 3, 4)
```

- Array pattern(much more efficient than Python for taking advantage of array views)

```julia
julia> it = @match [1, 2, 3, 4] begin
         [1, pack..., a] => (pack, a)
       end
([2, 3], 4)

julia> first(it)
2-element view(::Array{Int64,1}, 2:3) with eltype Int64:
 2
 3
julia> it[2]
4
```


Or Pattern
-------------------

```julia
test(num) =
    @match num begin
       ::Float64 ||
        0        ||
        1        ||
        2        => true

        _        => false
    end

test(0)   # true
test(1)   # true
test(2)   # true
test(1.0) # true
test(3)   # false
test("")  # false
```

Tips: `Or Pattern`s could nested.

ADT Destructing
---------------

You can match `ADT` in following 3 means:

```julia

C(a, b, c) => ... # ordered arguments
C(b = b) => ...   # record syntax
C(_) => ...       # wildcard for destructing

```

Here is an example:

```julia

@data Example begin
    Natural(dimension :: Float32, climate :: String, altitude :: Int32)
    Cutural(region :: String,  kind :: String, country :: String, nature :: Natural)
end

神农架 = Cutural("湖北", "林区", "中国", Natural(31.744, "北亚热带季风气候", 3106))
Yellostone = Cutural("Yellowstone National Park", "Natural", "United States", Natural(44.36, "subarctic", 2357))

function my_data_query(data_lst :: Vector{Cutural})
    filter(data_lst) do data
        @match data begin
            Cutural(_, "林区", "中国", Natural(dim=dim, altitude)) &&
            if dim > 30.0 && altitude > 1000 end => true

            Cutural(_, _, "United States", Natural(altitude=altitude)) &&
            if altitude > 2000 end  => true
            _ => false

        end
    end
end
my_data_query([神农架, Yellostone])
...
```

- About GADTs

```julia
@use GADT

@data internal Example{T} begin
    A{T} :: (Int, T) => Example{Tuple{Int, T}}
end

@match A(1, 2) begin
    A{T}(a :: Int, b :: T) where T <: Number => (a == 1 && T == Int)
end

```

Advanced Type Pattern
-------------------------

Instead of `TypeLevel` feature used in v0.1, an ideal type-stable way to destruct types now is introduced here.

```julia
@match 1 begin
    ::String => String
    ::Int => Int
end
# => Int64

@match 1 begin
    ::T where T <: AbstractArray => 0
    ::T where T <: Number => 1
end

# => 0

struct S{A, B}
    a :: A
    b :: B
end

@match S(1, "2") begin
    ::S{A} where A => A
end
# => Int64

@match S(1, "2") begin
    ::S{A, B} where {A, B <: AbstractString} => (A, B)
end
# => (Int64, String)

```


Side-Effect
-----------------------

To introduce side-effects into pattern matching, we provide a built-in pattern called `Do` pattern to achieve this.
Also, a pattern called `Many` can work with `Do` pattern in a perfect way.


Do-Pattern and Many-Pattern
--------------------

```julia

@match [1, 2, 3] begin
    Many(::Int) => true
    _ => false
end # true

@match [1, 2, 3,  "a", "b", "c", :a, :b, :c] begin
    Do(count = 0) &&
    Many(
        a::Int && Do(count = count + a) ||
        ::String                        ||
        ::Symbol && Do(count = count + 1)
    ) => count
end # 9
```

They may be not used very often but quite convenient for some specific domain.

Active Pattern
------------------

This implementation is a subset of [F# Active Patterns](https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/active-patterns).

There're 2 distinct active patterns, first of which is the normal form:

```julia
@active LessThan0(x) begin
    if x > 0
        nothing
    else
        x
    end
end

@match 15 begin
    LessThan0(_) => :a
    _ => :b
end # :b

@match -15 begin
    LessThan0(a) => a
    _ => 0
end # -15

```

The second is the parametric version.

```julia
@active Re{r :: Regex}(x) begin
    match(r, x)
end

@match "123" begin
    Re{r"\d+"}(x) => x
    _ => @error ""
end # RegexMatch("123")
```

Expr Pattern
-------------------

This is mainly for AST manipulations. In fact, another pattern called Ast Pattern, would be translated into Expr Pattern.

```julia
function extract_name(e)
        @match e begin
            ::Symbol                           => e
            Expr(:<:, a, _)                    => extract_name(a)
            Expr(:struct, _, name, _)          => extract_name(name)
            Expr(:call, f, _...)               => extract_name(f)
            Expr(:., subject, attr, _...)      => extract_name(subject)
            Expr(:function, sig, _...)         => extract_name(sig)
            Expr(:const, assn, _...)           => extract_name(assn)
            Expr(:(=), fn, body, _...)         => extract_name(fn)
            Expr(expr_type,  _...)             => error("Can't extract name from ",
                                                        expr_type, " expression:\n",
                                                        "    $e\n")
        end
end
@assert extract_name(:(quote
    function f()
        1 + 1
    end
end)) == :f
```


Ast Pattern
--------------------------

This might be the most important update since v0.2.

```julia
rmlines = @λ begin
    e :: Expr           -> Expr(e.head, filter(x -> x !== nothing, map(rmlines, e.args))...)
      :: LineNumberNode -> nothing
    a                   -> a
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
end # true
```

**How you create an AST, then how you match them.**

**How you use AST interpolations(`$` operation), then how you use capturing patterns on them.**

The pattern `quote .. end` is equivalent to `:(begin ... end)`.

Additonally, you can use any other patterns simultaneously when matching asts. In fact, there're regular patterns inside a `$` expression of your ast pattern.

A more complex example presented here might help with your comprehension about this:

```julia
ast = quote
    function f(a, b, c, d)
      let d = a + b + c, e = x -> 2x + d
          e(d)
      end
    end
end

@match ast begin
    quote
        $(::LineNumberNode)

        function $funcname(
            $firstarg,
            $(args...),
            $(a && if islowercase(string(a)[1]) end))

            $(::LineNumberNode)
            let $bind_name = a + b + $last_operand, $(other_bindings...)
                $(::LineNumberNode)
                $app_fn($app_arg)
                $(block1...)
            end

            $(block2...)
        end
    end && if (isempty(block1) && isempty(block2)) end =>

         Dict(:funcname => funcname,
              :firstarg => firstarg,
              :args     => args,
              :last_operand => last_operand,
              :other_bindings => other_bindings,
              :app_fn         => app_fn,
              :app_arg        => app_arg)
end
```


Here is an article about this [Ast Pattern](https://discourse.julialang.org/t/an-elegant-and-efficient-way-to-extract-something-from-asts/19123).
