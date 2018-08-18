@testset "pattern" begin
    @testset "ADT destructing" begin
        @case Natural(latitude :: Float32, longitude :: Float32, climate :: String, dimension :: Int32)
        @case Cutural(area :: String,  kind :: String, country :: String, nature :: Natural)


        神农架 = Cutural("湖北", "林区", "中国", Natural(31.744, 110.68, "北亚热带季风气候", 3106))

        function my_data_query(data_lst :: Vector{Cutural})
            filter(data_lst) do data
                @match data begin
                    Cutural(_, "林区", "中国", Natural(latitude, longitude, _, dim)){
                            latitude > 30.0, longitude > 100, dim > 1000
                    } => true
                    _ => false
                end
            end
        end

        @test length(my_data_query([神农架])) == 1
    end
end
