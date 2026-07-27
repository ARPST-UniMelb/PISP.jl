```@meta
EditURL = "../../../../literate/comparison/validation/source_availability_by_edition.jl"
```

# ISP 2024 and ISP 2026: what's actually on disk

This page counts the report PDFs and downloaded source files present in the
local `pisp-reports` and `pisp-downloads` folders for each edition. It's a
snapshot of one machine's local data, not an AEMO-published total — use it
to sanity-check a local setup, not to draw conclusions about the upstream
releases.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
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
````

```@raw html
</details>
```

## What each release's PLEXOS package contains

Per the AEMO PLEXOS Model Instructions (physical p. 5 and p. 7):

- **ISP 2024** — three scenarios (Step Change, Progressive Change, Green
  Energy Exports), six trace folders (demand, hydro, load subtractor,
  solar, timeslice, wind), 14 historical weather years.
- **ISP 2026** — three scenarios (Step Change, Slower Growth, Accelerated
  Transition), nine trace folders (adds DNSP, gas, and rooftop PV to the
  2024 set), 16 historical weather years.

Same shape, different numbers — don't assume a 2024 scenario or trace label
means the same thing in 2026 without checking the report definitions.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
for record in availability_records
    println("ISP ", record.edition, " source state: ", record.state)
    println("  reports found: ", count(o -> o.observed && o.requirement.class == :report, record.observations), "/10")
    println("  download requirements found: ", count(o -> o.observed && o.requirement.class == :download, record.observations), "/", count(o -> o.requirement.class == :download, record.observations))
    summary = source_availability_summary(source_profile(only(filter(p -> p.edition == record.edition, profiles))))
    println("  trace archives: ", length(summary.trace_archive_files), "; demand groups: ", length(summary.demand_group_paths), "; demand traces: ", summary.demand_trace_files)
    println("  local PoE labels: ", isempty(summary.poe_labels) ? "none" : join(summary.poe_labels, ", "))
end
````

```@raw html
</details>
```

````
ISP 2024 source state: complete
  reports found: 10/10
  download requirements found: 7/7
  trace archives: 62; demand groups: 39; demand traces: 2988
  local PoE labels: POE10, POE50
ISP 2026 source state: complete
  reports found: 10/10
  download requirements found: 8/8
  trace archives: 2; demand groups: 3; demand traces: 45
  local PoE labels: POE10

````

## Probability of exceedance (PoE) demand labels

AEMO's Inputs, Assumptions and Scenarios Report defines POE as "probability
of exceedance" (physical p. 172), and the ISP Methodology says 10% POE
demand profiles are used in capacity-outlook modelling for high peak demand
(physical p. 39). The local 2024 downloads use `POE10` and `POE50` in their
filenames, matching that terminology.

The 2026 downloads carry their own `POE10` filename label, but that doesn't
by itself mean the 2026 file covers the same years, region, or method as
the 2024 one — check both files' documentation before treating them as
interchangeable.

## Scope of these counts

These numbers describe the two folders configured on the machine that
rendered this page. They don't say anything about AEMO's published totals,
PISP.jl's parser coverage, or whether 2024 and 2026 files with the same
name hold equivalent data.

