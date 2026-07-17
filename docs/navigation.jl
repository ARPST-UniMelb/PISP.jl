module PISPDocsNavigation

using ..PISPDocsPageRegistry: is_published

export registry_navigation

const KIND_LABELS = Dict(
    "isp2024" => [
        "reference" => "Reference and inputs",
        "tutorial" => "Tutorials",
        "validation" => "Data validation",
        "analysis" => "Analyses and case studies",
    ],
    "isp2026" => [
        "reference" => "Reference and inputs",
        "tutorial" => "Tutorials",
        "validation" => "Data validation",
        "analysis" => "Analyses and case studies",
    ],
    "comparison" => [
        "reference" => "Reference and compatibility pages",
        "tutorial" => "Tutorials",
        "validation" => "Validation pages",
        "analysis" => "Analyses and case studies",
    ],
)

function track_sections(registry_pages, track)
    sections = Any[]
    for (kind, label) in KIND_LABELS[track]
        pages = sort(
            filter(page -> is_published(page) && page.track == track && page.kind == kind, registry_pages);
            by = page -> (page.nav_order, page.id),
        )
        isempty(pages) || push!(sections, label => Any[page.title => page.output for page in pages])
    end
    return sections
end

function track_navigation(registry_pages, track, overview_title, overview_path)
    navigation = Any[overview_title => overview_path]
    append!(navigation, track_sections(registry_pages, track))
    return navigation
end

function registry_navigation(registry_pages)
    navigation = Any["Home" => "index.md"]

    push!(
        navigation,
        "Understand PISP and ISP data" => Any[
            "Supported ISP editions" => "editions/supported-editions.md",
            "Domain concepts" => "concepts.md",
            "Output data model" => "editions/output-data-model.md",
            "Assumptions and scope" => "assumptions.md",
            "What each ISP edition publishes" => "editions/source-material.md",
            "Downloaded source inventory by edition" => "editions/source-inventory.md",
            "Trace families, schemas, and coverage" => "editions/trace-coverage.md",
            "Parameters and mappings across editions" => "editions/parameters-and-mappings.md",
        ],
    )
    push!(navigation, "ISP 2024" => track_navigation(registry_pages, "isp2024", "Overview", "editions/isp2024.md"))
    push!(navigation, "ISP 2026" => track_navigation(registry_pages, "isp2026", "Overview", "editions/isp2026.md"))
    push!(
        navigation,
        "Compare ISP 2024 and ISP 2026" =>
            track_navigation(registry_pages, "comparison", "Overview and comparison rules", "editions/comparison.md"),
    )
    push!(navigation, "API Reference" => "api.md")
    return navigation
end

end
