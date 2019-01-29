module Core
using MLStyle.Bootstrap.Proto

Qualifier = Function

struct PDesc
    predicate  :: Function
    rewrite    :: Function
    qualifiers :: Set{Qualifier}
end

"""
For Julia hasn't supported Function signatures yet,
we then avoid the monadic way to take advantage of
continuations.
This is introduced mainly for composing code generations
of pattern compilation.

For instance, if we want to compose
2 patterns:

- first of which is to assure if the type is Tuple
- and the second check if the size of Tuple is 5
checktype(Tuple) ∘ checklen(5)

"""

struct Cont
    Predef
    Procedure
end

macro match(expr, body)
    @_match body begin
        :($a => $b) => compilePattern(mkPattern(a, expr, mkPredef(), __module__)(b))
        quote
            $(suite && Many(::LineNumberNode || :($_ => $_))...)
        end =>
        let l :: LineNumberNode = __source__,
            pairs :: Vector{Pair{Any, Any}} = []
            predef = mkPredef()

            @linq suite.foreach(@_λ begin
                a::LineNumberNode => (l = a)
                :($pattern => $expr) => push!(pairs, l => pattern => mkPredef(expr, predef))
            end)


        end

    end


end

end