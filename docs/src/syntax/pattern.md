Pattern
=======================

Patterns provide convenient ways to manipulate data,

Literal pattern
------------------------

```julia

@match 10 {
    1  => "wrong!"
    2  => "wrong!"
    10 => "right!"
}
# => "right"
```
Default supported literal patterns are `Number`and `AbstractString`.


Capture pattern
--------------

```julia

@match 1 begin
    x => x + 1
end
# => 2
```

Type pattern
-----------------

```julia

@match 1 begin
    ::Int => "done"
    _     => "fault"
end
# => "done"
```

However, when you use `TypeLevel Feature`, the behavious could change slightly. See [TypeLevel Feature](#type-pattern).


(To be continue...