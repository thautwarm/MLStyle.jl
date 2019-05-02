module Uncomprehensions

using MLStyle
using MLStyle.MatchCore: mangle
using MLStyle.Infras: @format

def_pattern(Uncomprehensions,
    predicate = (x -> @match x begin
        :[$_ for $_ in $_ if $_] ||
        :[$_ for $_ in $_]    => true
        _                     => false
    end),
    rewrite = (tag, case, mod) -> begin
        @match case begin
            :[$expr for $iter in $seq if $cond]  ||
            :[$expr for $iter in $seq] && Do(cond=nothing) => begin
                function (body)
                    iter_var = mangle(mod)

                    # the name of element that'll be pushed to the result vector
                    produced_elt_var = mangle(mod)

                    inner_test_var = mangle(mod)
                    seq_var = mangle(mod)

                    # pattern is `expr`, return expr is `iter`
                    decons_elt = mk_pattern(iter_var, expr, mod)(iter)

                    # pattern is `seq`, return expr is `body`
                    decons_seq = mk_pattern(seq_var, seq, mod)(body)
                    @format [
                        seq_var, iter_var, inner_test_var, produced_elt_var,
                        body, tag, decons_elt, decons_seq, push!
                    ] quote
                        if tag isa Vector
                            let seq_var = [], inner_test_var = true
                                for iter_var in tag
                                    produced_elt_var = decons_elt
                                    if produced_elt_var === failed
                                        inner_test_var = false
                                        break
                                    end

                                    @static if $cond === nothing
                                        push!(seq_var, produced_elt_var)
                                    else
                                        if cond
                                            push!(seq_var, produced_elt_var)
                                        end
                                    end

                                end
                                if inner_test_var
                                    decons_seq
                                else
                                    failed
                                end
                            end
                        else
                            failed
                        end
                    end
                end
            end
        end
    end
)
end