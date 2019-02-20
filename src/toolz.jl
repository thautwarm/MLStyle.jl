module toolz
include("internal_list.jl")
using .List: list, head, tail, cons, nil, reverse, linkedlist

export ($), State, runState, bind, get, put, putBy, getBy,
       return!, combine, forM, isCapitalized, isCase

($)(f, a) = f(a)

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
isCapitalized(s :: AbstractString) :: Bool = !isempty(s) && isuppercase(s[1])

isCase(sym  :: Symbol) = isCapitalized ∘ string $ sym
isCase(expr :: Expr)   = expr.head === :(curly) && isCase(expr.args[1])
isCase(_) = false

end
