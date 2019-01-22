module MLStyle

# export Feature , @case, @data, @def, @match, Fun, (⇒), Pattern, Case, Failed, failed, PatternDef, pattern_match, app_pattern_match, (..), enum_next
export @match, Many, PushTo, Push, Seq, Do, @data, @use, use, @used
export defPattern, defAppPattern, defGAppPattern, mkPattern, mkAppPattern, mkGAppPattern
export PatternUnsolvedException, InternalException, SyntaxError
export Atom, Rule, Parserc

include("Extension.jl")
using MLStyle.Extension

include("Err.jl")
using MLStyle.Err

include("toolz.jl")

include("render.jl")

include("MatchCore.jl")
using MLStyle.MatchCore

include("Infras.jl")
using MLStyle.Infras

include("Pervasives.jl")
using MLStyle.Pervasives


include("StandardPatterns.jl")
using MLStyle.StandardPatterns

include("DataType.jl")
using MLStyle.DataType

export @λ
macro λ(cases)
    TARGET = mangle(__module__)
    @match cases begin
        :($a -> $(b...)) =>
                esc(quote
                    function ($TARGET, )
                        @match $TARGET begin
                            $a => begin $(b...) end
                            _ => @error "syntax error in lambda case definition."
                        end
                    end
                end)

        Do(stmts=[]) &&
        :(begin $(Many(:($a -> $(b...)) && Do(push!(stmts, :($a => begin $(b...) end))) ||
                       (a :: LineNumberNode) && Do(push!(stmts , a))
                       )...)
          end) =>
            esc(quote
                function ($TARGET, )
                    @match $TARGET begin
                        $(stmts...)
                    end
                end
            end)
        _ => @error "syntax error in lambda case definition."
    end
end

end # module
