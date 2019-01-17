@testset "pattern" begin
    @testset "ADT destructing" begin
        @data internal Case begin
            Natural(latitude :: Float32, longitude :: Float32, climate :: String, dimension :: Int32)
            Cutural(area :: String,  kind :: String, country :: String, nature :: Natural)
        end

        神农架 = Cutural("湖北", "林区", "中国", Natural(31.744, 110.68, "北亚热带季风气候", 3106))

        function my_data_query(data_lst :: Vector{Cutural})
            filter(data_lst) do data
                @match data begin
                    Cutural(kind="林区", country="中国", 
                            nature=Natural(latitude=latitude, longitude=longitude, dimension=dim)) && 
                    if latitude > 30.0 && longitude > 100 && dim > 1000
                    end => true
                    _ => false
                end
            end
        end

        @test length(my_data_query([神农架])) == 1
    end
end
