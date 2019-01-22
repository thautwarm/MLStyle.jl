module Infras
using MLStyle.MatchCore
using MLStyle.Extension
using MLStyle.Err
using MLStyle.toolz: ($)
using MLStyle.Render: render, format

export @format
macro format(args, template)
    __L__ = @__LINE__
    args = Expr(:vect, :__L__ => __L__, :failed => failed, args.args...)
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
                    $failed
                end

                NAME(tag)
            end
        end
    end
end


export @capture_type
"""
this macro provide a convenient and type-stable way to capture type
as a given variable.

Requires metavar `TARGET`.
e.g

TARGET = :target_id
(@typed_as T) # which generates a pattern to bind type of `TARGET` as `T`
"""
macro capture_type(t)
    esc $ quote
        NAME = mangle(mod)
        __T__ = $t
        function (body)
            @format [body, tag, NAME, TARGET, __T__] quote
                @inline __L__ function NAME(TARGET :: __T__) where __T__
                    __T__ # if not put this here, an error would be raised : "local variable XXX cannot be used in closure declaration"
                    body
                end
                NAME(tag)
            end
        end
    end
end


export patternAnd, patternOr
patternAnd = ∘
patternOr  = (p1, p2) -> body ->
    let p1 = p1(body), p2 = p2(body)
        tmp = mangle(Infras)
        @format [tmp, p1, p2] quote
            tmp = p1
            tmp === failed ? p2 : tmp
        end
    end


destructors = Vector{Tuple{Module, pattern_descriptor}}()
generalized_destructors = Vector{Tuple{Module, pattern_descriptor}}()

export defPattern
function defPattern(mod; predicate, rewrite, qualifiers=nothing)
    qualifiers = qualifiers === nothing ? Set([invasive]) : qualifiers
    desc = pattern_descriptor(predicate, rewrite, qualifiers)
    registerPattern(desc, mod)
end


# ======= App Patterns =============

export registerAppPattern
function registerAppPattern(pdesc :: pattern_descriptor, def_mod::Module)
    push!(destructors, (def_mod, pdesc))
end

export defAppPattern
function defAppPattern(mod; predicate, rewrite, qualifiers=nothing)
    qualifiers = qualifiers === nothing ? Set([invasive]) : qualifiers
    desc = pattern_descriptor(predicate, rewrite, qualifiers)
    registerAppPattern(desc, mod)
end

function mkAppPattern(tag, hd, tl, use_mod)
    hd = use_mod.eval(hd)
    for (def_mod, desc) in destructors
        if qualifierTest(desc.qualifiers, use_mod, def_mod) && desc.predicate(hd, tl)
            return desc.rewrite(tag, hd, tl, use_mod)
        end
    end
    info = string(hd) * "(" * string(tl) * ")"
    throw $ PatternUnsolvedException("invalid usage or unknown application case $info.")
end

# ===================================

# ===== Generalized App Patterns ====

export defGAppPattern
function defGAppPattern(mod; predicate, rewrite, qualifiers=nothing)
    qualifiers = qualifiers === nothing ? Set([invasive]) : qualifiers
    desc = pattern_descriptor(predicate, rewrite, qualifiers)
    registerGAppPattern(desc, mod)
end

export registerGAppPattern
function registerGAppPattern(pdesc :: pattern_descriptor, def_mod::Module)
    push!(generalized_destructors, (def_mod, pdesc))
end

export mkGAppPattern
function mkGAppPattern
end

# ===================================

defPattern(Infras,
    predicate = x -> x isa Expr && x.head == :call,
    rewrite = (tag, case, mod) ->
    let hd = case.args[1], tl = case.args[2:end]
    hd isa Symbol ? mkAppPattern(tag, hd, tl, mod) : mkGAppPattern(tag, [], hd, tl, mod)
    end)

end