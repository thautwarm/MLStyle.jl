module MLStyle

export @match, Many, Do, @data, @use, use, @used
export def_pattern_def_app_pattern_def_gapp_pattern_mk_pattern_mk_app_pattern_mk_gapp_pattern
export PatternUnsolvedException, InternalException, SyntaxError, UnknownExtension, @syntax_err
export @active

include("Err.jl")
using MLStyle.Err

include("Extension.jl")
using MLStyle.Extension

include("toolz.jl")

include("Render.jl")

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
        _ => @syntax_err "syntax error in lambda case definition."
    end
end

export @stagedexpr
macro stagedexpr(exp)
    __module__.eval(exp)
end

end # module
