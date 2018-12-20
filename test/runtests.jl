using Test
using MLStyle

include("pervasive.jl")

# using Test
# using MLStyle


# module hygiene
#     using Test
#     using MLStyle
#     import MLStyle.MatchExt: enum_next
#     import Base: (<=), (<)

#     range_match(x) = @match x begin
#         1..10  in x => "$x in [1, 10]"
#         11..20 in x => "$x in [11, 20]"
#         21..30 in x => "$x in [21, 30]"
#     end
    
#     @test range_match(3) == "3 in [1, 10]"
#     @test range_match(13) == "13 in [11, 20]"
#     @test range_match(23) == "23 in [21, 30]"

#     @data MyEnum begin
#         A
#         B
#         C
#     end

#     function (<)(enum1 :: MyEnum, enum2 :: MyEnum)
#         @match enum1 begin
#             A() => begin enum2 !== A() end
#             B() => begin enum2 === C() end
#             C() => false
#         end
#     end

#     function (<=)(enum1 :: MyEnum, enum2 :: MyEnum)
#         enum1 === enum2 || enum1 < enum2
#     end

#     function enum_next(enum :: MyEnum)

#         @match enum begin
#             A() => B()
#             B() => C()
#             C() => nothing
#         end
#     end
#     a = A()
#     b = B()
#     c = C()

#     res = @match a begin
#         a..b => true
#         _    => false
#     end
#     @test (res === true)

#     res = @match c begin
#         a..b => true
#         _    => false
#     end
#     @test (res === false)

# end 





# include("match.jl")
# include("pattern.jl")
# include("adt.jl")
# include("fn.jl")
# include("typelevel.jl")

# # WARNING: typelevel.jl must be at the end of the test for once `type level` feature
# #          is activated in a module, it won't be able to disable in this module.

# # TODO:
# # include("data.jl")
