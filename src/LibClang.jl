module LibClang

using LLVM_jll
export LLVM_jll

using CEnum

const Ctime_t = UInt

include("CXErrorCode.jl")
include("CXString.jl")
include("CXCompilationDatabase.jl")
include("BuildSystem.jl")
include("Index.jl")
include("Documentation.jl")

foreach(names(@__MODULE__, all=true)) do s
    if startswith(string(s), "CX") || startswith(string(s), "clang_")
        @eval export $s
    end
end

end # module
