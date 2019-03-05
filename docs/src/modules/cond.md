MLStyle.Modules.Cond
========================

- `@cond`: Lisp-flavored conditional branches

```julia
using MLStyle.Modules.Cond

x = 2
@cond begin
    x < 0 => :lessthan0
    x == 0 => :equal0
    _ => :greaterthan0
end # => :greaterthan0
```