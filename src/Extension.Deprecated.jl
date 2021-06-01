module Extension
using MLStyle.Err
export use, @use, used

@nospecialize
macro _depwarn(sym)
    :($Base.depwarn("No need to use this function anymore since MLStyle v0.4", $sym))
end

function used(ext::Symbol, mod::Module)::Bool
    @_depwarn :used
    false
end

function use(ext::Symbol, mod::Module)
    @_depwarn :use
    nothing
end

macro use(exts...)
    ln = __source__
    @warn "No need to use this function anymore since MLStyle v0.4 at $(ln.file):$(ln.line)"
    use(:_, @__MODULE__)
end
@specialize

end
