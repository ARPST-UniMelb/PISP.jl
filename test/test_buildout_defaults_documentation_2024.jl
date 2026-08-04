using Test
using DataFrames
using Dates
using Tables
using XLSX

if !isdefined(@__MODULE__, :PISPDocUtils)
    include(joinpath(@__DIR__, "..", "docs", "utils", "PISPDocUtils.jl"))
end
import .PISPDocUtils

const BUILDOUT_LABELS = [
    "bess_1h", "bess_2h", "bess_4h", "bess_8h", "phsp_24h", "phsp_48h",
    "ccgt", "ocgt_l", "ocgt_s",
]
const BUILDOUT_ESS_LABELS = filter(label -> label in PISP._BUILDOUT_ESS_TECHS, BUILDOUT_LABELS)
const BUILDOUT_GEN_LABELS = filter(label -> label in PISP._BUILDOUT_GEN_TECHS, BUILDOUT_LABELS)

buildout_name(label) = uppercase(label * "_NQ") * "_NEW"

function buildout_fixture(; year = 2030, n_value = nothing)
    row_count = length(BUILDOUT_LABELS)
    return DataFrame(
        tech = copy(BUILDOUT_LABELS),
        subregion = fill("NQ", row_count),
        year = fill(year, row_count),
        capacity = [100.0 + index for index in 1:row_count],
        n = isnothing(n_value) ? collect(1:row_count) : fill(n_value, row_count),
    )
end

function initialise_buildout_structures()
    ts = PISP.PISPtimeStatic()
    tv = PISP.PISPtimeVarying()
    push!(ts.bus, [17, "NQ", "NQ", 1, 0.0, 0.0, 1])
    return ts, tv
end

function input_row(frame, label)
    return only(eachrow(frame[frame.tech .== label, :]))
end

function assert_uniform_schedule(schedule, asset_column, asset_id, source_row)
    rows = schedule[schedule[!, asset_column] .== asset_id, :]
    @test nrow(rows) == length(PISP.ID2SCE)
    @test sort(rows.scenario) == sort(collect(keys(PISP.ID2SCE)))
    @test all(==(DateTime(source_row.year, 1, 1)), rows.date)
    @test all(==(source_row.n), rows.value)
end

@testset "ISP 2024 build-out defaults documentation" begin
    parser_path = joinpath(@__DIR__, "..", "src", "parsers", "PISP-2024buildout.jl")
    @test PISPDocUtils.validate_buildout_defaults_contract(parser_path)

    generated_path = joinpath(
        @__DIR__, "..", "docs", "src", "generated", "isp2024", "reference", "buildout-defaults.md",
    )
    @test isfile(generated_path)
    generated = replace(read(generated_path, String), "\r\n" => "\n")

    reference_tables = PISPDocUtils.buildout_reference_tables()
    for (table_name, table) in pairs(reference_tables)
        expected = strip(replace(
            PISPDocUtils.markdown_table(table; allow_markdown_in_cells = true).text,
            "\r\n" => "\n",
        ))
        @testset "rendered $(table_name) table" begin
            @test occursin(expected, generated)
        end
    end

    for field in union(
        Set(PISPDocUtils.ESS_TEMPLATE_FIELDS),
        Set(PISPDocUtils.GEN_TEMPLATE_FIELDS),
    )
        @test occursin("`$field`", generated)
    end
    for row in PISPDocUtils.buildout_technology_rows()
        @test occursin("`$(row.buildout_label)`", generated)
    end
    for row in PISPDocUtils.buildout_placeholder_rows()
        @test occursin("`$(row.field)`", generated)
    end
    for source in Iterators.flatten((
        values(PISPDocUtils.ESS_FIELD_SOURCES),
        values(PISPDocUtils.GEN_FIELD_SOURCES),
    ))
        @test any(
            startswith(source, prefix)
            for prefix in PISPDocUtils.BUILDOUT_SOURCE_PREFIXES
        )
    end
    @test !occursin(r"\|\s*`[^`]+`\s*\|\s*`?nothing`?\s*\|", generated)
end

@testset "ISP 2024 uniform build-out applied rows" begin
    mktempdir() do directory
        workbook_path = joinpath(directory, "buildout-uniform.xlsx")
        fixture = buildout_fixture()
        XLSX.writetable(
            workbook_path,
            Tables.columntable(fixture);
            sheetname = "buildout_1",
            overwrite = true,
        )

        static_data, tvarying_data = PISP.read_buildout_table(
            workbook_path;
            sheetname = "buildout_1",
        )
        expected_names = buildout_name.(BUILDOUT_LABELS)
        @test static_data.name == expected_names
        @test static_data.subregion == fixture.subregion
        @test static_data.tech == fixture.tech
        @test static_data.capacity == fixture.capacity
        @test tvarying_data.name == expected_names
        @test tvarying_data.year == fixture.year
        @test tvarying_data.n == fixture.n

        ts, tv = initialise_buildout_structures()
        PISP.add_buildouts!(ts, tv, workbook_path; sheetname = "buildout_1")

        @test nrow(ts.ess) == length(BUILDOUT_ESS_LABELS)
        @test nrow(ts.gen) == length(BUILDOUT_GEN_LABELS)
        @test nrow(tv.ess_n) == length(BUILDOUT_ESS_LABELS) * length(PISP.ID2SCE)
        @test nrow(tv.gen_n) == length(BUILDOUT_GEN_LABELS) * length(PISP.ID2SCE)
        @test collect(tv.ess_n.id) == collect(1:nrow(tv.ess_n))
        @test collect(tv.gen_n.id) == collect(1:nrow(tv.gen_n))

        for (expected_id, label) in enumerate(BUILDOUT_ESS_LABELS)
            name = buildout_name(label)
            source_row = input_row(fixture, label)
            row = only(eachrow(ts.ess[ts.ess.name .== name, :]))
            template = PISP.params_buildout_bess[Symbol(label)]

            @test row.id_ess == expected_id
            @test row.name == name
            @test row.alias == name
            @test row.id_bus == 17
            @test row.capacity == source_row.capacity
            @test row.pmax == source_row.capacity
            @test row.lmax == source_row.capacity
            @test row.emax == PISP._BESS_DURATION_H[label] * source_row.capacity
            @test row.latitude == 0.0
            @test row.longitude == 0.0
            for field in PISPDocUtils.ESS_TEMPLATE_FIELDS
                @test row[Symbol(field)] == template[field]
            end

            assert_uniform_schedule(tv.ess_n, :id_ess, row.id_ess, source_row)
        end

        for (expected_id, label) in enumerate(BUILDOUT_GEN_LABELS)
            name = buildout_name(label)
            source_row = input_row(fixture, label)
            row = only(eachrow(ts.gen[ts.gen.name .== name, :]))
            template = PISP.params_buildout_gen[PISP._BUILDOUT_GEN_TECH_KEY[label]]

            @test row.id_gen == expected_id
            @test row.name == name
            @test row.alias == name
            @test row.id_bus == 17
            @test row.capacity == source_row.capacity
            @test row.pmax == source_row.capacity
            @test row.latitude == 0.0
            @test row.longitude == 0.0
            for field in PISPDocUtils.GEN_TEMPLATE_FIELDS
                @test row[Symbol(field)] == template[field]
            end

            assert_uniform_schedule(tv.gen_n, :id_gen, row.id_gen, source_row)
        end
    end
end

@testset "ISP 2024 scenario-specific build-out applied rows" begin
    mktempdir() do directory
        workbook_path = joinpath(directory, "buildout-scenarios.xlsx")
        scenario_ids = sort(collect(keys(PISP.ID2SCE)))
        scenario_frames = Dict(
            scid => buildout_fixture(year = 2030 + scid, n_value = scid)
            for scid in scenario_ids
        )
        sheet_pairs = [
            "scenario_$scid" => Tables.columntable(scenario_frames[scid])
            for scid in scenario_ids
        ]
        XLSX.writetable(workbook_path, sheet_pairs; overwrite = true)

        ts, tv = initialise_buildout_structures()
        scenario_sheets = Dict(scid => "scenario_$scid" for scid in scenario_ids)
        PISP.add_buildouts!(ts, tv, workbook_path; sc_buildouts = scenario_sheets)

        @test nrow(ts.ess) == length(BUILDOUT_ESS_LABELS)
        @test nrow(ts.gen) == length(BUILDOUT_GEN_LABELS)
        @test nrow(tv.ess_n) == length(BUILDOUT_ESS_LABELS) * length(scenario_ids)
        @test nrow(tv.gen_n) == length(BUILDOUT_GEN_LABELS) * length(scenario_ids)
        @test collect(tv.ess_n.id) == collect(1:nrow(tv.ess_n))
        @test collect(tv.gen_n.id) == collect(1:nrow(tv.gen_n))

        for label in BUILDOUT_ESS_LABELS
            name = buildout_name(label)
            static_row = only(eachrow(ts.ess[ts.ess.name .== name, :]))
            for scid in scenario_ids
                source_row = input_row(scenario_frames[scid], label)
                rows = tv.ess_n[
                    (tv.ess_n.id_ess .== static_row.id_ess) .& (tv.ess_n.scenario .== scid),
                    :,
                ]
                @test nrow(rows) == 1
                schedule_row = only(eachrow(rows))
                @test schedule_row.date == DateTime(source_row.year, 1, 1)
                @test schedule_row.value == source_row.n
            end
        end

        for label in BUILDOUT_GEN_LABELS
            name = buildout_name(label)
            static_row = only(eachrow(ts.gen[ts.gen.name .== name, :]))
            for scid in scenario_ids
                source_row = input_row(scenario_frames[scid], label)
                rows = tv.gen_n[
                    (tv.gen_n.id_gen .== static_row.id_gen) .& (tv.gen_n.scenario .== scid),
                    :,
                ]
                @test nrow(rows) == 1
                schedule_row = only(eachrow(rows))
                @test schedule_row.date == DateTime(source_row.year, 1, 1)
                @test schedule_row.value == source_row.n
            end
        end
    end
end
