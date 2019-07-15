
function mod_show(ex::Expr) 
    s = IOBuffer(sizehint=0)
    show_unquoted(s, ex)
    s.ptr=1
    read(s, String)
end

# elseif (head === :& || head === :$) && nargs == 1
function dollar_output(io, head, args)
    print(io, head)
    a1 = args[1]
    parens = (isa(a1,Expr) && a1.head !== :tuple) || (isa(a1,Symbol) && isoperator(a1))
    parens && print(io, "(")
    show_unquoted(io, a1)
    parens && print(io, ")")
end

# NOT modified begin
## ==========================================================================
import Base: show_import_path, show_generator, show_unquoted_quote_expr,
    ## AST printing constants ##
    indent_width, quoted_syms, uni_syms, uni_ops, expr_infix_wide,
    expr_infix, expr_infix_any, expr_calls, expr_parens,
    ## AST decoding helpers ##
    isidentifier, isoperator, operator_precedence,
    is_expr, is_quoted, unquoted,
    ## AST printing helpers ##
    show_linenumber, show_block, show_list, show_enclosed_list,
    show_call

## AST printing ##

function valid_import_path(@nospecialize ex)
    return Meta.isexpr(ex, :(.)) && length(ex.args) > 0 && all(a->isa(a,Symbol), ex.args)
end

show_unquoted(io::IO, ex)              = show_unquoted(io, ex, 0, 0)
show_unquoted(io::IO, ex, indent::Int) = show_unquoted(io, ex, indent, 0)
show_unquoted(io::IO, ex, ::Int,::Int) = show(io, ex)
show_unquoted(io::IO, sym::Symbol, ::Int, ::Int)        = print(io, sym)
show_unquoted(io::IO, ex::LineNumberNode, ::Int, ::Int) = show_linenumber(io, ex.line, ex.file)
function show_unquoted(io::IO, ex::GlobalRef, ::Int, ::Int)
    print(io, ex.mod)
    print(io, '.')
    quoted = !isidentifier(ex.name) && !startswith(string(ex.name), "@")
    parens = quoted && (!isoperator(ex.name) || (ex.name in quoted_syms))
    quoted && print(io, ':')
    parens && print(io, '(')
    print(io, ex.name)
    parens && print(io, ')')
    nothing
end

function show_unquoted(io::IO, ex::QuoteNode, indent::Int, prec::Int)
    if isa(ex.value, Symbol)
        show_unquoted_quote_expr(io, ex.value, indent, prec)
    else
        print(io, "\$(QuoteNode(")
        show(io, ex.value)
        print(io, "))")
    end
end
## ==========================================================================
# NOT modified end


## https://github.com/JuliaLang/julia/blob/master/base/show.jl#L1122
function show_unquoted(io::IO, ex::Expr, indent::Int, prec::Int)
    head, args, nargs = ex.head, ex.args, length(ex.args)
    unhandled = false
    # dot (i.e. "x.y"), but not compact broadcast exps
    if head === :(.) && (nargs != 2 || !is_expr(args[2], :tuple))
        if nargs == 2 && is_quoted(args[2])
            item = args[1]
            # field
            field = unquoted(args[2])
            parens = !is_quoted(item) && !(item isa Symbol && isidentifier(item)) && !Meta.isexpr(item, :(.))
            parens && print(io, '(')
            show_unquoted(io, item, indent)
            parens && print(io, ')')
            # .
            print(io, '.')
            # item
            parens = !(field isa Symbol) || (field in quoted_syms)
            quoted = parens || isoperator(field)
            quoted && print(io, ':')
            parens && print(io, '(')
            show_unquoted(io, field, indent)
            parens && print(io, ')')
        else
            unhandled = true
        end

    # infix (i.e. "x <: y" or "x = y")
    elseif (head in expr_infix_any && nargs==2)
        func_prec = operator_precedence(head)
        head_ = head in expr_infix_wide ? " $head " : head
        if func_prec <= prec
            show_enclosed_list(io, '(', args, head_, ')', indent, func_prec, true)
        else
            show_list(io, args, head_, indent, func_prec, true)
        end

    # list (i.e. "(1, 2, 3)" or "[1, 2, 3]")
    elseif haskey(expr_parens, head)               # :tuple/:vcat
        op, cl = expr_parens[head]
        if head === :vcat || head === :bracescat
            sep = "; "
        elseif head === :hcat || head === :row
            sep = " "
        else
            sep = ", "
        end
        head !== :row && print(io, op)
        show_list(io, args, sep, indent)
        if nargs == 1
            if head === :tuple
                print(io, ',')
            elseif head === :vcat
                print(io, ';')
            end
        end
        head !== :row && print(io, cl)

    # function call
    elseif head === :call && nargs >= 1
        func = args[1]
        fname = isa(func, GlobalRef) ? func.name : func
        func_prec = operator_precedence(fname)
        if func_prec > 0 || fname in uni_ops
            func = fname
        end
        func_args = args[2:end]

        # scalar multiplication (i.e. "100x")
        if (func === :* &&
            length(func_args)==2 && isa(func_args[1], Real) && isa(func_args[2], Symbol))
            if func_prec <= prec
                show_enclosed_list(io, '(', func_args, "", ')', indent, func_prec)
            else
                show_list(io, func_args, "", indent, func_prec)
            end

        # unary operator (i.e. "!z")
        elseif isa(func,Symbol) && func in uni_ops && length(func_args) == 1
            show_unquoted(io, func, indent)
            arg1 = func_args[1]
            if isa(arg1, Expr) || (isa(arg1, Symbol) && isoperator(arg1))
                show_enclosed_list(io, '(', func_args, ", ", ')', indent, func_prec)
            else
                show_unquoted(io, arg1, indent, func_prec)
            end

        # binary operator (i.e. "x + y")
        elseif func_prec > 0 # is a binary operator
            na = length(func_args)
            if (na == 2 || (na > 2 && func in (:+, :++, :*)) || (na == 3 && func === :(:))) &&
                    all(!isa(a, Expr) || a.head !== :... for a in func_args)
                sep = func === :(:) ? "$func" : " $func "

                if func_prec <= prec
                    show_enclosed_list(io, '(', func_args, sep, ')', indent, func_prec, true)
                else
                    show_list(io, func_args, sep, indent, func_prec, true)
                end
            elseif na == 1
                # 1-argument call to normally-binary operator
                op, cl = expr_calls[head]
                print(io, "(")
                show_unquoted(io, func, indent)
                print(io, ")")
                show_enclosed_list(io, op, func_args, ", ", cl, indent)
            else
                show_call(io, head, func, func_args, indent)
            end

        # normal function (i.e. "f(x,y)")
        else
            show_call(io, head, func, func_args, indent)
        end

    # new expr
    elseif head === :new || head === :splatnew
        show_enclosed_list(io, "%$head(", args, ", ", ")", indent)

    # other call-like expressions ("A[1,2]", "T{X,Y}", "f.(X,Y)")
    elseif haskey(expr_calls, head) && nargs >= 1  # :ref/:curly/:calldecl/:(.)
        funcargslike = head == :(.) ? args[2].args : args[2:end]
        show_call(io, head, args[1], funcargslike, indent)

    # comprehensions
    elseif head === :typed_comprehension && nargs == 2
        show_unquoted(io, args[1], indent)
        print(io, '[')
        show_generator(io, args[2], indent)
        print(io, ']')

    elseif head === :comprehension && nargs == 1
        print(io, '[')
        show_generator(io, args[1], indent)
        print(io, ']')

    elseif (head === :generator && nargs >= 2) || (head === :flatten && nargs == 1)
        print(io, '(')
        show_generator(io, ex, indent)
        print(io, ')')

    elseif head === :filter && nargs == 2
        show_unquoted(io, args[2], indent)
        print(io, " if ")
        show_unquoted(io, args[1], indent)

    # comparison (i.e. "x < y < z")
    elseif head === :comparison && nargs >= 3 && (nargs&1==1)
        comp_prec = minimum(operator_precedence, args[2:2:end])
        if comp_prec <= prec
            show_enclosed_list(io, '(', args, " ", ')', indent, comp_prec)
        else
            show_list(io, args, " ", indent, comp_prec)
        end

    # function calls need to transform the function from :call to :calldecl
    # so that operators are printed correctly
    elseif head === :function && nargs==2 && is_expr(args[1], :call)
        show_block(io, head, Expr(:calldecl, args[1].args...), args[2], indent)
        print(io, "end")

    elseif (head === :function || head === :macro) && nargs == 1
        print(io, head, ' ', args[1], " end")

    elseif head === :do && nargs == 2
        show_unquoted(io, args[1], indent, -1)
        print(io, " do ")
        show_list(io, args[2].args[1].args, ", ", 0)
        for stmt in args[2].args[2].args
            print(io, '\n', " "^(indent + indent_width))
            show_unquoted(io, stmt, indent + indent_width, -1)
        end
        print(io, '\n', " "^indent)
        print(io, "end")

    # block with argument
    elseif head in (:for,:while,:function,:macro,:if,:elseif,:let) && nargs==2
        show_block(io, head, args[1], args[2], indent)
        print(io, "end")

    elseif (head === :if || head === :elseif) && nargs == 3
        show_block(io, head, args[1], args[2], indent)
        if isa(args[3],Expr) && args[3].head == :elseif
            show_unquoted(io, args[3], indent, prec)
        else
            show_block(io, "else", args[3], indent)
            print(io, "end")
        end

    elseif head === :module && nargs==3 && isa(args[1],Bool)
        show_block(io, args[1] ? :module : :baremodule, args[2], args[3], indent)
        print(io, "end")

    # type declaration
    elseif head === :struct && nargs==3
        show_block(io, args[1] ? Symbol("mutable struct") : Symbol("struct"), args[2], args[3], indent)
        print(io, "end")

    elseif head === :primitive && nargs == 2
        print(io, "primitive type ")
        show_list(io, args, ' ', indent)
        print(io, " end")

    elseif head === :abstract && nargs == 1
        print(io, "abstract type ")
        show_list(io, args, ' ', indent)
        print(io, " end")

    # empty return (i.e. "function f() return end")
    elseif head === :return && nargs == 1 && args[1] === nothing
        print(io, head)

    # type annotation (i.e. "::Int")
    elseif head in uni_syms && nargs == 1
        print(io, head)
        show_unquoted(io, args[1], indent)

    # var-arg declaration or expansion
    # (i.e. "function f(L...) end" or "f(B...)")
    elseif head === :(...) && nargs == 1
        show_unquoted(io, args[1], indent)
        print(io, "...")

    elseif (nargs == 0 && head in (:break, :continue))
        print(io, head)

    elseif (nargs == 1 && head in (:return, :const)) ||
                          head in (:local,  :global, :export)
        print(io, head, ' ')
        show_list(io, args, ", ", indent)

    elseif head === :macrocall && nargs >= 2
        # first show the line number argument as a comment
        if isa(args[2], LineNumberNode) || is_expr(args[2], :line)
            print(io, args[2], ' ')
        end
        # Use the functional syntax unless specifically designated with prec=-1
        # and hide the line number argument from the argument list
        if prec >= 0
            show_call(io, :call, args[1], args[3:end], indent)
        else
            show_args = Vector{Any}(undef, nargs - 1)
            show_args[1] = args[1]
            show_args[2:end] = args[3:end]
            show_list(io, show_args, ' ', indent)
        end

    elseif head === :line && 1 <= nargs <= 2
        show_linenumber(io, args...)

    elseif head === :try && 3 <= nargs <= 4
        show_block(io, "try", args[1], indent)
        if is_expr(args[3], :block)
            show_block(io, "catch", args[2] === false ? Any[] : args[2], args[3], indent)
        end
        if nargs >= 4 && is_expr(args[4], :block)
            show_block(io, "finally", Any[], args[4], indent)
        end
        print(io, "end")

    elseif head === :block
        show_block(io, "begin", ex, indent)
        print(io, "end")

    elseif head === :quote && nargs == 1 && isa(args[1], Symbol)
        show_unquoted_quote_expr(io, args[1]::Symbol, indent, 0)

    elseif head === :gotoifnot && nargs == 2 && isa(args[2], Int)
        print(io, "unless ")
        show_unquoted(io, args[1], indent, 0)
        print(io, " goto %")
        print(io, args[2]::Int)

    elseif head === :string && nargs == 1 && isa(args[1], AbstractString)
        show(io, args[1])

    elseif head === :null
        print(io, "nothing")

    elseif head === :kw && nargs == 2
        show_unquoted(io, args[1], indent+indent_width)
        print(io, '=')
        show_unquoted(io, args[2], indent+indent_width)

    elseif head === :string
        print(io, '"')
        for x in args
            if !isa(x,AbstractString)
                print(io, "\$(")
                if isa(x,Symbol) && !(x in quoted_syms)
                    print(io, x)
                else
                    show_unquoted(io, x)
                end
                print(io, ")")
            else
                escape_string(io, x, "\"\$")
            end
        end
        print(io, '"')
    
    ## NOTE: Modified!
    # elseif (head === :&#= || head === :$=#) && nargs == 1
    elseif (head === :& || head === :$) && nargs == 1
        dollar_output(io, head, args)
        # print(io, head)
        # a1 = args[1]
        # parens = (isa(a1,Expr) && a1.head !== :tuple) || (isa(a1,Symbol) && isoperator(a1))
        # parens && print(io, "(")
        # show_unquoted(io, a1)
        # parens && print(io, ")")

    # transpose
    elseif head === Symbol('\'') && nargs == 1
        if isa(args[1], Symbol)
            show_unquoted(io, args[1])
        else
            print(io, "(")
            show_unquoted(io, args[1])
            print(io, ")")
        end
        print(io, head)

    # `where` syntax
    elseif head === :where && nargs > 1
        parens = 1 <= prec
        parens && print(io, "(")
        show_unquoted(io, args[1], indent, operator_precedence(:(::)))
        print(io, " where ")
        if nargs == 2
            show_unquoted(io, args[2], indent, 1)
        else
            print(io, "{")
            show_list(io, args[2:end], ", ", indent)
            print(io, "}")
        end
        parens && print(io, ")")

    elseif (head === :import || head === :using) && nargs == 1 &&
            (valid_import_path(args[1]) ||
             (Meta.isexpr(args[1], :(:)) && length(args[1].args) > 1 && all(valid_import_path, args[1].args)))
        print(io, head)
        print(io, ' ')
        first = true
        for a in args
            if !first
                print(io, ", ")
            end
            first = false
            show_import_path(io, a)
        end
    elseif head === :meta && nargs >= 2 && args[1] === :push_loc
        print(io, "# meta: location ", join(args[2:end], " "))
    elseif head === :meta && nargs == 1 && args[1] === :pop_loc
        print(io, "# meta: pop location")
    elseif head === :meta && nargs == 2 && args[1] === :pop_loc
        print(io, "# meta: pop locations ($(args[2]))")
    # print anything else as "Expr(head, args...)"
    else
        unhandled = true
    end
    if unhandled
        print(io, "\$(Expr(")
        show(io, ex.head)
        for arg in args
            print(io, ", ")
            show(io, arg)
        end
        print(io, "))")
    end
    nothing
end
