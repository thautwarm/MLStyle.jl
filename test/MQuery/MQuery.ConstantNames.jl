if isdefined(@__MODULE__, :DEBUG)
    MQuerySymbol(x...) = Symbol(join(["MQuery", x...], "_"))
else
    MQuerySymbol(x...) = Symbol(join(["MQuery", x...], "."))
end

ARG = MQuerySymbol("ARG") # we just need limited mangled symbols here.
TYPE_ROOT = MQuerySymbol("TYPE_ROOT")

IN_TYPES = MQuerySymbol("IN", "TYPES")
IN_FIELDS = MQuerySymbol("IN", "FIELDS")
IN_SOURCE = MQuerySymbol("IN", "SOURCE")

OUT_TYPES = MQuerySymbol("OUT", "TYPES")
OUT_FIELDS = MQuerySymbol("MQuery", "OUT.FIELDS")
OUT_SOURCE = MQuerySymbol("MQuery", "OUT.SOURCE")
RECORD = MQuerySymbol("RECORD")

N = MQuerySymbol("N")
GROUPS = MQuerySymbol("GROUPS")
GROUP_KEY = MQuerySymbol("GROUP_KEY")

FN = MQuerySymbol("FN")
FN_RETURN_TYPES = MQuerySymbol("FN", "RETURN_TYPES")
FN_OUT_FIELDS = MQuerySymbol("FN", "OUT_FIELDS")

AGG = MQuerySymbol("AGG")
AGG_TYPES = MQuerySymbol("AGG", "TYPES")

_gen_sym_count = 0
function gen_sym()
    global _gen_sym_count
    let sym = MQuerySymbol("TMP", _gen_sym_count)
        _gen_sym_count = _gen_sym_count  + 1
        sym
    end
end

function gen_sym(a :: Union{Symbol, Int, String})
    global _gen_sym_count
    MQuerySymbol("Symbol", a)
end