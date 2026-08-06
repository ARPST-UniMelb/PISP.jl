module ISP2026ReportDownloader

    using ParseISP.ISPReportDownloader: ISPReportTarget, download_report_targets

    export report_targets,
        download_reports

    const DEFAULT_REPORTS_OUTDIR = "data/2026/pisp-reports"

    const ISP_REPORT_TARGETS = (
        ISPReportTarget(:integrated_system_plan,
                        "2026 Integrated System Plan",
                        "2026-integrated-system-plan.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/2026-integrated-system-plan-isp.pdf?rev=7f5dfd18aa1b4a3aab704c424f75afd3&sc_lang=en"),
        ISPReportTarget(:plexos_model_instructions,
                        "2026 ISP PLEXOS Model Instructions",
                        "2026-isp-plexos-model-instructions.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/isp-model/2026-isp-plexos-model-instructions.pdf?la=en"),
        ISPReportTarget(:iasr_2025,
                        "2025 Inputs, Assumptions and Scenarios Report",
                        "2025-inputs-assumptions-and-scenarios-report.pdf",
                        "https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2024/2025-iasr-scenarios/final-docs/2025-inputs-assumptions-and-scenarios-report.pdf?rev=63268acd3f044adb9f5f3a32b6880c27&sc_lang=en"),
        ISPReportTarget(:iasr_2025_addendum,
                        "Addendum to the 2025 Inputs, Assumptions and Scenarios Report",
                        "addendum-to-2025-inputs-assumptions-and-scenarios-report.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/draft-2026/addendum-to-the-2025-inputs-assumptions-and-scenarios-report.pdf"),
        ISPReportTarget(:isp_methodology_2025,
                        "ISP Methodology (June 2025)",
                        "2025-isp-methodology.pdf",
                        "https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2024/2026-isp-methodology/isp-methodology-june-2025.pdf"),
        ISPReportTarget(:appendix_a2_generation_storage,
                        "A2 ISP Development Opportunities",
                        "a2-isp-development-opportunities.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a2-isp-development-opportunities.pdf?rev=d81062e7cdcf4af8a04fbccdfc3c9fb4&sc_lang=en"),
        ISPReportTarget(:appendix_a3_rez,
                        "A3 Renewable Energy Zones",
                        "a3-renewable-energy-zones.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a3-renewable-energy-zones.pdf?la=en"),
        ISPReportTarget(:appendix_a4_operability,
                        "A4 System Operability",
                        "a4-system-operability.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a4-system-operability.pdf?la=en"),
        ISPReportTarget(:appendix_a6_cost_benefit,
                        "A6 Cost Benefit Analysis",
                        "a6-cost-benefit-analysis.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a6-cost-benefit-analysis.pdf?la=en"),
        ISPReportTarget(:appendix_a7_security,
                        "A7 System Security",
                        "a7-system-security.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a7-system-security.pdf?la=en"),
        ISPReportTarget(:integrated_system_plan_explainer,
                        "2026 Integrated System Plan - Explainer",
                        "2026-isp-explainer.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/aemo-2026-isp-explainer.pdf?rev=a1aa113a81194508a1aced90d26b1dd9&sc_lang=en"),
        ISPReportTarget(:integrated_system_plan_infographic,
                        "2026 Integrated System Plan - Infographic",
                        "2026-isp-infographic.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/2026-integrated-system-plan-infographic.pdf?rev=6568e9e8a4f34f5cb5f28a702d7fb453&sc_lang=en"),
        ISPReportTarget(:publication_webinar_presentation,
                        "2026 ISP Publication Webinar Presentation",
                        "2026-isp-publication-webinar-presentation.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/2026-isp-publication-webinar-presentation.pdf?rev=5d4743f20aff47699588354c1bfd76cc&sc_lang=en"),
        ISPReportTarget(:appendix_a1_stakeholder_engagement,
                        "A1 Stakeholder Engagement",
                        "a1-stakeholder-engagement.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a1-stakeholder-engagement.pdf?rev=fb67d2dee69042f3885d5f8a649267d6&sc_lang=en"),
        ISPReportTarget(:appendix_a5_network_investments,
                        "A5 Network Investments",
                        "a5-network-investments.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a5-network-investments.pdf?rev=a351f6c817484d79bc34f9a8e817f077&sc_lang=en"),
        ISPReportTarget(:appendix_a8_social_licence,
                        "A8 Social Licence",
                        "a8-social-licence.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a8-social-licence.pdf?rev=035a91c449f44bfc82a888a6770d9f90&sc_lang=en"),
        ISPReportTarget(:appendix_a9_demand_side_factors,
                        "A9 Demand Side Factors Statement",
                        "a9-demand-side-factors-statement.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a9-demand-side-factors-statement.pdf?rev=cfadf873c9934b46aecd670fdcd8995f&sc_lang=en"),
        ISPReportTarget(:appendix_a10_gas_development,
                        "A10 Gas Development Projections",
                        "a10-gas-development-projections.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a10-gas-development-projections.pdf?rev=e204886dac1c4f01a471e239723fb054&sc_lang=en"),
        ISPReportTarget(:consultation_summary,
                        "2026 ISP Consultation Summary Report",
                        "2026-isp-consultation-summary-report.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/supporting-materials/2026-isp-consultation-summary-report.pdf?rev=7982dc7041d4477d988d9f75485846d3&sc_lang=en"),
    )

    report_targets() = ISP_REPORT_TARGETS

    """
        download_reports(; outdir = "data/2026/pisp-reports", overwrite = false, throttle_seconds = nothing)

    Download the selected 2026 ISP report PDFs from AEMO. The command returns
    `nothing`; per-target failures are warned and do not stop later targets.
    """
    function download_reports(; outdir = DEFAULT_REPORTS_OUTDIR,
                              overwrite = false,
                              throttle_seconds = nothing)
        download_report_targets(ISP_REPORT_TARGETS;
                                outdir = outdir,
                                overwrite = overwrite,
                                throttle_seconds = throttle_seconds)
        return nothing
    end

end
