```@meta
EditURL = "../../../../literate/shared/reference/pisp_downloads_layout.jl"
```

# ISP 2024 and ISP 2026 downloaded source layout

Each ISP edition keeps downloaded source material and extracted source
directories under `data/<edition>/pisp-downloads/`. The ISP 2024 tree also
contains `Auxiliary/`, which PISP generates from the outlook workbooks during
preprocessing.

The main directory roles are:

```text
pisp-downloads/
├── Core/ or Core scenarios/   # extracted outlook workbooks
├── Sensitivities/             # extracted outlook sensitivities
├── Auxiliary/                 # ISP 2024 PISP-generated intermediates
├── Traces/                    # extracted trace inputs
└── zip/                       # retained source archives
```

The extracted `<edition> ISP Model/` directory is a separate model-archive
source family.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
const REPO_ROOT = normpath(
    get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..", "..")),
)
include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
include(joinpath(REPO_ROOT, "docs", "download_layout.jl"))
using .PISPDocsEditionProfiles: edition_profiles
using .PISPDocsDownloadLayout: inspect_download_layout

const DOWNLOAD_LAYOUTS = [
    inspect_download_layout(profile.label, profile.download_root)
    for profile in edition_profiles(REPO_ROOT)
]
````

```@raw html
</details>
```

## Observed outlook directories and source archives

The inventory is read from the configured edition roots. The outlook column
contains the top-level extracted workbook directories after separating
`Auxiliary`, `Traces`, `zip`, manifest directories, and directories ending in
`ISP Model` into their own source families. The archive column lists direct
ZIP files under `pisp-downloads/zip/`; trace archives stored below
`zip/Traces/` remain part of the trace source family.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
struct MarkdownTable
    text::String
end

Base.show(io::IO, ::MIME"text/markdown", table::MarkdownTable) = print(io, table.text)
Base.show(io::IO, ::MIME"text/plain", table::MarkdownTable) = print(io, table.text)

markdown_cell(value) = replace(replace(string(value), '\n' => "<br>"), '|' => "\\|")
markdown_items(values) = isempty(values) ? "—" : join(("`$(markdown_cell(value))`" for value in values), "<br>")

function markdown_table(headers, rows)
    lines = String[]
    push!(lines, "| " * join(markdown_cell.(headers), " | ") * " |")
    push!(lines, "| " * join(fill(":---", length(headers)), " | ") * " |")
    for row in rows
        length(row) == length(headers) || error("table row does not match the headers")
        push!(lines, "| " * join(markdown_cell.(row), " | ") * " |")
    end
    return MarkdownTable(join(lines, "\n"))
end

layout_rows = [
    Any[
        layout.edition,
        markdown_items(layout.outlook_directories),
        markdown_items(layout.source_archives),
    ]
    for layout in DOWNLOAD_LAYOUTS
]

markdown_table(
    ["Edition", "Extracted outlook directories", "Retained source archives"],
    layout_rows,
)
````

```@raw html
</details>
```

| Edition | Extracted outlook directories | Retained source archives |
| :--- | :--- | :--- |
| ISP 2024 | `Core`<br>`Sensitivities` | `2024-isp-generation-and-storage-outlook.zip`<br>`2024-isp-model.zip` |
| ISP 2026 | `Core scenarios`<br>`Sensitivities` | `2026-isp-generation-and-storage-outlook.zip`<br>`2026-isp-model.zip` |

`Core` or `Core scenarios` and `Sensitivities` contain the extracted
generation-and-storage-outlook workbooks. The other branches have distinct
source or preprocessing roles.

