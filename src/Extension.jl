module Extension
using MLStyle.Err

Support = Dict{Symbol, Vector{Module}}(
    :GADT      => [],
    :Enum      => [],
    :UppercaseCapturing => [],
)

Check = Dict{Symbol, Function}(
    :UppercaseCapturing => function (mod :: Module)
        if used(:Enum, mod)
            throw("Cannot use extensions `UppercaseCapturing` and `Enum` simultaneously.")
        end
    end,
    :Enum => function (mod :: Module)
        if used(:UppercaseCapturing, mod)
            throw("Cannot use extensions `UppercaseCapturing` and `Enum` simultaneously.")
        end
    end
)
export use, @use, used

function used(ext :: Symbol, mod :: Module) :: Bool
    get(Support, ext) do
        throw(UnknownExtension(ext))
    end |> mods -> mod in mods
end

_donothing(_) = nothing

function use(ext :: Symbol, mod :: Module)
    mods = get(Support, ext) do
        Support[ext] = []
    end

    check_extension = get(Check, ext) do
        _donothing
    end
    check_extension(mod)

    push!(mods, mod)
end

macro use(exts...)
    mod = __module__
    for each in exts
        use(each, mod)
    end
end

end