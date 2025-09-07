mutable struct PISPtimeConfig
    problem::DataFrame

    # Default constructor
    function PISPtimeConfig()
        problem    = PISP.schema_to_dataframe(PISP.MOD_PROBLEM)
        new(problem)
    end
end

mutable struct PISPtimeStatic
    bus::DataFrame
    dem::DataFrame
    ess::DataFrame
    gen::DataFrame
    line::DataFrame

    # Default constructor
    function PISPtimeStatic()
        bus    = PISP.schema_to_dataframe(PISP.MOD_BUS)
        dem    = PISP.schema_to_dataframe(PISP.MOD_DEMAND)
        ess    = PISP.schema_to_dataframe(PISP.MOD_ESS)
        gen    = PISP.schema_to_dataframe(PISP.MOD_GEN)
        line   = PISP.schema_to_dataframe(PISP.MOD_LINE)
        new(bus, dem, ess, gen, line)
    end
end

mutable struct PISPtimeVarying
    dem_load::DataFrame
    ess_emax::DataFrame
    ess_lmax::DataFrame
    ess_n::DataFrame
    ess_pmax::DataFrame
    gen_n::DataFrame
    gen_pmax::DataFrame
    line_tmax::DataFrame
    line_tmin::DataFrame

    # Default constructor
    function PISPtimeVarying()
        dem_load  = PISP.schema_to_dataframe(PISP.MOD_DEMAND_LOAD)
        ess_emax  = PISP.schema_to_dataframe(PISP.MOD_ESS_EMAX)
        ess_lmax  = PISP.schema_to_dataframe(PISP.MOD_ESS_LMAX)
        ess_n     = PISP.schema_to_dataframe(PISP.MOD_ESS_N)
        ess_pmax  = PISP.schema_to_dataframe(PISP.MOD_ESS_PMAX)
        gen_n     = PISP.schema_to_dataframe(PISP.MOD_GEN_N)
        gen_pmax  = PISP.schema_to_dataframe(PISP.MOD_GEN_PMAX)
        line_tmax = PISP.schema_to_dataframe(PISP.MOD_LINE_TMAX)
        line_tmin = PISP.schema_to_dataframe(PISP.MOD_LINE_TMIN)

        new(dem_load, ess_emax, ess_lmax, ess_n, ess_pmax,
            gen_n, gen_pmax, line_tmax, line_tmin)
    end
end