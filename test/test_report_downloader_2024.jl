# ISP 2024 report downloader: target catalogue plus download / skip-existing /
# overwrite / failure handling (mocked download function, no network).

@testset "ISP 2024 report downloader" begin
    core = PISP.ISPReportDownloader
    report_downloader = PISP.ISP2024ReportDownloader
    targets = report_downloader.report_targets()
    expected_targets = [
        (:plexos_model_instructions, "2024 ISP PLEXOS Model Instructions", "2024-isp-plexos-model-instructions.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/supporting-materials/2024-isp-plexos-model-instructions.pdf?la=en"),
        (:integrated_system_plan, "2024 Integrated System Plan", "2024-integrated-system-plan.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/2024-integrated-system-plan-isp.pdf?la=en"),
        (:iasr_2023, "2023 Inputs, Assumptions and Scenarios Report", "2023-inputs-assumptions-and-scenarios-report.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2023/2023-inputs-assumptions-and-scenarios-report.pdf?la=en"),
        (:iasr_2023_addendum, "Addendum to the 2023 Inputs Assumptions and Scenarios Report", "addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2023/addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf?la=en"),
        (:isp_methodology_2023, "ISP Methodology (30 June 2023)", "2023-isp-methodology.pdf", "https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2023/isp-methodology-2023/isp-methodology_june-2023.pdf?la=en"),
        (:appendix_a2_generation_storage, "A2 Generation and Storage Development Opportunities", "a2-generation-and-storage-development-opportunities.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a2-generation-and-storage-development-opportunities.pdf?la=en"),
        (:appendix_a3_rez, "A3 Renewable Energy Zones", "a3-renewable-energy-zones.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a3-renewable-energy-zones.pdf?rev=12a046694eac41dc99031c43bbce35e0&sc_lang=en"),
        (:appendix_a4_operability, "A4 System Operability", "a4-system-operability.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a4-system-operability.pdf?la=en"),
        (:appendix_a6_cost_benefit, "A6 Cost Benefit Analysis", "a6-cost-benefit-analysis.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a6-cost-benefit-analysis.pdf?la=en"),
        (:appendix_a7_security, "A7 System Security", "a7-system-security.pdf", "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a7-system-security.pdf?la=en"),
    ]

    @test isdefined(PISP, :download_ISP24_reports)
    @test PISP.download_ISP24_reports === report_downloader.download_reports
    @test !isdefined(PISP, :download_isp_reports)
    @test !isdefined(PISP, :download_isp2026_reports)
    @test [(target.key, target.title, target.filename, target.url) for target in targets] == expected_targets
    @test all(target -> endswith(lowercase(target.filename), ".pdf"), targets)
    @test all(target -> startswith(target.url, "https://www.aemo.com.au/"), targets)

    mktempdir() do outdir
        for target in targets
            write(joinpath(outdir, target.filename), "%PDF-1.7\nexisting")
        end

        @test PISP.download_ISP24_reports(outdir = outdir) === nothing
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
        @test readdir(outdir) == [target.filename]
    end

    mktempdir() do outdir
        target = targets[2]
        destination = joinpath(outdir, target.filename)
        mkpath(outdir)
        write(destination, "not a PDF")
        calls = Ref(0)
        received_headers = Ref{Any}(nothing)

        result = core.download_report_targets([target];
                                                            outdir = outdir,
                                                            download_function = function (url, path; headers)
                                                                calls[] += 1
                                                                received_headers[] = headers
                                                                write(path, "%PDF-1.7\nreplacement")
                                                                return path
                                                            end)

        @test result.paths == [destination]
        @test isempty(result.failures)
        @test calls[] == 1
        @test received_headers[] == PISP.PISPScrapperUtils.DEFAULT_FILE_HEADERS
        @test read(destination, String) == "%PDF-1.7\nreplacement"
        @test readdir(outdir) == [target.filename]
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
        @test result.failures[1].target === target
        @test occursin("not a non-empty PDF", result.failures[1].error)
        @test read(destination, String) == existing
        @test readdir(outdir) == [target.filename]
    end

    mktempdir() do outdir
        target = targets[4]
        result = core.download_report_targets([target];
                                                            outdir = outdir,
                                                            download_function = (url, path; headers) -> error("request failed"))

        @test isempty(result.paths)
        @test length(result.failures) == 1
        @test result.failures[1].target === target
        @test occursin("request failed", result.failures[1].error)
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
        @test readdir(outdir) == [target.filename]
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
