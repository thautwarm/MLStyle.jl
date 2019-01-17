module Pervasive
using MLStyle.MatchCore
using MLStyle.Err
using MLStyle.toolz: ($), ast_and, ast_or, isCase, yieldAst, mapAst, runAstMapper
using MLStyle.Render: render, @format
export Many, PushTo, Push, Do, Seq

export defPattern
function defPattern(mod; predicate, rewrite, qualifiers=nothing)
    qualifiers = qualifiers === nothing ? Set([invasive]) : qualifiers
    desc = pattern_descriptor(predicate, rewrite, qualifiers)
    registerPattern(desc, mod)
end

export defAppPattern
function defAppPattern(mod; predicate, rewrite, qualifiers=nothing)
    qualifiers = qualifiers === nothing ? Set([invasive]) : qualifiers
    desc = pattern_descriptor(predicate, rewrite, qualifiers)
    registerAppPattern(desc, mod)
end


def_pervasive = settings -> defPattern(Pervasive, predicate=settings[:predicate], rewrite=settings[:rewrite], qualifiers=nothing)
def_pervasive_app = settings -> defAppPattern(Pervasive, predicate=settings[:predicate], rewrite=settings[:rewrite], qualifiers=nothing)


# For app patterns
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
        :predicate => x -> x isa Expr && x.head == :if,
        :rewrite   => (tag, case, mod) -> begin
        # TODO: perform syntax validation here.
        case.args[1]
        end
)

def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head == :function,
        :rewrite   => (tag, case, mod) ->
        if length(case.args) === 1 # begin if
          fn = case.args[1]
          @format [tag, fn] quote
            fn(tag)
          end
        else
        @format [tag, case] quote
          case(tag)
        end
        end # end if
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
       tag isa Expr &&             begin
       lst = [tag.head, tag.args...]
       perf_match                    end
    end
    end
)

struct _ManyDescriptor end
struct _PushDescriptor end
struct _PushToDescriptor end
struct _SeqDescriptor end
struct _DoDescriptor end
struct _WhenDescriptor end

Many   = _ManyDescriptor()
Push   = _PushDescriptor()
PushTo = _PushToDescriptor()
Seq    = _SeqDescriptor()
Do     = _DoDescriptor()

def_pervasive_app $ Dict(
    :predicate => (hd_obj, args) -> hd_obj === Many,
    :rewrite   => (tag, hd_obj, args, mod) -> begin
    @assert length(args) == 1
    arg = args[1]
    iter_var = mangle(mod)
    test_var = mangle(mod)
    pat = mkPattern(iter_var, arg, mod)
    @format [iter_var, tag, test_var, pat] quote
       # TODO: any iterable checking method?
       test_var = true
       for iter_var in tag
          if !(pat)
             test_var = false
             break
          end
       end
       test_var
    end
    end
)


function allow_assignment(expr :: Expr)
    head = expr.head == :kw ? :(=) : expr.head
    Expr(head, expr.args...)
end

function allow_assignment(expr)
    expr
end

def_pervasive_app $ Dict(
    :predicate => (hd_obj, args) -> hd_obj === Do,
    :rewrite   => (_, _, args, _) -> begin
    Expr(:block, map(allow_assignment, args)..., true)
    end
)

def_pervasive_app $ Dict(
    :predicate => (hd_obj, args) -> hd_obj === Seq,
    :rewrite   => (tag, hd_obj, args, mod) -> begin
    iter_var = mangle(mod)
    idx_var  = mangle(mod)
    n        = mangle(mod)
    label    = mangle(mod)
    ln       = LineNumberNode(1)
    blocks = []
    has_predicate = false
    for arg in args
       if arg isa Expr && arg.head == :if
         has_predicate = true
         arg = arg.args[1]
         block = @format [arg, label, ln] quote
           if !arg
             @goto ln label
           end
         end
       else
         pat = mkPattern(iter_var, arg, mod)
         block = @format [n, idx_var, iter_var, tag, pat] quote
           while idx_var <= n
              iter_var = tag[idx_var]
              if !pat
                break
              end
              idx_var = idx_var + 1
           end
         end
       end
       push!(blocks, block)
    end
    init = @format [length, tag, n, idx_var] quote
       idx_var = 1
       n       = length(tag)
    end
    final = @format [n, idx_var] quote
       n + 1  == idx_var
    end
    if has_predicate
       # TODO: get filename of current module
    push!(blocks, @format [ln, label] quote @label ln label end)
    end
    Expr(:block, init, blocks..., final)
    end
)


def_pervasive_app $ Dict(
    :predicate => (hd_obj, args) -> hd_obj === Push,
    :rewrite   => (tag, hd_obj, args, mod) -> begin
    @assert length(args) == 2
    name  = args[1]
    value = args[2]
    @format [value, name] quote
         begin
            push!(name, value)
            true
         end
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

def_pervasive_app $ Dict(
    :predicate => (hd_obj, args) -> hd_obj === PushTo,
    :rewrite   => (tag, hd_obj, args, mod) -> begin
    @assert length(args) == 1
    name = args[1]
    @format [name] quote
         name = []
         true
    end
    end
)

def_pervasive_app $ Dict(
       :predicate => (hd_obj, args) -> hd_obj === Dict,
       :rewrite   => (tag, hd_obj, args, mod) -> begin
        map(args) do kv # begin do
            if !(isa(kv, Expr) && kv.head === :call && (@eval mod $(kv.args[1])) === Pair)
                SyntaxError("Dictionary destruct must take patterns like Dict(<expr> => <pattern>, ...)") |> throw
            end
            let (k, v) = kv.args[2:end] # begin let
                ident = mangle(mod)
                pat = mkPattern(ident, v, mod)
                @format [pat, ident, tag, k, get, failed] quote
                    ident = get(tag, k) do
                        failed
                    end
                    if ident !== failed
                        pat
                    else
                        false
                    end
                end
            end # end let
        end |> # end do
        function (seq)
            reduce(ast_and, seq, init = :($tag isa $Dict))
        end
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
