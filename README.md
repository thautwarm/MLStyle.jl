

MLStyle.jl
=========================

[![Build Status](https://travis-ci.org/thautwarm/MLStyle.jl.svg?branch=master)](https://travis-ci.org/thautwarm/MLStyle.jl)
[![codecov](https://codecov.io/gh/thautwarm/MLStyle.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thautwarm/MLStyle.jl)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/LICENSE)
[![Docs](https://img.shields.io/badge/docs-latest-orange.svg)](https://thautwarm.github.io/MLStyle.jl/latest/)

## Install
This package is registered. Please use the following command to install


### Install from REPL
type `]` in the Julia REPL to enter pkg mode

```julia
pkg> add MLStyle
```

### Install via other environment

```julia
using Pkg
Pkg.add("MLStyle")
```

To install the latest version of **MLStyle.jl**, please add its master branch

```julia
pkg> add MLStyle#master
```

To develop this package, please use `dev` command

```julia
pkg> dev MLStyle
```

## Extension

- About extending patterns for matching : [Examples to extend patterns](https://github.com/thautwarm/MLStyle.jl/blob/master/src/MatchExt.jl).

## Unfinished Features
- Numeric dependent types.
- Various monad utilities.
