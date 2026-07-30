# # ISP 2024: Temperature information and PISP coverage
#
# The 2024 ISP Inputs and Assumptions workbook contains temperature-related assumptions, but it does not provide an observed ambient-temperature time series for PISP.
# The current PISP.jl parser also does not read the workbook's temperature lookup tables or export a temperature field.
#
# This distinction matters for weather-aware studies: regional reference temperatures and temperature-dependent network limits are model assumptions, while an hourly weather series is an external input that needs its own source and mapping.

using DataFrames
using XLSX

repo_root = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(repo_root, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

include(joinpath(repo_root, "docs", "eda_support.jl"))
using .EdaSupport

isp2024_profile = edition_profile(repo_root, "2024")
workbook_path = joinpath(isp2024_profile.download_root, "2024-isp-inputs-and-assumptions-workbook.xlsx")
isfile(workbook_path) || error("ISP 2024 inputs workbook not found: $workbook_path")
nothing #hide

# ## What temperature information is present?
#
# The workbook uses temperature in three distinct ways:
#
# 1. global warming outcomes help define the three ISP scenarios and their carbon budgets;
# 2. regional reference temperatures support seasonal network and generator assumptions;
# 3. a temperature-to-transfer-capability lookup describes Murraylink limits in the source model.
#
# These are static assumptions and lookup values. They are not a local, timestamped meteorological record.

# ## Scenario-level temperature assumptions
#
# The temperature values below describe global scenario outcomes used in the ISP scenario framework.
# They do not describe weather at a generator, transmission line, or demand region.

scenario_temperature = XLSX.openxlsx(workbook_path) do workbook
    carbon_budget_cells = workbook["Carbon Budgets"]["B7:E10"]
    DataFrame(
        :Scenario => string.(carbon_budget_cells[1, 2:4]),
        Symbol("Global mean temperature increase by 2100") => string.(carbon_budget_cells[2, 2:4]),
        Symbol("NEM carbon budget, FY2025-52 (Mt CO₂-e)") => Int.(carbon_budget_cells[4, 2:4]),
    )
end

markdown_table(scenario_temperature)

# ## Regional reference temperatures
#
# The network-capability sheet provides regional reference temperatures for summer peak, summer typical, and winter typical conditions.
# South Australia has the highest listed summer 10% POE demand reference temperature, at 43 °C.
# This is a modelling reference for peak conditions, not evidence that every South Australian location experiences the same temperature.

regional_reference_temperature = XLSX.openxlsx(workbook_path) do workbook
    regional_cells = workbook["Network Capability"]["B77:E82"]
    seasonal_rating_rule = string(workbook["Seasonal ratings"]["B8"])

    occursin("POE10 reference temperature", seasonal_rating_rule) || error(
        "Expected the seasonal-rating hot-day rule in Seasonal ratings!B8",
    )

    DataFrame(
        :Region => string.(regional_cells[2:end, 1]),
        Symbol("Summer 10% POE reference (°C)") => Float64.(regional_cells[2:end, 2]),
        Symbol("Summer typical (°C)") => string.(regional_cells[2:end, 3]),
        Symbol("Winter typical (°C)") => Float64.(regional_cells[2:end, 4]),
    )
end

markdown_table(regional_reference_temperature)

# The generator seasonal-rating rule uses a regional POE10 reference temperature to identify hot days.
# When fewer than five days exceed the threshold, the source workbook uses the five hottest days of that year.

# ## Temperature-dependent Murraylink capability
#
# The source workbook includes an explicit ambient-temperature lookup for Murraylink.
# Capability is 220 MW through 38 °C, declines above that point, and reaches zero at 46 °C.

murraylink_temperature_capability = XLSX.openxlsx(workbook_path) do workbook
    murraylink_cells = workbook["Network Capability"]["B89:D104"]
    DataFrame(
        Symbol("Ambient temperature (°C)") => string.(murraylink_cells[2:end, 1]),
        Symbol("Forward capability (MW)") => Float64.(murraylink_cells[2:end, 2]),
        Symbol("Reverse capability (MW)") => Float64.(murraylink_cells[2:end, 3]),
    )
end

markdown_table(murraylink_temperature_capability)

# ## What PISP.jl currently uses
#
# PISP.jl reads the first network-capability table, which contains seasonal forward and reverse limits.
# The later regional-temperature and Murraylink lookup tables are outside the range currently read by `line_table`.
# The package source also contains no field or parser identifier named `temperature`.

parser_path = joinpath(repo_root, "src", "parsers", "PISP-2024parser.jl")
parser_text = read(parser_path, String)
network_capability_ranges = [
    match_result.captures[1]
    for match_result in eachmatch(r"\"Network Capability\",\s*\"([^\"]+)\"", parser_text)
]

source_files = String[]
for (directory, _, files) in walkdir(joinpath(repo_root, "src"))
    for file in files
        endswith(file, ".jl") && push!(source_files, joinpath(directory, file))
    end
end

temperature_source_hits = [
    relpath(path, repo_root)
    for path in source_files
    if occursin(r"\btemperature\b"i, read(path, String))
]

package_coverage = DataFrame(
    Layer = [
        "AEMO workbook",
        "PISP network parser",
        "PISP source and data model",
        "PISP renewable traces",
    ],
    Coverage = [
        "Static temperature assumptions and lookup tables are present",
        "Reads Network Capability $(join(network_capability_ranges, ", ")); does not read B77:E82 or B89:D104",
        isempty(temperature_source_hits) ? "No exact temperature field or parser identifier" : join(temperature_source_hits, ", "),
        "Solar and wind capacity factors, not ambient temperature",
    ],
    Consequence = [
        "Useful as source assumptions",
        "Temperature-dependent limits are not carried into current PISP line tables",
        "No temperature series or temperature-response function is exported",
        "Cannot be used as a substitute for meteorological temperature data",
    ],
)
markdown_table(package_coverage; alignment = [:l, :l, :l])

# The `derate` field in `Generator.csv` is populated from the workbook's generator-reliability settings for partial outages.
# It is not a temperature-driven derating curve.

# ## Implication for weather-aware studies
#
# A temperature-aware PISP study needs three additions outside the current ISP 2024 dataset contract:
#
# 1. an observed or climate-model temperature time series with explicit spatial and temporal coverage;
# 2. a mapping from weather locations to generators, lines, demand regions, or other assets;
# 3. component response models that convert temperature into capacity, availability, demand, or network-limit changes.
#
# The ISP workbook can inform assumptions and validation, but it cannot supply the meteorological time series or the missing response models by itself.
