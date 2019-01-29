module Prototype

export @match, Many, PushTo, Push, Seq, Do, @data, @use, use, used
export defPattern, defAppPattern, defGAppPattern, mkPattern, mkAppPattern, mkGAppPattern
export PatternUnsolvedException, InternalException, SyntaxError, UnknownExtension, @syntax_err
export @active
export Extension

using ..Err

include("Extension.jl")
using MLStyle.Prototype.Extension


include("toolz.jl")

include("render.jl")

include("MatchCore.jl")
using MLStyle.Prototype.MatchCore

include("Infras.jl")
using MLStyle.Prototype.Infras

include("Pervasives.jl")
using MLStyle.Prototype.Pervasives


include("StandardPatterns.jl")
using MLStyle.Prototype.StandardPatterns

include("DataType.jl")
using MLStyle.Prototype.DataType

export @λ
macro λ(cases)
    TARGET = mangle(__module__)
    @match cases begin
        :($a -> $(b...)) =>
                esc(quote
                    function ($TARGET, )
                        @match $TARGET begin
                            $a => begin $(b...) end
                            _ =>
                            begin
                                @syntax_err "syntax error in lambda case definition."
                            end
                        end
                    end
                end)

        Do(stmts = []) &&
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
