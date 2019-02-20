using MLStyle.Extension

@testset "exception" begin
    @test_skip @match 1 begin
        Unknown(a, b) => 0
    end

    @test_throws LoadError macroexpand(MODULE, :(@match 1 begin
        (a = b) => 0
    end))

    @test_throws LoadError macroexpand(MODULE, :(@λ begin
        1 => 1
    end))

    
    @test_throws UnknownExtension used(:FieldPuns, MODULE)
    
    @data Test_Ext_Data begin
        Test_Ext_Data_1 :: Int => Test_Ext_Data
    end

    @test_throws LoadError macroexpand(MODULE, :(@match $Test_Ext_Data_1(1) begin
        Test_Ext_Data_1(b, c=a) => 1
    end))

    @test_throws LoadError macroexpand(MODULE, :(
        @match 1 begin
            Int(x) => x
        end 
    ))
end

