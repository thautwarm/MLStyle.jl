using BenchmarkTools
using MacroTools
using MLStyle


ex = quote
    struct Foo
        x :: Int
        y
    end
end

function b_macrotools(ex)
    @capture(ex, struct T_ fields__ end)
    (T, fields)
end

function b_mlstyle(ex)
    MLStyle.@match ex begin
        Do(fields = []) &&
        quote
          $(::LineNumberNode)
          struct $typename
            $(
              Many(
                  ::LineNumberNode                 ||
                  :($name :: $typ) &&
                     Do(push!(fields, (name, typ)))||
                  (a :: Symbol)    &&
                     Do(push!(fields, (a, Any)))
              )...
            )
          end
        end => (typename, fields)
    end
end
# @info b_macrotools(ex)
# @info b_mlstyle(ex)

@btime b_macrotools(ex)
@btime b_mlstyle(ex)

# Output

# [ Info: (:Foo, Any[:(x::Int), :y])
# [ Info: (:Foo, Any[(:x, :Int), (:y, Any)])

# base:
#   18.824 μs (114 allocations: 6.41 KiB)
#   5.221 μs (32 allocations: 1.39 KiB)

#   19.825 μs (114 allocations: 6.41 KiB)
#   5.099 μs (30 allocations: 1.31 KiB)

# patterns-to-inline-functions:
# 19.903 μs (114 allocations: 6.41 KiB)
#   3.918 μs (30 allocations: 1.23 KiB)


module Samples

    node_fn1 = :(function f(a, b) a + b end)
    node_fn2 = :(function f(a, b, c...) c end)
    node_let = :(let x = a + b
                2x
            end)
    node_chain = :(subject.method(arg1, arg2))
    node_struct = :(
            struct name <: base
                field1 :: Int
                field2 :: Float32
            end
    )

    node_const = :(
            const a = value
    )
    node_assign = :(a = b + c)

end

module TestMatchJl
    using ..Samples
    using Match
    using BenchmarkTools

    extract_name(e :: Symbol) = e
    function extract_name(e::Expr)
        @match e begin
            Expr(:<:, [a, b])                  => extract_name(a)
            Expr(:struct,      [_, name, _])   => extract_name(name)
            Expr(:call,      [f, _...])        => extract_name(f)
            Expr(:., [subject, attr, _...])    => extract_name(subject)
            Expr(:function,  [sig, _...])      => extract_name(sig)
            Expr(:const,     [assn, _...])     => extract_name(assn)
            Expr(:(=),       [fn, body, _...]) => extract_name(fn)
            Expr(expr_type,  _...)             => error("Can't extract name from ",
                                                        expr_type, " expression:\n",
                                                        "    $e\n")
        end
    end

    @assert extract_name(Samples.node_fn1) == :f
    @assert extract_name(Samples.node_fn2) == :f
    @assert extract_name(Samples.node_chain) == :subject
    @assert extract_name(Samples.node_struct) == :name
    @assert extract_name(Samples.node_const) == :a
    @assert extract_name(Samples.node_assign) == :a

    @info "=======Match.jl=========="
    @info :node_fn1
    @btime extract_name(Samples.node_fn1) == :f
    @info :node_fn2
    @btime extract_name(Samples.node_fn2) == :f
    @info :node_chain
    @btime extract_name(Samples.node_chain) == :subject
    @info :node_struct
    @btime extract_name(Samples.node_struct) == :name
    @info :node_const
    @btime extract_name(Samples.node_const) == :a
    @info :node_assign
    @btime extract_name(Samples.node_assign) == :a

end

module TestMLStylejl
    using ..Samples
    using MLStyle
    using BenchmarkTools

    function extract_name(e)
        @match e begin
            ::Symbol                           => e
            Expr(:<:, a, _)                    => extract_name(a)
            Expr(:struct, _, name, _)          => extract_name(name)
            Expr(:call, f, _...)               => extract_name(f)
            Expr(:., subject, attr, _...)      => extract_name(subject)
            Expr(:function, sig, _...)         => extract_name(sig)
            Expr(:const, assn, _...)           => extract_name(assn)
            Expr(:(=), fn, body, _...)         => extract_name(fn)
            Expr(expr_type,  _...)             => error("Can't extract name from ",
                                                        expr_type, " expression:\n",
                                                        "    $e\n")
        end
    end

    @assert extract_name(Samples.node_fn1) == :f
    @assert extract_name(Samples.node_fn2) == :f
    @assert extract_name(Samples.node_chain) == :subject
    @assert extract_name(Samples.node_struct) == :name
    @assert extract_name(Samples.node_const) == :a
    @assert extract_name(Samples.node_assign) == :a

    @info "=======MLStyle.jl Expr pattern=========="
    @info :node_fn1
    @btime extract_name(Samples.node_fn1) == :f
    @info :node_fn2
    @btime extract_name(Samples.node_fn2) == :f
    @info :node_chain
    @btime extract_name(Samples.node_chain) == :subject
    @info :node_struct
    @btime extract_name(Samples.node_struct) == :name
    @info :node_const
    @btime extract_name(Samples.node_const) == :a
    @info :node_assign
    @btime extract_name(Samples.node_assign) == :a


    function extract_name_homoiconic(e)
        @match e begin
            ::Symbol                           => e
            :($a <: $_)                        => extract_name_homoiconic(a)
            :(struct $name <: $_
                $(_...)
              end)                             => name
            :($f($(_...)))                     => extract_name_homoiconic(f)
            :($subject.$_)                     => extract_name_homoiconic(subject)
            :(function $name($(_...))
                $(_...)
               end)                            => extract_name_homoiconic(name)
            :(const $assn = $_)                => extract_name_homoiconic(assn)
            :($fn = $_)                        => extract_name_homoiconic(fn)
            Expr(expr_type,  _...)             => error("Can't extract name from ",
                                                        expr_type, " expression:\n",
                                                        "    $e\n")
        end
    end

    @assert extract_name_homoiconic(Samples.node_fn1) == :f
    @assert extract_name_homoiconic(Samples.node_fn2) == :f
    @assert extract_name_homoiconic(Samples.node_chain) == :subject
    @assert extract_name_homoiconic(Samples.node_struct) == :name
    @assert extract_name_homoiconic(Samples.node_const) == :a
    @assert extract_name_homoiconic(Samples.node_assign) == :a

    @info "=======MLStyle.jl Ast pattern=========="
    @info :node_fn1
    @btime extract_name_homoiconic(Samples.node_fn1) == :f
    @info :node_fn2
    @btime extract_name_homoiconic(Samples.node_fn2) == :f
    @info :node_chain
    @btime extract_name_homoiconic(Samples.node_chain) == :subject
    @info :node_struct
    @btime extract_name_homoiconic(Samples.node_struct) == :name
    @info :node_const
    @btime extract_name_homoiconic(Samples.node_const) == :a
    @info :node_assign
    @btime extract_name_homoiconic(Samples.node_assign) == :a

end