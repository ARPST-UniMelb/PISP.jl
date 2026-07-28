```@meta
EditURL = "../../../../literate/comparison/analysis/model_archive_comparison.jl"
```

# ISP 2024 and ISP 2026 model archive comparison

AEMO publishes a scenario-specific PLEXOS model archive for each ISP edition.
The [2024 ISP PLEXOS Model Instructions, p. 6](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=6)
and [2026 ISP PLEXOS Model Instructions, p. 6](../../../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=6)
identify the model ZIP alongside separate wind, solar, and timeslice ZIP files.
This comparison therefore describes the two model ZIPs, not the complete set
of published traces.

The analysis reads archive membership and ZIP metadata directly. It compares
scenario directories, XML files, trace families, file counts, uncompressed
sizes, and representative filenames without extracting the archive contents.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using Printf

const REPO_ROOT = normpath(
    get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..", "..")),
)
include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles: edition_profiles

const EXPECTED_YEARS = (2024, 2026)
const PROFILES = Dict(parse(Int, profile.edition) => profile for profile in edition_profiles(REPO_ROOT))
const ARCHIVES = Dict(
    year => joinpath(PROFILES[year].download_root, "zip", "$(year)-isp-model.zip")
    for year in EXPECTED_YEARS
)

all(isfile, values(ARCHIVES)) || error(
    "The comparison requires $(join(sort(collect(values(ARCHIVES))), ", ")).",
);
````

```@raw html
</details>
```

## Method

Only the ZIP central directory is needed for this comparison. Reading that
directory avoids expanding several hundred megabytes of CSV and XML data.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
struct ZipMember
    path::String
    compressed_bytes::Int
    uncompressed_bytes::Int
    is_directory::Bool
end

little_u16(bytes, index) =
    UInt16(bytes[index]) | (UInt16(bytes[index + 1]) << 8)

little_u32(bytes, index) =
    UInt32(bytes[index]) |
    (UInt32(bytes[index + 1]) << 8) |
    (UInt32(bytes[index + 2]) << 16) |
    (UInt32(bytes[index + 3]) << 24)

function end_of_central_directory(io)
    file_size = filesize(io)
    search_size = min(file_size, 65_557)
    seek(io, file_size - search_size)
    tail = read(io, search_size)
    signature = UInt8[0x50, 0x4b, 0x05, 0x06]

    for index in (length(tail) - 3):-1:1
        tail[index:(index + 3)] == signature || continue
        return (
            entries = Int(little_u16(tail, index + 10)),
            central_offset = Int(little_u32(tail, index + 16)),
        )
    end

    error("ZIP end-of-central-directory record not found")
end

function zip_members(path)
    open(path, "r") do io
        directory = end_of_central_directory(io)
        seek(io, directory.central_offset)
        members = ZipMember[]

        for _ in 1:directory.entries
            header = read(io, 46)
            length(header) == 46 || error("Truncated ZIP central-directory header in $path")
            little_u32(header, 1) == 0x02014b50 || error(
                "Unexpected ZIP central-directory signature in $path",
            )

            compressed_bytes = Int(little_u32(header, 21))
            uncompressed_bytes = Int(little_u32(header, 25))
            filename_length = Int(little_u16(header, 29))
            extra_length = Int(little_u16(header, 31))
            comment_length = Int(little_u16(header, 33))

            compressed_bytes == typemax(UInt32) && error("ZIP64 entry sizes are not supported")
            uncompressed_bytes == typemax(UInt32) && error("ZIP64 entry sizes are not supported")

            member_path = String(read(io, filename_length))
            skip(io, extra_length + comment_length)
            push!(
                members,
                ZipMember(
                    member_path,
                    compressed_bytes,
                    uncompressed_bytes,
                    endswith(member_path, "/"),
                ),
            )
        end

        return members
    end
end

Base.@kwdef struct ArchiveRecord
    year::Int
    archive::String
    root::String
    scenario::String
    family::String
    category::Union{Nothing, String} = nothing
    role::Union{Nothing, String} = nothing
    filename::String
    member_path::String
    compressed_bytes::Int
    uncompressed_bytes::Int
end

scenario_name(directory, year) = strip(replace(directory, Regex("^$(year)\\s+ISP\\s+") => ""))
xml_role(filename) = occursin("solverparam", lowercase(filename)) ?
    "PLEXOS solver parameters" : "PLEXOS model"

function inspect_archive(year, archive_path)
    records = ArchiveRecord[]

    for member in zip_members(archive_path)
        member.is_directory && continue
        parts = split(member.path, '/'; keepempty = false)
        length(parts) >= 2 || continue

        scenario = scenario_name(parts[2], year)
        filename = parts[end]
        extension = lowercase(splitext(filename)[2])
        family = "Other"
        category = nothing
        role = nothing

        if extension == ".xml"
            family = "XML"
            role = xml_role(filename)
        elseif extension == ".csv"
            trace_index = findfirst(==("Traces"), parts)
            if trace_index !== nothing && trace_index < length(parts)
                family = "CSV trace"
                category = parts[trace_index + 1]
            end
        end

        push!(
            records,
            ArchiveRecord(
                year = year,
                archive = basename(archive_path),
                root = parts[1],
                scenario = scenario,
                family = family,
                category = category,
                role = role,
                filename = filename,
                member_path = member.path,
                compressed_bytes = member.compressed_bytes,
                uncompressed_bytes = member.uncompressed_bytes,
            ),
        )
    end

    return records
end

const RECORDS = reduce(
    vcat,
    (inspect_archive(year, ARCHIVES[year]) for year in EXPECTED_YEARS),
)

struct MarkdownTable
    text::String
end

Base.show(io::IO, ::MIME"text/markdown", table::MarkdownTable) = print(io, table.text)
Base.show(io::IO, ::MIME"text/plain", table::MarkdownTable) = print(io, table.text)

function markdown_cell(value)
    value === nothing && return "—"
    text = replace(string(value), '\n' => " ")
    return replace(text, '|' => "\\|")
end

function markdown_table(headers, rows; alignment = fill(:left, length(headers)))
    length(alignment) == length(headers) || error("Table alignment does not match the columns")
    separators = Dict(:left => ":---", :right => "---:", :centre => ":---:")
    all(item -> haskey(separators, item), alignment) ||
        error("Unsupported Markdown alignment")

    lines = String[]
    push!(lines, "| " * join(markdown_cell.(headers), " | ") * " |")
    push!(lines, "| " * join((separators[item] for item in alignment), " | ") * " |")
    for row in rows
        length(row) == length(headers) || error("Table row does not match the columns")
        push!(lines, "| " * join(markdown_cell.(row), " | ") * " |")
    end
    return MarkdownTable(join(lines, "\n"))
end

records_for(year) = filter(record -> record.year == year, RECORDS)
unique_sorted(values) = sort!(unique(collect(values)))
mib(bytes) = bytes / 1024^2;
````

```@raw html
</details>
```

## Archive overview

Both model ZIPs contain three scenario directories and one PLEXOS model XML
file per scenario. The main structural difference is the amount and variety
of CSV material packaged beside those model files.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
archive_summary_rows = Vector{Any}[]
for year in EXPECTED_YEARS
    subset = records_for(year)
    push!(
        archive_summary_rows,
        Any[
            year,
            basename(ARCHIVES[year]),
            only(unique(record.root for record in subset)),
            length(unique(record.scenario for record in subset)),
            count(record -> record.family == "XML" && record.role == "PLEXOS model", subset),
            count(
                record -> record.family == "XML" && record.role == "PLEXOS solver parameters",
                subset,
            ),
            count(record -> record.family == "CSV trace", subset),
            @sprintf("%.1f", mib(sum(record.uncompressed_bytes for record in subset))),
        ],
    )
end

markdown_table(
    [
        "ISP year",
        "Archive",
        "Root folder",
        "Scenarios",
        "Model XML",
        "Solver XML",
        "CSV files",
        "Uncompressed MiB",
    ],
    archive_summary_rows;
    alignment = [:right, :left, :left, :right, :right, :right, :right, :right],
)
````

```@raw html
</details>
```

| ISP year | Archive | Root folder | Scenarios | Model XML | Solver XML | CSV files | Uncompressed MiB |
| ---: | :--- | :--- | ---: | ---: | ---: | ---: | ---: |
| 2024 | 2024-isp-model.zip | 2024 ISP Model | 3 | 3 | 3 | 84 | 472.6 |
| 2026 | 2026-isp-model.zip | 2026 ISP Model | 3 | 3 | 0 | 345 | 572.0 |

The 2026 archive packages 345 CSV files, compared with 84 in the 2024
archive, and introduces several trace families that are not present in the
2024 model ZIP.

## Scenario continuity

The directory names change between editions, but AEMO provides the lineage.
The 2025 Inputs, Assumptions and Scenarios Report identifies Step Change as
continuing Step Change ([p. 18](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=18)),
Slower Growth as the successor to Progressive Change
([p. 19](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=19)),
and Accelerated Transition as a refinement of Green Energy Exports
([p. 20](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=20)).

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
const SCENARIO_MAPPING = [
    (
        scenario_2024 = "Green Energy Exports",
        scenario_2026 = "Accelerated Transition",
        relationship = "Refined successor",
        citation = "2025 IASR, p. 20",
    ),
    (
        scenario_2024 = "Progressive Change",
        scenario_2026 = "Slower Growth",
        relationship = "Renamed successor",
        citation = "2025 IASR, p. 19",
    ),
    (
        scenario_2024 = "Step Change",
        scenario_2026 = "Step Change",
        relationship = "Same scenario name",
        citation = "2025 IASR, p. 18",
    ),
]

scenarios_2024 = unique_sorted(record.scenario for record in records_for(2024))
scenarios_2026 = unique_sorted(record.scenario for record in records_for(2026))
@assert sort([row.scenario_2024 for row in SCENARIO_MAPPING]) == scenarios_2024
@assert sort([row.scenario_2026 for row in SCENARIO_MAPPING]) == scenarios_2026

markdown_table(
    ["ISP 2024 scenario", "ISP 2026 scenario", "Relationship", "Evidence"],
    [
        Any[row.scenario_2024, row.scenario_2026, row.relationship, row.citation]
        for row in SCENARIO_MAPPING
    ],
)
````

```@raw html
</details>
```

| ISP 2024 scenario | ISP 2026 scenario | Relationship | Evidence |
| :--- | :--- | :--- | :--- |
| Green Energy Exports | Accelerated Transition | Refined successor | 2025 IASR, p. 20 |
| Progressive Change | Slower Growth | Renamed successor | 2025 IASR, p. 19 |
| Step Change | Step Change | Same scenario name | 2025 IASR, p. 18 |

The crosswalk describes scenario lineage. It does not imply that assumptions
or model inputs are unchanged between editions.

## XML packaging

Each archive contains one model XML file per scenario. ISP 2024 also stores a
separate `PLEXOS_Solverparam.xml` file in each scenario directory; the 2026
model ZIP has no separate XML file with that role.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
xml_role_rows = Vector{Any}[]
for role in ["PLEXOS model", "PLEXOS solver parameters"]
    push!(
        xml_role_rows,
        Any[
            role,
            count(record -> record.family == "XML" && record.role == role && record.year == 2024, RECORDS),
            count(record -> record.family == "XML" && record.role == role && record.year == 2026, RECORDS),
        ],
    )
end

markdown_table(
    ["XML role", "ISP 2024 files", "ISP 2026 files"],
    xml_role_rows;
    alignment = [:left, :right, :right],
)
````

```@raw html
</details>
```

| XML role | ISP 2024 files | ISP 2026 files |
| :--- | ---: | ---: |
| PLEXOS model | 3 | 3 |
| PLEXOS solver parameters | 3 | 0 |

The missing standalone solver-parameter file is a packaging difference. The
location and representation of solver settings in the 2026 model must be
established from the model evidence.

## Trace families inside the model ZIPs

File counts are consistent across the three scenarios within each edition,
so the table reports files per scenario. The 2026 model ZIP adds DNSP, gas,
and rooftop-PV families, expands hydro material, and includes three more
demand files per scenario. Load-subtractor counts remain unchanged.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
function trace_counts_by_scenario(year)
    counts = Dict{Tuple{String, String}, Int}()
    for record in records_for(year)
        record.family == "CSV trace" || continue
        key = (record.scenario, something(record.category))
        counts[key] = get(counts, key, 0) + 1
    end
    return counts
end

function files_per_scenario(year, category)
    counts = trace_counts_by_scenario(year)
    observed = [
        count
        for ((_, observed_category), count) in counts
        if observed_category == category
    ]
    isempty(observed) && return 0
    length(unique(observed)) == 1 || error(
        "Trace count for $category is inconsistent across ISP $year scenarios",
    )
    return only(unique(observed))
end

humanise_category(category) = replace(
    titlecase(replace(category, '_' => ' ')),
    "Dnsp" => "DNSP",
    "Pv" => "PV",
    "Load Subtractor" => "Load subtractor",
)

trace_categories = unique_sorted(
    record.category for record in RECORDS
    if record.family == "CSV trace" && record.category !== nothing
)
trace_family_rows = Vector{Any}[]
for category in trace_categories
    count_2024 = files_per_scenario(2024, category)
    count_2026 = files_per_scenario(2026, category)
    coverage = count_2024 > 0 && count_2026 > 0 ? "Both model ZIPs" :
        count_2024 > 0 ? "ISP 2024 model ZIP only" : "ISP 2026 model ZIP only"
    push!(
        trace_family_rows,
        Any[humanise_category(category), count_2024, count_2026, coverage],
    )
end
push!(
    trace_family_rows,
    Any[
        "Total",
        sum(files_per_scenario(2024, category) for category in trace_categories),
        sum(files_per_scenario(2026, category) for category in trace_categories),
        "—",
    ],
)

markdown_table(
    ["Trace family", "ISP 2024", "ISP 2026", "Archive coverage"],
    trace_family_rows;
    alignment = [:left, :right, :right, :left],
)
````

```@raw html
</details>
```

| Trace family | ISP 2024 | ISP 2026 | Archive coverage |
| :--- | ---: | ---: | :--- |
| Demand | 12 | 15 | Both model ZIPs |
| DNSP | 0 | 38 | ISP 2026 model ZIP only |
| Gas | 0 | 11 | ISP 2026 model ZIP only |
| Hydro | 7 | 23 | Both model ZIPs |
| Load subtractor | 9 | 9 | Both model ZIPs |
| Rooftop PV | 0 | 19 | ISP 2026 model ZIP only |
| Total | 28 | 115 | — |

## Representative filenames

The filenames below are the first alphabetically within each family and
edition. They expose concrete parser differences without claiming that the
selected files contain equivalent data.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
function first_filename(year, category)
    filenames = unique_sorted(
        record.filename for record in records_for(year)
        if record.family == "CSV trace" && record.category == category
    )
    return isempty(filenames) ? "—" : "`$(first(filenames))`"
end

filename_rows = Vector{Any}[]
for category in trace_categories, year in EXPECTED_YEARS
    filename = first_filename(year, category)
    filename == "—" && continue
    push!(filename_rows, Any[humanise_category(category), year, filename])
end

markdown_table(
    ["Trace family", "ISP year", "Example filename"],
    filename_rows;
    alignment = [:left, :right, :left],
)
````

```@raw html
</details>
```

| Trace family | ISP year | Example filename |
| :--- | ---: | :--- |
| Demand | 2024 | `CNSW_RefYear_4006_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv` |
| Demand | 2026 | `CNSW_RefYear_5000_ACCELERATED_TRANSITION_POE10_OPSO_MODELLING_PVLITE.csv` |
| DNSP | 2026 | `CNSW_ESS_RefYear_5000_GREEN_ENERGY_EXPORTS_LV_C1.csv` |
| Gas | 2026 | `GPG_Limit_AT_S__Colongra_GPG_Limit_TJ_5000_POE10.csv` |
| Hydro | 2024 | `MaxEnergyYear_LT_RefYear4006_HydrogenSuperpower.csv` |
| Hydro | 2026 | `DailyNaturalInflow_AnthonyPieman_RefYear5000_Flat.csv` |
| Load subtractor | 2024 | `Solar_NSW_GREEN_ENERGY_EXPORTS_RefYear4006.csv` |
| Load subtractor | 2026 | `LS_NSW_Solar_ACCELERATED_TRANSITION_RefYear5000.csv` |
| Rooftop PV | 2026 | `CNSW_Area1_RefYear_5000_ACCELERATED_TRANSITION_POE10_PV_TOT.csv` |

The 2026 examples show why parser logic cannot rely on one scenario token.
The Accelerated Transition directory includes DNSP filenames containing
`GREEN_ENERGY_EXPORTS`, while gas filenames use the shorter `AT` alias.

## Implications for PISP

The archive comparison establishes several requirements for an ISP 2026
parser:

1. Scenario selection needs the published lineage above rather than a direct
   string match.
2. Trace discovery needs edition-specific family and filename rules. The 2026
   model ZIP contains additional families and different naming conventions.
3. A complete trace comparison must also load the separately published wind,
   solar, and timeslice ZIPs identified by AEMO.
4. CSV schemas, units, timestamp coverage, and model-XML references must be
   compared before files from different editions are treated as equivalent.
5. Solver configuration should be located from the 2026 model evidence rather
   than inferred from the absence of `PLEXOS_Solverparam.xml`.

The next mapping stage can use this inventory to define explicit source-file,
scenario, trace-family, schema, and XML-reference crosswalks.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
model_xml_counts = Dict{Tuple{Int, String}, Int}()
for record in RECORDS
    record.family == "XML" && record.role == "PLEXOS model" || continue
    key = (record.year, record.scenario)
    model_xml_counts[key] = get(model_xml_counts, key, 0) + 1
end
@assert all(==(1), values(model_xml_counts))
@assert Set(record.year for record in RECORDS) == Set(EXPECTED_YEARS)
@assert all(isfile, values(ARCHIVES))

println("Validated archive discovery, scenario coverage, XML roles, and trace-family counts.")
````

```@raw html
</details>
```

````
Validated archive discovery, scenario coverage, XML roles, and trace-family counts.

````

