struct ChainDict{K, V}
    cur :: Dict{K, V}
    init :: Ref{ChainDict{K, V}}
end

ChainDict(cur::Dict{K, V}, init::ChainDict{K, V}) where {K, V} = ChainDict(cur, Ref(init))
ChainDict(cur::Dict{K, V}) where {K, V} = ChainDict(cur, Ref{ChainDict{K, V}}())
ChainDict{K, V}() where {K, V} = ChainDict(Dict{K, V}())

function Base.get!(f::Function, c::ChainDict{K, V}, k::K)::V where {K, V}
    get!(c.cur, k) do
        f()
    end
end

function Base.get(c::ChainDict{K, V}, k::K)::V where {K, V}
    get(c.cur, k) do
         isassigned(c.init) ?
            get(c.init[], k) :
            throw(KeyError(k))
         end
end

function Base.get(f::Function, c::ChainDict{K, V}, k::K) where {K, V}
    get(c.cur, k) do
         isassigned(c.init) ?
            get(f, c.init[], k) :
            f()
         end
end

function for_chaindict(f::Function, d::ChainDict{K, V}) where {K, V}
    keys = Set{K}()
    while true
        for (k, v) in d.cur
            if k in keys
                continue
            else
                push!(keys, k)
            end
            f(k, v)
        end
        if isassigned(d.init)
            d = d.init[]
        else
            return
        end
    end
end

function for_chaindict_dup(f::Function, d::ChainDict{K, V}) where {K, V}
    while true
        for (k, v) in d.cur
            f(k, v)
        end
        if isassigned(d.init)
            d = d.init[]
        else
            return
        end
    end
end

Base.getindex(c::ChainDict, k) = Base.get(c, k)

function Base.setindex!(c::ChainDict{K, V}, value::V, k::K) where {K, V}
    c.cur[k] = value
end
        
function child(c::ChainDict{K, V}) where {K, V}
    ChainDict(Dict{K, V}(), c)
end

function parent(c::ChainDict{K, V}) where {K, V}
    c.init[]
end