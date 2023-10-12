When Destructuring
===========================

The `@when` macro was introduced to work with the scenarios where `@match` leads to heavy syntax.

It's similar to [if-let](https://doc.rust-lang.org/rust-by-example/flow_control/if_let.html) construct in Rust language.


There are three distinct syntaxes for `@when`.

Allow Destructuring in Let-Binding
-----------------------------------------------------------------

```julia
tp = (2, 3)
x = 2

@assert 5 ===
    @when let (2, a) = tp,
                  b  = x
        a + b
    end

@assert nothing ===
    @when let (2, a) = 1,
                   b = x
        a + b
    end
```

Note that only the binding formed as `$a = $b` would be treated as destructuring.

```julia
@data S begin
    S1(Int)
    S2(Int)
end

s = S1(5)

@assert 500 ===
    @when let S1(x) = s,
              @inline fn(x) = 100x
        fn(x)
    end
```

In the above snippet, `@inline fn(x) = 100x` is not regarded as destructuring.


Sole Destructuring
----------------------------

However, a let-binding could be also heavy when you just want to solely destructure something.

Finally, we allowed another syntax for `@when`.

```julia
s = S1(5)
@assert 5 === @when S1(x) = s x
@assert 10 === @when S1(x) = s begin
    2x
end
@assert nothing === @when S1(x) = S2(10) x
```

Multiple Branches
----------------------------------

Sometimes we might have this kind of logic:

- If `a` matches pattern `A`, then do `Aa`
- else if `b` matches pattern `B`, then do `Bb`
- otherwise do `Cc`


As there is currently no pattern matching support for `if-else`, we cannot represent above logic literally in vallina Julia.

MLStyle provides this, with the following syntax:

```julia
@when let A = a
    Aa
@when B = b
    Bb
@otherwise
    Cc
end
```

Also, predicates can be used here, thus it can be seen as superior to
`if-else`:

```julia
@when let A = a,
          condA.? # or if condA end
    Aa
@when begin B = b
            condB.? # or `if condB end`
      end
    Bb
@otherwise
    Cc
end
```

A concrete example is presented below:

```julia
a = 1
b = 2
@when let (t1, t2) = a, (t1 > 1).?
    t2
@when begin a::Int = b; (b < 10).? end
    0
end # => 0
```
