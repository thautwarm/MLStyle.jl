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

Firstly, we should define the constants and help functions, you can jump over here, and when you have
problems with your following reading, you can go back and refer to what you want.

```Julia
using MLStyle
using DataFrames

ARG = Symbol("MQuery.ARG") # we just need limited mangled symbols here.
TYPE = Symbol("MQuery.TYPE")
TYPE_ROOT = Symbol("MQuery.TYPE_ROOT")

IN_FIELDS = Symbol("MQuery.IN.FIELDS")
SOURCE = Symbol("MQuery.IN.SOURCE")
RECORD = Symbol("MQuery.RECORD")
N = Symbol("MQuery.N")
GROUPS = Symbol("MQuery.GROUPS")
GROUP_KEY = Symbol("MQuery.GROUP_KEY")
GROUP_FN = Symbol("MQuery.GROUP_FN")
AGG = Symbol("MQuery.AGG")
_gen_sym_count = 0

const MAX_FIELDS = 10
function gen_sym()
    global _gen_sym_count
    let sym = Symbol("MQuery.TMP.", _gen_sym_count)
        _gen_sym_count = _gen_sym_count  + 1
        sym
    end
end

function return_type(f, t)
    ts = Base.return_types(f, (t,))
    if length(ts) === 1
        ts[1]
    else
        Union{ts...}
    end
end

for i = 1:MAX_FIELDS
    types = [Symbol("T", j) for j = 1:i]
    inp = :(Type{Tuple{$(types...)}})
    out = Expr(:vect, [:(Vector{$t}) for t in types]...)
    @eval type_aggregate(n::Int, ::$inp) where {$(types...)} = $out
end

type_aggregate(n::Int, ::Type{Any}) = fill(Vector{Any}, n)

@inline function infer(::Type{T}, fields :: NTuple{N, Symbol}, gen :: Base.Generator) where {N, T}
    out_t = return_type(gen.f, T)
    (fields, out_t, gen)
end

for i = 1:MAX_FIELDS
    types = [Symbol("T", j) for j = 1:i]
    inp = :(Type{Tuple{$(types...)}})
    out = Expr(:vect, types...)
    @eval type_unpack(n::Int, ::$inp) where {$(types...)} = $out
end

function type_unpack(n::Int, x :: Type{Any})
    fill(Any, n)
end

function query_routine(assigns, result)
    inner_expr ->
    Expr(:let,
         Expr(:block,
              Expr(:(=), Expr(:tuple, IN_FIELDS, TYPE, SOURCE), inner_expr),
              assigns...
          ),
         result
     )
end
```

Then we should extract all clauses from a piece of given julia codes.

Given following codes,
```julia
@select args1,
@where args2,
@select args3
```
, we transform them into

```julia
[(generate_select, args), (generate_where, args2), (generate_select, args3)]
```



```julia
ismacro(x :: Expr) = Meta.isexpr(x, :macrocall)
ismacro(_) = false

function generate_select
end
function generate_where
end
function generate_groupby
end
function generate_orderby
end
function generate_having
end
function generate_limit
end

const registered_ops = Dict{Symbol, Any}(
    Symbol("@select") => generate_select,
    Symbol("@where") => generate_where,
    Symbol("@groupby") => generate_groupby,
    Symbol("@having") => generate_having,
    Symbol("@limit") => generate_limit,
    Symbol("@orderby") => generate_orderby
)

function get_op(op_name)
    registered_ops[op_name]
end

ismacro(x :: Expr) = Meta.isexpr(x, :macrocall)
ismacro(_) = false

function flatten_macros(node :: Expr)
    @match node begin
    Expr(:macrocall, op :: Symbol, ::LineNumberNode, arg) ||
    Expr(:macrocall, op :: Symbol, arg) =>

    @match arg begin
    Expr(:tuple, args...) || a && Do(args = [a]) =>

    @match args begin
    [args..., tl && if ismacro(tl) end] => [(op |> get_op, args), flatten_macros(tl)...]
    _ => [(op |> get_op, args)]
    end
    end
    end
end
```

Then, we should generate the final code from such a sequence given as the return of `flatten_macros`.

Note that `get_records`, `get_fields` and `build_result` should be implemented by your own to support
the datatype you want to query on.

```julia
function codegen(node)
    ops = flatten_macros(node)

    let rec(vec) =
        @match vec begin
            [] => []
            # we should mark it as a corner case for
            # where a `groupby` clause is followed by a `having` clause.
            [(&generate_groupby, args1), &(generate_having, args2), tl...] =>
                [generate_groupby(args1, args2), rec(tl)...]
            [(hd, args), tl...] =>
                [hd(args), rec(tl)...]
        end
        init = quote
            let iter = $get_records($ARG),
                fields = $get_fields($ARG),
                typ = $eltype(iter)

                (fields, typ, iter)
            end
        end
        fn_body = foldl(rec(ops), init = init) do last, mk
            mk(last)
        end
        quote
            @inline function ($ARG :: $TYPE_ROOT, ) where {$TYPE_ROOT}
                let (fields, typ, source) = $fn_body
                    build_result(
                        $TYPE_ROOT,
                        fields,
                        $type_unpack($length(fields), typ),
                        source
                    )
                end
            end
        end
    end
end
```

Then, we need a visitor to transform the patterns shaped as `_.foo` inside an expression to `RECORD[idx_of_foo]`:

```julia
# visitor to process the pattern `_.x, _,"x", _.(1)` inside an expression
function mk_visit(field_getted, assign)
        visit = expr ->
        @match expr begin
            :(_.$a) =>
                let a = a isa QuoteNode ? a.value : a
                    @match a begin
                        Expr(:tuple, a :: Int) => Expr(:ref, RECORD, a)
                        ::String && Do(b = Symbol(a)) || b::Symbol =>
                        Expr(:ref,
                            RECORD,
                            get!(field_getted, a) do
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
                            end
                        )

                    end
                end
            Expr(head, args...) => Expr(head, map(visit, args)...)
            a => a
        end
end
```

You might not know what's the meanings of `field_getted` and `assign`, I'm to explain it for you.

- `field_getted : Dict{Symbol, Symbol}`

    Think about you want such a query `@select _.foo * 2, _.foo + 2`, the `foo` field is referred twice, but you
    shouldn't make 2 symbols to represent the index of `foo` field. So I introduce a dictionary `field_getted` here to
    avoid re-calculation.

- `assign : Vector{Expr}`

    When you want to bind the index of `foo` to a given symbol `idx_of_foo`, you should push an expressison
    `$idx_of_foo = $findfirst(==(:foo), $IN_FIELDS)` to `assign`.

    Finally, `assign` would be generated to the binding section of
    a `let` sentence.


Now, following previous discussions, we can firstly implement the easiest one, `where` clause.

```julia
function generate_where(args :: AbstractArray)
    field_getted = Dict{Symbol, Symbol}()
    assign       :: Vector{Any} = []
    visit = mk_visit(field_getted, assign)

    pred = foldl(args, init=true) do last, arg
        boolean = visit(arg)
        if last === true
            boolean
        else
            Expr(:&&, last, boolean)
        end
    end

    # where expression generation
    query_routine(
        assign,
        Expr(:tuple,
             IN_FIELDS,
             TYPE,
             :($RECORD for $RECORD in $SOURCE if $pred)
        )
    )
end
```

Then `select`:

```julia
function generate_select(args :: AbstractArray)

    field_getted = Dict{Symbol, Symbol}()
    assign       :: Vector{Any} = []
    value_result :: Vector{Any} = []
    field_result :: Vector{Any} = []
    visit = mk_visit(field_getted, assign)

    # process selectors
    foreach(args) do arg
        @match arg begin
            :_ =>
                begin
                    push!(value_result, Expr(:..., RECORD))
                    push!(field_result, Expr(:..., IN_FIELDS))
                end

            :(_.(! $pred( $ (args...))))  =>
                let new_field_pack = gen_sym()
                    new_index_pack = gen_sym()
                    push!(Expr(:(=), new_field_pack, :[$RECORD for $RECORD in $IN_FIELDS if !($pred($RECORD, $ (args...)))]))
                    push!(Expr(:(=), new_index_pack, Expr(:call, indexin, new_field_pack, IN_FIELDS)))

                    push!(field_result, Expr(:...,  new_field_pack))
                    push!(value_result, Expr(:...,  :($RECORD[$new_index_pack])))

                end
            :(_.($pred( $ (args...))))  =>
                let new_field_pack = gen_sym()
                    new_index_pack = gen_sym()
                    push!(Expr(:(=), new_field_pack, :[$RECORD for $RECORD in $IN_FIELDS if ($pred($RECORD, $ (args...)))]))
                    push!(Expr(:(=), new_index_pack, Expr(:call, indexin, new_field_pack, IN_FIELDS)))

                    push!(field_result, Expr(:...,  new_field_pack))
                    push!(value_result, Expr(:...,  :($RECORD[$new_index_pack])))
                end

           :($a => $new_field) || a && Do(new_field = Symbol(string(a))) =>
                begin
                    new_value = visit(a)
                    push!(field_result, QuoteNode(new_field))
                    push!(value_result, new_value)
                end
        end
    end

    # select expression generation
    query_routine(
        assign,
        Expr(:call,
             infer,
              TYPE,
              Expr(:tuple, field_result...),
              let v = Expr(:tuple, value_result...)
                  :($v for $RECORD in $SOURCE)
              end
        )
    )
end
```