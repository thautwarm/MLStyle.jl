@use GADT

import Base: convert

struct Fun{T, R}
    fn :: Function
end

function (typed_fn :: Fun{T, R})(arg :: T) :: R where {T, R}
    typed_fn.fn(arg)
end

function convert(::Type{Fun{T, R}}, fn :: Function) where {T, R}
    Fun{T, R}(fn)
end

function convert(::Type{Fun{T, R}}, fn :: Fun{C, D}) where{T, R, C <: T, D <: R}
    Fun{T, R}(fn.fn)
end

⇒(::Type{A}, ::Type{B}) where {A, B} = Fun{A, B}

@data public Exp{T} begin
    Sym :: Symbol => Exp{A} where {A}
    Val{A} :: A => Exp{A}
    App{A, B} :: (Exp{Fun{A, B}}, Exp{A_}) => Exp{B} where {A_ <: A}
    Lam{A, B} :: (Symbol, Exp{B}) => Exp{Fun{A, B}}
    If{A} :: (Exp{Bool}, Exp{A}, Exp{A}) => Exp{A}
end

function substitute(template :: Exp{T}, pair :: Tuple{Symbol, Exp{G}}) where {T, G}
    (sym, exp) = pair
    @match template begin
        Sym(&sym) => exp
        Val(_) => template
        App(f, a) => App(substitute(f, pair), substitute(a, pair)) :: Exp{T}
        Lam(&sym, exp) => template
        If(cond, exp1, exp2) =>
            let (cond, exp1, exp2) = map(substitute, (cond, exp1, exp2))
                If(cond, exp1, exp2) :: Exp{T}
            end
    end
end

function eval_exp(exp :: Exp{T}, ctx :: Dict{Symbol, Any}) where T
    @match exp begin
        Sym(a) => (ctx[a] :: T, ctx)
        Val(a :: T) => (a, ctx)
        App{A, T, A_}(f :: Exp{Fun{A, T}}, arg :: Exp{A_}) where {A, A_ <: A} =>
            let (f, ctx) = eval_exp(f, ctx),
                (arg, ctx) = eval_exp(arg, ctx)
                (f(arg), ctx)
            end
        Lam{A, B}(sym, exp::Exp{B}) where {A, B} =>
            let f(x :: A) = begin
                    A
                    eval_exp(substitute(exp, sym => Val(x)), ctx)[1]
                end

                (f, ctx)
            end
        If(cond, exp1, exp2) =>
            let (cond, ctx) = eval_exp(cond, ctx)
                eval_exp(cond ? exp1 : exp2, ctx)
            end
    end
end

add = Val{Number ⇒ Number ⇒ Number}(x -> y -> x + y)
sub = Val{Number ⇒ Number ⇒ Number}(x -> y -> x - y)
gt = Val{Number ⇒ Number ⇒ Bool}(x -> y -> x > y)
ctx = Dict{Symbol, Any}()

@assert 3 == eval_exp(App(App(add, Val(1)), Val(2)), ctx)[1]
@assert -1 == eval_exp(App(App(sub, Val(1)), Val(2)), ctx)[1]
@assert 1 == eval_exp(
    If(
        App(App(gt, Sym{Int}(:x)), Sym{Int}(:y)),
        App(App(sub, Sym{Int}(:x)), Sym{Int}(:y)),
        App(App(sub, Sym{Int}(:y)), Sym{Int}(:x))
    ), Dict{Symbol, Any}(:x => 1, :y => 2))[1]
