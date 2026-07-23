# ISP 2026 report downloader: target catalogue plus download / skip-existing /
# overwrite / failure handling (mocked download function, no network).

@testset "ISP 2026 report downloader" begin
    core = PISP.ISPReportDownloader
    report_downloader = PISP.ISP2026ReportDownloader
    targets = report_downloader.report_targets()
    expected_targets = [
        (:integrated_system_plan, "2026 Integrated System Plan", "2026-integrated-system-plan.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/2026-integrated-system-plan-isp.pdf?rev=7f5dfd18aa1b4a3aab704c424f75afd3&sc_lang=en"),
        (:plexos_model_instructions, "2026 ISP PLEXOS Model Instructions", "2026-isp-plexos-model-instructions.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/isp-model/2026-isp-plexos-model-instructions.pdf?la=en"),
        (:iasr_2025, "2025 Inputs, Assumptions and Scenarios Report", "2025-inputs-assumptions-and-scenarios-report.pdf", "https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2024/2025-iasr-scenarios/final-docs/2025-inputs-assumptions-and-scenarios-report.pdf?rev=63268acd3f044adb9f5f3a32b6880c27&sc_lang=en"),
        (:iasr_2025_addendum, "Addendum to the 2025 Inputs, Assumptions and Scenarios Report", "addendum-to-2025-inputs-assumptions-and-scenarios-report.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/draft-2026/addendum-to-the-2025-inputs-assumptions-and-scenarios-report.pdf"),
        (:isp_methodology_2025, "ISP Methodology (June 2025)", "2025-isp-methodology.pdf", "https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2024/2026-isp-methodology/isp-methodology-june-2025.pdf"),
        (:appendix_a2_generation_storage, "A2 ISP Development Opportunities", "a2-isp-development-opportunities.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a2-isp-development-opportunities.pdf?rev=d81062e7cdcf4af8a04fbccdfc3c9fb4&sc_lang=en"),
        (:appendix_a3_rez, "A3 Renewable Energy Zones", "a3-renewable-energy-zones.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a3-renewable-energy-zones.pdf?la=en"),
        (:appendix_a4_operability, "A4 System Operability", "a4-system-operability.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a4-system-operability.pdf?la=en"),
        (:appendix_a6_cost_benefit, "A6 Cost Benefit Analysis", "a6-cost-benefit-analysis.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a6-cost-benefit-analysis.pdf?la=en"),
        (:appendix_a7_security, "A7 System Security", "a7-system-security.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/appendices/a7-system-security.pdf?la=en"),
    ]

    @test isdefined(PISP, :download_ISP26_reports)
    @test PISP.download_ISP26_reports === report_downloader.download_reports
    @test !isdefined(PISP, :download_isp_reports)
    @test !isdefined(PISP, :download_isp2026_reports)
    @test [(target.key, target.title, target.filename, target.url) for target in targets] == expected_targets

    mktempdir() do outdir
        for target in targets
            write(joinpath(outdir, target.filename), "%PDF-1.7\nexisting")
        end

        @test PISP.download_ISP26_reports(outdir = outdir) === nothing
    end

    mktempdir() do outdir
        target = targets[1]
        destination = joinpath(outdir, target.filename)
        mkpath(outdir)
        write(destination, "%PDF-1.7\nexisting")
        calls = Ref(0)

        result = core.download_report_targets([target];
                                                             outdir = outdir,
                                                             download_function = function (url, path; headers)
                                                                 calls[] += 1
                                                                 error("a valid existing PDF should be skipped")
                                                             end)

        @test result.paths == [destination]
        @test isempty(result.failures)
        @test calls[] == 0
    end

    mktempdir() do outdir
        target = targets[2]
        destination = joinpath(outdir, target.filename)
        mkpath(outdir)
        write(destination, "not a PDF")
        calls = Ref(0)

        result = core.download_report_targets([target];
                                                             outdir = outdir,
                                                             download_function = function (url, path; headers)
                                                                 calls[] += 1
                                                                 write(path, "%PDF-1.7\nreplacement")
                                                                 return path
                                                             end)

        @test result.paths == [destination]
        @test isempty(result.failures)
        @test calls[] == 1
        @test read(destination, String) == "%PDF-1.7\nreplacement"
    end

    mktempdir() do outdir
        target = targets[3]
        destination = joinpath(outdir, target.filename)
        mkpath(outdir)
        existing = "%PDF-1.7\nexisting"
        write(destination, existing)

        result = core.download_report_targets([target];
                                                            outdir = outdir,
                                                            overwrite = true,
                                                            download_function = (url, path; headers) -> write(path, "not a PDF"))
        @test isempty(result.paths)
        @test length(result.failures) == 1
        @test read(destination, String) == existing
    end

    mktempdir() do outdir
        target = targets[4]

        result = core.download_report_targets([target];
                                                            outdir = outdir,
                                                            download_function = (url, path; headers) -> error("request failed"))
        @test isempty(result.paths)
        @test length(result.failures) == 1
        @test isempty(readdir(outdir))
    end

    mktempdir() do outdir
        target = targets[5]
        destination = joinpath(outdir, target.filename)
        mkpath(outdir)
        write(destination, "%PDF-1.7\nexisting")
        calls = Ref(0)

        result = core.download_report_targets([target];
                                                             outdir = outdir,
                                                             overwrite = true,
                                                             download_function = function (url, path; headers)
                                                                 calls[] += 1
                                                                 write(path, "%PDF-1.7\nrefreshed")
                                                                 return path
                                                             end)

        @test result.paths == [destination]
        @test isempty(result.failures)
        @test calls[] == 1
        @test read(destination, String) == "%PDF-1.7\nrefreshed"
    end

    mktempdir() do outdir
        failed_target, successful_target = targets[1:2]
        successful_destination = joinpath(outdir, successful_target.filename)

        result = core.download_report_targets([failed_target, successful_target];
                                                             outdir = outdir,
                                                             download_function = function (url, path; headers)
                                                                 url == failed_target.url && error("temporary upstream failure")
                                                                 write(path, "%PDF-1.7\nlater target")
                                                                 return path
                                                             end)

        @test result.paths == [successful_destination]
        @test length(result.failures) == 1
        @test result.failures[1].target === failed_target
        @test occursin("temporary upstream failure", result.failures[1].error)
        @test read(successful_destination, String) == "%PDF-1.7\nlater target"
    end
end
