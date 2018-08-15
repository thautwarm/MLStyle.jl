module Feature
    export activate

    function activate(symbols :: Vararg{Symbol})
        if :TypeLevel in symbols
            TypeLevel.set(true)
        end
    end

    module TypeLevel
        activate = false
        set(status :: Bool) = begin
            global activate = status
        end
    end

end