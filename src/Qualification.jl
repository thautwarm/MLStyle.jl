module Qualification
using MLStyle.MatchCore

export get_qualifier 
get_qualifier(node, mod) =
    @match node begin
        :public   => invasive
        :internal => internal
        :(visible in [$(mods...)]) => share_with(Set(map(mod.eval, mods)))
    end
end