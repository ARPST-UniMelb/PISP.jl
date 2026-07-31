using DataFrames
using Dates
using OrderedCollections
using XLSX

if !isdefined(@__MODULE__, :NEMAREAS)
    include(joinpath(dirname(dirname(@__DIR__)), "parameters", "general2024ISP.jl"))
end

if !isdefined(@__MODULE__, :EV_2024_BEV_PHEV_PROFILE_WEEKEND_SOURCE)
    const EV_2024_BEV_PHEV_PROFILE_WEEKEND_SOURCE = XlsxSourceSpec(
        id = :ev_bev_phev_profile_weekend,
        edition = 2024,
        workbook = "2023-iasr-ev-workbook.xlsx",
        worksheet = "BEV_PHEV_Profile_kW (Weekend)",
        cell_range = "B:AY",
        description = "Weekend BEV and PHEV charging profiles by state and vehicle type.",
        source_family = :electric_vehicles,
        consumer = :ev_der_sched,
    )
    const EV_2024_BEV_PHEV_PROFILE_WEEKDAY_SOURCE = XlsxSourceSpec(
        id = :ev_bev_phev_profile_weekday,
        edition = 2024,
        workbook = "2023-iasr-ev-workbook.xlsx",
        worksheet = "BEV_PHEV_Profile_kW (Weekday)",
        cell_range = "B:AY",
        description = "Weekday BEV and PHEV charging profiles by state and vehicle type.",
        source_family = :electric_vehicles,
        consumer = :ev_der_sched,
    )
    const EV_2024_BEV_PHEV_CHARGE_TYPE_SOURCE = XlsxSourceSpec(
        id = :ev_bev_phev_charge_type,
        edition = 2024,
        workbook = "2023-iasr-ev-workbook.xlsx",
        worksheet = "BEV_PHEV_Charge_Type (%)",
        cell_range = "B:BF",
        description = "BEV and PHEV charging-type shares by state, scenario, category and year.",
        source_family = :electric_vehicles,
        consumer = :ev_der_sched,
    )
    const EV_2024_VEHICLE_NUMBERS_SOURCE = XlsxSourceSpec(
        id = :ev_vehicle_numbers,
        edition = 2024,
        workbook = "2023-iasr-ev-workbook.xlsx",
        worksheet = "*_Numbers",
        cell_range = "B:AZ",
        description = "Vehicle-number sheets selected by the `_Numbers` worksheet suffix.",
        source_family = :electric_vehicles,
        consumer = :ev_der_sched,
    )
    const EV_2024_SUBREGIONAL_DEMAND_ALLOCATION_SOURCE = XlsxSourceSpec(
        id = :ev_subregional_demand_allocation,
        edition = 2024,
        workbook = "2024-isp-inputs-and-assumptions-workbook.xlsx",
        worksheet = "Sub-regional demand allocation",
        cell_range = "B127:AG182",
        description = "Subregional EV demand allocations by scenario and financial year.",
        source_family = :electric_vehicles,
        consumer = :ev_der_sched,
    )

    register_source_specs!(
        EV_2024_BEV_PHEV_PROFILE_WEEKEND_SOURCE,
        EV_2024_BEV_PHEV_PROFILE_WEEKDAY_SOURCE,
        EV_2024_BEV_PHEV_CHARGE_TYPE_SOURCE,
        EV_2024_VEHICLE_NUMBERS_SOURCE,
        EV_2024_SUBREGIONAL_DEMAND_ALLOCATION_SOURCE,
    )

    const EV_2024_BEV_PHEV_PROFILE_WEEKEND_SHEET = EV_2024_BEV_PHEV_PROFILE_WEEKEND_SOURCE.worksheet
    const EV_2024_BEV_PHEV_PROFILE_WEEKDAY_SHEET = EV_2024_BEV_PHEV_PROFILE_WEEKDAY_SOURCE.worksheet
    const EV_2024_BEV_PHEV_CHARGE_TYPE_SHEET = EV_2024_BEV_PHEV_CHARGE_TYPE_SOURCE.worksheet
    const EV_2024_VEHICLE_NUMBERS_SHEET_SUFFIX = replace(EV_2024_VEHICLE_NUMBERS_SOURCE.worksheet, "*" => "")
    const EV_2024_SUBREGIONAL_DEMAND_ALLOCATION_SHEET = EV_2024_SUBREGIONAL_DEMAND_ALLOCATION_SOURCE.worksheet
    const EV_2024_VEHICLE_NUMBER_VALUE_COLUMN_BY_SHEET = OrderedDict(
        "BEV_Numbers" => :number_bev,
        "PHEV_Numbers" => :number_phev,
        "FCEV_Numbers" => :number_fcev,
        "ICE_Numbers" => :number_ice,
    )
    const EV_2024_STATE_CODE_BY_NAME = Dict(state_name => state_code for (state_code, state_name) in NEMAREAS)
    const EV_2024_SCENARIO_ID_BY_NAME = Dict(scenario_name => scenario_id for (scenario_name, scenario_id) in SCE)
    const EV_2024_VEHICLE_CATEGORY_BY_TYPE = Dict(
        "Articulated Truck" => "Buses and Trucks",
        "Bus" => "Buses and Trucks",
        "Large Light Commercial" => "Commercial",
        "Large Residential" => "Residential",
        "Medium Light Commercial" => "Commercial",
        "Medium Residential" => "Residential",
        "Motorcycle" => "Residential",
        "Rigid Truck" => "Buses and Trucks",
        "Small Light Commercial" => "Commercial",
        "Small Residential" => "Residential",
    )
end

ev_is_blank_cell(value) = ismissing(value) || (value isa AbstractString && isempty(strip(value)))
ev_is_singleton_label_row(row) = !ev_is_blank_cell(row[1]) && all(ev_is_blank_cell, row[2:end])
ev_singleton_label(row) = strip(String(row[1]))
ev_nonblank_indices(values) = findall(value -> !ev_is_blank_cell(value), values)

function ev_is_blank_row(row)
    return all(ev_is_blank_cell, row)
end

function ev_read_non_empty_rows(workbook_path::AbstractString, sheet_name::AbstractString, range_ref::AbstractString)
    raw_sheet = XLSX.readdata(workbook_path, sheet_name, range_ref)
    return [collect(raw_sheet[row_index, :]) for row_index in axes(raw_sheet, 1) if !ev_is_blank_row(raw_sheet[row_index, :])]
end

function ev_read_non_empty_rows(
    workbook_path::AbstractString,
    spec::XlsxSourceSpec;
    worksheet::AbstractString = spec.worksheet,
)
    raw_sheet = read_xlsx_rows(workbook_path, spec; worksheet = worksheet)
    return [
        collect(raw_sheet[row_index, :])
        for row_index in axes(raw_sheet, 1)
        if !ev_is_blank_row(raw_sheet[row_index, :])
    ]
end

function ev_ensure_columns!(columns::Dict{Symbol, Vector}, column_order::Vector{Symbol}, new_columns::Vector{Symbol}, factory::Function)
    for column in new_columns
        if !haskey(columns, column)
            columns[column] = factory()
            push!(column_order, column)
        end
    end
end

ev_dataframe_from_columns(column_order::Vector{Symbol}, columns::Dict{Symbol, Vector}) =
    DataFrame([column => columns[column] for column in column_order])

function ev_is_state_header_row(row)
    return ev_is_singleton_label_row(row) && haskey(EV_2024_STATE_CODE_BY_NAME, ev_singleton_label(row))
end

function ev_is_time_header_row(row)
    first_cell_is_blank = ev_is_blank_cell(row[1])
    later_cells = row[2:end]
    has_time_cells = any(value -> !ev_is_blank_cell(value), later_cells)
    all_time_cells = all(value -> ev_is_blank_cell(value) || value isa Time, later_cells)
    return first_cell_is_blank && has_time_cells && all_time_cells
end

function ev_split_profile_label(label::AbstractString)
    pieces = split(strip(label), ","; limit = 2)
    vehicle_type = strip(first(pieces))
    charging_profile = length(pieces) == 2 ? strip(pieces[2]) : ""
    charging_profile = replace(charging_profile, r"\s*-\s*vehicle charging$" => "")
    return vehicle_type, charging_profile
end

ev_time_column_name(value::Time) = Symbol(Dates.format(value, "HH_MM"))

function ev_map_state_name_to_code(state_name::AbstractString)
    state_code = get(EV_2024_STATE_CODE_BY_NAME, state_name, nothing)
    state_code === nothing && error("State `$state_name` was not found in NEMAREAS.")
    return state_code
end

function ev_normalize_numbers_state_name(state_name::AbstractString)
    return strip(replace(state_name, r"\s*\(includes ACT\)$" => ""))
end

function ev_is_numbers_header_row(row)
    if ev_is_blank_cell(row[1]) || strip(String(row[1])) != "Vehicle Type"
        return false
    end

    return any(value -> !ev_is_blank_cell(value), row[2:end])
end

function ev_is_year_only_header_row(row)
    if !ev_is_blank_cell(row[1])
        return false
    end

    later_cells = row[2:end]
    has_year_cells = any(value -> !ev_is_blank_cell(value), later_cells)
    all_year_cells = all(
        value ->
            ev_is_blank_cell(value) || (
                value isa AbstractString &&
                occursin(r"^\d{4}-\d{2}$", strip(value))
            ),
        later_cells,
    )

    return has_year_cells && all_year_cells
end

function ev_parse_year_header(row)
    indices = ev_nonblank_indices(row[2:end])
    labels = [replace(strip(String(row[index + 1])), "-" => "_") for index in indices]
    return indices, labels
end

function ev_map_vehicle_type_to_category(vehicle_type::AbstractString)
    category = get(EV_2024_VEHICLE_CATEGORY_BY_TYPE, vehicle_type, nothing)
    category === nothing && error("Vehicle type `$vehicle_type` was not found in EV_2024_VEHICLE_CATEGORY_BY_TYPE.")
    return category
end

function ev_split_charge_type_label(label::AbstractString)
    pieces = split(strip(label), "-"; limit = 2)
    category = strip(first(pieces))
    charging = length(pieces) == 2 ? strip(pieces[2]) : ""
    return category, charging
end

function ev_extract_subregion_code(label::AbstractString)
    match_result = match(r"\(([^)]+)\)\s*$", strip(label))
    return isnothing(match_result) ? strip(label) : strip(only(match_result.captures))
end

function ev_melt_year_columns_dataframe(
    df::DataFrame,
    id_columns::Vector{Symbol},
    value_name::Symbol;
    row_filter::Union{Nothing, Function} = nothing,
)
    year_columns = filter(name -> occursin(r"^\d{4}_\d{2}$", String(name)), names(df))
    long_df = stack(df, year_columns; variable_name = :year, value_name = value_name)
    long_df.year = String.(long_df.year)

    if !isnothing(row_filter)
        long_df = filter(row_filter, long_df)
    end

    return long_df[:, [id_columns..., :year, value_name]]
end

function ev_build_bev_phev_profile_dataframe(
    workbook_path::AbstractString,
    source_spec::XlsxSourceSpec;
    day_type::AbstractString,
    worksheet::AbstractString = source_spec.worksheet,
)
    sheet_name = String(worksheet)
    non_empty_rows = ev_read_non_empty_rows(
        workbook_path,
        source_spec;
        worksheet = sheet_name,
    )

    current_state = nothing
    profile_time_indices = Int[]
    profile_time_columns = Symbol[]
    column_order = Symbol[:state, :vehicle_type, :charging_profile, :day_type]
    columns = Dict{Symbol, Vector}(
        :state => String[],
        :vehicle_type => String[],
        :charging_profile => String[],
        :day_type => String[],
    )

    for row in non_empty_rows
        if ev_is_state_header_row(row)
            current_state = ev_map_state_name_to_code(ev_singleton_label(row))
            continue
        end

        if ev_is_time_header_row(row)
            profile_time_indices = ev_nonblank_indices(row[2:end])
            profile_time_columns = [ev_time_column_name(row[index + 1]) for index in profile_time_indices]
            isempty(profile_time_indices) && error("No half-hour columns were found in sheet `$sheet_name`.")
            ev_ensure_columns!(columns, column_order, profile_time_columns, () -> Vector{Union{Missing, Float64}}())
            continue
        end

        if current_state === nothing || isempty(profile_time_indices) || ev_is_blank_cell(row[1])
            continue
        end

        vehicle_type, charging_profile = ev_split_profile_label(strip(String(row[1])))
        push!(columns[:state], current_state)
        push!(columns[:vehicle_type], vehicle_type)
        push!(columns[:charging_profile], charging_profile)
        push!(columns[:day_type], day_type)

        for (relative_index, time_column) in zip(profile_time_indices, profile_time_columns)
            value = row[relative_index + 1]
            push!(columns[time_column], ismissing(value) ? missing : Float64(value))
        end
    end

    return ev_dataframe_from_columns(column_order, columns)
end

function ev_build_bev_phev_profile_dataframe(
    workbook_path::AbstractString,
    sheet_name::AbstractString;
    day_type::AbstractString,
)
    source_spec = sheet_name == EV_2024_BEV_PHEV_PROFILE_WEEKEND_SOURCE.worksheet ?
        EV_2024_BEV_PHEV_PROFILE_WEEKEND_SOURCE :
        EV_2024_BEV_PHEV_PROFILE_WEEKDAY_SOURCE
    return ev_build_bev_phev_profile_dataframe(
        workbook_path,
        source_spec;
        day_type = day_type,
        worksheet = sheet_name,
    )
end

function ev_build_vehicle_numbers_dataframe(
    workbook_path::AbstractString,
    source_spec::XlsxSourceSpec;
    worksheet::AbstractString = source_spec.worksheet,
)
    sheet_name = String(worksheet)
    non_empty_rows = ev_read_non_empty_rows(
        workbook_path,
        source_spec;
        worksheet = sheet_name,
    )

    current_scenario = nothing
    current_state = nothing
    year_indices = Int[]
    year_columns = Symbol[]
    column_order = Symbol[:scenario, :state, :vehicle_type, :category]
    columns = Dict{Symbol, Vector}(
        :scenario => Int[],
        :state => String[],
        :vehicle_type => String[],
        :category => String[],
    )

    for row in non_empty_rows
        if ev_is_singleton_label_row(row)
            label = ev_singleton_label(row)

            if haskey(EV_2024_SCENARIO_ID_BY_NAME, label)
                current_scenario = EV_2024_SCENARIO_ID_BY_NAME[label]
                current_state = nothing
                continue
            end

            normalized_state_name = ev_normalize_numbers_state_name(label)
            if haskey(EV_2024_STATE_CODE_BY_NAME, normalized_state_name)
                current_state = ev_map_state_name_to_code(normalized_state_name)
            end

            continue
        end

        if ev_is_numbers_header_row(row)
            year_indices, year_labels = ev_parse_year_header(row)
            year_columns = Symbol.(year_labels)
            ev_ensure_columns!(columns, column_order, year_columns, () -> Int[])
            continue
        end

        if current_scenario === nothing || current_state === nothing || isempty(year_indices) || ev_is_blank_cell(row[1])
            continue
        end

        vehicle_type = strip(String(row[1]))
        category = ev_map_vehicle_type_to_category(vehicle_type)
        push!(columns[:scenario], current_scenario)
        push!(columns[:state], current_state)
        push!(columns[:vehicle_type], vehicle_type)
        push!(columns[:category], category)

        for (relative_index, year_column) in zip(year_indices, year_columns)
            value = row[relative_index + 1]
            push!(columns[year_column], Int(round(Float64(value))))
        end
    end

    return ev_dataframe_from_columns(column_order, columns)
end

ev_build_vehicle_numbers_dataframe(workbook_path::AbstractString, sheet_name::AbstractString) =
    ev_build_vehicle_numbers_dataframe(
        workbook_path,
        EV_2024_VEHICLE_NUMBERS_SOURCE;
        worksheet = sheet_name,
    )

function ev_get_vehicle_numbers_sheet_names(
    workbook_path::AbstractString,
    source_spec::XlsxSourceSpec = EV_2024_VEHICLE_NUMBERS_SOURCE,
)
    worksheet_suffix = replace(source_spec.worksheet, "*" => "")
    return XLSX.openxlsx(workbook_path) do workbook
        filter(sheet_name -> endswith(sheet_name, worksheet_suffix), XLSX.sheetnames(workbook))
    end
end

function ev_melt_vehicle_numbers_dataframe(df::DataFrame, number_column::Symbol)
    return ev_melt_year_columns_dataframe(df, [:scenario, :state, :vehicle_type, :category], number_column)
end

function ev_build_bev_phev_charge_type_dataframe(
    workbook_path::AbstractString,
    source_spec::XlsxSourceSpec;
    worksheet::AbstractString = source_spec.worksheet,
)
    non_empty_rows = ev_read_non_empty_rows(
        workbook_path,
        source_spec;
        worksheet = worksheet,
    )

    current_state = nothing
    current_scenario = nothing
    year_indices = Int[]
    year_labels = String[]
    columns = Dict{Symbol, Vector}(
        :state => String[],
        :scenario => Int[],
        :category => String[],
        :charging => String[],
        :year => String[],
        :share => Float64[],
    )

    for row in non_empty_rows
        if ev_is_singleton_label_row(row)
            label = ev_singleton_label(row)
            normalized_state_name = ev_normalize_numbers_state_name(label)

            if haskey(EV_2024_STATE_CODE_BY_NAME, normalized_state_name)
                current_state = ev_map_state_name_to_code(normalized_state_name)
                continue
            end

            if haskey(EV_2024_SCENARIO_ID_BY_NAME, label)
                current_scenario = EV_2024_SCENARIO_ID_BY_NAME[label]
            end

            continue
        end

        if ev_is_year_only_header_row(row)
            year_indices, year_labels = ev_parse_year_header(row)
            continue
        end

        if current_state === nothing || current_scenario === nothing || isempty(year_indices) || ev_is_blank_cell(row[1])
            continue
        end

        category, charging = ev_split_charge_type_label(String(row[1]))

        for (relative_index, year_label) in zip(year_indices, year_labels)
            value = row[relative_index + 1]
            push!(columns[:state], current_state)
            push!(columns[:scenario], current_scenario)
            push!(columns[:category], category)
            push!(columns[:charging], charging)
            push!(columns[:year], year_label)
            push!(columns[:share], Float64(value))
        end
    end

    return DataFrame([
        :state => columns[:state],
        :scenario => columns[:scenario],
        :category => columns[:category],
        :charging => columns[:charging],
        :year => columns[:year],
        :share => columns[:share],
    ])
end

ev_build_bev_phev_charge_type_dataframe(workbook_path::AbstractString, sheet_name::AbstractString) =
    ev_build_bev_phev_charge_type_dataframe(
        workbook_path,
        EV_2024_BEV_PHEV_CHARGE_TYPE_SOURCE;
        worksheet = sheet_name,
    )

function ev_build_subregional_demand_allocation_dataframe(
    workbook_path::AbstractString;
    source_spec::XlsxSourceSpec = EV_2024_SUBREGIONAL_DEMAND_ALLOCATION_SOURCE,
)
    non_empty_rows = ev_read_non_empty_rows(workbook_path, source_spec)

    current_scenario = nothing
    current_state = nothing
    year_indices = Int[]
    year_columns = Symbol[]
    column_order = Symbol[:state, :subregion, :scenario]
    columns = Dict{Symbol, Vector}(
        :state => String[],
        :subregion => String[],
        :scenario => Int[],
    )

    for row in non_empty_rows
        if ev_is_singleton_label_row(row)
            label = ev_singleton_label(row)
            if haskey(EV_2024_SCENARIO_ID_BY_NAME, label)
                current_scenario = EV_2024_SCENARIO_ID_BY_NAME[label]
            end
            continue
        end

        if ev_is_year_only_header_row(row)
            year_indices, year_labels = ev_parse_year_header(row)
            year_columns = Symbol.(year_labels)
            ev_ensure_columns!(columns, column_order, year_columns, () -> Float64[])
            continue
        end

        if ev_is_blank_cell(row[1]) || current_scenario === nothing || isempty(year_indices)
            continue
        end

        label = strip(String(row[1]))
        subregion = ev_extract_subregion_code(label)

        if haskey(NEMAREAS, subregion)
            current_state = ev_map_state_name_to_code(NEMAREAS[subregion])
        end

        current_state === nothing && error("Could not determine state for subregional label `$label`.")

        push!(columns[:state], current_state)
        push!(columns[:subregion], subregion)
        push!(columns[:scenario], current_scenario)

        for (relative_index, year_column) in zip(year_indices, year_columns)
            value = row[relative_index + 1]
            push!(columns[year_column], Float64(value))
        end
    end

    return ev_dataframe_from_columns(column_order, columns)
end

function ev_melt_subregional_demand_allocation_dataframe(df::DataFrame)
    return ev_melt_year_columns_dataframe(
        df,
        [:state, :subregion, :scenario],
        :share;
        row_filter = row ->
            !(row.state == row.subregion && row.share == 1.0 && row.state ∉ ("TAS", "VIC")),
    )
end

function ev_assign_subregional_bus_ids!(subregional_df::DataFrame, ts)
    bus_id_by_name = Dict(row.name => row.id_bus for row in eachrow(ts.bus))
    missing_subregions = unique(filter(subregion -> !haskey(bus_id_by_name, subregion), subregional_df.subregion))

    isempty(missing_subregions) || error(
        "No matching bus found for subregions: $(join(string.(missing_subregions), ", ")).",
    )

    subregional_df.id_bus = [bus_id_by_name[subregion] for subregion in subregional_df.subregion]
    return subregional_df
end

function ev_format_profile_year(date_value::TimeType)
    current_year = year(date_value)
    if month(date_value) <= 6
        return "$(current_year - 1)_$(lpad(string(mod(current_year, 100)), 2, '0'))"
    end
    return "$(current_year)_$(lpad(string(mod(current_year + 1, 100)), 2, '0'))"
end

function ev_collect_data_dates(problem_df::AbstractDataFrame)
    ev_data_dates = String[]
    problem_dates = vcat(collect(problem_df.dstart), collect(problem_df.dend))

    for problem_date in problem_dates
        ismissing(problem_date) && continue
        profile_year = ev_format_profile_year(problem_date)
        profile_year in ev_data_dates || push!(ev_data_dates, profile_year)
    end

    return ev_data_dates
end

function ev_get_profile_column_names(df::DataFrame)
    return filter(name -> occursin(r"^\d{2}_\d{2}$", name), names(df))
end

"""
    ev_der_tables!(ts)

Ensure that `ts.der` contains one EV DER row for every bus in `ts.bus`.
Existing EV rows are preserved, and only missing bus-demand pairs are appended.

# Arguments
- `ts`: Time-static container with populated `bus`, `dem`, and `der` tables.

# Returns
- The mutated `ts.der` table.
"""
function ev_der_tables!(ts)
    demand_by_bus = Dict(row.id_bus => (row.id_dem, row.name) for row in eachrow(ts.dem))
    missing_demand_bus_ids = unique(filter(id_bus -> !haskey(demand_by_bus, id_bus), ts.bus.id_bus))

    isempty(missing_demand_bus_ids) || error(
        "Could not create EV DER rows because these bus ids have no matching demand rows: $(join(string.(missing_demand_bus_ids), ", ")).",
    )

    existing_ev_demand_ids = Set(ts.der[ts.der.tech .== "EV", :id_dem])
    next_der_id = isempty(ts.der) ? 1 : maximum(ts.der.id_der) + 1

    for id_bus in ts.bus.id_bus
        demand_id, demand_name = demand_by_bus[id_bus]
        demand_id in existing_ev_demand_ids && continue

        push!(ts.der, [
            next_der_id, # ID_DER
            "$(demand_name)_EV", # NAME
            "EV", # TECH
            demand_id, # ID_DEMAND
            1, # ACTIVE
            0, # INVESTMENT
            0, # CAPACITY
            1, # REDUCT
            0, # PRED_MAX
            41480.0, # COST_RED
            1, # N
        ])

        push!(existing_ev_demand_ids, demand_id)
        next_der_id += 1
    end

    return ts.der
end

function ev_der_id_by_bus(ts)
    demand_id_by_bus = Dict(row.id_bus => row.id_dem for row in eachrow(ts.dem))
    der_id_by_demand = Dict(row.id_dem => row.id_der for row in eachrow(ts.der) if row.tech == "EV")
    der_id_by_bus = Dict{Int64, Int64}()

    for (id_bus, id_dem) in demand_id_by_bus
        haskey(der_id_by_demand, id_dem) || continue
        der_id_by_bus[id_bus] = der_id_by_demand[id_dem]
    end

    return der_id_by_bus
end
