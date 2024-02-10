Records
----------------------

To add support pattern-matching deconstruction for a regular struct `A`, invoke `@as_record A`. Then `@match` can deconstruct `A(a,b,c)` using the same `A(a,b,c)` syntax as the constructor.

```julia-console
julia> struct A
           a
           b
           c
       end

julia> @as_record A

# or just wrap the struct definition with @as_record
# @as_record struct A
#     a
#     b
#     c
# end

julia> @match A(1, 2, 3) begin
           A(a, b, c) => a + (b)c
       end
7

julia> @match A(1, 2, 3) begin
           A(_) => true
       end # always true
true

julia> @match A(1, 2, 3) begin
           A() => true
       end # always true
true

# field punnings(superior than extracting fields)
julia> @match A(1, 2, 3) begin
           A(;a, b=b) => a + b
       end # 3
3

# extract fields
julia> @match A(1, 2, 3) begin
           A(a=a, b=b) => a + b
       end # 3
3
```
