"""
    read_buildout_table(filepath; sheetname) → (static_data, tvarying_data)

Parse a buildout schedule workbook sheet and return two DataFrames:
- `static_data`:   columns (name, subregion, tech, capacity) — one row per unique name
- `tvarying_data`: columns (name, subregion, year, n)         — one row per (name, year)

`name` is `uppercase(tech * "_" * subregion) * "_NEW"`.
"""
function read_buildout_table(filepath::AbstractString; sheetname::AbstractString="buildout_1")
    raw = XLSX.openxlsx(filepath) do xf
        data = XLSX.getdata(xf[sheetname])
        DataFrame(data[2:end, :], Symbol.(vec(data[1, :])))
    end

    raw.tech      = String.(raw.tech)
    raw.subregion = String.(raw.subregion)
    raw.year      = Int64.(raw.year)
    raw.capacity  = Float64.(raw.capacity)
    raw.n         = Int64.(raw.n)
    raw.name      = uppercase.(raw.tech .* "_" .* raw.subregion) .* "_NEW"

    static_data   = unique(select(raw, :name, :subregion, :tech, :capacity))
    tvarying_data = select(raw, :name, :subregion, :year, :n)

    return static_data, tvarying_data
end

# Internal tech-set constants
const _BUILDOUT_ESS_TECHS    = Set(["bess_1h", "bess_2h", "bess_4h", "bess_8h",
                                    "phsp_24h", "phsp_48h"])
const _BUILDOUT_GEN_TECHS    = Set(["ccgt", "ocgt_l", "ocgt_s"])
const _BUILDOUT_GEN_TECH_KEY = Dict("ccgt" => :ccgt, "ocgt_l" => :ocgt_large, "ocgt_s" => :ocgt_small)
const _BESS_DURATION_H       = Dict("bess_1h"  => 1.0,  "bess_2h"  => 2.0,
                                    "bess_4h"  => 4.0,  "bess_8h"  => 8.0,
                                    "phsp_24h" => 24.0, "phsp_48h" => 48.0)

"""
    add_buildout_ess!(ts, tv, static_data, tvarying_data)

Append new ESS buildout entries to `ts.ess` and unit-count schedule entries to
`tv.ess_n`, using engineering parameters from `PISP.params_buildout_bess`.

One row per unique name in `static_data` (filtered to BESS techs) is added to
`ts.ess`; IDs start from `max(ts.ess.id_ess) + 1`. For each (name, year) row in
`tvarying_data`, one entry per ISP scenario is added to `tv.ess_n` dated
`01-01-YYYY 00:00:00`.
"""
function add_buildout_ess!(ts::PISPtimeStatic, tv::PISPtimeVarying,
                           static_data::DataFrame, tvarying_data::DataFrame)
    bust   = ts.bus
    ess_id = isempty(ts.ess.id_ess) ? 0 : maximum(ts.ess.id_ess)
    n_id   = isempty(tv.ess_n.id)   ? 0 : maximum(tv.ess_n.id)

    sd = filter(r -> r.tech ∈ _BUILDOUT_ESS_TECHS, static_data)
    name_to_id = Dict{String, Int64}()

    for row in eachrow(sd)
        ess_id += 1
        name_to_id[row.name] = ess_id
        p      = PISP.params_buildout_bess[Symbol(row.tech)]
        bus_id = bust[bust.name .== row.subregion, :id_bus][1]
        # Column order matches MOD_ESS: id_ess, name, alias, tech, type, capacity,
        # investment, active, id_bus, ch_eff, dch_eff, eini, emin, emax,
        # pmin, pmax, lmin, lmax, fullout, partialout, mttrfull, mttrpart,
        # inertia, powerfactor, ffr, pfr, res2, res3,
        # fr_db, fr_ad, fr_dt, fr_frt, fr_fr, longitude, latitude, n, contingency
        push!(ts.ess, [ess_id, row.name, row.name,
                       p["tech"], p["type"], row.capacity,
                       p["investment"], p["active"], bus_id,
                       p["ch_eff"], p["dch_eff"], p["eini"], p["emin"], _BESS_DURATION_H[row.tech] * row.capacity,
                       p["pmin"], row.capacity, p["lmin"], row.capacity,
                       p["fullout"], p["partialout"], p["mttrfull"], p["mttrpart"],
                       p["inertia"], p["powerfactor"],
                       p["ffr"], p["pfr"], p["res2"], p["res3"],
                       p["fr_db"], p["fr_ad"], p["fr_dt"], p["fr_frt"], p["fr_fr"],
                       0.0, 0.0,
                       p["n"], p["contingency"]])
    end

    tvd = filter(r -> r.name ∈ keys(name_to_id), tvarying_data)
    for row in eachrow(tvd)
        id_ess = name_to_id[row.name]
        for scid in keys(PISP.ID2SCE)
            n_id += 1
            push!(tv.ess_n, [n_id, id_ess, scid, DateTime(row.year, 1, 1, 0, 0, 0), row.n])
        end
    end
end

"""
    add_buildout_gen!(ts, tv, static_data, tvarying_data)

Append new generator buildout entries to `ts.gen` and unit-count schedule entries
to `tv.gen_n`, using engineering parameters from `PISP.params_buildout_gen`.

Supported techs: `ccgt`, `ocgt_l`, `ocgt_s`. IDs start from
`max(ts.gen.id_gen) + 1`. One entry per ISP scenario per (name, year) row is
added to `tv.gen_n` dated `01-01-YYYY 00:00:00`.
"""
function add_buildout_gen!(ts::PISPtimeStatic, tv::PISPtimeVarying,
                           static_data::DataFrame, tvarying_data::DataFrame)
    bust   = ts.bus
    gen_id = isempty(ts.gen.id_gen) ? 0 : maximum(ts.gen.id_gen)
    n_id   = isempty(tv.gen_n.id)   ? 0 : maximum(tv.gen_n.id)

    sd = filter(r -> r.tech ∈ _BUILDOUT_GEN_TECHS, static_data)
    name_to_id = Dict{String, Int64}()

    for row in eachrow(sd)
        gen_id += 1
        name_to_id[row.name] = gen_id
        p      = PISP.params_buildout_gen[_BUILDOUT_GEN_TECH_KEY[row.tech]]
        bus_id = bust[bust.name .== row.subregion, :id_bus][1]
        # Column order matches MOD_GEN: id_gen, name, alias, fuel, tech, type, capacity,
        # forate, fullout, partialout, derate, mttrfull, mttrpart, id_bus,
        # pmin, pmax, rup, rdw, investment, active,
        # cvar, cfuel, cvom, cfom, co2, slope, hrate, pfrmax, g, inertia,
        # ffr, pfr, res2, res3, powerfactor, latitude, longitude,
        # n, contingency, down_time, up_time, last_state, last_state_period,
        # last_state_output, start_up_cost, shut_down_cost, start_up_time, shut_down_time
        push!(ts.gen, [gen_id, row.name, row.name,
                       p["fuel"], p["tech"], p["type"], row.capacity,
                       p["forate"], p["fullout"], p["partialout"], p["derate"],
                       p["mttrfull"], p["mttrpart"], bus_id,
                       p["pmin"], row.capacity, p["rup"], p["rdw"],
                       p["investment"], p["active"],
                       p["cvar"], p["cfuel"], p["cvom"], p["cfom"], p["co2"],
                       p["slope"], p["hrate"], p["pfrmax"], p["g"], p["inertia"],
                       p["ffr"], p["pfr"], p["res2"], p["res3"], p["powerfactor"],
                       0.0, 0.0,
                       p["n"], p["contingency"],
                       p["down_time"], p["up_time"], p["last_state"],
                       p["last_state_period"], p["last_state_output"],
                       p["start_up_cost"], p["shut_down_cost"],
                       p["start_up_time"], p["shut_down_time"]])
    end

    tvd = filter(r -> r.name ∈ keys(name_to_id), tvarying_data)
    for row in eachrow(tvd)
        id_gen = name_to_id[row.name]
        for scid in keys(PISP.ID2SCE)
            n_id += 1
            push!(tv.gen_n, [n_id, id_gen, scid, DateTime(row.year, 1, 1, 0, 0, 0), row.n])
        end
    end
end

"""
    add_buildouts!(ts, tv, filepath; sc_buildouts, sheetname)

Apply all buildout entries (ESS and generators) to `ts` and `tv` from `filepath`.

When `sc_buildouts` is empty (default), reads `sheetname` (default `"buildout_1"`)
and applies the same buildout to all scenarios. When `sc_buildouts` is provided it
must map every scenario ID (1, 2, 3) to a sheet name; each scenario then receives
its own time-varying buildout schedule while static asset entries are unioned across
all sheets (first-occurrence wins for capacity/tech parameters).
"""
function add_buildouts!(ts::PISPtimeStatic, tv::PISPtimeVarying,
                        filepath::AbstractString;
                        sc_buildouts::Dict{Int,String} = Dict{Int,String}(),
                        sheetname::Union{AbstractString,Nothing} = nothing)
    if sheetname === nothing && isempty(sc_buildouts)
        error("Either sheetname or sc_buildouts must be provided.")
    elseif sheetname !== nothing && !isempty(sc_buildouts)
        error("Cannot provide both sheetname and sc_buildouts.")
    end
    if isempty(sc_buildouts)
        static_data, tvarying_data = read_buildout_table(filepath; sheetname=sheetname)
        add_buildout_ess!(ts, tv, static_data, tvarying_data)
        add_buildout_gen!(ts, tv, static_data, tvarying_data)
    else
        for k in keys(PISP.ID2SCE)
            haskey(sc_buildouts, k) ||
                error("sc_buildouts must include a key for every scenario. Missing: $k")
        end
        sc_data = Dict(scid => read_buildout_table(filepath; sheetname=shname)
                       for (scid, shname) in sc_buildouts)
        _add_buildout_ess_sc!(ts, tv, sc_data)
        _add_buildout_gen_sc!(ts, tv, sc_data)
    end
end

# Internal: scenario-specific ESS buildout
function _add_buildout_ess_sc!(ts::PISPtimeStatic, tv::PISPtimeVarying,
                                sc_data::Dict{Int,<:Tuple{DataFrame,DataFrame}})
    bust   = ts.bus
    ess_id = isempty(ts.ess.id_ess) ? 0 : maximum(ts.ess.id_ess)
    n_id   = isempty(tv.ess_n.id)   ? 0 : maximum(tv.ess_n.id)

    seen       = Set{String}()
    name_to_id = Dict{String,Int64}()

    for (_, (sd, _)) in sc_data
        for row in eachrow(filter(r -> r.tech ∈ _BUILDOUT_ESS_TECHS, sd))
            row.name ∈ seen && continue
            push!(seen, row.name)
            ess_id += 1
            name_to_id[row.name] = ess_id
            p      = PISP.params_buildout_bess[Symbol(row.tech)]
            bus_id = bust[bust.name .== row.subregion, :id_bus][1]
            push!(ts.ess, [ess_id, row.name, row.name,
                           p["tech"], p["type"], row.capacity,
                           p["investment"], p["active"], bus_id,
                           p["ch_eff"], p["dch_eff"], p["eini"], p["emin"],
                           _BESS_DURATION_H[row.tech] * row.capacity,
                           p["pmin"], row.capacity, p["lmin"], row.capacity,
                           p["fullout"], p["partialout"], p["mttrfull"], p["mttrpart"],
                           p["inertia"], p["powerfactor"],
                           p["ffr"], p["pfr"], p["res2"], p["res3"],
                           p["fr_db"], p["fr_ad"], p["fr_dt"], p["fr_frt"], p["fr_fr"],
                           0.0, 0.0,
                           p["n"], p["contingency"]])
        end
    end

    for (scid, (_, tvd)) in sc_data
        for row in eachrow(filter(r -> r.name ∈ keys(name_to_id), tvd))
            n_id += 1
            push!(tv.ess_n, [n_id, name_to_id[row.name], scid,
                             DateTime(row.year, 1, 1, 0, 0, 0), row.n])
        end
    end
end

# Internal: scenario-specific generator buildout
function _add_buildout_gen_sc!(ts::PISPtimeStatic, tv::PISPtimeVarying,
                                sc_data::Dict{Int,<:Tuple{DataFrame,DataFrame}})
    bust   = ts.bus
    gen_id = isempty(ts.gen.id_gen) ? 0 : maximum(ts.gen.id_gen)
    n_id   = isempty(tv.gen_n.id)   ? 0 : maximum(tv.gen_n.id)

    seen       = Set{String}()
    name_to_id = Dict{String,Int64}()

    for (_, (sd, _)) in sc_data
        for row in eachrow(filter(r -> r.tech ∈ _BUILDOUT_GEN_TECHS, sd))
            row.name ∈ seen && continue
            push!(seen, row.name)
            gen_id += 1
            name_to_id[row.name] = gen_id
            p      = PISP.params_buildout_gen[_BUILDOUT_GEN_TECH_KEY[row.tech]]
            bus_id = bust[bust.name .== row.subregion, :id_bus][1]
            push!(ts.gen, [gen_id, row.name, row.name,
                           p["fuel"], p["tech"], p["type"], row.capacity,
                           p["forate"], p["fullout"], p["partialout"], p["derate"],
                           p["mttrfull"], p["mttrpart"], bus_id,
                           p["pmin"], row.capacity, p["rup"], p["rdw"],
                           p["investment"], p["active"],
                           p["cvar"], p["cfuel"], p["cvom"], p["cfom"], p["co2"],
                           p["slope"], p["hrate"], p["pfrmax"], p["g"], p["inertia"],
                           p["ffr"], p["pfr"], p["res2"], p["res3"], p["powerfactor"],
                           0.0, 0.0,
                           p["n"], p["contingency"],
                           p["down_time"], p["up_time"], p["last_state"],
                           p["last_state_period"], p["last_state_output"],
                           p["start_up_cost"], p["shut_down_cost"],
                           p["start_up_time"], p["shut_down_time"]])
        end
    end

    for (scid, (_, tvd)) in sc_data
        for row in eachrow(filter(r -> r.name ∈ keys(name_to_id), tvd))
            n_id += 1
            push!(tv.gen_n, [n_id, name_to_id[row.name], scid,
                             DateTime(row.year, 1, 1, 0, 0, 0), row.n])
        end
    end
end
