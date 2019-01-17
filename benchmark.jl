using BenchmarkTools
using MacroTools
using MLStyle
using MLStyle.Pervasive: Push, PushTo, Many


ex = quote
    struct Foo
        x :: Int
        y
    end
end

function b_macrotools(ex)
    @capture(ex, struct T_ fields__ end)
    (T, fields)
end

function b_mlstyle(ex)
    MLStyle.@match ex begin
        Do(fields = []) &&
        quote
          $(::LineNumberNode)
          struct $typename
            $(
              Many(
                  ::LineNumberNode             ||
                  :($name :: $typ) &&
                     Push(fields, (name, typ)) ||
                  (a :: Symbol)    &&
                     Push(fields, (a, Any))
              )...
            )
          end
        end => (typename, fields)
    end
end
@info b_macrotools(ex)
@info b_mlstyle(ex)

@btime b_macrotools(ex)
@btime b_mlstyle(ex)

# Output
# [ Info: (:Foo, Any[:(x::Int), :y])
# [ Info: (:Foo, Any[(:x, :Int), (:y, Any)])

# no function impl:
#   18.824 μs (114 allocations: 6.41 KiB)
#   5.221 μs (32 allocations: 1.39 KiB)

#   19.825 μs (114 allocations: 6.41 KiB)
#   5.099 μs (30 allocations: 1.31 KiB)

# inline function impl



