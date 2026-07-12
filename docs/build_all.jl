# Complete local documentation build:
# 1. regenerate registered EDA evidence and execute every active Literate page;
# 2. build the Documenter site.

const DOCS_DIR = @__DIR__
const REPO_ROOT = normpath(joinpath(DOCS_DIR, ".."))
render_command = `$(Base.julia_cmd()) --project=$(DOCS_DIR) $(joinpath(DOCS_DIR, "render_literate.jl"))`
make_command = `$(Base.julia_cmd()) --project=$(DOCS_DIR) $(joinpath(DOCS_DIR, "make.jl"))`

function run_stage(label, command)
    println("\n=== $label ===")
    try
        run(Cmd(command; dir = REPO_ROOT))
    catch
        println(stderr, "\nERROR: Documentation build stopped during: $label")
        label == "EDA and Literate regeneration" &&
            println(stderr, "Documenter was not run.")
        rethrow()
    end
end

run_stage("EDA and Literate regeneration", render_command)
run_stage("Documenter site build", make_command)

println("\nDocumentation build completed: $(joinpath(DOCS_DIR, "build", "index.html"))")
