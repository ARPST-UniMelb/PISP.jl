# PISP documentation maintenance

The human-facing documentation lives under `docs/src/` and is built with Documenter.jl.
Literate sources live under `docs/literate/` and render into committed Markdown under `docs/src/generated/`.

## Build the site

From the repository root:

```sh
julia --project=docs docs/make.jl
```

Open `docs/build/index.html` after the build completes.

`docs/make.jl` does not regenerate Literate pages and does not require local AEMO or PISP output data.
It publishes the committed Markdown already present in `docs/src/generated/`.

## Regenerate published Literate tutorials

From the repository root:

```sh
julia --project=docs docs/render_literate.jl
```

The default source set is `published` and currently contains:

| Literate source | Data requirement |
|---|---|
| `docs/literate/problem_table.jl` | None; the page uses in-memory package helpers. |
| `docs/literate/eda_06_pisp_outputs.jl` | A local PISP CSV build at `data/pisp-datasets/out-ref4006-poe10/csv/`, including `schedule-2030/`. |

When the output dataset is absent, the renderer stops with a named precondition error rather than silently producing an incomplete page.

## EDA Literate skeletons

The remaining numbered EDA workflows have draft Literate sources that read the evidence tables produced by their corresponding Julia scripts.
They are intentionally excluded from the published source set and from the Documenter navigation until their rendered outputs have been inspected and their interpretation sections have been replaced with evidence-backed prose.

| EDA script | Draft Literate source | Evidence directory |
|---|---|---|
| `eda/01_data_loading.jl` | `docs/literate/eda_01_data_loading.jl` | `eda/tables/julia/01_data_loading/` |
| `eda/02_plot_4006_traces.jl` | `docs/literate/eda_02_plot_4006_traces.jl` | `eda/tables/julia/02_plot_4006_traces/` |
| `eda/03_year_comparison.jl` | `docs/literate/eda_03_year_comparison.jl` | `eda/tables/julia/03_year_comparison/` |
| `eda/04_seasonal_extremes.jl` | `docs/literate/eda_04_seasonal_extremes.jl` | `eda/tables/julia/04_seasonal_extremes/` |
| `eda/05_temperature_analysis.jl` | `docs/literate/eda_05_temperature_analysis.jl` | `eda/tables/julia/05_temperature_analysis/` |
| `eda/07_demand_heat_events.jl` | `docs/literate/eda_07_demand_heat_events.jl` | `eda/tables/julia/07_demand_heat_events/` |
| `eda/08_4006_composite_map.jl` | `docs/literate/eda_08_4006_composite_map.jl` | `eda/tables/julia/08_4006_composite_map/` |

`eda/06_pisp_outputs.jl` is represented by the published `docs/literate/eda_06_pisp_outputs.jl` tutorial rather than a separate draft skeleton.
`eda/compare_tables.jl` remains a maintainer validation utility for Python/Julia evidence parity rather than a reader-facing EDA page.

Generate the evidence first, for example:

```sh
julia --project=. eda/03_year_comparison.jl
```

Render all draft EDA pages with:

```sh
PISP_LITERATE_SET=eda-drafts julia --project=docs docs/render_literate.jl
```

The draft workflow is:

1. Run the corresponding EDA scripts and preserve the generated evidence tables.
2. Render the draft Literate pages.
3. Inspect the complete rendered tables and any figures added during revision.
4. Replace each reserved interpretation section with conclusions supported by nearby evidence.
5. Add caveats exposed by the first render.
6. Rerun the EDA and Literate render so the prose and evidence remain aligned.
7. Add a page to `docs/make.jl` only when it reads as stable human-facing documentation rather than an analysis log.

Do not write final interpretation before the first successful render.
The skeletons intentionally frame questions and evidence but do not claim results that have not been inspected in this repository snapshot.

## Page ownership

| Path | Purpose |
|---|---|
| `docs/src/index.md` | Human overview, modelling problem, dataset workflow, and navigation. |
| `docs/src/data-sources.md` | Source roles, provenance, local input layout, and source-vintage boundary. |
| `docs/src/concepts.md` | Asset relationships, scenario and trace concepts, and the static/schedule model. |
| `docs/src/outputs.md` | Exported table names, join keys, units, and state-reconstruction rules. |
| `docs/src/parameters.md` | Package constants, mappings, hard-coded assumptions, and interpretation consequences. |
| `docs/src/assumptions.md` | Modelling scope, validation responsibilities, and caveats. |
| `docs/src/api.md` | Documenter `@docs` references. |
| `docs/literate/*.jl` | Executable tutorial sources and unpublished EDA documentation skeletons. |
| `docs/src/generated/*.md` | Committed rendered pages generated from published or inspected Literate sources. |

Keep build mechanics, regeneration commands, local-data preconditions, and source-code locations in this file or in source comments.
Do not place those details at the top of a rendered user page unless the reader needs them to run the documented workflow.

## Maintainer implementation references

The following details are useful when changing parsers or writers, but are intentionally kept out of the main user path:

| Concern | Maintainer location |
|---|---|
| Fixed workbook and archive download targets | `src/scrappers/PISP-scrapper-2024files.jl` |
| Trace-page selector and link-family filters | `src/scrappers/PISP-scrapper-2024traces.jl` |
| Exported schedule filename mapping, including `DER_pred_sched` | `src/utils/writing/PISPutils-writing.jl` |
| Internal DER schedule schema | `src/datamodel/PISPdata-schedule.jl` |
| Scenario labels, bus constants, area mappings, and reference-trace mapping | `src/parameters/general2024ISP.jl` |
| Generator identities, technology groupings, and trace filename exceptions | `src/parameters/gens2024ISP.jl` |
| Storage project mappings and parameters | `src/parameters/ess2024ISP.jl` |
| Hydro mappings | `src/parameters/hydro2024ISP.jl` |
| Future build-out templates | `src/parameters/buildout2024ISP.jl` |
| Retirement mappings and assumptions | `src/parameters/retirements2024ISP.jl` |
| Rooftop PV placeholder and utility-scale renewable capacity logic | `src/parsers/PISP-2024parser.jl` (`gen_pmax_distpv`, `gen_pmax_wind`, and the corresponding solar logic) |

The rooftop-PV, wind, and solar capacity logic reads two sheets of the 2024 ISP Inputs and Assumptions workbook: `Existing Gen Data Summary` (`B11:K297`) for operating capacity, and `Renewable Energy Zones` (`B7:G50`) for REZ-to-bus assignment; both `gen_pmax_wind` and `gen_pmax_solar` use identical sheet names and ranges.
The current trace scraper selects publication links with `div.field-link a` and recognises URL substrings `isp_demand_traces_`, `isp_solar_traces_`, and `isp_wind_traces_`.
It sanitises the published link text, adds `.zip` when required, prefixes a two-digit download index, and defaults to `scrapped/ISP_2024_traces`.
The exported DER schedule is named `DER_pred_sched`, while the internal schema is represented by `MOD_DER_PRED_MAX`.
These names matter when maintaining the implementation but do not change how a package user should read the generated file.

The public scenario mapping is `ID2SCE`; the secondary `ID2SCE2` mapping retains the alternate scenario-3 label `Hydrogen Export`.
