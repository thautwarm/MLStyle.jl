module Err
export PatternCompilationError,
    InternalException, SyntaxError, UnknownExtension, PatternUnsolvedException

PatternUnsolvedException = ErrorException

struct PatternCompilationError <: Exception
    line::Union{LineNumberNode, Nothing}
    ex::Exception
end

struct InternalException <: Exception
    msg::String
end

struct SyntaxError <: Exception
    msg::String
end

struct UnknownExtension <: Exception
    ext::Union{String, Symbol}
end

end
