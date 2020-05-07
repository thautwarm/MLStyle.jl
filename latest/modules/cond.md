
<a id='MLStyle.Modules.Cond-1'></a>

# MLStyle.Modules.Cond


<a id='@cond-1'></a>

## @cond


  * Description : Lisp-flavored conditional branches
  * Usage: `@cond begin cond1 => br1, [cond2 => br2, ...] end`


```julia
using MLStyle.Modules.Cond

x = 2
@cond begin
    x < 0 => :lessthan0
    x == 0 => :equal0
    _ => :greaterthan0
end # => :greaterthan0
```

