include("MatchCore.jl")

v = nothing
macro app!(a, b)
    b = MatchCore.collectCases(b)
    global v = b
    println(b)

end


 @app! a begin
    1 => 2
    2 => 3
end


@info (MatchCore.runState(v)(MatchCore.init_state))
