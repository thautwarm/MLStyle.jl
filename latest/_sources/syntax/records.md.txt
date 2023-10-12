Records
----------------------

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
