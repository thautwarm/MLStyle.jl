struct Record_1
    a
    b
end

@as_record Record_1

@test @match Record_1(1, 2) begin
    Record_1(1, 2) => true
    _ => false
end


@test @match Record_1(1, 2) begin
    Record_1(a=1) => true
    _ => false
end

@test @match Record_1(1, 2) begin
    Record_1(b = 2) => true
    _ => false
end

struct Record_2{A}
    x :: A
    y :: Int
end

@as_record visible in (@__MODULE__) Record_2

@test @match Record_2(1, 2) begin
    Record_2{A}(_) where A => A == typeof(1)
    _ => false
end



