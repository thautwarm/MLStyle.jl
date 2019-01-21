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

@assert (@linq [1, 2, 3].select(x -> x * 5)) == [5, 10,  15]
