using PISP

base_path = normpath(@__DIR__, "../../")
reference_trace = 2011  # Use 4006 for the reference trace of the ODP
poe = 10    # Probability of exceedance (POE) for demand
target_years = [2030, 2040, 2050]

PISP.build_ISP24_datasets(
    downloadpath=joinpath(base_path, "pisp-downloads"),
    poe=poe,
    reftrace=reference_trace,
    years=target_years,
    output_root=joinpath(base_path, "pisp-datasets"),
    write_csv=true,
    write_arrow=false,
    scenarios=[2])