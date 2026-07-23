# Zip extraction: extract_all_zips unpacks real archives and ignores
# macOS AppleDouble (._*) sidecar files.

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
