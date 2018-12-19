using MacroTools: prewalk
using DataStructures: list, head, tail, cons, nil, reverse, LinkedList, cat


($)(f, a) = f(a)

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
combine(ma, mb) = bind(ma, _ -> mb)


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

struct err_spec
    location :: LineNumberNode
    msg      :: String
end

struct config
    loc       :: LineNumberNode
    errs      :: LinkedList{err_spec}
end

# lens
loc(conf      :: config)               = conf.loc
errs(conf     :: config)               = conf.errs
set_loc(loc   :: LineNumberNode)       = (conf) -> config(loc, conf.errs)
set_errs(errs :: LinkedList{err_spec}) = (conf) -> config(conf.loc, errs)


# some useful utils:

err!(msg :: String) =
    bind(getBy $ loc)  do loc
    bind(getBy $ errs) do errs
    lens = set_errs $ cons(err_spec(loc, msg), errs)
    putBy(lens)
    end
    end


checkDo(f, check_fn, err_fn) = expr ->
     if !check_fn(expr)
         err_fn(expr)
     else
         f(expr)
     end


# TODO: for friendly error report
recogErr(expr) :: String = "syntax error"

checkSyntax(f, predicate) = begin
    check_fn = expr -> predicate(expr)
    err_fn   = expr -> bind(err! ∘ recogErr $ expr) do _
        return! $ nothing
    end
    checkDo(f, check_fn, err_fn)
end

const init_state = config(LineNumberNode(1), nil(err_spec))

