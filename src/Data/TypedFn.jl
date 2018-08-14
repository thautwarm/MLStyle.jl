module TypedFn
export Fun
using MLStyle

@case Fun{A, B}(fn :: Function)

function (typed_fn :: Fun{A, B})(arg :: A) :: B where {A, B}
    typed_fn.fn(arg)
end
end
