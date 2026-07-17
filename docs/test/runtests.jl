using Test

const TEST_DOCS_DIR = normpath(joinpath(@__DIR__, ".."))

include(joinpath(TEST_DOCS_DIR, "page_registry.jl"))
include(joinpath(TEST_DOCS_DIR, "render_literate.jl"))
include(joinpath(TEST_DOCS_DIR, "navigation.jl"))

using .PISPDocsPageRegistry
using .PISPDocsNavigation

function fixture_page(
    ;
    id,
    title = "Fixture $(id)",
    kind = "reference",
    track = "isp2024",
    editions = ["2024"],
    data_layer = "source-data",
    source = "literate/fixture/$(id).jl",
    output = "generated/fixture/$(id).md",
    status = "published",
    nav_order = 10,
    snapshot = false,
    data_requirements = nothing,
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

function with_registry_fixture(callback::Function, pages; generated_outputs = String[])
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
        id = "preflight-page",
        title = "Preflight fixture",
        kind = "reference",
        track = "isp2024",
        editions = ["2024"],
        data_layer = "source-data",
        source = "literate/fixture/preflight.jl",
        output = "generated/fixture/preflight.md",
        status = "published",
        nav_order = 10,
        snapshot = false,
        data_requirements = requirements,
    )
end

function renderer_page(
    ;
    id,
    track,
    editions,
    status,
    kind = "reference",
    nav_order = 10,
)
    return PageSpec(
        id = id,
        title = "Renderer $(id)",
        kind = kind,
        track = track,
        editions = editions,
        data_layer = "source-data",
        source = "literate/fixture/$(id).jl",
        output = "generated/fixture/$(id).md",
        status = status,
        nav_order = nav_order,
        snapshot = false,
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
        published = fixture_page(id = "published", nav_order = 10)
        draft = fixture_page(id = "draft", status = "draft", nav_order = 20)
        archived = fixture_page(id = "archived", status = "archived", nav_order = 10)
        pages = [published, draft, archived]

        with_registry_fixture(pages; generated_outputs = [published.output]) do registry_path, _
            loaded = load_page_registry(registry_path; require_published_outputs = true)
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
                require_published_outputs = true,
            )
        end

        with_registry_fixture([draft]) do registry_path, _
            loaded = load_page_registry(registry_path; require_published_outputs = true)
            @test only(loaded).status == "draft"
        end
    end

    @testset "track and edition rules" begin
        shared = fixture_page(id = "shared", track = "shared", editions = String[])
        isp2024 = fixture_page(id = "isp2024", track = "isp2024", editions = ["2024"])
        isp2026 = fixture_page(id = "isp2026", track = "isp2026", editions = ["2026"])
        comparison = fixture_page(
            id = "comparison",
            track = "comparison",
            editions = ["2024", "2026"],
        )
        valid_pages = [shared, isp2024, isp2026, comparison]

        with_registry_fixture(valid_pages; generated_outputs = [page.output for page in valid_pages]) do registry_path, _
            loaded = load_page_registry(registry_path; require_published_outputs = true)
            @test length(loaded) == 4
        end

        invalid_pages = [
            fixture_page(id = "unknown-track", track = "unsupported", editions = String[]),
            fixture_page(id = "wrong-2024", track = "isp2024", editions = ["2026"]),
            fixture_page(id = "wrong-2026", track = "isp2026", editions = ["2024"]),
            fixture_page(id = "one-edition-comparison", track = "comparison", editions = ["2024"]),
            fixture_page(id = "unknown-edition", track = "shared", editions = ["2030"]),
            fixture_page(
                id = "duplicate-editions",
                track = "comparison",
                editions = ["2024", "2024"],
            ),
        ]

        for invalid_page in invalid_pages
            with_registry_fixture([invalid_page]) do registry_path, _
                @test_throws ErrorException load_page_registry(registry_path)
            end
        end
    end

    @testset "navigation positions are scoped to track and kind" begin
        first_page = fixture_page(id = "first", nav_order = 10)
        duplicate_page = fixture_page(id = "duplicate", nav_order = 10)
        with_registry_fixture([first_page, duplicate_page]) do registry_path, _
            @test_throws ErrorException load_page_registry(registry_path)
        end

        isp2024 = fixture_page(id = "isp2024-position", track = "isp2024", editions = ["2024"])
        isp2026 = fixture_page(id = "isp2026-position", track = "isp2026", editions = ["2026"])
        with_registry_fixture([isp2024, isp2026]) do registry_path, _
            loaded = load_page_registry(registry_path)
            @test length(loaded) == 2
        end
    end

    @testset "typed data requirement parsing" begin
        valid_repo_requirement = fixture_page(
            id = "valid-repo-requirement",
            data_requirements = "[{ root = \"repo\", path = \"README.md\", type = \"file\" }]",
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
            page = fixture_page(id = "invalid-requirement-$(index)", data_requirements = requirement)
            with_registry_fixture([page]) do registry_path, _
                @test_throws ErrorException load_page_registry(registry_path)
            end
        end
    end

    @testset "data requirement preflight types and roots" begin
        fixture = fixture_page(
            id = "preflight-registry-page",
            data_requirements = """
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
                profile_for = edition -> profiles[edition],
            )
            @test length(resolved) == 7
            @test all(ispath, resolved)

            missing_download = preflight_page([
                DataRequirement("download", "2024", "missing.txt", "file"),
            ])
            @test_throws ErrorException validate_data_requirements(
                missing_download;
                repo_root,
                profile_for = edition -> profiles[edition],
            )

            missing_download_root = Dict(
                "2024" => (; download_root = joinpath(repo_root, "missing-download"), output_root),
            )
            download_requirement = preflight_page([
                DataRequirement("download", "2024", "download-file.txt", "file"),
            ])
            @test_throws ErrorException validate_data_requirements(
                download_requirement;
                repo_root,
                profile_for = edition -> missing_download_root[edition],
            )

            no_output_root = Dict("2024" => (; download_root, output_root = nothing))
            output_requirement = preflight_page([
                DataRequirement("output", "2024", "output-file.txt", "file"),
            ])
            @test_throws ErrorException validate_data_requirements(
                output_requirement;
                repo_root,
                profile_for = edition -> no_output_root[edition],
            )

            wrong_directory_type = preflight_page([
                DataRequirement("download", "2024", "download-file.txt", "directory"),
            ])
            @test_throws ErrorException validate_data_requirements(
                wrong_directory_type;
                repo_root,
                profile_for = edition -> profiles[edition],
            )

            wrong_file_type = preflight_page([
                DataRequirement("download", "2024", "download-directory", "file"),
            ])
            @test_throws ErrorException validate_data_requirements(
                wrong_file_type;
                repo_root,
                profile_for = edition -> profiles[edition],
            )
        end
    end

    @testset "renderer selection respects status and track" begin
        pages = [
            renderer_page(
                id = "shared-published",
                track = "shared",
                editions = String[],
                status = "published",
            ),
            renderer_page(
                id = "isp2024-published",
                track = "isp2024",
                editions = ["2024"],
                status = "published",
            ),
            renderer_page(
                id = "isp2024-draft",
                track = "isp2024",
                editions = ["2024"],
                status = "draft",
                nav_order = 20,
            ),
            renderer_page(
                id = "isp2024-archived",
                track = "isp2024",
                editions = ["2024"],
                status = "archived",
                nav_order = 30,
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
                id = "isp2024-reference-later",
                track = "isp2024",
                editions = ["2024"],
                status = "published",
                nav_order = 20,
            ),
            renderer_page(
                id = "isp2024-reference-first",
                track = "isp2024",
                editions = ["2024"],
                status = "published",
                nav_order = 10,
            ),
            renderer_page(
                id = "isp2024-tutorial",
                track = "isp2024",
                editions = ["2024"],
                status = "published",
                kind = "tutorial",
            ),
            renderer_page(
                id = "isp2024-validation",
                track = "isp2024",
                editions = ["2024"],
                status = "published",
                kind = "validation",
            ),
            renderer_page(
                id = "isp2024-analysis",
                track = "isp2024",
                editions = ["2024"],
                status = "published",
                kind = "analysis",
            ),
            renderer_page(
                id = "isp2024-draft",
                track = "isp2024",
                editions = ["2024"],
                status = "draft",
                nav_order = 30,
            ),
            renderer_page(
                id = "isp2024-archived",
                track = "isp2024",
                editions = ["2024"],
                status = "archived",
                nav_order = 40,
            ),
        ]
        navigation = registry_navigation(pages)

        @test first.(navigation) == [
            "Home",
            "Understand PISP and ISP data",
            "ISP 2024",
            "ISP 2026",
            "Compare ISP 2024 and ISP 2026",
            "API Reference",
        ]

        shared_material = last(navigation[2])
        @test first.(shared_material) == [
            "Supported ISP editions",
            "Domain concepts",
            "Output data model",
            "Assumptions and scope",
            "What each ISP edition publishes",
            "Downloaded source inventory by edition",
            "Trace families, schemas, and coverage",
            "Parameters and mappings across editions",
        ]
        @test last.(shared_material) == [
            "editions/supported-editions.md",
            "concepts.md",
            "editions/output-data-model.md",
            "assumptions.md",
            "editions/source-material.md",
            "editions/source-inventory.md",
            "editions/trace-coverage.md",
            "editions/parameters-and-mappings.md",
        ]

        isp2024_navigation = last(navigation[3])
        @test first.(isp2024_navigation) == [
            "Overview",
            "Reference and inputs",
            "Tutorials",
            "Data validation",
            "Analyses and case studies",
        ]
        @test last(isp2024_navigation[1]) == "editions/isp2024.md"
        @test first.(last(isp2024_navigation[2])) == [
            "Renderer isp2024-reference-first",
            "Renderer isp2024-reference-later",
        ]
        @test last.(last(isp2024_navigation[2])) == [
            "generated/fixture/isp2024-reference-first.md",
            "generated/fixture/isp2024-reference-later.md",
        ]
        @test first.(last(isp2024_navigation[3])) == ["Renderer isp2024-tutorial"]
        @test first.(last(isp2024_navigation[4])) == ["Renderer isp2024-validation"]
        @test first.(last(isp2024_navigation[5])) == ["Renderer isp2024-analysis"]
        @test !occursin("draft", repr(isp2024_navigation))
        @test !occursin("archived", repr(isp2024_navigation))

        isp2026_navigation = last(navigation[4])
        @test isp2026_navigation == Any["Overview" => "editions/isp2026.md"]

        comparison_navigation = last(navigation[5])
        @test comparison_navigation == Any[
            "Overview and comparison rules" => "editions/comparison.md",
        ]
    end
end
