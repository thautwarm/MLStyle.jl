module Record
using MLStyle
using MLStyle.MatchCore
using MLStyle.MatchImpl
using MLStyle.AbstractPattern
using MLStyle.AbstractPattern.BasicPatterns
using MLStyle.Qualification

export @as_record, record_def


function P_partial_struct_decons(t, partial_fields, ps, prepr::AbstractString="$t")
    function tcons(_...)
        t
    end
    
    comp = PComp(
        prepr, tcons;
    )
    function extract(sub::Any, i::Int, ::Any, ::Any)
        :($sub.$(partial_fields[i]))
    end
    decons(comp, extract, ps)
end

function record_def(Struct, line::LineNumberNode, ::Module)
    quote
        $line
        function $MatchImpl.pattern_uncall(t::Type{$Struct}, self::Function, type_params, type_args, args)
            $line
            isempty(type_params) || return begin
                call = Expr(:call, t, args...)
                ann = Expr(:curly, t, type_args...)
                self(Where(call, ann, type_params))
            end
            all_field_names = fieldnames(t)
            partial_field_names = Symbol[]
            patterns = Function[]
            $MatchImpl.@switch args begin    
            @case [Expr(:parameters, kwargs...), args...]
                @goto endswitch
            @case let kwargs = [] end
                @goto endswitch
            end
            @label endswitch
            n_args = length(args)
            if all(Meta.isexpr(arg, :kw) for arg in args)
                for arg in args
                    field_name = arg.args[1]
                    field_name in all_field_names || error("$t has no field $field_name.")
                    push!(partial_field_names, field_name)
                    push!(patterns, self(arg.args[2]))
                end
            elseif length(all_field_names) === n_args
                append!(patterns, map(self, args))
                append!(partial_field_names, all_field_names)
            elseif n_args === 1 && args[1] === :_
            elseif n_args !== 0
                error("count of positional fields should be 0 or the same as the fields($all_field_names)")
            end
            for e in kwargs
                $MatchImpl.@switch e begin
                @case :: Symbol
                    e in all_field_names || error("unknown field name $e for $t when field punnning.")
                    push!(partial_field_names, e)
                    push!(patterns, $P_capture(e))
                    continue
                @case Expr(:kw, key::Symbol, value)
                    key in all_field_names || error("unknown field name $key for $t when field punnning.")
                    push!(partial_field_names, key)
                    push!(patterns, $and([$P_capture(key), self(value)]))
                    continue
                @case _
                    
                    error("unknown sub-pattern $e in " * string(t) * ".")
                end
            end
            
            ret = $P_partial_struct_decons(t, partial_field_names, patterns)
            isempty(type_args) && return ret
            $and([self(Expr(:(::), Expr(:curly, t, type_args...))) , ret])
        end
    end
end

function as_record(n, line::LineNumberNode, __module__::Module)
    @switch n begin
    @case ::Symbol
        return record_def(n, line, __module__)
    @case :(struct $hd{$(_...)}
                $(_...)
            end) ||
          :(struct $hd{$(_...)} <: $_
            $(_...)
            end) ||
          :(struct $hd <: $_
                $(_...)
            end) ||
          :(struct $hd
                $(_...)
            end)
        return Expr(
            :block,
            n,
            record_def(hd, line)
        )
    @case _
        error("malformed structure $n")
    end
end



macro as_record(qualifier, n)
    deprecate_qualifiers(qualifier)
    esc(as_record(n, __source__, __module__))
end

macro as_record(n)
    esc(as_record(n, __source__, __module__))
end

end

