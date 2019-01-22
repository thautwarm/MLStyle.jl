# MLStyle.jl

*ML language pattern provider for Julia*

Check out documents here:

- [ADT](https://thautwarm.github.io/MLStyle.jl/latest/syntax/adt/)
- [Patterns for matching](https://thautwarm.github.io/MLStyle.jl/latest/syntax/pattern/)
- [Pattern function](https://thautwarm.github.io/MLStyle.jl/latest/syntax/pattern-function/)

Or you want some [examples](https://github.com/thautwarm/MLStyle.jl/tree/master/test).

## Install

```julia
pkg> add MLStyle
```

## Why ADT and pattern matching

- Clarity

Let's start from a simple case.

```Julia
function switch_task(status :: Int)
    @match status begin
        1 => "finish your homework:)"
        2 => "reading"
        3 => "put down your mobilephone and get outside for a one-hour exercise."
        4 => "go to some website and watch some live."
        _ => "sleep"
    end
end
```

For there is no `switch-case` in Julia syntax, sometimes there might be enormous
single cases to hard-code, `if-else-end` does hurt for its verbosity.

Another example is getting specific data from different schemas.
Assume that you have many deserialized JSON data, and they're in 3 schemas. Each of them represents
some information of a person.

```Julia
struct D1
  name : String
  age  : Int
  sex  : Int
end

struct D2
  nickname : String
  lifetime : Int
  gender   : Int
end

struct D3
  sex   : Int
  lifetime : Int
end
data :: Vector{Union{D1, D2, D3}}
```

Now your boss told you to extract `age` and `gender` from those people.
How would you do?

Yes it's so easy:

```julia
extracted = map data do record
  if isa(record, D1)
    (data.age, data.sex)
  else if isa(data, D2)
    (data.lifetime, data.gender)
  else
    (data.lifetime, data.sex)
  end
end
```

However, in real word, data from different places could have so many schemas and you code
will just swell both your editor and time. Think that your friends told you in the morning to
take part in their party when knock off, but you have a series of these stupid tasks to finish...

Let's try something else that might make you more pleasant.

```julia
extracted = map data do record
  @match record
    D1(_, age, gender) ||
    D2(_, age, gender) ||
    D3(gender, age) => (age, gender)
    _               => @error "unknown schema"
  end
end
```

What do you think about this? I admit that writing codes like the above may not
guarantee your attending to the party, but something is different, I think.

To be continue.
