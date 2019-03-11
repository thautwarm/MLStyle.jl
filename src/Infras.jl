module Infras
using MLStyle.MatchCore
using MLStyle.Extension
using MLStyle.Err
using MLStyle.Toolz: ($)
using MLStyle.Render: render, format

const __L__ = @__LINE__
export @format
macro format(args, template)
    args = Expr(:vect, :__L__ => LineNumberNode(__L__), :failed => QuoteNode(:($MatchCore.failed)), args.args...)
    esc(format(args, template))
end

export @typed_as
"""
this macro provide a convenient and type-stable way to generate
type checking.

However, the generated code requires a given variable `TARGET`
in metaprogramming level.

e.g

TARGET = :target_id
(@typed_as Int) # which generates a pattern to check if type is Int.

"""
macro typed_as(t)
    esc $ quote
        NAME = mangle(mod)
        __T__ = $t
        function (body)
            @format [body, tag, TARGET, NAME, __T__] quote

                @inline __L__ function NAME(TARGET :: __T__)
                    __T__
                    body
                end

                @inline __L__ function NAME(TARGET)
                    failed
                end

                NAME(tag)
            end
        end
    end
end

export patternOr
patternOr  = (p1, p2) -> body ->
    let p1 = p1(body), p2 = p2(body)
        tmp = mangle(Infras)
        @format [tmp, p1, p2] quote
            tmp = p1
            tmp === failed ? p2 : tmp
        end
    end


const APP_DESTRUCTORS = Vector{Tuple{Module, PDesc}}()
const GAPP_DESTRUCTORS = Vector{Tuple{Module, PDesc}}()

export def_pattern
function def_pattern(mod; predicate, rewrite, qualifiers=nothing)
    qualifiers = qualifiers === nothing ? Set([invasive]) : qualifiers
    desc = PDesc(predicate, rewrite, qualifiers)
    register_pattern(desc, mod)
end


# ======= App Patterns =============

export register_app_pattern
function register_app_pattern(pdesc :: PDesc, def_mod::Module)
    push!(APP_DESTRUCTORS, (def_mod, pdesc))
end

export def_app_pattern
function def_app_pattern(mod; predicate, rewrite, qualifiers=nothing)
    qualifiers = qualifiers === nothing ? Set([invasive]) : qualifiers
    desc = PDesc(predicate, rewrite, qualifiers)
    register_app_pattern(desc, mod)
end

export mk_app_pattern
function mk_app_pattern(tag, hd, tl, use_mod)
    if isdefined(use_mod, hd)
        hd = getfield(use_mod, hd)
        for (def_mod, desc) in APP_DESTRUCTORS
            if qualifier_test(desc.qualifiers, use_mod, def_mod) && desc.predicate(hd, tl)
                return desc.rewrite(tag, hd, tl, use_mod)
            end
        end
    end
    info = string(hd) * "(" * string(tl) * ")"
    throw $ PatternUnsolvedException("invalid usage or unknown application case $info.")
end

# ===================================

# ===== Generalized App Patterns ====

export def_gapp_pattern
function def_gapp_pattern(mod; predicate, rewrite, qualifiers=nothing)
    qualifiers = qualifiers === nothing ? Set([invasive]) : qualifiers
    desc = PDesc(predicate, rewrite, qualifiers)
    register_gapp_pattern(desc, mod)
end

export register_gapp_pattern
function register_gapp_pattern(pdesc :: PDesc, def_mod::Module)
    push!(GAPP_DESTRUCTORS, (def_mod, pdesc))
end

export mk_gapp_pattern
function mk_gapp_pattern
end

# ===================================

def_pattern(Infras,
    predicate = x -> x isa Expr && x.head == :call,
    rewrite = (tag, case, mod) ->
    let hd = case.args[1], tl = case.args[2:end]
    hd isa Symbol ? mk_app_pattern(tag, hd, tl, mod) : mk_gapp_pattern(tag, [], hd, tl, mod)
    end)

end