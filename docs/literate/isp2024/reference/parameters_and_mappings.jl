# # ISP 2024: Parameters and mappings
#
# PISP combines values published by AEMO with package-defined identifiers, defaults, aliases, and source-to-output mappings.
# The distinction matters because a downloaded workbook can remain unchanged while a package convention changes the generated dataset.
# This page identifies the authority for each parameter and mapping family, then presents the general mappings shared across the ISP 2024 workflow.

using PISP
using DataFrames
using Dates

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

coverage = PISPDocUtils.coverage_document(REPO_ROOT)
parameter_families = PISPDocUtils.coverage_table(coverage, "parameter_family")
mapping_families = PISPDocUtils.coverage_table(coverage, "mapping_family")

length(unique(parameter_families.id)) == nrow(parameter_families) || error("parameter-family IDs must be unique")
length(unique(mapping_families.id)) == nrow(mapping_families) || error("mapping-family IDs must be unique")
nothing #hide

# ## AEMO values and PISP conventions
#
# AEMO source values remain attributable to the workbook, model archive, report, or CSV that publishes them.
# PISP conventions are maintained in package parameter files, parser-local mappings, or user-controlled build-out inputs.
# Parsed representations are mechanical normalisations or runtime joins derived from those sources rather than independent external facts.

classification_roles = DataFrame([
    (
        classification = PISPDocUtils.friendly_classification("aemo_raw_source"),
        authority = "AEMO publication",
        meaning = "A value or record read directly from an AEMO workbook, model CSV, or report-backed source.",
    ),
    (
        classification = PISPDocUtils.friendly_classification("parsed_representation"),
        authority = "PISP transformation",
        meaning = "A normalised label, runtime lookup, or join derived from source records.",
    ),
    (
        classification = PISPDocUtils.friendly_classification("pisp_generated_intermediate"),
        authority = "PISP preprocessing",
        meaning = "An Auxiliary workbook generated from AEMO outlook workbooks and consumed by the parser.",
    ),
    (
        classification = PISPDocUtils.friendly_classification("package_convention"),
        authority = "PISP package",
        meaning = "A maintained identifier, default, alias, allocation rule, or source-file convention.",
    ),
    (
        classification = PISPDocUtils.friendly_classification("user_input"),
        authority = "PISP user",
        meaning = "An optional build-out or other value supplied when the workflow is run.",
    ),
    (
        classification = PISPDocUtils.friendly_classification("pisp_output"),
        authority = "PISP data model",
        meaning = "A generated table, field, or schema contract exposed to dataset users.",
    ),
])
PISPDocUtils.markdown_table(classification_roles)
#-

# ## Parameter-file ownership
#
# `PISPparameters.jl` includes six parameter files.
# Each file has one canonical documentation owner so that the package does not maintain a second handwritten copy of its constants.
# Subject pages describe how the relevant source data and conventions interact; the tables displayed there are generated from the imported PISP objects wherever practical.

parameter_owners = select(
    parameter_families,
    :source_path => ByRow(basename) => :parameter_file,
    :family,
    :classification,
    :owner => :canonical_page_id,
    :notes,
)
parameter_owners.classification = PISPDocUtils.friendly_classification.(parameter_owners.classification)
PISPDocUtils.markdown_table(parameter_owners)
#-

# ## Mapping-family ownership
#
# The mapping ledger covers source downloads, scenarios, geography, generation, storage, retirement, reliability, renewable energy zones, demand-side participation, electric vehicles, hydro, optional build-outs, and output schemas.
# Package conventions and parsed representations are listed separately because only the former are maintained as project choices.

mapping_owner_summary = combine(
    groupby(mapping_families, [:classification, :owner]),
    nrow => :mapping_families,
)
sort!(mapping_owner_summary, [:classification, :owner])
mapping_owner_summary.classification = PISPDocUtils.friendly_classification.(mapping_owner_summary.classification)
PISPDocUtils.markdown_table(mapping_owner_summary)
#-

mapping_inventory = select(
    mapping_families,
    :family,
    :classification,
    :owner => :canonical_page_id,
    :source_path,
)
sort!(mapping_inventory, [:classification, :canonical_page_id, :family])
mapping_inventory.classification = PISPDocUtils.friendly_classification.(mapping_inventory.classification)
PISPDocUtils.markdown_table(mapping_inventory)
#-

# ## Scenario identifiers and source labels
#
# The problem-table and build-out paths iterate `PISP.ID2SCE` to create rows for the package's three scenario IDs.
# The hydro parser uses `PISP.HYDROSCE` to select PLEXOS hydro labels, while the 4006 demand builder uses `PISP.DEMSCE` in source and output filenames.
# These mappings therefore affect generated data rather than serving only as display labels.

scenario_mappings = DataFrame([
    (
        scenario_id = scenario_id,
        scenario_name = scenario_name,
        hydro_label = PISP.HYDROSCE[scenario_name],
        demand_trace_label = PISP.DEMSCE[scenario_name],
    )
    for (scenario_id, scenario_name) in PISP.ID2SCE
])
PISPDocUtils.markdown_table(scenario_mappings)
#-

# ## Bus and area constants
#
# The bus constants provide the package's stable spatial identifiers, display names, area assignments, and representative coordinates.
# Source rows are assigned to these identifiers during parsing, so the aliases are part of the PISP data contract rather than AEMO workbook values.

bus_aliases = collect(keys(PISP.NEMBUSNAME))
bus_area_mappings = DataFrame([
    (
        bus_id = index,
        alias = alias,
        name = PISP.NEMBUSNAME[alias],
        area = PISP.BUS2AREA[alias],
        area_id = PISP.STID[PISP.BUS2AREA[alias]],
        latitude = PISP.NEMBUSES[alias][1],
        longitude = PISP.NEMBUSES[alias][2],
    )
    for (index, alias) in enumerate(bus_aliases)
])
PISPDocUtils.markdown_table(bus_area_mappings)
#-

# ## Reference trace 4006 weather-year mapping
#
# The composite trace maps each financial-year interval to a historical reference year.
# Repeated historical years are part of the mapping and should be considered when comparing planning periods.
#
# AEMO explains the rolling-reference-year method in the [2024 ISP PLEXOS Model Instructions, p. 5](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5).
# The Reference Year and VRE Reference Year sequence is in Table 1 of the [2024 ISP PLEXOS Model Instructions, p. 6](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=6); the table's Hydrological Reference Year is a distinct sequence.
# PISP stores the ending year of each report range: AEMO's `2018-19` reference year, for example, is represented as `2019` for the interval from 1 July 2024 through 30 June 2025.
#
# The 4006 solar, wind, and demand builders consume `PISP.ISPdatabuilder.DATE_RANGES_REFYEARS`.
# The current implementation does not parse this mapping from the 2024 Inputs and Assumptions workbook.

weather_year_mapping = DataFrame([
    (
        financial_year_start = financial_year_start,
        financial_year_end = financial_year_end,
        reference_year_ending = reference_year_ending,
    )
    for (financial_year_start, financial_year_end, reference_year_ending) in PISP.ISPdatabuilder.DATE_RANGES_REFYEARS
])
PISPDocUtils.markdown_table(weather_year_mapping)
#-

# ## Reliability fields represented in static schemas
#
# PISP's static schemas distinguish full outages, partial outages, derating, repair time, and state-dependent output where the asset table supports them.
# The AEMO reliability and retirement source records that populate these fields are described in [Generator reliability and retirement](../../shared/source-material/generator-reliability-and-retirement.md) and [Network and transmission assumptions](../../shared/source-material/network-and-transmission.md).

function reliability_fields(table_name)
    schema = PISP.TABLES_POWERSYSTEM[table_name]
    names = [
        column
        for column in keys(schema)
        if occursin(r"forate|out|derate|mttr"i, column)
    ]
    return join(names, ", ")
end

reliability_schema = DataFrame([
    (asset_table = table_name, fields = reliability_fields(table_name))
    for table_name in ("Generator", "ESS", "Line")
])
PISPDocUtils.markdown_table(reliability_schema)
#-

# ## Using the mappings
#
# Scenario labels, source-specific aliases, bus assignments, weather-year mappings, technology groupings, retirement schedules, and build-out templates are modelling inputs rather than incidental filenames.
# Changes to these mappings can change generated datasets without any change to the downloaded source files.
#
# Optional build-out technology labels select complete PISP generator or storage templates.
# See [ISP 2024 build-out defaults](buildout-defaults.md) for the field-level values, calculated fields, placeholders, and override rules.
#
# Rooftop PV and utility-scale renewable capacity fields require special care.
# The time-varying schedule is the relevant maximum-output series for solar and wind; the static `pmax` field is not a universal capacity-factor denominator.
# See [Assumptions and scope](@ref).
#
# The source selections for operating capacity, storage, renewable energy zones, and other workbook subjects are documented in the shared [AEMO ISP source coverage and ownership](../../shared/source-material/coverage-and-ownership.md) family.
# That family keeps workbook evidence beside its data meaning while this page remains the canonical index for package-defined parameters and mappings.
