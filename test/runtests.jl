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

    @testset "ISP report downloader" begin
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

        @test isdefined(PISP, :download_isp_reports)
        @test PISP.download_isp_reports === report_downloader.download_isp_reports
        @test [(target.key, target.title, target.filename, target.url) for target in targets] == expected_targets
        @test all(target -> endswith(lowercase(target.filename), ".pdf"), targets)
        @test all(target -> startswith(target.url, "https://www.aemo.com.au/"), targets)

        mktempdir() do outdir
            target = targets[1]
            destination = joinpath(outdir, target.filename)
            mkpath(outdir)
            write(destination, "%PDF-1.7\\nexisting")
            calls = Ref(0)

            paths = report_downloader.download_report_targets([target];
                                                                outdir = outdir,
                                                                download_function = function (url, path; headers)
                                                                    calls[] += 1
                                                                    error("a valid existing PDF should be skipped")
                                                                end)

            @test paths == [destination]
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

            paths = report_downloader.download_report_targets([target];
                                                                outdir = outdir,
                                                                download_function = function (url, path; headers)
                                                                    calls[] += 1
                                                                    received_headers[] = headers
                                                                    write(path, "%PDF-1.7\\nreplacement")
                                                                    return path
                                                                end)

            @test paths == [destination]
            @test calls[] == 1
            @test received_headers[] == PISP.PISPScrapperUtils.DEFAULT_FILE_HEADERS
            @test read(destination, String) == "%PDF-1.7\\nreplacement"
            @test readdir(outdir) == [target.filename]
        end

        mktempdir() do outdir
            target = targets[3]
            destination = joinpath(outdir, target.filename)
            mkpath(outdir)
            existing = "%PDF-1.7\\nexisting"
            write(destination, existing)

            err = try
                report_downloader.download_report_targets([target];
                                                           outdir = outdir,
                                                           overwrite = true,
                                                           download_function = (url, path; headers) -> write(path, "not a PDF"))
                nothing
            catch caught
                caught
            end

            @test err isa ErrorException
            @test occursin(string(target.key), sprint(showerror, err))
            @test occursin(target.title, sprint(showerror, err))
            @test occursin(target.url, sprint(showerror, err))
            @test read(destination, String) == existing
            @test readdir(outdir) == [target.filename]
        end

        mktempdir() do outdir
            target = targets[4]
            err = try
                report_downloader.download_report_targets([target];
                                                           outdir = outdir,
                                                           download_function = (url, path; headers) -> error("request failed"))
                nothing
            catch caught
                caught
            end

            @test err isa ErrorException
            @test occursin(string(target.key), sprint(showerror, err))
            @test occursin(target.title, sprint(showerror, err))
            @test occursin(target.url, sprint(showerror, err))
            @test isempty(readdir(outdir))
        end

        mktempdir() do outdir
            target = targets[5]
            destination = joinpath(outdir, target.filename)
            mkpath(outdir)
            write(destination, "%PDF-1.7\\nexisting")
            calls = Ref(0)

            paths = report_downloader.download_report_targets([target];
                                                                outdir = outdir,
                                                                overwrite = true,
                                                                download_function = function (url, path; headers)
                                                                    calls[] += 1
                                                                    write(path, "%PDF-1.7\\nrefreshed")
                                                                    return path
                                                                end)

            @test paths == [destination]
            @test calls[] == 1
            @test read(destination, String) == "%PDF-1.7\\nrefreshed"
            @test readdir(outdir) == [target.filename]
        end
    end
end
