using MLStyle

@testset "adt-type" begin

@data List{T} begin
    Nil{T}
    Cons{T}(head :: T, tail :: List{T})
end


lst = Cons(1, Nil{Int}())

let test =
    @match lst begin
    	   Cons(1, ::Cons) => nothing
           Cons(head, ::Nil{Int}) => head
	end
    @test test === 1
end

end
