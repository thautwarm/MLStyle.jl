
using MLStyle
Feature.@activate TypeLevel

@data 𝑀{𝑻} begin
    ϵ{𝑻}
    𝑪{𝑻}(𝒕 :: 𝑻)
end

@def (▷) begin
  ( ::ϵ{𝑻},   :: (𝑻 ⇒ 𝑀{𝑹})) => ϵ{𝑹}()
  (𝑪(𝒕::𝑻), 𝝀 :: (𝑻 ⇒ 𝑀{𝑹})) => 𝜆{𝑅}(𝒕)
end
