# # ISP 2026: Source availability and release structure
#
# This page describes source material observed in the configured ISP 2026 report
# and download roots. It does not establish parser, dataset, or cross-edition
# support.

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..", "..")))
include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
include(joinpath(REPO_ROOT, "docs", "source_availability.jl"))
using .PISPDocsEditionProfiles
using .PISPDocsSourceAvailability: inspect_edition, source_availability_summary

profile = edition_profile(REPO_ROOT, "2026")
source_profile = PISPDocsSourceAvailability.EditionProfile(
    edition = profile.edition,
    report_root = profile.report_root,
    download_root = profile.download_root,
    report_root_source = :profile,
    download_root_source = :profile,
)
inspection = inspect_edition(source_profile)
nothing #hide

# ## What a trace means here
#
# In the 2026 PLEXOS Model Instructions, a trace is a source time series used
# by the detailed long-term model. The report says that the published model
# contains demand, renewable-generation, gas-availability, DNSP-level CER,
# seasonal-timeslice, and load-subtractor traces. It lists demand, DNSP, gas,
# hydro, load subtractor, rooftop PV, solar, timeslice, and wind folders under
# `Traces`; the report describes the roles of those folders in the model package
# (2026 ISP PLEXOS Model Instructions, physical p. 5 and p. 7).
#
# The report also states that the traces combine 16 historical weather years in
# a repeating rolling-reference-year sequence (physical p. 5). That report
# description is not a claim that every local archive or extracted folder is
# complete.

# ## Report and archive observations
#
# `report-backed` statements above describe the report's release structure.
# `package-code-derived` requirements below follow PISP's configured report
# targets and source-download layout. `local-observed` statements are limited to
# the roots supplied to this render.

println("Edition: ISP 2026")
println("Availability state in configured roots: ", inspection.state)
println("Reports observed: ", count(o -> o.observed && o.requirement.class == :report, inspection.observations), "/10 configured report targets")
summary = source_availability_summary(source_profile)
println("Trace archive files observed under zip/Traces: ", join(summary.trace_archive_files, ", "))
println("Trace directories observed: ", join(summary.trace_directories, ", "))
println("Demand groups observed: ", join(summary.demand_group_paths, ", "))
println("Demand CSV traces observed: ", summary.demand_trace_files)
println("PoE labels observed in local filenames: ", isempty(summary.poe_labels) ? "none" : join(summary.poe_labels, ", "))

# The local observation above identifies files and folders in one checkout. It
# does not establish upstream completeness, a 2026 PISP trace schema, a PoE
# contract, or equivalence with ISP 2024.

# ## Probability of exceedance (PoE)
#
# The 2025 Inputs, Assumptions and Scenarios Report defines POE as “probability
# of exceedance” in its abbreviations (physical p. 234). The 2025 ISP
# Methodology describes 10%, 50%, and sometimes 90% POE simulations for
# reliability assessments, and says that 10% POE demand profiles are used in
# capacity-outlook modelling to represent high peak demand (physical p. 40).
# Those passages support the report's terminology and use of 10% profiles; they
# do not establish the meaning of any local 2026 filename label. The configured
# local roots contain a `POE10` filename label, but no 2026 semantic meaning is
# inferred from that name.
