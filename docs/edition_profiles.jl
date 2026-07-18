module PISPDocsEditionProfiles

export EditionProfile, edition_profile, edition_profiles

Base.@kwdef struct EditionProfile
    edition::String
    label::String
    report_root::String
    download_root::String
    output_root::Union{Nothing, String} = nothing
    schedule_tag::Union{Nothing, String} = nothing
end

function nonempty_environment_value(name::AbstractString)
    value = strip(get(ENV, name, ""))
    return isempty(value) ? nothing : value
end

function resolve_root(repo_root::AbstractString, path::AbstractString)
    root = abspath(repo_root)
    return normpath(isabspath(path) ? path : joinpath(root, path))
end

function configured_root(repo_root::AbstractString, variable::AbstractString, default::Union{Nothing, String})
    override = nonempty_environment_value(variable)
    override === nothing && return default === nothing ? nothing : resolve_root(repo_root, default)
    return resolve_root(repo_root, override)
end

function configured_schedule(variable::AbstractString, default::Union{Nothing, String})
    override = nonempty_environment_value(variable)
    return override === nothing ? default : override
end

function edition_profiles(repo_root::AbstractString)
    return (
        EditionProfile(
            edition = "2024",
            label = "ISP 2024",
            report_root = configured_root(
                repo_root,
                "PISP_DOCS_ISP2024_REPORT_ROOT",
                joinpath("data", "2024", "pisp-reports"),
            ),
            download_root = configured_root(
                repo_root,
                "PISP_DOCS_ISP2024_DOWNLOAD_ROOT",
                joinpath("data", "2024", "pisp-downloads"),
            ),
            output_root = configured_root(
                repo_root,
                "PISP_DOCS_ISP2024_OUTPUT_ROOT",
                joinpath("data", "2024", "pisp-datasets", "out-ref4006-poe10", "csv"),
            ),
            schedule_tag = configured_schedule("PISP_DOCS_ISP2024_SCHEDULE_TAG", "schedule-2030"),
        ),
        EditionProfile(
            edition = "2026",
            label = "ISP 2026",
            report_root = configured_root(
                repo_root,
                "PISP_DOCS_ISP2026_REPORT_ROOT",
                joinpath("data", "2026", "pisp-reports"),
            ),
            download_root = configured_root(
                repo_root,
                "PISP_DOCS_ISP2026_DOWNLOAD_ROOT",
                joinpath("data", "2026", "pisp-downloads"),
            ),
            output_root = configured_root(repo_root, "PISP_DOCS_ISP2026_OUTPUT_ROOT", nothing),
            schedule_tag = configured_schedule("PISP_DOCS_ISP2026_SCHEDULE_TAG", nothing),
        ),
    )
end

function edition_profile(repo_root::AbstractString, edition::AbstractString)
    requested = strip(edition)
    for profile in edition_profiles(repo_root)
        profile.edition == requested && return profile
    end
    throw(ArgumentError("unknown ISP edition \"$requested\"; supported editions are \"2024\" and \"2026\""))
end

end
