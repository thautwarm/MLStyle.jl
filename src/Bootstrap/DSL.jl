
module DSL
using Meta: isexpr
using MLStyle.Bootstrap.Proto

@_active CST{sym :: Symbol}(x) quote
    if isexpr(x, sym)
        x.args
    end
end


end