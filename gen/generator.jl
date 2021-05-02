using Clang.Generators
using Clang.JLLEnvs
using Clang_jll

cd(@__DIR__)

include_dir = joinpath(Clang_jll.artifact_dir, "include") |> normpath
clang_dir = joinpath(include_dir, "clang-c")

for target in JLLEnvs.JLL_ENV_TRIPLES
    target == "aarch64-apple-darwin20" && continue

    @info "processing $target"

    options = load_options(joinpath(@__DIR__, "configs", "$target.toml"))

    args = get_default_args(target)
    push!(args, "-I$include_dir")

    headers = detect_headers(clang_dir, args)

    ctx = create_context(headers, args, options)

    build!(ctx)
end
