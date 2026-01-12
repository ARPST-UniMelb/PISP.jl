"""
    initialise_time_structures()

Create and return fresh `PISPtimeConfig`, `PISPtimeStatic`, and `PISPtimeVarying`
containers. Encapsulating this logic in one helper keeps the script consistent
any time new runs are started or when the structures are re-created in tests.

# Returns
- `Tuple{PISPtimeConfig,PISPtimeStatic,PISPtimeVarying}`: The three empty
  containers required by the subsequent population routines.
"""
function initialise_time_structures()
    return (PISPtimeConfig(), PISPtimeStatic(), PISPtimeVarying())
end

"""
    fill_problem_example(tc)

Example to populate the `tc.problem` table with a week-long block for each scenario
registered in `PISP.ID2SCE`. The helper constructs start and end dates by
stepping from 1 January 2025 and wrapping at the June boundary so that no
interval spans financial years.

# Arguments
- `tc::PISPtimeConfig`: Time configuration container whose `problem` DataFrame
  receives the generated rows.
"""
function fill_problem_example(tc::PISPtimeConfig)
    start_date = DateTime(2030, 1, 1, 0, 0, 0)
    step_ = Day(120)
    nblocks = 3
    date_blocks = PISP.OrderedDict()
    ref_year = 2025

    for i in 1:nblocks
        dstart = start_date + (i - 1) * step_
        dend = dstart + Day(6) + Hour(23)

        if month(dend) >= 7 && month(dstart) <= 6
            dend = DateTime(year(dstart), month(dstart), 30, 23, 0, 0)
        end

        if i > 1 && day(date_blocks[i - 1][2]) == 30 && month(date_blocks[i - 1][2]) == 6
            dstart = DateTime(year(dstart), month(dstart), 1, 0, 0, 0)
        end

        date_blocks[i] = (dstart, dend)
    end

    i = 1
    for sc in keys(PISP.ID2SCE)
        pbname = "$(PISP.ID2SCE[sc])_$(i)"
        nd_yr = ref_year
        dstart = DateTime(nd_yr, month(date_blocks[i][1]), day(date_blocks[i][1]), 0, 0, 0)
        dend = DateTime(nd_yr, month(date_blocks[i][2]), day(date_blocks[i][2]), 23, 0, 0)
        arr = [i, replace(pbname, " " => "_"), sc, 1, "UC", dstart, dend, 60]
        push!(tc.problem, arr)
        i += 1
    end
end

"""
    populate_time_config!(tc)

Fill the time-configuration container with scenario metadata. This wrapper keeps
the mutation steps for `tc` in a single call-site so that new configuration
sections can be added in one place.

# Arguments
- `tc::PISPtimeConfig`: The configuration container to populate.

# Returns
- `PISPtimeConfig`: The same instance that was mutated, which permits piping the
  result into subsequent functions when convenient.
"""
function populate_time_config!(tc::PISPtimeConfig, fill_problem_function::Function)
    fill_problem_function(tc)
    return tc
end

"""
    populate_time_static!(tc, ts, tv, paths)

Construct the time-static portion of the ISP model. The function loads bus,
demand, line, generator, ESS and DER metadata using the file paths provided by
`paths` and stores the results in `ts` (with the required auxiliary data kept
for later steps).

# Arguments
- `tc::PISPtimeConfig`: Configuration container that supplies time blocks for demand processing.
- `ts::PISPtimeStatic`: Static data container that receives the tabular data.
- `tv::PISPtimeVarying`: Passed through so that `PISP.dem_load` can populate the static and varying demand components together.
- `paths::NamedTuple`: Must contain `profiledata`, `ispdata19`, and `ispdata24`.

# Returns
- `NamedTuple`: Contains `txdata` (line metadata) and `generator_tables`
  (currently exposing the `SYNC4`, `GENERATORS`, and `PS` tables) that are
  required by the time-varying stage.
"""
function populate_time_static!(ts::PISPtimeStatic, tv::PISPtimeVarying, paths::NamedTuple; refyear::Int64=2011, poe::Int64=10)
    PISP.bus_table(ts)
    PISP.dem_load(ts)

    txdata = PISP.line_table(ts, tv, paths.ispdata24)
    PISP.line_invoptions(ts, paths.ispdata24)

    SYNC4, GENERATORS, PS = PISP.generator_table(ts, paths.ispdata19, paths.ispdata24)
    PISP.ess_tables(ts, tv, PS, paths.ispdata24)
    PISP.der_tables(ts)

    return (
        txdata = txdata,
        generator_tables = (SYNC4 = SYNC4, GENERATORS = GENERATORS, PS = PS),
    )
end

"""
    populate_time_varying!(tc, ts, tv, paths, static_artifacts; refyear::Int64=2011)

Populate the time-varying data structures such as schedules, inflows and DER
profiles. The function expects the `static_artifacts` output of
`populate_time_static!` so that line schedules and generator schedules can be
derived without recomputing inputs.

# Arguments
- `tc::PISPtimeConfig`: Provides the configured periods for time-varying traces.
- `ts::PISPtimeStatic`: Supplies static context for inflows and DER schedules.
- `tv::PISPtimeVarying`: Target container for time-varying tables.
- `paths::NamedTuple`: Must include `profiledata`, `ispdata24`, `outlookdata`,
  `outlookAEMO`, `vpp_cap`, `vpp_ene`, and `dsp_data`.
- `static_artifacts::NamedTuple`: A direct output of
  `populate_time_static!`, providing `txdata`, `SYNC4`, and `GENERATORS`.

# Returns
- `NamedTuple`: Contains `SNOWY_GENS`, which may be needed by downstream
  post-processing utilities.
"""
function populate_time_varying!(tc::PISPtimeConfig, ts::PISPtimeStatic, tv::PISPtimeVarying,
        paths::NamedTuple, static_artifacts::NamedTuple; refyear::Int64=2011, poe::Int64=10)
    txdata = static_artifacts.txdata
    generator_tables = static_artifacts.generator_tables
    PISP.dem_load_sched(tc, tv, paths.profiledata; refyear=refyear, poe=poe)
    PISP.line_sched_table(tc, tv, txdata)
    PISP.gen_n_sched_table(tv, generator_tables.SYNC4, generator_tables.GENERATORS)
    PISP.gen_retirements(ts, tv)
    PISP.gen_pmax_distpv(tc, ts, tv, paths.profiledata; refyear=refyear, poe=poe)
    PISP.gen_pmax_solar(tc, ts, tv, paths.ispdata24, paths.outlookdata, paths.outlookAEMO, paths.profiledata; refyear=refyear)
    PISP.gen_pmax_wind(tc, ts, tv, paths.ispdata24, paths.outlookdata, paths.outlookAEMO, paths.profiledata; refyear=refyear)
    SNOWY_GENS = PISP.gen_inflow_sched(ts, tv, tc, paths.ispdata24, paths.ispmodel)

    PISP.ess_vpps(tc, ts, tv, paths.vpp_cap, paths.vpp_ene)
    PISP.ess_inflow_sched(ts, tv, tc, paths.ispdata24, SNOWY_GENS)
    PISP.der_pred_sched(ts, tv, paths.ispdata24)
end

"""
    write_time_data(ts, tv; csv_static_path, csv_varying_path,
                    arrow_static_path, arrow_varying_path,
                    write_static, write_varying)

Persist the populated static and time-varying tables to CSV and Arrow formats.
Output paths default to the test folders used prior to the refactor but can be
overridden via keyword arguments.

# Keyword Arguments
- `csv_static_path`:    Target directory for static CSV exports.
- `csv_varying_path`:   Target directory for time-varying CSV exports.
- `arrow_static_path`:  Target directory for static Arrow exports.
- `arrow_varying_path`: Target directory for time-varying Arrow exports.
- `write_static`:       Set to `false` to skip writing the static tables.
- `write_varying`:      Set to `false` to skip writing the time-varying tables.
"""
function write_time_data(
        ts::PISPtimeStatic,
        tv::PISPtimeVarying;
        csv_static_path::AbstractString,
        csv_varying_path::AbstractString,
        arrow_static_path::AbstractString,
        arrow_varying_path::AbstractString,
        write_static::Bool  = true,
        write_varying::Bool = true,
        output_root::Union{Nothing,AbstractString} = nothing,
        write_csv::Bool = true,
        write_arrow::Bool = true
)
    to_path(p) = isnothing(output_root) ? p : normpath(output_root, p)

    if write_static
        if write_csv PISP.PISPwritedataCSV(ts, to_path(csv_static_path)) end
        if write_arrow PISP.PISPwritedataArrow(ts, to_path(arrow_static_path)) end
    end

    if write_varying
        if write_csv PISP.PISPwritedataCSV(tv, to_path(csv_varying_path)) end
        if write_arrow PISP.PISPwritedataArrow(tv, to_path(arrow_varying_path)) end
    end
end
