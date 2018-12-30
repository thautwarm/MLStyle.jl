

MLStyle.jl
=========================

[![Build Status](https://travis-ci.org/thautwarm/MLStyle.jl.svg?branch=master)](https://travis-ci.org/thautwarm/MLStyle.jl)
[![codecov](https://codecov.io/gh/thautwarm/MLStyle.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thautwarm/MLStyle.jl)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/LICENSE)
<!-- [![Docs](https://img.shields.io/badge/docs-latest-orange.svg)](https://thautwarm.github.io/MLStyle.jl/latest/) -->


P.S **This branch is ready to be released very sooner. And there're 3 main changes presented in following sections.**

## Qualified Pattern Matching

`MLStyle` now is implemented with a much more elegant abstraction,
and since then programmers don't have to burden with the scoping of matching patterns:

Along with the definition of a pattern, a qualifier is defined too to descibe which module could use this pattern.
The qualifier `predicate` takes 2 arguments, one of them is the module where the pattern is defined, and another is the caller module.

Only the patterns defined in `src/Pervasive.jl` are exposed to all modules.


## Ast Pattern

If you have tried `MacroTools.jl`, you might feel that although it's quite powerful,
the way to perform capturing in that library is not so powerful and elegant. Now there is a
built-in pattern named *Ast Pattern* in MLStyle.jl, which could be used to match asts in a both
efficient and elegant way. **Arbitrary patterns could be used when matching asts**:


```julia
ast = quote
    function f(a, b, c, d)
      let d = a + b + c, e = x -> 2x + d
          e(d)
      end
    end
end

@match ast begin
    quote
        $(::LineNumberNode)

        function $funcname(
            $firstarg, 
            $(args...), 
            $(a where islowercase(string(a)[1])))
        
            $(::LineNumberNode)
        
            let $bind_name = a + b + $last_operand, $(other_bindings...)
                $(::LineNumberNode)
                $app_fn($app_arg)
                $(block1...)
            end
        
            $(block2...)
        end
    end where (isempty(block1) && isempty(block2)) =>

         Dict(:funcname => funcname,
              :firstarg => firstarg,
              :args     => args,
              :last_operand => last_operand,
              :other_bindings => other_bindings,
              :app_fn         => app_fn,
              :app_arg        => app_arg)
end

```

Output:

```julia
Dict{Symbol,Any} with 7 entries:
  :app_fn         => :e
  :args           => Symbol[:b, :c]
  :firstarg       => :a
  :funcname       => :f
  :other_bindings => Any[:(e = (x->begin…
  :last_operand   => :c
  :app_arg        => :d

```

The **Ast Pattern** of MLStyle.jl is not only elegant, but also very efficient for
it's purely statically code generation.

Here's an example from MacroTools.jl, and MLStyle.jl achieves the same functionalities with a less than **1/3** time cost, check `benchmark.jl`.


## API changes

Comparing with master branch, there are quite a few differences.

1. Fallthrough cases now use `||` instead of `|`:

```julia
@match 1 begin
    # match interval [1,10] or [100, 200]
    1:10 || 100:200 => :ok
    _               => :fail
end # => :ok
```

2. Uppercase names are now preserved and cannot be used as capture patterns.

```julia
@match 1 begin
       a => a # ok
end

@match 1 begin
       A => A # wrong!
end

```

The reason why is that, in ML Languages/Haskell,
there is a convention that enum patterns are represented with uppercase names.

3. ADTs are tentatively removed. We need more time to design a better(syntatically and functionally) ADT implementation.

4. The way to define a custom pattern is changed a little, comparing with master branch's implementation, a extra factor has to be
taken into consideration, it's the **qualifier**. Check `src/Pervasive.jl` to get more info about custom patterns.

P.S: We strongly recommend not to define a pattern with `invasive` qualifier.
