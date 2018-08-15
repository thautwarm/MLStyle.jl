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

function convert(::Type{Fun{A, B}}, fn :: Fun{C, D}) where{C, D, A >: C, B >: D}
    Fun{A, B}(fn.fn)
end
end
