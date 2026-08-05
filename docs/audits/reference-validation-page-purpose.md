# Reference and validation page-purpose audit

This audit records the publication decision for every ISP 2024 and ISP 2026
reference or validation Literate page present before the human-facing
architecture refactor. It is a maintainer record and is not part of the
Documenter navigation.

The audit uses `docs/src/concepts.md` as the common authority for the
relationship among planning year, scenario, `reftrace`, `poe`, and ISP edition.
Each other page must add a runnable selection, a page-specific contract or
interpretation, or a verified edition-specific difference.

## Page-purpose matrix

| Page | Reader question | Sources checked | Page output | Depends on | Disposition | Destination |
|---|---|---|---|---|---|---|
| `isp2024-source-data` | What files, workbook selections, keys, fields, and units make up the ISP 2024 source data? | ISP 2024 source specifications, workbooks, model instructions, and outlook reports | Source tables grouped by workbook, outlook, model traces, and renewable trace collections | ISP 2024 source material | Major refactor and rename | Match the ISP 2026 source-data page in filename, title, headings, and table columns; move build-input and source-to-output material to the 2024 workflow pages |
| `isp2024-output-tables` | Dataset users asking what PISP writes and how static and schedule tables relate | PISP data structures, table aliases, static and schedule schemas | Table, field, unit, identifier, relationship, and reconstruction reference | Integrated ISP 2024 dataset writer | Keep | Retain as the edition-specific output contract |
| `isp2024-parameters-and-mappings` | Package users asking which source values, mappings, and defaults govern an ISP 2024 build | PISP parameter modules, package constants, source reports | Scenario, bus, area, weather-year, reliability, and ownership mappings | Integrated ISP 2024 parser and parameter modules | Keep | Retain as the edition-specific mapping authority |
| `isp2024-buildout-defaults` | Package users asking how workbook rows become generator and storage build-out records | Build-out workbook contract and runtime defaults | Applied template sources, defaults, overrides, and derivations | Integrated ISP 2024 build-out parser | Keep | Retain; no page-purpose defect found |
| `isp2024-hydro-parameters-and-constants` | Package users asking which hydro mappings and constants PISP consumes | Hydro parameter modules and cited ISP report context | Trace assignments, annual limits, hydrological years, and Snowy allocations | Integrated ISP 2024 hydro parameter path | Keep | Retain; no page-purpose defect found |
| `isp2024-source-data-inventory` | Maintainers inspecting files, sizes, extensions, and directory trees | Recursive filesystem walk | Full-file inventory, byte and extension counts, largest files, directory tree | Machine-specific source tree | Delete from publication | Remove source, generated page, registry entry, and navigation; no reader workflow consumes the dump |
| `isp2024-workbook-and-trace-structure` | How are the ISP 2024 workbooks, scenario models, and trace collections organised? | ISP 2024 source specifications, workbook selections, scenario directories, and trace patterns | Workbook structure, model-archive structure, and trace schema | ISP 2024 source material | Major refactor and rename | Match the ISP 2026 workbook-and-trace page in filename, title, headings, and table columns; move analytical trace plots and low-output metrics to analysis pages |
| `isp2024-temperature-data-coverage` | Modellers asking what temperature evidence is present and what PISP does not model | ISP 2024 inputs workbook and package source scan | Workbook assumptions, regional temperatures, interconnector capability, and package boundary | Integrated ISP 2024 source workbook | Keep | Retain; the limitation answers a modelling question rather than reporting checkout state |
| `isp2024-generated-output-consistency` | Dataset users asking whether generated static and schedule outputs satisfy PISP relationships | Canonical ISP 2024 generated tables and join checks | Identifier coverage, static-to-schedule relationships, renewable classifications, and aggregate profiles | Integrated ISP 2024 dataset build | Refactor narrowly | Keep; remove path bookkeeping and console-style narration while preserving validation evidence |
| `isp2026-source-data` | What files, workbook selections, keys, fields, and units make up the ISP 2026 source data? | ISP 2026 source map, workbooks, model instructions, and outlook reports | Source tables grouped by workbook, outlook, model traces, and renewable trace collections | ISP 2026 source material | Major refactor and rename | Match the ISP 2024 source-data page in filename, title, headings, and table columns; keep cross-edition differences in the comparison pages |
| `isp2026-workbook-and-trace-structure` | How are the ISP 2026 workbooks, scenario models, and trace collections organised? | Source map, workbook selections, scenario directories, and trace families | Workbook structure, model-archive structure, and trace schema | ISP 2026 source material | Major refactor and rename | Match the ISP 2024 workbook-and-trace page in filename, title, headings, and table columns; remove file counts and status summaries |

## Central-concept delta audit

| Source | Existing use | Delta decision |
|---|---|---|
| `docs/src/concepts.md` | Defines planning year, financial-year blocks, scenario, `reftrace`, `poe`, ISP edition, historical trace selection, composite `4006`, and demand POE | Canonical common authority. Preserve the maintainer-authored planning-year paragraph and extend only for a verified cross-cutting definition |
| `docs/src/quickstart.md` | Supplies runnable `poe`, `reftrace`, year, and scenario arguments | Keep. The values are executable choices, not a second conceptual definition |
| `docs/src/api.md` | Shows public API arguments for complete-year and date-range builds | Keep. The parameter use is required at the call site |
| `docs/src/assumptions.md` | Uses the selectors in a reproducibility checklist | Keep. The checklist states what must be recorded rather than redefining the selectors |
| `docs/src/editions/trace-coverage.md` | Compares trace families, schemas, reference-year labels, and POE definitions by edition | Keep edition-specific source meaning; link to `concepts.md` for the common selector relationships |
| `docs/literate/isp2024/tutorials/working_with_pisp_outputs.jl` | Resolves an existing output folder from `reftrace`, `poe`, and planning year | Keep. Folder selection is the tutorial's runnable task |
| `docs/literate/shared/tutorials/selecting_raw_isp_material.jl` | Resolves an ISP 2024 raw source from scenario, `reftrace`, and `poe` | Keep runnable source selection; replace generic planning-year explanation with a concise concepts link |
| `docs/literate/isp2024/validation/workbook_and_trace_structure.jl` | Selects `4006` and `POE10`, then repeats generic POE and reference-year explanations | Keep the exact file-selection evidence and page-specific trace interpretation; remove generic definitions already owned by `concepts.md` |
| `docs/literate/isp2026/validation/workbook_and_trace_structure.jl` | Previously reported file counts and repeated the 2026 POE explanation | Keep the POE explanation in `docs/src/editions/trace-coverage.md`; refactor this page around workbook, model, and trace structure |

### Site-wide mention classification

The source review also covered every grep-discovered use of `reftrace`,
reference-weather trace, `poe`, probability of exceedance, and planning year
under `docs/src/` and `docs/literate/`. The retained uses fall into these
classes:

| Class | Files | Decision |
|---|---|---|
| Common definitions | `docs/src/concepts.md` | Keep only here |
| Runnable API or selection mechanics | `docs/src/quickstart.md`; `docs/src/api.md`; `docs/literate/isp2024/tutorials/working_with_pisp_outputs.jl`; `docs/literate/shared/tutorials/selecting_raw_isp_material.jl` | Keep arguments, folder resolution, validation, and exact selection steps; link to the concepts page instead of repeating the common explanation |
| Reproducibility or overview context | `docs/src/index.md`; `docs/src/assumptions.md` | Keep the requirement to record selectors and the high-level workflow sequence; these passages do not redefine the selectors |
| Edition-specific report meaning | `docs/src/editions/trace-coverage.md` | Keep the report terminology and edition-specific trace structures; link to the concepts page for common selector relationships |
| Page-specific validation evidence | `docs/literate/isp2024/validation/workbook_and_trace_structure.jl`; `docs/literate/isp2024/validation/generated_output_consistency.jl`; `docs/literate/isp2024/validation/temperature_data_coverage.jl` | Keep selected filenames, output-folder identity, and the distinct POE10 reference-temperature rule because each is evidence interpreted on that page |
| Analysis-specific premises | `docs/literate/isp2024/analysis/demand_stress_low_solar.jl` | Keep the POE10 demand premise and source-file filter because they define the analysed dataset rather than the general concept |
| Edition overview links | `docs/src/editions/supported-editions.md`; `docs/src/editions/source-material.md`; `docs/src/editions/source-inventory.md`; `docs/src/editions/output-data-model.md` | Keep links to the source and dataset pages; no selector definition is present |
| Edition-specific source documentation | `docs/literate/isp2024/reference/source_data.jl`; `docs/literate/isp2026/reference/source_data.jl`; the paired workbook-and-trace pages | Use the same page names, headings, and table contracts for files, selections, keys, fields, units, workbook structure, model archives, and trace schemas; keep differences in the comparison track |

Code tokens embedded in filenames, regular expressions, environment-variable
names, or function arguments were treated as executable mechanics rather than
reader definitions. No retained non-central passage supplies a second generic
definition of the relationship among planning year, scenario, `reftrace`,
`poe`, and ISP edition.

## Verification boundary

The authoritative Literate sources and their committed generated Markdown were
read for this audit. Julia execution, Literate regeneration, and Documenter HTML
inspection were intentionally not performed for this source-only patch.
