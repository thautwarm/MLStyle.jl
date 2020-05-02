module Err
export PatternCompilationError, InternalException, SyntaxError, UnknownExtension, @syntax_err

struct PatternCompilationError <: Exception
    line::Union{LineNumberNode,Nothing}
    msg::AbstractString
end

struct InternalException <: Exception
    msg :: String
end

struct SyntaxError <: Exception
    msg :: String
end

struct UnknownExtension <: Exception
    ext :: Union{String, Symbol}
end

end
