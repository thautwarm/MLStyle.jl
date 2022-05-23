module DataType

if isdefined(Base, :Experimental)
    Base.Experimental.@compiler_options optimize=0 compile=min infer=no
end


using MLStyle
using MLStyle.MatchImpl
using MLStyle.Qualification
using MLStyle.Record: as_record
using MLStyle.ExprTools

UNREACHABLE = nothing
export @data
@nospecialize

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
    deprecate_qualifier_macro(qualifier, __source__)
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
    suite::Vector{Any},
    @nospecialize(abs_t),
    abs_tvars::Vector{Symbol},
    variants::Expr,
    ln::LineNumberNode,
    mod::Module,
)
    abst() = isempty(abs_tvars) ? abs_t : :($abs_t{$(abs_tvars...)})
    for each in variants.args
        @switch each begin
            @case ::LineNumberNode
            ln = each
            continue

            @case Do[is_enum = false] && (
                :(
                    $case{$(generic_tvars...)}::($(params...),) =>
                        $(ret_ty) where {$(constraints...)}
                ) ||
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
                end ||
                :($case{$generic_tvars...}::$ret_ty where {$(constraints...)}) &&
                if error(
                    "Defining generic enum $each is invalid as Julia does not support generic value.",
                )
                end && let params = []
                end ||
                :($case{$generic_tvars...}::$ret_ty) &&
                if error(
                    "Defining generic enum $each is invalid as Julia does not support generic value.",
                )
                end && let params = [], constraints = []
                end ||
                :($(case::Symbol)::$ret_ty) &&
                Do[is_enum = true] &&
                let params = [], constraints = [], generic_tvars = []
                end ||
                (case::Symbol) &&
                Do[is_enum = true] &&
                if isempty(abs_tvars) || error(
                    "Defining generic enum $case <: $(abst()) is invalid, as Julia does not support generic value.",
                )
                end &&
                Do[is_enum = true] &&
                let ret_ty = abst(), params = [], constraints = [], generic_tvars = []
                end
            )

            ctor_name = is_enum ? Symbol(case, "'s constructor") : case
            expr_field_def = Expr(:block, ln)
            suite_field_def = expr_field_def.args
            field_symbols = Symbol[]
            for i in eachindex(params)
                each = params[i]
                @match each begin
                    a::Symbol &&
                        # TODO: check length of symbol?
                            (
                                if Base.isuppercase(string(each)[1])
                                end && let field = Symbol("_$i"), ty = a
                                end || let field = a, ty = Any
                                end
                            ) ||
                        :($field::$ty) ||
                        (:(::$ty) || ty) && let field = Symbol("_$i")
                        end => begin
                        argdecl = :($field::$ty)
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
                Expr(:(<:), Expr(:curly, ctor_name, generic_tvars...), ret_ty),
                expr_field_def,
            )

            expr_infer_constructor = if isempty(constraints)
                UNREACHABLE
            else
                call = Expr(:call, ctor_name, suite_field_def[2:end]...)
                type_arguments = get_type_parameters_ordered(generic_tvars)
                fn_sig = Expr(:where, call, generic_tvars...)
                Expr(
                    :function,
                    fn_sig,
                    Expr(
                        :block,
                        Expr(
                            :let,
                            Expr(:block, constraints...),
                            Expr(
                                :call,
                                :($ctor_name{$(type_arguments...)}),
                                field_symbols...,
                            ),
                        ),
                    ),
                )
            end

            expr_setup_record = if is_enum
                err_msg = "Enumeration $case should take 0 argument, type parameter or type argument."
                Expr(
                    :block,
                    ln,
                    :(
                        $MLStyle.pattern_uncall(::$ctor_name, _, tparams, targs, args) =
                            isempty(targs) &&
                            isempty(tparams) &&
                            isempty(args) &&
                            (return $MLStyle.AbstractPatterns.literal($case)) ||
                            error($err_msg)
                    ),
                    :($MLStyle.is_enum(::$ctor_name) = true),
                    :(const $case = $ctor_name.instance),
                    :(
                        $Base.show(io::$IO, ::$ctor_name) =
                            $Base.print(io, $(string(case)))
                    ),
                )
            else
                as_record(ctor_name, ln, mod)
            end

            push!(suite, expr_struct_def, expr_infer_constructor, expr_setup_record)
            continue
            @case :($case{$(_...)}) &&
                  if error("invalid enum constructor $each, use $case instead.")
            end
            @case _
            error("unrecognised data constructor $each.")
        end
    end
end
@specialize
end # module
