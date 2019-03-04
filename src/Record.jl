module Record
using MLStyle
using MLStyle.Toolz: isCapitalized, ($), cons, nil
using MLStyle.MatchCore
using MLStyle.Qualification
using MLStyle.Infras
using MLStyle.Pervasives
using MLStyle.Render: render

export @as_record
export def_record

function def_record(ctor, record_fields, qualifier :: Qualifier, mod)
    ctor_name = string(ctor)
    n_destructor_args = length(record_fields)
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
                        end ∘ mk_pattern(ident, pat, mod)
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
                map(zip(destruct_fields, record_fields)) do (pat, field)
                        let ident = mangle(mod)
                            function (body)
                                @format [TARGET, body, ident] quote
                                    ident = TARGET.$field
                                    body
                                end
                            end ∘ mk_pattern(ident, pat, mod)
                        end
                end
            end
        else
            @syntax_err "Destructor should be used in the form of `C(a, b, c)` or `C(a=a, b=b, c=c)` or `C(_)`"
        end |> x -> (TARGET, reduce(∘, x, init=identity))

    end

    def_app_pattern(mod,
                predicate = (hd_obj, args) -> hd_obj === ctor,
                rewrite   = (tag, hd_obj, destruct_fields, mod) -> begin
                    TARGET, match_fields = mk_match(tag, hd_obj, destruct_fields, mod)
                    (@typed_as hd_obj) ∘ match_fields
                end,
                qualifiers = Set([qualifier]))


    # GADT syntax support!!!
    def_gapp_pattern(mod,
                predicate = (spec_vars, hd_obj, args) -> hd_obj === ctor,
                rewrite   = (tag, forall, spec_vars, hd_obj, destruct_fields, mod) -> begin
                    hd = :($hd_obj{$(spec_vars...)})
                    TARGET, match_fields = mk_match(tag, hd, destruct_fields, mod)
                    if isempty(forall)
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
                qualifiers = Set([qualifier]))
    ctor
end


macro as_record(qualifier, ctor)
    let mod = __module__, ctor = mod.eval(ctor)
        def_record(ctor, fieldnames(ctor), get_qualifier(qualifier, mod), mod)
    end
end

macro as_record(ctor)
    let mod = __module__, ctor = mod.eval(ctor)
        def_record(ctor, fieldnames(ctor), get_qualifier(:public, mod), mod)
    end
end

end