@testcase "@switch" begin
    flag = Ref(0)
    function try_setflag(x)
        @switch x begin
            @case (::Integer, 2)
                flag[] = 1
            @case ::Bool
                nothing
                flag[] = 2
            @case ::String
                flag[] = 0
        end
    end

    try_setflag((1, 2))
    @test flag[] == 1
    try_setflag(false)
    @test flag[] == 2
    try_setflag("")
    @test flag[] == 0
    # Non-exhaustive matches throw an error.
    @test_throws ErrorException try_setflag(:a)

    flag2 = Ref(0)
    function try_setflag_2(x)
        @tryswitch x begin
            @case (::Integer, 2)
                flag[] = 1
            @case ::Bool
                flag[] = 2
                @tryswitch x begin
                    @case true
                        flag2[] = 2
                end
        end
    end

    try_setflag_2((1, 2))
    @test flag[] == 1
    try_setflag_2(false)
    @test flag[] == 2
    @test flag2[] == 0
    try_setflag_2(true)
    @test flag[] == 2
    @test flag2[] == 2

    # Non-exhaustive matches fail silently.
    try_setflag_2("")
end
