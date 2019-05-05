@testset "@when" begin
    # @testset "Only @when" begin
    #     @test_broken 2 == @when let (a, 1) = (2, 1)
    #         a
    #     end
    # 
    #     @test_broken 2 === @when let 1 = 1
    #         2
    #     end
    #     @test_broken 2 === @when 1 = 1 2
    # 
    #     @test_broken 1 === @when let a = 1
    #         a
    #     end
    #     @test_broken 1 === @when a = 1 a
    # 
    # 
    #     @test_broken nothing === @when let (a, b) = 1
    #         a + b
    #     end
    #     @test_broken nothing === @when (a, b) = 1 a + b
    # 
    # 
    #     ab = (2, 3)
    #     @test_broken 5 === @when let (a, b) = ab
    #         a + b
    #     end
    #     @test_broken 5 === @when (a, b) = ab a + b
    # end
    
    # @testset "@when + @data" begin
    #     @data WhenTest begin
    #         WhenTest_1(Int)
    #         WhenTest_2(Int)
    #     end
    # 
    #     var1 = WhenTest_1(2)
    #     var2 = WhenTest_2(2)
    #     @test_broken 200 === @when let WhenTest_1(x) = var1,
    #                             @inline WhenAction(x) = 100x
    #         WhenAction(x)
    #     end
    # 
    #     @test_broken 200 === @when WhenTest_1(x) = var1 begin
    #         100x
    #     end
    # 
    #     @test_broken nothing === @when let WhenTest_1(x) = var2,
    #                                 @inline WhenAction(x) = 100x
    #         WhenAction(x)
    #     end
    # end
    
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
        @test f1(1) == (1, )    # case: x
        @test f1(1, 2) == (1, 2)# case: x
        @test f1(2, 1) == 2     # case: a
        
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
        res = @when let (a, 1) = xy
            a
        @otherwise
            0
        end
        @test res == 0
        
        res = @when let (a, 3) = xy
            a
        @otherwise
            0
        end
        @test res == 1
        
        # @when let bindings... 
        z = 5
        res = @when let (a, 3) = xy,
                        5 = z
            a
        @otherwise
            0
        end
        @test res == 1
        
        res = @when let (a, 1) = xy,
                        5 = z
            a
        @otherwise
            0
        end
        @test res == 0
        
        res = @when let (a, 3) = xy,
                        6 = z
            a
        @otherwise
            0
        end
        @test res == 0
        
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
        
    end
    
    @testset "error handles" begin
        # no method matching
        @test_macro_throws MethodError @when
        
        # macro when(assignment, ret)
        #   case: _
        @test_macro_throws SyntaxError @when x 1
        @test_macro_throws SyntaxError("Not match the form of `@when a = b expr`") @when 1 1
       
        # gen_when
        #   case: Expr(a, _...)
        # @test_broken SyntaxError("Expect a let-binding, but found a `block` expression.") @when begin end
        # @test_broken SyntaxError("Expect a let-binding, but found a `macrocall` expression.") @when @when
        # 
        # #   case: _
        # @test_broken SyntaxError("Expect a let-binding.") @when 1
        # @test_broken SyntaxError("Expect a let-binding.") @when x
    end

end
