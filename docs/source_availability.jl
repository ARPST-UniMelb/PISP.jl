module PISPDocsSourceAvailability

export EditionProfile, Requirement, Observation, Inspection, AvailabilitySummary
export source_availability_profiles, edition_requirements, inspect_edition, source_availability_summary

Base.@kwdef struct EditionProfile
    edition::String
    report_root::String
    download_root::String
    report_root_source::Symbol
    download_root_source::Symbol
end

Base.@kwdef struct Requirement
    class::Symbol
    relative_path::String
    kind::Symbol
    label::String
end

Base.@kwdef struct Observation
    requirement::Requirement
    path::String
    observed::Bool
end

Base.@kwdef struct Inspection
    edition::String
    state::Symbol
    observations::Vector{Observation}
end

Base.@kwdef struct AvailabilitySummary
    edition::String
    trace_directories::Vector{String}
    trace_archive_files::Vector{String}
    demand_group_paths::Vector{String}
    demand_trace_files::Int
    poe_labels::Vector{String}
end

const REPORT_FILENAMES = Dict(
    "2024" => [
        "2024-isp-plexos-model-instructions.pdf",
        "2024-integrated-system-plan.pdf",
        "2023-inputs-assumptions-and-scenarios-report.pdf",
        "addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf",
        "2023-isp-methodology.pdf",
        "a2-generation-and-storage-development-opportunities.pdf",
        "a3-renewable-energy-zones.pdf",
        "a4-system-operability.pdf",
        "a6-cost-benefit-analysis.pdf",
        "a7-system-security.pdf",
    ],
    "2026" => [
        "2026-integrated-system-plan.pdf",
        "2026-isp-plexos-model-instructions.pdf",
        "2025-inputs-assumptions-and-scenarios-report.pdf",
        "addendum-to-2025-inputs-assumptions-and-scenarios-report.pdf",
        "2025-isp-methodology.pdf",
        "a2-isp-development-opportunities.pdf",
        "a3-renewable-energy-zones.pdf",
        "a4-system-operability.pdf",
        "a6-cost-benefit-analysis.pdf",
        "a7-system-security.pdf",
    ],
)

nonempty_environment_value(env, name) = begin
    value = strip(get(env, name, ""))
    isempty(value) ? nothing : value
end

function resolve_root(repo_root, path)
    isabspath(path) ? normpath(path) : normpath(joinpath(abspath(repo_root), path))
end

function configured_root(repo_root, env, variable, default)
    override = nonempty_environment_value(env, variable)
    override === nothing ? (resolve_root(repo_root, default), :default) :
        (resolve_root(repo_root, override), :environment)
end

function source_availability_profiles(repo_root; env = ENV)
    profiles = EditionProfile[]
    for (edition, report_default, download_default) in (
        ("2024", joinpath("data", "2024", "pisp-reports"), joinpath("data", "2024", "pisp-downloads")),
        ("2026", joinpath("data", "2026", "pisp-reports"), joinpath("data", "2026", "pisp-downloads")),
    )
        report_root, report_source = configured_root(repo_root, env, "PISP_ISP$(edition)_REPORT_ROOT", report_default)
        download_root, download_source = configured_root(repo_root, env, "PISP_ISP$(edition)_DOWNLOAD_ROOT", download_default)
        push!(profiles, EditionProfile(
            edition = edition,
            report_root = report_root,
            download_root = download_root,
            report_root_source = report_source,
            download_root_source = download_source,
        ))
    end
    profiles
end

function edition_requirements(edition)
    edition in keys(REPORT_FILENAMES) || throw(ArgumentError("unsupported ISP edition: $edition"))
    requirements = Requirement[
        Requirement(class = :report, relative_path = filename, kind = :file, label = "configured report target $filename")
        for filename in REPORT_FILENAMES[edition]
    ]
    if edition == "2024"
        append!(requirements, [
            Requirement(class = :download, relative_path = "zip/2024-isp-model.zip", kind = :file, label = "2024 model archive"),
            Requirement(class = :download, relative_path = "zip/2024-isp-generation-and-storage-outlook.zip", kind = :file, label = "2024 generation and storage outlook archive"),
            Requirement(class = :download, relative_path = "zip/Traces", kind = :archive_group, label = "2024 trace archive group"),
            Requirement(class = :download, relative_path = "2024 ISP Model", kind = :directory, label = "2024 model landmark"),
            Requirement(class = :download, relative_path = "Core", kind = :directory, label = "2024 Core landmark"),
            Requirement(class = :download, relative_path = "Sensitivities", kind = :directory, label = "2024 sensitivities landmark"),
            Requirement(class = :download, relative_path = "Traces", kind = :directory, label = "2024 traces landmark"),
        ])
    else
        append!(requirements, [
            Requirement(class = :download, relative_path = "zip/2026-isp-model.zip", kind = :file, label = "2026 model archive"),
            Requirement(class = :download, relative_path = "zip/2026-isp-generation-and-storage-outlook.zip", kind = :file, label = "2026 generation and storage outlook archive"),
            Requirement(class = :download, relative_path = "zip/Traces/2026-isp-solar-traces.zip", kind = :file, label = "2026 solar trace archive"),
            Requirement(class = :download, relative_path = "zip/Traces/2026-isp-wind-traces.zip", kind = :file, label = "2026 wind trace archive"),
            Requirement(class = :download, relative_path = "2026 ISP Model", kind = :directory, label = "2026 model landmark"),
            Requirement(class = :download, relative_path = "Core scenarios", kind = :directory, label = "2026 Core scenarios landmark"),
            Requirement(class = :download, relative_path = "Sensitivities", kind = :directory, label = "2026 sensitivities landmark"),
            Requirement(class = :download, relative_path = "Traces", kind = :directory, label = "2026 traces landmark"),
        ])
    end
    requirements
end

function requirement_observed(root, requirement)
    path = joinpath(root, requirement.relative_path)
    requirement.kind == :file && return isfile(path)
    requirement.kind == :directory && return isdir(path)
    requirement.kind == :archive_group && return isdir(path) && any(endswith(lowercase(name), ".zip") for name in readdir(path))
    throw(ArgumentError("unsupported requirement kind: $(requirement.kind)"))
end

function inspect_edition(profile::EditionProfile)
    requirements = edition_requirements(profile.edition)
    roots_present = ispath(profile.report_root) || ispath(profile.download_root)
    observations = Observation[]
    for requirement in requirements
        root = requirement.class == :report ? profile.report_root : profile.download_root
        push!(observations, Observation(
            requirement = requirement,
            path = normpath(joinpath(root, requirement.relative_path)),
            observed = requirement_observed(root, requirement),
        ))
    end
    state = !roots_present ? :absent : all(observation -> observation.observed, observations) ? :complete : :incomplete
    Inspection(edition = profile.edition, state = state, observations = observations)
end

function source_availability_summary(profile::EditionProfile)
    trace_directories = String[]
    trace_archive_files = String[]
    demand_group_paths = String[]
    demand_trace_files = 0
    poe_labels = Set{String}()

    for (directory, subdirectories, files) in walkdir(profile.download_root)
        filter!(name -> !startswith(name, ".") && !startswith(name, "._"), subdirectories)
        filter!(name -> !startswith(name, ".") && !startswith(name, "._"), files)
        relative_directory = replace(relpath(directory, profile.download_root), '\\' => '/')
        basename(directory) == "Traces" && push!(trace_directories, relative_directory)
        if startswith(relative_directory, "zip/Traces")
            append!(trace_archive_files, [joinpath(relative_directory, name) for name in files if endswith(lowercase(name), ".zip")])
        end
        if basename(directory) == "demand" || startswith(basename(directory), "demand_")
            push!(demand_group_paths, relative_directory)
        end
        if occursin("demand", lowercase(relative_directory))
            demand_trace_files += count(name -> endswith(lowercase(name), ".csv"), files)
        end
        for name in files
            for label in ("POE10", "POE50", "POE90")
                occursin(label, name) && push!(poe_labels, label)
            end
        end
    end

    AvailabilitySummary(
        edition = profile.edition,
        trace_directories = sort(unique(trace_directories)),
        trace_archive_files = sort(replace.(trace_archive_files, '\\' => '/')),
        demand_group_paths = sort(unique(demand_group_paths)),
        demand_trace_files = demand_trace_files,
        poe_labels = sort(collect(poe_labels)),
    )
end

end
