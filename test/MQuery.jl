using MLStyle
using DataFrames

ARG = Symbol("MQuery.ARG") # we just need limited mangled symbols here.
IN_FIELDS = Symbol("MQuery.IN.FIELDS")
IN_SOURCE = Symbol("MQuery.IN.SOURCE")
ELT = Symbol("MQuery.ELT")
N = Symbol("MQuery.N")
GROUPS = Symbol("MQuery.GROUPS")
GROUP_KEY = Symbol("MQuery.GROUP_KEY")
AGG_RANK = Symbol("MQuery.AGG_RANK")
AGG = Symbol("MQuery.AGG")

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

    args = @match args begin
        Expr(:tuple, args...) => args
        a => [a]
    end

    ast_makers = @match args begin
        [args..., function ismacro end && tl] => [(generate, args), codegen(tl)...]
        _ => [(generate, args)]
    end

    let rec(vec) =
        @match vec begin
            [] => []
            [(&generate_groupby, args1), &(generate_having, args2), tl...] =>
                [generate_groupby(args1, args2), rec(tl)...]
            [(hd, args), tl...] =>
                [hd(args), rec(tl)...]
        end        
        init = quote
            # TODO: get AGG_RANK from input_data         
            (0, $names($ARG), zip($(DataFrames.columns)($ARG)...))
        end 
        fn_body = foldl(rec(ast_makers), init = init) do last, mk
            mk(last)
        end
        quote
            @inline function ($ARG :: $DataFrame, )
                $fn_body
            end
        end
    end
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

# visitor to process the pattern `_.x, _,"x", _.(1)` inside an expression 
function mk_visit(field_getted, assign)
        visit = expr ->
        @match expr begin
            Expr(:. , :_, a) =>
                let a = a isa QuoteNode ? a.value : a
                    @match a begin
                        Expr(:tuple, a :: Int) => Expr(:ref, ELT, a)
                        ::String && Do(b = Symbol(a)) || b::Symbol =>
                        Expr(:ref, 
                            ELT,
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
                begin
                    new_value = visit(a)
                    push!(field_result, QuoteNode(new_field))
                    push!(value_result, new_value)
                end                        
        end
    end

    # select expression generation
    inner_expr ->
    Expr(:let,
        Expr(:block, 
            Expr(:(=), Expr(:tuple, AGG_RANK, IN_FIELDS, IN_SOURCE), inner_expr),
            assign...
        ),
        Expr(:tuple,
            AGG_RANK,
            Expr(:tuple, field_result...),
            let v = Expr(:tuple, value_result...)
                :[$v for $ELT in $IN_SOURCE]
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
    inner_expr ->
    Expr(:let,
        Expr(:block, 
            Expr(:(=), Expr(:tuple, AGG_RANK, IN_FIELDS, IN_SOURCE), inner_expr),
            assign...
        ),
        Expr(:tuple,
            AGG_RANK,
            IN_FIELDS,
            :[$ELT for $ELT in $IN_SOURCE if $pred]
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
            :($a = $b) || b && Do(a = Symbol(string(b))) =>
                let field = a
                    (field, Expr(:(=), field, visit(b)))
                end
        end
    end
    
    group_key = Expr(:tuple, map(x -> x[1], fields_gkeys)...)
    mk_keys = Expr(:block, map(x -> x[2], fields_gkeys)...)

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
    # where expression generation
    inner_expr ->
    Expr(:let,
        Expr(:block, 
            Expr(:(=), Expr(:tuple, AGG_RANK, IN_FIELDS, IN_SOURCE), inner_expr),
            assign...
        ),
        Expr(:tuple,
            Expr(:call, (+), AGG_RANK, 1),
            Expr(:tuple, QuoteNode(Symbol(string(group_key))), Expr(:..., IN_FIELDS)),
            quote
                $GROUPS = $Dict{$Tuple, $Vector}()
                $N = $length($IN_FIELDS,)
                for $ELT in $IN_SOURCE
                    $mk_keys
                    $GROUP_KEY = $group_key
                    $cond_expr
                    $AGG = 
                        $get!($GROUPS, $GROUP_KEY) do
                            [[] for i = 1:$N]
                        end
                    ($append!).($AGG, $ELT,)
                end
                [(k, v...) for (k, v) in $GROUPS]
            end
        )
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

df = DataFrame(foo=[1,2,3], bar=[3.,2.,1.], bat=["a","b","c"])

@select _.foo + 1, _.foo * 2



