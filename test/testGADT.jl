using MLStyle
@use GADT

@data S{T} begin
    C{A}(T, A)
end

@match C(1, "2") begin
    ::S{Int} => true
end


@match C(1, "2") begin
    C{A, B}(_) where {A, B} => (A, B)
end
