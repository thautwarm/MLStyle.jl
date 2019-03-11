# using DataFrames

function get_fields
end

function get_records
end

function build_result
end


# interface for `Dict`s
get_fields(df :: Dict{Symbol, Vector{T} where T}) = collect(keys(df))
get_records(df :: Dict{Symbol, Vector{T} where T}) = zip((df[key] for key in keys(df))...)
function build_result(::Type{Dict{Symbol, Vector{T} where T}}, fields, typs, source :: Base.Generator)
    res = Tuple(typ[] for typ in typs)
    for each in source
        push!.(res, each)
    end
    Dict(zip(fields, res))
end


# interface for DataFrames

# get_fields(df :: DataFrame) = collect(names(df))
# get_records(df :: DataFrame) = DataFrames.columns(df)
# function build_result(::Type{DataFrame}, fields, typs, source :: Base.Generator)
#     res = Tuple(typ[] for typ in typs)
#     for each in source
#         push!.(res, each)
#     end
#     DataFrame(collect(res), fields)
# end
