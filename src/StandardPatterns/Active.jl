# Active patterns
module Active
using MLStyle
using MLStyle.Qualification
using MLStyle.AbstractPattern

export @active, active_def

function active_def(P, body, mod::Module, line::LineNumberNode)
    @switch P begin
        @case Expr(:call,
            Expr(:curly, t, type_args...) || t && let type_args = [],
            arg
        ) && if t isa Symbol end
        @case _
            error("malformed active pattern definition: $P")
    end
    
    definition = if isdefined(mod, t)
        line
    else
        struct $t end
    end
    parametric = isempty(type_args) ? :(::Nothing) : Expr(:tuple, type_args...)
    token = gensym(:mlstyle)
    prepr = "$P"
    quote
        $definition
        ::Val{($Base.view, $token)}($parametric, $arg) = $body
        $line
        function $MatchImpl.pattern_compile(t::typeof{$t}, self::Function, type_params, type_args, args)
            $line
            isempty(type_params) || error("A ($t) pattern requires no type params.")
            parametric = isempty(type_args) ? nothing : Expr(:tuple, type_args...)
            n_args = length(args)
            function trans(expr)
                f = Val(($Base.view, $token))
                Expr(:call, f, parametric, expr)
            end
            
            function guard2(expr)
                :($expr !== nothing)
            end
            
            extract = if length(args) === 1
                function (expr::Any, i::Int, ::Any, ::Any)
                    expr
                end :
                function (expr::Any, i::Int, ::Any, ::Any)
                    :($expr[$i])
                end
            type_infer(_...) = Any
            
            comp = $PComp(
                $prepr, ()->Any;
                guard2=guard2
            )
            decons(comp, extract, [self(arg) for arg in args])
        end
    end
end


"""
Simple active pattern implementation.
You can give a qualifier in the first argument of `@active` to customize its visibility in other modules.
```julia
    @active F(x) begin
        if x > 0
            nothing
        else
            :ok
        end
    end

    @match -1 begin
        F(:ok) => false
        _ => true
    end # true

    @active public IsEven(x) begin
        x % 2 === 0
    end

    @match 4 begin
        IsEven() => :ok
        _ => :err
    end # :ok
```
"""
macro active(qualifier, case, active_body)
    deprecate_qualifiers(qualifier)
    active_def(case, body, __module__, __source__)
   def_active_pattern(qualifier, case, active_body, __module__)
end

macro active(case, active_body)
    active_def(case, body, __module__, __source__)
end

end