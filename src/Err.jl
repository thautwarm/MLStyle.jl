module Err
export PatternUnsolvedException, InternalException, SyntaxError

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


end
