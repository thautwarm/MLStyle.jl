module DataType
using MLStyle.MatchImpl
using MLStyle.Qualification
using MLStyle.Record: as_record
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
    esc(data(typ, def_variants, __source__, __module__))
end

macro data(qualifier, typ, def_variants)
    deprecate_qualifiers(string(qualifier))
    esc(data(typ, def_variants, __source__, __module__))
end

function data(typ::Any, def_variants::Expr, line::LineNumberNode, mod::Module)
    typename, tvars_of_abst = @match typ begin
        :($typename{$(a...)}) => (typename, get_type_parameters_ordered(a))
        :($typename{$(a...)} <: $b) => (typename, get_type_parameters_ordered(a))
        :($typename <: $b) => (typename, Symbol[])
        :($(typename::Symbol)) => (typename, Symbol[])
    end

    ret = Expr(:block, :(abstract type $typ end))
    impl!(ret.args, typename, tvars_of_abst, def_variants, line, mod)
    ret
end

function impl!(
    suite::AbstractArray,
    abs_t,
    abs_tvars::Vector{Symbol},
    variants::Expr,
    ln::LineNumberNode,
    mod::Module
)
    abst() = isempty(abs_tvars) ? abs_t : :($abs_t{$(abs_tvars...)})
    for each in variants.args
        @switch each begin
            @case ::LineNumberNode
            ln = each
            continue

            @case :($case{$(generic_tvars...)}::($(params...),) =>
                          $(ret_ty) where {$(constraints...)}
                  )   ||
                  :($case{$(generic_tvars...)}::($(params...),) => $ret_ty) &&
                  let constraints = []
                  end ||
                  :(
                      $case{$(generic_tvars...)}::$arg_ty =>
                          $ret_ty where {$(constraints...)}
                  ) && let params = [arg_ty]
                  end ||
                  :($case{$(generic_tvars...)}::$arg_ty => $ret_ty) &&
                  let params = [arg_ty], constraints = []
                  end ||
                  :($case::($(params...),) => $(ret_ty) where {$(constraints...)}) &&
                  let generic_tvars = []
                  end ||
                  :($case::($(params...),) => $ret_ty) &&
                  let generic_tvars = [], constraints = []
                  end ||
                  :($case::$arg_ty => $ret_ty where {$(constraints...)}) &&
                  let generic_tvars = [], params = [arg_ty]
                  end ||
                  :($case::$arg_ty => $ret_ty) &&
                  let generic_tvars = [], params = [arg_ty], constraints = []
                  end ||
                  :($case($(params...))) &&
                  let ret_ty = abst(), constraints = [], generic_tvars = abs_tvars
                  end
                
                
                expr_field_def = Expr(:block, ln)
                suite_field_def = expr_field_def.args
                field_symbols = Symbol[]
                for i in eachindex(params)
                    each = params[i]
                    @match each begin
                        a::Symbol &&
                             # TODO: check length of symbol?
                            (if Base.isuppercase(string(each)[1]) end &&
                                let field = Symbol("_$i"), ty = a end
                            ||  let field = a, ty = Any end) ||
                        :($field :: $ty) ||
                        (:(::$ty) || ty) && let field = Symbol("_$i") end =>
                            begin
                                argdecl = :($field :: $ty)
                                push!(suite_field_def, argdecl)
                                push!(field_symbols, field)
                                nothing
                            end
                        _ => error("invalid datatype field $each")
                    end
                end
                
                expr_struct_def = Expr(
                    :struct,
                    false,
                    Expr(:(<:),
                        Expr(:curly, case, generic_tvars...),
                        ret_ty
                    ),
                    expr_field_def
                )
                
                expr_infer_constructor = if isempty(constraints)
                     nothing
                else
                    call = Expr(:call, case, suite_field_def[2:end]...)
                    type_arguments = get_type_parameters_ordered(generic_tvars)
                    fn_sig = Expr(:where, call, generic_tvars...)
                    Expr(
                        :function,
                        fn_sig,
                        Expr(:block,
                            Expr(:let,
                                Expr(:block, constraints...),
                                Expr(:call,
                                    :($case{$(type_arguments...)}),
                                    field_symbols...
                                )
                            )
                        )
                    )
                end

                expr_setup_record = as_record(case, ln, mod)
                push!(
                    suite,
                    expr_struct_def,
                    expr_infer_constructor,
                    expr_setup_record
                )
            # TODO: @case _
        end
    end
end
end # module
