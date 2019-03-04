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
    "text": "(Image: Build Status) (Image: codecov) (Image: License) (Image: Docs)  (Image: Join the chat at https://gitter.im/MLStyle-jl/community)"
},

{
    "location": "#What\'s-MLStyle.jl?-1",
    "page": "Home",
    "title": "What\'s MLStyle.jl?",
    "category": "section",
    "text": "MLStyle.jl is a Julia package that provides multiple productivity tools from ML(Meta Language) like statically generated and extensible pattern matching, ADTs/GADTs(Algebraic Data Type, Generalized Algebraic Data Type) and Active Patterns.If you still have problems with the scoping of MLStyle.jl, treat it as FP.jl."
},

{
    "location": "#Motivation-1",
    "page": "Home",
    "title": "Motivation",
    "category": "section",
    "text": "The people who\'re used to so-called functional programming could become retarded when there\'re no pattern matching and ADTs, and of course I\'m one of them.However, I don\'t want to take a trade-off here to use some available alternatives that miss features or are not well-optimized. Just like why those greedy people created Julia, I\'m also so greedy that I want to integrate all those useful features into one language and, make all of them convenient, efficient and extensible.On the other side, during recent years I was addicted to extend Python with metaprogramming and even internal mechanisms. Although I made something interesting like pattern-matching, goto, ADTs, constexpr, macros, etc., most of these implementations are so disgustingly evil. Furtunately, in Julia, all of them could be achieved straightforwardly without any black magic, at last, some of these ideas come into the existence of MLStyle.jl.Finally, we finish such a library that provides extensible pattern matching in such an efficient language."
},

{
    "location": "#Why-to-use-MLStyle.jl-1",
    "page": "Home",
    "title": "Why to use MLStyle.jl",
    "category": "section",
    "text": "StraightforwardI think there is no need to talk about why we\r\nshould use pattern mathing instead of manually \r\nwriting something like conditional branches and\r\nnested visitors for datatypes.Performance GainWhen dealing with complex conditional logics and\r\nvisiting nested datatypes, the codes compiled via\r\n`MLStyle.jl` could always match the handwritten.\r\n\r\nYou can check [Benchmark](#benchmark) for details.Extensibility and Hygienic ScopingYou can define your own patterns via the interfaces\r\n`def_pattern`, `def_app_pattern` and `def_gapp_pattern`.\r\n\r\nAlmost all built-in patterns are defined at [Pervasives.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/src/Pervasives.jl).\r\n\nOnce you define a pattern, you\'re to be asked to give some\r\nqualifiers to your own patterns to prevent visiting them\r\nfrom unexpected modules.* Modern Ways about AST ManipulationsMLStyle.jl is not a superset of MacroToos.jl, but\r\nit provides something useful for AST manipulations.\r\n\nFurthermore, in terms of extracting sub-structures from\r\na given AST, using expr patterns and AST patterns could\r\nmake a orders of magnitude speed up."
},

{
    "location": "#Installation,-Documentations-and-Tutorials-1",
    "page": "Home",
    "title": "Installation, Documentations and Tutorials",
    "category": "section",
    "text": "Rich features are provided by MLStyle.jl and you can check documents to get started.For installation, open package manager mode in Julia shell and add MLStyle.For more examples or tutorials, check this project which will be frequently updated to present some interesting uses of MLStyle.jl."
},

{
    "location": "#Preview-1",
    "page": "Home",
    "title": "Preview",
    "category": "section",
    "text": "In this README I\'m glad to share some non-trivial code snippets."
},

{
    "location": "#Homoiconic-pattern-matching-for-Julia-ASTs-1",
    "page": "Home",
    "title": "Homoiconic pattern matching for Julia ASTs",
    "category": "section",
    "text": "rmlines = @λ begin\r\n    e :: Expr           -> Expr(e.head, filter(x -> x !== nothing, map(rmlines, e.args))...)\r\n      :: LineNumberNode -> nothing\r\n    a                   -> a\r\nend\r\nexpr = quote\r\n    struct S{T}\r\n        a :: Int\r\n        b :: T\r\n    end\r\nend |> rmlines\r\n\r\n@match expr begin\r\n    quote\r\n        struct $name{$tvar}\r\n            $f1 :: $t1\r\n            $f2 :: $t2\r\n        end\r\n    end =>\r\n    quote\r\n        struct $name{$tvar}\r\n            $f1 :: $t1\r\n            $f2 :: $t2\r\n        end\r\n    end |> rmlines == expr\r\nend"
},

{
    "location": "#Generalized-Algebraic-Data-Types-1",
    "page": "Home",
    "title": "Generalized Algebraic Data Types",
    "category": "section",
    "text": "@use GADT\r\n\r\n@data public Exp{T} begin\r\n    Sym       :: Symbol => Exp{A} where {A}\r\n    Val{A}    :: A => Exp{A}\r\n    App{A, B} :: (Exp{Fun{A, B}}, Exp{A_}) => Exp{B} where {A_ <: A}\r\n    Lam{A, B} :: (Symbol, Exp{B}) => Exp{Fun{A, B}}\r\n    If{A}     :: (Exp{Bool}, Exp{A}, Exp{A}) => Exp{A}\r\nend\r\nA simple intepreter implementation using GADTs could be found at test/untyped_lam.jl."
},

{
    "location": "#Active-Patterns-1",
    "page": "Home",
    "title": "Active Patterns",
    "category": "section",
    "text": "Currently, in MLStyle it\'s not a full featured one, but even a subset with parametric active pattern could be super useful.@active Re{r :: Regex}(x) begin\r\n    match(r, x)\r\nend\r\n\r\n@match \"123\" begin\r\n    Re{r\"\\d+\"}(x) => x\r\n    _ => @error \"\"\r\nend # RegexMatch(\"123\")"
},

{
    "location": "#Benchmark-1",
    "page": "Home",
    "title": "Benchmark",
    "category": "section",
    "text": ""
},

{
    "location": "#Prerequisite-1",
    "page": "Home",
    "title": "Prerequisite",
    "category": "section",
    "text": "Recently the rudimentary benchmarks have been finished, which turns out that MLStyle.jl could be extremely fast when matching cases are complicated, while in terms of some very simple cases(straightforward destruct shallow tuples, arrays and datatypes without recursive invocations), Match.jl could be faster.All benchmark scripts are provided at directory Matrix-Benchmark.To run these cross-implementation benchmarks, some extra dependencies should be installed:(v1.1) pkg> add https://github.com/thautwarm/Benchmarkplotting.jl#master for making cross-implementation benchmark methods and plotting.(v1.1) pkg> add Gadfly MacroTools Match BenchmarkTools StatsBase Statistics ArgParse DataFrames.(v1.1) pkg> add MLStyle#base for a specific version of MLStyle.jl is required.After installing dependencies, you can directly benchmark them with julia matrix_benchmark.jl hw-tuple hw-array match macrotools match-datatype at the root directory.The benchmarks presented here are made by Julia v1.1 on Fedora 28. For reports made on Win10, check stats/windows/ directory."
},

{
    "location": "#Visualization-1",
    "page": "Home",
    "title": "Visualization",
    "category": "section",
    "text": ""
},

{
    "location": "#Time-Overhead-1",
    "page": "Home",
    "title": "Time Overhead",
    "category": "section",
    "text": "In x-axis, after the name of test-case is the least time-consuming one\'s index, the unit is ns).The y-label is the ratio of the implementation\'s time cost to that of the least time-consuming."
},

{
    "location": "#Allocation-1",
    "page": "Home",
    "title": "Allocation",
    "category": "section",
    "text": "In x-axis, after the name of test-case is the least allocted one\'s index, the unit is _ -> (_ + 1) bytes).The y-label is the ratio of  the implementation\'s allocation cost to that of the least allocted."
},

{
    "location": "#Gallery-1",
    "page": "Home",
    "title": "Gallery",
    "category": "section",
    "text": "Check https://github.com/thautwarm/MLStyle.jl/tree/master/stats."
},

{
    "location": "#Contributing-to-MLStyle-1",
    "page": "Home",
    "title": "Contributing to MLStyle",
    "category": "section",
    "text": "Thanks to all individuals referred in Acknowledgements!Feel free to ask questions about usage, development or extensions about MLStyle at Gitter Room."
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
    "text": "\r\n<Seq> a         = a (\',\' a)*\r\n<TypeName>      = %Uppercase identifier%\r\n<fieldname>     = %Lowercase identifier%\r\n<TVar>          = %Uppercase identifier%\r\n<ConsName>      = %Uppercase identifier%\r\n<ImplicitTVar>  = %Uppercase identifier%\r\n<Type>          = <TypeName> [ \'{\' <Seq TVar> \'}\' ]\r\n<Module>        = %Uppercase identifier%\r\n\r\n<ADT>           =\r\n    \'@data\' [\'public\' | \'internal\' | \'visible\' \'in\' <Seq Module>] <Type> \'begin\'\r\n\r\n        (<ConsName>[{<Seq TVar>}] (\r\n            <Seq fieldname> | <Seq Type> | <Seq (<fieldname> :: <Type>)>\r\n        ))*\r\n\r\n    \'end\'\r\n\r\n<GADT>           =\r\n    \'@data\' [\'public\' | \'internal\'] <Type> \'begin\'\r\n\r\n        (<ConsName>[{<Seq TVar>}] \'::\'\r\n           ( \'(\'\r\n                (<Seq fieldname> | <Seq Type> | <Seq (<fieldname> :: <Type>)>)\r\n             \')\'\r\n              | <fieldname>\r\n              | <Type>\r\n           )\r\n           \'=>\' <Type> [\'where\' \'{\' <Seq ImplicitTvar> \'}\']\r\n        )*\r\n\r\n    \'end\'\r\n"
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
    "text": "using MLStyle\r\n@data internal Arith begin\r\n    Number(Int)\r\n    Minus(Arith, Arith)\r\n    Mult(Arith, Arith)\r\n    Divide(Arith, Arith)\r\nendAbove codes makes a clarified description about Arithmetic and provides a corresponding implementation.If you want to transpile above ADTs to some specific language, there is a clear step:\r\neval_arith(arith :: Arith) =\r\n    let wrap_op(op)  = (a, b) -> op(eval_arith(a), eval_arith(b)),\r\n        (+, -, *, /) = map(wrap_op, (+, -, *, /))\r\n        @match arith begin\r\n            Number(v)       => v\r\n            Minus(fst, snd) => fst - snd\r\n            Mult(fst, snd)   => fst * snd\r\n            Divide(fst, snd) => fst / snd\r\n        end\r\n    end\r\n\r\neval_arith(\r\n    Minus(\r\n        Number(2),\r\n        Divide(Number(20),\r\n               Mult(Number(2),\r\n                    Number(5)))))\r\n# => 0"
},

{
    "location": "syntax/adt/#Generalized-ADT-1",
    "page": "Algebraic Data Types",
    "title": "Generalized ADT",
    "category": "section",
    "text": "Note that, for GADTs would use where syntax as a pattern, it means that you cannot use GADTs and your custom where patterns at the same time. To resolve this, we introduce the extension system like Haskell here.Since that you can define your own where pattern and export it to any modules. Given an arbitrary Julia module, if you don\'t use @use GADT to enable GADT extensions and, the qualifier of the your where pattern makes it visible here(current module), your own where pattern could work here.Here\'s a simple intepreter implemented using GADTs.Firstly, enable GADT extension.using MLStyle\r\n@use GADTThen define the function type.import Base: convert\r\n\r\nstruct Fun{T, R}\r\n    fn :: Function\r\nend\r\n\r\nfunction (typed_fn :: Fun{T, R})(arg :: T) :: R where {T, R}\r\n    typed_fn.fn(arg)\r\nend\r\n\r\nfunction convert(::Type{Fun{T, R}}, fn :: Function) where {T, R}\r\n    Fun{T, R}(fn)\r\nend\r\n\r\nfunction convert(::Type{Fun{T, R}}, fn :: Fun{C, D}) where{T, R, C <: T, D <: R}\r\n    Fun{T, R}(fn.fn)\r\nend\r\n\r\n⇒(::Type{A}, ::Type{B}) where {A, B} = Fun{A, B}And now let\'s define the operators of our abstract machine.\r\n@data public Exp{T} begin\r\n\r\n    # The symbol referes to some variable in current context.\r\n    Sym       :: Symbol => Exp{A} where {A}\r\n\r\n    # Value.\r\n    Val{A}    :: A => Exp{A}\r\n\r\n    # Function application.\r\n    # add constraints to implicit tvars to get covariance\r\n    App{A, B} :: (Exp{Fun{A, B}}, Exp{A_}) => Exp{B} where {A_ <: A}\r\n\r\n    # Lambda/Anonymous function.\r\n    Lam{A, B} :: (Symbol, Exp{B}) => Exp{Fun{A, B}}\r\n\r\n    # If expression\r\n    If{A}     :: (Exp{Bool}, Exp{A}, Exp{A}) => Exp{A}\r\nendSomething deserved to be remark here: when using this GADT syntax like    ConsName{TVars1...} :: ... => Exp{TVars2...} where {TVar3...}You can add constraints to both TVars1 and TVars3, and TVars2 should be always empty or a sequence of Symbols. Furthermore, TVars3 are the so-called implicit type variables, and TVars1 are the normal generic type variables.Let\'s back to our topic.To make function abstractions, we need a substitute operation.\r\n\"\"\"\r\ne.g: substitute(some_exp, :a => another_exp)\r\n\"\"\"\r\nfunction substitute(template :: Exp{T}, pair :: Tuple{Symbol, Exp{G}}) where {T, G}\r\n    (sym, exp) = pair\r\n    @match template begin\r\n        Sym(&sym) => exp\r\n        Val(_) => template\r\n        App(f, a) => App(substitute(f, pair), substitute(a, pair)) :: Exp{T}\r\n        Lam(&sym, exp) => template\r\n        If(cond, exp1, exp2) =>\r\n            let (cond, exp1, exp2) = map(substitute, (cond, exp1, exp2))\r\n                If(cond, exp1, exp2) :: Exp{T}\r\n            end\r\n    end\r\nendThen we could write how to execute our abstract machine.function eval_exp(exp :: Exp{T}, ctx :: Dict{Symbol, Any}) where T\r\n    @match exp begin\r\n        Sym(a) => (ctx[a] :: T, ctx)\r\n        Val(a :: T) => (a, ctx)\r\n        App{A, T, A_}(f :: Exp{Fun{A, T}}, arg :: Exp{A_}) where {A, A_ <: A} =>\r\n            let (f, ctx) = eval_exp(f, ctx),\r\n                (arg, ctx) = eval_exp(arg, ctx)\r\n                (f(arg), ctx)\r\n            end\r\n        Lam{A, B}(sym, exp::Exp{B}) where {A, B} =>\r\n            let f(x :: A) = begin\r\n                    A\r\n                    eval_exp(substitute(exp, sym => Val(x)), ctx)[1]\r\n                end\r\n\r\n                (f, ctx)\r\n            end\r\n        If(cond, exp1, exp2) =>\r\n            let (cond, ctx) = eval_exp(cond, ctx)\r\n                eval_exp(cond ? exp1 : exp2, ctx)\r\n            end\r\n    end\r\nendThis eval_exp takes 2 arguments, one of which is an Exp{T}, while another is the store(you can regard it as the scope), the return is a tuple, the first of which is a value typed T and the second is the new store after the execution.Following codes are about how to use this abstract machine.add = Val{Number ⇒ Number ⇒ Number}(x -> y -> x + y)\r\nsub = Val{Number ⇒ Number ⇒ Number}(x -> y -> x - y)\r\ngt = Val{Number ⇒ Number ⇒ Bool}(x -> y -> x > y)\r\nctx = Dict{Symbol, Any}()\r\n\r\n@assert 3 == eval_exp(App(App(add, Val(1)), Val(2)), ctx)[1]\r\n@assert -1 == eval_exp(App(App(sub, Val(1)), Val(2)), ctx)[1]\r\n@assert 1 == eval_exp(\r\n    If(\r\n        App(App(gt, Sym{Int}(:x)), Sym{Int}(:y)),\r\n        App(App(sub, Sym{Int}(:x)), Sym{Int}(:y)),\r\n        App(App(sub, Sym{Int}(:y)), Sym{Int}(:x))\r\n    ), Dict{Symbol, Any}(:x => 1, :y => 2))[1]\r\n"
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
    "text": "Literal Pattern\nCapturing pattern\nType Pattern\nAs-Pattern, And Pattern\nGuard\nRange Pattern\nPredicate\nReference Pattern\nCustom Pattern, Dict, Tuple, Array\nOr Pattern\nADT destructuring, GADTs\nAdvanced Type Pattern\nSide Effect\nActive Pattern\nExpr Pattern\nAst PatternPatterns provide convenient ways to manipulate data."
},

{
    "location": "syntax/pattern/#Literal-Pattern-1",
    "page": "Pattern",
    "title": "Literal Pattern",
    "category": "section",
    "text": "\r\n\r\n@match 10 {\r\n    1  => \"wrong!\"\r\n    2  => \"wrong!\"\r\n    10 => \"right!\"\r\n}\r\n\r\n# => \"right\"There are 3 distinct types whose literal data could be used as literal patterns:Number\nAbstractString\nSymbol"
},

{
    "location": "syntax/pattern/#Capturing-Pattern-1",
    "page": "Pattern",
    "title": "Capturing Pattern",
    "category": "section",
    "text": "\r\n@match 1 begin\r\n    x => x + 1\r\nend\r\n# => 2Note that, by default only symbols given in lower case could be used as capturing.If you prefer to capture via upper case symbols, you can enable this feature via@use UppercaseCapturingExtension UppercaseCapturing conflicts with Enum.Any questions about Enum, check Active Patterns."
},

{
    "location": "syntax/pattern/#Type-Pattern-1",
    "page": "Pattern",
    "title": "Type Pattern",
    "category": "section",
    "text": "\r\n@match 1 begin\r\n    ::Float  => nothing\r\n    b :: Int => b\r\n    _        => nothing\r\nend\r\n# => 1There is an advanced version of Type-Patterns, which you can destruct types with fewer limitations. Check Advanced Type Pattern."
},

{
    "location": "syntax/pattern/#As-Pattern-1",
    "page": "Pattern",
    "title": "As-Pattern",
    "category": "section",
    "text": "As-Pattern can be expressed with And-Pattern.@match (1, 2) begin\r\n    (a, b) && c => c[1] == a && c[2] == b\r\nend"
},

{
    "location": "syntax/pattern/#Guard-1",
    "page": "Pattern",
    "title": "Guard",
    "category": "section",
    "text": "\r\n@match x begin\r\n    x && if x > 5 end => 5 - x # only succeed when x > 5\r\n    _        => 1\r\nend"
},

{
    "location": "syntax/pattern/#Predicate-1",
    "page": "Pattern",
    "title": "Predicate",
    "category": "section",
    "text": "The following has the same semantics as the above snippet.\r\nfunction pred(x)\r\n    x > 5\r\nend\r\n\r\n@match x begin\r\n    x && function pred end => 5 - x # only succeed when x > 5\r\n    _        => 1\r\nend\r\n\r\n@match x begin\r\n    x && function (x) x > 5 end => 5 - x # only succeed when x > 5\r\n    _        => 1\r\nend\r\n"
},

{
    "location": "syntax/pattern/#Range-Pattern-1",
    "page": "Pattern",
    "title": "Range Pattern",
    "category": "section",
    "text": "@match 1 begin\r\n    0:2:10 => 1\r\n    1:10 => 2\r\nend # 2"
},

{
    "location": "syntax/pattern/#Reference-Pattern-1",
    "page": "Pattern",
    "title": "Reference Pattern",
    "category": "section",
    "text": "This feature is from Elixir which could slightly extends ML pattern matching.c = ...\r\n@match (x, y) begin\r\n    (&c, _)  => \"x equals to c!\"\r\n    (_,  &c) => \"y equals to c!\"\r\n    _        => \"none of x and y equal to c\"\r\nend"
},

{
    "location": "syntax/pattern/#Custom-Pattern-1",
    "page": "Pattern",
    "title": "Custom Pattern",
    "category": "section",
    "text": "Not recommend to do this for it\'s implementation specific. If you want to make your own extensions, check Pervasives.jl.Defining your own patterns using the low level APIs is quite easy, but exposing the implementations would cause compatibilities in future development."
},

{
    "location": "syntax/pattern/#Dict,-Tuple,-Array-1",
    "page": "Pattern",
    "title": "Dict, Tuple, Array",
    "category": "section",
    "text": "Dict pattern(like Elixir\'s dictionary matching or ML record matching)dict = Dict(1 => 2, \"3\" => 4, 5 => Dict(6 => 7))\r\n@match dict begin\r\n    Dict(\"3\" => four::Int,\r\n          5  => Dict(6 => sev)) && if four < sev end => sev\r\nend\r\n# => 7Tuple pattern\r\n@match (1, 2, (3, 4, (5, ))) begin\r\n    (a, b, (c, d, (5, ))) => (a, b, c, d)\r\n\r\nend\r\n# => (1, 2, 3, 4)Array pattern(much more efficient than Python for taking advantage of array views)julia> it = @match [1, 2, 3, 4] begin\r\n         [1, pack..., a] => (pack, a)\r\n       end\r\n([2, 3], 4)\r\n\r\njulia> first(it)\r\n2-element view(::Array{Int64,1}, 2:3) with eltype Int64:\r\n 2\r\n 3\r\njulia> it[2]\r\n4"
},

{
    "location": "syntax/pattern/#Or-Pattern-1",
    "page": "Pattern",
    "title": "Or Pattern",
    "category": "section",
    "text": "test(num) =\r\n    @match num begin\r\n       ::Float64 ||\r\n        0        ||\r\n        1        ||\r\n        2        => true\r\n\r\n        _        => false\r\n    end\r\n\r\ntest(0)   # true\r\ntest(1)   # true\r\ntest(2)   # true\r\ntest(1.0) # true\r\ntest(3)   # false\r\ntest(\"\")  # falseTips: Or Patterns could nested."
},

{
    "location": "syntax/pattern/#ADT-Destructuring-1",
    "page": "Pattern",
    "title": "ADT Destructuring",
    "category": "section",
    "text": "You can match ADT in following 3 means:\r\nC(a, b, c) => ... # ordered arguments\r\nC(b = b) => ...   # record syntax\r\nC(_) => ...       # wildcard for destructuring\r\nHere is an example:\r\n@data Example begin\r\n    Natural(dimension :: Float32, climate :: String, altitude :: Int32)\r\n    Cutural(region :: String,  kind :: String, country :: String, nature :: Natural)\r\nend\r\n\r\n神农架 = Cutural(\"湖北\", \"林区\", \"中国\", Natural(31.744, \"北亚热带季风气候\", 3106))\r\nYellostone = Cutural(\"Yellowstone National Park\", \"Natural\", \"United States\", Natural(44.36, \"subarctic\", 2357))\r\n\r\nfunction my_data_query(data_lst :: Vector{Cutural})\r\n    filter(data_lst) do data\r\n        @match data begin\r\n            Cutural(_, \"林区\", \"中国\", Natural(dim=dim, altitude)) &&\r\n            if dim > 30.0 && altitude > 1000 end => true\r\n\r\n            Cutural(_, _, \"United States\", Natural(altitude=altitude)) &&\r\n            if altitude > 2000 end  => true\r\n            _ => false\r\n\r\n        end\r\n    end\r\nend\r\nmy_data_query([神农架, Yellostone])\r\n...Support destructuring Julia types defined regularlystruct A\r\n    a\r\n    b\r\n    c\r\nend\r\n\r\n# allow `A` to be destructured as datatypes in current module.\r\n@as_record internal A\r\n\r\n@match A(1, 2, 3) begin\r\n    A(1, 2, 3) => ...\r\nendAbout GADTs@use GADT\r\n\r\n@data internal Example{T} begin\r\n    A{T} :: (Int, T) => Example{Tuple{Int, T}}\r\nend\r\n\r\n@match A(1, 2) begin\r\n    A{T}(a :: Int, b :: T) where T <: Number => (a == 1 && T == Int)\r\nend\r\n"
},

{
    "location": "syntax/pattern/#Advanced-Type-Pattern-1",
    "page": "Pattern",
    "title": "Advanced Type Pattern",
    "category": "section",
    "text": "Instead of TypeLevel feature used in v0.1, an ideal type-stable way to destruct types now is introduced here.@match 1 begin\r\n    ::String => String\r\n    ::Int => Int\r\nend\r\n# => Int64\r\n\r\n@match 1 begin\r\n    ::T where T <: AbstractArray => 0\r\n    ::T where T <: Number => 1\r\nend\r\n\r\n# => 0\r\n\r\nstruct S{A, B}\r\n    a :: A\r\n    b :: B\r\nend\r\n\r\n@match S(1, \"2\") begin\r\n    ::S{A} where A => A\r\nend\r\n# => Int64\r\n\r\n@match S(1, \"2\") begin\r\n    ::S{A, B} where {A, B <: AbstractString} => (A, B)\r\nend\r\n# => (Int64, String)\r\n"
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
    "text": "\r\n@match [1, 2, 3] begin\r\n    Many(::Int) => true\r\n    _ => false\r\nend # true\r\n\r\n@match [1, 2, 3,  \"a\", \"b\", \"c\", :a, :b, :c] begin\r\n    Do(count = 0) &&\r\n    Many(\r\n        a::Int && Do(count = count + a) ||\r\n        ::String                        ||\r\n        ::Symbol && Do(count = count + 1)\r\n    ) => count\r\nend # 9They may be not used very often but quite convenient for some specific domain."
},

{
    "location": "syntax/pattern/#Active-Pattern-1",
    "page": "Pattern",
    "title": "Active Pattern",
    "category": "section",
    "text": "This implementation is a subset of F# Active Patterns.There\'re 2 distinct active patterns, first of which is the normal form:@active LessThan0(x) begin\r\n    if x > 0\r\n        nothing\r\n    else\r\n        x\r\n    end\r\nend\r\n\r\n@match 15 begin\r\n    LessThan0(_) => :a\r\n    _ => :b\r\nend # :b\r\n\r\n@match -15 begin\r\n    LessThan0(a) => a\r\n    _ => 0\r\nend # -15\r\nThe second is the parametric version.@active Re{r :: Regex}(x) begin\r\n    res = match(r, x)\r\n    if res !== nothing\r\n        # use explicit `if-else` to emphasize the return should be Union{T, Nothing}.\r\n        res\r\n    else\r\n        nothing\r\n    end\r\nend\r\n\r\n@match \"123\" begin\r\n    Re{r\"\\d+\"}(x) => x\r\n    _ => @error \"\"\r\nend # RegexMatch(\"123\")\r\n\r\n\r\n@active IsEven(x) begin\r\n    if x % 2 === 0\r\n        # use explicit `if-else` to emphasize the return should be true/false.\r\n        true\r\n    else\r\n        false\r\n    end\r\nend\r\n\r\n@match 4 begin\r\n    IsEven() => :even\r\n    _ => :odd\r\nend # :even\r\n\r\n@match 3 begin\r\n    IsEven() => :even\r\n    _ => :odd\r\nend # :oddNote that the pattern A{a, b, c} is equivalent to A{a, b, c}().When enabling the extension Enum with @use Enum, the pattern A is equivalent to A():@use Enum\r\n@match 4 begin\r\n    IsEven => :even\r\n    _ => :odd\r\nend # :even\r\n\r\n@match 3 begin\r\n    IsEven => :even\r\n    _ => :odd\r\nend # :oddFinally, you can customize the visibility of your own active patterns by giving it a qualifier."
},

{
    "location": "syntax/pattern/#Expr-Pattern-1",
    "page": "Pattern",
    "title": "Expr Pattern",
    "category": "section",
    "text": "This is mainly for AST manipulations. In fact, another pattern called Ast Pattern, would be translated into Expr Pattern.function extract_name(e)\r\n        @match e begin\r\n            ::Symbol                           => e\r\n            Expr(:<:, a, _)                    => extract_name(a)\r\n            Expr(:struct, _, name, _)          => extract_name(name)\r\n            Expr(:call, f, _...)               => extract_name(f)\r\n            Expr(:., subject, attr, _...)      => extract_name(subject)\r\n            Expr(:function, sig, _...)         => extract_name(sig)\r\n            Expr(:const, assn, _...)           => extract_name(assn)\r\n            Expr(:(=), fn, body, _...)         => extract_name(fn)\r\n            Expr(expr_type,  _...)             => error(\"Can\'t extract name from \",\r\n                                                        expr_type, \" expression:\\n\",\r\n                                                        \"    $e\\n\")\r\n        end\r\nend\r\n@assert extract_name(:(quote\r\n    function f()\r\n        1 + 1\r\n    end\r\nend)) == :f"
},

{
    "location": "syntax/pattern/#Ast-Pattern-1",
    "page": "Pattern",
    "title": "Ast Pattern",
    "category": "section",
    "text": "This might be the most important update since v0.2.rmlines = @λ begin\r\n    e :: Expr           -> Expr(e.head, filter(x -> x !== nothing, map(rmlines, e.args))...)\r\n      :: LineNumberNode -> nothing\r\n    a                   -> a\r\nend\r\nexpr = quote\r\n    struct S{T}\r\n        a :: Int\r\n        b :: T\r\n    end\r\nend |> rmlines\r\n\r\n@match expr begin\r\n    quote\r\n        struct $name{$tvar}\r\n            $f1 :: $t1\r\n            $f2 :: $t2\r\n        end\r\n    end =>\r\n    quote\r\n        struct $name{$tvar}\r\n            $f1 :: $t1\r\n            $f2 :: $t2\r\n        end\r\n    end |> rmlines == expr\r\nend # trueHow you create an AST, then how you match them.How you use AST interpolations($ operation), then how you use capturing patterns on them.The pattern quote .. end is equivalent to :(begin ... end).Additonally, you can use any other patterns simultaneously when matching asts. In fact, there\'re regular patterns inside a $ expression of your ast pattern.A more complex example presented here might help with your comprehension about this:ast = quote\r\n    function f(a, b, c, d)\r\n      let d = a + b + c, e = x -> 2x + d\r\n          e(d)\r\n      end\r\n    end\r\nend\r\n\r\n@match ast begin\r\n    quote\r\n        $(::LineNumberNode)\r\n\r\n        function $funcname(\r\n            $firstarg,\r\n            $(args...),\r\n            $(a && if islowercase(string(a)[1]) end))\r\n\r\n            $(::LineNumberNode)\r\n            let $bind_name = a + b + $last_operand, $(other_bindings...)\r\n                $(::LineNumberNode)\r\n                $app_fn($app_arg)\r\n                $(block1...)\r\n            end\r\n\r\n            $(block2...)\r\n        end\r\n    end && if (isempty(block1) && isempty(block2)) end =>\r\n\r\n         Dict(:funcname => funcname,\r\n              :firstarg => firstarg,\r\n              :args     => args,\r\n              :last_operand => last_operand,\r\n              :other_bindings => other_bindings,\r\n              :app_fn         => app_fn,\r\n              :app_arg        => app_arg)\r\nendHere is several articles about Ast Patterns.A Modern Way to Manipulate ASTs.An Elegant and Efficient Way to Extract Something from ASTs."
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
    "text": "Pattern function is a convenient way to define a function with multiple entries.f = @λ begin\r\n    # patterns here\r\n    x                  -> 1\r\n    ((x, (1, 2)) &&\r\n        if x > 3 end)  -> 5\r\n    (x, y)             -> 2\r\n    ::String           -> \"is string\"\r\n    _                  -> \"is any\"\r\nend\r\nf(1) # => 1\r\nf((4, (1, 2))) # => 5\r\nf((1, (1, 2))) # => 2\r\nf(\"\") # => \"is string\"Also, sometimes you might want to pass a single lambda which just matches the argument in one means:map((@λ [a, b, c...] -> c), [[1, 2, 3, 4], [1, 2]])\r\n# => 2-element Array{SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true},1}:\r\n#    [3, 4]\r\n#    []Functionally, A pattern function is no more than using a @match inside some anonymous function.\r\nfunction (x)\r\n    @match x begin\r\n        pat1 => body1\r\n        pat2 => body2\r\n    end\r\nend\r\n"
},

{
    "location": "syntax/when/#",
    "page": "When Destructuring",
    "title": "When Destructuring",
    "category": "page",
    "text": ""
},

{
    "location": "syntax/when/#When-Destructuring-1",
    "page": "When Destructuring",
    "title": "When Destructuring",
    "category": "section",
    "text": "The @when is introduced to work with the scenarios where @match is a bit heavy.It\'s similar to if-let construct in Rust language.There\'re two distinct syntaxes for @when."
},

{
    "location": "syntax/when/#Allow-Destructuring-in-Let-Binding-1",
    "page": "When Destructuring",
    "title": "Allow Destructuring in Let-Binding",
    "category": "section",
    "text": "tp = (2, 3)\r\nx = 2\r\n\r\n@assert 5 === \r\n    @when let (2, a) = tp,\r\n                  b  = x\r\n        a + b\r\n    end\r\n\r\n@assert nothing ===\r\n    @when let (2, a) = 1,\r\n                   b = x\r\n        a + b\r\n    endNote that only the binding formed as $a = $b would be treated as destructuring.@data S begin\r\n    S1(Int)\r\n    S2(Int)\r\nend\r\n\r\ns = S1(5)\r\n\r\n@assert 500 === \r\n    @when let S1(x) = s,\r\n              @inline fn(x) = 100x\r\n        fn(x)\r\n    endIn above snippet, @inline fn(x) = 100x is not regarded as destructuring."
},

{
    "location": "syntax/when/#Sole-Destructuring-1",
    "page": "When Destructuring",
    "title": "Sole Destructuring",
    "category": "section",
    "text": "However, a let-binding could be also heavy when you just want to solely destructure something.Finally, we allowed another syntax for @when.s = S1(5)\r\n@assert 5 === @when S1(x) = s x\r\n@assert 10 === @when S1(x) = s begin\r\n    2x\r\nend\r\n@assert nothing === @when S1(x) = S2(10) x"
},

{
    "location": "syntax/extension/#",
    "page": "MLStyle Extension List",
    "title": "MLStyle Extension List",
    "category": "page",
    "text": ""
},

{
    "location": "syntax/extension/#MLStyle-Extension-List-1",
    "page": "MLStyle Extension List",
    "title": "MLStyle Extension List",
    "category": "section",
    "text": ""
},

{
    "location": "syntax/extension/#GADT-1",
    "page": "MLStyle Extension List",
    "title": "GADT",
    "category": "section",
    "text": "Description: Introduce generic(and implicit) type variables in pattern matching when destructuring data types.\nConflicts: nothing\nExample:@use GADT\n\n@data S{G} begin\n    S1{T} :: T => S{G} where G\nend\n\nlet x :: S{String} = S1(2)\n    @match x begin\n        S1{T}(a) where T <: Number => show(a + 1)\n        _ => show(\"failed\")\n    end\nendoutputs3"
},

{
    "location": "syntax/extension/#UppercaseCapturing-1",
    "page": "MLStyle Extension List",
    "title": "UppercaseCapturing",
    "category": "section",
    "text": "Description: By default, uppercase symbols cannot be used as patterns for its ambiguous semantics. If you prefer capturing via uppercase symbols, use UppercaseCapturing.\nConflicts: Enum\nExample:@use UppercaseCapturing\n\n@match 1 begin\n    A => A + 1\nendoutputs:2"
},

{
    "location": "syntax/extension/#Enum-1",
    "page": "MLStyle Extension List",
    "title": "Enum",
    "category": "section",
    "text": "Description: By default, uppercase symbols cannot be used as patterns for its ambiguous semantics. If you prefer replacing patterns like S() with S, use Enum.Conflicts: UppercaseCapturing\nExample:@use Enum\n@data A begin\n    A1()\n    A2()\nend\n\n@match A1() begin\n    A1 => 1\n    _ => 2\nend\n# output: 1\n\n@active IsEven(x) begin\n    x % 2 === 0\nend\n@match 4 begin\n    IsEven => :ok\n    _ => :err\nend\n# output: :ok"
},

{
    "location": "syntax/qualifier/#",
    "page": "Pattern Scoping Qualifier",
    "title": "Pattern Scoping Qualifier",
    "category": "page",
    "text": ""
},

{
    "location": "syntax/qualifier/#Pattern-Scoping-Qualifier-1",
    "page": "Pattern Scoping Qualifier",
    "title": "Pattern Scoping Qualifier",
    "category": "section",
    "text": "To avoid scoping pollution, we introduce a mechanism to allow customizing a pattern\'s visibility.This is supported in the definitions of ADTs/GADTs and active patterns."
},

{
    "location": "syntax/qualifier/#Public-1",
    "page": "Pattern Scoping Qualifier",
    "title": "Public",
    "category": "section",
    "text": "Unless specified otherwise, all patterns are defined with a public qualifier.@data A begin\n    ...\nend\n@active B(x) begin\n    ...\nendAbove snippet is equivalent to@data public A begin\n    ...\nend\n@active public B(x) begin\n    ...\nendpublic means that the pattern is visible once it\'s imported into current scope."
},

{
    "location": "syntax/qualifier/#Internal-1",
    "page": "Pattern Scoping Qualifier",
    "title": "Internal",
    "category": "section",
    "text": "internal means that a pattern is only visible in the module it\'s defined in. In this situation, even if you export the pattern to other modules, it just won\'t work.module A\nusing MLStyle\nexport Data, Data1\n@data internal Data begin\n    Data1(Int)\nend\n\n@match Data1(2) begin\n    Data1(x) => @info x\nend\n\nmodule A2\n    using ..A\n    using MLStyle\n    @match Data1(2) begin\n        Data1(x) => @info x\n    end\nend\nendoutputs:[ Info: 2\nERROR: LoadError: MLStyle.Err.PatternUnsolvedException(\"invalid usage or unknown application case Main.A.Data1(Any[:x]).\")When it comes to active patterns, the behaviour is the same."
},

{
    "location": "syntax/qualifier/#Visible-In-1",
    "page": "Pattern Scoping Qualifier",
    "title": "Visible-In",
    "category": "section",
    "text": "Sometimes users need to have a more fine-grained control over the patterns\' visibility, thus we have provided such a way to allow patterns to be visible in several modules specified by one\'s own.@active visible in (@__MODULE__) IsEven(x) begin\n    x % 2 === 4\nendAbove IsEven is only visible in current module.@active visible in [MyPack.A, MyPack.B] IsEven(x) begin\n    x % 2 === 4\nendAbove IsEven is only visible in modules MyPack.A and MyPack.B."
},

{
    "location": "tutorials/capture/#",
    "page": "Static Capturing",
    "title": "Static Capturing",
    "category": "page",
    "text": ""
},

{
    "location": "tutorials/capture/#Static-Capturing-1",
    "page": "Static Capturing",
    "title": "Static Capturing",
    "category": "section",
    "text": "We know that MacroTools.jl has brought about a useful macro @capture to capture specific structures from a given AST.As the motivation of some contributors, @capture of MacroTools.jl has 3 following shortages.Use underscore to denote the structures to be captured, like struct typename_ field__ end, which makes you have to manually number the captured variables and not that readable or consistent.Cause Side-Effect. The captured variables are entered in current scope.Lack functionalities like conditional capturing.We can implement several new @capture via MLStyle.jl to get better in all aspects."
},

{
    "location": "tutorials/capture/#RAII-Style-1",
    "page": "Static Capturing",
    "title": "RAII-Style",
    "category": "section",
    "text": "This implementation prevents scope leaking.\r\nfunction capture(template, ex, action)\r\n    let template = Expr(:quote, template)\r\n        quote\r\n            @match $ex begin \r\n                $template => $action\r\n                _         => nothing\r\n            end\r\n        end \r\n    end\r\nend\r\n\r\nmacro capture(template, ex, action)\r\n    capture(template, ex, action) |> esc\r\nend\r\n\r\nnode = :(f(1))\r\n\r\n@capture f($(x :: T where T <: Number)) node begin\r\n    @info x + 1\r\nend\r\n\r\n# info: 2\r\n\r\nnode2 = :(f(x))\r\n\r\n@capture f($(x :: T where T <: Number)) node2 begin\r\n    @info x + 1\r\nend\r\n\r\n# do nothing"
},

{
    "location": "tutorials/capture/#Regex-Style-1",
    "page": "Static Capturing",
    "title": "Regex-Style",
    "category": "section",
    "text": "This implementation collects captured variables into a dictionary, just like groups in regex but more powerful.For we have to analyse which variables to be caught, this implementation could be a bit verbose(100 lines about scoping analysis) and might not work with your own patterns(application patterns/recognizers and active-patterns are okay).Check MLStyle-Playground for implementation codes.@info @capture f($x) :(f(1))\r\n# Dict(:x=>1)\r\n\r\ndestruct_fn = @capture function $(fname :: Symbol)(a, $(args...)) $(body...) end\r\n\r\n@info destruct_fn(:(\r\n    function f(a, x, y, z)\r\n        x + y + z\r\n    end\r\n))\r\n\r\n# Dict{Symbol,Any}(\r\n#     :args => Any[:x, :y, :z],\r\n#     :body=> Any[:(#= StaticallyCapturing.jl:93 =#), :(x + y + z)],\r\n#    :fname=>:f\r\n# )"
},

{
    "location": "tutorials/query-lang/#",
    "page": "Write You A Query Language",
    "title": "Write You A Query Language",
    "category": "page",
    "text": ""
},

{
    "location": "tutorials/query-lang/#Write-You-A-Query-Language-1",
    "page": "Write You A Query Language",
    "title": "Write You A Query Language",
    "category": "section",
    "text": "You may have heard of LINQ or extension methods before, and they\'re all embedded query langauges.In terms of Julia ecosystem, there\'re already Query.jl, LightQuery.jl, DataFramesMeta.jl, etc., each of which reaches the partial or full features of a query language.This document is provided for you to create a concise and efficient implementation of query language, which is a way for me to exhibit the power of MLStyle.jl on AST manipulations. Additionally, I think this tutorial can be also extremely helpful to those who\'re developing query languages for Julia."
},

{
    "location": "tutorials/query-lang/#Definition-of-Syntaxes-1",
    "page": "Write You A Query Language",
    "title": "Definition of Syntaxes",
    "category": "section",
    "text": "Firstly, we can refer to the the T-SQL syntax and, introduce it into Julia.df |>\n@select selectors...,\n@where predicates...,\n@groupby mappings...,\n@orderby mappings...,\n@having mappings...,\n@limit JuliaExpr\nA selector could be one of the following cases.select the field x / select the 1-fst field\n_.x / _.(1)select the field x(to support field name that\'re not an identifier)\n_.\"x\"\nselect an expression binded as x + _.x, where x is from current scope\nx + _.x\nselect something and bind it to symbol a\n<selector 1-3> => a / <selector 1-3> => \"a\"\nselect any field col that predicate1(col, args1...) && !predicate2(col, args2...) && ... is true\n_.(predicate1(args...), !predicate2(args2..., ),   ...)With E-BNF notation, we can formalize the synax,FieldPredicate ::= [\'!\'] QueryExpr \'(\' QueryExprList \')\' [\',\' FieldPredicate]\n\nField          ::= (Symbol | String | Int)\n\n\nQueryExpr      ::=  \'_\' \'.\' Field\n                  | <substitute QueryExpr in for JuliaExpr>\n\nQueryExprList  ::= [ QueryExpr (\',\' QueryExpr)* ]\n\nselector       ::= \'_\' \'.\' FieldPredicate\n                  | QueryExprA predicate is a QueryExpr, but should be evaluated to a boolean.A mapping  is a QueryExpr, but shouldn\'t be evaluated to a nothing.FYI, here\'re some valid instances about selector._.foo,\n_.1,\n_.(startswith(\"bar\"), !endswith(\"foo\")),\nx + _.foo,\nlet y = _.foo + y; y + _.(2) end"
},

{
    "location": "tutorials/query-lang/#Codegen-Target-1",
    "page": "Write You A Query Language",
    "title": "Codegen Target",
    "category": "section",
    "text": "Before implementing code generation, we should have a sketch about the target. The target here means the final shape of the code generated from a sequence of query clauses.I\'ll take you to the travel within the inference about the final shape of code generation.Firstly, for we want this:df |>\n@select _.foo + x, _.barWe can infer out that the generated code is an anonymous function which takes only one argument.Okay, cool. We\'ve known that the final shape of generated code should be:function (ARG)\n    # implementations\nendThen, let\'s think about the select clause. You might find it\'s a map(if we don\'t take aggregrate function into consideration). However, for we don\'t want to make redundant allocations when executing the queries, so we should use Base.Generator as the data representation.For @select _.foo + x, _.bar, it should be generated to something like((RECORD[:foo] + x, RECORD[:bar])   for RECORD in IN_SOURCE)Where IN_SOURCE is the data representation, RECORD is the record(row) of IN_SOURCE, and x is the variable captured by the closure.Now, a smart reader might observe that there\'s a trick for optimization! If we can have the actual indices of the fields foo and bar in the record(each row of IN_SOURCE), then they can be indexed via integers, which could avoid reflections in some degree.I don\'t have much knowledge about NamedTuple\'s implementation, but indexing via names on unknown datatypes cannot be faster than simply indexing via integers.So, the generated code of select could belet idx_of_foo = findfirst(==(:foo), IN_FIELDS),\n    idx_of_bar = findfirst(==(:bar), IN_FIELDS),\n    @inline FN(_foo, _bar) = (_foo + x, _bar)\n    (\n    let _foo = RECORD[idx_of_foo],\n        _bar = RECORD[idx_of_bar]\n        FN(_foo, _bar)\n    end\n    for RECORD in IN_SOURCE)\nend\nWhere we introduce a new requirement of the query\'s code generation, IN_FIELDS, which denotes the field names of IN_SOURCE.Now, to have a consistent code generation, let\'s think about stacked select clauses.df |>\n@select _, _.foo + 1, => foo1,\n# `select _` here means `SELECT *` in T-SQL.\n@select _.foo1 + 2 => foo2I don\'t know how to explain the iteration in my mind, but I\'ve figured out such a way.let (IN_FIELDS, IN_SOURCE) =\n    let (IN_FIELDS, IN_SOURCE) = process(df),\n        idx_of_foo = findfirst(==(:foo), IN_FIELDS),\n        @inline FN(_record, _foo) = (_record..., _foo + 1)\n        [IN_FIELDS..., :foo1],\n        (\n            let _foo = RECORD[idx_of_foo]\n                FN(RECORD, _foo)\n            end\n            for RECORD in IN_SOURCE\n        )\n    end,\n    idx_of_foo1 = findfirst(==(:foo1), IN_FIELDS),\n    @inline FN(_foo1) = (_foo1 + 2, )\n\n    [:foo2],\n    (\n        let _foo1 = RECORD[idx_of_foo1]\n            FN(_foo1)\n        end\n        for RECORD in IN_SOURCE\n    )\nendOh, perfect! I\'m so excited! That\'s so beautiful!If the output field names are a list of meta variables [:foo2], then output expression inside the comprehension should be a list of terms [foo2]. For foo2 = _.foo1 + 2 which is generated as RECORD[idx_of_foo1] + 2, so it comes into the shape of above code snippet.Let\'s think about the where clause.If we want this:df |>\n@where _.foo < 2That\'s similar to select:let (IN_FIELDS, IN_SOURCE) = process(df),\n    idx_of_foo = findfirst(==(:foo), IN_FIELDS)\n    IN_FIELDS,\n    (\n        RECORD for RECORD in SOURCE\n        if  let _foo = RECORD[idx_of_foo]\n                _foo < 2\n            end\n    )\nendObviously that where clauses generated in this way could be stacked.Next, it\'s the turn of groupby. It could be much more complex, for we should make it consistent with code generation for select and where.Let\'s think about the case below.df |>\n@groupby startswith(_.name, \"Ruby\")  => is_rubyYep, we want to group data frames(of course, any other datatypes that can be processed via this pipeline) by whether its field name starts with a string \"Ruby\" like, \"Ruby Rose\".Ha, I\'d like to use a dictionary here to store the groups.let IN_FIELDS, IN_SOURCE = process(df),\n    idx_of_name = findfirst(==(:name), IN_FIELDS),\n    @inline FN(_name) = (startswith(_.name, \"Ruby\"), )\n\n    GROUPS = Dict() # the type issues will be discussed later.\n    for RECORD in IN_SOURCE\n        _name = RECORD[idx_of_name]\n        GROUP_KEY = (is_ruby, ) = FN(_name)\n        AGGREGATES = get!(GROUPS, GROUP_KEY) do\n            Tuple([] for _ in IN_FIELDS)\n        end\n        push!.(AGGREGATES, RECORD)\n    end\n    # then output fields and source here\nendI think it perfect, so let\'s go ahead. The reason why we make an inline function would be given later, I\'d disclosed that it\'s for type inference.So, what should the output field names and the source be?An implementation is,IN_FIELDS, values(GROUPS)But if so, we will lose the information of group keys, which is not that good.So, if we want to persist the group keys, we can do this:[[:is_ruby]; IN_FIELDS], ((k..., v...) for (k, v) in GROUPS)I think the latter could be sufficiently powerful, although it might not be that efficient. You can have different implementations of groupby if you have more specific use cases, just use the extensible system which will be introduced later.So, the code generation of groupby could be:let IN_FIELDS, IN_SOURCE = process(df),\n    idx_of_name = findfirst(==(:name), IN_FIELDS),\n    @inline FN(_name) = (startswith(_.name, \"Ruby\"), )\n\n    GROUPS = Dict() # the type issues will be discussed later.\n    for RECORD in IN_SOURCE\n        _name = RECORD[idx_of_name]\n        GROUP_KEY = (is_ruby, ) = FN(_name)\n        AGGREGATES = get!(GROUPS, GROUP_KEY) do\n            Tuple([] for _ in IN_FIELDS)\n        end\n        push!.(AGGREGATES, RECORD)\n    end\n    [[:is_ruby]; IN_FIELDS], ((k..., v...) for (k, v) in GROUPS)\nend\nHowever, subsequently, we comes to the having clause, in fact, I\'d regard it as a sub-clause of groupby, which means it cannot take place indenpendently, but co-appear with a groupby clause.Given such a case:df |>\n@groupby startswith(_.name, \"Ruby\")  => is_ruby\n@having is_ruby || count(_.is_rose) > 5The generated code should be:let IN_FIELDS, IN_SOURCE = process(df),\n    idx_of_name = findfirst(==(:name), IN_FIELDS),\n    idx_of_is_rose = findfirst(==(:is_rose), IN_FIELDS)\n    @inline FN(_name) = (startswith(_name, \"Ruby\"), )\n\n    GROUPS = Dict() # the type issues will be discussed later.\n    for RECORD in IN_SOURCE\n        _name = RECORD[idx_of_name]\n        _is_rose = RECORD[idx_of_rose]\n        GROUP_KEY = (is_ruby, ) = GROUP_FN(RECORD)\n        if !(is_ruby || count(is_rose) > 5)\n            continue\n        end\n        AGGREGATES = get!(GROUPS, GROUP_KEY) do\n            Tuple([] for _ in IN_FIELDS)\n        end\n        push!.(AGGREGATES, RECORD)\n    end\n    [[:is_ruby]; IN_FIELDS], ((k..., v...) for (k, v) in GROUPS)\nendThe conditional code generation of groupby could be achieved very concisely via AST patterns of MLStyle, we\'ll refer to this later.After introducing the generation for above 4 clauses, orderby and limit then become quite trivial, and I don\'t want to repeat myself if not necessary.Now we know that mulitiple clauses could be generated to produce a Tuple result, first of which is the field names, the second is the lazy computation of the query. We can resume this tuple to the corresponding types, for instance,function (ARG :: DataFrame)\n    (IN_FIELDS, IN_SOURCE) = let IN_FIELDS, IN_SOURCE = ...\n        ...\n    end\n\n    res = Tuple([] for _ in IN_FIELDS)\n    for each in IN_SOURCE\n        push!.(res, each)\n    end\n    DataFrame(collect(res), IN_FIELDS)\nend"
},

{
    "location": "tutorials/query-lang/#Refinement-of-Codegen:-Typed-Columns-1",
    "page": "Write You A Query Language",
    "title": "Refinement of Codegen: Typed Columns",
    "category": "section",
    "text": "Last section introduce a framework of code generation for implementing query langauges, but in Julia, there\'s still a fatal problem.Look at the value to be return(when input is a DataFrame):res = Tuple([] for _ in IN_FIELDS)\nfor each in SOURCE\n    push!.(res, each)\nend\nDataFrame(collect(res), collect(IN_FIELDS))I can promise you that, each column of your data frames is a Vector{Any}, yes, not its actual type. You may prefer to calculate the type of a column using the common super type of all elements, but there\'re 2 problems if you try this:If the column is empty, emmmm...\nCalculating the super type of all elements causes unaffordable cost!Yet, I\'ll introduce a new requirement IN_TYPES of the query\'s code generation, which perfectly solves problems of column types.Let\'s have a look at code generation for select after introducing the IN_TYPES.Given that@select _, _.foo + 1\n# `@select _` is regarded as `SELECT *` in T-SQL.return_type(f, ts) =\n    let ts = Base.return_types(f, ts)\n        length(ts) === 1 ?\n            ts[1]        :\n            Union{ts...}\n    end\ntype_unpack(n, ::Type{Tuple{}}) = throw(\"error\")\ntype_unpack(n, ::Type{Tuple{T1}}) where T1 = [T1]\ntype_unpack(n, ::Type{Tuple{T1, T2}}) where {T1, T2} = [T1, T2]\n# type_unpack(::Type{Tuple{T1, T2, ...}}) where {T1, T2, ...} = [T1, T2, ...]\ntype_unpack(n, ::Type{Any}) = fill(Any, n)\n\nlet (IN_FIELDS, IN_TYPES, SOURCE) = process(df),\n    idx_of_foo = findfirst(==(:foo),  IN_FIELDS),\n    (@inline FN(_record, _foo) = (_record..., _foo)),\n    FN_OUT_FIELDS = [IN_FIELDS..., :foo1],\n    FN_OUT_TYPES = type_unpack(length(FN_OUT_FIELDS), return_type(Tuple{IN_TYPES...}, IN_TYPES[idx_of_foo]))\n\n    FN_OUT_FILEDS,\n    FN_OUT_TYPES,\n    (let _foo = RECORD[idx_of_foo]; FN(RECORD, _foo) end for RECORD in SOURCE)\nendFor groupby, it could be a bit more complex, but it does nothing new towards what select does. You can check the repo for codes."
},

{
    "location": "tutorials/query-lang/#Implementation-1",
    "page": "Write You A Query Language",
    "title": "Implementation",
    "category": "section",
    "text": "Firstly, we should define something like constants and helper functions.FYI, some constants and interfaces are defined at MQuery.ConstantNames.jl and MQuery.Interfaces.jl, you might want to refer to them if any unknown symbol prevents you from understanding this sketch.Then we should extract all clauses from a piece of given julia codes.Given following codes,@select args1,\n@where args2,\n@select args3, we transform them into[(generate_select, args), (generate_where, args2), (generate_select, args3)]function generate_select\nend\nfunction generate_where\nend\nfunction generate_groupby\nend\nfunction generate_orderby\nend\nfunction generate_having\nend\nfunction generate_limit\nend\n\nconst registered_ops = Dict{Symbol, Any}(\n    Symbol(\"@select\") => generate_select,\n    Symbol(\"@where\") => generate_where,\n    Symbol(\"@groupby\") => generate_groupby,\n    Symbol(\"@having\") => generate_having,\n    Symbol(\"@limit\") => generate_limit,\n    Symbol(\"@orderby\") => generate_orderby\n)\n\nfunction get_op(op_name)\n    registered_ops[op_name]\nend\n\nismacro(x :: Expr) = Meta.isexpr(x, :macrocall)\nismacro(_) = false\n\nfunction flatten_macros(node :: Expr)\n    @match node begin\n    Expr(:macrocall, op :: Symbol, ::LineNumberNode, arg) ||\n    Expr(:macrocall, op :: Symbol, arg) =>\n\n    @match arg begin\n    Expr(:tuple, args...) || a && Do(args = [a]) =>\n\n    @match args begin\n    [args..., tl && if ismacro(tl) end] => [(op |> get_op, args), flatten_macros(tl)...]\n    _ => [(op |> get_op, args)]\n    end\n    end\n    end\nendThe core is flatten_macros, it destructures macrocall expressions and then we can simply flatten the macrocalls.Next, we could have a common behaviour of code generation.\nstruct Field\n    name      :: Any    # an expr to represent the field name from IN_FIELDS.\n    make      :: Any    # an expression to assign the value into `var` like, `RECORD[idx_of_foo]`.\n    var       :: Symbol # a generated symbol via mangling\n    typ       :: Any    # an expression to get the type of the field like, `IN_TYPES[idx_of_foo]`.\nend\n\nfunction query_routine(assigns            :: OrderedDict{Symbol, Any},\n                       fn_in_fields       :: Vector{Field},\n                       fn_returns         :: Any,\n                       result; infer_type = true)\n    @assert haskey(assigns, FN_OUT_FIELDS)\n\n    fn_arguments = map(x -> x.var, fn_in_fields)\n    fn_arg_types = Expr(:vect, map(x -> x.typ, fn_in_fields)...)\n\n    function (inner_expr)\n        let_seq = [\n            Expr(:(=), Expr(:tuple, IN_FIELDS, IN_TYPES, IN_SOURCE), inner_expr),\n            (:($name = $value) for (name, value) in assigns)...,\n            :(@inline $FN($(fn_arguments...)) =  $fn_returns),\n        ]\n        if infer_type\n            let type_infer = :($FN_RETURN_TYPES = $type_unpack($length($FN_OUT_FIELDS, ), $return_type($FN, $fn_arg_types)))\n                push!(let_seq, type_infer)\n            end\n        end\n        Expr(:let,\n            Expr(\n                :block,\n                let_seq...\n            ),\n            result\n        )\n    end\nendIn fact, query_routine generates code likelet IN_FIELDS, IN_TYPES, IN_SOURCE = <inner query>,\n    idx_of_foo = ...,\n    idx_of_bar = ...,\n    @inline FN(x) = ...\n\n    ...\nendThen, we should generate the final code from such a sequence given as the return of flatten_macros.Note that get_records, get_fields and build_result should be implemented by your own to support datatypes that you want to query on.function codegen(node)\n    ops = flatten_macros(node)\n    let rec(vec) =\n        @match vec begin\n            [] => []\n            [(&generate_groupby, args1), (&generate_having, args2), tl...] =>\n                [generate_groupby(args1, args2), rec(tl)...]\n            [(hd, args), tl...] =>\n                [hd(args), rec(tl)...]\n        end\n        init = quote\n            let iter = $get_records($ARG),\n                fields = $get_fields($ARG),\n                types =$type_unpack($length(fields), $eltype(iter))\n                (fields, types, iter)\n            end\n        end\n        fn_body = foldl(rec(ops), init = init) do last, mk\n            mk(last)\n        end\n        quote\n            @inline function ($ARG :: $TYPE_ROOT, ) where {$TYPE_ROOT}\n                let ($IN_FIELDS, $IN_TYPES, $IN_SOURCE) = $fn_body\n                    $build_result(\n                        $TYPE_ROOT,\n                        $IN_FIELDS,\n                        $IN_TYPES,\n                        $IN_SOURCE\n                    )\n                end\n            end\n        end\n    end\nendThen, we need a visitor to transform the patterns shaped as _.foo inside an expression to a mangled symbol whose value is RECORD[idx_of_foo].# visitor to process the pattern `_.x, _,\"x\", _.(1)` inside an expression\nfunction mk_visit(fields :: Dict{Any, Field}, assigns :: OrderedDict{Symbol, Any})\n    visit = expr ->\n    @match expr begin\n        Expr(:. , :_, q :: QuoteNode) && Do(a = q.value) ||\n        Expr(:., :_, Expr(:tuple, a)) =>\n            @match a begin\n                a :: Int =>\n                    let field = get!(fields, a) do\n                            var_sym = gen_sym(a)\n                            Field(\n                                a,\n                                Expr(:ref, RECORD, a),\n                                var_sym,\n                                Expr(:ref, IN_TYPES, a)\n                            )\n                        end\n                        field.var\n                    end\n\n                ::String && Do(b = Symbol(a)) ||\n                b::Symbol =>\n                    let field = get!(fields, b) do\n                            idx_sym = gen_sym()\n                            var_sym = gen_sym(b)\n                            assigns[idx_sym] = Expr(:call, findfirst, x -> x === b, IN_FIELDS)\n                            Field(\n                                b,\n                                Expr(:ref, RECORD, idx_sym),\n                                var_sym,\n                                Expr(:ref, IN_TYPES, idx_sym)\n                            )\n                        end\n                        field.var\n                    end\n            end\n        Expr(head, args...) => Expr(head, map(visit, args)...)\n        a => a\n    end\nendYou might not be able to understand what the meanings of fields and assigns are, don\'t worry too much, and I\'m to explain it for you.fields : Dict{Any, Field}\nThink about you want such a query @select _.foo * 2, _.foo + 2, you can see that field foo is referred twice, but you shouldn\'t make 2 symbols to represent the index of foo field. So I introduce a dictionary fields here to   avoid re-calculation.\nassigns : OrderedDict{Any, Expr}\nWhen you want to bind the index of foo to a given symbol idx_of_foo, you should set an expressison $findfirst(==(:foo), $IN_FIELDS) to assigns on key idx_of_foo. The reason why we don\'t use a Vector{Expr} to represent assigns is, we can avoid re-assignments in some cases(you can find an instance in generate_groupby).\nFinally, assigns would be generated to the binding section of   a let sentence.Now, following previous discussions, we can firstly implement the easiest one, codegen method for where clause.function generate_where(args :: AbstractArray)\n    field_getted = Dict{Symbol, Symbol}()\n    assign       :: Vector{Any} = []\n    visit = mk_visit(field_getted, assign)\n\n    pred = foldl(args, init=true) do last, arg\n        boolean = visit(arg)\n        if last === true\n            boolean\n        else\n            Expr(:&&, last, boolean)\n        end\n    end\n\n    # where expression generation\n    query_routine(\n        assign,\n        Expr(:tuple,\n             IN_FIELDS,\n             TYPE,\n             :($RECORD for $RECORD in $SOURCE if $pred)\n        )\n    )\nendThen select:function generate_select(args :: AbstractArray)\n    map_in_fields = Dict{Any, Field}()\n    assigns = OrderedDict{Symbol, Any}()\n    fn_return_elts   :: Vector{Any} = []\n    fn_return_fields :: Vector{Any} = []\n    visit = mk_visit(map_in_fields, assigns)\n    # process selectors\n    predicate_process(arg) =\n        @match arg begin\n        :(!$pred($ (args...) )) && Do(ab=true)  ||\n        :($pred($ (args...) ))  && Do(ab=false) ||\n        :(!$pred) && Do(ab=true, args=[])       ||\n        :($pred)  && Do(ab=false, args=[])      =>\n            let idx_sym = gen_sym()\n                assigns[idx_sym] =\n                    Expr(\n                        :call,\n                        findall,\n                        ab ?\n                            :(@inline function ($ARG,) !$pred($string($ARG,), $(args...)) end) :\n                            :(@inline function ($ARG,) $pred($string($ARG,), $(args...)) end)\n                        , IN_FIELDS\n                    )\n                idx_sym\n            end\n        endfn_return_elts will be finally evaluated as the return of FN, while FN will be used to be generate the next IN_SOURCE with :(let ... ; $FN($args...) end for $RECORD in $SOURCE), while fn_retrun_fields will be finally used to generate the next IN_FIELDS with Expr(:vect, fn_return_fields...).Let\'s go ahead.    foreach(args) do arg\n        @match arg begin\n            :_ =>\n                let field = get!(map_in_fields, all) do\n                        var_sym = gen_sym()\n                        push!(fn_return_elts, Expr(:..., var_sym))\n                        push!(fn_return_fields, Expr(:..., IN_FIELDS))\n                        Field(\n                            all,\n                            RECORD,\n                            var_sym,\n                            :($Tuple{$IN_TYPES...})\n                        )\n                    end\n                    nothing\n                end\nWe\'ve said that @select _ here is equivalent to SELECT * in T-SQL.The remaining is also implemented with a concise case splitting via pattern matchings on ASTs.            :(_.($(args...))) =>\n                let indices = map(predicate_process, args)\n                    if haskey(map_in_fields, arg)\n                        throw(\"The columns `$(string(arg))` are selected twice!\")\n                    elseif !isempty(indices)\n                        idx_sym = gen_sym()\n                        var_sym = gen_sym()\n                        field = begin\n                            assigns[idx_sym] =\n                                length(indices) === 1 ?\n                                indices[1] :\n                                Expr(:call, intersect, indices...)\n                            push!(fn_return_elts, Expr(:..., var_sym))\n                            push!(fn_return_fields, Expr(:..., Expr(:ref, IN_FIELDS, idx_sym)))\n                            Field(\n                                arg,\n                                Expr(:ref, RECORD, idx_sym),\n                                var_sym,\n                                Expr(:curly, Tuple, Expr(:..., Expr(:ref, IN_TYPES, idx_sym)))\n                            )\n                        end\n                        map_in_fields[arg] = field\n                        nothing\n                    end\n                endAbove case is for handling with field filters, like @select _.(!startswith(\"Java\"), endswith(\"#\")).           :($a => $new_field) || a && Do(new_field = Symbol(string(a))) =>\n                let new_value = visit(a)\n                    push!(fn_return_fields, QuoteNode(new_field))\n                    push!(fn_return_elts, new_value)\n                    nothing\n                end\n        end\n    end\n\n    fields = map_in_fields |> values |> collect\n    assigns[FN_OUT_FIELDS] = Expr(:vect, fn_return_fields...)\n    # select expression generation\n    query_routine(\n        assigns,\n        fields,\n        Expr(:tuple, fn_return_elts...),\n        Expr(\n            :tuple,\n            FN_OUT_FIELDS,\n            FN_RETURN_TYPES,\n            :($(fn_apply(fields)) for $RECORD in $IN_SOURCE)\n        ); infer_type = true\n    )\nendAbove case is for handling with regular expressions which might contain something like _.x, _.(1) or _.\"is ruby\".Meanwhile, => allows you to alias the expression with the name you prefer. Note that, in terms of @select (_.foo => :a) => a, the first => is a normal infix operator, which denotes the built-in object Pair, but the second is alias.If you have problems with $ in AST patterns, just remember that, inside a quote ... end or :(...), ASTs/Expressions are compared by literal, except for $(...) things are matched via normal patterns, for instance, :($(a :: Symbol) = 1) can match :($a = 1) if the available variable a has type Symbol.With respect of groupby and having, they\'re too long to put in this article, so you might want to check them at MQuery.Impl.jl#L217."
},

{
    "location": "tutorials/query-lang/#Enjoy-You-A-Query-Language-1",
    "page": "Write You A Query Language",
    "title": "Enjoy You A Query Language",
    "category": "section",
    "text": "using Enums\n@enum TypeChecking Dynamic Static\n\ninclude(\"MQuery.jl\")\ndf = DataFrame(\n        Symbol(\"Type checking\") =>\n            [Dynamic, Static, Static, Dynamic, Static, Dynamic, Dynamic, Static],\n        :name =>\n            [\"Julia\", \"C#\", \"F#\", \"Ruby\", \"Java\", \"JavaScript\", \"Python\", \"Haskell\"]),\n        :year => [2012, 2000, 2005, 1995, 1995, 1995, 1990, 1990]\n)\n\ndf |>\n@where !startswith(_.name, \"Java\"),\n@groupby _.\"Type checking\" => TC, endswith(_.name, \"#\") => is_sharp,\n@having TC === Dynamic || is_sharp,\n@select join(_.name, \" and \") => result, _.TC => TC\noutputs2×2 DataFrame\n│ Row │ result                    │ TC        │\n│     │ String                    │ TypeChec… │\n├─────┼───────────────────────────┼───────────┤\n│ 1   │ Julia and Ruby and Python │ Dynamic   │\n│ 2   │ C# and F#                 │ Static    │"
},

]}
