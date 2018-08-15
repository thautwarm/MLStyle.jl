module Err
export PatternUnsolvedException, InternalException, SyntaxError
struct PatternUnsolvedException <: Exception
    pattern :: Expr
end

struct InternalException <: Exception
    msg :: String
end

struct SyntaxError <: Exception
    msg :: String
end

struct DataTypeUsageError <: Exception
    msg :: String
end

end
