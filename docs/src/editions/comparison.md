# Comparing ISP 2024 and ISP 2026

The [model archive comparison](../generated/comparison/analyses/model-archive-comparison.md)
is the starting point for mapping the ISP 2024 data workflow to ISP 2026.
It reads the two AEMO model ZIPs and compares their scenario directories, XML
files, trace families, file counts, sizes, and representative filenames.

The comparison also applies AEMO's published scenario lineage from the 2025
Inputs, Assumptions and Scenarios Report. It shows where a parser can preserve
an explicit crosswalk and where the two editions require different discovery
or filename rules.

The model ZIPs are only one part of each release. Wind, solar, and timeslice
traces are published separately, while CSV schemas, units, time coverage, and
model-XML references require their own comparisons before data from the two
editions can be treated as equivalent.

The [supported editions](supported-editions.md) page describes current package
coverage. The [source material](source-material.md), [trace coverage](trace-coverage.md),
and [parameters and mappings](parameters-and-mappings.md) pages provide the
release-specific context needed for later parser and data-model work.
