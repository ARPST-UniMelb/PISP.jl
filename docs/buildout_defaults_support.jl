module PISPDocsBuildoutDefaults

using PISP
using DataFrames

export ESS_TEMPLATE_FIELDS,
    GEN_TEMPLATE_FIELDS,
    ESS_FIELD_METADATA,
    GEN_FIELD_METADATA,
    buildout_technology_rows,
    buildout_origin_rows,
    buildout_placeholder_rows,
    template_comparison_rows,
    split_common_rows,
    comparison_frame,
    field_metadata_frame,
    technology_value_frame,
    buildout_reference_tables,
    parser_template_fields,
    validate_buildout_defaults_contract

const ESS_TEMPLATE_FIELDS = [
    "tech", "type", "investment", "active", "ch_eff", "dch_eff", "eini", "emin",
    "pmin", "lmin", "fullout", "partialout", "mttrfull", "mttrpart", "inertia",
    "powerfactor", "ffr", "pfr", "res2", "res3", "fr_db", "fr_ad", "fr_dt",
    "fr_frt", "fr_fr", "n", "contingency",
]

const GEN_TEMPLATE_FIELDS = [
    "fuel", "tech", "type", "forate", "fullout", "partialout", "derate", "mttrfull",
    "mttrpart", "pmin", "rup", "rdw", "investment", "active", "cvar", "cfuel", "cvom",
    "cfom", "co2", "slope", "hrate", "pfrmax", "g", "inertia", "ffr", "pfr", "res2",
    "res3", "powerfactor", "n", "contingency", "down_time", "up_time", "last_state",
    "last_state_period", "last_state_output", "start_up_cost", "shut_down_cost",
    "start_up_time", "shut_down_time",
]

const ESS_FIELD_METADATA = Dict(
    "tech" => (meaning = "Storage technology written to `ESS.tech`.", unit = "category"),
    "type" => (meaning = "Storage-duration classification written to `ESS.type`.", unit = "category"),
    "investment" => (meaning = "Investment flag.", unit = "0/1 flag"),
    "active" => (meaning = "Active-status flag.", unit = "0/1 flag"),
    "ch_eff" => (meaning = "Charging efficiency under PISP's stored-fraction convention.", unit = "fraction"),
    "dch_eff" => (meaning = "Discharging efficiency under PISP's stored-fraction convention.", unit = "fraction"),
    "eini" => (meaning = "Initial stored-energy level relative to `emax`.", unit = "fraction"),
    "emin" => (meaning = "Minimum stored-energy level relative to `emax`.", unit = "fraction"),
    "pmin" => (meaning = "Minimum discharging power per unit.", unit = "MW"),
    "lmin" => (meaning = "Minimum charging input per unit.", unit = "MW"),
    "fullout" => (meaning = "Full forced-outage rate.", unit = "fraction of time"),
    "partialout" => (meaning = "Partial forced-outage rate.", unit = "fraction of time"),
    "mttrfull" => (meaning = "Mean time to repair after a full outage.", unit = "h"),
    "mttrpart" => (meaning = "Mean time to repair after a partial outage.", unit = "h"),
    "inertia" => (meaning = "Meaning not defined in PISP.", unit = "Not defined in PISP."),
    "powerfactor" => (meaning = "Power-factor parameter.", unit = "ratio"),
    "ffr" => (meaning = "Fast-frequency-response provision flag.", unit = "0/1 flag"),
    "pfr" => (meaning = "Primary-frequency-response provision flag.", unit = "0/1 flag"),
    "res2" => (meaning = "Secondary-reserve provision flag.", unit = "0/1 flag"),
    "res3" => (meaning = "Tertiary or regulation-reserve provision flag.", unit = "0/1 flag"),
    "fr_db" => (meaning = "Meaning not defined in PISP.", unit = "Not defined in PISP."),
    "fr_ad" => (meaning = "Meaning not defined in PISP.", unit = "Not defined in PISP."),
    "fr_dt" => (meaning = "Meaning not defined in PISP.", unit = "Not defined in PISP."),
    "fr_frt" => (meaning = "Meaning not defined in PISP.", unit = "Not defined in PISP."),
    "fr_fr" => (meaning = "Meaning not defined in PISP.", unit = "Not defined in PISP."),
    "n" => (meaning = "Static maximum unit-count field; the build-out schedule supplies the time-varying count.", unit = "units"),
    "contingency" => (meaning = "Contingency-classification flag.", unit = "0/1 flag"),
)

const GEN_FIELD_METADATA = Dict(
    "fuel" => (meaning = "Generator fuel category.", unit = "category"),
    "tech" => (meaning = "Generator technology.", unit = "category"),
    "type" => (meaning = "Generator type or planning classification.", unit = "category"),
    "forate" => (meaning = "Aggregate availability factor after full- and partial-outage effects.", unit = "fraction"),
    "fullout" => (meaning = "Full forced-outage rate.", unit = "fraction of time"),
    "partialout" => (meaning = "Partial forced-outage rate.", unit = "fraction of time"),
    "derate" => (meaning = "Capacity derating during a partial outage.", unit = "fraction"),
    "mttrfull" => (meaning = "Mean time to repair after a full outage.", unit = "h"),
    "mttrpart" => (meaning = "Mean time to repair after a partial outage.", unit = "h"),
    "pmin" => (meaning = "Minimum power output per unit.", unit = "MW"),
    "rup" => (meaning = "Ramp-up capability.", unit = "MW/min"),
    "rdw" => (meaning = "Ramp-down capability.", unit = "MW/min"),
    "investment" => (meaning = "Investment flag.", unit = "0/1 flag"),
    "active" => (meaning = "Active-status flag.", unit = "0/1 flag"),
    "cvar" => (meaning = "Variable generation cost.", unit = raw"$/MWh"),
    "cfuel" => (meaning = "Fuel cost.", unit = raw"$/GJ"),
    "cvom" => (meaning = "Variable operation and maintenance cost.", unit = raw"$/MWh"),
    "cfom" => (meaning = "Fixed operation and maintenance cost parameter.", unit = raw"$/MW/yr"),
    "co2" => (meaning = "Carbon-dioxide emissions intensity.", unit = "kgCO2/MWh"),
    "slope" => (meaning = "Meaning not defined in PISP.", unit = "Not defined in PISP."),
    "hrate" => (meaning = "Generator heat rate.", unit = "GJ/MWh"),
    "pfrmax" => (meaning = "Maximum headroom available for frequency response.", unit = "MW"),
    "g" => (meaning = "Meaning not defined in PISP.", unit = "Not defined in PISP."),
    "inertia" => (meaning = "Meaning not defined in PISP.", unit = "Not defined in PISP."),
    "ffr" => (meaning = "Fast-frequency-response provision flag.", unit = "0/1 flag"),
    "pfr" => (meaning = "Primary-frequency-response provision flag.", unit = "0/1 flag"),
    "res2" => (meaning = "Secondary-reserve provision flag.", unit = "0/1 flag"),
    "res3" => (meaning = "Tertiary or regulation-reserve provision flag.", unit = "0/1 flag"),
    "powerfactor" => (meaning = "Power-factor parameter.", unit = "ratio"),
    "n" => (meaning = "Static maximum unit-count field; the build-out schedule supplies the time-varying count.", unit = "units"),
    "contingency" => (meaning = "Contingency-classification flag.", unit = "0/1 flag"),
    "down_time" => (meaning = "Minimum down time after shutdown.", unit = "h"),
    "up_time" => (meaning = "Minimum up time after startup.", unit = "h"),
    "last_state" => (meaning = "Meaning not defined in PISP.", unit = "Not defined in PISP."),
    "last_state_period" => (meaning = "Meaning not defined in PISP.", unit = "Not defined in PISP."),
    "last_state_output" => (meaning = "Meaning not defined in PISP.", unit = "Not defined in PISP."),
    "start_up_cost" => (meaning = "Startup cost.", unit = raw"$"),
    "shut_down_cost" => (meaning = "Shutdown cost.", unit = raw"$"),
    "start_up_time" => (meaning = "Time required to start a unit.", unit = "h"),
    "shut_down_time" => (meaning = "Time required to shut down a unit.", unit = "h"),
)

const ESS_PLACEHOLDER_ORIGINS = Dict(
    "id_ess" => "Sequential identifier generated by PISP.",
    "name" => "Generated as `uppercase(tech * \"_\" * subregion) * \"_NEW\"`.",
    "alias" => "Set equal to the generated name.",
    "capacity" => "Read from the build-out workbook.",
    "id_bus" => "Looked up from the workbook subregion in the current bus table.",
    "emax" => "Computed as duration in hours multiplied by workbook capacity.",
    "pmax" => "Set to workbook capacity.",
    "lmax" => "Set to workbook capacity.",
    "longitude" => "Set explicitly to `0.0` by the build-out parser.",
    "latitude" => "Set explicitly to `0.0` by the build-out parser.",
)

const GEN_PLACEHOLDER_ORIGINS = Dict(
    "id_gen" => "Sequential identifier generated by PISP.",
    "name" => "Generated as `uppercase(tech * \"_\" * subregion) * \"_NEW\"`.",
    "alias" => "Set equal to the generated name.",
    "capacity" => "Read from the build-out workbook.",
    "id_bus" => "Looked up from the workbook subregion in the current bus table.",
    "pmax" => "Set to workbook capacity.",
    "latitude" => "Set explicitly to `0.0` by the build-out parser.",
    "longitude" => "Set explicitly to `0.0` by the build-out parser.",
)

function buildout_technology_rows()
    rows = NamedTuple[]
    for label in sort(collect(PISP._BUILDOUT_ESS_TECHS))
        push!(rows, (
            buildout_label = label,
            output_table = "ESS",
            template_key = label,
            duration_h = PISP._BESS_DURATION_H[label],
        ))
    end
    for label in sort(collect(PISP._BUILDOUT_GEN_TECHS))
        push!(rows, (
            buildout_label = label,
            output_table = "Generator",
            template_key = String(PISP._BUILDOUT_GEN_TECH_KEY[label]),
            duration_h = missing,
        ))
    end
    return rows
end

function buildout_origin_rows()
    return [
        (output = "ESS static row", field_group = "Workbook", rule = "`tech`, `subregion`, and `capacity` select, locate, and size the asset."),
        (output = "ESS static row", field_group = "Generated or looked up", rule = "PISP generates `id_ess`, `name`, and `alias`, and resolves `id_bus` from the subregion."),
        (output = "ESS static row", field_group = "Computed or explicit", rule = "`emax = duration_h × capacity`; `pmax = capacity`; `lmax = capacity`; coordinates are `0.0`."),
        (output = "ESS static row", field_group = "Template", rule = "The 27 non-placeholder fields listed below come from `PISP.params_buildout_bess`."),
        (output = "ESS unit-count schedule", field_group = "Workbook and generated", rule = "The workbook supplies `year` and `n`; PISP adds scenario IDs, row IDs, and `DateTime(year, 1, 1)`."),
        (output = "Generator static row", field_group = "Workbook", rule = "`tech`, `subregion`, and `capacity` select, locate, and size the asset."),
        (output = "Generator static row", field_group = "Generated or looked up", rule = "PISP generates `id_gen`, `name`, and `alias`, and resolves `id_bus` from the subregion."),
        (output = "Generator static row", field_group = "Computed or explicit", rule = "`pmax = capacity`; coordinates are `0.0`."),
        (output = "Generator static row", field_group = "Template", rule = "The 40 non-placeholder fields listed below come from `PISP.params_buildout_gen`."),
        (output = "Generator unit-count schedule", field_group = "Workbook and generated", rule = "The workbook supplies `year` and `n`; PISP adds scenario IDs, row IDs, and `DateTime(year, 1, 1)`."),
    ]
end

function buildout_placeholder_rows()
    rows = NamedTuple[]
    for field in sort(collect(keys(ESS_PLACEHOLDER_ORIGINS)))
        push!(rows, (output_table = "ESS", field = field, applied_source = ESS_PLACEHOLDER_ORIGINS[field]))
    end
    for field in sort(collect(keys(GEN_PLACEHOLDER_ORIGINS)))
        push!(rows, (output_table = "Generator", field = field, applied_source = GEN_PLACEHOLDER_ORIGINS[field]))
    end
    return rows
end

function template_comparison_rows(kind::Symbol)
    if kind == :ess
        labels = sort(collect(PISP._BUILDOUT_ESS_TECHS))
        fields = ESS_TEMPLATE_FIELDS
        metadata = ESS_FIELD_METADATA
        templates = Dict(label => PISP.params_buildout_bess[Symbol(label)] for label in labels)
    elseif kind == :gen
        labels = sort(collect(PISP._BUILDOUT_GEN_TECHS))
        fields = GEN_TEMPLATE_FIELDS
        metadata = GEN_FIELD_METADATA
        templates = Dict(label => PISP.params_buildout_gen[PISP._BUILDOUT_GEN_TECH_KEY[label]] for label in labels)
    else
        error("kind must be :ess or :gen")
    end

    return [(
        field = field,
        meaning = metadata[field].meaning,
        unit = metadata[field].unit,
        values = Dict(label => templates[label][field] for label in labels),
    ) for field in fields]
end

function split_common_rows(rows, labels)
    common = NamedTuple[]
    varying = NamedTuple[]
    for row in rows
        values = [row.values[label] for label in labels]
        if all(==(first(values)), values)
            push!(common, (field = row.field, value = first(values), meaning = row.meaning, unit = row.unit))
        else
            push!(varying, row)
        end
    end
    return common, varying
end

function comparison_frame(rows, labels)
    table = DataFrame(
        field = [row.field for row in rows],
        meaning = [row.meaning for row in rows],
        unit = [row.unit for row in rows],
    )
    for label in labels
        table[!, Symbol(label)] = [row.values[label] for row in rows]
    end
    return table
end

function field_metadata_frame(rows)
    return DataFrame(
        field = [row.field for row in rows],
        meaning = [row.meaning for row in rows],
        unit = [row.unit for row in rows],
    )
end

function technology_value_frame(rows, labels)
    table = DataFrame(buildout_label = labels)
    for row in rows
        table[!, Symbol(row.field)] = [row.values[label] for label in labels]
    end
    return table
end

function buildout_reference_tables()
    ess_labels = sort(collect(PISP._BUILDOUT_ESS_TECHS))
    ess_rows = template_comparison_rows(:ess)
    ess_common, ess_varying = split_common_rows(ess_rows, ess_labels)

    gen_labels = sort(collect(PISP._BUILDOUT_GEN_TECHS))
    gen_rows = template_comparison_rows(:gen)
    gen_common, gen_varying = split_common_rows(gen_rows, gen_labels)

    return (
        technology = DataFrame(buildout_technology_rows()),
        origins = DataFrame(buildout_origin_rows()),
        placeholders = DataFrame(buildout_placeholder_rows()),
        ess_common = DataFrame(ess_common),
        ess_varying_fields = field_metadata_frame(ess_varying),
        ess_varying_values = technology_value_frame(ess_varying, ess_labels),
        gen_common = DataFrame(gen_common),
        gen_varying = comparison_frame(gen_varying, gen_labels),
    )
end

function _section(text, start_marker, end_marker)
    start_range = findfirst(start_marker, text)
    start_range === nothing && error("missing parser marker: $start_marker")
    start_index = first(start_range)
    end_range = findnext(end_marker, text, last(start_range) + 1)
    end_range === nothing && error("missing parser marker: $end_marker")
    return text[start_index:first(end_range)-1]
end

function _template_keys(text)
    return Set(match.captures[1] for match in eachmatch(r"p\[\"([^\"]+)\"\]", text))
end

function parser_template_fields(parser_path)
    text = read(parser_path, String)
    ess = union(
        _template_keys(_section(text, "function add_buildout_ess!", "function add_buildout_gen!")),
        _template_keys(_section(text, "function _add_buildout_ess_sc!", "function _add_buildout_gen_sc!")),
    )
    gen = union(
        _template_keys(_section(text, "function add_buildout_gen!", "function add_buildouts!")),
        _template_keys(text[findfirst("function _add_buildout_gen_sc!", text)[1]:end]),
    )
    return (ess = ess, gen = gen)
end

function validate_buildout_defaults_contract(parser_path)
    parser_fields = parser_template_fields(parser_path)
    parser_fields.ess == Set(ESS_TEMPLATE_FIELDS) || error("ESS documentation fields differ from parser-consumed keys")
    parser_fields.gen == Set(GEN_TEMPLATE_FIELDS) || error("Generator documentation fields differ from parser-consumed keys")

    Set(keys(ESS_FIELD_METADATA)) == Set(ESS_TEMPLATE_FIELDS) || error("ESS field metadata is incomplete")
    Set(keys(GEN_FIELD_METADATA)) == Set(GEN_TEMPLATE_FIELDS) || error("Generator field metadata is incomplete")

    for (label, template) in PISP.params_buildout_bess
        for field in ESS_TEMPLATE_FIELDS
            haskey(template, field) || error("ESS template $label is missing $field")
            template[field] === nothing && error("ESS output-effective field $label.$field is `nothing`")
        end
        actual_placeholders = Set(key for (key, value) in template if value === nothing)
        actual_placeholders == Set(keys(ESS_PLACEHOLDER_ORIGINS)) || error("ESS placeholder classification differs for $label")
    end

    for (label, template) in PISP.params_buildout_gen
        for field in GEN_TEMPLATE_FIELDS
            haskey(template, field) || error("Generator template $label is missing $field")
            template[field] === nothing && error("Generator output-effective field $label.$field is `nothing`")
        end
        actual_placeholders = Set(key for (key, value) in template if value === nothing)
        actual_placeholders == Set(keys(GEN_PLACEHOLDER_ORIGINS)) || error("Generator placeholder classification differs for $label")
    end

    return true
end

end
