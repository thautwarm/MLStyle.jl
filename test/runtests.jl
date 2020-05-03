module TestModule

using Test
using MLStyle

liftsym = Symbol("@lift")

function lift!(ex, lifted::Vector{Any})
    @switch ex begin
        @case Expr(:macrocall, &liftsym, _, arg)
        push!(lifted, arg)
        ex.args
        ex.args[1] = Symbol("@static")
        ex.args[3] = :(true ? true : true)
        return
        @case Expr(hd, args...)
        for arg in args
            lift!(arg, lifted)
        end
        return
        @case _
        return
    end
end

macro testcase(name, ex)
    lifted = []
    lift!(ex, lifted)
    m = gensym(name)
    println(Expr(:block, lifted...))
    __module__.eval(:(module $m
    using MLStyle
    using Test
    $(lifted...)
    @testset $name $ex
    end))
end

macro test_macro_throws(errortype, m)
    :(@test_throws $errortype try
        @eval $m
    catch err
        while err isa LoadError
            err = err.error
        end
        throw(err)
    end)
end

MODULE = TestModule

@use GADT
include("active_patterns.jl")
include("uncomp.jl")
include("lambda.jl")
include("as_record.jl")
include("adt.jl")

include("exception.jl")
include("expr_template.jl")
include("gallery/simple.jl")
include("dot_expression.jl")

include("modules/cond.jl")
include("modules/ast.jl")

include("render.jl")
include("pervasive.jl")
include("match.jl")
include("pattern.jl")
include("typelevel.jl")
include("untyped_lam.jl")
include("nothing.jl")

include("when.jl")
include("MQuery/test.jl")
end
