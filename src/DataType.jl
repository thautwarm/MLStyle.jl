module DataType
using MLStyle
using MLStyle.Render
using MLStyle.toolz: isCapitalized, ($), cons, nil, ast_and
using MLStyle.MatchCore
using MLStyle.Pervasive
using MLStyle.Pervasive: @typed_pattern

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
    typename, original_def =
        @match typ begin
           :($typename{$(a...)})       => (typename, (spec_name) -> :($spec_name{$(a...)}))
           :($typename{$(a...)} <: $b) => (typename, (spec_name) -> :($spec_name{$(a...)} <: $b))
           :($typename)                => (typename, identity)
           :($typename <: $b)          => (typename, (spec_name) -> :($spec_name <: $b))
        end

    spec_name = Symbol("MLStyle.ADTUnion.", typename)
    original_ty_ast = original_def(spec_name)

    mod.eval(:(abstract type $original_ty_ast end))

    original_ty = getfield(mod, spec_name)
    tvars_of_abst = get_tvars(original_ty)

    if isempty(tvars_of_abst)
        mod.eval $ quote
            $typename = $Union{$original_ty, $Type{$original_ty}}
        end
    else
        concrete_orig = :($original_ty{$(tvars_of_abst...)})
        mod.eval(:($typename{$(tvars_of_abst...)} = $Union{$concrete_orig, $Type{$concrete_orig}}))
    end

    for (ctor_name, pairs, each) in impl(original_ty, def_variants, mod)
        mod.eval(each)
        ctor = getfield(mod, ctor_name)
        export_anchor_var = Symbol("MLStyle.ADTConstructor.", ctor_name)
        mod.eval(@format [export_anchor_var] quote
                     export export_anchor_var
                     export_anchor_var = true
                 end)
        qualifier_ =
            @match qualifier begin
                :public   => shareThrough(export_anchor_var, true)
                :internal => internal
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
              NAME   = mangle(mod)

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
                    _ => @error "The field name of destructor must be a Symbol!"
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
                 @error "Destructor should be used in the form of `C(a, b, c)` or `C(a=a, b=b, c=c)` or `C(_)`"
              end |> x -> (TARGET, NAME, reduce(∘, x, init=identity))

        end

        defAppPattern(mod,
                      predicate = (hd_obj, args) -> hd_obj === ctor,
                      rewrite   = (tag, hd_obj, destruct_fields, mod) -> begin
                        TARGET, NAME, match_fields = mk_match(tag, hd_obj, destruct_fields, mod)
                        (@typed_pattern hd_obj) ∘ match_fields
                      end,
                      qualifiers = Set([qualifier_]))


        # GADT syntax support!!!
        defGAppPattern(mod,
                      predicate = (spec_vars, hd_obj, args) -> hd_obj === ctor,
                      rewrite   = (tag, forall, hd, destruct_fields, mod) -> begin
                        TARGET, NAME, match_fields = mk_match(tag, hd, destruct_fields, mod)
                        L = LineNumberNode(1)
                        if forall === nothing
                            function (body)
                                @format [TARGET, NAME, tag, body, failed, L, hd] quote
                                    @inline L function NAME(TARGET :: hd)
                                        body
                                    end
                                    @inline L function NAME(_)
                                        failed
                                    end
                                    NAME(tag)
                                end
                            end
                        else
                            function (body)
                                @format [TARGET, NAME, tag, body, failed, L, hd] quote
                                    @inline L function NAME(TARGET :: hd) where {$(forall...)}
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
    abst = isempty(abs_tvars) ? t : :($t{$(abs_tvars...)})
    for each in variants.args
        @match each begin
            ::LineNumberNode => (l = each)
            :($case{$(tvars...)}($(params...))) ||
            :($case($((params && Do(tvars=[]))...))) => begin
              pairs = map(enumerate(params)) do (i, each)
                 @match each begin
                    :($(a::Symbol && function isSymCap  end)) => (Symbol("_$i"), a)
                    :($(a::Symbol && function (x) !isSymCap(x) end)) => (a, Any)
                    :($field :: $ty)                => (field, ty)
                 end
              end
              definition_body = [Expr(:(::), field, ty) for (field, ty) in pairs]
              definition_head = :($case{$(abs_tvars...), $(tvars...)})
              definition = @format [l, abst, definition_head] quote
                 struct definition_head <: abst
                     l
                     $(definition_body...)
                 end
              end
              push!(defs, (case, pairs, definition))
            end
        end
    end
    defs
end

end # module
