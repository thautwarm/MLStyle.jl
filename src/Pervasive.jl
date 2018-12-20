module Pervasive
using MLStyle.MatchCore
using MLStyle.toolz: ($), ast_and, ast_or, isCase
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

# Not decided of capitalized symbol's use case, for generic enum is impossible in Julia.
def_pervasive $ Dict(
        :predicate => isCase,
        :rewrite   => (tag, case, mod) ->
        @format [case, tag] quote
            tag isa case
        end
)

destructors = Dict{Any, Any}()
end
