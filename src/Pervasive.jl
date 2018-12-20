module Pervasive
using MLStyle.MatchCore
using MLStyle.toolz: ($), ast_and, ast_or, isCase

function def_pervasive(settings)
    predicate  = settings[:predicate]
    rewrite    = settings[:rewrite]
    qualifiers = get(settings, :qualifiers) do
        Set([invasive])
    end
    desc = pattern_descriptor(predicate, rewrite, qualifiers)
    registerPattern(desc, Pervasive)
end

def_pervasive $ Dict(
        :predicate => x -> x isa Int,
        :rewrite   => (tag, case, mod) -> quote $tag === $case end)


# TODO: figure out the list of the mutabilities of `Number`'s subtypes and
#       use `===` instead of `==` for immutable types.
def_pervasive $ Dict(
        :predicate => x -> x isa Number,
        :rewrite   => (tag, case, mod) -> quote $tag == $case end)

def_pervasive $ Dict(
        :predicate => x -> x isa String,
        :rewrite   => (tag, case, mod) -> quote $tag == $case end)


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
                mapreduce(fn, ast_or, case.args)
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
        :rewrite   => (tag, case, mod) ->
            quote
                true
            end)

def_pervasive $ Dict(
        :predicate => x -> x isa Symbol && is_captured ∘ string $ x,
        :rewrite   => (tag, case, mod) ->
            quote
                $case = $tag
                true
            end)


def_pervasive $ Dict(
        :predicate => x -> isCase(x),
        :rewrite   => (tag, case, mod) ->
            quote
               $tag isa $case
            end)

destructors = Dict{Any, Any}()


end
