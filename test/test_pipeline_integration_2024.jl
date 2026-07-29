# Integration characterization test for the 2024 populate stage: exercises
# PISP.populate_time_static!/PISP.populate_time_varying! end-to-end against the real
# local data/2024/pisp-downloads/ checkout, for one scenario and one short date window.
# This is the call graph PISP.build_ISP24_datasets itself runs after the one-time
# PISP.build_pipeline data-preparation step, so it reaches almost every function in
# src/parsers/PISP-2024parser.jl, src/parsers/PISP-2024core.jl, src/parsers/PISP-2024ev.jl,
# and the df-evs/df-hydro/general utils — the largest previously-0%-covered source files.
# PISP.build_pipeline itself is deliberately never called here: it downloads/re-extracts
# archives and regenerates Auxiliary/ outlook workbooks and 4006 traces in place, mutating
# the real local checkout, which a test must never do. Skipped gracefully when the real
# AEMO data is absent, since CI has no access to it.
#
# Note: populate_time_static! -> generator_table creates a scratch test/.tmp/ directory
# (relative to the process's working directory) with ~26 intermediate workbooks; this is
# pre-existing src/ behaviour, not introduced here, and test/.tmp/ is already gitignored.
#
# Takes noticeably longer than the rest of the suite (real workbook/CSV I/O). Set
# PISP_SKIP_SLOW_TESTS=1 to skip it for a fast local inner loop; CI already skips it via
# the data-presence check below, so this is purely a local dev convenience.

using DataFrames
using Dates

pipeline_integration_2024_edition = only(filter(
    p -> p.edition == "2024",
    source_availability_profiles(normpath(joinpath(@__DIR__, ".."))),
))
pipeline_integration_2024_available = inspect_edition(pipeline_integration_2024_edition).state == :complete
pipeline_integration_2024_skip_slow = get(ENV, "PISP_SKIP_SLOW_TESTS", "") == "1"

@testset "pipeline integration: populate_time_static!/populate_time_varying! (2024, Step Change, one day)" begin
    if pipeline_integration_2024_skip_slow
        @test_skip "PISP_SKIP_SLOW_TESTS=1; skipping the slow real-data pipeline integration test"
    elseif !pipeline_integration_2024_available
        @test_skip "2024 pisp-downloads material is absent; pipeline integration test requires the real AEMO workbooks/CSVs"
    else
        paths = PISP.default_data_paths(filepath=pipeline_integration_2024_edition.download_root)

        tc, ts, tv = PISP.initialise_time_structures()
        PISP.fill_problem_table_drange(tc, DateTime(2030, 1, 1, 0, 0, 0), DateTime(2030, 1, 1, 23, 0, 0); sce=[2])

        static_artifacts = PISP.populate_time_static!(ts, tv, paths; refyear=4006, poe=10)
        PISP.populate_time_varying!(tc, ts, tv, paths, static_artifacts; refyear=4006, poe=10, skip_traces=false)

        @testset "static tables (ts)" begin
            @test size(ts.bus) == (12, 7)
            @test names(ts.bus) == ["id_bus", "name", "alias", "active", "latitude", "longitude", "id_area"]
            @test collect(ts.bus[1, :]) == Any[1, "NQ", "Northern Queensland", true, -17.79385, 145.5635, 1]

            @test size(ts.dem) == (12, 8)
            @test names(ts.dem) == ["id_dem", "name", "load_", "id_bus", "active", "controllable", "voll", "contingency"]

            @test size(ts.ess) == (73, 37)
            @test names(ts.ess) == ["id_ess", "name", "alias", "tech", "type", "capacity", "investment",
                                     "active", "id_bus", "ch_eff", "dch_eff", "eini", "emin", "emax", "pmin",
                                     "pmax", "lmin", "lmax", "fullout", "partialout", "mttrfull", "mttrpart",
                                     "inertia", "powerfactor", "ffr", "pfr", "res2", "res3", "fr_db", "fr_ad",
                                     "fr_dt", "fr_frt", "fr_fr", "longitude", "latitude", "n", "contingency"]

            @test size(ts.gen) == (124, 48)
            @test names(ts.gen) == ["id_gen", "name", "alias", "fuel", "tech", "type", "capacity", "forate",
                                     "fullout", "partialout", "derate", "mttrfull", "mttrpart", "id_bus", "pmin",
                                     "pmax", "rup", "rdw", "investment", "active", "cvar", "cfuel", "cvom",
                                     "cfom", "co2", "slope", "hrate", "pfrmax", "g", "inertia", "ffr", "pfr",
                                     "res2", "res3", "powerfactor", "latitude", "longitude", "n", "contingency",
                                     "down_time", "up_time", "last_state", "last_state_period",
                                     "last_state_output", "start_up_cost", "shut_down_cost", "start_up_time",
                                     "shut_down_time"]
            @test collect(ts.gen[1, 1:8]) ==
                  Any[1, "Bayswater", "BW01", "Coal", "Black Coal NSW", "Steam Sub Critical", 678.75, 0.6745236000000001]

            @test size(ts.line) == (54, 22)
            @test names(ts.line) == ["id_lin", "name", "alias", "tech", "capacity", "id_bus_from", "id_bus_to",
                                      "investment", "active", "r", "x", "rvcap", "fwcap", "fullout", "mttrfull",
                                      "voltage", "segments", "latitude", "longitude", "length", "n", "contingency"]

            @test size(ts.der) == (72, 11)
            @test names(ts.der) == ["id_der", "name", "tech", "id_dem", "active", "investment", "capacity",
                                     "reduct", "pred_max", "cost_red", "n"]
        end

        @testset "time-varying tables (tv)" begin
            @test size(tv.dem_load) == (288, 5)
            @test collect(tv.dem_load[1, :]) == Any[1, 1, 2, DateTime(2030, 1, 1, 0, 0, 0), 749.427093165194]

            @test size(tv.ess_emax) == (12, 5)
            @test size(tv.ess_lmax) == (12, 5)
            @test size(tv.ess_n) == (84, 5)

            @test size(tv.ess_pmax) == (12, 5)
            @test collect(tv.ess_pmax[1, :]) == Any[1, 62, 2, DateTime(2030, 1, 1, 0, 0, 0), 118.8294867]

            @test size(tv.ess_inflow) == (24, 5)
            @test collect(tv.ess_inflow[1, :]) == Any[1, 59, 2, DateTime(2030, 1, 1, 0, 0, 0), 4.9647956459628055]

            @test size(tv.gen_n) == (201, 5)

            @test size(tv.gen_pmax) == (795, 5)
            @test collect(tv.gen_pmax[1, :]) == Any[1, 78, 1, DateTime(2044, 7, 1, 0, 0, 0), 106.0]

            @test size(tv.gen_inflow) == (720, 5)
            @test collect(tv.gen_inflow[1, :]) == Any[1, 23, 2, DateTime(2030, 1, 1, 0, 0, 0), 4.38160830479452]

            @test size(tv.line_fwcap) == (20, 5)
            @test collect(tv.line_fwcap[1, :]) == Any[1, 15, 1, DateTime(2024, 7, 1, 0, 0, 0), 150.0]

            @test size(tv.line_rvcap) == (20, 5)

            @test size(tv.der_pred) == (11448, 5)
            @test collect(tv.der_pred[1, :]) == Any[1, 1, 1, DateTime(2023, 11, 1, 0, 0, 0), 0.0]
        end
    end
end
