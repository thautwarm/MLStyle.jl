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
- [ADT destructuring, GADTs](#ADT-Destructuring-1)
- [Records](#Records-1)
- [Advanced Type Pattern](#Advanced-Type-Pattern-1)
- [Side Effect](#Side-Effect-1)
- [Let Pattern](#Let-Pattern-1)
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

Note that, by default only symbols given in lower case could be used as capturing.

If you prefer to capture via upper case symbols, you can enable this feature via

```julia
@use UppercaseCapturing
```

Extension `UppercaseCapturing` conflicts with `Enum`.

Any questions about `Enum`, check [Active Patterns](#Active-Pattern-1).


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
    x && GuardBy(pred) => 5 - x # only succeed when x > 5
    _        => 1
end

@match x begin
    x && GuardBy(x -> x > 5) => 5 - x # only succeed when x > 5
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

TODO.

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

ADT Destructuring
---------------

Here is an example, check more about ADTs(and GADTs) at [Algebraic Data Type Syntax in MLStyle](https://thautwarm.github.io/MLStyle.jl/latest/syntax/adt).

```julia

@data Example begin
    Natural(dimension :: Float32, climate :: String, altitude :: Int32)
    Cultural(region :: String,  kind :: String, country :: String, nature :: Natural)
end

神农架 = Cultural("湖北", "林区", "中国", Natural(31.744, "北亚热带季风气候", 3106))
Yellostone = Cultural("Yellowstone National Park", "Natural", "United States", Natural(44.36, "subarctic", 2357))

function my_data_query(data_lst :: Vector{Cultural})
    filter(data_lst) do data
        @match data begin
            Cultural(_, "林区", "中国", Natural(dim=dim, altitude)) &&
            if dim > 30.0 && altitude > 1000 end => true

            Cultural(_, _, "United States", Natural(altitude=altitude)) &&
            if altitude > 2000 end  => true
            _ => false

        end
    end
end
my_data_query([神农架, Yellostone])
...
```

Records
----------------------

```julia
struct A
    a
    b
    c
end
@as_record A

# or just wrap the struct definition with @as_record
# @as_record struct A
#     a
#     b
#     c
# end

@match A(1, 2, 3) begin
    A(1, 2, 3) => ...
end

@match A(1, 2, 3) begin
    A(_) => true
end # always true

@match A(1, 2, 3) begin
    A() => true
end # always true

# field punnings(superior than extracting fields)
@match A(1, 2, 3) begin
    A(;a, b=b) => a + b
end # 3

# extract fields
@match A(1, 2, 3) begin
    A(a=a, b=b) => a + b
end # 3
```

Advanced Type Pattern
-------------------------

We can introduce type parameters via `where` syntax.

```julia
@match 1 begin
    a :: T where T => T
end # => T
```

However, whenever you're using `where`, DO NOT use locally captured type arguments in the right side of `::`, when `::` is directly under a `where`.


**Wrong use**:

```julia
@match (1, (2, 3)) begin
    (::T1 where T1, ::Tuple{T1, T2} where T2) => (T1, T2)
end
# T1 not defined
```

Workaround 1:

```julia
@match (1, (2, 3)) begin
    (::T1 where T1, ::Tuple{T1′, T2} where {T1′, T2}) &&
     if T1′ == T1 end => (T1, T2)
end
# (Int64, Int64)
```

Workaround 2:

```julia
@match (1, (2, 3)) begin
    (::T1, (::T1, ::T2)) :: Tuple{T1, Tuple{T1, T2}} where {T1, T2} =>
        (T1, T2)
end
# (Int64, Int64)
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

**P.S 1**: when assigning variables with `Do`, don't do `Do((x, y) = expr)`, use this: `Do(x = expr[1], y = expr[2])`. Our pattern compile needs to aware the scope change!

**P.S 2**: `Do[x...]` is an eye candy for `Do(x)`, and so does `Many[x]` for `Many(x)`. **HOWEVER**, do not use `begin end` syntax in `Do[...]` or `Many[...]`. Julia restricts the parser and it'll not get treated as a `begin end` block.

**P.S 3**: The [`let` pattern](#Let-Pattern-1) is different from the `Do` pattern.

- `Do[x=y]` changes `x`, but `let x = y end` shadows `x`. `let` may also change a variable's value. Check the documents of `@switch` macro.

- You can write non-binding in `Do`: `Do[println(1)]`, but you cannot do this in `let` patterns.


Let Pattern
-------------------

```julia
@match 1 begin
    let x = 1 end => x
end
```

Bind a variable without changing the value of existing variables, i.e., `let` patterns shadow symbols.

`let` may also change a variable's value. Check the documents of `@switch` macro.

Active Pattern
------------------

This implementation is a subset of [F# Active Patterns](https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/active-patterns).

There're 3 distinct active patterns, first of which is the normal form:

```julia
# 1-ary deconstruction: return Union{Some{T}, Nothing}
@active LessThan0(x) begin
    if x >= 0
        nothing
    else
        Some(x)
    end
end

@match 15 begin
    LessThan0(a) => a
    _ => 0
end # 0

@match -15 begin
    LessThan0(a) => a
    _ => 0
end # -15

# 0-ary deconstruction: return Bool
@active IsLessThan0(x) begin
    x < 0
end

@match 10 begin
    IsLessThan0() => :a
    _ => :b
end # b

# (n+2)-ary deconstruction: return Tuple{E1, E2, ...}
@active SplitVecAt2(x) begin
    (x[1:2], x[2+1:end])
end

@match [1, 2, 3, 4, 7] begin
    SplitVecAt2(a, b) => (a, b)
end
# ([1, 2], [3, 4, 7])

```

Above 3 cases can be enhanced by becoming **parametric**:

```julia

@active SplitVecAt{N::Int}(x) begin
    (x[1:N], x[N+1:end])
end

@match [1, 2, 3, 4, 7] begin
    SplitVecAt{2}(a, b) => (a, b)
end
# ([1, 2], [3, 4, 7])

@active Re{r :: Regex}(x) begin
    res = match(r, x)
    if res !== nothing
        # use explicit `if-else` to emphasize the return should be Union{T, Nothing}.
        Some(res)
    else
        nothing
    end
end

@match "123" begin
    Re{r"\d+"}(x) => x
    _ => @error ""
end # RegexMatch("123")

```

Sometimes the enum syntax is useful and convenient:

```julia
@active IsEven(x) begin
    x % 2 === 0
end

MLStyle.is_enum(::Type{IsEven}) = true

@match 6 begin
    IsEven => :even
    _ => :odd
end # :even
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
@assert :f == extract_name(:(
    function f()
        1 + 1
    end
))
```


Ast Pattern
--------------------------

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

Additionally, you can use any other patterns simultaneously when matching asts. In fact, there're regular patterns inside a `$` expression of your ast pattern.

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
    end && if isempty(block1 && isempty(block2) end =>

         Dict(:funcname => funcname,
              :firstarg => firstarg,
              :args     => args,
              :last_operand => last_operand,
              :other_bindings => other_bindings,
              :app_fn         => app_fn,
              :app_arg        => app_arg)
end

# Dict{Symbol,Any} with 7 entries:
#   :app_fn         => :e
#   :args           => Any[:b, :c]
#   :firstarg       => :a
#   :funcname       => :f
#   :other_bindings => Any[:(e = (x->begin…
#   :last_operand   => :c
#   :app_arg        => :d
```

Here is several articles about Ast Patterns.

- [A Modern Way to Manipulate ASTs](https://www.reddit.com/r/Julia/comments/ap4xwr/mlstylejl_a_modern_way_to_manipulate_asts/).

- [An Elegant and Efficient Way to Extract Something from ASTs](https://discourse.julialang.org/t/an-elegant-and-efficient-way-to-extract-something-from-asts/19123).


