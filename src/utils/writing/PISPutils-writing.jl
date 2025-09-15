alt_names = Dict(
        :gen => "Generator",
        :dem => "Demand",
        :ess => "ESS",
        :line => "Line",
        :bus => "Bus",
        :der => "DER",
        :dem_load => "Demand_load_sched",
        :ess_emax => "ESS_emax_sched",
        :ess_lmax => "ESS_lmax_sched",
        :ess_n => "ESS_n_sched",
        :ess_pmax => "ESS_pmax_sched",
        :gen_n => "Generator_n_sched",
        :gen_pmax => "Generator_pmax_sched",
        :line_tmax => "Line_tmax_sched",
        :line_tmin => "Line_tmin_sched",
        :der_pred => "DER_pred_sched",

    )

function PISPwritedataCSV(input::Union{PISPtimeStatic, PISPtimeVarying}, path::AbstractString)
    isdir(path) || mkpath(path)
    input_type = typeof(input)

    for name in fieldnames(input_type)
        df = getfield(input, name)
        if df isa DataFrame
            CSV.write(joinpath(path, "$(alt_names[name]).csv"), df)
        end
    end
end

function PISPwritedataArrow(input::Union{PISPtimeStatic, PISPtimeVarying}, path::AbstractString)
    isdir(path) || mkpath(path)
    input_type = typeof(input)

    for name in fieldnames(input_type)
        df = getfield(input, name)
        if df isa DataFrame
            Arrow.write(joinpath(path, "$(alt_names[name]).arrow"), df)
        end
    end
end