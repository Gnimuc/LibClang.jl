module LibClang

using Clang_jll
export Clang_jll

@static if Sys.islinux() && Sys.ARCH === :aarch64 && !occursin("musl", Base.BUILD_TRIPLET)
    include("wrappers/aarch64-linux-gnu.jl")
elseif Sys.islinux() && Sys.ARCH === :aarch64 && occursin("musl", Base.BUILD_TRIPLET)
    include("wrappers/aarch64-linux-musl.jl")
elseif Sys.islinux() && startswith(string(Sys.ARCH), "arm") && !occursin("musl", Base.BUILD_TRIPLET)
    include("wrappers/armv7l-linux-gnueabihf.jl")
elseif Sys.islinux() && startswith(string(Sys.ARCH), "arm") && occursin("musl", Base.BUILD_TRIPLET)
    include("wrappers/armv7l-linux-musleabihf.jl")
elseif Sys.islinux() && Sys.ARCH === :i686 && !occursin("musl", Base.BUILD_TRIPLET)
    include("wrappers/i686-linux-gnu.jl")
elseif Sys.islinux() && Sys.ARCH === :i686 && occursin("musl", Base.BUILD_TRIPLET)
    include("wrappers/i686-linux-musl.jl")
elseif Sys.iswindows() && Sys.ARCH === :i686
    include("wrappers/i686-w64-mingw32.jl")
elseif Sys.islinux() && Sys.ARCH === :powerpc64le
    include("wrappers/powerpc64le-linux-gnu.jl")
elseif Sys.isapple() && Sys.ARCH === :x86_64
    include("wrappers/x86_64-apple-darwin14.jl")
elseif Sys.islinux() && Sys.ARCH === :x86_64 && !occursin("musl", Base.BUILD_TRIPLET)
    include("wrappers/x86_64-linux-gnu.jl")
elseif Sys.islinux() && Sys.ARCH === :x86_64 && occursin("musl", Base.BUILD_TRIPLET)
    include("wrappers/x86_64-linux-musl.jl")
elseif Sys.isbsd() && !Sys.isapple()
    include("wrappers/x86_64-unknown-freebsd11.1.jl")
elseif Sys.iswindows() && Sys.ARCH === :x86_64
    include("wrappers/x86_64-w64-mingw32.jl")
end

# exports
const PREFIXES = ["CX", "clang_"]
foreach(names(@__MODULE__; all=true)) do s
    for prefix in PREFIXES
        if startswith(string(s), prefix)
            @eval export $s
        end
    end
end

end # module
