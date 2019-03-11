module MatchCore
using MLStyle
using MLStyle.Toolz.List
using MLStyle.Err
using MLStyle.Render
export Failed, failed
struct Failed
end
const failed = Failed()
export Qualifier
Qualifier = Function
export internal, invasive, share_with, share_through
internal = ((my_mod, umod)->begin
            my_mod === umod
        end)
invasive = ((my_mod, umod)->begin
            true
        end)
share_with(ms::Set{Module}) = begin
        (_, umod)->begin
                umod in ms
            end
    end
export qualifier_test
function qualifier_test(qualifiers::Set{Qualifier}, use_mod, def_mod)
    any(qualifiers) do q
        q(def_mod, use_mod)
    end
end
export PDesc
struct PDesc
    predicate::Function
    rewrite::Function
    qualifiers::Set{Qualifier}
end
PDesc(; predicate, rewrite, qualifiers) = begin
        PDesc(predicate, rewrite, qualifiers)
    end
const PATTERNS = Vector{Tuple{Module, PDesc}}()
export register_pattern
function register_pattern(pdesc::PDesc, defmod::Module)
    push!(PATTERNS, (defmod, pdesc))
end
function get_pattern(case, use_mod::Module)
    for (def_mod, desc) = PATTERNS
        if qualifier_test(desc.qualifiers, use_mod, def_mod) && desc.predicate(case)
            return desc.rewrite
        end
    end
end
const INTERNAL_COUNTER = Dict{Module, Int}()
function remove_module_patterns(mod::Module)
    delete!(INTERNAL_COUNTER, mod)
end
function get_name_of_module(m::Module)::String
    string(m)
end
export mangle
function mangle(mod::Module)
    get!(INTERNAL_COUNTER, mod) do 
            0
        end |> (id->begin
                INTERNAL_COUNTER[mod] = id + 1
                mod_name = get_name_of_module(mod)
                gensym("$(mod_name) $(id)")
            end)
end
export gen_match, @match
begin
    macro match(target, cbl)
        gen_match(target, cbl, __source__, __module__) |> esc
    end
end
function gen_match(target, cbl, init_loc::LineNumberNode, mod::Module)
    branches = begin
            begin
                let _mangled_sym_417 = cbl
                    begin
                        _mangled_sym_418 = begin
                                function _mangled_sym_422(_mangled_sym_419::Expr)
                                    nothing
                                    Expr
                                    begin
                                        let (_mangled_sym_420, _mangled_sym_421) = ((_mangled_sym_419).head, (_mangled_sym_419).args)
                                            begin
                                                if (===)(_mangled_sym_420, :block)
                                                    function _mangled_sym_424(_mangled_sym_423::(AbstractArray){_mangled_sym_425, 1}) where _mangled_sym_425
                                                        nothing
                                                        begin
                                                            if (length)(_mangled_sym_423) >= 0
                                                                _mangled_sym_426 = view(_mangled_sym_423, 1:(length)(_mangled_sym_423) - 0)
                                                                begin
                                                                    let branches = _mangled_sym_426
                                                                        begin
                                                                            _mangled_sym_428 = true
                                                                            for _mangled_sym_427 = _mangled_sym_426
                                                                                if begin
                                                                                            _mangled_sym_441 = begin
                                                                                                    function _mangled_sym_432(_mangled_sym_429::Expr)
                                                                                                        nothing
                                                                                                        Expr
                                                                                                        begin
                                                                                                            let (_mangled_sym_430, _mangled_sym_431) = ((_mangled_sym_429).head, (_mangled_sym_429).args)
                                                                                                                begin
                                                                                                                    if (===)(_mangled_sym_430, :call)
                                                                                                                        function _mangled_sym_434(_mangled_sym_433::(AbstractArray){_mangled_sym_435, 1}) where _mangled_sym_435
                                                                                                                            nothing
                                                                                                                            begin
                                                                                                                                if (length)(_mangled_sym_433) === 3
                                                                                                                                    _mangled_sym_436 = _mangled_sym_433[1]
                                                                                                                                    begin
                                                                                                                                        if (===)(_mangled_sym_436, :(=>))
                                                                                                                                            _mangled_sym_437 = _mangled_sym_433[2]
                                                                                                                                            begin
                                                                                                                                                let a = _mangled_sym_437
                                                                                                                                                    begin
                                                                                                                                                        _mangled_sym_438 = _mangled_sym_433[3]
                                                                                                                                                        begin
                                                                                                                                                            let b = _mangled_sym_438
                                                                                                                                                                nothing
                                                                                                                                                            end
                                                                                                                                                        end
                                                                                                                                                    end
                                                                                                                                                end
                                                                                                                                            end
                                                                                                                                        else
                                                                                                                                            (MLStyle.MatchCore).failed
                                                                                                                                        end
                                                                                                                                    end
                                                                                                                                else
                                                                                                                                    (MLStyle.MatchCore).failed
                                                                                                                                end
                                                                                                                            end
                                                                                                                        end
                                                                                                                        function _mangled_sym_434(_)
                                                                                                                            nothing
                                                                                                                            (MLStyle.MatchCore).failed
                                                                                                                        end
                                                                                                                        _mangled_sym_434(_mangled_sym_431)
                                                                                                                    else
                                                                                                                        (MLStyle.MatchCore).failed
                                                                                                                    end
                                                                                                                end
                                                                                                            end
                                                                                                        end
                                                                                                    end
                                                                                                    function _mangled_sym_432(_mangled_sym_429)
                                                                                                        nothing
                                                                                                        (MLStyle.MatchCore).failed
                                                                                                    end
                                                                                                    _mangled_sym_432(_mangled_sym_427)
                                                                                                end
                                                                                            if _mangled_sym_441 === (MLStyle.MatchCore).failed
                                                                                                function _mangled_sym_440(_mangled_sym_439::LineNumberNode)
                                                                                                    nothing
                                                                                                    LineNumberNode
                                                                                                    nothing
                                                                                                end
                                                                                                function _mangled_sym_440(_mangled_sym_439)
                                                                                                    nothing
                                                                                                    (MLStyle.MatchCore).failed
                                                                                                end
                                                                                                _mangled_sym_440(_mangled_sym_427)
                                                                                            else
                                                                                                _mangled_sym_441
                                                                                            end
                                                                                        end !== nothing
                                                                                    _mangled_sym_428 = false
                                                                                    break
                                                                                end
                                                                            end
                                                                            if _mangled_sym_428
                                                                                branches
                                                                            else
                                                                                (MLStyle.MatchCore).failed
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            else
                                                                (MLStyle.MatchCore).failed
                                                            end
                                                        end
                                                    end
                                                    function _mangled_sym_424(_)
                                                        nothing
                                                        (MLStyle.MatchCore).failed
                                                    end
                                                    _mangled_sym_424(_mangled_sym_421)
                                                else
                                                    (MLStyle.MatchCore).failed
                                                end
                                            end
                                        end
                                    end
                                end
                                function _mangled_sym_422(_mangled_sym_419)
                                    nothing
                                    (MLStyle.MatchCore).failed
                                end
                                _mangled_sym_422(_mangled_sym_417)
                            end
                        if _mangled_sym_418 === (MLStyle.MatchCore).failed
                            _mangled_sym_418 = begin
                                    if (===)(_mangled_sym_417, :_)
                                        (throw)((SyntaxError)("Malformed syntax, expect `begin a => b; ... end` as match's branches."))
                                    else
                                        (MLStyle.MatchCore).failed
                                    end
                                end
                            if _mangled_sym_418 === (MLStyle.MatchCore).failed
                                (throw)((InternalException)("Non-exhaustive pattern found!"))
                            else
                                _mangled_sym_418
                            end
                        else
                            _mangled_sym_418
                        end
                    end
                end
            end
        end
    loc = init_loc
    branches_located = map(branches) do each
                begin
                    let _mangled_sym_442 = each
                        begin
                            _mangled_sym_443 = begin
                                    function _mangled_sym_449(_mangled_sym_446::Expr)
                                        nothing
                                        Expr
                                        begin
                                            let (_mangled_sym_447, _mangled_sym_448) = ((_mangled_sym_446).head, (_mangled_sym_446).args)
                                                begin
                                                    if (===)(_mangled_sym_447, :call)
                                                        function _mangled_sym_451(_mangled_sym_450::(AbstractArray){_mangled_sym_452, 1}) where _mangled_sym_452
                                                            nothing
                                                            begin
                                                                if (length)(_mangled_sym_450) === 3
                                                                    _mangled_sym_453 = _mangled_sym_450[1]
                                                                    begin
                                                                        if (===)(_mangled_sym_453, :(=>))
                                                                            _mangled_sym_454 = _mangled_sym_450[2]
                                                                            begin
                                                                                let pattern = _mangled_sym_454
                                                                                    begin
                                                                                        _mangled_sym_455 = _mangled_sym_450[3]
                                                                                        begin
                                                                                            let body = _mangled_sym_455
                                                                                                (pattern, body, loc)
                                                                                            end
                                                                                        end
                                                                                    end
                                                                                end
                                                                            end
                                                                        else
                                                                            (MLStyle.MatchCore).failed
                                                                        end
                                                                    end
                                                                else
                                                                    (MLStyle.MatchCore).failed
                                                                end
                                                            end
                                                        end
                                                        function _mangled_sym_451(_)
                                                            nothing
                                                            (MLStyle.MatchCore).failed
                                                        end
                                                        _mangled_sym_451(_mangled_sym_448)
                                                    else
                                                        (MLStyle.MatchCore).failed
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    function _mangled_sym_449(_mangled_sym_446)
                                        nothing
                                        (MLStyle.MatchCore).failed
                                    end
                                    _mangled_sym_449(_mangled_sym_442)
                                end
                            if _mangled_sym_443 === (MLStyle.MatchCore).failed
                                _mangled_sym_443 = begin
                                        function _mangled_sym_445(_mangled_sym_444::LineNumberNode)
                                            nothing
                                            LineNumberNode
                                            begin
                                                let curloc = _mangled_sym_444
                                                    begin
                                                        loc = curloc
                                                        nothing
                                                    end
                                                end
                                            end
                                        end
                                        function _mangled_sym_445(_mangled_sym_444)
                                            nothing
                                            (MLStyle.MatchCore).failed
                                        end
                                        _mangled_sym_445(_mangled_sym_442)
                                    end
                                if _mangled_sym_443 === (MLStyle.MatchCore).failed
                                    (throw)((InternalException)("Non-exhaustive pattern found!"))
                                else
                                    _mangled_sym_443
                                end
                            else
                                _mangled_sym_443
                            end
                        end
                    end
                end
            end |> (xs->begin
                    filter((x->begin
                                x !== nothing
                            end), xs)
                end)
    final = @format([init_loc, throw, InternalException], quote
                
                begin
                    init_loc
                    throw(InternalException("Non-exhaustive pattern found!"))
                end
            end)
    result = mangle(mod)
    tag_sym = mangle(mod)
    foldr(branches_located, init=final) do (pattern, body, loc), last
            expr = (mk_pattern(tag_sym, pattern, mod))(body)
            @format [result, expr, loc, MatchCore, last] quote
                    
                    begin
                        loc
                        result = expr
                        if result === $MatchCore.failed
                            last
                        else
                            result
                        end
                    end
                end
        end |> (main_logic->begin
                @format [tag_sym, target, main_logic] quote
                        
                        begin
                            let tag_sym = target
                                main_logic
                            end
                        end
                    end
            end)
end
export mk_pattern
function mk_pattern(tag_sym::Symbol, case::Any, mod::Module)
    rewrite = get_pattern(case, mod)
    if rewrite !== nothing
        return rewrite(tag_sym, case, mod)
    end
    case = string(case)
    throw $ PatternUnsolvedException("invalid usage or unknown case $(case)")
end
end