Pattern function
=========================

`Pattern function` is a convenient way to define a function with multiple entries.

```julia
@def f begin
    # patterns here
    x                  => 1
    (x, (1, 2)){x > 3} => 5
    (x, y)             => 2
    ::String           => "is string"
    _                  => "is any"
end
f(1) # => 1
f(4, (1, 2)) # => 5
f(1, (1, 2)) # => 2
f("") # => "is string"
```

Take care that until now performance of pattern functions could be not that efficient.

The use case of pattern functions is somewhere
- without a signaficant requirerment of execution efficiency.
- filled with tedious business logics.

There is promise that we will make outstanding optimizations on pattern functions in the future, where we bootstrap a new MLStyle with the current version. Reservedly, the user interfaces of MLStyle builtin patterns and pattern functions will not change at all, **the only one without complete backward compatibility is the way to extending custom patterns**, that is to say, if you don't use `PatternDef.Meta` or `PatternDef.App`, your codes will works well no matter which version of Julia/MLStyle you're getting along with.

