module WhenCases
using MLStyle
using MLStyle.Render

export @when, @otherwise, gen_when

@active WhenSpliter{s::String}(x) begin
    @match x begin
        Expr(:macrocall,
            &(Symbol("@", s)),
            ln::LineNumberNode,
            Expr(:block, elts...) || a && Do(elts = [a])
        ) => (ln, elts)
        Expr(:macrocall,
            &(Symbol("@", s)),
            ln::LineNumberNode
            # no args
        ) => (ln, [:(_)])
        _ => nothing
    end
end

function split_case_and_block(stmts, first_bindings, first_source)
    blocks :: Vector{Any} = []
    binding_seqs :: Vector{Any} = [first_bindings]
    sources :: Vector{LineNumberNode} = [first_source]
    current_block = []

    function make_block!()

        # avoid setting LineNumberNode in the end of block.
        block_size = length(current_block)
        take_size = block_size
        for i in block_size:-1:(block_size - 1)
            take_size = i
            if !(current_block[i] isa LineNumberNode)
                break
            end
        end
        # push current_block(cache) to current_block, then clear cache
        push!(blocks, Expr(:block, view(current_block, take_size)...))
        empty!(current_block)
        nothing
    end

    function append_block!(a)
        push!(current_block, a)
        nothing
    end

    for stmt in stmts
        @match stmt begin
            WhenSpliter{"when"}(source, bindings) =>
                begin
                    push!(binding_seqs, bindings)
                    push!(sources, source)
                    make_block!()
                end
            WhenSpliter{"otherwise"}(source, _) =>
                begin
                    push!(binding_seqs, [])
                    push!(sources, source)
                    make_block!()
                end
            a => append_block!(a)
        end
    end
    make_block!()
    # thus, the length of `sources`, `binding_seqs` and `blocks`
    # are guaranteed to be the same.
    collect(zip(sources, binding_seqs, blocks))
end

"""
Used in the `@when` block:

```
@when (a, b) = x begin
    a + b
@otherwise
    0
end
```
"""
macro otherwise()
    throw(SyntaxError("@otherwise is only used inside @when block, as a token to indicate default case."))
end

"""
Code generation for `@when`.
You should pass an `Expr(:let, ...)` as the first argument.
"""
function gen_when(let_expr, source :: LineNumberNode, mod :: Module)
    @match let_expr begin
        Expr(:let,
            Expr(:block, bindings...) || a && Do(bindings = [a]),
            Expr(:block, stmts...) || b && Do(stmts = [b])) =>

            begin
                sources_cases_blocks = split_case_and_block(stmts, bindings, source)
                # pprint(sources_cases_blocks)
                foldr(sources_cases_blocks, init=:nothing) do (source, bindings, block), last_block
                    foldr(bindings, init=block) do each, last_ret
                        @match each begin
                            :($a = $b) =>
                                let cbl = @format [source, a, last_ret, last_block] quote
                                            source
                                            a => last_ret
                                            _ => last_block
                                        end
                                    gen_match(b, cbl, source, mod)
                                    # :(@match $b $cbl)
                                end

                            # like:
                            # let a; a = 1; a end
                            new_source::LineNumberNode => begin
                                    source = new_source
                                    last_ret
                                end
                            :(if $a; $(_...) end) ||
                            :($a.?) => @format [source, a, last_ret, last_block] quote
                                    source
                                    a ? last_ret : last_block
                                end
                            a => @format [source, a, last_ret] quote
                                    source
                                    let a
                                        last_ret
                                    end
                                end
                        end
                    end
                end
            end

        a => let short_msg = SubString(string(a), 1, 20)
                throw(SyntaxError("Expected a let expression, got a `$short_msg` at $(string(source))."))
            end
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
@when begin ::Float = x end
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
    gen_when(let_expr, __source__, __module__) |> esc
end

macro when(assignment, ret)
    @match assignment begin
        :($_ = $_) =>
            let let_expr = Expr(:let, Expr(:block, assignment), ret)
                gen_when(let_expr, __source__, __module__) |> esc
            end
        _ => @syntax_err "Not match the form of `@when a = b expr`"
    end
end

end