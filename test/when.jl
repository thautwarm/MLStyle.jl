@testset "when" begin
    @test 2 === @when let 1 = 1
        2
    end
    @test 2 === @when 1 = 1 2

    @test 1 === @when let a = 1
        a
    end

    @test 1 === @when a = 1 a


    @test nothing === @when let (a, b) = 1
        a + b
    end

    @test nothing === @when (a, b) = 1 a + b


    ab = (2, 3)
    @test 5 === @when let (a, b) = ab
        a + b
    end

    @test 5 === @when (a, b) = ab a + b

    @data WhenTest begin
        WhenTest_1(Int)
        WhenTest_2(Int)
    end

    var1 = WhenTest_1(2)
    var2 = WhenTest_2(2)
    @test 200 === @when let WhenTest_1(x) = var1,
                            @inline WhenAction(x) = 100x
        WhenAction(x)
    end

    @test 200 === @when WhenTest_1(x) = var1 begin
        100x
    end

    @test nothing === @when let WhenTest_1(x) = var2,
                                @inline WhenAction(x) = 100x
        WhenAction(x)
    end


end