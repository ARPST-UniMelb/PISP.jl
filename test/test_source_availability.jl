# Local source-availability helpers (docs/source_availability.jl):
# fixture-level state detection, and the per-edition check for whether the
# local ISP report/download data is present (skipped when it is absent).

function local_material_state(profile)
    inspection = inspect_edition(profile)
    inspection.state == :absent && return :skip
    inspection.state == :complete && return :pass
    error("$(profile.edition) local source material is incomplete")
end

@testset "source availability helper fixtures" begin
    function fixture_roots(dir, edition; report = true, download = true)
        profiles = source_availability_profiles(dir; env = Dict{String, String}())
        profile = only(filter(p -> p.edition == edition, profiles))
        report && mkpath(profile.report_root)
        download && mkpath(profile.download_root)
        return profile
    end

    function populate_fixture(profile)
        for requirement in edition_requirements(profile.edition)
            root = requirement.class == :report ? profile.report_root : profile.download_root
            path = joinpath(root, requirement.relative_path)
            if requirement.kind == :file
                mkpath(dirname(path))
                write(path, "fixture")
            elseif requirement.kind == :directory
                mkpath(path)
            elseif requirement.kind == :archive_group
                mkpath(path)
                write(joinpath(path, "fixture-traces.zip"), "fixture")
            end
        end
    end

    mktempdir() do dir
        profiles = source_availability_profiles(dir; env = Dict{String, String}())
        @test all(profile -> inspect_edition(profile).state == :absent, profiles)
        @test all(profile -> local_material_state(profile) == :skip, profiles)
    end

    mktempdir() do dir
        profile = fixture_roots(dir, "2024"; report = true, download = false)
        @test inspect_edition(profile).state == :incomplete
        @test_throws ErrorException local_material_state(profile)
    end

    mktempdir() do dir
        profile = fixture_roots(dir, "2024")
        populate_fixture(profile)
        inspection = inspect_edition(profile)
        @test inspection.state == :complete
        @test all(observation -> observation.observed, inspection.observations)
        @test local_material_state(profile) == :pass
        summary = source_availability_summary(profile)
        @test summary.trace_archive_files == ["zip/Traces/fixture-traces.zip"]
        @test isempty(summary.demand_group_paths)
        @test summary.demand_trace_files == 0
    end

    mktempdir() do dir
        profile = fixture_roots(dir, "2026")
        populate_fixture(profile)
        requirement = first(filter(r -> r.kind == :file && r.class == :download, edition_requirements("2026")))
        path = joinpath(profile.download_root, requirement.relative_path)
        rm(path)
        mkpath(path)
        @test inspect_edition(profile).state == :incomplete
    end

    mktempdir() do dir
        override_report = joinpath(dir, "reports-override")
        env = Dict("PISP_ISP2024_REPORT_ROOT" => override_report)
        profile = only(filter(p -> p.edition == "2024", source_availability_profiles(dir; env = env)))
        @test profile.report_root == normpath(abspath(override_report))
        @test profile.report_root_source == :environment
        @test profile.download_root_source == :default
    end

    @test !isdefined(PISPDocsSourceAvailability, :HTTP)
end

profiles = source_availability_profiles(normpath(joinpath(@__DIR__, "..")))
for profile in profiles
    inspection = inspect_edition(profile)
    @testset "$(profile.edition) local source material" begin
        if inspection.state == :absent
            @test_skip "$(profile.edition) report and download roots are absent"
        else
            @test inspection.state == :complete
        end
    end
end
