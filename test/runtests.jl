using PISP
using Test

@testset "PISP.jl" begin
    @testset "extract_all_zips ignores AppleDouble files" begin
        zip_cmd = Sys.which("zip")
        unzip_cmd = Sys.which("unzip")

        if zip_cmd === nothing || unzip_cmd === nothing
            @test_skip "zip/unzip not available in test environment"
        else
            mktempdir() do tmpdir
                src_dir = joinpath(tmpdir, "src")
                dest_dir = joinpath(tmpdir, "dest")
                mkpath(src_dir)

                payload_path = joinpath(src_dir, "payload.txt")
                write(payload_path, "payload")

                archive_path = joinpath(src_dir, "archive.zip")
                cd(src_dir) do
                    run(`$(zip_cmd) -q archive.zip payload.txt`)
                end
                write(joinpath(src_dir, "._archive.zip"), "appledouble metadata")

                extracted_paths = PISP.PISPScrapperUtils.extract_all_zips(src_dir, dest_dir; skip_existing = false)

                @test extracted_paths == [normpath(dest_dir)]
                @test isfile(joinpath(dest_dir, "payload.txt"))
                @test !isfile(joinpath(dest_dir, "._archive.zip"))
            end
        end
    end

    @testset "ISP 2024 report downloader" begin
        report_downloader = PISP.ISPReportDownloader
        targets = report_downloader.isp_report_targets()
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
        @test PISP.download_ISP24_reports === report_downloader.download_isp_reports
        @test !isdefined(PISP, :download_isp_reports)
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

            result = report_downloader.download_report_targets([target];
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

            result = report_downloader.download_report_targets([target];
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

            result = report_downloader.download_report_targets([target];
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
            result = report_downloader.download_report_targets([target];
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

            result = report_downloader.download_report_targets([target];
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

            result = report_downloader.download_report_targets([failed_target, successful_target];
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

    @testset "ISP 2026 report downloader" begin
        report_downloader = PISP.ISP2026ReportDownloader
        targets = report_downloader.isp_report_targets()
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
        @test PISP.download_ISP26_reports === report_downloader.download_isp_reports
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

            result = report_downloader.download_report_targets([target];
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

            result = report_downloader.download_report_targets([target];
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

            result = report_downloader.download_report_targets([target];
                                                                outdir = outdir,
                                                                overwrite = true,
                                                                download_function = (url, path; headers) -> write(path, "not a PDF"))
            @test isempty(result.paths)
            @test length(result.failures) == 1
            @test read(destination, String) == existing
        end

        mktempdir() do outdir
            target = targets[4]

            result = report_downloader.download_report_targets([target];
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

            result = report_downloader.download_report_targets([target];
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

            result = report_downloader.download_report_targets([failed_target, successful_target];
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

    @testset "ISP 2026 source downloader" begin
        downloader = PISP.ISP2026FileDownloader
        targets = downloader.isp_file_targets()
        expected_targets = [
            (:isp26_inputs, "2026 ISP Inputs and Assumptions workbook", "2026-isp-inputs-and-assumptions-workbook.xlsm", "", "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/supporting-materials/2026-isp-inputs-and-assumptions-workbook.xlsm?rev=de6f5853cd5e4d5cbb06bc90bdf0e378&sc_lang=en"),
            (:isp26_ev_support, "2025 IASR EV workbook referenced by the final 2026 ISP workbook", "aemo-2025-iasr-ev-workbook.xlsx", "", "https://aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2024/2025-iasr-scenarios/final-docs/AEMO-2025-IASR-EV-workbook"),
            (:isp26_outlook, "2026 ISP generation and storage outlook", "2026-isp-generation-and-storage-outlook.zip", "zip", "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/supporting-materials/2026-isp-generation-and-storage-outlook.zip?rev=b64eda28a46b4d3eb3e4b3cbafea3f84&sc_lang=en"),
            (:isp26_model, "2026 ISP Model", "2026-isp-model.zip", "zip", "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/isp-model/2026-isp-model.zip?rev=78bfcf05ad414a8f9ba01f6a7c329fc2&sc_lang=en"),
            (:isp26_solar_traces, "2026 ISP Solar traces", "2026-isp-solar-traces.zip", "zip/Traces", "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/isp-model/2026-isp-solar-traces.zip?rev=3ad06155b7b94628bc77b90efe94588e&sc_lang=en"),
            (:isp26_wind_traces, "2026 ISP Wind traces", "2026-isp-wind-traces.zip", "zip/Traces", "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/isp-model/2026-isp-wind-traces.zip?rev=73674cd5bc6b4b7fbbc7d0e68ee0bc7c&sc_lang=en"),
        ]

        @test isdefined(PISP, :download_isp2026_assets)
        @test PISP.download_isp2026_assets === downloader.download_isp2026_files
        @test downloader.DEFAULT_FILES_OUTDIR == PISP.ISPFileDownloader.DEFAULT_FILES_OUTDIR
        @test [(target.key, target.title, target.filename, target.subdir, target.url) for target in targets] == expected_targets

        mktempdir() do outdir
            target = targets[1]
            destination = joinpath(outdir, target.filename)
            mkpath(outdir)
            write(destination, "existing")
            calls = Ref(0)

            paths = downloader.download_isp_files([target];
                                                   outdir = outdir,
                                                   download_function = function (url, path; headers)
                                                       calls[] += 1
                                                       error("an existing file should be skipped")
                                                   end)

            @test paths == [destination]
            @test calls[] == 0
        end

        mktempdir() do outdir
            target = targets[5]
            destination = joinpath(outdir, target.subdir, target.filename)
            calls = Ref(0)

            paths = downloader.download_isp_files([target];
                                                   outdir = outdir,
                                                   overwrite = true,
                                                   download_function = function (url, path; headers)
                                                       calls[] += 1
                                                       write(path, "replacement")
                                                       return path
                                                   end)

            @test paths == [destination]
            @test calls[] == 1
            @test read(destination, String) == "replacement"
        end

        mktempdir() do outdir
            target = targets[2]

            @test_throws ErrorException downloader.download_isp_files([target];
                                                                         outdir = outdir,
                                                                         download_function = (url, path; headers) -> error("request failed"))
            @test isempty(readdir(outdir))
        end
    end
end
