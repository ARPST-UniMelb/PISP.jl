module ISP2026ReportDownloader

    using PISP.ISPReportDownloader: ISPReportTarget, download_report_targets

    const DEFAULT_REPORTS_OUTDIR = "data/2026/pisp-reports"

    const ISP_REPORT_TARGETS = ISPReportTarget[
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
    ]

    isp_report_targets() = copy(ISP_REPORT_TARGETS)

    """
        download_isp_reports(; outdir = "data/2026/pisp-reports", overwrite = false, throttle_seconds = nothing)

    Download the ten selected 2026 ISP report PDFs from AEMO. The returned result
    contains every successful path and any failures after all targets are attempted.
    """
    function download_isp_reports(; outdir = DEFAULT_REPORTS_OUTDIR,
                                  overwrite = false,
                                  throttle_seconds = nothing)
        download_report_targets(ISP_REPORT_TARGETS;
                                outdir = outdir,
                                overwrite = overwrite,
                                throttle_seconds = throttle_seconds)
        return nothing
    end

end
