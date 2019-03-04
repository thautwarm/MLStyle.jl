module Qualification
using MLStyle.MatchCore
using MLStyle.Pervasives

export get_qualifier
get_qualifier(node, curmod) =
    @match node begin
        :public   => invasive
        :internal => internal
        :(visible in [$(mods...)]) ||
        :(visible in $mod) && Do(mods = [mod]) =>
            share_with(Set(map(curmod.eval, mods)))
    end
end