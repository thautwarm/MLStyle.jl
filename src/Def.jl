module Def
    using MLStyle

    macro def (fn_name, cases)
        quote
            function $fn_name(args...)
                @match $args begin
                    $cases
                end
            end
        end
    end

end

"""
@def f begin
    (x, y) => x
    (z, y) => z
    (a, b) => z
end
"""