# # ISP 2024 and ISP 2026: Source availability by edition
#
# The comparison records acquisition and extraction structures observed in the
# configured ISP 2024 and ISP 2026 roots. Similar filenames, folders, or
# scenario labels require an explicit crosswalk before they are treated as
# equivalent.

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..", "..")))
include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
include(joinpath(REPO_ROOT, "docs", "source_availability.jl"))
using .PISPDocsEditionProfiles
using .PISPDocsSourceAvailability: inspect_edition, source_availability_summary

function source_profile(profile)
    PISPDocsSourceAvailability.EditionProfile(
        edition = profile.edition,
        report_root = profile.report_root,
        download_root = profile.download_root,
        report_root_source = :profile,
        download_root_source = :profile,
    )
end

profiles = edition_profiles(REPO_ROOT)
availability_records = [inspect_edition(source_profile(profile)) for profile in profiles]
nothing #hide

# ## What is being compared
#
# The 2024 PLEXOS Model Instructions describe a package containing one model
# for each of Step Change, Progressive Change, and Green Energy Exports, plus
# demand, renewable-generation, timeslice, and load-subtractor traces. They
# describe six trace folders and 14 historical weather years (physical p. 5
# and p. 7).
#
# The 2026 PLEXOS Model Instructions describe Step Change, Slower Growth, and
# Accelerated Transition, plus a larger trace-folder set that includes demand,
# DNSP, gas, hydro, load subtractor, rooftop PV, solar, timeslice, and wind.
# They describe 16 historical weather years (physical p. 5 and p. 7).
#
# These release descriptions come from the AEMO reports. Scenario labels and
# counts remain edition-specific.

for record in availability_records
    println("ISP ", record.edition, " source state: ", record.state)
    println("  reports observed: ", count(o -> o.observed && o.requirement.class == :report, record.observations), "/10")
    println("  download requirements observed: ", count(o -> o.observed && o.requirement.class == :download, record.observations), "/", count(o -> o.requirement.class == :download, record.observations))
    summary = source_availability_summary(source_profile(only(filter(p -> p.edition == record.edition, profiles))))
    println("  trace archives: ", length(summary.trace_archive_files), "; demand groups: ", length(summary.demand_group_paths), "; demand traces: ", summary.demand_trace_files)
    println("  local PoE labels: ", isempty(summary.poe_labels) ? "none" : join(summary.poe_labels, ", "))
end

# ## PoE and demand traces
#
# The 2023 Inputs, Assumptions and Scenarios Report defines POE as “probability
# of exceedance” (physical p. 172). The 2023 ISP Methodology discusses 10%,
# 50%, and sometimes 90% POE simulations and says that 10% POE demand profiles
# are used for capacity-outlook modelling to meet high peak demand (physical
# p. 39). In the configured 2024 downloads, the locally observed demand
# filename labels include `POE10` and `POE50`; those labels are local filenames,
# while the report-backed definition and use are separate evidence.
#
# No 2026 PoE filename meaning is inferred from the 2024 labels. A relationship
# between the two editions' demand traces requires a release-specific crosswalk
# covering labels, time axis, units, coverage, and missing-data treatment.

# ## Boundary
#
# Snapshot scope: counts describe the configured local roots. They do not imply
# parser coverage, upstream completeness, or cross-edition equivalence.
