module Sugars
if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@compiler_options"))
    @eval Base.Experimental.@compiler_options compile=min infer=no optimize=0
end

using MLStyle
using MLStyle.AbstractPatterns

export Q, And, Or
@nospecialize

struct Q end
struct And end
struct Or end

function MLStyle.pattern_unref(::Type{Or}, self::Function, args::AbstractArray)
    isempty(args) && error("An Or pattern should take more than 1 clause!")
    or([self(arg) for arg in args])
end

function MLStyle.pattern_unref(::Type{And}, self::Function, args::AbstractArray)
    isempty(args) && error("An And pattern should take more than 1 clause!")
    and([self(arg) for arg in args])
end

function MLStyle.pattern_unref(::Type{Q}, self::Function, args::AbstractArray)
    length(args) === 1 || error("A Q pattern should take only 1 argument!")
    self(Expr(:quote, args[1]))
end
@specialize
end
