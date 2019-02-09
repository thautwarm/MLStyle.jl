ismacro(x :: Expr) = Meta.isexpr(x, :macrocall)
ismacro(_) = false

function flatten_macros(node :: Expr)
    @match node begin
    Expr(:macrocall, op :: Symbol, ::LineNumberNode, arg) ||
    Expr(:macrocall, op :: Symbol, arg) =>

    @match arg begin
    Expr(:tuple, args...) || a && Do(args = [a]) =>

    @match args begin
    [args..., function ismacro end && tl] => [(op |> get_op, args), flatten_macros(tl)...]
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

macro select(node)
    codegen(Expr(:macrocall, Symbol("@select"), __source__, node)) |> esc
end


macro where(node)
    codegen(Expr(:macrocall, Symbol("@where"), __source__, node)) |> esc
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
