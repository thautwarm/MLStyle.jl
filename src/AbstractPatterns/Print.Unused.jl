@nospecialize
Print = (
    indent = function Print_indent(p)
        function (io::IO, prefix::AbstractString)
            prefix = "  " * prefix
            p(io, prefix)
        end
    end,
    line =  function Print_line(io::IO, prefix :: AbstractString)
        println(io)
        print(io, prefix)
    end,
    w = function Print_word(s::AbstractString)
        function write(io::IO, ::AbstractString)
            print(io, s)    
        end
    end,
    seq = function Print_seq(ps...)
        function (io::IO, prefix::AbstractString)
            prefix = prefix
            for p in ps
                p(io, prefix)
            end
        end
    end,
    run = function Print_run(io::IO, builder)
        builder(io, "")
    end
)
@specialize