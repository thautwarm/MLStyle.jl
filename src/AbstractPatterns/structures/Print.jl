@nospecialize
"""The view point of showing patterns
"""
function pretty(points_of_view::Dict{Function, Int})
    viewpoint = points_of_view[pretty]

    function and(ps)
        xs = Any[Print.w("(")]
        for p in ps
            push!(xs, p[viewpoint])
            push!(xs, Print.w(" && "))
        end
        pop!(xs)
        if !isempty(ps)
            push!(xs, Print.w(")"))
        end
        Print.seq(xs...)
    end

    function or(ps)
        xs = Any[Print.w("(")]
        for p in ps
            push!(xs, p[viewpoint])
            push!(xs, Print.w(" || "))
        end
        pop!(xs)
        if !isempty(ps)
            push!(xs, Print.w(")"))
        end
        Print.seq(xs...)
    end
    literal(val) = Print.w(string(val))
    wildcard = Print.w("_")

    function decons(comp::PComp, _, ps)
        Print.seq(Print.w(comp.repr), Print.w("("), getindex.(ps, viewpoint)..., Print.w(")"))
    end

    function guard(pred)
        Print.seq(Print.w("when("), Print.w(repr(pred)), Print.w(")"))
    end

    function effect(eff)
        Print.seq(Print.w("do("), Print.w(repr(eff)), Print.w(")"))
    end

    (
        and = and,
        or = or,
        literal = literal,
        wildcard = wildcard,
        decons = decons,
        guard = guard,
        effect = effect
    )
end
@specialize
