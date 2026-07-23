using Test

include(joinpath(@__DIR__, "source_links.jl"))
using .SourceLinks

function fixture_repo()
    root = mktempdir()
    mkpath(joinpath(root, "sources"))
    write(joinpath(root, "sources", "report.pdf"), UInt8[0x25, 0x50, 0x44, 0x46])
    mkpath(joinpath(root, "docs", "src", "nested"))
    registry = """
    schema_version = 2

    [[source]]
    title = "Report"
    publisher = "Australian Energy Market Operator"
    local_path = "sources/report.pdf"
    public_url = "https://www.aemo.com.au/report.pdf?la=en"
    public_origin = "official"
    """
    write(joinpath(root, "docs", "source-links.toml"), registry)
    write(joinpath(root, "docs", "src", "nested", "page.md"),
        "[report-p3]: ../../../sources/report.pdf#page=3\n")
    return root
end

registry_path(root) = joinpath(root, "docs", "source-links.toml")
source_root(root) = joinpath(root, "docs", "src")
staging_root(root) = joinpath(root, "docs", ".documenter-source")

@testset "repository source-link routing" begin
    @testset "schema and URL validation" begin
        root = fixture_repo()
        entries = load_registry(registry_path(root))
        @test entries[1].local_path == "sources/report.pdf"
        @test entries[1].public_url == "https://www.aemo.com.au/report.pdf?la=en"
        @test_throws SourceLinkError SourceLinks.validate_public_url("http://example.test/report.pdf")
        @test_throws SourceLinkError SourceLinks.validate_public_url("https://example.test/report.pdf#page=2")
        @test_throws SourceLinkError SourceLinks.normalise_local_path("../report.pdf")
        bad_schema = joinpath(root, "bad-schema.toml")
        write(bad_schema, "schema_version = 1\n")
        @test_throws SourceLinkError load_registry(bad_schema)
        missing_field = joinpath(root, "missing-field.toml")
        write(missing_field, "schema_version = 2\n[[source]]\ntitle = \"x\"\n")
        @test_throws SourceLinkError load_registry(missing_field)
        for value in ("http://example.test/report.pdf", "https://example.test/report.pdf#page=1")
            path = joinpath(root, "invalid-url.toml")
            write(path, "schema_version = 2\n[[source]]\ntitle=\"x\"\npublisher=\"p\"\nlocal_path=\"sources/report.pdf\"\npublic_url=\"$value\"\npublic_origin=\"official\"\n")
            @test_throws SourceLinkError load_registry(path)
        end
        origin_path = joinpath(root, "invalid-origin.toml")
        write(origin_path, "schema_version = 2\n[[source]]\ntitle=\"x\"\npublisher=\"p\"\nlocal_path=\"sources/report.pdf\"\npublic_url=\"https://example.test/report.pdf\"\npublic_origin=\"unverified\"\n")
        @test_throws SourceLinkError load_registry(origin_path)
        duplicate_path = joinpath(root, "duplicate.toml")
        write(duplicate_path, "schema_version = 2\n[[source]]\ntitle=\"x\"\npublisher=\"p\"\nlocal_path=\"sources/report.pdf\"\npublic_url=\"https://example.test/a.pdf\"\npublic_origin=\"official\"\n[[source]]\ntitle=\"y\"\npublisher=\"p\"\nlocal_path=\"sources/./report.pdf\"\npublic_url=\"https://example.test/b.pdf\"\npublic_origin=\"official\"\n")
        @test_throws SourceLinkError load_registry(duplicate_path)
    end

    @testset "local and public nested links" begin
        root = fixture_repo()
        before = read(joinpath(source_root(root), "nested", "page.md"), String)
        stage_documentation!(source_root(root), staging_root(root), registry_path(root), :local; repo_root=root)
        @test read(joinpath(staging_root(root), "nested", "page.md"), String) == before
        stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
        @test read(joinpath(staging_root(root), "nested", "page.md"), String) ==
            "[report-p3]: https://www.aemo.com.au/report.pdf?la=en#page=3\n"
        @test read(joinpath(source_root(root), "nested", "page.md"), String) == before
    end

    @testset "protected regions and idempotence" begin
        root = fixture_repo()
        page = joinpath(source_root(root), "nested", "page.md")
        write(page, "---\n[frontmatter]: ../../../sources/report.pdf#page=8\n---\n\n```\n[code]: ../../../sources/report.pdf#page=9\n```\n\n```@raw html\n<a href=\"../../../sources/report.pdf#page=10\">raw</a>\n```\n\n[inline](../../../sources/report.pdf#page=11)\n\n" * read(page, String))
        stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
        first = read(joinpath(staging_root(root), "nested", "page.md"), String)
        stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
        @test read(joinpath(staging_root(root), "nested", "page.md"), String) == first
        @test occursin("[code]: ../../../sources/report.pdf#page=9", first)
        @test occursin("[frontmatter]: ../../../sources/report.pdf#page=8", first)
        @test occursin("../../../sources/report.pdf#page=10", first)
        @test occursin("[inline](https://www.aemo.com.au/report.pdf?la=en#page=11)", first)
    end

    @testset "failures preserve the previous staging tree" begin
        root = fixture_repo()
        stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
        previous = read(joinpath(staging_root(root), "nested", "page.md"), String)
        write(joinpath(source_root(root), "broken.md"), "[missing]: ../../../sources/missing.pdf#page=1\n")
        @test_throws SourceLinkError stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
        @test read(joinpath(staging_root(root), "nested", "page.md"), String) == previous
    end

    @testset "invalid target and page rejected" begin
        root = fixture_repo()
        write(joinpath(source_root(root), "bad.md"), "[bad]: ../../../sources/report.pdf#page=0\n")
        @test_throws SourceLinkError stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
        @test_throws SourceLinkError stage_documentation!(source_root(root), staging_root(root), registry_path(root), :invalid; repo_root=root)
    end

    @testset "arbitrary labels, unmapped and escaping paths" begin
        root = fixture_repo()
        write(joinpath(source_root(root), "arbitrary.md"), "[descriptive source]: ../../sources/report.pdf#page=4\n")
        stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
        @test occursin("[descriptive source]: https://www.aemo.com.au/report.pdf?la=en#page=4", read(joinpath(staging_root(root), "arbitrary.md"), String))
        write(joinpath(source_root(root), "unmapped.md"), "[missing]: ../../sources/unknown.pdf#page=1\n")
        @test_throws SourceLinkError stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
        write(joinpath(source_root(root), "escape.md"), "[escape]: ../../../../outside.pdf#page=1\n")
        @test_throws SourceLinkError stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
    end

    @testset "narrow inline links and protected Markdown" begin
        root = fixture_repo()
        page = joinpath(source_root(root), "nested", "page.md")
        write(page, "See [report](../../../sources/report.pdf#page=7) and [page 8](../../../sources/report.pdf#page=8).\n" *
            "Keep [title](../../../sources/report.pdf#page=9 \"title\"), ![image](../../../sources/report.pdf#page=10), and <https://example.test/report.pdf#page=11>.\n" *
            "Keep ` [inline](../../../sources/report.pdf#page=12) ` and [remote](https://example.test/report.pdf#page=13).\n" *
            "<p>[raw](../../../sources/report.pdf#page=14)</p>\n")
        stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
        staged = read(joinpath(staging_root(root), "nested", "page.md"), String)
        @test occursin("[report](https://www.aemo.com.au/report.pdf?la=en#page=7)", staged)
        @test occursin("[page 8](https://www.aemo.com.au/report.pdf?la=en#page=8)", staged)
        @test occursin("[title](../../../sources/report.pdf#page=9 \"title\")", staged)
        @test occursin("![image](../../../sources/report.pdf#page=10)", staged)
        @test occursin("` [inline](../../../sources/report.pdf#page=12) `", staged)
        @test occursin("<p>[raw](../../../sources/report.pdf#page=14)</p>", staged)
    end

    @testset "complete protected syntax matrix" begin
        root = fixture_repo()
        page = joinpath(source_root(root), "nested", "protected.md")
        original = "---\n[frontmatter](../../../sources/report.pdf#page=1)\n---\n" *
            "   ```markdown\n[fenced](../../../sources/report.pdf#page=2)\n   ```\n" *
            "~~~~markdown\n[tilde](../../../sources/report.pdf#page=3)\n~~~~\n" *
            "````markdown\n[long](../../../sources/report.pdf#page=4)\n````\n" *
            "    [indented](../../../sources/report.pdf#page=5)\n" *
            "\t[tabbed](../../../sources/report.pdf#page=6)\n" *
            "\\[escaped](../../../sources/report.pdf#page=7)\n"
        write(page, original)
        stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
        @test read(joinpath(staging_root(root), "nested", "protected.md"), String) == original
    end

    @testset "Markdown table rows remain byte-identical" begin
        root = fixture_repo()
        table = "| Source | Reference |\n| --- | --- |\n| report | [report](../../../sources/report.pdf#page=15) |\n"
        write(joinpath(source_root(root), "nested", "table.md"), table)
        stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
        @test read(joinpath(staging_root(root), "nested", "table.md"), String) == table
    end

    @testset "inline invalid candidates fail" begin
        for markdown in ("[missing](../../sources/unknown.pdf#page=1)\n", "[query](../../sources/report.pdf?x=1#page=1)\n", "[zero](../../sources/report.pdf#page=0)\n", "[bad](../../sources/report.pdf#page=wat)\n", "[escape](../../../outside/report.pdf#page=1)\n")
            root = fixture_repo()
            write(joinpath(source_root(root), "bad.md"), markdown)
            @test_throws SourceLinkError stage_documentation!(source_root(root), staging_root(root), registry_path(root), :public; repo_root=root)
        end
    end
end
