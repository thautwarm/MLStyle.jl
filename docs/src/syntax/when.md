When Destructuring
===========================

The `@when` is introduced to work with the scenarios where `@match` is a bit heavy.

It's similar to [if-let](https://doc.rust-lang.org/rust-by-example/flow_control/if_let.html) construct in Rust language.


There're two distinct syntaxes for `@when`.

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

In above snippet, `@inline fn(x) = 100x` is not regarded as destructuring.


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