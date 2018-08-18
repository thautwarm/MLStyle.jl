var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#MLStyle.jl-1",
    "page": "Home",
    "title": "MLStyle.jl",
    "category": "section",
    "text": "ML language pattern provider for JuliaCheck out documents here:ADT\nPatterns for matching\nPattern functionOr you want some examples."
},

{
    "location": "#Install-1",
    "page": "Home",
    "title": "Install",
    "category": "section",
    "text": "pkg> add MLStyle"
},

{
    "location": "syntax/adt/#",
    "page": "Algebraic Data Types",
    "title": "Algebraic Data Types",
    "category": "page",
    "text": ""
},

{
    "location": "syntax/adt/#Algebraic-Data-Types-1",
    "page": "Algebraic Data Types",
    "title": "Algebraic Data Types",
    "category": "section",
    "text": "What\'s the so-called ADT?An efficient way to represent data.\nAn elegant way to composite data.\nAn effective way to manipulate data.\nAn easy way to analyse data."
},

{
    "location": "syntax/adt/#Example:-Describe-arithmetic-operations-1",
    "page": "Algebraic Data Types",
    "title": "Example: Describe arithmetic operations",
    "category": "section",
    "text": "using MLStyle\n@data Arith begin \n    Number(v :: Int)\n    Minus(fst :: Arith, snd :: Arith)\n    Mult(fst :: Arith, snd :: Arith)\n    Divide(fst :: Arith, snd :: Arith)\nendAbove codes makes a clarified description about Arithmetic and provides a corresponding implementation.If you want to transpile above ADTs to some specific language, there is a clear step: \neval_arith(arith :: Arith) = \n    let wrap_op(op)  = (a, b) -> op(eval_arith(a), eval_arith(b)),\n        (+, -, *, /) = map(wrap_op, (+, -, *, /))\n        @match arith begin\n            Number(v)       => v\n            Minus(fst, snd) => fst - snd\n            Mult(fst, snd)   => fst * snd\n            Divide(fst, snd) => fst / snd\n        end\n    end\n\neval_arith(\n    Minus(\n        Number(2), \n        Divide(Number(20), \n               Mult(Number(2), \n                    Number(5)))))\n# => 0"
},

{
    "location": "syntax/adt/#Case-Class-1",
    "page": "Algebraic Data Types",
    "title": "Case Class",
    "category": "section",
    "text": "Just like the similar one in Scalaabstract type A end\n@case C{T}(a :: Int, b)\n@case D(a, b)\n@case E <: AIn terms of data structure definition, following codes could be expanded toabstract type A end\nstruct C{T}\n    a :: Int\n    b\nend\n\nstruct D\n    a\n    b\nend\n\nstruct E <: A\nend\n\n<additional codes>Take care that any instance of E is a singleton thanks to Julia\'s language design pattern.However the two snippet above are not equivalent, for there are other hidden details to support pattern matching on these data structures.See pattern.md."
},

{
    "location": "syntax/pattern/#",
    "page": "Pattern",
    "title": "Pattern",
    "category": "page",
    "text": ""
},

{
    "location": "syntax/pattern/#Pattern-1",
    "page": "Pattern",
    "title": "Pattern",
    "category": "section",
    "text": "ADT destructing\nAs-Pattern\nLiteral pattern\nCapture pattern\nType pattern\nGuard\nCustom pattern & dictionary, tuple, array, linked list pattern\nRange Pattern\nReference Pattern\nFall through cases\nType level featurePatterns provide convenient ways to manipulate data,"
},

{
    "location": "syntax/pattern/#ADT-destructing-1",
    "page": "Pattern",
    "title": "ADT destructing",
    "category": "section",
    "text": "\n@case Natural(dimension :: Float32, climate :: String, altitude :: Int32)\n@case Cutural(region :: String,  kind :: String, country :: String, nature :: Natural)\n\n\n神农架 = Cutural(\"湖北\", \"林区\", \"中国\", Natural(31.744, \"北亚热带季风气候\", 3106))\nYellostone = Cutural(\"Yellowstone National Park\", \"Natural\", \"United States\", Natural(44.36, \"subarctic\", 2357))\n\nfunction my_data_query(data_lst :: Vector{Cutural})\n    filter(data_lst) do data\n        @match data begin\n            Cutural(_, \"林区\", \"中国\", Natural(dim, _, altitude)){\n                dim > 30.0, altitude > 1000\n            } => true\n\n            Cutural(_, _, \"United States\", Natural(_, _, altitude)){\n                altitude > 2000\n            } => true\n\n            _ => false\n\n        end\n    end\nend\nmy_data_query([神农架, Yellostone])\n..."
},

{
    "location": "syntax/pattern/#Literal-pattern-1",
    "page": "Pattern",
    "title": "Literal pattern",
    "category": "section",
    "text": "\n@match 10 {\n    1  => \"wrong!\"\n    2  => \"wrong!\"\n    10 => \"right!\"\n}\n# => \"right\"Default supported literal patterns are Numberand AbstractString."
},

{
    "location": "syntax/pattern/#Capture-pattern-1",
    "page": "Pattern",
    "title": "Capture pattern",
    "category": "section",
    "text": "\n@match 1 begin\n    x => x + 1\nend\n# => 2"
},

{
    "location": "syntax/pattern/#Type-pattern-1",
    "page": "Pattern",
    "title": "Type pattern",
    "category": "section",
    "text": "\n@match 1 begin\n    ::Float  => nothing\n    b :: Int => b\n    _        => nothing\nend\n# => 1However, when you use TypeLevel Feature, the behavious could change slightly. See TypeLevel Feature."
},

{
    "location": "syntax/pattern/#As-Pattern-1",
    "page": "Pattern",
    "title": "As-Pattern",
    "category": "section",
    "text": "For julia don\'t have an as  keyword and operator @(adopted by Haskell and Rust) is invalid for the conflicts against macro, we use in keyword to do such stuffs.The feature is unstable for there might be perspective usage on in keyword about making patterns.@match (1, 2) begin\n    (a, b) in c => c[1] == a && c[2] == b\nend"
},

{
    "location": "syntax/pattern/#Guard-1",
    "page": "Pattern",
    "title": "Guard",
    "category": "section",
    "text": "\n@match x begin\n    x{x > 5} => 5 - x # only succeed when x > 5\n    _        => 1\nend"
},

{
    "location": "syntax/pattern/#Range-pattern-1",
    "page": "Pattern",
    "title": "Range pattern",
    "category": "section",
    "text": "\n@match num begin\n    1..10  in x => \"$x in [1, 10]\"\n    11..20 in x => \"$x in [11, 20]\"\n    21..30 in x => \"$x in [21, 30]\"\nend"
},

{
    "location": "syntax/pattern/#Reference-pattern-1",
    "page": "Pattern",
    "title": "Reference pattern",
    "category": "section",
    "text": "This feature is from Elixir which could slightly extends ML pattern matching.c = ...\n@match (x, y) begin\n    (&c, _)  => \"x equals to c!\"\n    (_,  &c) => \"y equals to c!\"\n    _        => \"none of x and y equal to c\"\nend"
},

{
    "location": "syntax/pattern/#Custom-pattern-1",
    "page": "Pattern",
    "title": "Custom pattern",
    "category": "section",
    "text": "The reason why Julia is a new \"best language\" might be that you can implement your own static pattern matching with this feature:-).Here is a example although it\'s not robust at all. You can use it to solve multiplication equations.uisng MLStyle\n\n# define pattern for application\nPatternDef.App(*) do args, guard, tag, mod\n         @match (args) begin\n            (l::QuoteNode, r :: QuoteNode) => MLStyle.Err.SyntaxError(\"both sides of (*) are symbols!\")\n            (l::QuoteNode, r) =>\n               quote\n                   $(eval(l)) = $tag / ($r)\n               end\n           (l, r :: QuoteNode) =>\n               quote\n                   $(eval(r)) = $tag / ($l)\n               end\n           end\nend\n\n@match 10 begin\n     5 * :a => a\nend\n# => 2.0Dictionary pattern, tuple pattern, array pattern and linked list destructing are both implemented by Custom pattern.Dict pattern(like Elixir\'s dictionary matching or ML record matching)dict = Dict(1 => 2, \"3\" => 4, 5 => Dict(6 => 7))\n@match dict begin\n    Dict(\"3\" => four::Int,\n          5  => Dict(6 => sev)){four < sev} => sev\nend\n# => 7Tuple pattern\n@match (1, 2, (3, 4, (5, )))\n\n    (a, b, (c, d, (5, ))) => (a, b, c, d)\n\nend\n# => (1, 2, 3, 4)Array pattern(as efficient as linked list pattern for the usage of array view)julia> it = @match [1, 2, 3, 4] begin\n         [1, pack..., a] => (pack, a)\n       end\n([2, 3], 4)\n\njulia> first(it)\n2-element view(::Array{Int64,1}, 2:3) with eltype Int64:  \n 2\n 3\njulia> it[2]\n4Linked list pattern\nlst = List.List!(1, 2, 3)\n\n@match lst begin\n    1 ^ a ^ tail => a\nend\n\n# => (2, MLStyle.Data.List.Cons{Int64}(3, MLStyle.Data.List.Nil{Int64}()))"
},

{
    "location": "syntax/pattern/#Fall-through-cases-1",
    "page": "Pattern",
    "title": "Fall through cases",
    "category": "section",
    "text": "test(num) =\n    @match num begin\n       ::Float64 |\n        0        |\n        1        |\n        2        => true\n\n        _        => false\n    end\n\ntest(0)   # true\ntest(1)   # true\ntest(2)   # true\ntest(1.0) # true\ntest(3)   # false\ntest(\"\")  # false"
},

{
    "location": "syntax/pattern/#Type-level-feature-1",
    "page": "Pattern",
    "title": "Type level feature",
    "category": "section",
    "text": "By default, type level feature wouldn\'t be activated.@match 1 begin\n    ::String => String\n    ::Int => Int    \nend\n# => Int64Feature.@activate TypeLevel\n\n@match 1 begin\n    ::String => String\n    ::Int    => Int\nend\n# => Int64When using type level feature, if you can only perform runtime type checking when matching, and type level variables could be captured as normal variables.If you do want to check type when type level feature is activated, do as the following snippet@match 1 begin\n    ::&String => String\n    ::&Int    => Int\nend"
},

{
    "location": "syntax/pattern-function/#",
    "page": "Pattern function",
    "title": "Pattern function",
    "category": "page",
    "text": ""
},

{
    "location": "syntax/pattern-function/#Pattern-function-1",
    "page": "Pattern function",
    "title": "Pattern function",
    "category": "section",
    "text": "\n@def f begin\n    # patterns here\n    x                  => 1\n    (x, (1, 2)){x > 3} => 5\n    (x, y)             => 2\n    ::String           => \"is string\"\n    _                  => \"is any\"\nend\nf(1) # => 1\nf(4, (1, 2)) # => 5\nf(1, (1, 2)) # => 2\nf(\"\") # => \"is string\""
},

]}
