include("Benchmarkplotting.jl/src/Benchmarkplotting.jl")

module VersusMacroTools
    using ..Benchmarkplotting
    using MLStyle
    using Statistics
    using Gadfly
    using MacroTools: @capture

    data = [
        :simple1 => quote
            struct Foo
                x :: Int
                y
            end
        end,

        :simple2 => quote
            struct Foo
                x :: Int
                y :: Array{Int}
            end
        end,

        Symbol("N(fields) = 5") => quote
            struct Foo
                x1 :: Int
                x2 :: Int
                x3 :: Int
                x4 :: Float32
                x5 :: Int
            end
        end,
        Symbol("N(fields) = 10") => quote
            struct Foo
                x1 :: Int
                x2 :: Int
                x3 :: Int
                x4 :: Float32
                x5 :: Int
                x6 :: Int
                x7 :: Int
                x8 :: Int
                x9 :: Int
                x10 :: Int
            end
        end
    ]

    implementations = [
        :MacroTools => function(ex)
            @capture(ex, struct T_ fields__ end)
            (T, fields)
        end,
        :MLStyle => function (ex)
            @match ex begin
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
    ]

    criterion(x) = (meantime = mean(x.times), allocs = float(x.allocs))
    df = Benchmarkplotting.bcompare(criterion, data, implementations)

    report_meantime = report(:meantime, df, Scale.y_log10)[1]
    report_allocs = report(:allocs, df)[1]

    draw(SVG("vs-macrotools-on-time.svg", 10inch, 4inch), report_meantime);
    draw(SVG("vs-macrotools-on-allocs.svg", 10inch, 4inch), report_allocs);
end

module VersusMatch
    using ..Benchmarkplotting
    using Statistics
    using Gadfly
    using MLStyle
    using Match
    import Base.getindex
    getindex(asoc_lst :: Vector{Pair{Symbol, T}}, key ::Symbol) where T =
        for (search_key, value) in asoc_lst
            if search_key === key
                return value
            end
        end

    data = [
        :node_fn1 => :(function f(a, b) a + b end),
        :node_fn2 => :(function f(a, b, c...) c end),
        :node_chain => :(subject.method(arg1, arg2)),
        :node_struct => :(
                struct name <: base
                    field1 :: Int
                    field2 :: Float32
                end
        ),
        :node_const => :(
                const a = value
        ),
        :node_assign => :(a = b + c)
    ]
    implementations = [
        :Match =>  let
            extract_name(e :: Symbol) = e
            function extract_name(e::Expr)
                Match.@match e begin
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
            @assert extract_name(data[:node_fn1]) == :f
            @assert extract_name(data[:node_fn2]) == :f
            @assert extract_name(data[:node_chain]) == :subject
            @assert extract_name(data[:node_struct]) == :name
            @assert extract_name(data[:node_const]) == :a
            @assert extract_name(data[:node_assign]) == :a
            extract_name
        end,
        Symbol(:MLStyle, " Expr-pattern") => let
            function extract_name(e)
                MLStyle.@match e begin
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
            @assert extract_name(data[:node_fn1]) == :f
            @assert extract_name(data[:node_fn2]) == :f
            @assert extract_name(data[:node_chain]) == :subject
            @assert extract_name(data[:node_struct]) == :name
            @assert extract_name(data[:node_const]) == :a
            @assert extract_name(data[:node_assign]) == :a
            extract_name
        end,
        Symbol(:MLStyle, " AST-pattern") => let
            function extract_name_homoiconic(e)
                MLStyle.@match e begin
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
            @assert extract_name_homoiconic(data[:node_fn1]) == :f
            @assert extract_name_homoiconic(data[:node_fn2]) == :f
            @assert extract_name_homoiconic(data[:node_chain]) == :subject
            @assert extract_name_homoiconic(data[:node_struct]) == :name
            @assert extract_name_homoiconic(data[:node_const]) == :a
            @assert extract_name_homoiconic(data[:node_assign]) == :a
            extract_name_homoiconic
        end
    ]
    criterion(x) = (meantime = mean(x.times), allocs = float(x.allocs))
    df = bcompare(criterion, data, implementations)

    report_meantime = report(:meantime, df, Scale.y_log10)[1]
    report_allocs = report(:allocs, df)[1]

    draw(SVG("vs-match-on-time.svg", 10inch, 4inch), report_meantime);
    draw(SVG("vs-match-on-allocs.svg", 10inch, 4inch), report_allocs);

end