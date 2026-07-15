module ISP2024ReportDownloader

    using PISP.ISPReportDownloader: ISPReportTarget, download_report_targets

    export report_targets,
        download_reports

    const DEFAULT_REPORTS_OUTDIR = "data/pisp-reports"

    const ISP_REPORT_TARGETS = ISPReportTarget[
        ISPReportTarget(:plexos_model_instructions,
                        "2024 ISP PLEXOS Model Instructions",
                        "2024-isp-plexos-model-instructions.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/supporting-materials/2024-isp-plexos-model-instructions.pdf?la=en"),
        ISPReportTarget(:integrated_system_plan,
                        "2024 Integrated System Plan",
                        "2024-integrated-system-plan.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/2024-integrated-system-plan-isp.pdf?la=en"),
        ISPReportTarget(:iasr_2023,
                        "2023 Inputs, Assumptions and Scenarios Report",
                        "2023-inputs-assumptions-and-scenarios-report.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2023/2023-inputs-assumptions-and-scenarios-report.pdf?la=en"),
        ISPReportTarget(:iasr_2023_addendum,
                        "Addendum to the 2023 Inputs Assumptions and Scenarios Report",
                        "addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2023/addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf?la=en"),
        ISPReportTarget(:isp_methodology_2023,
                        "ISP Methodology (30 June 2023)",
                        "2023-isp-methodology.pdf",
                        "https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2023/isp-methodology-2023/isp-methodology_june-2023.pdf?la=en"),
        ISPReportTarget(:appendix_a2_generation_storage,
                        "A2 Generation and Storage Development Opportunities",
                        "a2-generation-and-storage-development-opportunities.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a2-generation-and-storage-development-opportunities.pdf?la=en"),
        ISPReportTarget(:appendix_a3_rez,
                        "A3 Renewable Energy Zones",
                        "a3-renewable-energy-zones.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a3-renewable-energy-zones.pdf?rev=12a046694eac41dc99031c43bbce35e0&sc_lang=en"),
        ISPReportTarget(:appendix_a4_operability,
                        "A4 System Operability",
                        "a4-system-operability.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a4-system-operability.pdf?la=en"),
        ISPReportTarget(:appendix_a6_cost_benefit,
                        "A6 Cost Benefit Analysis",
                        "a6-cost-benefit-analysis.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a6-cost-benefit-analysis.pdf?la=en"),
        ISPReportTarget(:appendix_a7_security,
                        "A7 System Security",
                        "a7-system-security.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a7-system-security.pdf?la=en"),
    ]

    report_targets() = copy(ISP_REPORT_TARGETS)

    """
        download_reports(; outdir = "data/pisp-reports", overwrite = false, throttle_seconds = nothing)

    Download the ten selected 2024 ISP report PDFs from AEMO. Existing valid PDFs are
    retained unless `overwrite = true`; invalid existing files are re-downloaded.
    The command returns `nothing`; per-target failures are warned and do not stop later targets.
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
