mutable struct ParseISPtimeConfig
    problem::DataFrame

    # Default constructor
    function ParseISPtimeConfig()
        problem    = ParseISP.schema_to_dataframe(ParseISP.MOD_PROBLEM)
        new(problem)
    end
end

mutable struct ParseISPtimeStatic
    bus::DataFrame
    dem::DataFrame
    ess::DataFrame
    gen::DataFrame
    line::DataFrame
    der::DataFrame

    # Default constructor
    function ParseISPtimeStatic()
        bus    = ParseISP.schema_to_dataframe(ParseISP.MOD_BUS)
        dem    = ParseISP.schema_to_dataframe(ParseISP.MOD_DEMAND)
        ess    = ParseISP.schema_to_dataframe(ParseISP.MOD_ESS)
        gen    = ParseISP.schema_to_dataframe(ParseISP.MOD_GEN)
        line   = ParseISP.schema_to_dataframe(ParseISP.MOD_LINE)
        der    = ParseISP.schema_to_dataframe(ParseISP.MOD_DER)
        new(bus, dem, ess, gen, line, der)
    end
end

mutable struct ParseISPtimeVarying
    dem_load::DataFrame
    ess_emax::DataFrame
    ess_lmax::DataFrame
    ess_n::DataFrame
    ess_pmax::DataFrame
    ess_inflow::DataFrame
    gen_n::DataFrame
    gen_pmax::DataFrame
    gen_inflow::DataFrame
    line_fwcap::DataFrame
    line_rvcap::DataFrame
    der_pred::DataFrame

    # Default constructor
    function ParseISPtimeVarying()
        dem_load   = ParseISP.schema_to_dataframe(ParseISP.MOD_DEMAND_LOAD)
        ess_emax   = ParseISP.schema_to_dataframe(ParseISP.MOD_ESS_EMAX)
        ess_lmax   = ParseISP.schema_to_dataframe(ParseISP.MOD_ESS_LMAX)
        ess_n      = ParseISP.schema_to_dataframe(ParseISP.MOD_ESS_N)
        ess_pmax   = ParseISP.schema_to_dataframe(ParseISP.MOD_ESS_PMAX)
        ess_inflow = ParseISP.schema_to_dataframe(ParseISP.MOD_ESS_INFLOW)
        gen_n      = ParseISP.schema_to_dataframe(ParseISP.MOD_GEN_N)
        gen_pmax   = ParseISP.schema_to_dataframe(ParseISP.MOD_GEN_PMAX)
        gen_inflow = ParseISP.schema_to_dataframe(ParseISP.MOD_GEN_INFLOW)
        line_fwcap = ParseISP.schema_to_dataframe(ParseISP.MOD_LINE_FWCAP)
        line_rvcap = ParseISP.schema_to_dataframe(ParseISP.MOD_LINE_RVCAP)
        der_pred   = ParseISP.schema_to_dataframe(ParseISP.MOD_DER_PRED_MAX)

        new(dem_load, ess_emax, ess_lmax, ess_n, ess_pmax, ess_inflow,
            gen_n, gen_pmax, gen_inflow, line_fwcap, line_rvcap, der_pred)
    end
end