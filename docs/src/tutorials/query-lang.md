Write You A Query Language
===============================================

You may have heard of LINQ or extension methods before, and they're all embedded query langauges.

In terms of Julia ecosystem, there're Query.jl, LightQuery.jl, DataFramesMeta.jl, etc., each of which reaches the partial or full features of a query language.

This document is provided for you to create a concise and efficient implementation of query langauge,
which is a way for me to exhibit the power of MLStyle.jl on AST manipulations. Additionally, I think this tutorial can be also extremely helpful to those who're developing query languages for Julia.

Definition of Syntaxes
------------------------------

Firstly, we can refer to the the T-SQL syntax and, introduce it into Julia.

```Julia

df |>
@select selectors...,
@where predicates...,
@groupby mappings...,
@orderby mappings...,
@having mappings...,
@limit JuliaExpr

```

A `selector` could be one of the following cases.

1. select the field `x` / select the 1-fst field.

    ```
    _.x
    _.(1)
    ```

2. select the field `x`(to support field name that're not an identifier)

    ```
    _."x"
    ```

3. select the fields that're not `x` / select the fields that're not the first.

    ```
    _.(!x)
    _.(!1)
    ```

4.  select an expression binded as `x + _.x`, where `x` is from current scope

    ```
    x + _.x
    ```

5.  select something and bind it to symbol `a`

    ```
    <selector 1-4> => a
    <selector 1-4> => "a"
    ```
6. select any field `col` that `predicate(col, args...)` is true.

    ```
    _.(predicate(args...))
    ```

7. select any field `col` that `predicate(col, args...)` is false.

    ```
    _.(!predicate(args...))
    ```

With E-BNF notation, we can formalize the synax,

```

FieldPredicate ::= ['!'] QueryExpr '(' QueryExprList ')'

Field          ::=  ['!'] (Symbol | String | Int)


QueryExpr      ::=  '_' '.' Field
                  | <substitute QueryExpr in for JuliaExpr>

QueryExprList  ::= [ QueryExpr (',' QueryExpr)* ]

selector       ::= '_' '.' FieldPredicate
                  | QueryExpr

```

A `predicate` is a `QueryExpr`, but shouldn't be evaluated to a boolean.

A `mapping`  is ap `QueryExpr`, but shouldn't be evaluated to a nothing.

FYI, here're some instances about `selector`.
```
_.foo,
_.(!1),
_.(startswith("bar")),
_.(!startswith("bar")),
x + _.foo,
let y = _.foo + y; y + _.(2) end
```

Codegen Target
--------------------------------

Before implementing code generation, we should have a sketch about the target. The **target** here means the final shape of the code generated from query sentences.


'll take you to the travel within the inference about the final shape of code generation.

Firstly, for we want this:

```julia
df |>
@select _.foo + x, _.bar
```

We can infer out that the generated code is an anonymous function which takes only one argument.

Okay, cool. We've known that the final shape of generated code should be:

```julia
function (ARG)
    # implementations
end
```

Then, let's think about the `select` clause. You might find it's a `map`(if we don't take aggregrate function into consideration). However, for we don't want to
make redundant allocations when executing the queries, so we should use `Base.Generator` as the data representation.

For `@select _.foo + x, _.bar`, it should be generated to something like

```julia
((RECORD[:foo] + x, RECORD[:bar])   for RECORD in SOURCE)
```

Where `SOURCE` is the data representation, `RECORD` is the record(row) of SOURCE, and `x` is the variable captured by the closure.

Now, a smart reader might observe that there's a trick for optimization! If we can have the actual indices of the fields `foo` and `bar` in the record(each row of `SOURCE`), then they can be indexed via integers, which could avoid reflections in some degree.

I don't have much knowledge about NamedTuple's implementation, but indexing via names on unknown datatypes cannot be faster than simply indexing via integers.

So, the generated code of `select` could be
```julia

let idx_of_foo = findfirst(==(:foo), IN_FIELDS),
    idx_of_bar = findfirst(==(:bar), IN_FIELDS),
    ((RECORD[idx_of_foo] + x, RECORD[idx_of_bar]) for RECORD in SOURCE)
end

```

Where we introduce a new requirement of the query's code generation: the field names of input `SOURCE`, `IN_FIELDS`.

Now, to have a consistent code generation, let's think about the stacked `select` clauses.

```julia
df |>
@select _, _.foo + 1, => foo1,
# `select _` here means `SELECT *` in T-SQL.
@select _.foo1 + 2 => foo2
```

I don't know how to explain the iteration in my mind, but I've figured out such a way.

```julia
let (IN_FIELDS, SOURCE) =
    let (IN_FIELDS, SOURCE) = process(df),
        idx_of_foo = findfirst(==(:foo),  IN_FIELDS)
        (IN_FIELDS..., :foo1), ((RECORD..., RECORD[idx_of_foo] + 1) for RECORD in SOURCE)
    end,
    idx_of_foo1 = findfirst(==(:foo1), IN_FIELDS)
    (:foo2, ), ((RECORD[idx_of_foo1] + 2, ) for RECORD in SOURCE)
end
```
Oh, perfect! I'm so excited! That's so beautiful!

If the output field names are a list of meta variables `(:foo2, )`, then output expression inside the comprehension should be a list of terms `(foo2, )`. For `foo2 = _.foo1 + 2` which is generated as `RECORD[idx_of_foo1] + 2`, so it comes to the above code snippet.

Let's think about the `where` clause.

If we want this:
```julia
df |>
@where _.foo < 2
```

That's similar to `select`:

```julia
let (IN_FIELDS, SOURCE) = process(df),
    idx_of_foo = findfirst(==(:foo), IN_FIELDS)
    (IN_FIELDS, (RECORD for RECORD in SOURCE if RECORD[idx_of_foo] < 2))
end
```

Obviously that `where` clauses generated in this way could be stacked.


Next, it's the turn of `groupby`. It could be much more complex, for we should make it consistent with code generation
for `select` and `where`.

Let's think about the case below.

```julia
df |>
@groupby startswith(_.name, "Ruby")  => is_ruby
```

Yep, we want to group data frames(of course, any other datatypes that can be processed via this pipeline) by whether its field `name` starts with a string "Ruby", like "Ruby Rose".

Ha, I'd like to use a dictionary to group it here.

```julia
let IN_FIELDS, SOURCE = process(df)
    @inline function GROUP_FN(RECORD)
        (startswith(_.name, "Ruby"), )
    end
    GROUPS = Dict() # the type issues will be discussed later.
    for RECORD in SOURCE
        GROUP_KEY = (is_ruby, ) = GROUP_FN(RECORD)
        AGGREGATES = get!(GROUPS, GROUP_KEY) do
            [[] for _ in IN_FIELDS]
        end
        push!.(AGGREGATES, RECORD)
    end
    # then output fields and source here
end
```

I think it perfect, so let's go ahead. The reason why we make an inline function would be given
later, I'd disclosed that it's for type inference.

So, what should the output field names and the source be?

An implementation is,

```julia
IN_FIELD, values(GROUPS)
```

But if so, we will lose the information of group keys, that's bad.

So, if we want to persist the group keys, we can do this:

```julia
((:is_ruby, )..., IN_FIELDS...), ((k..., v...) for (k, v) in GROUPS)
```
I think the later could be sufficiently powerful, although it might not be that efficient. You can have
different implementations of `groupby` if you have more specific use cases, just use the extensible system
which will be introduced later.

So, the code generation of `groupby` could be:

```julia
let IN_FIELDS, SOURCE = process(df)
    @inline function GROUP_FN(RECORD)
        (startswith(_.name, "Ruby"), )
    end
    GROUPS = Dict() # the type issues will be discussed later.
    for RECORD in SOURCE
        GROUP_KEY = (is_ruby, ) = GROUP_FN(RECORD)
        AGGREGATES = get!(GROUPS, GROUP_KEY) do
            [[] for _ in IN_FIELDS]
        end
        push!.(AGGREGATES, RECORD)
    end
    ((:is_ruby, ), IN_FIELDS...), ((k..., v...) for (k, v) in SOURCE)
end
```

However, subsequently, we comes to the `having` clause, in fact, I think it's a subclause of
`groupby` clause, which means it cannot take place indenpendently, but co-appear with a `groupby`.

Given such a case:
```julia
df |>
@groupby startswith(_.name, "Ruby")  => is_ruby
@having is_ruby || _.is_rose
```
The generated code should be:

```julia
let IN_FIELDS, SOURCE = process(df),
    idx_of_is_rose = findfirst(==(:is_rose), IN_FIELDS)

    @inline function GROUP_FN(RECORD)
        (startswith(_.name, "Ruby"), )
    end
    GROUPS = Dict() # the type issues will be discussed later.
    for RECORD in SOURCE
        GROUP_KEY = (is_ruby, ) = GROUP_FN(RECORD)
        if is_ruby || RECORD[idx_is_rose]
            continue
        end
        AGGREGATES = get!(GROUPS, GROUP_KEY) do
            [[] for _ in IN_FIELDS]
        end
        push!.(AGGREGATES, RECORD)
    end
    ((:is_ruby, ), IN_FIELDS...), ((k..., v...) for (k, v) in SOURCE)
end
```

That could be achieved very concisely, we'll refer to this later.

After introducing the generation for above 4 clauses, `orderby` and `limit` then become trivial, I don't want to repeat
myself if not necessary.

Now we know that mulitiple clauses could be generated to give a `Tuple` result, first of which is the field names, the
second is the lazy computation of the query. We can resume it to the corresponding types, for instance,

```julia
function (ARG :: DataFrame)
    (IN_FIELDS, SOURCE) = let IN_FIELDS, SOURCE = ...
        ...
    end

    res = Tuple([] for _ in IN_FIELDS)
    for each in SOURCE
        push!.(res, each)
    end
    DataFrame(collect(res), collect(IN_FIELDS))
end
```

Refinement of Codegen: Typed Columns
---------------------------------------------

Last section introduce a framework of code generation for query langauge, but in Julia, there's problem.

Look at the value to be return(when input is a `DataFrame`):

```julia
res = Tuple([] for _ in IN_FIELDS)
for each in SOURCE
    push!.(res, each)
end
DataFrame(collect(res), collect(IN_FIELDS))
```

I can promise you that, each column of your dataframes is a `Vector{Any`, yes, not its actual type.
You may prefer to calculate the type of a column using the common super type of all elements, but there're
2 problems if you try this:

- If the column is empty, emmmm...
- Calculating the super type of all elements does cost much!

So, I'll introduce a new requirement `TYPE` of the query's code generation.

Let's have a look at code generation for `select` after introducing the `TYPE`.

Given that
```julia
@select _, _.foo + 1
```

```julia
return_type(f, t) =
    let ts = Base.return_types(f, (t,))
        length(ts) === 1 ?
            ts[1]        :
            Union{ts...}
    end

infer(TYPE, IN_FIELDS, gen)
    let TYPE_ = return_type(gen.f, TYPE)
        IN_FIELDS, TYPE_, gen
    end

let (IN_FIELDS, TYPE, SOURCE) = process(df),
    idx_of_foo = findfirst(==(:foo),  IN_FIELDS)
    infer(
        TYPE,
        (IN_FIELDS..., :foo1),
        ((RECORD..., RECORD[idx_of_foo] + 1) for RECORD in SOURCE)
    )
end
```

For `groupby`, it could be a bit more complex, but it does nothing new towards what `select` does.

Implementation
------------------------

It's obviously observed that a sequence of query macros should return a function which takes
one argument(object that's able to be queried), so let's think about how to implement code generation.

```Julia
using DataFrames
ARG = Symbol("MQuery.ARG") # we just need limited mangled symbols here.
IN_FIELDS = Symbol("MQuery.IN.FIELDS")
IN_SOURCE = Symbol("MQuery.IN.SOURCE")
ELT = Symbol("MQuery.ELT")
_gen_sym_count = 0

function gen_sym()
    global _gen_sym_count
    let sym = Symbol("MQuery.TMP.", _gen_sym_count)
        _gen_sym_count = _gen_sym_count  + 1
        sym
    end
end

ismacro(x :: Expr) = Meta.isexpr(x, :macrocall)
ismacro(_) = false

function codegen(node :: Expr)
    (generate, args) = @match node begin
        :(@select $(::LineNumberNode) $args) || :(@select $args) =>
            (generate_select, args)
        :(@where $(::LineNumberNode) $args) || :(@where $args)=>
            (generate_where, args)
        :(@groupby $(::LineNumberNode) $args) || :(@groupby $args) =>
            (generate_groupby, args)
        :(@orderby $(::LineNumberNode) $args) || :(@orderby $args) =>
            (generate_orderby, args)

        :(@having $(::LineNumberNode) $args) || :(@having $args) =>
            (generate_having, args)

        :(@limit $(::LineNumberNode) $args) || :(@limit $args) =>
            (generate_limit, args)
    end

    ast_makers = @match args begin
        [args..., function ismacro end && tl] => [generate(args), codegen(tl)...]
        _ => [generate(args)]
    end
    init = quote
         ($names($ARG), $(DataFrames.columns)($ARG))
    end
    fn_body = foldl(ast_makers, init = init) do last, mk
        mk(last)
    end
    quote
        @inline function ($ARG :: $DataFrame)
            $fn_body
        end
    end |> esc
end
```

Since we perform AST pattern matching here, the problem is then divided into 6 parts, and then
we can smoothly make the solution via finishing these 6 functions, `generate_select,
generate_where, generate_groupby, generate_orderby`, `generate_having` , and `generate_limit`.

```Julia

function generate_select(args :: Vector) :: Select
    not_impl
end

function generate_where(args :: Vector) :: Where
    not_impl
end

function generate_groupby(args :: Vector) :: GroupBy
    not_impl
end

function generate_orderby(args :: Vector) :: OrderBy
    not_impl
end

function generate_having(args :: Vector) :: Having
    not_impl
end

function generate_limit(args :: Vector) :: Limit
    not_impl
end
```

The `select` could be the most difficult, so we can start with the easier ones, for examplem, `where`:

```julia

function generate_select(args :: Vector)

    field_getted = Dict{Symbol, Symbol}()
    assign       :: Vector{Any} = []
    value_result :: Vector{Any} = []
    field_result :: Vector{Any} = []

    # visitor to process the pattern `_.x, _,"x", _.(1)` inside an expression
    visit(expr) =
        @match expr begin
            Expr(:. , :_, a) end =>
                let a = a isa QuoteNode ? a.value : a
                    @match a begin
                        Expr(:tuple, a :: Int) => Expr(:ref, ELT, idx_sym)
                        ::String && Do(b = Symbol(a)) || b::Symbol =>
                            get!(idx, a) do
                                idx_sym = gen_sym()
                                field_getted[a] = idx_sym
                                push!(
                                    assign,
                                    Expr(:(=),
                                        idx_sym,
                                        Expr(:call,
                                            findfirst,
                                            x -> x === a,
                                            IN_FIELDS
                                        )
                                    )
                                )
                                idx_sym
                            end |>
                            idx_sym -> Expr(:ref, ELT, idx_sym)
                    end
                end
            Expr(head, args) => Expr(head, map(visit, args))
            a => a
        end

    # process selectors
    foreach(args) do arg
        @match arg begin
            :_ =>
                begin
                    push!(value_result, Expr(:..., ELT))
                    push!(field_result, Expr(:..., IN_FIELDS))
                end

            :(_.(! $pred( $ (args...))))  =>
                let new_field_pack = gen_sym()
                    new_index_pack = gen_sym()
                    push!(Expr(:(=), new_field_pack, :[$ELT for $ELT in $IN_FIELDS if !($pred($ELT, $ (args...)))]))
                    push!(Expr(:(=), new_index_pack, Expr(:call, indexin, new_field_pack, IN_FIELDS)))

                    push!(field_result, Expr(:...,  new_field_pack))
                    push!(value_result, Expr(:...,  :($ELT[$new_index_pack])))

                end
            :(_.($pred( $ (args...))))  =>
                let new_field_pack = gen_sym()
                    new_index_pack = gen_sym()
                    push!(Expr(:(=), new_field_pack, :[$ELT for $ELT in $IN_FIELDS if ($pred($ELT, $ (args...)))]))
                    push!(Expr(:(=), new_index_pack, Expr(:call, indexin, new_field_pack, IN_FIELDS)))

                    push!(field_result, Expr(:...,  new_field_pack))
                    push!(value_result, Expr(:...,  :($ELT[$new_index_pack])))
                end

           :($new_field = $a) || a && Do(new_field = Symbol(string(a))) =>
                let new_value = visit(a)
                    push!(field_result, new_field)
                    push!(value_result, new_value)
                end
        end
    end

    # select expression generation
    inner_expr ->
    Expr(:let,
        Expr(:block,
            Expr(:(=), Expr(:tuple, IN_FIELDS, IN_SOURCE), inner_expr),
            assign...
        ),
        Expr(:tuple,
            Expr(:tuple, field_result...),
            let v = Expr(:tuple, value_result...)
                :[$v for $ELT in $IN_SOURCE]
            end
        )
    )
end

```
