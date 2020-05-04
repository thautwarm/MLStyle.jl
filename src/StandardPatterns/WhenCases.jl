module WhenCases
using MLStyle
using MLStyle.Sugars: Q
using MLStyle.AbstractPattern: init_cfg

export @when, @otherwise, gen_when

function split_case_and_block(stmts, first_bindings, first_source)
    blocks :: Vector{Any} = []
    binding_seqs :: Vector{Any} = [first_bindings]
    sources :: Vector{LineNumberNode} = [first_source]
    current_block = []

    function make_block!()
        # avoid setting LineNumberNode in the end of block.
        block_size = length(current_block)
        take_size = block_size
        for i in block_size:-1:1
            take_size = i
            current_block[i] isa LineNumberNode || break
        end
        # push current_block(cache) to blocks, then clear cache
        push!(blocks, Expr(:block, view(current_block, 1:take_size)...))
        empty!(current_block)
        nothing
    end

    function append_block!(a)
        push!(current_block, a)
        nothing
    end

    for stmt in stmts
        @switch stmt begin
        @case :(@when $source begin $(bindings...) end) ||
              Q[@when $source $elt] && let bindings=[elt] end
                
            push!(binding_seqs, bindings)
            push!(sources, source)
            make_block!()
            continue
        @case Q[@otherwise $source]
            push!(binding_seqs, [])
            push!(sources, source)
            make_block!()
            continue
        @case a
            append_block!(a)
            continue
        end
    end

    make_block!()
    # thus, the length of `sources`, `binding_seqs` and `blocks`
    # are guaranteed to be the same.
    collect(zip(sources, binding_seqs, blocks))
end

"""
Used in the `@when` block:

```julia
@when (a, b) = x begin
    a + b
@otherwise
    0
end
```

See also: [`@when`](@ref)
"""
macro otherwise()
    throw(SyntaxError("@otherwise is only used inside @when block, as a token to indicate default case."))
end

"""
Code generation for `@when`.
You should pass an `Expr(:let, ...)` as the first argument.
"""
function gen_when(let_expr, source :: LineNumberNode, mod :: Module)
    @switch let_expr begin
    @case Expr(:let,
            Expr(:block, bindings...) || a && let bindings = [a] end,
            Expr(:block, stmts...)    || b && let stmts = [b] end)
            sources_cases_blocks = split_case_and_block(stmts, bindings, source)
            return foldr(sources_cases_blocks, init=:nothing) do (source, bindings, block), last_block
                foldr(bindings, init=block) do each, last_ret
                    @switch each begin
                    @case :($a = $b)
                        cbl = Expr(:block, source, :($a => $last_ret), :(_ => $last_block))
                        return gen_match(b, cbl, source, mod)
                       
                    @case new_source::LineNumberNode
                        source = new_source
                        return last_ret    

                        # match `cond.?` or `if cond end`
                    @case :(if $a; $(_...) end) ||
                          :($a.?)
                        
                        return Expr(:block, source, :($a ? $last_ret : $last_block))
                          
                    # match something like: `let a; a = 1; a end`
                    @case a
                        return Expr(:block, source, Expr(:let, a, last_ret))
                    end
                end
            end

    @case a 
        s = string(a)
        short_msg = SubString(s, 1, min(length(s), 20))
        throw(SyntaxError("Expected a let expression, got a `$short_msg` at $(string(source))."))
    end
end

"""
1. Allow destructuring in binding sequences of `let` syntax.

In binding sequences,
- For bindings in form of `a = b` and `f(x) = y`, it's regarded as pattern matching here.
- For others like `@inline f(x) = 1`, it's the same as the original let binding(not pattern matching).

```julia
    @when let (a, 1) = x,
          [b, c, 5] = y
        (a, b, c)
    end
```

2. For a regular assignment, like

```julia
    @when (a, 2) = x begin
        # dosomething
    end
```

It's nothing different from

```julia
    @match x begin
        (a, 2) => # dosomething
        _ => nothing
    end
```

3. For multiple branches, we can have

```julia
x = 1
@when let (_, _) = x
    :tuple
@when begin ::Float64 = x end
    :float
@when ::Int = x
    :int
@otherwise
    :unknown
end
```

4. Also, you can use predicates when matching, in the form
of `cond.?` or `if cond end`:

```julia
x = 1
y = (1, 2)
cond1 = true
cond2 = true
@when let cond1.?,
          (a, b) = x
    a + b
@when begin if cond2 end
            (a, b) = y
      end
    a + b
end
```
"""
macro when(let_expr)
    res = gen_when(let_expr, __source__, __module__)
    res = init_cfg(res)
    esc(res)
end

macro when(assignment, ret)
    @match assignment begin
        :($_ = $_) =>
            let let_expr = Expr(:let, Expr(:block, assignment), ret)
                res = gen_when(let_expr, __source__, __module__)
                res = init_cfg(res)
                esc(res)
            end
        _ => throw(SyntaxError("Not match the form of `@when a = b expr`"))
    end
end

end