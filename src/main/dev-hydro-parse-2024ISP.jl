using PISP
using Dates

# Initialise DataFrames
tc = PISPtimeConfig();
ts = PISPtimeStatic();
tv = PISPtimeVarying();

# ======================================== #
# Data file paths   
# ======================================== #
datapath    = normpath(@__DIR__, "..", "..", "data"); # Adjust this path as needed
ispdata19   = normpath(datapath, "2019InputandAssumptionsworkbookv13Dec19.xlsx");
ispdata24   = normpath(datapath, "2024 ISP Inputs and Assumptions workbook.xlsx");
profiledata = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/Traces/";
outlookdata = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/2024 ISP generation and storage outlook/Core";
outlookAEMO = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/CapacityOutlook_2024_ISP_melted_CDP14.xlsx";
vpp_cap     = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/Storage/StorageOutlook_Capacity.xlsx";
vpp_ene     = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/Storage/StorageOutlook_Energy.xlsx";
dsp_data    = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/2024ISP_DSP.xlsx";

# ================================================ #
#  Define dates and scenarios for data collection  #
# ================================================ #
# --> Example of problem table
# `name`          : Name of the study/case
# `scenario`      : Scenario id as per ID2SCE dictionary in PISPparameters.jl
# `weight`        : Weight of the scenario
# `problem_type`  : UC (unit commitment) - just for reference
# `dstart`        : Start date of the study [to generate only the corresponding traces]
# `dend`          : End date of the study [to generate only the corresponding traces]
# `tstep`         : Time step in minutes
# ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#  Row │ id     name                    scenario  weight   problem_type  dstart               dend                 tstep |
#      │ Int64  String                  Int64     Float64  String        DateTime             DateTime             Int64 |
# ─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#    1 │     1  Progressive_Change_1           1      1.0  UC            2025-01-01T00:00:00  2025-01-07T23:00:00     60 |
#    2 │     2  Step_Change_2                  2      1.0  UC            2025-01-08T00:00:00  2025-01-14T23:00:00     60 |
#    3 │     3  Green_Energy_Exports_3         3      1.0  UC            2025-01-15T00:00:00  2025-01-21T23:00:00     60 |
# ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

function fill_problem_table(tc::PISPtimeConfig)
    start_date = DateTime(2025, 1, 1, 0, 0, 0)
    step_ = Day(7) 
    nblocks = 3 # 1 block per scenario to be called in the following loop [this is just an example]
    date_blocks = PISP.OrderedDict()
    ref_year = 2025

    for i in 1:nblocks
        dstart = start_date + (i-1) * step_
        dend = dstart + Day(6) + Hour(23)

        if month(dend) >= 07 && month(dstart) <= 6
            dend = DateTime(year(dstart), month(dstart), 30, 23, 0, 0)
        end

        if i>1 && day(date_blocks[i-1][2]) == 30 && month(date_blocks[i-1][2]) == 6
            dstart = DateTime(year(dstart), month(dstart), 1, 0, 0, 0)
        end

        date_blocks[i] = (dstart, dend)
    end

    i = 1
    for sc in keys(PISP.ID2SCE)
        pbname = "$(PISP.ID2SCE[sc])_$(i)"
        nd_yr = ref_year
        dstart = DateTime(nd_yr, month(date_blocks[i][1]), day(date_blocks[i][1]), 0, 0, 0)
        dend   = DateTime(nd_yr, month(date_blocks[i][2]), day(date_blocks[i][2]), 23, 0, 0)
        arr = [i, replace(pbname," "=> "_"), sc, 1, "UC", dstart, dend, 60]
        push!(tc.problem, arr)
        i = i + 1
    end
end

fill_problem_table(tc);
# ============================================ #
# ======= Fill tables with information  ====== #
# ============================================ #
PISP.bus_table(ts); 
PISP.dem_load(tc, ts, tv, profiledata);

txdata = PISP.line_table(ts, tv, ispdata24);
PISP.line_sched_table(tc, tv, txdata);
PISP.line_invoptions(ts, ispdata24);

SYNC4, GENERATORS, PS = PISP.generator_table(ts, ispdata19, ispdata24);
PISP.gen_n_sched_table(tv, SYNC4, GENERATORS);
PISP.gen_retirements(ts, tv);
PISP.gen_pmax_distpv(tc, ts, tv, profiledata);
PISP.gen_pmax_solar(tc, ts, tv, ispdata24, outlookdata, outlookAEMO, profiledata);
PISP.gen_pmax_wind(tc, ts, tv, ispdata24, outlookdata, outlookAEMO, profiledata);
# ============================================ #
# Develop generator inflows 
# ============================================ #
using CSV
using DataFrames
const HOURS_PER_DAY = 24

# Move these functions to PISPutils-2024ISP.jl later TODO
function weather_years_df(d::Dict)
    parse_date(x) = x isa Date ? x : Date(x, dateformat"yyyy-mm-dd")
    rows = [(parse_date(s), parse_date(e), string(v)) for ((s,e), v) in d]
    return sort!(DataFrame(rows, [:start_date, :end_date, :label]), :start_date)
end

function monthly_to_hourly(df::DataFrame; date_col::Symbol=:exact_date, value_col::Symbol=:value)
    n = nrow(df)
    # hours per row (days in month * 24)
    hours_per_row = Dates.daysinmonth.(df[!, date_col]) .* HOURS_PER_DAY
    total_hours = sum(hours_per_row)

    dates_out  = Vector{DateTime}(undef, total_hours)
    values_out = Vector{Float64}(undef, total_hours)

    pos = 1
    for i in 1:n
        dt0 = DateTime(df[i, date_col])       # start at midnight on the 1st
        h   = hours_per_row[i]
        v   = Float64(df[i, value_col]) / h  # hourly value
        for off in 0:h-1
            dates_out[pos]  = dt0 + Hour(off)
            values_out[pos] = v
            pos += 1
        end
    end

    return DataFrame(date = dates_out, value = values_out)
end

function expand_yearly_to_hourly(df_energy)
    n = nrow(df_energy)
    hourly_dates = DateTime[]
    hourly_limits = Float64[]

    for i in 1:n
        start_dt = df_energy.date[i]
        stop_dt = i < n ? df_energy.date[i + 1] : start_dt + Year(1)
        hours = collect(start_dt:Hour(1):stop_dt - Hour(1))
        append!(hourly_dates, hours)
        append!(hourly_limits, fill(df_energy.HourlyLimit[i], length(hours)))
    end

    return DataFrame(date = hourly_dates, HourlyLimit = hourly_limits)
end

function build_hourly_snowy(
    ispdata24;
    weather_years = PISP.WEATHER_YEARS,
    sheet_name = "Hydro Scheme Inflows",
    cell_range = "B34:N47",
)
    monthly_cols = Symbol.([:Jul, :Aug, :Sep, :Oct, :Nov, :Dec, :Jan, :Feb, :Mar, :Apr, :May, :Jun])
    month_map = Dict(
        "Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4, "May" => 5, "Jun" => 6,
        "Jul" => 7, "Aug" => 8, "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12,
    )

    weather_df = weather_years_df(weather_years)

    data = PISP.read_xlsx_with_header(ispdata24, sheet_name, cell_range)
    rename!(data, Symbol("Reference Year (FYE)") => :ref_year)

    monthly_lookup = select(data, :ref_year => ByRow(string) => :label, monthly_cols...)

    weather_df = leftjoin(weather_df, monthly_lookup, on = :label)

    keep_cols = Not([:start_date, :end_date, :label])
    long = stack(weather_df, keep_cols, variable_name = :month, value_name = :value)

    month_str = strip.(string.(long.month))
    month_num = get.(Ref(month_map), month_str, missing)

    if any(ismissing, month_num)
        bad = unique(month_str[ismissing.(month_num)])
        throw(ArgumentError("Unexpected month names: $bad"))
    end

    year_vec = ifelse.(month_num .>= 7, year.(long.start_date), year.(long.end_date))
    long[!, :exact_date] = Date.(year_vec, month_num, 1)

    sort!(long, [:start_date, :exact_date])

    hourly_input = select(long, [:exact_date, :value])
    return monthly_to_hourly(hourly_input)
end

# ============================================ #
gen       = ts.gen
hydro_gen = filter(row -> row.fuel == "Hydro", gen)
hydro_gen[!, :gen_totcap] = hydro_gen.pmax .* hydro_gen.n # Total installed capacity of hydro generators
gen_inflow_dummy = deepcopy(tv.gen_inflow)

# Pre-group generators by inflow file
gens_by_file = Dict{String, Vector{typeof(first(first(PISP.HYDRO2FILE)))}}()
for (gen_id, fname) in PISP.HYDRO2FILE
    push!(get!(Vector{typeof(gen_id)}, gens_by_file, fname), gen_id)
end

gens_by_file_sorted = Dict(fname => sort!(copy(ids)) for (fname, ids) in gens_by_file) # Associate each inflow file to a sorted list of generator that receive the corresponding inflow
hydro_groups = Dict(
    fname => subset(hydro_gen, :id_gen => ByRow(in(ids)))
    for (fname, ids) in gens_by_file_sorted
)
# ============================================ #

# 1 - Hydro Inflows
for scenario in keys(PISP.SCE)
    hydro_root    = "/Users/papablaza/git/ARPST-CSIRO-STAGE-5/PISP-dev.jl/data/2024 ISP Model/2024 ISP $(scenario)/Traces/hydro/"
    sce_label     = PISP.SCE[scenario]      # Scenario number
    hydro_sce     = PISP.HYDROSCE[scenario] # Hydro scenario from PLEXOS model

    for (file_name, gen_ids) in gens_by_file_sorted
        startswith(file_name, "MonthlyNaturalInflow") || continue # Skip file with energy constraints and only process inflow files

        gen_entries = hydro_groups[file_name]
        total_cap   = sum(gen_entries.gen_totcap)
        gen_entries[!, :partial] .= gen_entries.gen_totcap ./ total_cap
        #print gen_entries id_gen, gen_totcap, partial
        # println(gen_entries[:, [:id_gen, :name, :gen_totcap, :partial]])

        filepath = normpath(hydro_root, file_name * "_" * hydro_sce * ".csv")
        inflow_data = CSV.read(filepath, DataFrame)

        # Create timestamped DataFrame with daily inflows
        df_timestamped = select(
            transform(inflow_data, [:Year, :Month, :Day] => ByRow(DateTime) => :date),
            :date, :Inflows
        )

        n_days       = nrow(df_timestamped)
        n_hours      = n_days * HOURS_PER_DAY
        base_dates   = Vector{DateTime}(undef, n_hours)
        base_inflows = Vector{Float64}(undef, n_hours)

        idx = 1
        for row in eachrow(df_timestamped)
            per_hour = row.Inflows / HOURS_PER_DAY # Distribute daily inflow equally over 24 hours
            for h in 0:HOURS_PER_DAY-1
                base_dates[idx]   = row.date + Hour(h)
                base_inflows[idx] = per_hour
                idx += 1
            end
        end

        base_ids = collect(1:n_hours)

        # Pro-rate inflows among generators based on their capacity share
        for row in eachrow(gen_entries)
            scaled = base_inflows .* row.partial
            append!(gen_inflow_dummy, DataFrame(
                id       = base_ids,
                id_gen   = fill(row.id_gen, n_hours),
                scenario = fill(sce_label, n_hours),
                date     = base_dates,
                value    = scaled,
            ))
        end
    end
end

# 2 - Yearly Energy Limits
for scenario in keys(PISP.SCE)
    hydro_root    = "/Users/papablaza/git/ARPST-CSIRO-STAGE-5/PISP-dev.jl/data/2024 ISP Model/2024 ISP $(scenario)/Traces/hydro/"
    sce_label     = PISP.SCE[scenario]      # Scenario number
    hydro_sce     = PISP.HYDROSCE[scenario] # Hydro scenario from PLEXOS model

    for (file_name, gen_ids) in gens_by_file_sorted
        startswith(file_name, "MaxEnergyYear") || continue # Skip file with energy constraints and only process inflow files

        gen_entries = hydro_groups[file_name]
        gen_entries[!, :constraint] = [PISP.HYDRO2CNS[row.id_gen] for row in eachrow(gen_entries)] # Map generator to its energy constraint

        filepath    = normpath(hydro_root, file_name * "_" * hydro_sce * ".csv") # Path to energy constraint file
        inflow_data = CSV.read(filepath, DataFrame) # Read energy constraint data

        for constraint in unique(values(PISP.HYDRO2CNS))                        # Loop over unique constraints (many generators may be associated to one constraint)
            cns_gens = filter(row -> row.constraint == constraint, gen_entries) # Get generators under this constraint

            total_cns_cap          = sum(cns_gens.gen_totcap)               # Total capacity of generators under this constraint
            cns_gens[!, :partial] .= cns_gens.gen_totcap ./ total_cns_cap   # Proportion of each generator's capacity to total constraint capacity

            df_energy                  = select(inflow_data, [:Year, Symbol(constraint)])  # Extract energy constraint data for this constraint
            df_energy[!, :HourlyLimit] = df_energy[!, Symbol(constraint)] ./ (8760.0/1000) # Convert annual energy (GWh) to `hourly power inflow` (MW)
            df_energy[!, :date]        = [DateTime(row.Year, 7, 1, 0, 0, 0) for row in eachrow(df_energy)] 

            df_energy_hourly = expand_yearly_to_hourly(df_energy) # Expand yearly limits to hourly limits

            for row in eachrow(cns_gens)
                # Pro-rate energy limits among generators based on their capacity share
                scaled_limits = df_energy_hourly.HourlyLimit .* row.partial
                append!(gen_inflow_dummy, DataFrame(
                    id       = collect(1:nrow(df_energy_hourly)),
                    id_gen   = fill(row.id_gen, nrow(df_energy_hourly)),
                    scenario = fill(sce_label, nrow(df_energy_hourly)),
                    date     = df_energy_hourly.date,
                    value    = scaled_limits,
                ))
            end
        end
    end
end

# 3 - Snowy Scheme Inflows
hourly_snowy = build_hourly_snowy(ispdata24); # Generate hourly values for the Snowy scheme (Tumut, Murray, etc) using the inflows from the IASR 
df_snowy_capacity = nothing
for scenario in keys(PISP.SCE)
    sce_label     = PISP.SCE[scenario]      # Scenario number
    for (file_name, gen_ids) in gens_by_file_sorted
        startswith(file_name, "SNOWY_SCHEME") || continue   # Skip file with energy constraints and only process inflow files
        # Work on a copy to avoid mutating the original hydro_groups lookup
        gen_entries = deepcopy(hydro_groups[file_name])

        # For each Snowy group keep only the generator with the largest capacity (avoid double counting)
        for group in values(PISP.SNOWY_HYDRO_GROUPS)
            present = filter(row -> row.id_gen in group, gen_entries)
            if nrow(present) > 1
                # find index of the generator with the largest capacity and keep it
                _, rel_idx = findmax(present.gen_totcap)
                to_keep = present[rel_idx, :id_gen]
                to_remove = setdiff(group, [to_keep])
                if !isempty(to_remove)
                    gen_entries = filter(row -> !(row.id_gen in to_remove), gen_entries)
                end
            end
        end

        # Recalculate totals and partial shares
        total_cap = sum(gen_entries.gen_totcap)
        gen_entries[!, :partial] .= gen_entries.gen_totcap ./ total_cap

        # Precompute hourly vectors once for this Snowy dataset
        n_hourly = nrow(hourly_snowy)
        hourly_ids = collect(1:n_hourly)
        hourly_dates = hourly_snowy.date
        hourly_values = hourly_snowy.value

        for group in values(PISP.SNOWY_HYDRO_GROUPS)
            # Generators associated to the Snowy group
            group_entries = filter(row -> row.id_gen in group, gen_entries) 
            share_group   = sum(group_entries.partial) # Generation share of the group (%)

            for id_gen in group # Generators forming the Snowy group
                hydro_dam = PISP.HYDRO_DAMS_GENS[id_gen]
                share_dam = get(PISP.DAM_SHARES, hydro_dam, 0.0)
                share_gen = share_group * share_dam
                println("Scenario: ", sce_label, " Gen: ", id_gen, " Share gen: ", share_gen)
                scaled_inflows = hourly_values .* share_gen * 1000.0 # Scale to MW (same as original)

                append!(gen_inflow_dummy, DataFrame(
                    id       = hourly_ids,
                    id_gen   = fill(id_gen, n_hourly),
                    scenario = fill(sce_label, n_hourly),
                    date     = hourly_dates,
                    value    = scaled_inflows,
                ))
            end
        end
        df_snowy_capacity = gen_entries
    end
end

# Final order of the inflow dataframe
for row in eachrow(tc.problem)
    sce    = row.scenario
    dstart = row.dstart
    dend   = row.dend

    df_filt = filter(r -> r.scenario == sce && r.date >= dstart && r.date <= dend, gen_inflow_dummy)
    append!(tv.gen_inflow, df_filt)
end
sort!(tv.gen_inflow, [:id_gen, :scenario, :date])
tv.gen_inflow[!, :id] = collect(1:nrow(tv.gen_inflow))
# save tv_gen_inflow as CSV for checking
CSV.write("tv_gen_inflow_2024ISP.csv", tv.gen_inflow)

# ============================================ #
PISP.ess_tables(ts, tv, PS, ispdata24);
PISP.ess_vpps(tc, ts, tv, vpp_cap, vpp_ene);

# ============================================ #
ess       = ts.ess
gen       = ts.gen
tumut_ps  = filter(row -> row.name == "Tumut 3", ess)
id_tumut  = tumut_ps.id_ess[1]
hourly_snowy = build_hourly_snowy(ispdata24); # Generate hourly values for the Snowy scheme (Tumut, Murray, etc) using the inflows from the IASR
ess_inflow_dummy = deepcopy(tv.ess_inflow)
# Calculate dam share
t3_dams  = PISP.HYDRO_DAMS_STORAGE[id_tumut]
t3_share = 0.0
for dam in t3_dams
    t3_share += get(PISP.DAM_SHARES, dam, 0.0)
end

# Calculate generator share
tumut_gen = PISP.HYDRO_STORAGE_GEN[id_tumut]
tumut_entry = filter(row -> row.id_gen == tumut_gen, df_snowy_capacity)
tumut_partial = tumut_entry.partial

t3_total_share = t3_share * tumut_partial[1]

hourly_values = hourly_snowy.value
n_hourly      = nrow(hourly_snowy)
hourly_ids    = collect(1:n_hourly)
for scenario in keys(PISP.SCE)
    sce_label      = PISP.SCE[scenario]      # Scenario number
    scaled_inflows = hourly_values .* t3_total_share * 1000.0 # Scale to MW (same as original)
    append!(ess_inflow_dummy, DataFrame(
        id       = hourly_ids,
        id_ess   = fill(id_tumut, n_hourly),
        scenario = fill(sce_label, n_hourly),
        date     = hourly_snowy.date,
        value    = scaled_inflows,
    ))
end

# Final order of the inflow dataframe
for row in eachrow(tc.problem)
    sce    = row.scenario
    dstart = row.dstart
    dend   = row.dend

    df_filt = filter(r -> r.scenario == sce && r.date >= dstart && r.date <= dend, ess_inflow_dummy)
    println(df_filt)
    append!(tv.ess_inflow, df_filt)
end
sort!(tv.ess_inflow, [:id_ess, :scenario, :date])
tv.ess_inflow[!, :id] = collect(1:nrow(tv.ess_inflow))
# save tv_ess_inflow as CSV for checking
CSV.write("tv_ess_inflow_2024ISP.csv", tv.ess_inflow)


# ============================================ #

# hydro_gen = filter(row -> row.fuel == "Hydro", gen)
# hydro_gen[!, :gen_totcap] = hydro_gen.pmax .* hydro_gen.n # Total installed capacity of hydro generators
# ess_inflow_dummy = deepcopy(tv.ess_inflow)
# hourly_snowy = build_hourly_snowy(ispdata24)
# # gen_inflow_dummy = deepcopy(tv.gen_inflow)

# # Pre-group generators by inflow file
# gens_by_file = Dict{String, Vector{typeof(first(first(PISP.HYDRO2FILE)))}}()
# for (gen_id, fname) in PISP.HYDRO2FILE
#     push!(get!(Vector{typeof(gen_id)}, gens_by_file, fname), gen_id)
# end

# gens_by_file_sorted = Dict(fname => sort!(copy(ids)) for (fname, ids) in gens_by_file) # Associate each inflow file to a sorted list of generator that receive the corresponding inflow
# hydro_groups = Dict(
#     fname => subset(hydro_gen, :id_gen => ByRow(in(ids)))
#     for (fname, ids) in gens_by_file_sorted
# )

# # Pre-group generators by inflow file
# ess_by_file = Dict{String, Vector{typeof(first(first(PISP.PS2FILE)))}}()
# for (ess_id, fname) in PISP.PS2FILE
#     push!(get!(Vector{typeof(ess_id)}, ess_by_file, fname), ess_id)
# end

# # 1 - Snowy Scheme Inflows for TUMUT PS
# for scenario in keys(PISP.SCE)
#     sce_label     = PISP.SCE[scenario]      # Scenario number
#     for (file_name, gen_ids) in gens_by_file_sorted
#         startswith(file_name, "SNOWY_SCHEME") || continue   # Skip file with energy constraints and only process inflow files

#         # Work on a copy to avoid mutating the original hydro_groups lookup
#         gen_entries = deepcopy(hydro_groups[file_name])

#         # For each Snowy group keep only the generator with the largest capacity (avoid double counting)
#         for group in values(PISP.SNOWY_HYDRO_GROUPS)
#             present = filter(row -> row.id_gen in group, gen_entries)
#             if nrow(present) > 1
#                 # find index of the generator with the largest capacity and keep it
#                 _, rel_idx = findmax(present.gen_totcap)
#                 to_keep = present[rel_idx, :id_gen]
#                 to_remove = setdiff(group, [to_keep])
#                 if !isempty(to_remove)
#                     gen_entries = filter(row -> !(row.id_gen in to_remove), gen_entries)
#                 end
#             end
#         end

#         # Recalculate totals and partial shares
#         total_cap = sum(gen_entries.gen_totcap)
#         gen_entries[!, :partial] .= gen_entries.gen_totcap ./ total_cap

#         # Precompute hourly vectors once for this Snowy dataset
#         n_hourly = nrow(hourly_snowy)
#         hourly_ids = collect(1:n_hourly)
#         hourly_dates = hourly_snowy.date
#         hourly_values = hourly_snowy.value

#         for group in values(PISP.SNOWY_HYDRO_GROUPS)
#             # Generators associated to the Snowy group
#             group_entries = filter(row -> row.id_gen in group, gen_entries) 
#             share_group   = sum(group_entries.partial) # Generation share of the group (%)

#             for id_gen in group # Generators forming the Snowy group
#                 hydro_dam = PISP.HYDRO_DAMS_GENS[id_gen]
#                 share_dam = get(PISP.DAM_SHARES, hydro_dam, 0.0)
#                 share_gen = share_group * share_dam
#                 println("Scenario: ", sce_label, " Gen: ", id_gen, " Share gen: ", share_gen)
#                 scaled_inflows = hourly_values .* share_gen * 1000.0 # Scale to MW (same as original)

#                 append!(gen_inflow_dummy, DataFrame(
#                     id       = hourly_ids,
#                     id_gen   = fill(id_gen, n_hourly),
#                     scenario = fill(sce_label, n_hourly),
#                     date     = hourly_dates,
#                     value    = scaled_inflows,
#                 ))
#             end
#         end
#     end
# end


# for scenario in keys(PISP.SCE)
#     sce_label     = PISP.SCE[scenario]      # Scenario number

#     for (file_name, gen_ids) in ess_by_file
#         # startswith(file_name, "SNOWY_SCHEME") || continue # Skip file with energy constraints and only process inflow files
#         # gen_entries = hydro_groups[file_name]
#         # total_cap   = sum(gen_entries.gen_totcap)
#         # gen_entries[!, :partial] .= gen_entries.gen_totcap ./ total_cap
#         for id_gen in gen_ids
#             hydro_dam = PISP.HYDRO_DAMS_GENS[id_gen] # Name of the hydro dam
#             share_dam = PISP.DAM_SHARES[hydro_dam] # Share of the dam for this generator
#             share_gen = filter(row -> row.id_gen == id_gen, gen_entries)[1, :partial] # Share of the generator in the snowy scheme
#             snowy_share = share_dam * share_gen

#             scaled_inflows = hourly_snowy.value .* snowy_share * 1000.0 # Scale to MW
#             append!(gen_inflow_dummy, DataFrame(
#                 id       = collect(1:nrow(hourly_snowy)),
#                 id_gen   = fill(id_gen, nrow(hourly_snowy)),
#                 scenario = fill(sce_label, nrow(hourly_snowy)),
#                 date     = hourly_snowy.date,
#                 value    = scaled_inflows,
#             ))
#         end
#     end
# end

# PISP.der_tables(ts);
# PISP.der_pred_sched(ts, tv, dsp_data);

# ============================================ #
# ============================================ #
