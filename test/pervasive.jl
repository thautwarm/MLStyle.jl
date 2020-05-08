@testcase "Int" begin
    @testset "affirm: 1-10" begin
    @test all(1:10) do a
        @match a begin
            1 => a == 1
            2 => a == 2
            3 => a == 3
            4 => a == 4
            5 => a == 5
            6 => a == 6
            7 => a == 7
            8 => a == 8
            9 => a == 9
            10 => a == 10
        end
    end
    end
    @testset "negate: 1-10" begin
    @test !any(1:10) do a
        @match a begin
            1 => a != 1
            2 => a != 2
            3 => a != 3
            4 => a != 4
            5 => a != 5
            6 => a != 6
            6 => a != 6
            7 => a != 7
            8 => a != 8
            9 => a != 9
            10 => a != 10
        end
    end
    end
end

@testset "Generic Number" begin
    _1_10 = map(Float64, 1:10)
    @testset "affirm float32: 1-10" begin
    @test all(_1_10) do a
        @match a begin
            1.0 => a == 1.0
            2.0 => a == 2.0
            3.0 => a == 3.0
            4.0 => a == 4.0
            5.0 => a == 5.0
            6.0 => a == 6.0
            7.0 => a == 7.0
            8.0 => a == 8.0
            9.0 => a == 9.0
            10.0 => a == 10.0
        end
    end
    end
    @testset "negate float32: 1-10" begin
    foreach(_1_10) do a
        @test !(@match a begin
            1.0 => a != 1.0
            2.0 => a != 2.0
            3.0 => a != 3.0
            4.0 => a != 4.0
            5.0 => a != 5.0
            6.0 => a != 6.0
            6.0 => a != 6.0
            7.0 => a != 7.0
            8.0 => a != 8.0
            9.0 => a != 9.0
            10.0 => a != 10.0
        end)
    end
    end
end

@testset "String" begin
    @test @match "aaaa" begin
        "1234" => false
        "aaaa" => true
        1234   => false
    end
end

@testset "OrPattern" begin
    @test @match 1 begin
        2 => false
        3 => false
        (4 || 5 || 1) => true
    end
end

@testset "AndPattern" begin
    @test @match 2 begin
        "1" || 1 => false
        2   && 1 => false
        10  || 2 && ::Int => true
    end
end

@testset "Predicate" begin
    @test @match 10 begin
        x && if x^2 > 200 end => false
        x && if (x-3)^3 < 125 end => false
        x => x === 10
    end
end

@testset "Wildcard" begin
    @test @match 100 begin
        1 && 100 => false
        _        => true
    end
end


@testset "RefPattern" begin
    @test @match 100 begin
        (&100)   =>  true
        _        =>  false
    end
    a = "123"
    @test @match a begin
        (&a)     =>  true
        _        =>  false
    end
end


@testcase "Recognizer(AppPattern)" begin
    @lift @data internal TestRecog begin
        TestRecog_A(Int, Int)
        TestRecog_B(a :: Float64, b :: String)
    end

    a = TestRecog_A(1, 2)
    b = TestRecog_B(1.0, "2")

    @testset "Wildcard" begin
        @test @match a begin
            TestRecog_A(_) => true
            _ => false
        end
    end
    @testset "Ordered Anonymous Fields" begin
        @test @match a begin
            TestRecog_A(1, 2) => true
            _ => false
        end

        @test @match b begin
            TestRecog_B(1.0, "2") => true
            _ => false
        end
    end

    @testset "Named Fields" begin
        @test @match a begin
            TestRecog_A(_2 = 2) => true
            _ => false
        end

        @test @match b begin
            TestRecog_B(a = 1.0) => true
            _ => false
        end
    end
end

@testset "null-value dict pattern" begin
    x = Dict(:a => nothing)
    @test @match x begin
        Dict(:a => a) => a === nothing
        _ => false
    end

end



@testcase "Generalized Recognizer(GAppPattern)" begin
    @use GADT
    @lift struct TestGH end
    @lift @data internal TestGRecog{T} begin
        TestGRecog_A{T, A} :: (A, T) => TestGRecog{T}
        TestGRecog_B{T, B} :: (a :: T, b :: B) => TestGRecog{T}
    end

    a = TestGRecog_A(1, TestGH())
    b = TestGRecog_B([1], "2")

    @testset "Matching for specialization" begin
        @test @match a begin
            TestGRecog_A(_) => true
            _ => false
        end

        @test @match a begin
            TestGRecog_A{TestGH, Int}(_) => true
            _ => false
        end

        @test @match b begin
            TestGRecog_B{Vector{Int}, String}(_) => true
            _ => false
        end

        @test @match b begin
            ::TestGRecog{Vector{Int}} => true
            _ => false
        end

        @test @match a begin
            ::TestGRecog{TestGH} => true
            _ => false
        end

        @test @match a begin
            TestGRecog_A{TestGH}(_) => true
            _ => false
        end

    end

    @testset "Matching for generalization" begin

        @test @match a begin
            TestGRecog_A{T, A}(::A, ::T) where {A, T} => true
            _ => false
        end

        @test @match a begin
            TestGRecog_A{TestGH, A}(_) where A <: Number => true
            _ => false
        end

        @test @match a begin
            TestGRecog_A{TestGH}(_) => true
            _ => false
        end

        @test @match b begin
            TestGRecog_B{A, B}(::B, ::A) where {A, B} => false
            TestGRecog_B{A, B}(::A, ::B) where {A, B} => true
            _ => false
        end

    end

end

@testcase "TestUppercaseCapturing" begin
    @testset "UppercaseCapturing" begin
        @use UppercaseCapturing

        @test 2 === @match 1 begin
            A => A + 1
        end
    end
end

@testcase "variable mutation in Many(..)" begin
    @test @match [1, 2, 3] begin
        Many(::Int) => true
        _ => false
    end

    @test 9 == @match [1, 2, 3,  "a", "b", "c", :a, :b, :c] begin
        Do(count = 0) &&
        Many[
            a::Int && Do(count = count + a) ||
            ::String                        ||
            ::Symbol && Do(count = count + 1)
        ] => count
    end
    @test @test_logs (:warn, r"[d|D]eprecated") begin
        @match 1 begin
            let x = 1 end && Do[x = 2] => (x==2)
            _ => false
        end
    end
end