Static-Capturing
================================

We know that `MacroTools.jl` has brought about a useful macro
`@capture` to capture specific structures from a given AST.

As the motivation of some contributors, `@capture` of `MacroTools.jl` has 3 following shortages.

- Use underscore to denote the structures to be captured, like
`struct typename_ field__ end`, which makes you have to manually number the captured variables and not that readable or consistent.

- Side-Effect. The captured variables are entered in current scope.



