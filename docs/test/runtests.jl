using Test
using DataFrames

const TEST_DOCS_DIR = normpath(joinpath(@__DIR__, ".."))

include(joinpath(TEST_DOCS_DIR, "page_registry.jl"))
include(joinpath(TEST_DOCS_DIR, "render_literate.jl"))
include(joinpath(TEST_DOCS_DIR, "navigation.jl"))
include(joinpath(TEST_DOCS_DIR, "eda_support.jl"))
include(joinpath(TEST_DOCS_DIR, "download_layout.jl"))

using .PISPDocsPageRegistry
using .PISPDocsNavigation
using .EdaSupport
using .PISPDocsDownloadLayout

@testset "Markdown table rendering" begin
    rendered = markdown_table(DataFrame(Label=["alpha", "beta"], Value=[1.0, 2.0]))
    separator_cells = strip.(split(split(chomp(rendered.text), '\n')[2], '|'; keepempty=false))

    @test length(separator_cells) == 2
    @test !endswith(separator_cells[1], ":")
    @test endswith(separator_cells[2], ":")
    @test occursin("alpha", rendered.text)

    currency = markdown_table(DataFrame(Label=["Cost (\$/MW)"], Value=[2.0]))
    @test occursin(raw"\$", currency.text)

    missing_numeric = markdown_table(
        DataFrame(Label=["alpha", "beta"], Value=Union{Missing,Float64}[1.0, missing]),
    )
    missing_separator = strip.(split(split(chomp(missing_numeric.text), '\n')[2], '|'; keepempty=false))
    @test endswith(missing_separator[2], ":")

    empty_typed = markdown_table(DataFrame(Label=String[], Value=Float64[]))
    empty_separator = strip.(split(split(chomp(empty_typed.text), '\n')[2], '|'; keepempty=false))
    @test !endswith(empty_separator[1], ":")
    @test endswith(empty_separator[2], ":")

    mixed_any = markdown_table(DataFrame(Mixed=Any[1, "two"], Value=Any[1, 2]))
    mixed_separator = strip.(split(split(chomp(mixed_any.text), '\n')[2], '|'; keepempty=false))
    @test !endswith(mixed_separator[1], ":")
    @test endswith(mixed_separator[2], ":")

    overridden = markdown_table(
        DataFrame(Label=["alpha"], Value=[1.0]);
        alignment=[:r, :l],
    )
    overridden_separator = strip.(split(split(chomp(overridden.text), '\n')[2], '|'; keepempty=false))
    @test endswith(overridden_separator[1], ":")
    @test !endswith(overridden_separator[2], ":")

    multiline = markdown_table(DataFrame(Label=["alpha\nbeta"], Value=[1]))
    @test occursin("alpha beta", multiline.text)
    @test !occursin("alpha\nbeta", multiline.text)

    metrics = metric_value_table(["Rows" => 12, "Coverage (%)" => 98.5])
    @test occursin("Metric", metrics.text)
    @test occursin("Coverage (%)", metrics.text)

    table_interface = markdown_table((Label=["alpha"], Value=[1.0]))
    @test occursin("alpha", table_interface.text)
end

@testset "Human-use documentation invariants" begin
    read_doc(path...) = read(joinpath(TEST_DOCS_DIR, "src", path...), String)

    concepts = read_doc("concepts.md")
    for required in (
        "Demand.id_bus",
        "Generator.id_bus",
        "ESS.id_bus",
        "DER.id_dem",
        "Line.id_bus_from",
        "Line.id_bus_to",
        "Generator.tech",
        "schedule-<year>",
        "1 July",
        "4006",
    )
        @test occursin(required, concepts)
    end
    @test occursin("rooftop PV is represented in `Generator`", concepts)
    @test occursin("storage is represented in `ESS`", concepts)

    assumptions = read_doc("assumptions.md")
    for required in (
        "problem_type = \"UC\"",
        "seasonal or year-by-year outage-rate schedules",
        "Rooftop PV",
        "write_traces",
        "check_exist_trace",
        "checksums",
    )
        @test occursin(required, assumptions)
    end

    isp2026 = read_doc("editions", "isp2026.md")
    @test occursin("https://github.com/airampg/ParseISP.jl", isp2026)

    source_material = read_doc("editions", "source-material.md")
    for required in (
        "A2, A3, A4, A6, and A7",
        "2023 IASR EV workbook",
        "2025 IASR EV workbook",
        "`Auxiliary`",
    )
        @test occursin(required, source_material)
    end

    mappings = read_doc("editions", "parameters-and-mappings.md")
    for required in (
        "`1`, `2`, and `3`",
        "Twelve package bus aliases",
        "PISP.WEATHER_YEARS_ISP",
        "B11:K297",
        "B7:G50",
        "Report-defined mappings",
        "Workbook-derived values",
        "Package-defined defaults",
        "Unverified provenance",
        "ISP 2024 build-out defaults",
    )
        @test occursin(required, mappings)
    end

    generated_mappings = read_doc(
        "generated",
        "isp2024",
        "reference",
        "parameters-and-mappings.md",
    )
    @test occursin("2024 ISP PLEXOS Model Instructions, p. 6", generated_mappings)
    @test occursin("ending year", generated_mappings)
    @test occursin("2024-isp-plexos-model-instructions.pdf#page=5", generated_mappings)
    @test occursin("2024-isp-plexos-model-instructions.pdf#page=6", generated_mappings)

    buildout_defaults = read_doc(
        "generated",
        "isp2024",
        "reference",
        "buildout-defaults.md",
    )
    @test occursin("Source status", buildout_defaults)
    @test occursin("original external source", buildout_defaults)
    @test !occursin("\n````\ntrue\n````", buildout_defaults)

    comparison = read_doc("editions", "comparison.md")
    for required in (
        "model archive comparison",
        "scenario directories",
        "Wind, solar, and timeslice",
        "CSV schemas",
        "model-XML references",
    )
        @test occursin(required, comparison)
    end

    model_archive_comparison = read_doc(
        "generated",
        "comparison",
        "analyses",
        "model-archive-comparison.md",
    )
    for required in (
        "Progressive Change",
        "Slower Growth",
        "Green Energy Exports",
        "Accelerated Transition",
        "PLEXOS solver parameters",
        "345",
        "DNSP",
        "Rooftop PV",
        "2025-inputs-assumptions-and-scenarios-report.pdf#page=20",
    )
        @test occursin(required, model_archive_comparison)
    end

    trace_coverage = read_doc("editions", "trace-coverage.md")
    for required in ("14 historical reference years", "16 for 2026", "DNSP", "probability of exceedance")
        @test occursin(required, trace_coverage)
    end

    download_layout = read_doc("generated", "shared", "reference", "pisp-downloads-layout.md")
    for required in (
        "Core/ or Core scenarios/",
        "PISP-generated intermediates",
        "Extracted outlook directories",
        "2024-isp-generation-and-storage-outlook.zip",
        "2026-isp-generation-and-storage-outlook.zip",
    )
        @test occursin(required, download_layout)
    end
end

@testset "Literate executable narrative structure" begin
    read_literate(path...) = read(joinpath(TEST_DOCS_DIR, "literate", path...), String)
    function position(needle, source)
        match = findfirst(needle, source)
        match === nothing && error("missing source marker: $needle")
        return first(match)
    end

    layout = read_literate("shared", "reference", "pisp_downloads_layout.jl")
    availability = read_literate("isp2026", "validation", "source_availability.jl")
    archive_comparison = read_literate("comparison", "analysis", "model_archive_comparison.jl")

    for source in (layout, availability, archive_comparison)
        hidden_lines = filter(line -> occursin("#hide", line), split(source, '\n'))
        @test !isempty(hidden_lines)
        @test all(line -> strip(line) == "nothing #hide", hidden_lines)
    end

    @test position("download_layouts =", layout) >
        position("# ## Observed outlook directories and source archives", layout)
    @test position("inspection = inspect_edition", availability) >
        position("# ## Report and archive observations", availability)

    @test !occursin("const RECORDS", archive_comparison)
    for (selection, heading) in (
        ("archive_records =", "# ## Archive overview"),
        ("scenario_records_2024 =", "# ## Scenario continuity"),
        ("xml_records =", "# ## XML packaging"),
        ("trace_records_2024 =", "# ## Trace families inside the model ZIPs"),
        ("filename_records =", "# ## Representative filenames"),
        ("verification_records =", "# ## Verification"),
    )
        @test position(selection, archive_comparison) > position(heading, archive_comparison)
    end
end

@testset "Downloaded source layout filtering" begin
    mktempdir() do root
        for directory in (
            "Core",
            "Sensitivities",
            "Auxiliary",
            "Traces",
            "2024 ISP Model",
            "manifests",
            "zip",
            "__MACOSX",
        )
            mkpath(joinpath(root, directory))
        end
        write(joinpath(root, "zip", "2024-isp-model.zip"), "model")
        write(joinpath(root, "zip", "2024-isp-generation-and-storage-outlook.zip"), "outlook")
        mkpath(joinpath(root, "zip", "Traces"))
        write(joinpath(root, "zip", "Traces", "2024-isp-solar-traces.zip"), "trace")

        @test outlook_directories(root) == ["Core", "Sensitivities"]
        @test source_archives(root) == [
            "2024-isp-generation-and-storage-outlook.zip",
            "2024-isp-model.zip",
        ]
    end
end

function fixture_page(
    ;
    id,
    title="Fixture $(id)",
    kind="reference",
    track="isp2024",
    editions=["2024"],
    data_layer="source-data",
    source="literate/fixture/$(id).jl",
    output="generated/fixture/$(id).md",
    status="published",
    nav_order=10,
    snapshot=false,
    data_requirements=nothing,
)
    edition_values = join(repr.(editions), ", ")
    requirement_line = data_requirements === nothing ? "" : "\ndata_requirements = $(data_requirements)"
    block = """
    [[page]]
    id = "$(id)"
    title = "$(title)"
    kind = "$(kind)"
    track = "$(track)"
    editions = [$(edition_values)]
    data_layer = "$(data_layer)"
    source = "$(source)"
    output = "$(output)"
    status = "$(status)"
    nav_order = $(nav_order)
    snapshot = $(snapshot)$(requirement_line)
    """
    return (; id, source, output, status, block)
end

function with_registry_fixture(callback::Function, pages; generated_outputs=String[])
    mktempdir() do repo_root
        docs_dir = joinpath(repo_root, "docs")
        registry_path = joinpath(docs_dir, "page-registry.toml")

        for page in pages
            source_path = joinpath(docs_dir, page.source)
            mkpath(dirname(source_path))
            write(source_path, "# fixture Literate source\n")
        end

        for output in generated_outputs
            output_path = joinpath(docs_dir, "src", output)
            mkpath(dirname(output_path))
            write(output_path, "# fixture generated output\n")
        end

        mkpath(dirname(registry_path))
        write(registry_path, join((page.block for page in pages), "\n"))
        return callback(registry_path, repo_root)
    end
end

function preflight_page(requirements)
    return PageSpec(
        id="preflight-page",
        title="Preflight fixture",
        kind="reference",
        track="isp2024",
        editions=["2024"],
        data_layer="source-data",
        source="literate/fixture/preflight.jl",
        output="generated/fixture/preflight.md",
        status="published",
        nav_order=10,
        snapshot=false,
        data_requirements=requirements,
    )
end

function renderer_page(
    ;
    id,
    track,
    editions,
    status,
    kind="reference",
    data_layer="source-data",
    nav_order=10,
)
    return PageSpec(
        id=id,
        title="Renderer $(id)",
        kind=kind,
        track=track,
        editions=editions,
        data_layer=data_layer,
        source="literate/fixture/$(id).jl",
        output="generated/fixture/$(id).md",
        status=status,
        nav_order=nav_order,
        snapshot=false,
    )
end

function with_environment(callback::Function, overrides::Pair...)
    keys = String[first(override) for override in overrides]
    previous = Dict(key => get(ENV, key, nothing) for key in keys)

    try
        for override in overrides
            key, value = override
            if value === nothing
                haskey(ENV, key) && delete!(ENV, key)
            else
                ENV[key] = value
            end
        end
        return callback()
    finally
        for key in keys
            value = previous[key]
            if value === nothing
                haskey(ENV, key) && delete!(ENV, key)
            else
                ENV[key] = value
            end
        end
    end
end

@testset "PISP documentation page registry" begin
    @testset "status semantics and published generated outputs" begin
        published = fixture_page(id="published", nav_order=10)
        draft = fixture_page(id="draft", status="draft", nav_order=20)
        archived = fixture_page(id="archived", status="archived", nav_order=10)
        pages = [published, draft, archived]

        with_registry_fixture(pages; generated_outputs=[published.output]) do registry_path, _
            loaded = load_page_registry(registry_path; require_published_outputs=true)
            by_id = Dict(page.id => page for page in loaded)

            @test is_published(by_id["published"])
            @test !is_draft(by_id["published"])
            @test is_renderable(by_id["published"])
            @test is_draft(by_id["draft"])
            @test !is_published(by_id["draft"])
            @test is_renderable(by_id["draft"])
            @test !is_renderable(by_id["archived"])
        end

        with_registry_fixture([published]) do registry_path, _
            @test_throws ErrorException load_page_registry(
                registry_path;
                require_published_outputs=true,
            )
        end

        with_registry_fixture([draft]) do registry_path, _
            loaded = load_page_registry(registry_path; require_published_outputs=true)
            @test only(loaded).status == "draft"
        end
    end

    @testset "track and edition rules" begin
        shared = fixture_page(id="shared", track="shared", editions=String[])
        isp2024 = fixture_page(id="isp2024", track="isp2024", editions=["2024"])
        isp2026 = fixture_page(id="isp2026", track="isp2026", editions=["2026"])
        comparison = fixture_page(
            id="comparison",
            track="comparison",
            editions=["2024", "2026"],
        )
        valid_pages = [shared, isp2024, isp2026, comparison]

        with_registry_fixture(valid_pages; generated_outputs=[page.output for page in valid_pages]) do registry_path, _
            loaded = load_page_registry(registry_path; require_published_outputs=true)
            @test length(loaded) == 4
        end

        invalid_pages = [
            fixture_page(id="unknown-track", track="unsupported", editions=String[]),
            fixture_page(id="wrong-2024", track="isp2024", editions=["2026"]),
            fixture_page(id="wrong-2026", track="isp2026", editions=["2024"]),
            fixture_page(id="one-edition-comparison", track="comparison", editions=["2024"]),
            fixture_page(id="unknown-edition", track="shared", editions=["2030"]),
            fixture_page(
                id="duplicate-editions",
                track="comparison",
                editions=["2024", "2024"],
            ),
        ]

        for invalid_page in invalid_pages
            with_registry_fixture([invalid_page]) do registry_path, _
                @test_throws ErrorException load_page_registry(registry_path)
            end
        end
    end

    @testset "navigation positions are scoped to track and kind" begin
        first_page = fixture_page(id="first", nav_order=10)
        duplicate_page = fixture_page(id="duplicate", nav_order=10)
        with_registry_fixture([first_page, duplicate_page]) do registry_path, _
            @test_throws ErrorException load_page_registry(registry_path)
        end

        isp2024 = fixture_page(id="isp2024-position", track="isp2024", editions=["2024"])
        isp2026 = fixture_page(id="isp2026-position", track="isp2026", editions=["2026"])
        with_registry_fixture([isp2024, isp2026]) do registry_path, _
            loaded = load_page_registry(registry_path)
            @test length(loaded) == 2
        end
    end

    @testset "typed data requirement parsing" begin
        valid_repo_requirement = fixture_page(
            id="valid-repo-requirement",
            data_requirements="[{ root = \"repo\", path = \"README.md\", type = \"file\" }]",
        )
        with_registry_fixture([valid_repo_requirement]) do registry_path, _
            loaded = load_page_registry(registry_path)
            requirement = only(only(loaded).data_requirements)
            @test requirement.root == "repo"
            @test requirement.edition === nothing
            @test requirement.type == "file"
        end

        invalid_requirements = [
            "[{ root = \"unknown\", edition = \"2024\", path = \"file.txt\", type = \"file\" }]",
            "[{ root = \"download\", edition = \"2024\", path = \"file.txt\", type = \"unknown\" }]",
            "[{ root = \"download\", edition = \"2030\", path = \"file.txt\", type = \"file\" }]",
            "[{ root = \"download\", edition = \"2026\", path = \"file.txt\", type = \"file\" }]",
            "[{ root = \"repo\", edition = \"2024\", path = \"file.txt\", type = \"file\" }]",
            "[{ root = \"download\", path = \"file.txt\", type = \"file\" }]",
            "[{ root = \"repo\", path = \"../outside.txt\", type = \"file\" }]",
            "[{ root = \"repo\", path = \"/tmp/outside.txt\", type = \"file\" }]",
        ]

        for (index, requirement) in enumerate(invalid_requirements)
            page = fixture_page(id="invalid-requirement-$(index)", data_requirements=requirement)
            with_registry_fixture([page]) do registry_path, _
                @test_throws ErrorException load_page_registry(registry_path)
            end
        end
    end

    @testset "data requirement preflight types and roots" begin
        fixture = fixture_page(
            id="preflight-registry-page",
            data_requirements="""
          [
              { root = \"repo\", path = \"repo-file.txt\", type = \"file\" },
              { root = \"repo\", path = \"repo-directory\", type = \"directory\" },
              { root = \"repo\", path = \"repo-file.txt\", type = \"path\" },
              { root = \"download\", edition = \"2024\", path = \"download-file.txt\", type = \"file\" },
              { root = \"download\", edition = \"2024\", path = \"download-directory\", type = \"directory\" },
              { root = \"output\", edition = \"2024\", path = \"output-file.txt\", type = \"path\" },
              { root = \"output\", edition = \"2024\", path = \"output-directory\", type = \"path\" },
          ]
          """,
        )

        with_registry_fixture([fixture]) do registry_path, repo_root
            download_root = joinpath(repo_root, "download")
            output_root = joinpath(repo_root, "output")
            mkpath(joinpath(repo_root, "repo-directory"))
            mkpath(joinpath(download_root, "download-directory"))
            mkpath(joinpath(output_root, "output-directory"))
            write(joinpath(repo_root, "repo-file.txt"), "fixture\n")
            write(joinpath(download_root, "download-file.txt"), "fixture\n")
            write(joinpath(output_root, "output-file.txt"), "fixture\n")

            page = only(load_page_registry(registry_path))
            profiles = Dict("2024" => (; download_root, output_root))
            resolved = validate_data_requirements(
                page;
                repo_root,
                profile_for=edition -> profiles[edition],
            )
            @test length(resolved) == 7
            @test all(ispath, resolved)

            missing_download = preflight_page([
                DataRequirement("download", "2024", "missing.txt", "file"),
            ])
            @test_throws ErrorException validate_data_requirements(
                missing_download;
                repo_root,
                profile_for=edition -> profiles[edition],
            )

            missing_download_root = Dict(
                "2024" => (; download_root=joinpath(repo_root, "missing-download"), output_root),
            )
            download_requirement = preflight_page([
                DataRequirement("download", "2024", "download-file.txt", "file"),
            ])
            @test_throws ErrorException validate_data_requirements(
                download_requirement;
                repo_root,
                profile_for=edition -> missing_download_root[edition],
            )

            no_output_root = Dict("2024" => (; download_root, output_root=nothing))
            output_requirement = preflight_page([
                DataRequirement("output", "2024", "output-file.txt", "file"),
            ])
            @test_throws ErrorException validate_data_requirements(
                output_requirement;
                repo_root,
                profile_for=edition -> no_output_root[edition],
            )

            wrong_directory_type = preflight_page([
                DataRequirement("download", "2024", "download-file.txt", "directory"),
            ])
            @test_throws ErrorException validate_data_requirements(
                wrong_directory_type;
                repo_root,
                profile_for=edition -> profiles[edition],
            )

            wrong_file_type = preflight_page([
                DataRequirement("download", "2024", "download-directory", "file"),
            ])
            @test_throws ErrorException validate_data_requirements(
                wrong_file_type;
                repo_root,
                profile_for=edition -> profiles[edition],
            )
        end
    end

    @testset "renderer selection respects status and track" begin
        pages = [
            renderer_page(
                id="shared-published",
                track="shared",
                editions=String[],
                status="published",
            ),
            renderer_page(
                id="isp2024-published",
                track="isp2024",
                editions=["2024"],
                status="published",
            ),
            renderer_page(
                id="isp2024-draft",
                track="isp2024",
                editions=["2024"],
                status="draft",
                nav_order=20,
            ),
            renderer_page(
                id="isp2024-archived",
                track="isp2024",
                editions=["2024"],
                status="archived",
                nav_order=30,
            ),
        ]

        with_environment(
            "PISP_LITERATE_PAGES" => nothing,
            "PISP_LITERATE_SET" => nothing,
            "PISP_DOCS_TRACK" => nothing,
        ) do
            @test [page.id for page in select_pages(pages)] == [
                "shared-published",
                "isp2024-published",
            ]
        end

        with_environment(
            "PISP_LITERATE_PAGES" => nothing,
            "PISP_LITERATE_SET" => "published",
            "PISP_DOCS_TRACK" => "isp2024",
        ) do
            @test [page.id for page in select_pages(pages)] == ["isp2024-published"]
        end

        with_environment(
            "PISP_LITERATE_PAGES" => nothing,
            "PISP_LITERATE_SET" => "draft",
            "PISP_DOCS_TRACK" => "isp2024",
        ) do
            @test [page.id for page in select_pages(pages)] == ["isp2024-draft"]
        end

        with_environment(
            "PISP_LITERATE_PAGES" => "isp2024-archived",
            "PISP_LITERATE_SET" => nothing,
            "PISP_DOCS_TRACK" => nothing,
        ) do
            @test_throws ErrorException select_pages(pages)
        end

        with_environment(
            "PISP_LITERATE_PAGES" => "isp2024-published",
            "PISP_LITERATE_SET" => "all",
            "PISP_DOCS_TRACK" => nothing,
        ) do
            @test_throws ErrorException select_pages(pages)
        end

        with_environment(
            "PISP_LITERATE_PAGES" => "isp2024-published",
            "PISP_LITERATE_SET" => nothing,
            "PISP_DOCS_TRACK" => "isp2024",
        ) do
            @test_throws ErrorException select_pages(pages)
        end
    end

    @testset "edition navigation from published registry pages" begin
        pages = [
            renderer_page(
                id="isp2024-reference-later",
                track="isp2024",
                editions=["2024"],
                status="published",
                nav_order=20,
            ),
            renderer_page(
                id="isp2024-reference-first",
                track="isp2024",
                editions=["2024"],
                status="published",
                nav_order=10,
            ),
            renderer_page(
                id="isp2024-tutorial",
                track="isp2024",
                editions=["2024"],
                status="published",
                kind="tutorial",
            ),
            renderer_page(
                id="isp2024-validation",
                track="isp2024",
                editions=["2024"],
                status="published",
                kind="validation",
            ),
            renderer_page(
                id="isp2024-analysis",
                track="isp2024",
                editions=["2024"],
                status="published",
                kind="analysis",
            ),
            renderer_page(
                id="isp2024-draft",
                track="isp2024",
                editions=["2024"],
                status="draft",
                nav_order=30,
            ),
            renderer_page(
                id="isp2024-archived",
                track="isp2024",
                editions=["2024"],
                status="archived",
                nav_order=40,
            ),
            renderer_page(
                id="comparison-source-data",
                track="comparison",
                editions=["2024", "2026"],
                status="published",
                kind="analysis",
                data_layer="source-data",
                nav_order=20,
            ),
            renderer_page(
                id="comparison-pisp-dataset",
                track="comparison",
                editions=["2024", "2026"],
                status="published",
                kind="reference",
                data_layer="pisp-dataset",
                nav_order=10,
            ),
            renderer_page(
                id="comparison-package-workflow-draft",
                track="comparison",
                editions=["2024", "2026"],
                status="draft",
                data_layer="package-workflow",
                nav_order=10,
            ),
            renderer_page(
                id="comparison-cross-layer-archived",
                track="comparison",
                editions=["2024", "2026"],
                status="archived",
                data_layer="cross-layer",
                nav_order=10,
            ),
        ]
        navigation = registry_navigation(pages)

        @test first.(navigation) == [
            "Home",
            "Quickstart",
            "Understand PISP and ISP data",
            "ISP 2024",
            "ISP 2026",
            "Compare ISP 2024 and ISP 2026",
            "Contributing",
            "API Reference",
        ]

        navigation_by_title = Dict(first(entry) => last(entry) for entry in navigation)
        @test navigation_by_title["Contributing"] == "contributing.md"

        shared_material = navigation_by_title["Understand PISP and ISP data"]
        @test first.(shared_material) == [
            "ISP source data",
            "PISP transformation",
            "PISP datasets",
        ]
        @test first.(last(shared_material[1])) == [
            "Source material by edition",
            "Trace families and source meaning",
            "Downloaded source layout by edition",
        ]
        @test last.(last(shared_material[1])) == [
            "editions/source-material.md",
            "editions/trace-coverage.md",
            "generated/shared/reference/pisp-downloads-layout.md",
        ]
        @test first.(last(shared_material[2])) == [
            "Workflow support by edition",
            "Source-to-dataset processing",
            "Parameters, mappings, and constants",
        ]
        @test last.(last(shared_material[2])) == [
            "editions/supported-editions.md",
            "editions/source-inventory.md",
            "editions/parameters-and-mappings.md",
        ]
        @test first.(last(shared_material[3])) == [
            "Assets, relationships, and schedules",
            "Output tables, fields, and units",
            "Dataset interpretation and study bounds",
        ]
        @test last.(last(shared_material[3])) == [
            "concepts.md",
            "editions/output-data-model.md",
            "assumptions.md",
        ]

        isp2024_navigation = navigation_by_title["ISP 2024"]
        @test first.(isp2024_navigation) == [
            "Overview",
            "Preprocessing workflow",
            "Reference and inputs",
            "Tutorials",
            "Data validation",
            "Analyses and case studies",
        ]
        @test last(isp2024_navigation[1]) == "editions/isp2024.md"
        @test last(isp2024_navigation[2]) == "editions/isp2024-preprocessing.md"
        @test first.(last(isp2024_navigation[3])) == [
            "Renderer isp2024-reference-first",
            "Renderer isp2024-reference-later",
        ]
        @test last.(last(isp2024_navigation[3])) == [
            "generated/fixture/isp2024-reference-first.md",
            "generated/fixture/isp2024-reference-later.md",
        ]
        @test first.(last(isp2024_navigation[4])) == ["Renderer isp2024-tutorial"]
        @test first.(last(isp2024_navigation[5])) == ["Renderer isp2024-validation"]
        @test first.(last(isp2024_navigation[6])) == ["Renderer isp2024-analysis"]
        @test !occursin("draft", repr(isp2024_navigation))
        @test !occursin("archived", repr(isp2024_navigation))

        isp2026_navigation = navigation_by_title["ISP 2026"]
        @test isp2026_navigation == Any["Overview"=>"editions/isp2026.md"]

        comparison_navigation = navigation_by_title["Compare ISP 2024 and ISP 2026"]
        @test comparison_navigation == Any[
            "Overview and comparison rules"=>"editions/comparison.md",
            "ISP source data"=>Any[
                "Renderer comparison-source-data"=>
                    "generated/fixture/comparison-source-data.md",
            ],
            "PISP datasets"=>Any[
                "Renderer comparison-pisp-dataset"=>
                    "generated/fixture/comparison-pisp-dataset.md",
            ],
        ]
        @test !occursin("package-workflow-draft", repr(comparison_navigation))
        @test !occursin("cross-layer-archived", repr(comparison_navigation))
    end

    @testset "every published page is nav-reachable" begin
        function flatten_nav_outputs(navigation)
            outputs = String[]
            for (_, value) in navigation
                if value isa AbstractString
                    push!(outputs, value)
                else
                    append!(outputs, flatten_nav_outputs(value))
                end
            end
            return outputs
        end

        # Sanity-check the assertion mechanism itself: a published page whose
        # kind has no entry in its track's KIND_LABELS is never selected by
        # track_sections, so it must be detected as unreachable.
        reachable_pages = [
            renderer_page(id="covered-page", track="isp2024", editions=["2024"], status="published"),
        ]
        reachable_outputs = Set(flatten_nav_outputs(registry_navigation(reachable_pages)))
        @test reachable_pages[1].output in reachable_outputs

        orphan_pages = [
            renderer_page(
                id="orphan-page",
                track="isp2024",
                editions=["2024"],
                status="published",
                kind="unregistered-kind",
            ),
        ]
        orphan_outputs = Set(flatten_nav_outputs(registry_navigation(orphan_pages)))
        @test !(orphan_pages[1].output in orphan_outputs)

        # Sanity-check the actual original failure mode: `registry_navigation`
        # has no dynamic handler for the `shared` track at all (unlike
        # `isp2024`/`isp2026`/`comparison`, which go through `track_navigation`
        # or `comparison_navigation`). Only one `shared` page is placed, by a
        # hand-written literal entry in the "Understand" tree; any other
        # `shared` page is unreachable until it also gets a literal entry.
        unhandled_track_pages = [
            renderer_page(
                id="future-shared-page",
                track="shared",
                editions=["2024", "2026"],
                status="published",
                kind="reference",
            ),
        ]
        unhandled_track_outputs = Set(flatten_nav_outputs(registry_navigation(unhandled_track_pages)))
        @test !(unhandled_track_pages[1].output in unhandled_track_outputs)

        # The real registry: every published page's output must appear
        # somewhere in the rendered navigation tree.
        real_pages = load_page_registry(
            joinpath(TEST_DOCS_DIR, "page-registry.toml");
            require_published_outputs=true,
            check_generated_outputs=true,
        )
        real_outputs = Set(flatten_nav_outputs(registry_navigation(real_pages)))
        for page in real_pages
            is_published(page) || continue
            @test page.output in real_outputs
        end
    end
end
