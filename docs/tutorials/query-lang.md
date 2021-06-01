Write You A Query Language
===============================================

**P.S**: *this document is not up-to-date*.

You may have heard of embedded query languages like LINQ or extension methods before.

In terms of Julia ecosystem, there is already Query.jl, LightQuery.jl, DataFramesMeta.jl, etc. These packages accomplish the partial or full features of a query language.

This tutorial primarily shows the creation a concise and efficient query language implemented  with MLStyle.jl. This demonstration illustrates the power of MLStyle.jl's ability to perform AST manipulations. Additionally, I think this tutorial can be also extremely helpful to those who're developing query languages for Julia.

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

1. select the field `x` / select the 1-fst field

    `_.x / _.(1)`


2. select the field `x`(to support field name that're not an identifier)

    `_."x"`

3.  select an expression binded as `x + _.x`, where `x` is from current scope

    `x + _.x`

4.  select something and bind it to symbol `a`

    `<selector 1-3> => a / <selector 1-3> => "a"`

5. select any field `col` that `predicate1(col, args1...) && !predicate2(col, args2...) && ...` is true

    `_.(predicate1(args...), !predicate2(args2..., ),   ...)`

With E-BNF notation, we can formalize the synax,

```
FieldPredicate ::= ['!'] QueryExpr '(' QueryExprList ')' [',' FieldPredicate]

Field          ::= (Symbol | String | Int)


QueryExpr      ::=  '_' '.' Field
                  | <substitute QueryExpr in for JuliaExpr>

QueryExprList  ::= [ QueryExpr (',' QueryExpr)* ]

selector       ::= '_' '.' FieldPredicate
                  | QueryExpr
```

A `predicate` is a `QueryExpr`, but should be evaluated to a boolean.

A `mapping`  is a `QueryExpr`, but shouldn't be evaluated to a nothing.

FYI, here're some valid instances about `selector`.

```
_.foo,
_.1,
_.(startswith("bar"), !endswith("foo")),
x + _.foo,
let y = _.foo + y; y + _.(2) end
```

Codegen Target
--------------------------------

Before implementing code generation, we should have a sketch about the target. The **target** here means the final shape of the code generated from a sequence of query clauses.

I'll take you to the travel within the inference about the final shape of code generation.

First, we want to do this:

```julia
df |>
@select _.foo + x, _.bar
```

We can infer that the generated code is an anonymous function which takes only one argument.

Okay, cool. We now know that the final shape of generated code should have the following form:

```julia
function (ARG)
    # implementations
end
```

Then, let's think about the `select` clause. You might find it's a `map`(if we don't take aggregate function into consideration). However, we don't want to
make redundant allocations when executing the queries, so we should use `Base.Generator` as the data representation.

For `@select _.foo + x, _.bar`, it should be generated to something like the following:

```julia
((RECORD[:foo] + x, RECORD[:bar])   for RECORD in IN_SOURCE)
```

Where `IN_SOURCE` is the data representation, `RECORD` is the record(row) of `IN_SOURCE`, and `x` is the variable captured by the closure.

Now, a smart reader might observe that there's a trick for optimization! If we can have the actual indices of the fields `foo` and `bar` in the record(each row of `IN_SOURCE`), then they can be indexed via integers, which could avoid reflections in some degree.

I don't have much knowledge about NamedTuple's implementation, but indexing via names on unknown datatypes cannot be faster than simply indexing via integers.

So, the generated code of `select` could be

```julia
let idx_of_foo = findfirst(==(:foo), IN_FIELDS),
    idx_of_bar = findfirst(==(:bar), IN_FIELDS),
    @inline FN(_foo, _bar) = (_foo + x, _bar)
    (
    let _foo = RECORD[idx_of_foo],
        _bar = RECORD[idx_of_bar]
        FN(_foo, _bar)
    end
    for RECORD in IN_SOURCE)
end

```

Where we introduce a new requirement of the query's code generation, `IN_FIELDS`, which denotes the field names of `IN_SOURCE`.

Now, to have a consistent code generation, let's think about stacked `select` clauses.

```julia
df |>
@select _, _.foo + 1, => foo1,
# `select _` here means `SELECT *` in T-SQL.
@select _.foo1 + 2 => foo2
```

I don't know how to explain the iteration in my mind, but I've figured out the following way to do it.

```julia
let (IN_FIELDS, IN_SOURCE) =
    let (IN_FIELDS, IN_SOURCE) = process(df),
        idx_of_foo = findfirst(==(:foo), IN_FIELDS),
        @inline FN(_record, _foo) = (_record..., _foo + 1)
        [IN_FIELDS..., :foo1],
        (
            let _foo = RECORD[idx_of_foo]
                FN(RECORD, _foo)
            end
            for RECORD in IN_SOURCE
        )
    end,
    idx_of_foo1 = findfirst(==(:foo1), IN_FIELDS),
    @inline FN(_foo1) = (_foo1 + 2, )

    [:foo2],
    (
        let _foo1 = RECORD[idx_of_foo1]
            FN(_foo1)
        end
        for RECORD in IN_SOURCE
    )
end
```
Oh, perfect! I'm so excited! That's so beautiful!

If the output field names are a list of meta variables `[:foo2]`, then output expression inside the comprehension should be a list of terms `[foo2]`. For `foo2 = _.foo1 + 2` which is generated as `RECORD[idx_of_foo1] + 2`, so it comes into the shape of above code snippet.

Let's think about the `where` clause.

If we want this:
```julia
df |>
@where _.foo < 2
```

That's similar to `select`:

```julia
let (IN_FIELDS, IN_SOURCE) = process(df),
    idx_of_foo = findfirst(==(:foo), IN_FIELDS)
    IN_FIELDS,
    (
        RECORD for RECORD in SOURCE
        if  let _foo = RECORD[idx_of_foo]
                _foo < 2
            end
    )
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

Yep, we want to group data frames(of course, any other datatypes that can be processed via this pipeline) by whether its field `name` starts with a string "Ruby" like, "Ruby Rose".

Ha, I'd like to use a dictionary here to store the groups.

```julia
let IN_FIELDS, IN_SOURCE = process(df),
    idx_of_name = findfirst(==(:name), IN_FIELDS),
    @inline FN(_name) = (startswith(_.name, "Ruby"), )

    GROUPS = Dict() # the type issues will be discussed later.
    for RECORD in IN_SOURCE
        _name = RECORD[idx_of_name]
        GROUP_KEY = (is_ruby, ) = FN(_name)
        AGGREGATES = get!(GROUPS, GROUP_KEY) do
            Tuple([] for _ in IN_FIELDS)
        end
        push!.(AGGREGATES, RECORD)
    end
    # then output fields and source here
end
```

I think it perfect, so let's go ahead. We'll explain more about why we use `@inline` later, but the short answer is that it was needed for type inference.

So, what should the output field names and the source be?

An implementation could be,

```julia
IN_FIELDS, values(GROUPS)
```

But if so, we will lose the information of group keys, which is undesirable.

So, if we want to persist the group keys, we can do this:

```julia
[[:is_ruby]; IN_FIELDS], ((k..., v...) for (k, v) in GROUPS)
```

I think the latter could be sufficiently powerful, although it might not be that efficient. You can have
different implementations of `groupby` if you have more specific use cases, just use the extensible system
which will be introduced later.

So, the code generation of `groupby` could be:

```julia
let IN_FIELDS, IN_SOURCE = process(df),
    idx_of_name = findfirst(==(:name), IN_FIELDS),
    @inline FN(_name) = (startswith(_.name, "Ruby"), )

    GROUPS = Dict() # the type issues will be discussed later.
    for RECORD in IN_SOURCE
        _name = RECORD[idx_of_name]
        GROUP_KEY = (is_ruby, ) = FN(_name)
        AGGREGATES = get!(GROUPS, GROUP_KEY) do
            Tuple([] for _ in IN_FIELDS)
        end
        push!.(AGGREGATES, RECORD)
    end
    [[:is_ruby]; IN_FIELDS], ((k..., v...) for (k, v) in GROUPS)
end

```

However, subsequently, we come to the `having` clause, in fact, I'd regard it as a sub-clause of
`groupby`, which means it cannot take place independently, but co-appear with a `groupby` clause.

Given such a case:
```julia
df |>
@groupby startswith(_.name, "Ruby")  => is_ruby
@having is_ruby || count(_.is_rose) > 5
```
The generated code should be:

```julia
let IN_FIELDS, IN_SOURCE = process(df),
    idx_of_name = findfirst(==(:name), IN_FIELDS),
    idx_of_is_rose = findfirst(==(:is_rose), IN_FIELDS)
    @inline FN(_name) = (startswith(_name, "Ruby"), )

    GROUPS = Dict() # the type issues will be discussed later.
    for RECORD in IN_SOURCE
        _name = RECORD[idx_of_name]
        _is_rose = RECORD[idx_of_rose]
        GROUP_KEY = (is_ruby, ) = GROUP_FN(RECORD)
        if !(is_ruby || count(is_rose) > 5)
            continue
        end
        AGGREGATES = get!(GROUPS, GROUP_KEY) do
            Tuple([] for _ in IN_FIELDS)
        end
        push!.(AGGREGATES, RECORD)
    end
    [[:is_ruby]; IN_FIELDS], ((k..., v...) for (k, v) in GROUPS)
end
```

The conditional code generation of `groupby` could be achieved very concisely via AST patterns of MLStyle, we'll refer to this later.

After introducing the generation for above 4 clauses, `orderby` and `limit` then become trivial, and I don't want to repeat myself if it is not necessary.

Now we know that multiple clauses could be generated to produce a `Tuple` result, first of which is the field names, the
second is the lazy computation of the query. We can associate this tuple to the corresponding types, for instance,

```julia
function (ARG :: DataFrame)
    (IN_FIELDS, IN_SOURCE) = let IN_FIELDS, IN_SOURCE = ...
        ...
    end

    res = Tuple([] for _ in IN_FIELDS)
    for each in IN_SOURCE
        push!.(res, each)
    end
    DataFrame(collect(res), IN_FIELDS)
end
```

Refinement of Codegen: Typed Columns
---------------------------------------------

This last section introduces a framework of code generation for implementing query languages, but there's still a fatal problem.

Look at the value to be returned (when input is a `DataFrame`):

```julia
res = Tuple([] for _ in IN_FIELDS)
for each in SOURCE
    push!.(res, each)
end
DataFrame(collect(res), collect(IN_FIELDS))
```

I can promise you that, each column of your data frames is a `Vector{Any}`, yes, not its actual type.
You may prefer to calculate the type of a column using the common super type of all elements, but there are
two problems if you try this:

- If the column is empty, emmmm...
- Calculating the super type of all elements is very slow!

Yet, I'll introduce a new requirement `IN_TYPES` of the query's code generation, which perfectly solves problems of column types.

Let's have a look at code generation for `select` after introducing the `IN_TYPES`.

Given that
```julia
@select _, _.foo + 1
# `@select _` is regarded as `SELECT *` in T-SQL.
```

```julia
return_type(f, ts) =
    let ts = Base.return_types(f, ts)
        length(ts) === 1 ?
            ts[1]        :
            Union{ts...}
    end
type_unpack(n, ::Type{Tuple{}}) = throw("error")
type_unpack(n, ::Type{Tuple{T1}}) where T1 = [T1]
type_unpack(n, ::Type{Tuple{T1, T2}}) where {T1, T2} = [T1, T2]
# type_unpack(::Type{Tuple{T1, T2, ...}}) where {T1, T2, ...} = [T1, T2, ...]
type_unpack(n, ::Type{Any}) = fill(Any, n)

let (IN_FIELDS, IN_TYPES, SOURCE) = process(df),
    idx_of_foo = findfirst(==(:foo),  IN_FIELDS),
    (@inline FN(_record, _foo) = (_record..., _foo)),
    FN_OUT_FIELDS = [IN_FIELDS..., :foo1],
    FN_OUT_TYPES = type_unpack(length(FN_OUT_FIELDS), return_type(Tuple{IN_TYPES...}, IN_TYPES[idx_of_foo]))

    FN_OUT_FILEDS,
    FN_OUT_TYPES,
    (let _foo = RECORD[idx_of_foo]; FN(RECORD, _foo) end for RECORD in SOURCE)
end
```

For `groupby`, it could be a bit more complex, but it does nothing new towards what `select` does. You can check [the repo](https://github.com/thautwarm/MLStyle-Playground/tree/master/MQuery) for codes.

Implementation
------------------------

Firstly, we should define something like constants and helper functions.

FYI, some constants and interfaces are defined at [MQuery.ConstantNames.jl](https://github.com/thautwarm/MLStyle-Playground/blob/master/MQuery/MQuery.ConstantNames.jl)
and [MQuery.Interfaces.jl](https://github.com/thautwarm/MLStyle-Playground/blob/master/MQuery/MQuery.Interfaces.jl),
you might want to refer to them if any unknown symbol prevents you from understanding this sketch.

Then we should extract all clauses from a piece of given julia codes.

Given following codes,
```julia
@select args1,
@where args2,
@select args3
```
we transform them into

```julia
[(generate_select, args), (generate_where, args2), (generate_select, args3)]
```

```julia
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

The core is `flatten_macros`, it destructures `macrocall` expressions and then we can simply flatten the `macrocall`s.

Next, we could have a common behaviour of code generation.

```julia

struct Field
    name      :: Any    # an expr to represent the field name from IN_FIELDS.
    make      :: Any    # an expression to assign the value into `var` like, `RECORD[idx_of_foo]`.
    var       :: Symbol # a generated symbol via mangling
    typ       :: Any    # an expression to get the type of the field like, `IN_TYPES[idx_of_foo]`.
end

function query_routine(assigns            :: OrderedDict{Symbol, Any},
                       fn_in_fields       :: Vector{Field},
                       fn_returns         :: Any,
                       result; infer_type = true)
    @assert haskey(assigns, FN_OUT_FIELDS)

    fn_arguments = map(x -> x.var, fn_in_fields)
    fn_arg_types = Expr(:vect, map(x -> x.typ, fn_in_fields)...)

    function (inner_expr)
        let_seq = [
            Expr(:(=), Expr(:tuple, IN_FIELDS, IN_TYPES, IN_SOURCE), inner_expr),
            (:($name = $value) for (name, value) in assigns)...,
            :(@inline $FN($(fn_arguments...)) =  $fn_returns),
        ]
        if infer_type
            let type_infer = :($FN_RETURN_TYPES = $type_unpack($length($FN_OUT_FIELDS, ), $return_type($FN, $fn_arg_types)))
                push!(let_seq, type_infer)
            end
        end
        Expr(:let,
            Expr(
                :block,
                let_seq...
            ),
            result
        )
    end
end
```

In fact, `query_routine` generates code like

```julia
let IN_FIELDS, IN_TYPES, IN_SOURCE = <inner query>,
    idx_of_foo = ...,
    idx_of_bar = ...,
    @inline FN(x) = ...

    ...
end
```

Then, we should generate the final code from such a sequence given as the return of `flatten_macros`.

Note that `get_records`, `get_fields` and `build_result` should be implemented by your own to support datatypes that you want to query on.

```julia
function codegen(node)
    ops = flatten_macros(node)
    let rec(vec) =
        @match vec begin
            [] => []
            [(&generate_groupby, args1), (&generate_having, args2), tl...] =>
                [generate_groupby(args1, args2), rec(tl)...]
            [(hd, args), tl...] =>
                [hd(args), rec(tl)...]
        end
        init = quote
            let iter = $get_records($ARG),
                fields = $get_fields($ARG),
                types =$type_unpack($length(fields), $eltype(iter))
                (fields, types, iter)
            end
        end
        fn_body = foldl(rec(ops), init = init) do last, mk
            mk(last)
        end
        quote
            @inline function ($ARG :: $TYPE_ROOT, ) where {$TYPE_ROOT}
                let ($IN_FIELDS, $IN_TYPES, $IN_SOURCE) = $fn_body
                    $build_result(
                        $TYPE_ROOT,
                        $IN_FIELDS,
                        $IN_TYPES,
                        $IN_SOURCE
                    )
                end
            end
        end
    end
end
```

Then, we need a visitor pattern to transform the patterns shaped as `_.foo` inside an expression to a mangled symbol whose value is `RECORD[idx_of_foo]`.

```julia
# visitor to process the pattern `_.x, _,"x", _.(1)` inside an expression
function mk_visit(fields :: Dict{Any, Field}, assigns :: OrderedDict{Symbol, Any})
    visit = expr ->
    @match expr begin
        Expr(:. , :_, q :: QuoteNode) && Do(a = q.value) ||
        Expr(:., :_, Expr(:tuple, a)) =>
            @match a begin
                a :: Int =>
                    let field = get!(fields, a) do
                            var_sym = gen_sym(a)
                            Field(
                                a,
                                Expr(:ref, RECORD, a),
                                var_sym,
                                Expr(:ref, IN_TYPES, a)
                            )
                        end
                        field.var
                    end

                ::String && Do(b = Symbol(a)) ||
                b::Symbol =>
                    let field = get!(fields, b) do
                            idx_sym = gen_sym()
                            var_sym = gen_sym(b)
                            assigns[idx_sym] = Expr(:call, findfirst, x -> x === b, IN_FIELDS)
                            Field(
                                b,
                                Expr(:ref, RECORD, idx_sym),
                                var_sym,
                                Expr(:ref, IN_TYPES, idx_sym)
                            )
                        end
                        field.var
                    end
            end
        Expr(head, args...) => Expr(head, map(visit, args)...)
        a => a
    end
end
```

The meaning of `fields` and `assign`s might not be obvious, so we'll dig closer into these terms now.

- `fields : Dict{Any, Field}`

    Think about if you wanted such a query `@select _.foo * 2, _.foo + 2`, you can see that field `foo` is referred twice, but you shouldn't make 2 symbols to represent the index of `foo` field. So I introduce a dictionary `fields` here to
    avoid the cost of that re-calculation.

- `assigns : OrderedDict{Any, Expr}`

    When you want to bind the index of `foo` to a given symbol `idx_of_foo`, you should set an expression `$findfirst(==(:foo), $IN_FIELDS)` to `assigns` on key `idx_of_foo`. The reason why we don't use a `Vector{Expr}` to represent `assigns` is, we can avoid re-assignments in some cases(you can find an instance in `generate_groupby`).

    Finally, `assigns` would be generated to the binding section of
    a `let` sentence.

Now, following previous discussions, we can firstly implement the easiest one, codegen method for `where` clause.

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
    map_in_fields = Dict{Any, Field}()
    assigns = OrderedDict{Symbol, Any}()
    fn_return_elts   :: Vector{Any} = []
    fn_return_fields :: Vector{Any} = []
    visit = mk_visit(map_in_fields, assigns)
    # process selectors
    predicate_process(arg) =
        @match arg begin
        :(!$pred($ (args...) )) && Do(ab=true)  ||
        :($pred($ (args...) ))  && Do(ab=false) ||
        :(!$pred) && Do(ab=true, args=[])       ||
        :($pred)  && Do(ab=false, args=[])      =>
            let idx_sym = gen_sym()
                assigns[idx_sym] =
                    Expr(
                        :call,
                        findall,
                        ab ?
                            :(@inline function ($ARG,) !$pred($string($ARG,), $(args...)) end) :
                            :(@inline function ($ARG,) $pred($string($ARG,), $(args...)) end)
                        , IN_FIELDS
                    )
                idx_sym
            end
        end
```

`fn_return_elts` will be finally evaluated as the return of `FN`, while `FN` will be used to be generate the next `IN_SOURCE` with `:(let ... ; $FN($args...) end for
$RECORD in $SOURCE)`, while `fn_retrun_fields` will be finally used to generate the next `IN_FIELDS` with `Expr(:vect, fn_return_fields...)`.

Let's go ahead.

```julia
    foreach(args) do arg
        @match arg begin
            :_ =>
                let field = get!(map_in_fields, all) do
                        var_sym = gen_sym()
                        push!(fn_return_elts, Expr(:..., var_sym))
                        push!(fn_return_fields, Expr(:..., IN_FIELDS))
                        Field(
                            all,
                            RECORD,
                            var_sym,
                            :($Tuple{$IN_TYPES...})
                        )
                    end
                    nothing
                end

```

We've said that `@select _` here is equivalent to `SELECT *` in T-SQL.

The remaining is also implemented with a concise case splitting via pattern matchings on ASTs.

```julia
            :(_.($(args...))) =>
                let indices = map(predicate_process, args)
                    if haskey(map_in_fields, arg)
                        throw("The columns `$(string(arg))` are selected twice!")
                    elseif !isempty(indices)
                        idx_sym = gen_sym()
                        var_sym = gen_sym()
                        field = begin
                            assigns[idx_sym] =
                                length(indices) === 1 ?
                                indices[1] :
                                Expr(:call, intersect, indices...)
                            push!(fn_return_elts, Expr(:..., var_sym))
                            push!(fn_return_fields, Expr(:..., Expr(:ref, IN_FIELDS, idx_sym)))
                            Field(
                                arg,
                                Expr(:ref, RECORD, idx_sym),
                                var_sym,
                                Expr(:curly, Tuple, Expr(:..., Expr(:ref, IN_TYPES, idx_sym)))
                            )
                        end
                        map_in_fields[arg] = field
                        nothing
                    end
                end
```

Above case is for handling with field filters, like
`@select _.(!startswith("Java"), endswith("#"))`.

```julia
           :($a => $new_field) || a && Do(new_field = Symbol(string(a))) =>
                let new_value = visit(a)
                    push!(fn_return_fields, QuoteNode(new_field))
                    push!(fn_return_elts, new_value)
                    nothing
                end
        end
    end

    fields = map_in_fields |> values |> collect
    assigns[FN_OUT_FIELDS] = Expr(:vect, fn_return_fields...)
    # select expression generation
    query_routine(
        assigns,
        fields,
        Expr(:tuple, fn_return_elts...),
        Expr(
            :tuple,
            FN_OUT_FIELDS,
            FN_RETURN_TYPES,
            :($(fn_apply(fields)) for $RECORD in $IN_SOURCE)
        ); infer_type = true
    )
end
```

The above case is for handling with regular expressions which might contain something like `_.x`, `_.(1)` or `_."is ruby"`.

Meanwhile, `=>` allows you to alias the expression with the name you prefer. Note that, in terms of `@select (_.foo => :a) => a`, the first `=>` is a normal infix operator, which denotes the built-in object `Pair`, but the second is an *alias*.

If you have problems with `$` in AST patterns, just remember that, inside a `quote ... end` or `:(...)`, ASTs/Expressions are compared by literal, except for `$(...)` things are matched via normal patterns, for instance, `:($(a :: Symbol) = 1)` can match `:($a = 1)` if the available variable `a` has type `Symbol`.

With respect of `groupby` and `having`, they're too long to put in this article, so you might want to check them at [MQuery.Impl.jl#L217](https://github.com/thautwarm/MLStyle-Playground/blob/master/MQuery/MQuery.Impl.jl#L217).

Enjoy You A Query Language
-------------------------------------

```julia
using Enums
@enum TypeChecking Dynamic Static

include("MQuery.jl")
df = DataFrame(
        Symbol("Type checking") =>
            [Dynamic, Static, Static, Dynamic, Static, Dynamic, Dynamic, Static],
        :name =>
            ["Julia", "C#", "F#", "Ruby", "Java", "JavaScript", "Python", "Haskell"]),
        :year => [2012, 2000, 2005, 1995, 1995, 1995, 1990, 1990]
)

df |>
@where !startswith(_.name, "Java"),
@groupby _."Type checking" => TC, endswith(_.name, "#") => is_sharp,
@having TC === Dynamic || is_sharp,
@select join(_.name, " and ") => result, _.TC => TC

```

outputs

```
2×2 DataFrame
│ Row │ result                    │ TC        │
│     │ String                    │ TypeChec… │
├─────┼───────────────────────────┼───────────┤
│ 1   │ Julia and Ruby and Python │ Dynamic   │
│ 2   │ C# and F#                 │ Static    │
```
