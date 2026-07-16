# PISP documentation maintenance

PISP documentation uses two source types:

- stable explanatory pages under `docs/src/` for package purpose, concepts, assumptions, and API reference;
- executable Literate.jl pages under `docs/literate/` for package-derived reference tables, tutorials, data validation, and analyses.

`docs/page-registry.toml` is the authority for every executable page. It records the stable page ID, reader-facing title, page role, data lineage, Literate source, generated Markdown destination, navigation order, evidence producer, evidence directory, and direct local-data requirements.

## Documentation surfaces

| Surface | Responsibility |
|---|---|
| `docs/src/index.md` | Package purpose, dataset workflow, and entry points. |
| `docs/src/concepts.md` | Stable explanation of asset relationships, scenarios, traces, and the static/schedule model. |
| `docs/src/assumptions.md` | Modelling scope, caveats, validation responsibilities, and external checks. |
| `docs/src/api.md` | Public API reference. |
| `docs/literate/reference/` | Executable reference pages generated from package constants, schemas, downloader targets, and filesystem checks. |
| `docs/literate/tutorials/` | Executable package and dataset workflows. |
| `docs/literate/validation/` | Executable validation pages. |
| `docs/literate/eda/` | Executable analysis and validation pages that load their own source data, compute their own evidence, and build their own figures directly on the page — the page itself is the analysis, not a consumer of a separate producer script. |
| `docs/literate/eda_09_download_inventory.jl`, `docs/literate/eda_11_rez_resource_vs_cost.jl` | Two remaining pages that still follow the older producer-consumer model: a registered `eda/*.jl` producer writes evidence tables that the page then reads and displays. |
| `docs/src/generated/` | Static Markdown and figures generated from all active Literate sources. |
| `eda/eda_support.jl` | Shared table/figure-writer helper used by every page under `docs/literate/eda/`. |
| `eda/09_download_inventory.jl`, `eda/11_rez_resource_vs_cost.jl` | The two remaining standalone producer scripts, for the two pages listed above. |
| `eda/compare_tables.jl` | Regression harness comparing Julia-produced evidence tables against the archived Python baseline under `eda/archive/`. |
| `eda/tables/julia/<script-stem>/` | Current EDA evidence location. |

The public navigation follows reader purpose: reference, tutorial, validation, or analysis. Not every page in `docs/page-registry.toml` sets a `producer`/`evidence_dir` — only the two pages named above do; every other executable page computes its own evidence at render time.

## Complete local build

From the repository root, run:

```sh
julia --project=docs docs/build_all.jl
```

The complete build performs these lifecycle stages in order:

1. run each unique `eda/*.jl` producer registered by an active page (only `source-data-inventory` and `rez-resource-versus-connection-cost` currently register one — every other page computes its own evidence when its Literate source executes);
2. execute every active Literate source and regenerate its static Markdown and figures;
3. build the Documenter site from the generated files.

The build stops on the first failed producer, Literate page, registry check, or Documenter build. A failed complete render does not replace an existing `docs/src/generated/` tree.

Set `PISP_DATA_ROOT` when the source-data reference page should inspect a download root other than `data/2024/pisp-downloads/`.

Open `docs/build/index.html` after the build completes.

## Run stages separately

Render one page (and rerun its registered producer, if it has one):

```sh
PISP_LITERATE_PAGES=historical-trace-years julia --project=docs docs/render_literate.jl
```

Render every active Literate page and rerun every registered producer (`source-data-inventory` and `rez-resource-versus-connection-cost` are the only two that currently have one):

```sh
julia --project=docs docs/render_literate.jl
```

Skip rerunning registered producers, reusing their existing evidence only when it is known to match the current Literate sources (has no effect on pages that compute their own evidence, since those have no producer to skip):

```sh
PISP_RUN_PRODUCERS=false julia --project=docs docs/render_literate.jl
```

Build Documenter from the committed generated files:

```sh
julia --project=docs docs/make.jl
```

`docs/render_literate.jl` defaults to every non-archived registry entry and reruns the unique producers required by the selected pages. A complete render writes all pages to a temporary staging tree and replaces `docs/src/generated/` only after every page succeeds. This removes stale renamed pages without destroying the previous generated site when one page fails. Explicit page IDs can be supplied as a comma-separated list through `PISP_LITERATE_PAGES`. Set `PISP_RUN_PRODUCERS=false` only to reuse an already current evidence bundle. The renderer executes each selected source, writes its registered output path, and collapses Julia source blocks behind a **Show source code** disclosure while leaving rendered tables and figures visible.

## Page registry

Each `[[page]]` entry in `docs/page-registry.toml` contains:

| Field | Meaning |
|---|---|
| `id` | Stable page identity, independent of filenames. |
| `title` | Reader-facing navigation title. |
| `kind` | `reference`, `tutorial`, `validation`, or `analysis`. |
| `data_layer` | `package-workflow`, `source-data`, `pisp-dataset`, or `cross-layer`. |
| `source` | Literate source path relative to `docs/`. |
| `output` | Generated Markdown path relative to `docs/src/`. |
| `status` | `published`, `draft`, or `archived`. Active pages are included in navigation; archived pages are not rendered or published. |
| `nav_order` | Position within the page role. |
| `snapshot` | Whether results describe a dated source or generated-data state. |
| `evidence_dir` | Optional EDA evidence directory relative to the repository root. |
| `producer` | Optional analytical producer relative to the repository root. |
| `data_requirements` | Optional direct local inputs required by the Literate page. |
| `related_reference_pages` | Reference or caveat pages that define the relevant package contract. |

`docs/page_registry.jl` rejects unsupported classifications, unsafe paths, duplicate IDs or outputs, duplicate navigation positions, unregistered Literate sources, orphan generated Markdown, missing producers, and missing related pages. A Documenter build also requires every active registry output to exist.

## Evidence and rendering contract

Two flows exist. The self-contained flow is now the default for every page under `docs/literate/eda/`:

```text
source data or PISP datasets
    -> docs/literate/eda/<page>.jl   (loads data, computes evidence, builds figures, on the page)
        -> eda/tables/julia/<script-stem>/   (the same code also writes this, for the regression harness)
            -> docs/src/generated/<role>/<topic>.md
```

The legacy producer-consumer flow remains for the two pages that still use it (`source-data-inventory`, `rez-resource-versus-connection-cost`):

```text
source data or PISP datasets
    -> eda/<producer>.jl
        -> eda/tables/julia/<script-stem>/
            -> docs/literate/<page>.jl
                -> docs/src/generated/<role>/<topic>.md
```

In the self-contained flow, the Literate page owns everything: calculations, evidence tables, figures, reader framing, and interpretation boundaries. In the legacy flow, the registered producer owns calculations and evidence tables, and the Literate page owns reader framing, visible evidence, interpretation boundaries, and links to stable package references. Prefer the self-contained flow for new pages; the legacy flow is not being expanded.

Snapshot pages must display their input or build identity (which download root, output root, or schedule directory was inspected) — every page under `docs/literate/eda/` does this via `EdaSupport.snapshot_metadata_line`, printing the PISP.jl commit, generation date, and a page-specific description of the dated source/build it describes. Final claims should be derived from executed evidence or written as interpretation rules rather than hard-coded observations that can become stale.

## Adding a page

1. Choose one primary reader purpose: reference, tutorial, validation, or analysis.
2. Add the Literate source under the matching `docs/literate/` area where practical.
3. Add one registry entry with a topic-oriented output path.
4. Prefer making the page self-contained: load data, compute evidence, and build figures directly in the Literate source (`include`-ing `eda/eda_support.jl` for the shared table/figure-writer helpers and `EdaSupport.snapshot_metadata_line` for the provenance line), and skip `producer`/`evidence_dir`. Only register a separate `eda/*.jl` producer and `evidence_dir` when there is a specific reason the evidence must be computed outside the page itself.
5. Keep source-derived tables executable rather than copying package constants, filenames, schemas, or repository inventories into plain Markdown.
6. Run the page and inspect the rendered evidence.
7. Run the full documentation build before committing generated Markdown and figures.

## Removing or renaming a page

Remove or rename the Literate source, registry entry, generated Markdown, and generated figures together. Update internal links and decide whether the previous public URL requires a compatibility page or redirect.

`assumptions.md` is the authority for modelling caveats. The earlier standalone `caveats.md` page and duplicate output-validation Literate source are intentionally removed.

## Implementation locations

The generated reference pages read current values from package objects. The main implementation locations remain:

| Concern | Source location |
|---|---|
| Fixed workbook and archive download targets | `src/scrappers/PISP-scrapper-2024files.jl` |
| Trace-page configuration | `src/scrappers/PISP-scrapper-2024traces.jl` |
| Static and schedule schemas | `src/datamodel/` |
| Exported filename mapping | `src/utils/writing/PISPutils-writing.jl` |
| Scenario, bus, area, and weather-year mappings | `src/parameters/general2024ISP.jl` |
| Generator, storage, hydro, build-out, and retirement mappings | `src/parameters/` |
| Renewable-capacity construction | `src/parsers/PISP-2024parser.jl` |
