@nospecialize
# term_position is from ./SourcePos.jl and,
# PatternCompilationError is from ../PatternSignature
"""the view point of the type tag for each term
"""
function tag_extract(points_of_view::Dict{Function,Int})
    viewpoint = points_of_view[tag_extract]

    function and(many)
        @assert !isempty(many)
        ts = getindex.(many, viewpoint)
        t = reduce(typeintersect, ts)
        if t === Base.Bottom
            core_msg = "and patterns require an intersection of $(ts), which seems empty!"
            throw(PatternCompilationError(nothing, core_msg))
        end
        t
    end

    function or(many)
        ts = getindex.(many, viewpoint)
        Union{ts...}
    end

    function literal(val)
        typeof(val)
    end

    wildcard = Any

    function decons(comp::PComp, _, ns)
        targs = getindex.(ns, viewpoint)
        try
            comp.tcons(targs...)
        catch e
            join(map(repr, targs), ",")
            if e isa MethodError && e.f === comp.tcons
                argstr = join(repeat(String["_"], length(targs)), ", ")
                throw(PatternCompilationError(
                    nothing,
                    "invalid deconstructor $(comp.repr)($(argstr))",
                ))
            end
            rethrow()
        end
    end

    guard(_) = Any
    effect(_) = Any
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
