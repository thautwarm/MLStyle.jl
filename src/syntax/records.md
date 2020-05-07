Records
----------------------

```julia
struct A
    a
    b
    c
end
@as_record A

# or just wrap the struct definition with @as_record
# @as_record struct A
#     a
#     b
#     c
# end

@match A(1, 2, 3) begin
    A(1, 2, 3) => ...
end

@match A(1, 2, 3) begin
    A(_) => true
end # always true

@match A(1, 2, 3) begin
    A() => true
end # always true

# field punnings(superior than extracting fields)
@match A(1, 2, 3) begin
    A(;a, b=b) => a + b
end # 3

# extract fields
@match A(1, 2, 3) begin
    A(a=a, b=b) => a + b
end # 3
```
