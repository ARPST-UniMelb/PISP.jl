# PISP documentation maintenance

This guide describes the maintained documentation sources, the Literate rendering workflow, and the checks required before publishing the Documenter site.
It is for maintainers; ordinary readers should begin with the rendered site.

## Fresh-clone setup

PISP's root `Project.toml` declares Julia `1.11` compatibility.
Clone the canonical repository, then instantiate the package and documentation environments separately:

```sh
git clone https://github.com/ARPST-UniMelb/PISP.jl.git
cd PISP.jl
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=docs -e 'using Pkg; Pkg.instantiate()'
```

The root environment contains PISP and its runtime and test dependencies.
`docs/Project.toml` is a separate environment for Documenter, Literate, plotting, workbook inspection, and documentation tests.
Its committed source override resolves PISP from the same checkout:

```toml
[sources]
PISP = {path = ".."}
```

The repository does not commit `Manifest.toml` files.
Instantiate each environment from its `Project.toml`, and change dependency constraints only when dependencies are intentionally updated.
Package and documentation-infrastructure tests use fixture or source-code checks unless a test explicitly declares an external-data prerequisite.
Literate pages with `data_requirements` need the configured report, download, or generated-output roots described below.

To instantiate the documentation environment and build the site from the committed generated Markdown:

```sh
julia --project=docs -e 'using Pkg; Pkg.instantiate()'
julia --project=docs docs/make.jl
```

Open `docs/build/index.html` in a browser to inspect the local site.
This build does not execute Literate pages and does not require local ISP data.

While iterating on Literate sources, re-render only the pages whose source changed instead of the whole published set:

```sh
julia --project=docs docs/render_changed.jl
```

`render_changed.jl` resolves the changed `docs/literate/**/*.jl` files (staged, unstaged, or untracked, versus `HEAD`) to their registry page IDs and re-renders just those in place through `PISP_LITERATE_PAGES`.
It reports when a shared file changed (`eda_support.jl`, an EDA producer, or `page-registry.toml`), since those can affect many pages.
Set `PISP_RUN_PRODUCERS=false` to reuse existing EDA evidence instead of re-running the producers.
Run the full `docs/render_literate.jl` before committing regenerated Markdown; the changed-only path skips the whole-set completeness and atomic-replacement checks.

## Prepare local data for complete regeneration

Regenerating every published Literate page requires the referenced ISP report PDFs, the extracted ISP 2026 source assets, and the default ISP 2024 generated dataset.
Start Julia at the repository root with `julia --project=.` and run:

```julia
using PISP

repo = pwd()

reports_2024   = joinpath(repo, "data", "2024", "pisp-reports")
downloads_2024 = joinpath(repo, "data", "2024", "pisp-downloads")
datasets_2024  = joinpath(repo, "data", "2024", "pisp-datasets")

reports_2026   = joinpath(repo, "data", "2026", "pisp-reports")
downloads_2026 = joinpath(repo, "data", "2026", "pisp-downloads")

# Reports referenced by the documentation.
PISP.download_ISP24_reports(
    outdir = reports_2024,
    overwrite = false,
)

PISP.download_ISP26_reports(
    outdir = reports_2026,
    overwrite = false,
)

# ISP 2026 source-availability and comparison pages.
PISP.download_isp2026_assets(
    outdir = downloads_2026,
    overwrite = false,
)

PISP.ISPdatabuilder.extract_downloads(
    data_root = downloads_2026,
)

# Exact ISP 2024 dataset consumed by the published pages.
# This also downloads and extracts the required 2024 source assets.
PISP.build_ISP24_datasets(
    downloadpath = downloads_2024,
    download_from_AEMO = true,
    poe = 10,
    reftrace = 4006,
    years = [2030],
    output_root = datasets_2024,
    write_csv = true,
    write_arrow = false,
    scenarios = [1, 2, 3],
)
```

The ISP 2024 build writes the schedule used by the default documentation profile under `data/2024/pisp-datasets/out-ref4006-poe10/csv/schedule-2030`.
Downloaded and generated files remain under `data/`, which is ignored by Git.

After preparing the local data, regenerate the published pages and build the site:

```sh
julia --project=docs docs/render_literate.jl
julia --project=docs docs/make.jl
```

The combined entry point runs those stages in sequence:

```sh
julia --project=docs docs/build_all.jl
```

Local data are required for complete Literate regeneration, but not for a site build from the committed generated Markdown with `julia --project=docs docs/make.jl`.

## Documentation architecture

| Surface | Responsibility |
| --- | --- |
| `docs/src/index.md` | Package entry points and the ISP edition guide. |
| `docs/src/quickstart.md` | Package-user installation, first ISP 2024 build, output verification, and next steps. |
| `docs/src/contributing.md` | Contributor workspace setup, package and documentation tests, and documentation-change checks. |
| `docs/src/editions/` | Edition support, source-material, output-model, trace, mapping, and comparison boundaries. |
| `docs/src/concepts.md` | Stable explanation of the ISP 2024 asset, scenario, trace, and static/schedule model. |
| `docs/src/assumptions.md` | ISP 2024 modelling scope, caveats, validation responsibilities, and external checks. |
| `docs/src/api.md` | Public ISP 2024 build and source-acquisition API boundary. |
| `docs/literate/isp2024/` | Executable ISP 2024 reference, tutorial, validation, and analysis sources. |
| `docs/page-registry.toml` | Authority for every registry-managed Literate source and generated Markdown output. |
| `docs/edition_profiles.jl` | Edition-specific report/download roots and schedule defaults used by rendering preflight. |
| `docs/navigation.jl` | Published-site navigation assembled from static edition pages and published registry entries. |
| `docs/src/generated/` | Markdown and figures generated from registered Literate pages. |
| `docs/render_literate.jl` | Literate selection, profile resolution, data preflight, execution, and generated-output installation. |
| `docs/make.jl` | Target-specific source-link staging and Documenter site build. |

The public site separates shared explanatory pages from ISP 2024, ISP 2026, and comparison tracks.
The ISP 2026 and comparison tracks publish source-data-only availability pages;
processed-data and parser claims remain outside their scope.

## Page registry

Each `[[page]]` entry in `docs/page-registry.toml` describes one executable Literate page.
The registry validates page metadata, source and output paths, navigation positions, related pages, registered sources, and generated Markdown.

| Field | Meaning |
| --- | --- |
| `id` | Stable page identity, independent of filenames. |
| `title` | Reader-facing page title. |
| `kind` | `reference`, `tutorial`, `validation`, or `analysis`. |
| `track` | `shared`, `isp2024`, `isp2026`, or `comparison`. |
| `editions` | Edition scope declared by the page. `isp2024` requires `["2024"]`; `isp2026` requires `["2026"]`; `comparison` requires at least two editions. |
| `data_layer` | `package-workflow`, `source-data`, `pisp-dataset`, or `cross-layer`. |
| `source` | Literate source path relative to `docs/`. |
| `output` | Generated Markdown path relative to `docs/src/`. |
| `status` | Publication and render selection state. |
| `nav_order` | Position within a track and kind. |
| `snapshot` | Whether the page describes a dated source or generated-data state. |
| `data_requirements` | Typed local files or directories required before page execution. |
| `producer` and `evidence_dir` | Optional external evidence producer and its directory. |
| `related_reference_pages` | Static or generated pages defining the relevant package contract. |

Use relative paths in registry metadata; paths that escape their declared root are rejected.
The registry also rejects duplicate IDs, titles, outputs, and renderable `(track, kind, nav_order)` positions.

### Status and selection

| Status | Navigation | Default render selection | Generated-output requirement |
| --- | --- | --- | --- |
| `published` | Included in the published navigation. | Included by `PISP_LITERATE_SET=published`, the default. | Required before `docs/make.jl` can build the site. |
| `draft` | Omitted from published navigation. | Included only by `PISP_LITERATE_SET=draft` or `all`. | Not required by `docs/make.jl`. |
| `archived` | Omitted. | Never renderable, including through an explicit page-ID selection. | Not required. |

`PISP_LITERATE_SET` accepts `published`, `draft`, or `all`; `eda-drafts` is also accepted as a draft alias.
`PISP_DOCS_TRACK` filters the selected status set by `shared`, `isp2024`, `isp2026`, or `comparison`.
`PISP_LITERATE_PAGES` selects explicit comma-separated page IDs, but it cannot be combined with a non-default set or with a track filter.

For example, render the current published ISP 2024 track with:

```sh
PISP_DOCS_TRACK=isp2024 julia --project=docs docs/render_literate.jl
```

Render one known page by its registry ID with:

```sh
PISP_LITERATE_PAGES=isp2024-historical-trace-years julia --project=docs docs/render_literate.jl
```

## Edition profiles and data preflight

`docs/edition_profiles.jl` centralises local roots and schedule defaults used by documentation rendering.
Relative environment-variable values are resolved from the repository root.

| Edition | Environment variable | Default |
| --- | --- | --- |
| ISP 2024 | `PISP_DOCS_ISP2024_REPORT_ROOT` | `data/2024/pisp-reports` |
| ISP 2024 | `PISP_DOCS_ISP2024_DOWNLOAD_ROOT` | `data/2024/pisp-downloads` |
| ISP 2024 | `PISP_DOCS_ISP2024_OUTPUT_ROOT` | `data/2024/pisp-datasets/out-ref4006-poe10/csv` |
| ISP 2024 | `PISP_DOCS_ISP2024_SCHEDULE_TAG` | `schedule-2030` |
| ISP 2026 | `PISP_DOCS_ISP2026_DOWNLOAD_ROOT` | `data/2026/pisp-downloads` |
| ISP 2026 | `PISP_DOCS_ISP2026_REPORT_ROOT` | `data/2026/pisp-reports` |
| ISP 2026 | `PISP_DOCS_ISP2026_OUTPUT_ROOT` | Unset unless explicitly configured. |
| ISP 2026 | `PISP_DOCS_ISP2026_SCHEDULE_TAG` | Unset unless explicitly configured. |

A `data_requirements` item is an inline TOML table with `root`, `path`, and `type`; `download` and `output` requirements also need an `edition` that the page declares.
The allowed roots are `repo`, `report`, `download`, and `output`, while the allowed types are `file`, `directory`, and `path`.

```toml
data_requirements = [{ root = "download", edition = "2024", path = "2024-isp-inputs-and-assumptions-workbook.xlsx", type = "file" }]
```

The source-only ISP 2026 and comparison pages declare edition-qualified report
and download requirements. Their preflight is mandatory for a selected
Literate render: provide both roots, render the selected page, and inspect the
generated Markdown and local-observation tables. An absent root is not skipped
by selected-page rendering. The optional skip-versus-fail behavior belongs only
to the package-root fixture checks in `test/runtests.jl`.

Before any producer or Literate page runs, the renderer resolves each selected requirement through the relevant edition profile and checks its type.
The render plan prints selected page IDs, track and edition scope, resolved profiles, and resolved requirements.

## Validation commands

Run checks from the repository root.

| Lifecycle action | Command | Reads and writes | Local ISP data required? |
| --- | --- | --- | --- |
| Package tests | `julia --project=. -e 'using Pkg; Pkg.test()'` | Reads the package and root test environment; writes normal Julia caches and temporary test artefacts. | No for fixture-based checks; local source-root checks skip when configured material is absent. |
| Documentation infrastructure tests | `julia --project=docs docs/test/runtests.jl` | Reads registry, navigation, renderer, and helper fixtures; writes temporary test directories. | No. |
| Source-link routing | `julia --project=docs docs/test_source_links.jl` | Reads maintained Markdown and source-link configuration; writes temporary staged files. | No. |
| Literate render | `julia --project=docs docs/render_literate.jl` | Reads registered sources and their declared data requirements; writes committed generated Markdown and figures. | Yes for selected data-dependent pages. |
| Local-link site build | `julia --project=docs docs/make.jl` | Reads maintained and committed generated Markdown; writes `docs/.documenter-source/` and `docs/build/`. | No. |
| Public-link site build | `PISP_DOCS_LINK_TARGET=public julia --project=docs docs/make.jl` | Reads source-link mappings and documentation sources; writes staged public-link pages and `docs/build/`. | No. |
| Render and local build | `julia --project=docs docs/build_all.jl` | Runs the registered Literate render followed by the local-link site build. | Yes for data-dependent published pages. |

Package tests, documentation tests, and source-link tests are normal contributor checks.
A complete Literate render and both link-target builds are publication checks because they validate committed generated sources and the rendered reader experience.

## Rendering and site builds

Regenerate all published Literate pages before a complete local site build:

```sh
julia --project=docs docs/render_literate.jl
```

When this selection is exactly the published registry set, rendering uses a staging tree and replaces `docs/src/generated/` only after every page succeeds and the registry validates the results.
For selected-page renders, inspect the generated Markdown and figures before building the site.

Build the site from the maintained Markdown and generated outputs with local source links:

```sh
julia --project=docs docs/make.jl
```

Run rendering followed by the site build in one command sequence with:

```sh
julia --project=docs docs/build_all.jl
```

`docs/make.jl` never executes Literate pages.
It requires every published registry output to exist, stages `docs/src/` under `docs/.documenter-source/`, and builds the site under `docs/build/`.
It does not resolve or evaluate `data_requirements`; it builds from committed
generated Markdown and therefore does not require local source roots.

## Source links and validation

Maintained Markdown keeps repository-local links to registered source PDFs.
`docs/source-links.toml` maps those local paths to official publisher URLs for public builds, while `docs/make.jl` stages a target-specific copy rather than rewriting `docs/src/`.

Build the public-link variant with:

```sh
PISP_DOCS_LINK_TARGET=public julia --project=docs docs/make.jl
```

Validate source-link routing independently with:

```sh
julia --project=docs docs/test_source_links.jl
```

## Adding or changing a registry-managed page

1. Choose the page's reader purpose, track, edition scope, and data layer.
2. Add or update the Literate source and its registry entry together.
3. Declare every direct local input through typed `data_requirements` instead of embedding untracked path assumptions in the renderer.
4. Use the edition profile for source or output roots in edition-specific Literate pages.
5. Render the affected page, inspect its Markdown and figures, then run the appropriate site and source-link checks.
6. Update related reference pages whenever a source, output, mapping, or support boundary changes.

Executable validation and analysis pages should keep reader-facing evidence and interpretation with the code that computes them.
Use `producer` and `evidence_dir` only when a separate producer is necessary; every registered path must be valid, and `evidence_dir` requires a `producer`.

## Implementation locations

| Concern | Source location |
| --- | --- |
| ISP 2024 source download targets | `src/scrappers/PISP-scrapper-2024files.jl` |
| ISP 2024 trace configuration | `src/scrappers/PISP-scrapper-2024traces.jl` |
| ISP 2026 source-asset download targets | `src/scrappers/PISP-scrapper-2026files.jl` |
| ISP 2026 report-download targets | `src/scrappers/PISP-scrapper-2026reports.jl` |
| Static and schedule schemas | `src/datamodel/` |
| Exported filename mapping | `src/utils/writing/PISPutils-writing.jl` |
| ISP 2024 scenario, bus, area, and weather-year mappings | [`src/parameters/general2024ISP.jl`](https://github.com/ARPST-UniMelb/PISP.jl/blob/main/src/parameters/general2024ISP.jl) |
| ISP 2024 parser | [`src/parsers/PISP-2024parser.jl`](https://github.com/ARPST-UniMelb/PISP.jl/blob/main/src/parsers/PISP-2024parser.jl) |
