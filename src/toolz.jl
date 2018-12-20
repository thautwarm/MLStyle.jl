module toolz
include("internal_list.jl")
using .List: list, head, tail, cons, nil, reverse, linkedlist

export ($), State, runState, bind, get, put, putBy, getBy,
       return!, combine, forMM, forM, flip, fst, snd,
       isCapitalized, ast_and, ast_or, mapAst, yieldAst, runAstMapper,
       isCase

($)(f, a) = f(a)
flip(f) = a -> b -> f $ b $ a
fst((a, b)) = a
snd((a, b)) = b

# Poor man's state monad

struct State
    # s -> (a, s)
    run :: Function
end

function runState(s :: State)
    s.run
end

bind(k :: Function, m :: State) =
    State $ s -> begin
        m = runState(m)(s)
       (a, s!) = m
       runState $ k(a) $ s!
    end

get        = State        $ s -> (s, s)
put        = s! -> State  $ _ -> (nothing, s!)
putBy(f)   = State        $ s -> (nothing, f(s))
getBy(f)   = State        $ s -> (f $ s,   s)
return!(a) = State        $ s -> (a, s)
combine(ma, mb) = bind( _ -> mb, ma)


forMM(k, ms) =
   State $ s ->
   begin
        v = nil(State)
        for m in ms
          (a, s) = runState(bind(k, m))(s)
          v = cons(a, v)
        end
        (reverse(v), s)
   end

forM(k, xs) =
    State $ s ->
    begin
          v = nil()
          for x in xs
             (a, s) = runState(k(x))(s)
             v = cons(a, v)
          end
         (reverse(v), s)
    end



# AST manipulation

export get_most_union_all, ast_and, ast_or

function get_most_union_all(expr, mod :: Module)
    if isa(expr, Expr) && expr.head == :curly
        get_most_union_all(expr.args[1], mod)
    else
        @eval mod $expr
    end
end

ast_and(a, b) =  Expr(:&&, a, b)
ast_or(a, b) = Expr(:||, a, b)
isCapitalized(s :: AbstractString) :: Bool = !isempty(s) && isuppercase(s[1])
isCase(sym  :: Symbol) = isCapitalized ∘ string ∘ sym
isCase(expr :: Expr)   = expr.head === :(curly) && isCase(expr.args[1])
yieldAst(a :: Any) = putBy $ s -> cons(a, s)

function mapAst(hd_f, tl_f, s :: Expr) :: State
    State $ lst -> begin
    head, lst = runState $ hd_f(s.head) $ lst
    _, lst = runState $ mapreduce(tl_f, combine, s.args, init=return! $ nothing) $ lst
    lst = collect ∘ reverse $ lst
    expr :: Any = Expr(head, lst...)
    nothing, list(expr)
    end
end

function mapAst(hd_f, tl_f, s) :: State
    f(s)
end

function runAstMapper(s :: State)
   ast = runState $ s $ nil() |> snd
   if isempty $ ast
       throw()
   elseif length $ ast === 1
       ast.head
   else
      ast = collect ∘ reverse $ ast
      Expr(ast...)
  end
end

macro fn0(expr)
    esc $ quote
        () -> $expr
    end
end

macro fn1(expr)
    esc $ quote
        _1 -> $expr
    end
end

macro fn2(expr)
    esc $ quote
        (_1, _2)-> $expr
    end
end

end
