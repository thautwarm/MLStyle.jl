module Qualification
export deprecate_qualifier_macro

@nospecialize
function deprecate_qualifier_macro(o, ln::LineNumberNode)
    s = string(o)
    trunc = min(length(s), 20)
    s = SubString(s, 1:trunc)
    @warn (
        "Deprecated use of qualifier $s at $(ln.file):$(ln.line):\n" *
        "Scoping specifiers such as 'internal', 'public' are deprecated. " *
        "Now the scope of a pattern is consistent with the visibility of the pattern object in current module."
    )
end
@specialize

end