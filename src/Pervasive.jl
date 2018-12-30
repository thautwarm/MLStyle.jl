module Pervasive
using MLStyle.MatchCore
using MLStyle.toolz: ($), ast_and, ast_or, isCase, yieldAst, mapAst, runAstMapper
using MLStyle.Render: render, @format

function def_pervasive(settings)
    predicate  = settings[:predicate]
    rewrite    = settings[:rewrite]
    qualifiers = get(settings, :qualifiers) do
        Set([invasive])
    end
    desc = pattern_descriptor(predicate, rewrite, qualifiers)
    registerPattern(desc, Pervasive)
end

destructors = Vector{Tuple{Module, pattern_descriptor}}()


function mkAppPattern(tag, hd, tl, use_mod)
    hd = use_mod.eval(hd)
    for (def_mod, desc) in destructors
        if qualifierTest(desc.qualifiers, use_mod, def_mod) && desc.predicate(hd, tl)
            return desc.rewrite(tag, hd, tl, use_mod)
        end
    end
    info = string(hd) * string(tl)
    throw $ PatternUnsolvedException("invalid usage or unknown application case $info.")
end


function def_pervasive_app(settings)
    predicate  = settings[:predicate]
    rewrite    = settings[:rewrite]
    qualifiers = get(settings, :qualifiers) do
        Set([invasive])
    end
    desc = pattern_descriptor(predicate, rewrite, qualifiers)
    registerAppPattern(desc, Pervasive)
end

export registerAppPattern
function registerAppPattern(pdesc :: pattern_descriptor, def_mod::Module)
    push!(destructors, (def_mod, pdesc))
end


def_pervasive $ Dict(
        :predicate => x -> x isa Int,
        :rewrite   => (tag, case, mod) ->
         @format [tag, case] quote
            tag === case
         end
)


# TODO: figure out the list of the mutabilities of `Number`'s subtypes and
#       use `===` instead of `==` for immutable types.
def_pervasive $ Dict(
        :predicate => x -> x isa Number,
        :rewrite   => (tag, case, mod) ->
         @format [tag, case] quote
            tag == case
         end
)

def_pervasive $ Dict(
        :predicate => x -> x isa String,
        :rewrite   => (tag, case, mod) ->
        @format [tag, case] quote
           tag == case
        end
)


def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head == :(||),
        :rewrite   => (tag, case, mod) -> begin
                fn = x -> mkPattern(tag, x, mod)
                mapreduce(fn, ast_or, case.args)
              end)

def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head == :(&&),
        :rewrite   => (tag, case, mod) -> begin
                fn = x -> mkPattern(tag, x, mod)
                mapreduce(fn, ast_and, case.args)
              end)

def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head == :(::),
        :rewrite   => (tag, case, mod) -> begin
                args = case.args
                if length(args) == 1
                   t = args[1]
                   @format [t, tag, isa] quote
                       tag isa t
                   end
                # :: T => ...
                else
                   pat, t = args
                   pat = mkPattern(tag, pat, mod)
                   @format [t, tag, isa, pat] quote
                       tag isa t && pat
                   end
                # a :: T =>
                end
              end)

def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head == :(&),
        :rewrite   => (tag, case, mod) -> begin
                @assert length(case.args) == 1 "invalid ref of existed var"
                var = case.args[1]
                @format [tag] quote
                   tag == $var
                end
              end)

def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head == :(where),
        :rewrite   => (tag, case, mod) -> begin
                @assert length(case.args) === 2 "invalid where syntax"
                pat, guard = case.args
                ast_and(mkPattern(tag, pat, mod), guard)
              end)

# snake case for internal use.
is_captured(s)::Bool = !isempty(s) && islowercase(s[1])

def_pervasive $ Dict(
        :predicate => x -> x isa Symbol && x == :(_),
        :rewrite   => (tag, case, mod) -> true)

def_pervasive $ Dict(
        :predicate => x -> x isa Symbol && is_captured ∘ string $ x,
        :rewrite   => (tag, case, mod) ->
        @format [case, tag] quote
            case = tag
            true
        end
)

function mk_expr_template(expr :: Expr)
    if expr.head == :($)
        return expr.args[1]
    end
    rec = mk_expr_template
    Expr(:call, :Expr, rec(expr.head), filter(x -> x !== nothing, map(rec, expr.args))...)
end

function mk_expr_template(expr :: Symbol)
    QuoteNode(expr)
end

function mk_expr_template(expr :: LineNumberNode)
    nothing
end

function mk_expr_template(expr)
    expr
end


# Not decided of capitalized symbol's use case, for generic enum is impossible in Julia.
def_pervasive $ Dict(
        :predicate => isCase,
        :rewrite   => (tag, case, mod) ->
        @format [case, tag] quote
            tag isa case
        end
)

def_pervasive $ Dict(
        :predicate => x -> x isa QuoteNode,
        :rewrite   => (tag, case, mod) ->
        @format [case, tag] quote
            tag == case
        end
)

def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head === :tuple,
        :rewrite   => (tag, case, mod) -> begin
        args = case.args
        isempty(args) ? :(() === $tag) : begin
        asts = [
            begin
               ident = mangle(mod)
               pat = mkPattern(ident, arg, mod)
               @format [i, ident, pat, tag] quote
                  ident = tag[i]
                  pat
               end
            end
            for (i, arg) in enumerate(args)
        ]
        reduce(ast_and, asts)
        end
        end
)

def_pervasive $ Dict(
    :predicate => x -> x isa Expr && x.head == :vect,
    :rewrite   => (tag, case, mod) -> begin
    args = case.args
    isempty(args) ? :($isempty($tag)) : orderedSeqMatch(tag, case.args, mod)
    end
)

def_pervasive_app $ Dict(
    :predicate => (hd_obj, args) -> hd_obj === (:),
    :rewrite   => (tag, hd_obj, args, mod) -> begin
        pat = Expr(:call, hd_obj, args...)
        @format [pat, tag] quote
            tag in pat
        end
    end
)

# All AppPatterns are mastered by following general pattern:
def_pervasive $ Dict(
    :predicate => x -> x isa Expr && x.head == :call,
    :rewrite   => (tag, case, mod) ->
    let hd = case.args[1], tl = case.args[2:end]
    # @info :ExprCall
    # dump(case)
    mkAppPattern(tag, hd, tl, mod)
    end
)

# Expr template !!!
def_pervasive_app $ Dict(
    :predicate => (hd_obj, args) -> hd_obj === Expr && !isempty(args),
    :rewrite   => (tag, hd_obj, args, mod) -> begin
    lst        = mangle(mod)
    perf_match = orderedSeqMatch(lst, args, mod)
    @format [lst, tag, perf_match]   quote
       tag isa   Expr &&             begin
       lst = [tag.head, tag.args...]
       perf_match                    end
    end
    end
)

def_pervasive $ Dict(
       :predicate => x -> x isa Expr && x.head == :quote,
       :rewrite   => (tag, case, mod) -> begin
        expr = case.args[1]
        expr = mk_expr_template(expr)
        # @info :QuoteTemplate
        # dump(expr)
        mkPattern(tag, expr, mod)
       end
)


# arbitray ordered sequential patterns match
function orderedSeqMatch(tag, args, mod)
    length(args) == 0 ? (
        @format [seq_tag] quote
            isempty(seq_tag)
        end)          : begin
    atleast_element_count = 0
    unpack_begin          = nothing
    unpack_end            = 0
    unpack                = []
    foreach(args) do arg                          # start foreach
        if arg isa Expr && arg.head === :...  # start if
            if unpack_begin === nothing
                unpack_begin = atleast_element_count + 1
            else
                throw $
                SyntaxError("Vector unpack can only perform sequential unpack at most once.")
            end
            push!(unpack, arg.args[1])
        else
	    atleast_element_count = atleast_element_count + 1
            ident = mangle(mod)
            perf_match = mkPattern(ident, arg, mod)
            if unpack_begin !== nothing

                pat = @format [arg, ident, perf_match] quote
                    ident = $tag[end-$unpack_end]
                    perf_match
                end
                push!(unpack, pat)
                unpack_end = unpack_end + 1
            else

                pat = @format [arg, ident, perf_match] quote
                    ident = $tag[$atleast_element_count]
                    perf_match
                end
                push!(unpack, pat)
            end

        end # end if
    end     # end foreach
    if unpack_begin !== nothing # check begin
        ident = mangle(mod)
        check_len = @format [tag] quote
            $length($tag) >= $atleast_element_count
        end
        arg = unpack[unpack_begin] # must be a Symbol
        unpack[unpack_begin] = mkPattern(ident, arg, mod)
        perf_match = reduce(ast_and, unpack, init = check_len)
        @format [arg, ident, perf_match] quote
            ident = $view($tag, $unpack_begin:($length($tag) - $unpack_end))
            perf_match
        end
    else
        check_len = @format [tag] quote
            $length($tag) == $atleast_element_count
        end
        reduce(ast_and, unpack, init=check_len)
    end # end check begin
    end
end

end
