# -*- coding: utf-8 -*-
# Based on file here: https://bitbucket.org/natashawatkins/pygments-main/src/a893dbff5bfc4359d07d222bb9c3b4a0dec062bc/pygments/lexers/julia.py?fileviewer=file-view-default
"""
    pygments.lexers.julia
    ~~~~~~~~~~~~~~~~~~~~~
    Lexers for the Julia language.
    :copyright: Copyright 2006-2017 by the Pygments team, see AUTHORS.
    :license: BSD, see LICENSE for details.

    Me(thautwarm) Notes:
        The code is from https://github.com/sisl/pygments-julia
"""

import re

from pygments.lexer import Lexer, RegexLexer, bygroups, do_insertions, \
    words, include
from pygments.token import Text, Comment, Operator, Keyword, Name, String, \
    Number, Punctuation, Generic
from pygments.util import shebang_matches, unirange

__all__ = ['Julia1Lexer', 'Julia1ConsoleLexer']

allowed_variable = (
    u'(?:[a-zA-Z_\u00A1-\uffff]|%s)(?:[a-zA-Z_0-9\u00A1-\uffff]|%s)*!*' %
    ((unirange(0x10000, 0x10ffff),) * 2))

class Julia1Lexer(RegexLexer):
    """
    For `Julia <http://julialang.org/>`_ source code.
    """

    name = 'Julia'
    aliases = ['julia1', 'jl1']
    filenames = ['*.jl']
    mimetypes = ['text/x-julia', 'application/x-julia']

    flags = re.MULTILINE | re.UNICODE

    # builtins
    base_types = r'\b(?:AbstractArray|AbstractChannel|AbstractDict|AbstractDisplay|AbstractFloat|AbstractIrrational|AbstractMatrix|AbstractRNG|AbstractRange|AbstractSerializer|AbstractSet|AbstractSparseArray|AbstractSparseMatrix|AbstractSparseVector|AbstractString|AbstractUnitRange|AbstractVecOrMat|AbstractVector|Adjoint|Any|ArgumentError|Array|AssertionError|Bidiagonal|BigFloat|BigInt|BitArray|BitMatrix|BitSet|BitVector|Bool|BoundsError|BufferStream|CapturedException|CartesianIndex|CartesianIndices|Cchar|Cdouble|Cfloat|Channel|Char|Cint|Cintmax_t|Clong|Clonglong|Cmd|CodeInfo|Colon|Complex|ComplexF16|ComplexF32|ComplexF64|CompositeException|Condition|ConjArray|ConjMatrix|ConjVector|Cptrdiff_t|Cshort|Csize_t|Cssize_t|Cstring|Cuchar|Cuint|Cuintmax_t|Culong|Culonglong|Cushort|Cvoid|Cwchar_t|Cwstring|DataType|DenseArray|DenseMatrix|DenseVecOrMat|DenseVector|Diagonal|Dict|DimensionMismatch|Dims|DivideError|DomainError|EOFError|EachLine|Enum|Enumerate|ErrorException|Exception|ExponentialBackOff|Expr|Factorization|Float16|Float32|Float64|Function|GlobalRef|GotoNode|HTML|Hermitian|IO|IOBuffer|IOContext|IOStream|IPAddr|IPv4|IPv6|IndexCartesian|IndexLinear|IndexStyle|InexactError|InitError|Int|Int128|Int16|Int32|Int64|Int8|Integer|InterruptException|InvalidStateException|Irrational|KeyError|LabelNode|LinSpace|LineNumberNode|LinearIndices|LoadError|LowerTriangular|MIME|Matrix|MersenneTwister|Method|MethodError|MethodTable|Missing|MissingException|Module|NTuple|NamedTuple|NewvarNode|Nothing|Number|ObjectIdDict|OrdinalRange|OutOfMemoryError|OverflowError|Pair|PartialQuickSort|PermutedDimsArray|Pipe|Ptr|QuoteNode|RandomDevice|Rational|RawFD|ReadOnlyMemoryError|Real|ReentrantLock|Ref|Regex|RegexMatch|RoundingMode|RowVector|SSAValue|SegmentationFault|SerializationState|Set|Signed|SimpleVector|Slot|SlotNumber|Some|SparseMatrixCSC|SparseVector|StackFrame|StackOverflowError|StackTrace|StepRange|StepRangeLen|StridedArray|StridedMatrix|StridedVecOrMat|StridedVector|String|StringIndexError|SubArray|SubString|SymTridiagonal|Symbol|Symmetric|SystemError|TCPSocket|Task|Text|TextDisplay|Timer|Transpose|Tridiagonal|Tuple|Type|TypeError|TypeMapEntry|TypeMapLevel|TypeName|TypeVar|TypedSlot|UDPSocket|UInt|UInt128|UInt16|UInt32|UInt64|UInt8|UndefRefError|UndefVarError|UniformScaling|Uninitialized|Union|UnionAll|UnitRange|Unsigned|UpperTriangular|Val|Vararg|VecElement|VecOrMat|Vector|VersionNumber|WeakKeyDict|WeakRef|equalto)\b'
    base_funcs = r'(?:abs|abs2|abspath|accept|accumulate|accumulate!|acos|acos_fast|acosd|acosh|acosh_fast|acot|acotd|acoth|acsc|acscd|acsch|adjoint|adjoint!|all|all!|allunique|angle|angle_fast|any|any!|append!|apropos|ascii|asec|asecd|asech|asin|asin_fast|asind|asinh|asinh_fast|assert|asyncmap|asyncmap!|atan|atan2|atan2_fast|atan_fast|atand|atanh|atanh_fast|atexit|atreplinit|axes|backtrace|base|basename|beta|big|bin|bind|binomial|bitbroadcast|bitrand|bits|bitstring|bkfact|bkfact!|blkdiag|broadcast|broadcast!|broadcast_getindex|broadcast_setindex!|bswap|bytes2hex|cat|catch_backtrace|catch_stacktrace|cbrt|cbrt_fast|cd|ceil|cfunction|cglobal|charwidth|checkbounds|checkindex|chmod|chol|cholfact|cholfact!|chomp|chop|chown|chr2ind|circcopy!|circshift|circshift!|cis|cis_fast|clamp|clamp!|cld|clipboard|close|cmp|coalesce|code_llvm|code_lowered|code_native|code_typed|code_warntype|codeunit|codeunits|collect|colon|complex|cond|condskeel|conj|conj!|connect|consume|contains|convert|copy|copy!|copysign|copyto!|cor|cos|cos_fast|cosc|cosd|cosh|cosh_fast|cospi|cot|cotd|coth|count|count_ones|count_zeros|countlines|countnz|cov|cp|cross|csc|cscd|csch|ctime|ctranspose|ctranspose!|cummax|cummin|cumprod|cumprod!|cumsum|cumsum!|current_module|current_task|dec|deepcopy|deg2rad|delete!|deleteat!|den|denominator|deserialize|det|detach|diag|diagind|diagm|diff|digits|digits!|dirname|disable_sigint|display|displayable|displaysize|div|divrem|done|dot|download|dropzeros|dropzeros!|dump|eachindex|eachline|eachmatch|edit|eig|eigfact|eigfact!|eigmax|eigmin|eigvals|eigvals!|eigvecs|eltype|empty|empty!|endof|endswith|enumerate|eof|eps|equalto|error|esc|escape_string|evalfile|exit|exp|exp10|exp10_fast|exp2|exp2_fast|exp_fast|expand|expanduser|expm|expm!|expm1|expm1_fast|exponent|extrema|eye|factorial|factorize|falses|fd|fdio|fetch|fieldcount|fieldname|fieldnames|fieldoffset|filemode|filesize|fill|fill!|filter|filter!|finalize|finalizer|find|findfirst|findin|findlast|findmax|findmax!|findmin|findmin!|findn|findnext|findnz|findprev|first|fld|fld1|fldmod|fldmod1|flipbits!|flipdim|flipsign|float|floor|flush|fma|foldl|foldr|foreach|frexp|full|fullname|functionloc|gamma|gc|gc_enable|gcd|gcdx|gensym|get|get!|get_zero_subnormals|getaddrinfo|getalladdrinfo|gethostname|getindex|getipaddr|getkey|getnameinfo|getpeername|getpid|getsockname|givens|gperm|gradient|hash|haskey|hcat|hessfact|hessfact!|hex|hex2bytes|hex2bytes!|hex2num|homedir|htol|hton|hvcat|hypot|hypot_fast|identity|ifelse|ignorestatus|im|imag|in|include_dependency|include_string|ind2chr|ind2sub|indexin|indices|indmax|indmin|info|insert!|instances|intersect|intersect!|inv|invmod|invperm|invpermute!|ipermute!|ipermutedims|is|is_apple|is_bsd|is_linux|is_unix|is_windows|isabspath|isapprox|isascii|isassigned|isbits|isblockdev|ischardev|isconcrete|isconst|isdiag|isdir|isdirpath|isempty|isequal|iseven|isfifo|isfile|isfinite|ishermitian|isimag|isimmutable|isinf|isinteger|isinteractive|isleaftype|isless|islink|islocked|ismarked|ismatch|ismissing|ismount|isnan|isodd|isone|isopen|ispath|isperm|isposdef|isposdef!|ispow2|isqrt|isreadable|isreadonly|isready|isreal|issetgid|issetuid|issocket|issorted|issparse|issticky|issubnormal|issubset|issubtype|issymmetric|istaskdone|istaskstarted|istextmime|istril|istriu|isvalid|iswritable|iszero|join|joinpath|keys|keytype|kill|kron|last|lbeta|lcm|ldexp|ldltfact|ldltfact!|leading_ones|leading_zeros|length|less|lexcmp|lexless|lfact|lgamma|lgamma_fast|linearindices|linreg|linspace|listen|listenany|lock|log|log10|log10_fast|log1p|log1p_fast|log2|log2_fast|log_fast|logabsdet|logdet|logging|logm|logspace|lpad|lq|lqfact|lqfact!|lstat|lstrip|ltoh|lu|lufact|lufact!|lyap|macroexpand|map|map!|mapfoldl|mapfoldr|mapreduce|mapreducedim|mapslices|mark|match|matchall|max|max_fast|maxabs|maximum|maximum!|maxintfloat|mean|mean!|median|median!|merge|merge!|method_exists|methods|methodswith|middle|midpoints|mimewritable|min|min_fast|minabs|minimum|minimum!|minmax|minmax_fast|missing|mkdir|mkpath|mktemp|mktempdir|mod|mod1|mod2pi|modf|module_name|module_parent|mtime|muladd|mv|names|nb_available|ncodeunits|ndigits|ndims|next|nextfloat|nextind|nextpow|nextpow2|nextprod|nnz|nonzeros|norm|normalize|normalize!|normpath|notify|ntoh|ntuple|nullspace|num|num2hex|numerator|nzrange|object_id|oct|oftype|one|ones|oneunit|open|operm|ordschur|ordschur!|pairs|parent|parentindexes|parentindices|parse|partialsort|partialsort!|partialsortperm|partialsortperm!|peakflops|permute|permute!|permutedims|permutedims!|pi|pinv|pipeline|pointer|pointer_from_objref|pop!|popdisplay|popfirst!|position|pow_fast|powermod|precision|precompile|prepend!|prevfloat|prevind|prevpow|prevpow2|print|print_shortest|print_with_color|println|process_exited|process_running|prod|prod!|produce|promote|promote_rule|promote_shape|promote_type|push!|pushdisplay|pushfirst!|put!|pwd|qr|qrfact|qrfact!|quantile|quantile!|quit|rad2deg|rand|rand!|randcycle|randcycle!|randexp|randexp!|randjump|randn|randn!|randperm|randperm!|randstring|randsubseq|randsubseq!|range|rank|rationalize|read|read!|readandwrite|readavailable|readbytes!|readchomp|readdir|readline|readlines|readlink|readstring|readuntil|real|realmax|realmin|realpath|recv|recvfrom|redirect_stderr|redirect_stdin|redirect_stdout|redisplay|reduce|reducedim|reenable_sigint|reim|reinterpret|reload|relpath|rem|rem2pi|repeat|replace|replace!|repmat|repr|reprmime|reset|reshape|resize!|rethrow|retry|reverse|reverse!|reverseind|rm|rol|rol!|ror|ror!|rot180|rotl90|rotr90|round|rounding|rowvals|rpad|rsearch|rsearchindex|rsplit|rstrip|run|scale!|schedule|schur|schurfact|schurfact!|search|searchindex|searchsorted|searchsortedfirst|searchsortedlast|sec|secd|sech|seek|seekend|seekstart|select|select!|selectperm|selectperm!|send|serialize|set_zero_subnormals|setdiff|setdiff!|setenv|setindex!|setprecision|setrounding|shift!|show|showall|showcompact|showerror|shuffle|shuffle!|sign|signbit|signed|signif|significand|similar|sin|sin_fast|sinc|sincos|sind|sinh|sinh_fast|sinpi|size|sizehint!|sizeof|skip|skipchars|skipmissing|sleep|slicedim|sort|sort!|sortcols|sortperm|sortperm!|sortrows|sparse|sparsevec|spawn|spdiagm|speye|splice!|split|splitdir|splitdrive|splitext|spones|sprand|sprandn|sprint|spzeros|sqrt|sqrt_fast|sqrtm|squeeze|srand|stacktrace|start|startswith|stat|std|stdm|step|stride|strides|string|stringmime|strip|strwidth|sub2ind|subtypes|success|sum|sum!|sumabs|sumabs2|summary|supertype|svd|svdfact|svdfact!|svdvals|svdvals!|sylvester|symdiff|symdiff!|symlink|systemerror|take!|takebuf_array|takebuf_string|tan|tan_fast|tand|tanh|tanh_fast|task_local_storage|tempdir|tempname|thisind|tic|time|time_ns|timedwait|to_indices|toc|toq|touch|trace|trailing_ones|trailing_zeros|transcode|transpose|transpose!|tril|tril!|triu|triu!|trues|trunc|truncate|trylock|tryparse|typeintersect|typejoin|typemax|typemin|unescape_string|union|union!|unique|unique!|unlock|unmark|unsafe_copy!|unsafe_copyto!|unsafe_load|unsafe_pointer_to_objref|unsafe_read|unsafe_store!|unsafe_string|unsafe_trunc|unsafe_wrap|unsafe_write|unshift!|unsigned|uperm|valtype|values|var|varinfo|varm|vcat|vec|vecdot|vecnorm|versioninfo|view|wait|walkdir|warn|which|whos|widemul|widen|withenv|workspace|write|xor|yield|yieldto|zero|zeros|zip|applicable|eval|fieldtype|getfield|invoke|isa|isdefined|nfields|nothing|setfield!|throw|tuple|typeassert|typeof|uninitialized)(?=\()'
    base_modules = r'\b(?:BLAS|Base|Broadcast|DFT|Docs|Iterators|LAPACK|LibGit2|Libc|Libdl|LinAlg|Markdown|Meta|Operators|Pkg|Serializer|SparseArrays|StackTraces|Sys|Threads|Core|Main)\b'
    base_module_func = r'(?<!\.)(?:BLAS\.(?:asum|axpby!|axpy!|blascopy!|dot|dotc|dotu|gbmv|gbmv!|gemm|gemm!|gemv|gemv!|ger!|hemm|hemm!|hemv|hemv!|her!|her2k|her2k!|herk|herk!|iamax|nrm2|sbmv|sbmv!|scal|scal!|symm|symm!|symv|symv!|syr!|syr2k|syr2k!|syrk|syrk!|trmm|trmm!|trmv|trmv!|trsm|trsm!|trsv|trsv!)|Base\.(?:abs|abs2|abspath|accept|accumulate|accumulate!|acos|acos_fast|acosd|acosh|acosh_fast|acot|acotd|acoth|acsc|acscd|acsch|adjoint|adjoint!|all|all!|allunique|angle|angle_fast|any|any!|append!|apropos|ascii|asec|asecd|asech|asin|asin_fast|asind|asinh|asinh_fast|assert|asyncmap|asyncmap!|atan|atan2|atan2_fast|atan_fast|atand|atanh|atanh_fast|atexit|atreplinit|axes|backtrace|base|basename|beta|bfft|bfft!|big|bin|bind|binomial|bitbroadcast|bitrand|bits|bitstring|bkfact|bkfact!|blkdiag|brfft|broadcast|broadcast!|broadcast_getindex|broadcast_setindex!|bswap|bytes2hex|cat|catch_backtrace|catch_stacktrace|cbrt|cbrt_fast|cd|ceil|cfunction|cglobal|charwidth|checkbounds|checkindex|chmod|chol|cholfact|cholfact!|chomp|chop|chown|chr2ind|circcopy!|circshift|circshift!|cis|cis_fast|clamp|clamp!|cld|clipboard|close|cmp|coalesce|code_llvm|code_lowered|code_native|code_typed|code_warntype|codeunit|codeunits|collect|colon|complex|cond|condskeel|conj|conj!|connect|consume|contains|conv|conv2|convert|copy|copy!|copysign|copyto!|cor|cos|cos_fast|cosc|cosd|cosh|cosh_fast|cospi|cot|cotd|coth|count|count_ones|count_zeros|countlines|countnz|cov|cp|cross|csc|cscd|csch|ctime|ctranspose|ctranspose!|cummax|cummin|cumprod|cumprod!|cumsum|cumsum!|current_module|current_task|dct|dct!|dec|deconv|deepcopy|deg2rad|delete!|deleteat!|den|denominator|deserialize|det|detach|diag|diagind|diagm|diff|digits|digits!|dirname|disable_sigint|display|displayable|displaysize|div|divrem|done|dot|download|dropzeros|dropzeros!|dump|eachindex|eachline|eachmatch|edit|eig|eigfact|eigfact!|eigmax|eigmin|eigvals|eigvals!|eigvecs|eltype|empty|empty!|endof|endswith|enumerate|eof|eps|equalto|error|esc|escape_string|evalfile|exit|exp|exp10|exp10_fast|exp2|exp2_fast|exp_fast|expand|expanduser|expm|expm!|expm1|expm1_fast|exponent|extrema|eye|factorial|factorize|falses|fd|fdio|fetch|fft|fft!|fftshift|fieldcount|fieldname|fieldnames|fieldoffset|filemode|filesize|fill|fill!|filt|filt!|filter|filter!|finalize|finalizer|find|findfirst|findin|findlast|findmax|findmax!|findmin|findmin!|findn|findnext|findnz|findprev|first|fld|fld1|fldmod|fldmod1|flipbits!|flipdim|flipsign|float|floor|flush|fma|foldl|foldr|foreach|frexp|full|fullname|functionloc|gamma|gc|gc_enable|gcd|gcdx|gensym|get|get!|get_zero_subnormals|getaddrinfo|getalladdrinfo|gethostname|getindex|getipaddr|getkey|getnameinfo|getpeername|getpid|getsockname|givens|gperm|gradient|hash|haskey|hcat|hessfact|hessfact!|hex|hex2bytes|hex2bytes!|hex2num|homedir|htol|hton|hvcat|hypot|hypot_fast|idct|idct!|identity|ifelse|ifft|ifft!|ifftshift|ignorestatus|im|imag|in|include_dependency|include_string|ind2chr|ind2sub|indexin|indices|indmax|indmin|info|insert!|instances|intersect|intersect!|inv|invmod|invperm|invpermute!|ipermute!|ipermutedims|irfft|is|is_apple|is_bsd|is_linux|is_unix|is_windows|isabspath|isapprox|isascii|isassigned|isbits|isblockdev|ischardev|isconcrete|isconst|isdiag|isdir|isdirpath|isempty|isequal|iseven|isfifo|isfile|isfinite|ishermitian|isimag|isimmutable|isinf|isinteger|isinteractive|isleaftype|isless|islink|islocked|ismarked|ismatch|ismissing|ismount|isnan|isodd|isone|isopen|ispath|isperm|isposdef|isposdef!|ispow2|isqrt|isreadable|isreadonly|isready|isreal|issetgid|issetuid|issocket|issorted|issparse|issticky|issubnormal|issubset|issubtype|issymmetric|istaskdone|istaskstarted|istextmime|istril|istriu|isvalid|iswritable|iszero|join|joinpath|keys|keytype|kill|kron|last|lbeta|lcm|ldexp|ldltfact|ldltfact!|leading_ones|leading_zeros|length|less|lexcmp|lexless|lfact|lgamma|lgamma_fast|linearindices|linreg|linspace|listen|listenany|lock|log|log10|log10_fast|log1p|log1p_fast|log2|log2_fast|log_fast|logabsdet|logdet|logging|logm|logspace|lpad|lq|lqfact|lqfact!|lstat|lstrip|ltoh|lu|lufact|lufact!|lyap|macroexpand|map|map!|mapfoldl|mapfoldr|mapreduce|mapreducedim|mapslices|mark|match|matchall|max|max_fast|maxabs|maximum|maximum!|maxintfloat|mean|mean!|median|median!|merge|merge!|method_exists|methods|methodswith|middle|midpoints|mimewritable|min|min_fast|minabs|minimum|minimum!|minmax|minmax_fast|missing|mkdir|mkpath|mktemp|mktempdir|mod|mod1|mod2pi|modf|module_name|module_parent|mtime|muladd|mv|names|nb_available|ncodeunits|ndigits|ndims|next|nextfloat|nextind|nextpow|nextpow2|nextprod|nnz|nonzeros|norm|normalize|normalize!|normpath|notify|ntoh|ntuple|nullspace|num|num2hex|numerator|nzrange|object_id|oct|oftype|one|ones|oneunit|open|operm|ordschur|ordschur!|pairs|parent|parentindexes|parentindices|parse|partialsort|partialsort!|partialsortperm|partialsortperm!|peakflops|permute|permute!|permutedims|permutedims!|pi|pinv|pipeline|plan_bfft|plan_bfft!|plan_brfft|plan_dct|plan_dct!|plan_fft|plan_fft!|plan_idct|plan_idct!|plan_ifft|plan_ifft!|plan_irfft|plan_rfft|pointer|pointer_from_objref|pop!|popdisplay|popfirst!|position|pow_fast|powermod|precision|precompile|prepend!|prevfloat|prevind|prevpow|prevpow2|print|print_shortest|print_with_color|println|process_exited|process_running|prod|prod!|produce|promote|promote_rule|promote_shape|promote_type|push!|pushdisplay|pushfirst!|put!|pwd|qr|qrfact|qrfact!|quantile|quantile!|quit|rad2deg|rand|rand!|randcycle|randcycle!|randexp|randexp!|randjump|randn|randn!|randperm|randperm!|randstring|randsubseq|randsubseq!|range|rank|rationalize|read|read!|readandwrite|readavailable|readbytes!|readchomp|readdir|readline|readlines|readlink|readstring|readuntil|real|realmax|realmin|realpath|recv|recvfrom|redirect_stderr|redirect_stdin|redirect_stdout|redisplay|reduce|reducedim|reenable_sigint|reim|reinterpret|reload|relpath|rem|rem2pi|repeat|replace|replace!|repmat|repr|reprmime|reset|reshape|resize!|rethrow|retry|reverse|reverse!|reverseind|rfft|rm|rol|rol!|ror|ror!|rot180|rotl90|rotr90|round|rounding|rowvals|rpad|rsearch|rsearchindex|rsplit|rstrip|run|scale!|schedule|schur|schurfact|schurfact!|search|searchindex|searchsorted|searchsortedfirst|searchsortedlast|sec|secd|sech|seek|seekend|seekstart|select|select!|selectperm|selectperm!|send|serialize|set_zero_subnormals|setdiff|setdiff!|setenv|setindex!|setprecision|setrounding|shift!|show|showall|showcompact|showerror|shuffle|shuffle!|sign|signbit|signed|signif|significand|similar|sin|sin_fast|sinc|sincos|sind|sinh|sinh_fast|sinpi|size|sizehint!|sizeof|skip|skipchars|skipmissing|sleep|slicedim|sort|sort!|sortcols|sortperm|sortperm!|sortrows|sparse|sparsevec|spawn|spdiagm|speye|splice!|split|splitdir|splitdrive|splitext|spones|sprand|sprandn|sprint|spzeros|sqrt|sqrt_fast|sqrtm|squeeze|srand|stacktrace|start|startswith|stat|std|stdm|step|stride|strides|string|stringmime|strip|strwidth|sub2ind|subtypes|success|sum|sum!|sumabs|sumabs2|summary|super|supertype|svd|svdfact|svdfact!|svdvals|svdvals!|sylvester|symdiff|symdiff!|symlink|systemerror|take!|takebuf_array|takebuf_string|tan|tan_fast|tand|tanh|tanh_fast|task_local_storage|tempdir|tempname|thisind|tic|time|time_ns|timedwait|to_indices|toc|toq|touch|trace|trailing_ones|trailing_zeros|transcode|transpose|transpose!|tril|tril!|triu|triu!|trues|trunc|truncate|trylock|tryparse|typeintersect|typejoin|typemax|typemin|unescape_string|union|union!|unique|unique!|unlock|unmark|unsafe_copy!|unsafe_copyto!|unsafe_load|unsafe_pointer_to_objref|unsafe_read|unsafe_store!|unsafe_string|unsafe_trunc|unsafe_wrap|unsafe_write|unshift!|unsigned|uperm|valtype|values|var|varinfo|varm|vcat|vec|vecdot|vecnorm|versioninfo|view|wait|walkdir|warn|which|whos|widemul|widen|withenv|workspace|write|xcorr|xor|yield|yieldto|zero|zeros|zip)|Broadcast\.(?:broadcast_getindex|broadcast_indices|broadcast_setindex!|broadcast_similar|dotview)|DFT\.(?:)|Docs\.(?:apropos|doc)|Iterators\.(?:countfrom|cycle|drop|enumerate|flatten|partition|product|repeated|rest|take|zip)|LAPACK\.(?:)|LibGit2\.(?:get_creds!|with)|Libc\.(?:calloc|errno|flush_cstdio|free|gethostname|getpid|malloc|realloc|strerror|strftime|strptime|systemsleep|time|transcode)|Libdl\.(?:dlclose|dlext|dllist|dlopen|dlopen_e|dlpath|dlsym|dlsym_e|find_library)|LinAlg\.(?:adjoint|adjoint!|axpby!|axpy!|bkfact|bkfact!|chol|cholfact|cholfact!|cond|condskeel|copy_transpose!|copyto!|cross|det|diag|diagind|diagm|diff|dot|eig|eigfact|eigfact!|eigmax|eigmin|eigvals|eigvals!|eigvecs|factorize|getq|givens|gradient|hessfact|hessfact!|isdiag|ishermitian|isposdef|isposdef!|issuccess|issymmetric|istril|istriu|kron|ldltfact|ldltfact!|linreg|logabsdet|logdet|lq|lqfact|lqfact!|lu|lufact|lufact!|lyap|norm|normalize|normalize!|nullspace|ordschur|ordschur!|peakflops|pinv|qr|qrfact|qrfact!|rank|scale!|schur|schurfact|schurfact!|svd|svdfact|svdfact!|svdvals|svdvals!|sylvester|trace|transpose|transpose!|transpose_type|tril|tril!|triu|triu!|vecdot|vecnorm)|Markdown\.(?:html|latex|license|readme)|Meta\.(?:isexpr|quot|show_sexpr)|Operators\.(?:)|Pkg\.(?:add|available|build|checkout|clone|dir|free|init|installed|pin|resolve|rm|setprotocol!|status|test|update)|Serializer\.(?:deserialize|serialize)|SparseArrays\.(?:blkdiag|droptol!|dropzeros|dropzeros!|issparse|nnz|nonzeros|nzrange|permute|rowvals|sparse|sparsevec|spdiagm|spones|sprand|sprandn|spzeros)|StackTraces\.(?:catch_stacktrace|stacktrace)|Sys\.(?:cpu_info|cpu_summary|free_memory|isapple|isbsd|islinux|isunix|iswindows|loadavg|total_memory|uptime)|Threads\.(?:atomic_add!|atomic_and!|atomic_cas!|atomic_fence|atomic_max!|atomic_min!|atomic_nand!|atomic_or!|atomic_sub!|atomic_xchg!|atomic_xor!|nthreads|threadid)|Core\.(?:applicable|eval|fieldtype|getfield|invoke|isa|isdefined|nfields|nothing|setfield!|throw|tuple|typeassert|typeof|uninitialized))'

    # symbols
    symb_op_unicode = r'[≤≥¬←→↔↚↛↠↣↦↮⇎⇏⇒⇔⇴⇶⇷⇸⇹⇺⇻⇼⇽⇾⇿⟵⟶⟷⟷⟹⟺⟻⟼⟽⟾⟿⤀⤁⤂⤃⤄⤅⤆⤇⤌⤍⤎⤏⤐⤑⤔⤕⤖⤗⤘⤝⤞⤟⤠⥄⥅⥆⥇⥈⥊⥋⥎⥐⥒⥓⥖⥗⥚⥛⥞⥟⥢⥤⥦⥧⥨⥩⥪⥫⥬⥭⥰⧴⬱⬰⬲⬳⬴⬵⬶⬷⬸⬹⬺⬻⬼⬽⬾⬿⭀⭁⭂⭃⭄⭇⭈⭉⭊⭋⭌￩￫≡≠≢∈∉∋∌⊆⊈⊂⊄⊊∝∊∍∥∦∷∺∻∽∾≁≃≄≅≆≇≈≉≊≋≌≍≎≐≑≒≓≔≕≖≗≘≙≚≛≜≝≞≟≣≦≧≨≩≪≫≬≭≮≯≰≱≲≳≴≵≶≷≸≹≺≻≼≽≾≿⊀⊁⊃⊅⊇⊉⊋⊏⊐⊑⊒⊜⊩⊬⊮⊰⊱⊲⊳⊴⊵⊶⊷⋍⋐⋑⋕⋖⋗⋘⋙⋚⋛⋜⋝⋞⋟⋠⋡⋢⋣⋤⋥⋦⋧⋨⋩⋪⋫⋬⋭⋲⋳⋴⋵⋶⋷⋸⋹⋺⋻⋼⋽⋾⋿⟈⟉⟒⦷⧀⧁⧡⧣⧤⧥⩦⩧⩪⩫⩬⩭⩮⩯⩰⩱⩲⩳⩴⩵⩶⩷⩸⩹⩺⩻⩼⩽⩾⩿⪀⪁⪂⪃⪄⪅⪆⪇⪈⪉⪊⪋⪌⪍⪎⪏⪐⪑⪒⪓⪔⪕⪖⪗⪘⪙⪚⪛⪜⪝⪞⪟⪠⪡⪢⪣⪤⪥⪦⪧⪨⪩⪪⪫⪬⪭⪮⪯⪰⪱⪲⪳⪴⪵⪶⪷⪸⪹⪺⪻⪼⪽⪾⪿⫀⫁⫂⫃⫄⫅⫆⫇⫈⫉⫊⫋⫌⫍⫎⫏⫐⫑⫒⫓⫔⫕⫖⫗⫘⫙⫷⫸⫹⫺⊢⊣⊕⊖⊞⊟∪∨⊔±∓∔∸≂≏⊎⊻⊽⋎⋓⧺⧻⨈⨢⨣⨤⨥⨦⨧⨨⨩⨪⨫⨬⨭⨮⨹⨺⩁⩂⩅⩊⩌⩏⩐⩒⩔⩖⩗⩛⩝⩡⩢⩣÷⋅∘×∩∧⊗⊘⊙⊚⊛⊠⊡⊓∗∙∤⅋≀⊼⋄⋆⋇⋉⋊⋋⋌⋏⋒⟑⦸⦼⦾⦿⧶⧷⨇⨰⨱⨲⨳⨴⨵⨶⨷⨸⨻⨼⨽⩀⩃⩄⩋⩍⩎⩑⩓⩕⩘⩚⩜⩞⩟⩠⫛⊍▷⨝⟕⟖⟗↑↓⇵⟰⟱⤈⤉⤊⤋⤒⤓⥉⥌⥍⥏⥑⥔⥕⥘⥙⥜⥝⥠⥡⥣⥥⥮⥯￪￬]'
    symb_op_ascii = r'[-+*/\\=^:<>~?&$%|!]'
    symb_op = r'(?:[-+*/\\=^:<>~?&$%|!]|[≤≥¬←→↔↚↛↠↣↦↮⇎⇏⇒⇔⇴⇶⇷⇸⇹⇺⇻⇼⇽⇾⇿⟵⟶⟷⟷⟹⟺⟻⟼⟽⟾⟿⤀⤁⤂⤃⤄⤅⤆⤇⤌⤍⤎⤏⤐⤑⤔⤕⤖⤗⤘⤝⤞⤟⤠⥄⥅⥆⥇⥈⥊⥋⥎⥐⥒⥓⥖⥗⥚⥛⥞⥟⥢⥤⥦⥧⥨⥩⥪⥫⥬⥭⥰⧴⬱⬰⬲⬳⬴⬵⬶⬷⬸⬹⬺⬻⬼⬽⬾⬿⭀⭁⭂⭃⭄⭇⭈⭉⭊⭋⭌￩￫≡≠≢∈∉∋∌⊆⊈⊂⊄⊊∝∊∍‖∥∦∷∺∻∽∾≁≃≄≅≆≇≈≉≊≋≌≍≎≐≑≒≓≔≕≖≗≘≙≚≛≜≝≞≟≣≦≧≨≩≪≫≬≭≮≯≰≱≲≳≴≵≶≷≸≹≺≻≼≽≾≿⊀⊁⊃⊅⊇⊉⊋⊏⊐⊑⊒⊜⊩⊬⊮⊰⊱⊲⊳⊴⊵⊶⊷⋍⋐⋑⋕⋖⋗⋘⋙⋚⋛⋜⋝⋞⋟⋠⋡⋢⋣⋤⋥⋦⋧⋨⋩⋪⋫⋬⋭⋲⋳⋴⋵⋶⋷⋸⋹⋺⋻⋼⋽⋾⋿⟈⟉⟒⦷⧀⧁⧡⧣⧤⧥⩦⩧⩪⩫⩬⩭⩮⩯⩰⩱⩲⩳⩴⩵⩶⩷⩸⩹⩺⩻⩼⩽⩾⩿⪀⪁⪂⪃⪄⪅⪆⪇⪈⪉⪊⪋⪌⪍⪎⪏⪐⪑⪒⪓⪔⪕⪖⪗⪘⪙⪚⪛⪜⪝⪞⪟⪠⪡⪢⪣⪤⪥⪦⪧⪨⪩⪪⪫⪬⪭⪮⪯⪰⪱⪲⪳⪴⪵⪶⪷⪸⪹⪺⪻⪼⪽⪾⪿⫀⫁⫂⫃⫄⫅⫆⫇⫈⫉⫊⫋⫌⫍⫎⫏⫐⫑⫒⫓⫔⫕⫖⫗⫘⫙⫷⫸⫹⫺⊢⊣⊕⊖⊞⊟∪∨⊔±∓∔∸≂≏⊎⊻⊽⋎⋓⧺⧻⨈⨢⨣⨤⨥⨦⨧⨨⨩⨪⨫⨬⨭⨮⨹⨺⩁⩂⩅⩊⩌⩏⩐⩒⩔⩖⩗⩛⩝⩡⩢⩣÷⋅∘×∩∧⊗⊘⊙⊚⊛⊠⊡⊓∗∙∤⅋≀⊼⋄⋆⋇⋉⋊⋋⋌⋏⋒⟑⦸⦼⦾⦿⧶⧷⨇⨰⨱⨲⨳⨴⨵⨶⨷⨸⨻⨼⨽⩀⩃⩄⩋⩍⩎⩑⩓⩕⩘⩚⩜⩞⩟⩠⫛⊍▷⨝⟕⟖⟗↑↓⇵⟰⟱⤈⤉⤊⤋⤒⤓⥉⥌⥍⥏⥑⥔⥕⥘⥙⥜⥝⥠⥡⥣⥥⥮⥯￪￬])'
    symb_lang = r'(?:[(){}\[\],.;:\'"`@#])'
    symb_id = r'((?:[^\s(?:[(){}\[\],.;:\'"`@#])(?:[-+*/\\=^:<>~?&$%|!])|([≤≥¬←→↔↚↛↠↣↦↮⇎⇏⇒⇔⇴⇶⇷⇸⇹⇺⇻⇼⇽⇾⇿⟵⟶⟷⟷⟹⟺⟻⟼⟽⟾⟿⤀⤁⤂⤃⤄⤅⤆⤇⤌⤍⤎⤏⤐⤑⤔⤕⤖⤗⤘⤝⤞⤟⤠⥄⥅⥆⥇⥈⥊⥋⥎⥐⥒⥓⥖⥗⥚⥛⥞⥟⥢⥤⥦⥧⥨⥩⥪⥫⥬⥭⥰⧴⬱⬰⬲⬳⬴⬵⬶⬷⬸⬹⬺⬻⬼⬽⬾⬿⭀⭁⭂⭃⭄⭇⭈⭉⭊⭋⭌￩￫≡≠≢∈∉∋∌⊆⊈⊂⊄⊊∝∊∍∥∦∷∺∻∽∾≁≃≄≅≆≇≈≉≊≋≌≍≎≐≑≒≓≔≕≖≗≘≙≚≛≜≝≞≟≣≦≧≨≩≪≫≬≭≮≯≰≱≲≳≴≵≶≷≸≹≺≻≼≽≾≿⊀⊁⊃⊅⊇⊉⊋⊏⊐⊑⊒⊜⊩⊬⊮⊰⊱⊲⊳⊴⊵⊶⊷⋍⋐⋑⋕⋖⋗⋘⋙⋚⋛⋜⋝⋞⋟⋠⋡⋢⋣⋤⋥⋦⋧⋨⋩⋪⋫⋬⋭⋲⋳⋴⋵⋶⋷⋸⋹⋺⋻⋼⋽⋾⋿⟈⟉⟒⦷⧀⧁⧡⧣⧤⧥⩦⩧⩪⩫⩬⩭⩮⩯⩰⩱⩲⩳⩴⩵⩶⩷⩸⩹⩺⩻⩼⩽⩾⩿⪀⪁⪂⪃⪄⪅⪆⪇⪈⪉⪊⪋⪌⪍⪎⪏⪐⪑⪒⪓⪔⪕⪖⪗⪘⪙⪚⪛⪜⪝⪞⪟⪠⪡⪢⪣⪤⪥⪦⪧⪨⪩⪪⪫⪬⪭⪮⪯⪰⪱⪲⪳⪴⪵⪶⪷⪸⪹⪺⪻⪼⪽⪾⪿⫀⫁⫂⫃⫄⫅⫆⫇⫈⫉⫊⫋⫌⫍⫎⫏⫐⫑⫒⫓⫔⫕⫖⫗⫘⫙⫷⫸⫹⫺⊢⊣⊕⊖⊞⊟∪∨⊔±∓∔∸≂≏⊎⊻⊽⋎⋓⧺⧻⨈⨢⨣⨤⨥⨦⨧⨨⨩⨪⨫⨬⨭⨮⨹⨺⩁⩂⩅⩊⩌⩏⩐⩒⩔⩖⩗⩛⩝⩡⩢⩣÷⋅∘×∩∧⊗⊘⊙⊚⊛⊠⊡⊓∗∙∤⅋≀⊼⋄⋆⋇⋉⋊⋋⋌⋏⋒⟑⦸⦼⦾⦿⧶⧷⨇⨰⨱⨲⨳⨴⨵⨶⨷⨸⨻⨼⨽⩀⩃⩄⩋⩍⩎⩑⩓⩕⩘⩚⩜⩞⩟⩠⫛⊍▷⨝⟕⟖⟗↑↓⇵⟰⟱⤈⤉⤊⤋⤒⤓⥉⥌⥍⥏⥑⥔⥕⥘⥙⥜⥝⥠⥡⥣⥥⥮⥯￪￬])])'

    # Multi-character operators
    long_op = r'(?:\+=|-=|\*=|/=|//=|\\\\=|^=|÷=|%=|<<=|>>=|>>>=|\|=|&=|:=|=>|$=|\|\||&&|<:|>:|\|>|<\||//|\+\+|<=|>=|->|===|==|!==|!=)'

    # numbers
    numbers = r'[0123456789]'

    tokens = {

        'root': [
            # text
            (r'\n', Text),
            (r'[^\S\n]+', Text),

            # comments
            (r'#=', Comment.Multiline, "blockcomment"),
            (r'#.*$', Comment),

            # array indexing
            (r'([\[])',  Punctuation, "index"),

            # punctuation symbols
            (r'[\[\]{}(),;.]', Punctuation),

            # literals
            (r'\b(true|false|nothing|missing|im|uninitialized|NaN|NaN16|NaN32|NaN64|Inf|Inf16|Inf32|Inf64|ARGS|C_NULL|ENDIAN_BOM|ENV|LOAD_PATH|PROGRAM_FILE|STDERR|STDIN|STDOUT|VERSION)\b', Keyword),
            (numbers, Number),

            # keywords
            (r'(true|false)\b', Keyword.Constant),
            (r'\b(mutable|immutable|struct|begin|end|function|macro|quote|let|local|global|const|abstract|module|baremodule|using|import|export|in)\b', Keyword),
            (r'\b(if|else|elseif|for|while|do|try|catch|finally|return|break|continue)\b', Keyword),
            (words([
                u'ARGS', u'CPU_CORES', u'C_NULL', u'DevNull', u'ENDIAN_BOM',
                u'ENV', u'I', u'Inf', u'Inf16', u'Inf32', u'Inf64',
                u'InsertionSort', u'JULIA_HOME', u'LOAD_PATH', u'MergeSort',
                u'NaN', u'NaN16', u'NaN32', u'NaN64', u'OS_NAME',
                u'QuickSort', u'RoundDown', u'RoundFromZero', u'RoundNearest',
                u'RoundNearestTiesAway', u'RoundNearestTiesUp',
                u'RoundToZero', u'RoundUp', u'STDERR', u'STDIN', u'STDOUT',
                u'VERSION', u'WORD_SIZE', u'catalan', u'eu',
                u'eulergamma', u'golden', u'im', u'nothing',
                ],
                suffix=r'\b'), Keyword.Reserved),
            (r'julia>', Generic.Prompt),
            # built ins
            (base_types, Name.Builtin),
            (base_funcs, Name.Builtin),
            (r'(?<!\.)' + base_modules, Name.Builtin),
            (base_module_func, Name.Builtin),

            # regular functions
            (r'\b(?:(' + allowed_variable + r')(?=\())', Name.Function),

            # anonymous functions
            (r'(' + symb_id + r'+)\s*(->)', bygroups(Name.Variable, Operator)),

            # operators
            # see: https://github.com/JuliaLang/julia/blob/master/src/julia-parser.scm
            (r'(\.?)(' + long_op + r')', Operator),
            (r'(\.?)(=)', Operator),
            (symb_op_ascii, Operator),
            (symb_op_unicode, Operator),

            # chars
            (r"'(\\.|\\[0-7]{1,3}|\\x[a-fA-F0-9]{1,3}|\\u[a-fA-F0-9]{1,4}|"
             r"\\U[a-fA-F0-9]{1,6}|[^\\\'\n])'", String.Char),

            # try to match trailing transpose
            (r'(?<=[.\w)\]])\'+', Operator),

            # strings
            (r'"""', String, 'tqstring'),
            (r'"', String, 'string'),

            # regular expressions
            (r'r"""', String.Regex, 'tqregex'),
            (r'r"', String.Regex, 'regex'),

            # backticks
            (r'`', String.Backtick, 'command'),

            # variables
            (allowed_variable, Name.Variable),

            # macros
            (r'@' + allowed_variable, Name.Decorator),

        ],

        "blockcomment": [
            (r'[^=#]', Comment.Multiline),
            (r'#=', Comment.Multiline, '#push'),
            (r'=#', Comment.Multiline, '#pop'),
            (r'[=#]', Comment.Multiline),
        ],

        "index": [
            (r'\[', Punctuation, '#push'),
            (r'"""', String, 'tqstring'),
            (r'"', String, 'string'),
            (numbers, Number),
            (r'end', Name.Builtin),
            (r'\b(?:(' + allowed_variable + r')(?=\())', Name.Function),
            (allowed_variable, Name.Variable),
            (r'[\(\)\+\-\*\/,.:;]', Punctuation),
            (symb_op_ascii, Operator),
            (symb_op_unicode, Operator),
            (symb_id, Operator),
            (r'\b(if|else|elseif|for|while|do|try|catch|finally|return|break|continue|in)\b', Keyword),
            (r' ', Text),
            (r'(?<=[.\w)\]])\'+', Operator), # Also try to match trailing transpose when inside index.
            (r'\]', Punctuation, '#pop'),
        ],

        'string': [
            (r'"', String, '#pop'),
            # FIXME: This escape pattern is not perfect.
            (r'\\([\\"\'$nrbtfav]|(x|u|U)[a-fA-F0-9]+|\d+)', String.Escape),
            # Interpolation is defined as "$" followed by the shortest full
            # expression, which is something we can't parse.
            # Include the most common cases here: $word, and $(paren'd expr).
            (r'\$' + allowed_variable, String.Interpol),
            # (r'\$[a-zA-Z_]+', String.Interpol),
            (r'(\$)(\()', bygroups(String.Interpol, Punctuation), 'in-intp'),
            # @printf and @sprintf formats
            (r'%[-#0 +]*([0-9]+|[*])?(\.([0-9]+|[*]))?[hlL]?[E-GXc-giorsux%]',
             String.Interpol),
            (r'.|\s', String),
        ],

        'tqstring': [
            (r'"""', String, '#pop'),
            (r'\\([\\"\'$nrbtfav]|(x|u|U)[a-fA-F0-9]+|\d+)', String.Escape),
            (r'\$' + allowed_variable, String.Interpol),
            (r'(\$)(\()', bygroups(String.Interpol, Punctuation), 'in-intp'),
            (r'.|\s', String),
        ],

        'regex': [
            (r'"', String.Regex, '#pop'),
            (r'\\"', String.Regex),
            (r'.|\s', String.Regex),
        ],

        'tqregex': [
            (r'"""', String.Regex, '#pop'),
            (r'.|\s', String.Regex),
        ],

        'command': [
            (r'`', String.Backtick, '#pop'),
            (r'\$' + allowed_variable, String.Interpol),
            (r'(\$)(\()', bygroups(String.Interpol, Punctuation), 'in-intp'),
            (r'.|\s', String.Backtick),
        ],

        'in-intp': [
            (r'\(', Punctuation, '#push'),
            (r'\)', Punctuation, '#pop'),
            include('root'),
        ],

    }

    def analyse_text(text):
        return shebang_matches(text, r'julia')


class Julia1ConsoleLexer(Lexer):
    """
    For Julia console sessions. Modeled after MatlabSessionLexer.
    """
    name = 'Julia console'
    aliases = ['jlcon1']

    def get_tokens_unprocessed(self, text):
        jllexer = Julia1Lexer(**self.options)
        start = 0
        curcode = ''
        insertions = []
        output = False
        error = False

        for line in text.splitlines(True):
            if line.startswith('julia>'):
                insertions.append((len(curcode), [(0, Generic.Prompt, line[:6])]))
                curcode += line[6:]
                output = False
                error = False
            elif line.startswith('help?>') or line.startswith('shell>'):
                yield start, Generic.Prompt, line[:6]
                yield start + 6, Text, line[6:]
                output = False
                error = False
            elif line.startswith('      ') and not output:
                insertions.append((len(curcode), [(0, Text, line[:6])]))
                curcode += line[6:]
            else:
                if curcode:
                    for item in do_insertions(
                            insertions, jllexer.get_tokens_unprocessed(curcode)):
                        yield item
                    curcode = ''
                    insertions = []
                if line.startswith('ERROR: ') or error:
                    yield start, Generic.Error, line
                    error = True
                else:
                    yield start, Generic.Output, line
                output = True
            start += len(line)

        if curcode:
            for item in do_insertions(
                    insertions, jllexer.get_tokens_unprocessed(curcode)):
                yield item