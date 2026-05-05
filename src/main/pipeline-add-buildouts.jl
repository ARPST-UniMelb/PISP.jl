using PISP

downloadpath       = normpath(@__DIR__, "..", "data", "PISP-downloads"), # Path where all files from AEMO's website will be downloaded and extracted
download_from_AEMO = false
poe                = 10
reftrace           = 4006
output_root        = normpath(@__DIR__, "..", "data", "PISP-outputs-buildouts")
write_csv          = true
write_arrow        = false
scenarios          = [1, 2, 3]
buildout_filepath  = normpath(joinpath(@__DIR__, "..", "data", "PISP-buildouts", "buildouts.xlsx"))
sc_buildouts       = Dict(1 => "buildout_1", 2 => "buildout_2", 3 => "buildout_3")


PISP.build_ISP24_datasets(
    downloadpath       = downloadpath,
    download_from_AEMO = download_from_AEMO,
    poe                = poe,
    reftrace           = reftrace,
    years              = [2025, 2030],
    output_name        = "out-buildout",
    output_root        = output_root,
    write_csv          = write_csv,
    write_arrow        = write_arrow,
    scenarios          = scenarios,
    write_traces       = false,
    buildout_filepath  = buildout_filepath,
    sc_buildouts       = sc_buildouts,
)