# this source will be included by MLStyle.jl
import Base: convert
@case Fun{T, R}(fn :: Function)

function (typed_fn :: Fun{T, R})(arg :: T) :: R where {T, R}
    typed_fn.fn(arg)
end

function convert(::Type{Fun{T, R}}, fn :: Function) where {T, R}
    Func{T, R}(fn)
end

function convert(::Type{Fun{T, R}}, fn :: Fun{C, D}) where{T, R, C <: T, D <: R}
    Fun{T, R}(fn.fn)
end

(⇒)(::Type{T}, ::Type{R}) where {T, R} = Fun{T, R}
