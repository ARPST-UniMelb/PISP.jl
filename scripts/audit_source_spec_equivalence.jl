#!/usr/bin/env julia

using CSV
using DataFrames
using PISP
using SHA
using TOML
using XLSX

const ISP24 = "2024-isp-inputs-and-assumptions-workbook.xlsx"
const ISP19 = "2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx"
const SCENARIOS = ["Green Energy Exports", "Progressive Change", "Step Change"]

struct Case
    id::String
    source_id::Symbol
    workbook::String
    worksheet::String
    range::Union{Nothing,String}
    replacements::NamedTuple
end

Case(id, source_id, workbook, worksheet, range; replacements=(;)) =
    Case(id, source_id, workbook, worksheet, range, replacements)

const CORE_CASES = [
    ("network_capability", "Network Capability", "B6:H21"),
    ("transmission_reliability", "Transmission Reliability", "B7:G11"),
    ("flow_path_augmentation_options", "Flow Path Augmentation options", "B11:N94"),
    ("generator_summary_mapping_names", "Summary Mapping", "B6:B680"),
    ("generator_summary_mapping_mlf", "Summary Mapping", "AA6:AA680"),
    ("existing_generator_maximum_capacity", "Maximum capacity", "B8:D260"),
    ("committed_generator_maximum_capacity", "Maximum capacity", "F8:I35"),
    ("anticipated_generator_maximum_capacity", "Maximum capacity", "K8:N24"),
    ("generator_summary_mapping", "Summary Mapping", "B4:I680"),
    ("coal_minimum_stable_generation", "Generation limits", "B8:D52"),
    ("gpg_minimum_stable_generation", "GPG Min Stable Level", "B9:E34"),
    ("generator_minimum_up_down_times", "Min Up&Down Times", "B8:E25"),
    ("generator_maximum_ramp_rates", "Max Ramp Rates", "B8:F72"),
    ("generator_retirements", "Retirement", "B9:D460"),
    ("existing_generator_reliability", "Generator Reliability Settings", "B20:G28"),
    ("new_generator_reliability", "Generator Reliability Settings", "I20:N40"),
    ("existing_generator_summary", "Existing Gen Data Summary", "B10:U319"),
    ("additional_generator_summary", "Existing Gen Data Summary", "B382:U397"),
    ("generator_emissions_intensity", "Emissions intensity", "B7:D73"),
    ("bess_storage_properties", "Storage properties", "B4:H13"),
    ("pumped_storage_properties", "Storage properties", "B22:K26"),
    ("bess_maximum_capacity", "Maximum capacity", "P8:U62"),
    ("bess_summary_mapping", "Summary Mapping", "B314:AB370"),
    ("existing_generators", "Existing Gen Data Summary", "B11:K297"),
    ("renewable_energy_zones", "Renewable Energy Zones", "B7:G50"),
]

const DSP_CASES = [
    ("progressive_change", "QLD", "SUMMER", "B128:AG133"), ("progressive_change", "QLD", "WINTER", "B137:AG142"),
    ("progressive_change", "NSW", "SUMMER", "B108:AG113"), ("progressive_change", "NSW", "WINTER", "B118:AG123"),
    ("progressive_change", "SA", "SUMMER", "B147:AG152"), ("progressive_change", "SA", "WINTER", "B156:AG161"),
    ("progressive_change", "TAS", "SUMMER", "B166:AG171"), ("progressive_change", "TAS", "WINTER", "B175:AG180"),
    ("progressive_change", "VIC", "SUMMER", "B185:AG190"), ("progressive_change", "VIC", "WINTER", "B194:AG199"),
    ("step_change", "QLD", "SUMMER", "B226:AG231"), ("step_change", "QLD", "WINTER", "B235:AG240"),
    ("step_change", "NSW", "SUMMER", "B206:AG211"), ("step_change", "NSW", "WINTER", "B216:AG221"),
    ("step_change", "SA", "SUMMER", "B245:AG250"), ("step_change", "SA", "WINTER", "B254:AG259"),
    ("step_change", "TAS", "SUMMER", "B264:AG269"), ("step_change", "TAS", "WINTER", "B273:AG278"),
    ("step_change", "VIC", "SUMMER", "B283:AG288"), ("step_change", "VIC", "WINTER", "B292:AG297"),
    ("green_energy_exports", "QLD", "SUMMER", "B30:AG35"), ("green_energy_exports", "QLD", "WINTER", "B39:AG44"),
    ("green_energy_exports", "NSW", "SUMMER", "B10:AG15"), ("green_energy_exports", "NSW", "WINTER", "B20:AG25"),
    ("green_energy_exports", "SA", "SUMMER", "B49:AG54"), ("green_energy_exports", "SA", "WINTER", "B58:AG63"),
    ("green_energy_exports", "TAS", "SUMMER", "B68:AG73"), ("green_energy_exports", "TAS", "WINTER", "B77:AG82"),
    ("green_energy_exports", "VIC", "SUMMER", "B87:AG92"), ("green_energy_exports", "VIC", "WINTER", "B96:AG101"),
]

slug(s) = replace(lowercase(String(s)), r"[^a-z0-9]+" => "_")
function cases(data_root)
    c = Case[Case(id, Symbol(id), ISP24, sheet, range) for (id, sheet, range) in CORE_CASES]
    push!(c, Case("legacy_generator_minimum_up_time", :legacy_generator_minimum_up_time, ISP19, "Generation limits", "O9:Q69"))
    for (scenario, region, season, range) in DSP_CASES
        source_id = Symbol("dsp_$(scenario)_$(lowercase(region))_$(lowercase(season))")
        push!(c, Case("dsp_$(scenario)_$(region)_$(season)", source_id, ISP24, "DSP", range))
    end
    for (kind, source_id, workbook) in (
        ("capacity", :vpp_capacity_outlook, "Auxiliary/StorageCapacityOutlook_2024_ISP.xlsx"),
        ("energy", :vpp_energy_outlook, "Auxiliary/StorageEnergyOutlook_2024_ISP.xlsx"),
    )
        for scenario in SCENARIOS
            push!(c, Case("vpp_$(kind)_$(slug(scenario))", source_id, workbook, scenario, "A1:AG1769"))
        end
    end
    push!(c, Case("hydro_scheme_inflows", :hydro_scheme_inflows, ISP24, "Hydro Scheme Inflows", "B34:N47"))
    push!(c, Case("ev_bev_phev_profile_weekend", :ev_bev_phev_profile_weekend, "2023-iasr-ev-workbook.xlsx", "BEV_PHEV_Profile_kW (Weekend)", "B:AY"))
    push!(c, Case("ev_bev_phev_profile_weekday", :ev_bev_phev_profile_weekday, "2023-iasr-ev-workbook.xlsx", "BEV_PHEV_Profile_kW (Weekday)", "B:AY"))
    push!(c, Case("ev_bev_phev_charge_type", :ev_bev_phev_charge_type, "2023-iasr-ev-workbook.xlsx", "BEV_PHEV_Charge_Type (%)", "B:BF"))
    push!(c, Case("ev_subregional_demand_allocation", :ev_subregional_demand_allocation, ISP24, "Sub-regional demand allocation", "B127:AG182"))
    ev = joinpath(data_root, "2023-iasr-ev-workbook.xlsx")
    if isfile(ev)
        sheets = XLSX.openxlsx(ev) do xf
            sort!(filter(s -> endswith(s, "_Numbers"), XLSX.sheetnames(xf)))
        end
        for sheet in sheets
            push!(c, Case("ev_vehicle_numbers_$(slug(sheet))", :ev_vehicle_numbers, "2023-iasr-ev-workbook.xlsx", sheet, "B:AZ"))
        end
    end
    push!(c, Case("buildout_schedule", :buildout_schedule, "PISP-buildouts/buildouts.xlsx", "buildout_1", nothing))
    core = joinpath(data_root, "Core")
    if isdir(core)
        for file in sort(filter(f -> endswith(lowercase(f), ".xlsx"), readdir(core)))
            stem = slug(file)
            for (id, sheet) in (("capacity", "Capacity"), ("storage_energy", "Storage Energy"),
                                ("storage_capacity", "Storage Capacity"), ("rez_generation_capacity", "REZ Generation Capacity"))
                source_id = Dict("capacity" => :core_capacity_outlook,
                                 "storage_energy" => :core_storage_energy_outlook,
                                 "storage_capacity" => :core_storage_capacity_outlook,
                                 "rez_generation_capacity" => :core_rez_generation_capacity)[id]
                push!(c, Case("core_$(id)_$(stem)", source_id, "Core/$file", sheet, "A3:AG5000";
                             replacements=(core_workbook=file,)))
            end
        end
    end
    aux = joinpath(data_root, "Auxiliary")
    if isdir(aux)
        for file in sort(filter(f -> endswith(lowercase(f), ".xlsx") &&
                                (occursin("Condensed", f) || occursin("REZCAP", f)), readdir(aux)))
            path = joinpath(aux, file); stem = slug(file)
            sheets = XLSX.openxlsx(path) do xf; sort!(XLSX.sheetnames(xf)); end
            for sheet in sheets
                is_rez = occursin("REZCAP", file)
                source_id = is_rez ? :auxiliary_rez_generation_capacity : :condensed_capacity_outlook
                range = is_rez ? "A1:AG2238" : "A1:G14356"
                replacements = is_rez ? (scenario=strip(replace(file,
                    "2024 ISP - " => "", " - Core_REZCAP.xlsx" => "")),) : (;)
                push!(c, Case("aux_$(stem)_$(slug(sheet))", source_id, "Auxiliary/$file", sheet, range;
                             replacements=replacements))
            end
        end
    end
    return c
end

function raw_df(path, sheet, range)
    data = XLSX.readdata(path, sheet, range)
    header = [ismissing(x) || x == "" ? "Column_$i" : string(x) for (i, x) in enumerate(data[1, :])]
    return DataFrame(data[2:end, :], Symbol.(header); makeunique=true)
end

function whole_df(path, sheet)
    data = XLSX.openxlsx(path) do xf; XLSX.getdata(xf[sheet]); end
    return DataFrame(data[2:end, :], Symbol.(string.(data[1, :])); makeunique=true)
end

function literal_read(root, case)
    path = joinpath(root, case.workbook)
    case.range === nothing ? whole_df(path, case.worksheet) : PISP.read_xlsx_with_header(path, case.worksheet, case.range)
end

function spec_read(root, case)
    spec = PISP.source_spec(case.source_id, 2024)
    replacements = (; case.replacements...)
    path = PISP.source_path(root, spec; replacements...)
    if spec.cell_range === nothing
        return whole_df(path, case.worksheet)
    end
    return PISP.read_xlsx_with_header(path, spec; worksheet=case.worksheet)
end

function record(case, df, root, output_dir)
    io = IOBuffer(); CSV.write(io, df); bytes = take!(io)
    Dict("case_id" => case.id, "relative_file" => case.workbook, "worksheet" => case.worksheet,
         "range" => something(case.range, "whole-sheet"), "rows" => nrow(df), "columns" => ncol(df),
         "column_names" => String.(names(df)), "sha256" => bytes2hex(sha256(bytes)))
end

function write_manifest(path, records, skips)
    mkpath(dirname(path)); open(path, "w") do io
        TOML.print(io, Dict("cases" => records, "skips" => skips))
    end
end

function run_mode(mode, root, output)
    use_specs = mode == "specs"
    recs = Dict{String,Any}[]; skips = Dict{String,Any}[]
    for case in cases(root)
        path = joinpath(root, case.workbook)
        if !isfile(path)
            push!(skips, Dict("case_id" => case.id, "reason" => "missing workbook: $(case.workbook)")); continue
        end
        try
            df = use_specs ? spec_read(root, case) : literal_read(root, case)
            push!(recs, record(case, df, root, dirname(output)))
        catch err
            push!(skips, Dict("case_id" => case.id, "reason" => sprint(showerror, err)))
        end
    end
    sort!(recs; by=x -> x["case_id"]); sort!(skips; by=x -> x["case_id"])
    write_manifest(output, recs, skips)
    println("wrote $(length(recs)) cases and $(length(skips)) skips to $output")
end

function compare_manifests(a, b)
    left, right = TOML.parsefile(a), TOML.parsefile(b)
    l = Dict(x["case_id"] => x for x in get(left, "cases", Any[])); r = Dict(x["case_id"] => x for x in get(right, "cases", Any[]))
    mismatches = String[]
    for id in sort!(collect(union(keys(l), keys(r))))
        haskey(l, id) && haskey(r, id) || (push!(mismatches, "$id: case present in only one manifest"); continue)
        for field in ("rows", "columns", "column_names", "sha256")
            l[id][field] == r[id][field] || push!(mismatches, "$id: $field differs ($(l[id][field]) vs $(r[id][field]))")
        end
    end
    for message in mismatches; println(message); end
    isempty(mismatches) && println("manifests match ($(length(l)) cases)")
    return isempty(mismatches)
end

function main(args)
    isempty(args) && error("usage: legacy|specs --data-root PATH --output PATH, or compare --baseline PATH --candidate PATH")
    mode = args[1]; mode in ("legacy", "specs", "compare") || error("unknown mode: $mode")
    opts = Dict{String,String}(); i = 2
    while i <= length(args)
        startswith(args[i], "--") || error("expected option, got $(args[i])")
        i == length(args) && error("missing value for $(args[i])")
        opts[args[i][3:end]] = args[i + 1]; i += 2
    end
    if mode == "compare"
        haskey(opts, "baseline") && haskey(opts, "candidate") || error("compare requires --baseline and --candidate")
        compare_manifests(opts["baseline"], opts["candidate"]) || exit(1)
    else
        haskey(opts, "data-root") && haskey(opts, "output") || error("$mode requires --data-root and --output")
        run_mode(mode, opts["data-root"], opts["output"])
    end
end

main(ARGS)
