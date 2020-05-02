# restore tagless final encoding from Core
export re_tagless

@nospecialize
function re_tagless(pi :: PatternInfo, ln :: Union{Nothing, LineNumberNode} = nothing)
    config = (type=pi.typetag, ln=ln)
    re_tagless(config, pi.pattern)
end

function re_tagless(config :: NamedTuple, p :: And)
    UserSitgnature.and([re_tagless(e) for e in p.ps], config)
end

function re_tagless(config :: NamedTuple, p::Or)
    UserSitgnature.or([re_tagless(e) for e in p.ps], config)
end

function re_tagless(config :: NamedTuple, p :: Literal)
    UserSitgnature.literal(p.val, config)
end

function re_tagless(config :: NamedTuple, p :: Wildcard)
    UserSitgnature.wildcard(config)
end

function re_tagless(config :: NamedTuple, p :: Deconstrucution)
    UserSitgnature.decons(p.comp::PComp, p.extract, [re_tagless(p) for p in p.params], config)
end

function re_tagless(config :: NamedTuple, p :: Guard)
    UserSitgnature.guard(p.predicate, config)
end

function re_tagless(config :: NamedTuple, p :: Effect)
    UserSitgnature.effect(p.perform, config)
end
@specialize