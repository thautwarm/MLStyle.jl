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
    "text": "ML-style infrastructure provider for JuliaCheck out documents here:ADT\nPatterns for matching\nPattern functionOr you want some examples."
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
    "text": ""
},

{
    "location": "syntax/adt/#Syntax-1",
    "page": "Algebraic Data Types",
    "title": "Syntax",
    "category": "section",
    "text": "\n<Seq> a         = a (\',\' a)*\n<TypeName>      = %Uppercase identifier%\n<fieldname>     = %Lowercase identifier%\n<TVar>          = %Uppercase identifier%\n<ConsName>      = %Uppercase identifier%\n<ImplicitTVar>  = %Uppercase identifier%\n<Type>          = <TypeName> [ \'{\' <Seq TVar> \'}\' ]\n<Module>        = %Uppercase identifier%\n\n<ADT>           =\n    \'@data\' [\'public\' | \'internal\' | \'visible\' \'in\' <Seq Module>] <Type> \'begin\'\n\n        (<ConsName>[{<Seq TVar>}] (\n            <Seq fieldname> | <Seq Type> | <Seq (<fieldname> :: <Type>)>\n        ))*\n\n    \'end\'\n\n<GADT>           =\n    \'@data\' [\'public\' | \'internal\'] <Type> \'begin\'\n\n        (<ConsName>[{<Seq TVar>}] \'::\'\n           ( \'(\'\n                (<Seq fieldname> | <Seq Type> | <Seq (<fieldname> :: <Type>)>)\n             \')\'\n              | <fieldname>\n              | <Type>\n           )\n           \'=>\' <Type> [\'where\' \'{\' <Seq ImplicitTvar> \'}\']\n        )*\n\n    \'end\'\n"
},

{
    "location": "syntax/adt/#Qualifier-1",
    "page": "Algebraic Data Types",
    "title": "Qualifier",
    "category": "section",
    "text": "There are 3 default qualifiers for ADT definition:internal: The pattern created by the ADT can only be used in the module it\'s defined in.\npublic: If the constructor is imported into current module, the corresponding pattern will be available.\nvisible in [mod...]: Define a set of modules where the pattern is available."
},

{
    "location": "syntax/adt/#Example:-Describe-arithmetic-operations-1",
    "page": "Algebraic Data Types",
    "title": "Example: Describe arithmetic operations",
    "category": "section",
    "text": "using MLStyle\n@data internal Arith begin\n    Number(Int)\n    Minus(Arith, Arith)\n    Mult(Arith, Arith)\n    Divide(Arith, Arith)\nendAbove codes makes a clarified description about Arithmetic and provides a corresponding implementation.If you want to transpile above ADTs to some specific language, there is a clear step:\neval_arith(arith :: Arith) =\n    let wrap_op(op)  = (a, b) -> op(eval_arith(a), eval_arith(b)),\n        (+, -, *, /) = map(wrap_op, (+, -, *, /))\n        @match arith begin\n            Number(v)       => v\n            Minus(fst, snd) => fst - snd\n            Mult(fst, snd)   => fst * snd\n            Divide(fst, snd) => fst / snd\n        end\n    end\n\neval_arith(\n    Minus(\n        Number(2),\n        Divide(Number(20),\n               Mult(Number(2),\n                    Number(5)))))\n# => 0"
},

{
    "location": "syntax/adt/#Generalized-ADT-1",
    "page": "Algebraic Data Types",
    "title": "Generalized ADT",
    "category": "section",
    "text": "Note that, for GADTs would use where syntax as a pattern, it means that you cannot use GADTs and your custom where patterns at the same time. To resolve this, we introduce the extension system like Haskell here.Since that you can define your own where pattern and export it to any modules. Given an arbitrary Julia module, if you don\'t use @use GADT to enable GADT extensions and, the qualifier of the your where pattern makes it visible here(current module), your own where pattern could work here.Here\'s a simple intepreter implemented using GADTs.Firstly, enable GADT extension.using MLStyle\n@use GADTThen define the function type.import Base: convert\n\nstruct Fun{T, R}\n    fn :: Function\nend\n\nfunction (typed_fn :: Fun{T, R})(arg :: T) :: R where {T, R}\n    typed_fn.fn(arg)\nend\n\nfunction convert(::Type{Fun{T, R}}, fn :: Function) where {T, R}\n    Fun{T, R}(fn)\nend\n\nfunction convert(::Type{Fun{T, R}}, fn :: Fun{C, D}) where{T, R, C <: T, D <: R}\n    Fun{T, R}(fn.fn)\nend\n\n⇒(::Type{A}, ::Type{B}) where {A, B} = Fun{A, B}And now let\'s define the operators of our abstract machine.\n@data public Exp{T} begin\n\n    # The symbol referes to some variable in current context.\n    Sym       :: Symbol => Exp{A} where {A}\n\n    # Value.\n    Val{A}    :: A => Exp{A}\n\n    # Function application.\n    # add constraints to implicit tvars to get covariance\n    App{A, B} :: (Exp{Fun{A, B}}, Exp{A_}) => Exp{B} where {A_ <: A}\n\n    # Lambda/Anonymous function.\n    Lam{A, B} :: (Symbol, Exp{B}) => Exp{Fun{A, B}}\n\n    # If expression\n    If{A}     :: (Exp{Bool}, Exp{A}, Exp{A}) => Exp{A}\nendSomething deserved to be remark here: when using this GADT syntax like    ConsName{TVars1...} :: ... => Exp{TVars2...} where {TVar3...}You can add constraints to both TVars1 and TVars3, and TVars2 should be always empty or a sequence of Symbols. Furthermore, TVars3 are the so-called implicit type variables, and TVars1 are the normal generic type variables.Let\'s back to our topic.To make function abstractions, we need a substitute operation.\n\"\"\"\ne.g: substitute(some_exp, :a => another_exp)\n\"\"\"\nfunction substitute(template :: Exp{T}, pair :: Tuple{Symbol, Exp{G}}) where {T, G}\n    (sym, exp) = pair\n    @match template begin\n        Sym(&sym) => exp\n        Val(_) => template\n        App(f, a) => App(substitute(f, pair), substitute(a, pair)) :: Exp{T}\n        Lam(&sym, exp) => template\n        If(cond, exp1, exp2) =>\n            let (cond, exp1, exp2) = map(substitute, (cond, exp1, exp2))\n                If(cond, exp1, exp2) :: Exp{T}\n            end\n    end\nendThen we could write how to execute our abstract machine.function eval_exp(exp :: Exp{T}, ctx :: Dict{Symbol, Any}) where T\n    @match exp begin\n        Sym(a) => (ctx[a] :: T, ctx)\n        Val(a :: T) => (a, ctx)\n        App{A, T, A_}(f :: Exp{Fun{A, T}}, arg :: Exp{A_}) where {A, A_ <: A} =>\n            let (f, ctx) = eval_exp(f, ctx),\n                (arg, ctx) = eval_exp(arg, ctx)\n                (f(arg), ctx)\n            end\n        Lam{A, B}(sym, exp::Exp{B}) where {A, B} =>\n            let f(x :: A) = begin\n                    A\n                    eval_exp(substitute(exp, sym => Val(x)), ctx)[1]\n                end\n\n                (f, ctx)\n            end\n        If(cond, exp1, exp2) =>\n            let (cond, ctx) = eval_exp(cond, ctx)\n                eval_exp(cond ? exp1 : exp2, ctx)\n            end\n    end\nendThis eval_exp takes 2 arguments, one of which is an Exp{T}, while another is the store(you can regard it as the scope), the return is a tuple, the first of which is a value typed T and the second is the new store after the execution.Following codes are about how to use this abstract machine.add = Val{Number ⇒ Number ⇒ Number}(x -> y -> x + y)\nsub = Val{Number ⇒ Number ⇒ Number}(x -> y -> x - y)\ngt = Val{Number ⇒ Number ⇒ Bool}(x -> y -> x > y)\nctx = Dict{Symbol, Any}()\n\n@assert 3 == eval_exp(App(App(add, Val(1)), Val(2)), ctx)[1]\n@assert -1 == eval_exp(App(App(sub, Val(1)), Val(2)), ctx)[1]\n@assert 1 == eval_exp(\n    If(\n        App(App(gt, Sym{Int}(:x)), Sym{Int}(:y)),\n        App(App(sub, Sym{Int}(:x)), Sym{Int}(:y)),\n        App(App(sub, Sym{Int}(:y)), Sym{Int}(:x))\n    ), Dict{Symbol, Any}(:x => 1, :y => 2))[1]\n"
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
    "text": "Literal Pattern\nCapturing pattern\nType Pattern\nAs-Pattern, And Pattern\nGuard\nRange Pattern\nPredicate\nRference Pattern\nCustom Pattern, Dict, Tuple, Array\nOr Pattern\nADT destructing, GADTs\nAdvanced Type Pattern\nSide Effect\nActive Pattern\nAst PatternPatterns provide convenient ways to manipulate data."
},

{
    "location": "syntax/pattern/#Literal-Pattern-1",
    "page": "Pattern",
    "title": "Literal Pattern",
    "category": "section",
    "text": "\n\n@match 10 {\n    1  => \"wrong!\"\n    2  => \"wrong!\"\n    10 => \"right!\"\n}\n\n# => \"right\"There are 3 distinct types whose literal data could be used as literal patterns:Number\nAbstractString\nSymbol"
},

{
    "location": "syntax/pattern/#Capturing-Pattern-1",
    "page": "Pattern",
    "title": "Capturing Pattern",
    "category": "section",
    "text": "\n@match 1 begin\n    x => x + 1\nend\n# => 2"
},

{
    "location": "syntax/pattern/#Type-Pattern-1",
    "page": "Pattern",
    "title": "Type Pattern",
    "category": "section",
    "text": "\n@match 1 begin\n    ::Float  => nothing\n    b :: Int => b\n    _        => nothing\nend\n# => 1There is an advanced version of Type-Patterns, which you can destruct types with fewer limitations. Check Advanced Type Pattern.However, when you use TypeLevel Feature, the behavious could change slightly. See TypeLevel Feature."
},

{
    "location": "syntax/pattern/#As-Pattern-1",
    "page": "Pattern",
    "title": "As-Pattern",
    "category": "section",
    "text": "As-Pattern can be expressed with And-Pattern. @match (1, 2) begin\n    (a, b) && c => c[1] == a && c[2] == b\nend"
},

{
    "location": "syntax/pattern/#Guard-1",
    "page": "Pattern",
    "title": "Guard",
    "category": "section",
    "text": "\n@match x begin\n    x && if x > 5 end => 5 - x # only succeed when x > 5\n    _        => 1\nend"
},

{
    "location": "syntax/pattern/#Predicate-1",
    "page": "Pattern",
    "title": "Predicate",
    "category": "section",
    "text": "The following has the same semantics as the above snippet.\nfunction pred(x)\n    x > 5\nend\n\n@match x begin\n    x && function pred end => 5 - x # only succeed when x > 5\n    _        => 1\nend\n\n@match x begin\n    x && function (x) x > 5 end => 5 - x # only succeed when x > 5\n    _        => 1\nend\n"
},

{
    "location": "syntax/pattern/#Range-Pattern-1",
    "page": "Pattern",
    "title": "Range Pattern",
    "category": "section",
    "text": "@match 1 begin\n    0:2:10 => 1\n    1:10 => 2\nend # 2"
},

{
    "location": "syntax/pattern/#Reference-Pattern-1",
    "page": "Pattern",
    "title": "Reference Pattern",
    "category": "section",
    "text": "This feature is from Elixir which could slightly extends ML pattern matching.c = ...\n@match (x, y) begin\n    (&c, _)  => \"x equals to c!\"\n    (_,  &c) => \"y equals to c!\"\n    _        => \"none of x and y equal to c\"\nend"
},

{
    "location": "syntax/pattern/#Custom-Pattern-1",
    "page": "Pattern",
    "title": "Custom Pattern",
    "category": "section",
    "text": "Not recommend to do this for it\'s implementation specific. If you want to make your own extensions, check MLStyle/src/Pervasives.jl.Defining your own patterns using the low level APIs is quite easy, but exposing the implementations would cause compatibilities in future development."
},

{
    "location": "syntax/pattern/#Dict,-Tuple,-Array-1",
    "page": "Pattern",
    "title": "Dict, Tuple, Array",
    "category": "section",
    "text": "Dict pattern(like Elixir\'s dictionary matching or ML record matching)dict = Dict(1 => 2, \"3\" => 4, 5 => Dict(6 => 7))\n@match dict begin\n    Dict(\"3\" => four::Int,\n          5  => Dict(6 => sev)) && if four < sev end => sev\nend\n# => 7Tuple pattern\n@match (1, 2, (3, 4, (5, ))) begin\n    (a, b, (c, d, (5, ))) => (a, b, c, d)\n\nend\n# => (1, 2, 3, 4)Array pattern(much more efficient than Python for taking advantage of array views)julia> it = @match [1, 2, 3, 4] begin\n         [1, pack..., a] => (pack, a)\n       end\n([2, 3], 4)\n\njulia> first(it)\n2-element view(::Array{Int64,1}, 2:3) with eltype Int64:\n 2\n 3\njulia> it[2]\n4"
},

{
    "location": "syntax/pattern/#Or-Pattern-1",
    "page": "Pattern",
    "title": "Or Pattern",
    "category": "section",
    "text": "test(num) =\n    @match num begin\n       ::Float64 ||\n        0        ||\n        1        ||\n        2        => true\n\n        _        => false\n    end\n\ntest(0)   # true\ntest(1)   # true\ntest(2)   # true\ntest(1.0) # true\ntest(3)   # false\ntest(\"\")  # falseTips: Or Patterns could nested."
},

{
    "location": "syntax/pattern/#ADT-Destructing-1",
    "page": "Pattern",
    "title": "ADT Destructing",
    "category": "section",
    "text": "You can match ADT in following 3 means:\nC(a, b, c) => ... # ordered arguments\nC(b = b) => ...   # record syntax\nC(_) => ...       # wildcard for destructing\nHere is an example:\n@data Example begin\n    Natural(dimension :: Float32, climate :: String, altitude :: Int32)\n    Cutural(region :: String,  kind :: String, country :: String, nature :: Natural)\nend\n\n神农架 = Cutural(\"湖北\", \"林区\", \"中国\", Natural(31.744, \"北亚热带季风气候\", 3106))\nYellostone = Cutural(\"Yellowstone National Park\", \"Natural\", \"United States\", Natural(44.36, \"subarctic\", 2357))\n\nfunction my_data_query(data_lst :: Vector{Cutural})\n    filter(data_lst) do data\n        @match data begin\n            Cutural(_, \"林区\", \"中国\", Natural(dim=dim, altitude)) &&\n            if dim > 30.0 && altitude > 1000 end => true\n\n            Cutural(_, _, \"United States\", Natural(altitude=altitude)) &&\n            if altitude > 2000 end  => true\n            _ => false\n\n        end\n    end\nend\nmy_data_query([神农架, Yellostone])\n...About GADTs@use GADT\n\n@data internal Example{T} begin\n    A{T} :: (Int, T) => Example{Tuple{Int, T}}\nend\n\n@match A(1, 2) begin\n    A{T}(a :: Int, b :: T) where T <: Number => (a == 1 && T == Int)\nend\n"
},

{
    "location": "syntax/pattern/#Advanced-Type-Pattern-1",
    "page": "Pattern",
    "title": "Advanced Type Pattern",
    "category": "section",
    "text": "Instead of TypeLevel feature used in v0.1, an ideal type-stable way to destruct types now is introduced here.@match 1 begin\n    ::String => String\n    ::Int => Int\nend\n# => Int64\n\n@match 1 begin\n    ::T where T <: AbstractArray => 0\n    ::T where T <: Number => 1\nend\n\n# => 0\n\nstruct S{A, B}\n    a :: A\n    b :: B\nend\n\n@match S(1, \"2\") begin\n    ::S{A} where A => A\nend\n# => Int64\n\n@match S(1, \"2\") begin\n    ::S{A, B} where {A, B <: AbstractString} => (A, B)\nend\n# => (Int64, String)\n"
},

{
    "location": "syntax/pattern/#Side-Effect-1",
    "page": "Pattern",
    "title": "Side-Effect",
    "category": "section",
    "text": "To introduce side-effects into pattern matching, we provide a built-in pattern called Do pattern to achieve this. Also, a pattern called Many can work with Do pattern in a perfect way."
},

{
    "location": "syntax/pattern/#Do-Pattern-and-Many-Pattern-1",
    "page": "Pattern",
    "title": "Do-Pattern and Many-Pattern",
    "category": "section",
    "text": "\n@match [1, 2, 3] begin\n    Many(::Int) => true\n    _ => false\nend # true\n\n@match [1, 2, 3,  \"a\", \"b\", \"c\", :a, :b, :c] begin\n    Do(count = 0) &&\n    Many(\n        a::Int && Do(count = count + a) ||\n        ::String                        ||\n        ::Symbol && Do(count = count + 1)\n    ) => count\nend # 9They may be not used very often but quite convenient for some specific domain."
},

{
    "location": "syntax/pattern/#Active-Pattern-1",
    "page": "Pattern",
    "title": "Active Pattern",
    "category": "section",
    "text": "This implementation is a subset of F# Active Patterns.There\'re 2 distinct active patterns, first of which is the normal form:@active LessThan0(x) begin\n    if x > 0\n        nothing\n    else\n        x\n    end\nend\n\n@match 15 begin\n    LessThan0(_) => :a\n    _ => :b\nend # :b\n\n@match -15 begin\n    LessThan0(a) => a\n    _ => 0\nend # -15\nThe second is the parametric version.@active Re{r :: Regex}(x) begin\n    match(r, x)\nend\n\n@match \"123\" begin\n    Re{r\"\\d+\"}(x) => x\n    _ => @error \"\"\nend # RegexMatch(\"123\")"
},

{
    "location": "syntax/pattern/#Ast-Pattern-1",
    "page": "Pattern",
    "title": "Ast Pattern",
    "category": "section",
    "text": "This might be the most important update since v0.2.rmlines = @λ begin\n    e :: Expr           -> Expr(e.head, filter(x -> x !== nothing, map(rmlines, e.args))...)\n      :: LineNumberNode -> nothing\n    a                   -> a\nend\nexpr = quote\n    struct S{T}\n        a :: Int\n        b :: T\n    end\nend |> rmlines\n\n@match expr begin\n    quote\n        struct $name{$tvar}\n            $f1 :: $t1\n            $f2 :: $t2\n        end\n    end =>\n    quote\n        struct $name{$tvar}\n            $f1 :: $t1\n            $f2 :: $t2\n        end\n    end |> rmlines == expr\nend # trueHow you create an AST, then how you match them.How you use AST interpolations($ operation), then how you use capturing patterns on them.Here is an article about this Ast Pattern."
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
    "text": "Pattern function is a convenient way to define a function with multiple entries.f = @λ begin\n    # patterns here\n    x                  -> 1\n    (x, (1, 2)) &&\n        if x > 3 end   -> 5\n    (x, y)             -> 2\n    ::String           -> \"is string\"\n    _                  -> \"is any\"\nend\nf(1) # => 1\nf((4, (1, 2))) # => 5\nf((1, (1, 2))) # => 2\nf(\"\") # => \"is string\"Also, sometimes you might want to pass a single lambda which just matches the argument in one means:map((@λ [a, b, c...] -> c))\nA pattern function is no more than using a @match inside some anonymous function.\nfunction (x)\n    @match x begin\n        pat1 => body1\n        pat2 => body2\n    end\nend\n"
},

]}
