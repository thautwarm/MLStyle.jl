# Active patterns
module Active
using MLStyle
using MLStyle.Qualification
using MLStyle.AbstractPatterns

export @active, active_def
@nospecialize
function active_def(P, body, mod::Module, line::LineNumberNode)

    @switch P begin
        @case Expr(:call,
            Expr(:curly, t, type_args...) || t && let type_args = [] end,
            arg
        ) && if t isa Symbol end

        @case _
            error("malformed active pattern definition: $P")
    end
    
    definition = if isdefined(mod, t)
        line
    else
        :(struct $t end)
    end
    parametric = isempty(type_args) ? [] : type_args
    prepr = "$P"
    token = gensym(prepr)
    v_ty = Val{(view, token)}
    v_val = Val((view, token))

    quote
        $definition
        (::$v_ty)($(parametric...), ) = $arg -> $body
        $line
        function $MLStyle.pattern_uncall(t::($t isa Function ? typeof($t) : Type{$t}), self::Function, type_params, type_args, args)
            $line
            isempty(type_params) || error("A ($t) pattern requires no type params.")
            parametric = isempty(type_args) ? [] : type_args
            n_args = length(args)
        
            function trans(expr)
                Expr(:call, Expr(:call, $v_val, parametric...), expr)
            end
            
            function guard2(expr)
                if n_args === 0
                    :($expr isa Bool && $expr)
                elseif n_args === 1
                    expr_s = "$t(x)"
                    msg = "invalid use of active patterns: " *
                          "1-ary view pattern($expr_s) should accept Union{Some{T}, Nothing} " *
                          "instead of Union{T, Nothing}! " *
                           "A simple solution is:\n" *
                           "  (@active $expr_s ex) =>\n  (@active $expr_s let r=ex; r === nothing? r : Some(r)) end"
                            
                    :($expr !== nothing && ($expr isa $Some || begin
                        $error($msg)
                    end))
                else
                    :($expr isa $Tuple && length($expr) === $n_args)
                end
            end
            
            extract = if n_args <= 1
                function (expr::Any, i::Int, ::Any, ::Any)
                    expr
                end
            else
                function (expr::Any, i::Int, ::Any, ::Any)
                    :($expr[$i])
                end
            end
                
            type_infer(_...) = Any
            
            comp = $PComp(
                $prepr, type_infer;
                view=$SimpleCachablePre(trans),
                guard2=$NoncachablePre(guard2)
            )
            ps = if n_args === 0
                []
            elseif n_args === 1
                [self(Expr(:call, Some, args[1]))]
            else
                [self(e) for e in args]
            end    
            $decons(comp, extract, ps)
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
    active_def(case, active_body, __module__, __source__) |> esc
end

macro active(case, active_body)
    active_def(case, active_body, __module__, __source__) |> esc
end
@specialize

end