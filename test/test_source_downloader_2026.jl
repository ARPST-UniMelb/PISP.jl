# ISP 2026 source downloader (workbook / model / trace archives): target
# catalogue plus download / skip-existing / failure handling (mocked, no network).

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
