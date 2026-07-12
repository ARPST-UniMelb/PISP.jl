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
| `docs/literate/validation/` | Executable validation pages backed by registered evidence producers. |
| `docs/literate/eda_*.jl` | Current analysis pages backed by numbered EDA producers. Their public output paths are topic-oriented through the registry. |
| `docs/src/generated/` | Static Markdown and figures generated from all active Literate sources. |
| `eda/*.jl` | Analytical producers that write evidence for validation and analysis pages. |
| `eda/tables/julia/<script-stem>/` | Current EDA evidence location. |

The public navigation follows reader purpose: reference, tutorial, validation, or analysis. Numeric EDA identifiers remain producer identifiers and do not determine public page names.

## Complete local build

From the repository root, run:

```sh
julia --project=docs docs/build_all.jl
```

The complete build performs these lifecycle stages in order:

1. run each unique EDA producer registered by an active page;
2. execute every active Literate source and regenerate its static Markdown and figures;
3. build the Documenter site from the generated files.

The build stops on the first failed producer, Literate page, registry check, or Documenter build. A failed complete render does not replace an existing `docs/src/generated/` tree.

Set `PISP_DATA_ROOT` when the source-data reference page should inspect a download root other than `data/pisp-downloads/`.

Open `docs/build/index.html` after the build completes.

## Run stages separately

Render one page and rerun its registered producer:

```sh
PISP_LITERATE_PAGES=historical-trace-years julia --project=docs docs/render_literate.jl
```

Render every active Literate page and rerun all registered producers:

```sh
julia --project=docs docs/render_literate.jl
```

Reuse existing evidence only when it is known to match the current Literate sources:

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

Validation and analysis pages normally follow this flow:

```text
source data or PISP datasets
    -> eda/<producer>.jl
        -> eda/tables/julia/<script-stem>/
            -> docs/literate/<page>.jl
                -> docs/src/generated/<role>/<topic>.md
```

The EDA producer owns calculations and evidence tables. The Literate page owns reader framing, visible evidence, interpretation boundaries, and links to stable package references. A tutorial may execute similar joins when those joins are themselves the workflow being taught, but validation metrics remain in the registered producer.

Snapshot pages must display their generated time and input or build identity. Final claims should be derived from executed evidence or written as interpretation rules rather than hard-coded observations that can become stale.

## Adding a page

1. Choose one primary reader purpose: reference, tutorial, validation, or analysis.
2. Add the Literate source under the matching `docs/literate/` area where practical.
3. Add one registry entry with a topic-oriented output path.
4. Register an EDA producer and evidence directory when the page consumes computed evidence.
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
