

MLStyle.jl
=========================

[![Build Status](https://travis-ci.org/thautwarm/MLStyle.jl.svg?branch=master)](https://travis-ci.org/thautwarm/MLStyle.jl)
[![codecov](https://codecov.io/gh/thautwarm/MLStyle.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thautwarm/MLStyle.jl)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/LICENSE)
[![Docs](https://img.shields.io/badge/docs-latest-orange.svg)](https://thautwarm.github.io/MLStyle.jl/latest/)

## Install

```julia
pkg> add MLStyle
```

## Preview

```julia
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

```

## Extension
- About extending patterns for matching : [Examples to extend patterns](https://github.com/thautwarm/MLStyle.jl/blob/master/src/MatchExt.jl).

## Unfinished Features
- Numeric dependent types.
- Various monad utilities.
