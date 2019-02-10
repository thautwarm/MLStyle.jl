module Err
export PatternUnsolvedException, InternalException, SyntaxError, UnknownExtension, @syntax_err

struct PatternUnsolvedException <: Exception
    msg :: String
    PatternUnsolvedException(arg) =
        if isa(arg, String)
            new(arg)
        else
            new("Non-exhaustive pattern found for target `$(string(arg))`.")
        end
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

macro syntax_err(msg)
    esc(:($throw($SyntaxError($msg))))
end

end
