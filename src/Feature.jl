module Feature
    export @activate, is_activated
    separate_module_features = Dict()
    function is_activated(symbol, mod)
        get(separate_module_features, symbol) do
            nothing
        end |>
        function (modules)
            if modules === nothing
                false
            else
                mod in modules
            end
        end
    end
    macro activate(symbols...)
        if :TypeLevel in symbols
            modules = get(separate_module_features, :TypeLevel) do
                    separate_module_features[:TypeLevel] = []
            end
            if !(__module__ in modules)
                push!(modules, __module__)
            end
        end
    end
end