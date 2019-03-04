module DataType
using MLStyle
using MLStyle.Toolz: isCapitalized, ($), cons, nil
using MLStyle.MatchCore
using MLStyle.Qualification
using MLStyle.Infras
using MLStyle.Pervasives
using MLStyle.Render: render
using MLStyle.Record: def_record

export @data
is_symbol_capitalized = isCapitalized ∘ string


macro data(typ, def_variants)
    data(typ, def_variants, :public, __module__) |> esc
end

macro data(qualifier, typ, def_variants)
    data(typ, def_variants, qualifier, __module__) |> esc
end

function get_tvars(t :: UnionAll)
    cons(t.var.name, get_tvars(t.body))
end

function get_tvars(t :: Base.DataType)
   nil()
end


function get_tvars(t :: Union)
   nil()
end

function data(typ, def_variants, qualifier_ast, mod)
    typename =
        @match typ begin
           :($typename{$(a...)})       => typename
           :($typename{$(a...)} <: $b) => typename
           :($typename <: $b)          => typename
           :($(typename :: Symbol))    => typename
        end

    mod.eval(:(abstract type $typ end))

    original_ty = getfield(mod, typename)
    tvars_of_abst = get_tvars(original_ty)

    for (ctor_name, pairs, each) in impl(original_ty, def_variants, mod)
        mod.eval(each)
        ctor = getfield(mod, ctor_name)
        qualifier = get_qualifier(qualifier_ast, mod)
        def_record(ctor, convert(Vector{Symbol}, map(first, pairs)), qualifier, mod)
    end
    nothing
end


function impl(t, variants :: Expr, mod :: Module)
    l :: LineNumberNode = LineNumberNode(1)
    abs_tvars = get_tvars(t)
    defs = []
    abst() = isempty(abs_tvars) ? t : :($t{$(abs_tvars...)})
    VAR = mangle(mod)

    for each in variants.args
        @match each begin
            ::LineNumberNode => (l = each)
            :($case{$(tvars...)} :: ($(params...), ) => $(ret_ty) where {$(gtvars...)})                          ||
            :($case{$(tvars...)} :: ($(params...), ) => $(ret_ty && Do(gtvars=[])))                              ||
            :($case{$(tvars...)} :: $(arg_ty && Do(params = [arg_ty])) => $ret_ty where {$(gtvars...)})          ||
            :($case{$(tvars...)} :: $(arg_ty && Do(params = [arg_ty])) => $(ret_ty && Do(gtvars=[])))            ||
            :($(case && Do(tvars = [])) :: ($(params...), ) => $(ret_ty) where {$(gtvars...)})                   ||
            :($(case && Do(tvars = [])) :: ($(params...), ) => $(ret_ty && Do(gtvars=[])))                       ||
            :($(case && Do(tvars = [])) :: $(arg_ty && Do(params = [arg_ty])) => $(ret_ty) where {$(gtvars...)}) ||
            :($(case && Do(tvars = [])) :: $(arg_ty && Do(params = [arg_ty])) => $(ret_ty && Do(gtvars=[])))     ||

            :($case($((params && Do(tvars=abs_tvars))...))) && Do(ret_ty = abst(), gtvars=[]) => begin

              config = Dict{Symbol, Any}([(gtvar isa Expr ? gtvar.args[1] : gtvar) => Any for gtvar in gtvars])

              pairs = map(enumerate(params)) do (i, each)
                 @match each begin
                    :($(a::Symbol && function (x) !is_symbol_capitalized(x) end)) => (a, Any, Any)
                    :($(a && function is_symbol_capitalized  end)) => (Symbol("_$i"), a, render(a, config))
                    :($field :: $ty)                => (field, ty, render(ty, config))
                 end
              end

              definition_body = [Expr(:(::), field, ty) for (field, ty, _) in pairs]
              constructor_args = [Expr(:(::), field, ty) for (field, _, ty) in pairs]
              arg_names = [field for (field, _, _) in pairs]
              spec_tvars = [tvars..., [Any for _ in gtvars]...]
              getfields = [:($VAR.$field) for field in arg_names]

              convert_fn = isempty(gtvars) ? nothing : let (=>) = (a, b) -> convert(b, a)
                        out_tvars    = [tvars..., fill(nothing, length(gtvars))...] => Vector{Any}
                        inp_tvars    = [tvars..., fill(nothing, length(gtvars))...] => Vector{Any}
                        fresh_tvars1 = fill(nothing, length(gtvars)) => Vector{Any}
                        fresh_tvars2 = fill(nothing, length(gtvars)) => Vector{Any}
                        tcovs = []
                        for (i, _) in enumerate(gtvars)
                            TAny = mangle(mod)
                            TCov = mangle(mod)
                            push!(tcovs, TCov)
                            fresh_tvars2[end-i + 1] = :($TCov <: $TAny)
                            fresh_tvars1[end-i + 1] = TAny
                            inp_tvars[end-i + 1] = TAny
                            out_tvars[end-i + 1] = TCov
                        end
                        tcovs = reverse(tcovs)
                        arg2 = :($VAR :: $case{$(inp_tvars...)})
                        arg1_cov = :($Type{$case{$(out_tvars...)}})
                        arg1_abs = :($Type{$t{$(tcovs...)}})
                        casted = :($case{$(out_tvars...)}($(getfields...)))
                        quote
                            $Base.convert(::$arg1_cov, $arg2) where {$(tvars...), $(fresh_tvars1...), $(fresh_tvars2...)} = $casted
                            $Base.convert(::$arg1_abs, $arg2) where {$(tvars...), $(fresh_tvars1...), $(fresh_tvars2...)} = $casted
                        end
                    end

            definition_head = :($case{$(tvars...), $(gtvars...)})
            def_cons =
                isempty(spec_tvars) ?
                    !isempty(constructor_args) ?
                    quote
                        function $case(;$(constructor_args...))
                            $case($(arg_names...))
                        end
                    end                       :
                    nothing        :
                    quote
                        function $case($(constructor_args...), ) where {$(tvars...)}
                            $case{$(spec_tvars...)}($(arg_names...))
                        end
                    end

              definition = @format [case, l, ret_ty, definition_head] quote
                 struct definition_head <: ret_ty
                     l
                     $(definition_body...)
                 end
                 $def_cons
                 $convert_fn
              end
              push!(defs, (case, pairs, definition))
            end
        end
    end
    defs
end

end # module
