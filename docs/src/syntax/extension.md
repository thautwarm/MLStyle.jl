
MLStyle Extension List
=============================



GADT
--------------------

- Description: Introduce generic(and implicit) type variables in pattern matching when destructuring data types.
- Conflicts: nothing

- Example:

```julia
@use GADT

@data S{G} begin
    S1{T} :: T => S{G} where G
end

let x :: S{String} = S1(2)
    @match x begin
        S1{T}(a) where T <: Number => show(a + 1)
        _ => show("failed")
    end
end
```
outputs
```
3
```

UppercaseCapturing
-----------------------------


- Description: By default, uppercase symbols cannot be used as patterns for its ambiguous semantics. If you prefer capturing via uppercase symbols, use `UppercaseCapturing`.

- Conflicts: `Enum`

- Example:

```julia
@use UppercaseCapturing

@match 1 begin
    A => A + 1
end
```
outputs:
```
2
```

Enum
-----------------------------


- Description: By default, uppercase symbols cannot be used as patterns for its ambiguous semantics. If you prefer replacing patterns like `S()` with `S`, use `Enum`.


- Conflicts: `UppercaseCapturing`
- Example:

```julia
@use Enum
@data A begin
    A1()
    A2()
end

@match A1() begin
    A1 => 1
    _ => 2
end
# output: 1

@active IsEven(x) begin
    x % 2 === 0
end
@match 4 begin
    IsEven => :ok
    _ => :err
end
# output: :ok
```