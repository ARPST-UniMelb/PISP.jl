using PISP
using Test
using Dates

include(joinpath(@__DIR__, "..", "docs", "source_availability.jl"))
using .PISPDocsSourceAvailability

# The suite is partitioned into one file per topic. The source-availability checks
# run at top level (matching the original layout); the package-behaviour tests run
# under the "PISP.jl" test set.
include("test_source_availability.jl")

@testset "PISP.jl" begin
    include("test_zip_extraction.jl")
    include("test_report_downloader_2024.jl")
    include("test_report_downloader_2026.jl")
    include("test_source_downloader_2026.jl")
end
