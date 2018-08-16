using MLStyle
using MLStyle.Data

@testset "adt-type" begin

lst = List.Cons(1, List.Nil{Int}())


let test =
    @match lst begin
    	   List.Cons(1, ::List.Cons)        => nothing
           List.Cons(head, ::List.Nil{Int}) => head
	end
    @test test === 1
end

let test = 
    @match 1 ^ 2 ^ List.List!{Int32}() begin 
        1 ^ 2 ^ [] => true
    end 
    @test test === true
end    

let _ = 
    @match [1, 2, 3, 4] begin 
        [1, pack..., last] => 
            @test pack == [2, 3]  && last == 4
        _ =>
            @test false
    end

end

end
