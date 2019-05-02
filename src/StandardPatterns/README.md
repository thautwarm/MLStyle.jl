
There's an order among all those patterns' implementations, for some pattern might rely on an other.

1. TypeVarDecons.jl
    - description: provided with the capability of deconstructing type variables, thus we can match types.
    - no dependencies

2. Active.jl
    - description: provided with the capability of defining custom patterns easily with backward compatibilities.
    - dep(s): `TypeVarDecons.jl`

3. Uncomprehensions.jl
    - description: provided with the capability of deconstructing `Vector`(and more iterable types in the future) instances just as how they're constructed.
    - deps(s): `TypeVarDecons.jl`

