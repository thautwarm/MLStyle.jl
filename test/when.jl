@testcase "@when" begin
    @lift @data WhenTest begin
        WhenTest_1(Int)
        WhenTest_2(Int)
    end

    @testset "docstring" begin
        # otherwise()
        @test 3 == @when (a, b) = (1, 2) begin
            a + b
        @otherwise
            0
        end
        @test 0 == @when (a, b) = () begin
            a + b
        @otherwise
            0
        end

        # macro when
        @test (1,2,3) == @when let (a, 1) = (1, 1),
                                   [b, c, 5] = [2, 3, 5]
            (a, b, c)
        end

        x = 1
        @test :int == @when let (_, _) = x
            :tuple
        @when begin ::Float64 = x end
            :float
        @when ::Int = x
            :int
        @otherwise
            :unknown
        end

        x = 1
        y = (1, 2)
        cond1 = true
        cond2 = true
        @test 3 == @when let cond1.?,
                  (a, b) = x
            a + b
        @when begin if cond2 end
                    (a, b) = y
              end
            a + b
        end
    end

    @testset "Only @when" begin
        @test 2 == @when let (a, 1) = (2, 1)
            a
        end
        @test 2 == @when (a, 1) = (2, 1) a

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
    end

    @testset "@when + @data" begin

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

    @testset "when with predicates" begin
        @test 2 === @when let if 1 > 0 end
            2
        end
        @test 3 === @when let (a, b) = (1, 2),
                              (1 > 0).?
                a + b
        end
    end

    @testset "@when in @when" begin
        function f1(args...)
            x = Tuple(args)
            @when (a, 1) = x begin
                a
            @when (b, 2) = x
                (2, b)
            end
        end
        # case: a
        @test f1(111, 1) == 111
        @test f1(222, 1) == 222
        # case: (2, b)
        @test f1(111, 2) == (2, 111)
        @test f1(222, 2) == (2, 222)
        # default case
        @test f1() == nothing

        function f2(args...)
            x = Tuple(args)
            @when (a, 1) = x begin
                a
            @when (b, 2) = x
                (:b, b)
            @when (c, 3) = x
                (:c, c)
            end
        end
        @test f2(10, 1) == 10       # case: a
        @test f2(20, 2) == (:b, 20) # case: (:b, b)
        @test f2(30, 3) == (:c, 30) # case: (:c, c)
        @test f2() == nothing       # default case
    end

    @testset "@when + @otherwise" begin
        function f1(args...)
            x = Tuple(args)
            @when (a, 1) = x begin
                a
            @otherwise
                x
            end
        end
        @test f1(1) == (1, )        # case: x
        @test f1(1, 2) == (1, 2)    # case: x
        @test f1(2, 1) == 2         # case: a

        function f2(args...)
            x = Tuple(args)
            @when (a, 1) = x begin
                a
            @when (b, 2) = x
                (:b, b)
            @when (c, 3) = x
                (:c, c)
            @otherwise
                x
            end
        end
        @test f2(1) == (1, )        # case: x
        @test f2(1, 0) == (1, 0)    # case: x
        @test f2(10, 1) == 10       # case: a
        @test f2(20, 2) == (:b, 20) # case: (:b, b)
        @test f2(30, 3) == (:c, 30) # case: (:c, c)

        xy = (1, 3)
        @test 0 == @when let (a, 1) = xy
            a
        @otherwise
            0
        end

        @test 1 == @when let (a, 3) = xy
            a
        @otherwise
            0
        end

        # multi let bindings
        z = 5
        @test 1 == @when let (a, 3) = xy,
                             5 = z
            a
        @otherwise
            0
        end

        @test 0 == @when let (a, 1) = xy,
                             5 = z
            a
        @otherwise
            0
        end

        @test 0 == @when let (a, 3) = xy,
                             6 = z
            a
        @otherwise
            0
        end
    end

    @testset "@when + @otherwise with many bidings" begin
        function f1(xy, z)
            @when let (a, 1) = xy,
                      5      = z
                a
            @otherwise
                0   # default value
            end
        end
        @test f1((123, 1), 5) == 123    # case: a
        @test f1((123, 3), 5) == 0      # not match `(a, 1) = xy`
        @test f1((123, 1), 1) == 0      # not match `5 = z`

        function f2(ab, c, d, e)
            @when let (a, 1) = ab,
                      5      = c
                a, c
            @when begin :cpp = d; 2.0 = e end
                d, e
            @otherwise
                0
            end
        end
        @test f2((9, 1), 5, :c, 1.0) == (9, 5)          # case: a, c
        @test f2((9, 1), 5, :cpp, 2.0) == (9, 5)        # case: a, c
        @test f2((9, 2), 5, :cpp, 2.0) == (:cpp, 2.0)   # case: d, e

        @test f2((9, 0), 5, :c00, 2.0) == 0  # default case
        @test f2((9, 1), 0, :c00, 2.0) == 0  # default case
        @test f2((9, 0), 5, :cpp, 0.0) == 0  # default case
        @test f2((9, 1), 0, :cpp, 0.0) == 0  # default case
    end
    @testset "multiple statements for each case" begin
        s = (1, 2, 3)
        @test 2 == @when (a, 2, 3) = s begin
            k = 1
            if a > 2
                k *= a
            else
                k += a
            end
            k
        @otherwise
            throw("")
        end

        s = (20, 3)
        @test 100 == @when (10, 3) = s begin
            a = 10
            a = 10
            a = a * a
            a
        @otherwise
            a = 10
            a = 10
            a = a * a
            a
        end
    end
    @testset "error handles" begin
        # no method matching
        @test_macro_throws MethodError @when

        # macro when(assignment, ret)
        #   case: _
        @test_macro_throws SyntaxError @when x 1
        @test_macro_throws SyntaxError("Not match the form of `@when a = b expr`") @when 1 1

        # `gen_when`
        #   case: a
        @test_macro_throws SyntaxError @when 1
        @test_macro_throws SyntaxError @when x
        @test_macro_throws SyntaxError @when @when
        @test_macro_throws SyntaxError @when begin end

        # `@otherwise`
        @test_macro_throws SyntaxError("@otherwise is only used inside @when block, as a token to indicate default case.") @otherwise
    end

end