# Complete local documentation build:
# 1. execute every active Literate page and install its generated output;
# 2. build the Documenter site.

const DOCS_DIR = @__DIR__
const REPO_ROOT = normpath(joinpath(DOCS_DIR, ".."))

function active_project_directory()
    project = Base.active_project()
    project === nothing && error("build_all.jl requires an active Julia project")
    return dirname(project)
end

const PROJECT_DIR = active_project_directory()
render_command = `$(Base.julia_cmd()) --project=$(PROJECT_DIR) $(joinpath(DOCS_DIR, "render_literate.jl"))`
make_command = `$(Base.julia_cmd()) --project=$(PROJECT_DIR) $(joinpath(DOCS_DIR, "make.jl"))`

function run_stage(label, command)
    println("\n=== $label ===")
    try
        run(Cmd(command; dir = REPO_ROOT))
    catch
        println(stderr, "\nERROR: Documentation build stopped during: $label")
        label == "Literate regeneration" &&
            println(stderr, "Documenter was not run.")
        rethrow()
    end
end

run_stage("Literate regeneration", render_command)
run_stage("Documenter site build", make_command)

println("\nDocumentation build completed: $(joinpath(DOCS_DIR, "build", "index.html"))")
