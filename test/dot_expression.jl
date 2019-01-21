using MLStyle

module Linq
    select(arr, f) = map(f, arr)
end

macro linq(expr)
    @match expr begin
        :($subject.$method($(args...))) =>
            let method = getfield(Linq, method)
                quote $method($subject, $(args...)) end
            end
        _ => @error "invalid"
    end
end

@test (@linq [1, 2, 3].select(x -> x * 5)) == [5, 10,  15]

@data internal AAA begin
    AAA_1(Int, Int)
    AAA_2(Float32)
end

@test (@linq [AAA_1(2, 2), AAA_2(3.9)].select(@λ begin
    AAA_1(a, b) -> a + b
    AAA_2(a)    -> 3
end)) == [4, 3]
