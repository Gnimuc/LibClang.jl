using LibClang
using Test

@testset "LibClang.jl" begin
    cxstr = clang_getClangVersion()
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    @test match(r"[0-9]+.[0-9]+.[0-9]+", s).match == string(Base.libllvm_version)
end
