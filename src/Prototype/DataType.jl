module DataType
using MLStyle.Prototype
using MLStyle.Prototype.toolz: isCapitalized, ($), cons, nil, ast_and
using MLStyle.Prototype.MatchCore
using MLStyle.Prototype.Infras
using MLStyle.Prototype.Pervasives
using MLStyle.Prototype.Render: render

export @data
isSymCap = isCapitalized ∘ string


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

function data(typ, def_variants, qualifier, mod)
    typename =
        @match typ begin
           :($typename{$(a...)})       => typename
           :($typename{$(a...)} <: $b) => typename
           :($typename)                => typename
           :($typename <: $b)          => typename
        end

    mod.eval(:(abstract type $typ end))

    original_ty = getfield(mod, typename)
    tvars_of_abst = get_tvars(original_ty)

    for (ctor_name, pairs, each) in impl(original_ty, def_variants, mod)
        mod.eval(each)
        ctor = getfield(mod, ctor_name)
        export_anchor_var = Symbol("MLStyle.Prototype.ADTConstructor.", ctor_name)
        mod.eval(@format [export_anchor_var] quote
                     export export_anchor_var
                     export_anchor_var = true
                 end)
        qualifier_ =
            @match qualifier begin
                :public   => shareThrough(export_anchor_var, true)
                :internal => internal
                :(visible in [$(mods...)]) => shareWith(Set(map(mod.eval, mods)))
            end
        n_destructor_args = length(pairs)

        mk_match(tag, hd_obj, destruct_fields, mod) = begin
              check_if_given_field_names = map(destruct_fields) do field
                @match field begin
                  Expr(:kw, _...) => true
                  _               => false
                end
              end
              TARGET = mangle(mod)

              if all(check_if_given_field_names) # begin if
                map(destruct_fields) do field_
                  @match field_ begin
                    Expr(:kw, field::Symbol, pat) => begin
                        let ident = mangle(mod), field = field
                            function(body)
                                @format [TARGET, body, ident] quote
                                    ident = TARGET.$field
                                    body
                                end
                            end ∘ mkPattern(ident, pat, mod)
                        end
                    end
                    _ => @syntax_err "The field name of destructor must be a Symbol!"
                  end
                end
              elseif all(map(!, check_if_given_field_names))
                 n_d = length(destruct_fields)
                 if n_d == 1 && destruct_fields[1] == :(_)
                    []
                    # ignore fields
                 else
                     @assert n_d == n_destructor_args "Malformed destructing for case class $ctor_name(from module $(nameof(mod)))."
                     map(zip(destruct_fields, pairs)) do (pat, (field, _))
                            let ident = mangle(mod)
                                function (body)
                                    @format [tag, body, ident] quote
                                        ident = tag.$field
                                        body
                                    end
                                end ∘ mkPattern(ident, pat, mod)
                            end
                     end
                 end
              else
                 @syntax_err "Destructor should be used in the form of `C(a, b, c)` or `C(a=a, b=b, c=c)` or `C(_)`"
            end |> x -> (TARGET, reduce(∘, x, init=identity))

        end

        defAppPattern(mod,
                      predicate = (hd_obj, args) -> hd_obj === ctor,
                      rewrite   = (tag, hd_obj, destruct_fields, mod) -> begin
                        TARGET, match_fields = mk_match(tag, hd_obj, destruct_fields, mod)
                        (@typed_as hd_obj) ∘ match_fields
                      end,
                      qualifiers = Set([qualifier_]))


        # GADT syntax support!!!
        defGAppPattern(mod,
                      predicate = (spec_vars, hd_obj, args) -> hd_obj === ctor,
                      rewrite   = (tag, forall, spec_vars, hd_obj, destruct_fields, mod) -> begin
                        hd = :($hd_obj{$(spec_vars...)})
                        TARGET, match_fields = mk_match(tag, hd, destruct_fields, mod)
                        if forall === nothing
                            @typed_as hd
                        else
                            function (body)
                                NAME = mangle(mod)
                                @format [TARGET, tag, body, hd] quote
                                    @inline __L__ function NAME(TARGET :: hd) where {$(forall...)}
                                        body
                                    end
                                    @inline L function NAME(_)
                                        failed
                                    end
                                    NAME(tag)
                                end
                            end
                        end ∘ match_fields
                      end,
                      qualifiers = Set([qualifier_]))
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
                    :($(a::Symbol && function (x) !isSymCap(x) end)) => (a, Any, Any)
                    :($(a && function isSymCap  end)) => (Symbol("_$i"), a, render(a, config))
                    :($field :: $ty)                => (field, ty, render(ty, config))
                 end
              end

              definition_body = [Expr(:(::), field, ty) for (field, ty, _) in pairs]
              constructor_args = [Expr(:(::), field, ty) for (field, _, ty) in pairs]
              arg_names = [field for (field, _, _) in pairs]
              spec_tvars = [tvars..., [Any for _ in gtvars]...]
              getfields = [:($VAR.$field) for field in arg_names]

              convert_fn = isempty(gtvars) ? nothing : let (=>) = (a, b) -> convert(b, a)
                        out_tvars    = fill(nothing, length(spec_tvars)) => Vector{Any}
                        inp_tvars    = fill(nothing, length(spec_tvars)) => Vector{Any}
                        fresh_tvars1 = fill(nothing, length(gtvars)) => Vector{Any}
                        fresh_tvars2 = fill(nothing, length(gtvars)) => Vector{Any}

                        for (i, _) in enumerate(gtvars)
                            TAny = mangle(mod)
                            TCov = mangle(mod)
                            fresh_tvars2[end-i + 1] = :($TCov <: $TAny)
                            fresh_tvars1[end-i + 1] = TAny
                            inp_tvars[end-i + 1] = TAny
                            out_tvars[end-i + 1] = TCov
                        end

                        arg1 = :($Type{$case{$(out_tvars...)}})
                        arg2 = :($VAR :: $case{$(inp_tvars...)})
                        specialized = :($case{$(out_tvars...)}($(getfields...)))
                        quote
                            $Base.convert(::$arg1, $arg2) where {$(tvars...), $(fresh_tvars1...), $(fresh_tvars2...)} = $specialized
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
