***This documentation needs to get up-to-date.***

There's an order among all those patterns' implementations, for some pattern might rely on an other.

## Active.jl

- Description: provided with the capability of defining custom patterns easily with backward compatibilities.
- Dep(s): `TypeVarDecons.jl`
- Instance:

    ```julia
    @active F(x) begin
        if x > 0
            nothing
        else
            Some(:ok)
        end
    end

    @match -1 begin
        F(:ok) => false
        _ => true
    end # true

    @active IsEven(x) begin
        x % 2 === 0
    end

    @match 4 begin
        IsEven() => :ok
        _ => :err
    end # :ok
    ```

## Uncomprehensions.jl
- Description: provided with the capability of deconstructing `Vector`(and more iterable types in the future) instances just as how they're constructed.
- Deps(s): `TypeVarDecons.jl`
- Instance:

    ```julia
    arr = [2, 3, 5]

    @match [(i, 2i) for i in arr] begin
        [(i, _) for i in seq] => seq == arr # true
    end

    @match [(i, 2i) for i in arr] begin
        [(i, _) for i in seq if i > 2] => seq == [3, 5] # true
    end
    ```

## LambdaCases.jl
- Description: provided with two means to define lambdas with pattern matching support.
- No dependencies
- Instance:

    ```julia
    xs = [(1, 2), (1, 3), (1, 4)]
    map((@λ (1, x) => x), xs)
    # => [2, 3, 4]

    (2, 3) |> @λ begin
        1 => 2
        2 => 7
        (a, b) => a + b
    end
    # => 5
    ```

## WhenCases.jl

- Description: provided with the capability of peeforming pattern matching on more than one value(Like `if-else` with pattern matching)
- No dependencies
- Instance:

    ```julia
    x = 1
    y = (1, 2)
    cond1 = true
    cond2 = true
    @when let cond1.?,
              (a, b) = x
        a + b
    @when begin cond2.?
                (a, b) = y
           end
        a + b
    @otherwise
        10
    end # 3
    ```
