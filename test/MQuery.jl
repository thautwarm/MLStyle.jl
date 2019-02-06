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

ismacro(x :: Expr) = Meta.isexpr(x, :macrocall)
ismacro(_) = false

function get_fields
end

function get_records
end

function build_result
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

function flatten_macros(node :: Expr)
    @match node begin
    Expr(:macrocall, op :: Symbol, ::LineNumberNode, arg) ||
    Expr(:macrocall, op :: Symbol, arg) =>

    @match arg begin
    Expr(:tuple, args...) || a && Do(args = [a]) =>

    @match args begin
    [args..., function ismacro end && tl] => [(op |> get_op, args), flatten_macros(tl)]
    _ => [(op |> get_op, args)]

    end
    end
    end
end

function codegen(node)
    ops = flatten_macros(node)
    let rec(vec) =
        @match vec begin
            [] => []
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

# visitor to process the pattern `_.x, _,"x", _.(1)` inside an expression
function mk_visit(field_getted, assign)
        visit = expr ->
        @match expr begin
            Expr(:. , :_, a) =>
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

macro select(node)
    codegen(Expr(:macrocall, Symbol("@select"), __source__, node)) |> esc
end


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

macro where(node)
    codegen(Expr(:macrocall, Symbol("@where"), __source__, node)) |> esc
end

function generate_groupby(args :: AbstractArray, having_args :: Union{Nothing, AbstractArray} = nothing)
    field_getted = Dict{Symbol, Symbol}()
    assign       :: Vector{Any} = []
    visit = mk_visit(field_getted, assign)

    fields_gkeys = map(args) do arg
        @match arg begin
            :($b => $a) || b && Do(a = Symbol(string(b))) =>
                let field = a
                    (field, visit(b))
                end
        end
    end

    group_key = map(x -> x[1], fields_gkeys)
    ngroup_key = length(fields_gkeys)
    group_key_values = Expr(:tuple, map(x -> x[2], fields_gkeys)...)
    group_key_fields = map(QuoteNode ∘ Symbol ∘ string, group_key)
    cond_expr = having_args === nothing ? nothing :
        let cond =
            foldl(having_args) do last, arg
                Expr(:&&, last, visit(arg))
            end

            quote
                if $cond
                    continue
                end
            end
        end

    # groupby expression generation
    query_routine(
        assign,
        let out_fields = Expr(:tuple, Expr(:..., group_key_fields), Expr(:..., IN_FIELDS))
            quote
                $GROUPS = $Dict{$Tuple, $Vector}()
                $N = $length($IN_FIELDS,)
                @inline function $GROUP_FN($RECORD :: $TYPE, )
                    $group_key_values
                end
                for $RECORD in $SOURCE
                    $group_key = $GROUP_FN($RECORD, )
                    $GROUP_KEY = $group_key
                    $cond_expr
                    $AGG =
                        $get!($GROUPS, $GROUP_KEY) do
                            [[] for _ = 1:$N]
                        end
                    ($push!).($AGG, $RECORD,)
                end
                (
                    $out_fields,
                    ($type_unpack($ngroup_key, $return_type($GROUP_FN, $TYPE))...,
                     $type_aggregate($N, $TYPE)...),
                    ((k..., v...) for (k, v) in $GROUPS)
                )
            end
        end
    )
end

macro groupby(node)
    codegen(Expr(:macrocall, Symbol("@groupby"), __source__, node)) |> esc
end

macro having(node)
    codegen(Expr(:macrocall, Symbol("@having"), __source__, node)) |> esc
end


macro orderby(node)
    codegen(Expr(:macrocall, Symbol("@orderby"), __source__, node)) |> esc
end


macro limit(node)
    codegen(Expr(:macrocall, Symbol("@limit"), __source__, node)) |> esc
end

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

get_fields(df :: DataFrame) = names(df)
get_records(df :: DataFrame) = zip(DataFrames.columns(df)...)
function build_result(::Type{DataFrame}, fields, typs, source :: Base.Generator)
    res = Tuple(typ[] for typ in typs)
    for each in source
        push!.(res, each)
    end
    DataFrame(collect(res), collect(fields))
end
