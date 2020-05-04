module Qualification
export deprecate_qualifiers

function deprecate_qualifiers(o)
    s = string(o)
    trunc = min(length(s), 20)
    s = SubString(s, 1:trunc)
    Base.depwarn(
        "When using qualifier '$(s)': " *
        "Scoping specifiers such as 'internal', 'public' are deprecated. " *
        "Now the scope of a pattern is consistent with the visibility of the pattern object in current module.",
        :qualifier
    )
end

end