@testset "simple" begin
    @testset "simple.gallery.`Ast Pattern`" begin
        isnothing(x) = x !== nothing

        rmlines(a::Expr) =
            Expr(a.head, filter(isnothing, map(rmlines, a.args))...)

        rmlines(::LineNumberNode) = nothing

        rmlines(a::Any) = a

        ex = quote
            function f(x, y=5)
                x + 1
                x + 2
                x + "3"
                x + "4"
                y + x
            end
        end

        @test @match rmlines(ex) begin
            quote
                function f(x, y=$default)
                    x + $a
                    x + $b
                    x + $c
                    x + $d
                    y + x
                end
            end => (a, b, c, d, default) == (1, 2, "3", "4", 5)
        end


        ex = quote
            struct A{T} end
            struct B end
            struct C end
            struct D{G} end
        end


        @match rmlines(ex) begin
            Do(names=[]) &&
                quote
                    $(
                        Many(
                            (
                                :(struct $name end)
                                || :(struct $name{$(_...)} end)
                            ) &&
                            Do(push!(names, name))
                        )...
                    )
                end => names == [:A, :B, :C, :D]
        end
    end
    @testset "gallery.simple.`Array & Tuple`" begin

        @test @match [1, 2, 3] begin
            [1, a..., b] => (a, b) == ([2], 3)
        end
        # Attention:
        # `a` is not a copy of a part of original array.
        # In Python, `_, *a, b = [1, 2, 3]` means `a` is a copy,
        #   while in Julia, `a` here is a `view`[1].
        # [1] view: https://docs.julialang.org/en/latest/devdocs/subarrays/index.html

        @test @match (1, 2, 3) begin
            (1, 2, a) => a == 3
        end
        # Note that, you cannot pack a tuple,
        # and this is invalid
        # ```
        # @match (1, 2, 3) begin
        #   (1, a..., b) => ...
        # end
        # ```

        # nested match
        @test @match [1, [2, 3], (4, 5)] begin
            [1, [2, a], (b, 5), tail...] =>
                a == 3 && b == 4 && isempty(tail)
        end
    end
    @testset "gallery.simple.`Or Pattern`" begin
        # If I want number 1 or 2:
        function is_it(x)
            @match x begin
                1 || 2 => true
                _     => false
            end
        end
        @test is_it(1)
        @test is_it(2)
        @test !is_it(3)

        # Patterns can be nested
        function nested_or(x)
            @match x begin
                1 || [1 || 2] =>  true
                _             =>  false
            end
        end
        @test nested_or(1)
        @test nested_or([1])
        @test nested_or([2])
        @test !nested_or([1, 1])
    end

    @testset "gallery.simple.`And Pattern`" begin
        @test @match 1 begin
            a && 1 : 10 => a == 1
            _           => false
        end
    end
end
