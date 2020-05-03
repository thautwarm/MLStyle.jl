module DataType
using MLStyle
using MLStyle.Qualification
using MLStyle.Record
using MLStyle.ExprTools

export @data



"""
Codegen for `@data`, e.g.,

```
@data A begin              abstract type A end
    A1(Int, Int)     ≡     struct A1
                               _1 :: Int
end                            _2 :: Int
                           end


@data B{T}<:A begin        abstract type B{T} <: A end
    B1(T, Int)        ≡    struct B1{T}
end                            _1 :: T
                               _2 :: Int
                           end


@data C{T}<:B{T} begin          abstract type C{T} <: B{T} end
    C1{A, B} ::
    (A, B)=>C{Tuple{A, B}} ≡    struct C1{A, B} <: C{Tuple{A, B}}
end                                 _1 :: A
                                    _2 :: B
                                end


@data D{T}<:A begin        abstract type D{T} <: A end
    D1(a::T)          ≡    struct D1{T} <: D{T}
end                            a :: T
                           end
```

Additionally, `@data` macros setup up pattern matching for those datatypes.
```julia

@data S begin
    S1(Int)
end

@match S1(1) begin
    S1(x) => x == 1
end # => true
```
"""
macro data(typ, def_variants)
    data(typ, def_variants, :public, __module__) |> esc
end

macro data(qualifier, typ, def_variants)
    deprecate_qualifiers(qualifier)
    data(typ, def_variants, qualifier, __module__) |> esc
end

function data(typ, def_variants, mod, line)
    typename, tvars_of_abst = @match typ begin
        :($typename{$(a...)}) => (typename, get_type_parameters_ordered(a))
        :($typename{$(a...)} <: $b) => (typename, get_type_parameters_ordered(a))
        :($typename <: $b) => (typename, Symbol[])
        :($(typename::Symbol)) => (typename, Symbol[])
    end

    ret = Expr(:block, :(abstract type $typ end))
    for (ctor_name, pairs, each) in impl(typename, tvars_of_abst, def_variants, mod, line)
        push!(ret.args, each, record_def(ctor_name, line))
    end
    ret
end


function impl(t, variants::Expr, mod::Module, ln::LineNumberNode)
    abs_tvars = collect(get_tvars(t))
    defs = []
    abst() = isempty(abs_tvars) ? t : :($t{$(abs_tvars...)})
    VAR = mangle(mod)

    for each in variants.args
        @switch each begin
            @case ::LineNumberNode
            ln = each
            continue

            @case :($case{$(generic_tvars...)}::($(params...),) =>
                          $(ret_ty) where {$(implicit_tvars...)}
                  )   ||
                  :($case{$(generic_tvars...)}::($(params...),) => ret_ty) &&
                  let implicit_tvars = []
                  end ||
                  :(
                      $case{$(generic_tvars...)}::$arg_ty =>
                          $ret_ty where {$(implicit_tvars...)}
                  ) && let params = [arg_ty]
                  end ||
                  :($case{$(generic_tvars...)}::$arg_ty => $ret_ty) &&
                  let params = [arg_ty], implicit_tvars = []
                  end ||
                  :($case::($(params...),) => $(ret_ty) where {$(implicit_tvars...)}) &&
                  let generic_tvars = []
                  end ||
                  :($case::($(params...),) => $ret_ty) &&
                  let generic_tvars = [], implicit_tvars = []
                  end ||
                  :($case::$arg_ty => $ret_ty where {$(implicit_tvars...)}) &&
                  let generic_tvars = [], params = [arg_ty]
                  end ||
                  :($case::$arg_ty => $ret_ty) &&
                  let generic_tvars = [], params = [arg_ty], implicit_tvars = []
                  end ||
                  :($case($(params...))) &&
                  let ret_ty = abst(), implicit_tvars = [], generic_tvars = abs_tvars
                  end

                config = Dict{Symbol,Any}(
                    [(gtvar isa Expr ? gtvar.args[1] : gtvar) => Any for
                    gtvar in implicit_tvars],
                )

                pairs = map(enumerate(params)) do (i, each)
                    @match each begin
                        a::Symbol =>
                            Base.isuppercase(string(each)[1] ?
                                (a, Any, Any) :
                                (Symbol("_$i"), a, render(a, config))
                            
                        :($field::$ty) => (field, ty, render(ty, config))
                    end
                end

                definition_body = [Expr(:(::), field, ty) for (field, ty, _) in pairs]
                constructor_args = [Expr(:(::), field, ty) for (field, _, ty) in pairs]
                arg_names = [field for (field, _, _) in pairs]
                getfields = [:($VAR.$field) for field in arg_names]
                definition_head = :($case{$(generic_tvars...),$(implicit_tvars...)})

                generic_tvars = collect(map(to_tvar, extract_tvars(generic_tvars)))
                implicit_tvars = collect(map(to_tvar, extract_tvars(implicit_tvars)))

                convert_fn = isempty(implicit_tvars) ? nothing :
                        let (=>) = (a, b) -> convert(b, a)
                    out_tvars = [generic_tvars; implicit_tvars]
                    inp_tvars = [generic_tvars; [mangle(mod) for _ in implicit_tvars]]
                    fresh_tvars1 = []
                    fresh_tvars2 = []
                    n_generic_tvars = length(generic_tvars)
                    for i in 1+n_generic_tvars:length(implicit_tvars)+n_generic_tvars
                        TAny = inp_tvars[i]
                        TCov = out_tvars[i]
                        push!(fresh_tvars2, :($TCov <: $TAny))
                        push!(fresh_tvars1, TAny)
                    end
                    arg2 = :($VAR::$case{$(inp_tvars...)})
                    arg1_cov = :($Type{$case{$(out_tvars...)}})
                    arg1_abs = :($Type{$ret_ty})
                    casted = :($case{$(out_tvars...)}($(getfields...)))
                    quote
                        $Base.convert(
                            ::$arg1_cov,
                            $arg2,
                        ) where {
                            $(generic_tvars...),
                            $(fresh_tvars1...),
                            $(fresh_tvars2...),
                        } = $casted
                        $Base.convert(
                            ::$arg1_abs,
                            $arg2,
                        ) where {
                            $(generic_tvars...),
                            $(fresh_tvars1...),
                            $(fresh_tvars2...),
                        } = $casted
                    end
                end

                def_cons = isempty(generic_tvars) && isempty(implicit_tvars) ?
                        !isempty(constructor_args) ?
                        quote
                    function $case(; $(constructor_args...))
                        $case($(arg_names...))
                    end
                end : nothing :
                        let spec_tvars = [generic_tvars; [Any for _ in implicit_tvars]]
                    if isempty(generic_tvars)
                        quote
                            function $case($(constructor_args...))
                                $case{$(spec_tvars...)}($(arg_names...))
                            end
                        end
                    else
                        quote
                            function $case($(constructor_args...)) where {$(generic_tvars...)}
                                $case{$(spec_tvars...)}($(arg_names...))
                            end
                        end
                    end
                end

                definition = @format [case, l, ret_ty, definition_head] quote
                    struct definition_head <: ret_ty
                        l::Any
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
