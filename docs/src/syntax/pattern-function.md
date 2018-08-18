Pattern function
=========================

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
