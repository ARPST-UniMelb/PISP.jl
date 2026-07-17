# PISP documentation maintenance

This guide describes the maintained documentation sources, the Literate rendering workflow, and the checks required before publishing the Documenter site.
It is for maintainers; ordinary readers should begin with the rendered site.

## Documentation architecture

| Surface | Responsibility |
| --- | --- |
| `docs/src/index.md` | Package entry points and the ISP edition guide. |
| `docs/src/editions/` | Edition support, source-material, output-model, trace, mapping, and comparison boundaries. |
| `docs/src/concepts.md` | Stable explanation of the ISP 2024 asset, scenario, trace, and static/schedule model. |
| `docs/src/assumptions.md` | ISP 2024 modelling scope, caveats, validation responsibilities, and external checks. |
| `docs/src/api.md` | Public ISP 2024 build and source-acquisition API boundary. |
| `docs/literate/isp2024/` | Executable ISP 2024 reference, tutorial, validation, and analysis sources. |
| `docs/page-registry.toml` | Authority for every registry-managed Literate source and generated Markdown output. |
| `docs/edition_profiles.jl` | Edition-specific local data roots and schedule defaults used by rendering preflight. |
| `docs/navigation.jl` | Published-site navigation assembled from static edition pages and published registry entries. |
| `docs/src/generated/` | Markdown and figures generated from registered Literate pages. |
| `docs/render_literate.jl` | Literate selection, profile resolution, data preflight, execution, and generated-output installation. |
| `docs/make.jl` | Target-specific source-link staging and Documenter site build. |

The public site separates shared explanatory pages from ISP 2024, ISP 2026, and comparison tracks.
Only the ISP 2024 track currently has registry-managed Literate pages.
The ISP 2026 and comparison landing pages state their available support boundaries without representing source downloads as generated data.

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
| ISP 2024 | `PISP_DOCS_ISP2024_DOWNLOAD_ROOT` | `data/2024/pisp-downloads` |
| ISP 2024 | `PISP_DOCS_ISP2024_OUTPUT_ROOT` | `data/2024/pisp-datasets/out-ref4006-poe10/csv` |
| ISP 2024 | `PISP_DOCS_ISP2024_SCHEDULE_TAG` | `schedule-2030` |
| ISP 2026 | `PISP_DOCS_ISP2026_DOWNLOAD_ROOT` | `data/2026/pisp-downloads` |
| ISP 2026 | `PISP_DOCS_ISP2026_OUTPUT_ROOT` | Unset unless explicitly configured. |
| ISP 2026 | `PISP_DOCS_ISP2026_SCHEDULE_TAG` | Unset unless explicitly configured. |

A `data_requirements` item is an inline TOML table with `root`, `path`, and `type`; `download` and `output` requirements also need an `edition` that the page declares.
The allowed roots are `repo`, `download`, and `output`, while the allowed types are `file`, `directory`, and `path`.

```toml
data_requirements = [{ root = "download", edition = "2024", path = "2024-isp-inputs-and-assumptions-workbook.xlsx", type = "file" }]
```

Before any producer or Literate page runs, the renderer resolves each selected requirement through the relevant edition profile and checks its type.
The render plan prints selected page IDs, track and edition scope, resolved profiles, and resolved requirements.

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
| ISP 2024 scenario, bus, area, and weather-year mappings | `src/parameters/general2024ISP.jl` |
| ISP 2024 parser | `src/parsers/PISP-2024parser.jl` |
