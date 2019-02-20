let b1 = (1, 2)
    begin
        function f1(a1 :: Tuple{A, B}) where {A, B}
            b2 = a1[1]
            function f2(a2 :: A)
                A
                b3 = a1[2]
                function f3(a3 :: B)
                   # B # if don't explicitly give a `B` here, err can be raised
                   a2 + a3
                end
                f3(b3)
            end
            f2(b2)
        end
        f1(b1)
    end
end
