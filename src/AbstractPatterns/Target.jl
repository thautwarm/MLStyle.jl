TypeObject = Union{DataType, Union, UnionAll}

"""representing the in-matching object in pattern compile time
"""
struct Target{IsComplex}
    repr::Any
    type::Ref{TypeObject}
end

@nospecialize

function target_method end

function Base.getproperty(target::Target, sym::Symbol)
    target_method(target, Val(sym))
end

function target_method(target::Target, ::Val{:type_narrow!})
    function (ty::TypeObject)
        tyref = getfield(target, :type)
        if tyref[] <: ty
        else
            tyref[] = ty
        end
    end
end

function target_method(target::Target, ::Val{:type})
    getfield(target, :type)[]
end


function target_method(target::Target, ::Val{:repr})
    getfield(target, :repr)
end

function target_method(target::Target{IsC}, ::Val{:with_repr}) where IsC
    function ap(repr::Any)
        Target{IsC}(repr,  getfield(target, :type))
    end
    function ap(repr::Any, ::Val{IsC′}) where IsC′
        Target{IsC′}(repr, getfield(target, :type))
    end
    ap
end

function target_method(target::Target{IsC}, ::Val{:with_type}) where IsC
    function ap(ty::TypeObject)
        Target{IsC}(target.repr, Ref{TypeObject}(ty))
    end
    function ap(ty::TypeObject, ::Val{IsC′}) where IsC′
        Target{IsC′}(target.repr, Ref{TypeObject}(ty))
    end
    ap
end

function target_method(target::Target{IsC}, ::Val{:clone}) where IsC
    Target{IsC}(target.repr, Ref{TypeObject}(target.type))
end

@specialize