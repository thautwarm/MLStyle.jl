module Extension
using MLStyle.Err
export use, @use, used


function used(ext :: Symbol, mod :: Module) :: Bool
    Base.depwarn(
       "No need to use this function anymore since MLStyle v0.4",
        :used
    )
    false
end

function use(ext :: Symbol, mod :: Module)
    Base.depwarn(
       "No need to use this function anymore since MLStyle v0.4",
        :use
    )
end

macro use(exts...)
    use(:_, @__MODULE__)    
end

end