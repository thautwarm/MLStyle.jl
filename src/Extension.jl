module Extension
using MLStyle.Err

Support = Dict{Symbol, Vector{Module}}(
    :GADT      => []
)

export use, @use, used

function used(ext :: Symbol, mod :: Module) :: Bool
    get(Support, ext) do
        throw(UnknownExtension(ext))
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