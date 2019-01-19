using MLStyle


@data S{T} begin
    C{A}(T, A)
end

@match C(1, "2") begin
    C{A, B}() => (A, B)
end
