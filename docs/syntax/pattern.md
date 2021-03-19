Pattern Matching
=======================

Pattern matching provides convenient ways to manipulate data. The basic syntax for pattern matching with MLStyle is of the form
```julia
@match data begin
    pattern1 => result1
    pattern2 => result2
    ...
    patternn => resultn
end
```
MLStyle will first test if `data` is matched by `pattern1` and if it does match, return `result1`. If `pattern1` does not match, then MLStyle moves on to the next pattern in sequence. If no pattern in the list matches `data`, an error is thrown.

In version 0.4.1 and newer, if you only have a single pattern you may instead write
```julia
@match data pattern => result
```
without the block syntax.


Literal Patterns
------------------------

Patterns with a literal (e.g. `1`, `false`, `nothing`, `4.0`, `1f-6`, etc) on the left hand side will check if the the argument is equal to that literal:

```julia-console
julia> @match 10 begin
           1  => "wrong!"
           2  => "wrong!"
           10 => "right!"
       end
"right!"
```
All literal data introduced with Julia syntax can be matched by literal patterns.

However, note that the equality is strict for primitive types(`Int8-64`, `UInt8-64`, `Bool`, etc.) and singleton types(`struct Data end; Data()`).

Specifically, **substrings can match a literal string.**

Capturing Patterns
--------------------------

A pattern where there is a symbol such as `x` on the left hand side will bind the input value to that symbol and let you use that captured value on the right hand side

```julia-console
julia> @match 1 begin
           x => x + 1
       end
2
```
You can put `_` on the left hand side of a pattern if you don't care about what the captured value is.

However, sometimes a symbol might not be used for capturing. If and only if some visible global variable `x` satisfying `MLStyle.is_enum(x) == true`, `x` is used as an enum pattern.

Check [Custom Patterns](#custom-patterns) for details.

Type Patterns
-----------------

Writing `::Foo` on the left hand side of a pattern will match if the input is of type `Foo`. You can conbine this with a literal pattern by writing `x::Foo` which will match inputs of type `Foo` and bind them to a variable `x`.

```julia-console
julia> @match 1 begin
           ::Float64  => nothing
           b :: Int => b
           _        => nothing
       end
1
```

Guards
--------------------

Writing `if cond end` as a pattern will match if `cond==true`

```julia-console
julia> @match 1.0 begin
           if 1 < 5 end  => √(5 - 1)
       end
2.0
```

Unlike most of ML languages or other libraries who only permit guards in the end of a case clause,
MLStyle.jl allows you to put guards anywhere during matching.

However, remember, due to some Julia optimization details, even if the guards can be put
in the middle of a matching process, it is still better to postpone it until the end of matching sequence. This allows for better performance.

Sometimes, in practice, you might want to introduce type variables into the scope, in this case use `where` clause, and see [Advanced Type Patterns](#advanced-type-patterns) for more details.


And-Patterns
--------------------

`pat2 && pat2` on the left hand side of a pattern will match if and only if `pat1` and `pat2` match individually. This lets you combine two separate patterns together,

```julia-console
julia> @match 2 begin
           x::Int && if x < 5 end => √(5 - x)
       end
1.7320508075688772
```

- As Pattern

Writing `pat && x` on the left hand side of a pattern will bind the input to `x` if `pat` matches the input, allowing the input to be used on the right hand side. This is sometimes called an As-Pattern in ML derived languages, but in MLStyle, it is just a subset of the functionality in the And-Pattern

```julia
julia> @match (1, 2) begin
           (a, b) && c => c[1] == a && c[2] == b
       end
true
```

Destructuring Tuples, Arrays, and Dictionaries with Pattern Matching
---------------------

- Tuple Patterns

```julia-console
julia> @match (1, 2, (3, 4, (5, ))) begin
           (a, b, (c, d, (5, ))) => (a, b, c, d)
       end
(1, 2, 3, 4)
```

- Array Patterns

```julia-console
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

julia> @match Int[1, 2] begin
         Any[1, 2] => :a
         Int[_, _] => :b
       end
:b
```

- Dict pattern(like `Elixir`'s dictionary matching or ML record matching)

```julia-console
julia> dict = Dict(1 => 2, "3" => 4, 5 => Dict(6 => 7))
Dict{Any,Any} with 3 entries:
  1   => 2
  5   => Dict(6=>7)
  "3" => 4

julia> @match dict begin
           Dict("3" => four::Int,
                 5  => Dict(6 => sev)) && if four < sev end => sev
       end
7
```

Note that, due to the lack of an operation for distinguishing `nothing` from "key not found" in Julia's standard library, the dictionary pattern has a little overhead. This will be resolved after [Julia#34821](https://github.com/JuliaLang/julia/pull/34821) is completed.

**P.S**:  MLStyle will not refer an external package to solve this issue, as MLStyle is generating "runtime support free" code, which means that any code generated by MLStyle itself depends only on Stdlib. This feature allows MLStyle to be introduced as a dependency only in development, instead of being distributed together to downstream codes.

Deconstruction of Custom Composite Data
-------------------------------------------

In order to deconstruct arbitrary data types in a similar way to `Tuple`, `Array` and `Dict`, simply declare them to be record types with the `@as_record` macro.

Here is an example, check more about ADTs(and GADTs) at [Algebraic Data Type Syntax in MLStyle](https://thautwarm.github.io/MLStyle.jl/latest/syntax/adt).

```julia-console
julia> @data Color begin
         RGB(r::Int, g::Int, b::Int)
         Gray(Int)
       end

julia> # treating those types as records for more flexible pattern matching

julia> @as_record RGB

julia> @as_record Gray

julia> color_to_int(x) = @match x begin
           RGB(;r, g, b) => 16 + b + 6g + 36r
           Gray(i)       => 232 + i
       end
color_to_int (generic function with 1 method)

julia> RGB(200, 0, 200) |> color_to_int
7416

julia> Gray(10)         |> color_to_int
242
```

In above cases, after `@as_record T`, we can use something called [field punning](https://dev.realworldocaml.org/records.html#field-punning) to match structures very conveniently.

```julia
@match rbg_datum begin
    RGB(;r) && if r < 20 end => ...
    RGB(;r, g) && if 10r < g end => ...
    ...
end
```

As you can see, field punning can be partial.

Predicates
---------------

Equivalent to guard patterns, writing `GuardBy(f)` in a pattern will match if and only if `f` applied to the pattern matching input gives true:

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

Range Patterns
--------------------

```julia-console
julia> @match 1 begin
           0:2:10 => 1
           1:10 => 2
       end
2
```

Reference Patterns
-----------------

This feature is from `Elixir` which could slightly extends ML based pattern matching.

```julia
c = ...
@match (x, y) begin
    (&c, _)  => "x equals to c!"
    (_,  &c) => "y equals to c!"
    _        => "none of x and y equal to c"
end
```


Macro Call Patterns
------------------------

By default, macro calls occur in patterns will be no different than its expanded expression, hence the following bidirectional relationship **sometimes** holds:

```julia-console
julia> macro mymacro(a)
         esc(:([$a]))
       end
@mymacro (macro with 1 method)

julia> a = 2
2

julia> a == @match @mymacro(a) begin
                @mymacro(a) => a
            end
true

# expanded form:
# julia> a == @match [a] begin
#                [a] => a
#            end
```

However, you can also change the pattern compilation behavior by overloading `MLStyle.pattern_unmacrocall`, whose usage can be found at the implementation of the pattern support for [`@r_str`](https://github.com/thautwarm/MLStyle.jl/blob/master/src/Pervasives.jl#L191).

Some examples about string macro patterns:

```julia
@match  raw"$$$" begin
    raw"$$$" => ...
end

@match "123" begin
    r"\G\d+$" => ...
end
```

Custom Patterns
--------------

As we've suggested in [Capturing-Patterns](#capturing-patterns),
you can always define your own patterns with MLStyle and easily leverge our compiler and optimizer.

You can extend following APIs for your pattern objects, to implement custom patterns:

- `MLStyle.pattern_uncall`
  - args:
    - `pat_obj`

       your pattern object, should be a global variable in some module. The pattern is visible if and only if the global variable is visible in current scope.
    -  `expr_to_pat::Function`

       this is provided for you to transform an AST into patterns, for instance, `expr_to_pat(:([a, 1]))`, with which you create a pattern same as `[a, 1]`.

    -  `type_params`
    -  `type_args`
    -  `args`
  
  - usage
  
    We compile the AST `pat_obj{c, d}(e, f) where {a, b}` into
    the pattern with `MLStyle.pattern_uncall(pat_obj, expr_to_pat, [:a, :b], [:c, :d], [:e, :f])`.

- `MLStyle.pattern_unref`
  - args:
    - `pat_obj`
    - `expr_to_pat`
    - `args`
  - usage

    We compile the AST `pat_obj[a, b]` into patterns with
    `MLStyle.pattern_unref(pat_obj, expr_to_pat, [:a, :b]`.

- `MLStyle.is_enum`
  
   In a pattern `[A, B]`, usually we think both `A` and `B` are capturing patterns. However, it is handy if we can have a pattern `A` whose match means comparing to the global variable `A`.

   To achieve this, we provide `MLStyle.is_enum`.
   For a visible global variable `A`, if `MLStyle.is_enum(A) == true`, a symbol `A` will compile into a pattern with `MLStyle.pattern_uncall(A, expr_to_ast, [], [], [])`.

We present some examples for understandability:

### Support Pattern Matching for Julia Enums

```julia-console
julia> using MLStyle.ActivePatterns: literal
julia> @enum E E1 E2
# mark E1, E2 as non-capturing patterns
julia> MLStyle.is_enum(::E) = true
# tell the compiler how to match E1, E2
julia> MLStyle.pattern_uncall(e::E, _, _, _, _) = literal(e)
julia> x = E2
julia> @match x begin
           E1 => "match E1!"
           E2 => "match E2!"
       end
"match E2!"
x = E1
julia> @macroexpand @match x begin
                  E1 => "match E1!"
                  E2 => "match E2!"
        end
"match E1!"
```

### Pattern Synonyms

[pattern synonyms](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/pattern_synonyms.html) is a tasty feature in Haskell programming language for defining patterns based on existing patterns.

We can support it:

suppose we want to regard `Triple` as a pattern `(_, _, _)`

```julia-console
julia> struct Triple end
julia> MLStyle.pattern_uncall(::Type{Triple}, expr_to_ast, _, _, _) =
            expr_to_ast(:(  (_, _, _)  ))
julia> @match (1, 2) begin
            Triple => "triple"
            _ => "no a triple"
        end

"no a triple"

julia> @match (1, 2, 3) begin
            Triple => "triple"
            _ => "no a triple"
        end

"triple"
```

[Active Patterns](#active-patterns) and [ADTs](https://thautwarm.github.io/MLStyle.jl/latest/syntax/adt.html#cheat-sheet) are implemented via custom patterns.

The custom patterns gives us so-called **extensible pattern matching**.

Or Patterns
-------------------

Writing `pat1 || pat2` will match if either `pat1` *or* `pat2` match. If `pat1` matches, MLStyle will not attempt to match `pat2`.

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

Tips: `Or Pattern`s could be nested.


Advanced Type Patterns
-------------------------

We can introduce type parameters via `where` syntax.

```julia
@match 1 begin
    a :: T where T => T
end # => Int64
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

Some other examples:

```julia-console
julia> @match 1 begin
           ::T where T => T
       end
Int64

julia> @match 1 begin
           ::T where T <: Number => T
       end
Int64

julia> @match 1 begin
           ::T where T <: AbstractFloat => T
       end
ERROR: matching non-exhaustive, at #= REPL[n]:1 =#
```

Do-Patterns & Many-Patterns
-----------------------

To introduce side-effects into pattern matching, we provide a built-in pattern called `Do` pattern to achieve this.

Also, a pattern called `Many` can work with `Do` pattern in a perfect way.

```julia
@match [1, 2, 3] begin
    Many(::Int) => true
    _ => false
end # true

@match [1, 2, 3,  "a", "b", "c", :a, :b, :c] begin
    Do(count = 0) &&
    Many[
        a::Int && Do(count = count + a) ||
        ::String                        ||
        ::Symbol && Do(count = count + 1)
    ] => count
end # 9
```

`Do` and `Many` may be not used very often but quite convenient for some specific domain.

**P.S 1**: when assigning variables with `Do`, don't do `Do((x, y) = expr)`, use this: `Do(x = expr[1], y = expr[2])`. Our pattern compile needs to aware the scope change!

**P.S 2**: `Do[x...]` is an eye candy for `Do(x)`, and so does `Many[x]` for `Many(x)`. **HOWEVER**, do not use `begin end` syntax in `Do[...]` or `Many[...]`. Julia restricts the parser and it'll not get treated as a `begin end` block.

**P.S 3**: The [`let` pattern](#let-patterns) is different from the `Do` pattern.

- `Do[x=y]` changes `x`, but `let x = y end` shadows `x`. `let` may also change a variable's value. Check the documents of `@switch` macro.

- You can write non-binding in `Do`: `Do[println(1)]`, but you cannot do this in `let` patterns.

Let Patterns
-------------------

```julia
@match 1 begin
    let x = 1 end => x
end
```

Bind a variable without changing the value of existing variables, i.e., `let` patterns shadow symbols.

`let` may also change a variable's value. Check the documents of `@switch` macro.

Active Patterns
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

Expr Patterns
-------------------

This is mainly for AST manipulations. In fact, another pattern informally called "Ast pattern", would be translated into Expr patterns.

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


Julia Code as Expr Patterns
--------------------------

For convenience I call this "AST pattern", note it's not a formal name.

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

Additionally, you can use any other patterns simultaneously when matching ASTs. In fact, there are regular patterns inside a `$` expression of your AST pattern.

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
    end && if isempty(block1) && isempty(block2) end =>

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

If you are interested, here are several useful articles about AST Patterns:

- [A Modern Way to Manipulate ASTs](https://www.reddit.com/r/Julia/comments/ap4xwr/mlstylejl_a_modern_way_to_manipulate_asts/).

- [An Elegant and Efficient Way to Extract Something from ASTs](https://discourse.julialang.org/t/an-elegant-and-efficient-way-to-extract-something-from-asts/19123).
