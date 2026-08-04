Base.@kwdef struct SourceAvailabilityProfile
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
    expected_demand_group_count::Union{Int,Nothing}
    missing_demand_groups::Vector{String}
    unexpected_demand_paths::Vector{String}
end

const REPORT_COUNTERPART_KEY_MAP = (
    :plexos_model_instructions => :plexos_model_instructions,
    :integrated_system_plan => :integrated_system_plan,
    :iasr_2023 => :iasr_2025,
    :iasr_2023_addendum => :iasr_2025_addendum,
    :isp_methodology_2023 => :isp_methodology_2025,
    :appendix_a2_generation_storage => :appendix_a2_generation_storage,
    :appendix_a3_rez => :appendix_a3_rez,
    :appendix_a4_operability => :appendix_a4_operability,
    :appendix_a6_cost_benefit => :appendix_a6_cost_benefit,
    :appendix_a7_security => :appendix_a7_security,
    :publication_webinar_presentation => :publication_webinar_presentation,
    :appendix_a1_stakeholder_engagement => :appendix_a1_stakeholder_engagement,
    :appendix_a5_network_investments => :appendix_a5_network_investments,
    :appendix_a8_social_licence => :appendix_a8_social_licence,
    :consultation_summary => :consultation_summary,
)

report_counterpart_key_map() = collect(REPORT_COUNTERPART_KEY_MAP)

function report_filenames(edition)
    targets = if edition == "2024"
        PISP.ISP2024ReportDownloader.report_targets()
    elseif edition == "2026"
        PISP.ISP2026ReportDownloader.report_targets()
    else
        throw(ArgumentError("unsupported ISP edition: $edition"))
    end
    return [target.filename for target in targets]
end

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
    profiles = SourceAvailabilityProfile[]
    for (edition, report_default, download_default) in (
        ("2024", joinpath("data", "2024", "pisp-reports"), joinpath("data", "2024", "pisp-downloads")),
        ("2026", joinpath("data", "2026", "pisp-reports"), joinpath("data", "2026", "pisp-downloads")),
    )
        report_root, report_source = configured_root(repo_root, env, "PISP_ISP$(edition)_REPORT_ROOT", report_default)
        download_root, download_source = configured_root(repo_root, env, "PISP_ISP$(edition)_DOWNLOAD_ROOT", download_default)
        push!(profiles, SourceAvailabilityProfile(
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
    requirements = Requirement[
        Requirement(class = :report, relative_path = filename, kind = :file, label = "configured report target $filename")
        for filename in report_filenames(edition)
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

function inspect_edition(profile::SourceAvailabilityProfile)
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

# The direct ISP 2024 demand-trace groups are named `demand_{subregion}_{scenario}`
# for every subregion in `PISP.NEMBUSNAME` and every scenario in `PISP.ID2SCE` —
# a fixed 12 x 3 = 36 combination regardless of which files a given download
# actually contains. Other editions have no such registered enumeration yet, so
# they fall back to the broader substring match below rather than asserting a
# bound PISP does not yet support.
function known_demand_group_names(edition)
    edition == "2024" || return nothing
    Set(
        "demand_$(subregion)_$(scenario)"
        for subregion in keys(PISP.NEMBUSNAME)
        for scenario in values(PISP.ID2SCE)
    )
end

function source_availability_summary(profile::SourceAvailabilityProfile)
    trace_directories = String[]
    trace_archive_files = String[]
    demand_group_paths = String[]
    unexpected_demand_paths = String[]
    demand_trace_files = 0
    poe_labels = Set{String}()

    known_demand_groups = known_demand_group_names(profile.edition)

    for (directory, subdirectories, files) in walkdir(profile.download_root)
        filter!(name -> !startswith(name, ".") && !startswith(name, "._"), subdirectories)
        filter!(name -> !startswith(name, ".") && !startswith(name, "._"), files)
        relative_directory = replace(relpath(directory, profile.download_root), '\\' => '/')
        directory_name = basename(directory)
        directory_name == "Traces" && push!(trace_directories, relative_directory)
        if startswith(relative_directory, "zip/Traces")
            append!(trace_archive_files, [joinpath(relative_directory, name) for name in files if endswith(lowercase(name), ".zip")])
        end

        is_extracted_group = directory_name == "demand"
        is_direct_group = startswith(directory_name, "demand_")
        if known_demand_groups === nothing
            if is_extracted_group || is_direct_group
                push!(demand_group_paths, relative_directory)
            end
            if occursin("demand", lowercase(relative_directory))
                demand_trace_files += count(name -> endswith(lowercase(name), ".csv"), files)
            end
        elseif is_extracted_group || is_direct_group
            push!(demand_group_paths, relative_directory)
            demand_trace_files += count(name -> endswith(lowercase(name), ".csv"), files)
            if is_direct_group && !(directory_name in known_demand_groups)
                push!(unexpected_demand_paths, relative_directory)
            end
        end

        for name in files
            for label in ("POE10", "POE50", "POE90")
                occursin(label, name) && push!(poe_labels, label)
            end
        end
    end

    missing_demand_groups = known_demand_groups === nothing ? String[] :
        sort(collect(setdiff(known_demand_groups, basename.(demand_group_paths))))

    AvailabilitySummary(
        edition = profile.edition,
        trace_directories = sort(unique(trace_directories)),
        trace_archive_files = sort(replace.(trace_archive_files, '\\' => '/')),
        demand_group_paths = sort(unique(demand_group_paths)),
        demand_trace_files = demand_trace_files,
        poe_labels = sort(collect(poe_labels)),
        expected_demand_group_count = known_demand_groups === nothing ? nothing : length(known_demand_groups),
        missing_demand_groups = missing_demand_groups,
        unexpected_demand_paths = sort(unique(unexpected_demand_paths)),
    )
end
