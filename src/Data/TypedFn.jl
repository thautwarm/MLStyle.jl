module TypedFn
export Fun
using MLStyle
import Base: convert
@case Fun{A, B}(fn :: Function)

function (typed_fn :: Fun{A, B})(arg :: A) :: B where {A, B}
    typed_fn.fn(arg)
end

function convert(::Type{Fun{A, B}}, fn :: Function) where {A, B}
    Func{A, B}(fn)
end

function convert(::Type{Fun{A, B}}, fn :: Fun{C, D}) where{A, B, C <: A, D <: B}
    Fun{A, B}(fn.fn)
end
end
