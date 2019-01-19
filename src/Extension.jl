module Extension

Support = Dict{Symbol, Vector{Module}}(
    :TypeLevel => [],
    :GADT      => []
)

export use, @use, used

function used(ext :: Symbol, mod :: Module) :: Bool
    get(Support, ext) do
        @error "no extension `$ext`."
    end |> mods -> mod in mods
end

function use(ext :: Symbol, mod :: Module)
    mods = get(Support, ext) do
        Support[ext] = []
    end
    push!(mods, mod)
end


macro use(exts...)
    mod = __module__
    for each in exts
        use(each, mod)
    end
end




end