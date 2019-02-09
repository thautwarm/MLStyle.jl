
function get_fields
end

function get_records
end

function build_result
end


# interface for `DataFrame`s
get_fields(df :: DataFrame) = names(df)
get_records(df :: DataFrame) = zip(DataFrames.columns(df)...)
function build_result(::Type{DataFrame}, fields, typs, source :: Base.Generator)
    res = Tuple(typ[] for typ in typs)
    for each in source
        push!.(res, each)
    end
    DataFrame(collect(res), fields)
end
