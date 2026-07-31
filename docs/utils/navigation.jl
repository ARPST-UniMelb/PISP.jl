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
)

const COMPARISON_DATA_LAYER_LABELS = [
    "source-data" => "ISP source data",
    "package-workflow" => "PISP transformation",
    "pisp-dataset" => "PISP datasets",
    "cross-layer" => "Cross-layer comparisons",
]

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

function comparison_sections(registry_pages)
    sections = Any[]
    for (data_layer, label) in COMPARISON_DATA_LAYER_LABELS
        pages = sort(
            filter(
                page -> is_published(page) &&
                    page.track == "comparison" &&
                    page.data_layer == data_layer,
                registry_pages,
            );
            by = page -> (page.nav_order, page.id),
        )
        isempty(pages) || push!(sections, label => Any[page.title => page.output for page in pages])
    end
    return sections
end

function comparison_navigation(registry_pages)
    navigation = Any["Overview and comparison rules" => "editions/comparison.md"]
    append!(navigation, comparison_sections(registry_pages))
    return navigation
end

function shared_source_pages(registry_pages)
    pages = sort(
        filter(
            page -> is_published(page) &&
                page.track == "shared" &&
                page.data_layer == "source-data",
            registry_pages,
        );
        by = page -> (page.nav_order, page.id),
    )
    return Any[page.title => page.output for page in pages]
end

function shared_lifecycle_navigation(registry_pages)
    source_pages = Any["Source material by edition" => "editions/source-material.md"]
    append!(source_pages, shared_source_pages(registry_pages))
    push!(source_pages, "Trace families and source meaning" => "editions/trace-coverage.md")

    return Any[
        "ISP source data" => source_pages,
        "PISP transformation" => Any[
            "Workflow support by edition" => "editions/supported-editions.md",
            "Source-to-dataset processing" => "editions/source-inventory.md",
            "Parameters, mappings, and constants" => "editions/parameters-and-mappings.md",
        ],
        "PISP datasets" => Any[
            "Assets, relationships, and schedules" => "concepts.md",
            "Output tables, fields, and units" => "editions/output-data-model.md",
            "Dataset interpretation and study bounds" => "assumptions.md",
        ],
    ]
end

function registry_navigation(registry_pages)
    navigation = Any[
        "Home" => "index.md",
        "Quickstart" => "quickstart.md",
    ]

    push!(
        navigation,
        "Understand PISP and ISP data" => shared_lifecycle_navigation(registry_pages),
    )
    isp2024_navigation = track_navigation(registry_pages, "isp2024", "Overview", "editions/isp2024.md")
    insert!(isp2024_navigation, 2, "Preprocessing workflow" => "editions/isp2024-preprocessing.md")
    push!(navigation, "ISP 2024" => isp2024_navigation)
    push!(navigation, "ISP 2026" => track_navigation(registry_pages, "isp2026", "Overview", "editions/isp2026.md"))
    push!(
        navigation,
        "Compare ISP 2024 and ISP 2026" => comparison_navigation(registry_pages),
    )
    push!(navigation, "Contributing" => "contributing.md")
    push!(navigation, "API Reference" => "api.md")
    return navigation
end
