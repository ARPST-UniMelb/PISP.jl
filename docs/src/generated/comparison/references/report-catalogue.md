```@meta
EditURL = "../../../../literate/comparison/reference/report_catalogue.jl"
```

# ISP report catalogue

The catalogue follows the ordered report targets exposed by the ISP 2024 and
ISP 2026 downloaders. Each entry identifies the report, its repository PDF,
and the corresponding publication on the Australian Energy Market Operator
website.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using ParseISP

const REPO_ROOT = normpath(
    get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..", "..")),
)
include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const REPORT_PDF_ROOT = "../../../../../data"

function report_pdf_link(edition, target)
    path = "$(REPORT_PDF_ROOT)/$(edition)/pisp-reports/$(target.filename)#page=1"
    return "[$(target.filename)]($(path))"
end

function report_filename_cell(edition, target)
    return "$(report_pdf_link(edition, target)) · [AEMO]($(target.url))"
end

function counterpart_cell(edition, target)
    return "$(target.title) — $(report_filename_cell(edition, target))"
end

function inventory_rows(edition, targets)
    return [
        Any[target.title, report_filename_cell(edition, target)]
        for target in targets
    ]
end

targets_2024 = collect(ParseISP.ISP2024ReportDownloader.report_targets())
targets_2026 = collect(ParseISP.ISP2026ReportDownloader.report_targets())
targets_2024_by_key = Dict(target.key => target for target in targets_2024)
targets_2026_by_key = Dict(target.key => target for target in targets_2026)
counterpart_rows = [
    Any[
        counterpart_cell("2024", targets_2024_by_key[key_2024]),
        counterpart_cell("2026", targets_2026_by_key[key_2026]),
    ]
    for (key_2024, key_2026) in ParseISPDocUtils.report_counterpart_key_map()
]
````

```@raw html
</details>
```

## Explicit counterparts

These rows show only conservative semantic counterparts. Reports without an
explicit counterpart remain in the complete edition inventories below.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ParseISPDocUtils.markdown_table(
    ["ISP 2024 report", "ISP 2026 report"],
    counterpart_rows;
    alignment = [:left, :left],
)
````

```@raw html
</details>
```

| ISP 2024 report | ISP 2026 report |
| :--- | :--- |
| 2024 ISP PLEXOS Model Instructions — [2024-isp-plexos-model-instructions.pdf](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/supporting-materials/2024-isp-plexos-model-instructions.pdf?la=en) | 2026 ISP PLEXOS Model Instructions — [2026-isp-plexos-model-instructions.pdf](../../../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/isp-model/2026-isp-plexos-model-instructions.pdf?la=en) |
| 2024 Integrated System Plan — [2024-integrated-system-plan.pdf](../../../../../data/2024/pisp-reports/2024-integrated-system-plan.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/2024-integrated-system-plan-isp.pdf?la=en) | 2026 Integrated System Plan — [2026-integrated-system-plan.pdf](../../../../../data/2026/pisp-reports/2026-integrated-system-plan.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/2026-integrated-system-plan-isp.pdf?rev=7f5dfd18aa1b4a3aab704c424f75afd3&sc_lang=en) |
| 2023 Inputs, Assumptions and Scenarios Report — [2023-inputs-assumptions-and-scenarios-report.pdf](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2023/2023-inputs-assumptions-and-scenarios-report.pdf?la=en) | 2025 Inputs, Assumptions and Scenarios Report — [2025-inputs-assumptions-and-scenarios-report.pdf](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2024/2025-iasr-scenarios/final-docs/2025-inputs-assumptions-and-scenarios-report.pdf?rev=63268acd3f044adb9f5f3a32b6880c27&sc_lang=en) |
| Addendum to the 2023 Inputs Assumptions and Scenarios Report — [addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf](../../../../../data/2024/pisp-reports/addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2023/addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf?la=en) | Addendum to the 2025 Inputs, Assumptions and Scenarios Report — [addendum-to-2025-inputs-assumptions-and-scenarios-report.pdf](../../../../../data/2026/pisp-reports/addendum-to-2025-inputs-assumptions-and-scenarios-report.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/draft-2026/addendum-to-the-2025-inputs-assumptions-and-scenarios-report.pdf) |
| ISP Methodology (30 June 2023) — [2023-isp-methodology.pdf](../../../../../data/2024/pisp-reports/2023-isp-methodology.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2023/isp-methodology-2023/isp-methodology_june-2023.pdf?la=en) | ISP Methodology (June 2025) — [2025-isp-methodology.pdf](../../../../../data/2026/pisp-reports/2025-isp-methodology.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2024/2026-isp-methodology/isp-methodology-june-2025.pdf) |
| A2 Generation and Storage Development Opportunities — [a2-generation-and-storage-development-opportunities.pdf](../../../../../data/2024/pisp-reports/a2-generation-and-storage-development-opportunities.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a2-generation-and-storage-development-opportunities.pdf?la=en) | A2 ISP Development Opportunities — [a2-isp-development-opportunities.pdf](../../../../../data/2026/pisp-reports/a2-isp-development-opportunities.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a2-isp-development-opportunities.pdf?rev=d81062e7cdcf4af8a04fbccdfc3c9fb4&sc_lang=en) |
| A3 Renewable Energy Zones — [a3-renewable-energy-zones.pdf](../../../../../data/2024/pisp-reports/a3-renewable-energy-zones.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a3-renewable-energy-zones.pdf?rev=12a046694eac41dc99031c43bbce35e0&sc_lang=en) | A3 Renewable Energy Zones — [a3-renewable-energy-zones.pdf](../../../../../data/2026/pisp-reports/a3-renewable-energy-zones.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a3-renewable-energy-zones.pdf?la=en) |
| A4 System Operability — [a4-system-operability.pdf](../../../../../data/2024/pisp-reports/a4-system-operability.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a4-system-operability.pdf?la=en) | A4 System Operability — [a4-system-operability.pdf](../../../../../data/2026/pisp-reports/a4-system-operability.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a4-system-operability.pdf?la=en) |
| A6 Cost Benefit Analysis — [a6-cost-benefit-analysis.pdf](../../../../../data/2024/pisp-reports/a6-cost-benefit-analysis.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a6-cost-benefit-analysis.pdf?la=en) | A6 Cost Benefit Analysis — [a6-cost-benefit-analysis.pdf](../../../../../data/2026/pisp-reports/a6-cost-benefit-analysis.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a6-cost-benefit-analysis.pdf?la=en) |
| A7 System Security — [a7-system-security.pdf](../../../../../data/2024/pisp-reports/a7-system-security.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a7-system-security.pdf?la=en) | A7 System Security — [a7-system-security.pdf](../../../../../data/2026/pisp-reports/a7-system-security.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a7-system-security.pdf?la=en) |
| 2024 ISP Publication Webinar Presentation — [2024-isp-publication-webinar-presentation.pdf](../../../../../data/2024/pisp-reports/2024-isp-publication-webinar-presentation.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/2024-isp-publication-webinar-presentation.pdf?rev=392d12bc130f48fab67051f86977e939&sc_lang=en) | 2026 ISP Publication Webinar Presentation — [2026-isp-publication-webinar-presentation.pdf](../../../../../data/2026/pisp-reports/2026-isp-publication-webinar-presentation.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/2026-isp-publication-webinar-presentation.pdf?rev=5d4743f20aff47699588354c1bfd76cc&sc_lang=en) |
| A1 Stakeholder Engagement — [a1-stakeholder-engagement.pdf](../../../../../data/2024/pisp-reports/a1-stakeholder-engagement.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a1-stakeholder-engagement.pdf?rev=21f03a266f854bccb1faa82485de094f&sc_lang=en) | A1 Stakeholder Engagement — [a1-stakeholder-engagement.pdf](../../../../../data/2026/pisp-reports/a1-stakeholder-engagement.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a1-stakeholder-engagement.pdf?rev=fb67d2dee69042f3885d5f8a649267d6&sc_lang=en) |
| A5 Network Investments — [a5-network-investments.pdf](../../../../../data/2024/pisp-reports/a5-network-investments.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a5-network-investments.pdf?rev=330abdf826cd4310a05f16fdeafd98d3&sc_lang=en) | A5 Network Investments — [a5-network-investments.pdf](../../../../../data/2026/pisp-reports/a5-network-investments.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a5-network-investments.pdf?rev=a351f6c817484d79bc34f9a8e817f077&sc_lang=en) |
| A8 Social Licence — [a8-social-licence.pdf](../../../../../data/2024/pisp-reports/a8-social-licence.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a8-social-licence.pdf?rev=ab35f15c9fcf4303a43a3ec4acbb3dca&sc_lang=en) | A8 Social Licence — [a8-social-licence.pdf](../../../../../data/2026/pisp-reports/a8-social-licence.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a8-social-licence.pdf?rev=035a91c449f44bfc82a888a6770d9f90&sc_lang=en) |
| 2024 ISP Consultation Summary Report — [2024-isp-consultation-summary-report.pdf](../../../../../data/2024/pisp-reports/2024-isp-consultation-summary-report.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/supporting-materials/2024-isp-consultation-summary-report.pdf?rev=9e901f2b861843ccbd8673ebb6e7819b&sc_lang=en) | 2026 ISP Consultation Summary Report — [2026-isp-consultation-summary-report.pdf](../../../../../data/2026/pisp-reports/2026-isp-consultation-summary-report.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/supporting-materials/2026-isp-consultation-summary-report.pdf?rev=7982dc7041d4477d988d9f75485846d3&sc_lang=en) |

## ISP 2024 report inventory

The order follows `ISP2024ReportDownloader.report_targets()`.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ParseISPDocUtils.markdown_table(
    ["Report title", "Filename"],
    inventory_rows("2024", targets_2024);
    alignment = [:left, :left],
)
````

```@raw html
</details>
```

| Report title | Filename |
| :--- | :--- |
| 2024 ISP PLEXOS Model Instructions | [2024-isp-plexos-model-instructions.pdf](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/supporting-materials/2024-isp-plexos-model-instructions.pdf?la=en) |
| 2024 Integrated System Plan | [2024-integrated-system-plan.pdf](../../../../../data/2024/pisp-reports/2024-integrated-system-plan.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/2024-integrated-system-plan-isp.pdf?la=en) |
| 2023 Inputs, Assumptions and Scenarios Report | [2023-inputs-assumptions-and-scenarios-report.pdf](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2023/2023-inputs-assumptions-and-scenarios-report.pdf?la=en) |
| Addendum to the 2023 Inputs Assumptions and Scenarios Report | [addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf](../../../../../data/2024/pisp-reports/addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2023/addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf?la=en) |
| ISP Methodology (30 June 2023) | [2023-isp-methodology.pdf](../../../../../data/2024/pisp-reports/2023-isp-methodology.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2023/isp-methodology-2023/isp-methodology_june-2023.pdf?la=en) |
| A2 Generation and Storage Development Opportunities | [a2-generation-and-storage-development-opportunities.pdf](../../../../../data/2024/pisp-reports/a2-generation-and-storage-development-opportunities.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a2-generation-and-storage-development-opportunities.pdf?la=en) |
| A3 Renewable Energy Zones | [a3-renewable-energy-zones.pdf](../../../../../data/2024/pisp-reports/a3-renewable-energy-zones.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a3-renewable-energy-zones.pdf?rev=12a046694eac41dc99031c43bbce35e0&sc_lang=en) |
| A4 System Operability | [a4-system-operability.pdf](../../../../../data/2024/pisp-reports/a4-system-operability.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a4-system-operability.pdf?la=en) |
| A6 Cost Benefit Analysis | [a6-cost-benefit-analysis.pdf](../../../../../data/2024/pisp-reports/a6-cost-benefit-analysis.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a6-cost-benefit-analysis.pdf?la=en) |
| A7 System Security | [a7-system-security.pdf](../../../../../data/2024/pisp-reports/a7-system-security.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a7-system-security.pdf?la=en) |
| 2024 Integrated System Plan - Overview | [2024-integrated-system-plan-overview.pdf](../../../../../data/2024/pisp-reports/2024-integrated-system-plan-overview.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/2024-integrated-system-plan-overview.pdf?rev=ac883f3706bc449ca4cd64da6cb25175&sc_lang=en) |
| 2024 ISP Publication Webinar Presentation | [2024-isp-publication-webinar-presentation.pdf](../../../../../data/2024/pisp-reports/2024-isp-publication-webinar-presentation.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/2024-isp-publication-webinar-presentation.pdf?rev=392d12bc130f48fab67051f86977e939&sc_lang=en) |
| A1 Stakeholder Engagement | [a1-stakeholder-engagement.pdf](../../../../../data/2024/pisp-reports/a1-stakeholder-engagement.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a1-stakeholder-engagement.pdf?rev=21f03a266f854bccb1faa82485de094f&sc_lang=en) |
| A5 Network Investments | [a5-network-investments.pdf](../../../../../data/2024/pisp-reports/a5-network-investments.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a5-network-investments.pdf?rev=330abdf826cd4310a05f16fdeafd98d3&sc_lang=en) |
| A8 Social Licence | [a8-social-licence.pdf](../../../../../data/2024/pisp-reports/a8-social-licence.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a8-social-licence.pdf?rev=ab35f15c9fcf4303a43a3ec4acbb3dca&sc_lang=en) |
| 2024 ISP Consultation Summary Report | [2024-isp-consultation-summary-report.pdf](../../../../../data/2024/pisp-reports/2024-isp-consultation-summary-report.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/supporting-materials/2024-isp-consultation-summary-report.pdf?rev=9e901f2b861843ccbd8673ebb6e7819b&sc_lang=en) |
| Summary of Consumer Risk Preferences Project | [summary-of-consumer-risk-preferences-project.pdf](../../../../../data/2024/pisp-reports/summary-of-consumer-risk-preferences-project.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2023/draft-2024-isp-consultation/supporting-materials/summary-of-consumer-risk-preferences-project.pdf?rev=573eb60f837c4c58bdef452f425da215&sc_lang=en) |
| Attachment 1 Deloitte Report - Consumer Risk Preferences | [attachment-1-deloitte-report-consumer-risk-preferences.pdf](../../../../../data/2024/pisp-reports/attachment-1-deloitte-report-consumer-risk-preferences.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2023/draft-2024-isp-consultation/supporting-materials/attachment-1-deloitte-report-consumer-risk-preferences.pdf?rev=ac0acb36290d439cbf3d6c4690ac39f2&sc_lang=en) |
| Attachment 2 Antenna Report - Consumer Risk Preferences | [attachment-2-antenna-report-consumer-risk-preferences.pdf](../../../../../data/2024/pisp-reports/attachment-2-antenna-report-consumer-risk-preferences.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2023/draft-2024-isp-consultation/supporting-materials/attachment-2-antenna-report-consumer-risk-preferences.pdf?rev=67c875994d514ff295a22188b07ec078&sc_lang=en) |
| 2024 ISP Delphi Panel - Overview | [2024-isp-delphi-panel-overview.pdf](../../../../../data/2024/pisp-reports/2024-isp-delphi-panel-overview.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2023/2024-isp-delphi-panel---overview.pdf?rev=299bd33e7faf43f1b1e5654aadbbe423&sc_lang=en) |
| The Australian Electricity Workforce for the 2024 ISP: Projections to 2050 | [2024-isp-workforce-projections-nem.pdf](../../../../../data/2024/pisp-reports/2024-isp-workforce-projections-nem.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/electricity-sector-workforce-projections/nem-2024-workforce_final.pdf?rev=5640af2eadd448cba44f1fb3a61bc9e3&sc_lang=en) |
| Electricity Workforce Projections for the 2024 ISP: New South Wales | [2024-isp-workforce-projections-nsw.pdf](../../../../../data/2024/pisp-reports/2024-isp-workforce-projections-nsw.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/electricity-sector-workforce-projections/focus-on-nsw_2024.pdf?rev=de6545e01db84720b6645356b4dd0053&sc_lang=en) |
| Electricity Workforce Projections for the 2024 ISP: Queensland | [2024-isp-workforce-projections-qld.pdf](../../../../../data/2024/pisp-reports/2024-isp-workforce-projections-qld.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/electricity-sector-workforce-projections/focus-on-qld-2024_final.pdf?rev=7414890c9a684c5db75f64790ff76afb&sc_lang=en) |
| Electricity Workforce Projections for the 2024 ISP: South Australia | [2024-isp-workforce-projections-sa.pdf](../../../../../data/2024/pisp-reports/2024-isp-workforce-projections-sa.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/electricity-sector-workforce-projections/focus-on-sa-2024_final.pdf?rev=4db5b7bfc983460b9c658680693ccb56&sc_lang=en) |
| Electricity Workforce Projections for the 2024 ISP: Tasmania | [2024-isp-workforce-projections-tas.pdf](../../../../../data/2024/pisp-reports/2024-isp-workforce-projections-tas.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/electricity-sector-workforce-projections/focus-on-tas-2024_final.pdf?rev=252f6df93f6a43a79c3df0dff145874d&sc_lang=en) |
| Electricity Workforce Projections for the 2024 ISP: Victoria | [2024-isp-workforce-projections-vic.pdf](../../../../../data/2024/pisp-reports/2024-isp-workforce-projections-vic.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2024/electricity-sector-workforce-projections/focus-on-vic-2024_final.pdf?rev=7f4f554dc25c4dff91e05d896bc76288&sc_lang=en) |
| Aurecon 2022 Costs and Technical Parameters Review | [aurecon-2022-cost-and-technical-parameter-review.pdf](../../../../../data/2024/pisp-reports/aurecon-2022-cost-and-technical-parameter-review.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2022/2023-inputs-assumptions-and-scenarios-consultation/supporting-materials-for-2023/aurecon-2022-cost-and-technical-parameter-review.pdf) |

## ISP 2026 report inventory

The order follows `ISP2026ReportDownloader.report_targets()`.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ParseISPDocUtils.markdown_table(
    ["Report title", "Filename"],
    inventory_rows("2026", targets_2026);
    alignment = [:left, :left],
)
````

```@raw html
</details>
```

| Report title | Filename |
| :--- | :--- |
| 2026 Integrated System Plan | [2026-integrated-system-plan.pdf](../../../../../data/2026/pisp-reports/2026-integrated-system-plan.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/2026-integrated-system-plan-isp.pdf?rev=7f5dfd18aa1b4a3aab704c424f75afd3&sc_lang=en) |
| 2026 ISP PLEXOS Model Instructions | [2026-isp-plexos-model-instructions.pdf](../../../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/isp-model/2026-isp-plexos-model-instructions.pdf?la=en) |
| 2025 Inputs, Assumptions and Scenarios Report | [2025-inputs-assumptions-and-scenarios-report.pdf](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2024/2025-iasr-scenarios/final-docs/2025-inputs-assumptions-and-scenarios-report.pdf?rev=63268acd3f044adb9f5f3a32b6880c27&sc_lang=en) |
| Addendum to the 2025 Inputs, Assumptions and Scenarios Report | [addendum-to-2025-inputs-assumptions-and-scenarios-report.pdf](../../../../../data/2026/pisp-reports/addendum-to-2025-inputs-assumptions-and-scenarios-report.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/draft-2026/addendum-to-the-2025-inputs-assumptions-and-scenarios-report.pdf) |
| ISP Methodology (June 2025) | [2025-isp-methodology.pdf](../../../../../data/2026/pisp-reports/2025-isp-methodology.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2024/2026-isp-methodology/isp-methodology-june-2025.pdf) |
| A2 ISP Development Opportunities | [a2-isp-development-opportunities.pdf](../../../../../data/2026/pisp-reports/a2-isp-development-opportunities.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a2-isp-development-opportunities.pdf?rev=d81062e7cdcf4af8a04fbccdfc3c9fb4&sc_lang=en) |
| A3 Renewable Energy Zones | [a3-renewable-energy-zones.pdf](../../../../../data/2026/pisp-reports/a3-renewable-energy-zones.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a3-renewable-energy-zones.pdf?la=en) |
| A4 System Operability | [a4-system-operability.pdf](../../../../../data/2026/pisp-reports/a4-system-operability.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a4-system-operability.pdf?la=en) |
| A6 Cost Benefit Analysis | [a6-cost-benefit-analysis.pdf](../../../../../data/2026/pisp-reports/a6-cost-benefit-analysis.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a6-cost-benefit-analysis.pdf?la=en) |
| A7 System Security | [a7-system-security.pdf](../../../../../data/2026/pisp-reports/a7-system-security.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a7-system-security.pdf?la=en) |
| 2026 Integrated System Plan - Explainer | [2026-isp-explainer.pdf](../../../../../data/2026/pisp-reports/2026-isp-explainer.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/aemo-2026-isp-explainer.pdf?rev=a1aa113a81194508a1aced90d26b1dd9&sc_lang=en) |
| 2026 Integrated System Plan - Infographic | [2026-isp-infographic.pdf](../../../../../data/2026/pisp-reports/2026-isp-infographic.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/2026-integrated-system-plan-infographic.pdf?rev=6568e9e8a4f34f5cb5f28a702d7fb453&sc_lang=en) |
| 2026 ISP Publication Webinar Presentation | [2026-isp-publication-webinar-presentation.pdf](../../../../../data/2026/pisp-reports/2026-isp-publication-webinar-presentation.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/2026-isp-publication-webinar-presentation.pdf?rev=5d4743f20aff47699588354c1bfd76cc&sc_lang=en) |
| A1 Stakeholder Engagement | [a1-stakeholder-engagement.pdf](../../../../../data/2026/pisp-reports/a1-stakeholder-engagement.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a1-stakeholder-engagement.pdf?rev=fb67d2dee69042f3885d5f8a649267d6&sc_lang=en) |
| A5 Network Investments | [a5-network-investments.pdf](../../../../../data/2026/pisp-reports/a5-network-investments.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a5-network-investments.pdf?rev=a351f6c817484d79bc34f9a8e817f077&sc_lang=en) |
| A8 Social Licence | [a8-social-licence.pdf](../../../../../data/2026/pisp-reports/a8-social-licence.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a8-social-licence.pdf?rev=035a91c449f44bfc82a888a6770d9f90&sc_lang=en) |
| A9 Demand Side Factors Statement | [a9-demand-side-factors-statement.pdf](../../../../../data/2026/pisp-reports/a9-demand-side-factors-statement.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a9-demand-side-factors-statement.pdf?rev=cfadf873c9934b46aecd670fdcd8995f&sc_lang=en) |
| A10 Gas Development Projections | [a10-gas-development-projections.pdf](../../../../../data/2026/pisp-reports/a10-gas-development-projections.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a10-gas-development-projections.pdf?rev=e204886dac1c4f01a471e239723fb054&sc_lang=en) |
| 2026 ISP Consultation Summary Report | [2026-isp-consultation-summary-report.pdf](../../../../../data/2026/pisp-reports/2026-isp-consultation-summary-report.pdf#page=1) · [AEMO](https://www.aemo.com.au/-/media/files/major-publications/isp/2026/supporting-materials/2026-isp-consultation-summary-report.pdf?rev=7982dc7041d4477d988d9f75485846d3&sc_lang=en) |
