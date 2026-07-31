# Comparing ISP 2024 and ISP 2026

Two executable comparisons cover distinct source layers.

The [raw-source comparison](../generated/comparison/analyses/raw-source-comparison.md) compares the non-trace inputs and assumptions workbooks, EV workbooks, and generation-and-storage outlook packages.
It distinguishes worksheet additions and removals, source-family relocations, declared dimensions, and schema changes.
The detailed evidence remains on the corresponding [source-material subject pages](source-material.md).

The [model archive comparison](../generated/comparison/analyses/model-archive-comparison.md) reads the two AEMO model ZIPs and compares scenario directories, XML files, trace families, file counts, sizes, and representative filenames.
It also applies AEMO's published scenario lineage: Step Change refines the 2023 scenario with the same name ([2025 IASR, p. 18](../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=18)), Slower Growth succeeds Progressive Change ([p. 19](../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=19)), and Accelerated Transition refines Green Energy Exports ([p. 20](../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=20)).
The comparison shows where an explicit crosswalk is supportable and where the editions require different discovery or filename rules.

These comparisons do not establish generated-output compatibility.
Wind, solar, and timeslice traces are published separately, while units, keys, time coverage, model-XML references, package mappings, and generated CSV schemas require release-specific validation before data from the two editions can be treated as equivalent.

The [supported editions](supported-editions.md) page describes current package coverage.
The [source material](source-material.md), [trace coverage](trace-coverage.md), and [parameters and mappings](parameters-and-mappings.md) pages provide the release-specific context needed for parser and data-model work.
