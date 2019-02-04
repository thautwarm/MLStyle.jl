Implement You A Query Language
===============================================

You may have heard of LINQ or extension methods before, and they're all embedded query langauges.

In Julia ecosystem, there're Query.jl, LightQuery.jl, DataFramesMeta.jl, etc., each of which reaches the partial or full features of a query language. 

This document is provided for you to create a concise and efficient implementation of query langauge,
which is a way for me to exhibit the power of MLStyle.jl on AST manipulations. Additionally, I think this tutorial can be also
extremely helpful to those who're developing query languages for Julia.


Definition of Syntaxes
------------------------------

Firstly, we can refer to the the T-SQL syntaxes and introduce the basic syntaxes into Julia.

```Julia

df                   |>
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

2. select the field `x`

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
    a = <selector 1-4>
    "a" = <selector 1-4>
    ```

6. select any the field `col` when `predicate(col, args...)` is true.
    
    ```
    _.(predicate(args...))
    ```

7. select any the field `col` when `predicate(col, args...)` is false.

    ```
    _.(!predicate(args...))
    ```

With E-BNF, we can formalize the synaxes,

```

FieldPredicate ::= QueryExpr '(' QueryExprList ')'
Field          ::=  ['!'] (Symbol | String | Int)

selectorExpr   ::=  '_' '.' Field
                  | QueryExpr(QueryExprList)
                  | QueryExpr Operator QueryExpr

selector       ::= '_' '.' FieldPredicate
                  | selectorExpr
QueryExpr      ::= selectorExpr | JuliaExpr
QueryExprList  ::= [ QueryExpr (',' QueryExpr)* ]

```

A `predicate` is a `selectorExpr`, but shouldn't be evaluated to a boolean.

A `mapping`  is ap `selectorExpr`, but shouldn't be evaluated to a nothing.


Structured Notation
--------------------------------

Before codegen we might not have a clear blueprint about the implementation, but anyway,
build the structures of your syntaxes would help you with the comprehension of the problem.

```Julia
Option{T} = Union{Nothing, T} where T

@data Query begin
    # predicate : Symbol -> AST(evalued to boolean)
    Where(predicate :: Function)
    Having(predicate :: Function)
    # selector :: Symbol -> AST
    Select(selector :: Function)
    # mapping :: Symbol -> AST
    GroupBy(mapping :: Function)
    OrderBy(mapping :: Function)
    # take :: Symbol-> AST
    Limit(take :: Function)
    Combine(Query, Query)
end
```

Intuitively, I make such a design, which could be illustrated in following steps:

1. Original Julia macrocalls.

We can get started with a simple expressione.

```Julia

@select _.x + 1, a = _.y * 2,
@where _.a < 2

```

2. Query Transformation

P.S: The quoted expressions are not their actual values. No mangling here for readability.

```Julia

queries = [
    Select(sym ->
        quote     
            let (source, fields) = $sym, 
                i_x = at(fields, :x),
                i_y = at(fields, :y)
                
                (Symbol("_.x + 1"), :a), ((record[i_x] + 1, record[i_y] * 2) for record in sym)
            end
        end),
        
    Where(sym ->
        quote
            let (source, fields) = $sym, 
                i_a = at(fields, :a)
               
                fields, (record for record in sym if record[i_a] < 2)
            end
        end)
]
```

3. Code(AST) Generation

```Julia
@inline function (mangled1 :: DataFrame)
    source = columns(mangled1)
    fields = names(mangled1)
    let (source, fields) = 
        let (fields, source) = (fields, source) , 
            i_x = at(fields, :x),
            i_y = at(fields, :y)
             
            (Symbol("_.x + 1"), :a), ((record[i_x] + 1, record[i_y] * 2) for record in sym)
        end
        
        i_a = at(fields, :a)      
        fields, (record for record in sym if record[i_a] < 2)
        
    end |> to_dataframe
end
```


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

