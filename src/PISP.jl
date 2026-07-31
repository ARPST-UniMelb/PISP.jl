module PISP
    using Dates
    using DataFrames
    using OrderedCollections
    using XLSX
    using CSV
    using Arrow
    export DataFrames

    include("PISPdatamodel.jl")
    include("PISPstructures.jl")
    include("PISPsource_specs.jl")
    include("PISPutils.jl")
    include("PISPparameters.jl")
    include("PISPparsers.jl")
    include("PISPscrappers.jl")

    export SourceSpec,
        XlsxSourceSpec,
        CsvSourceSpec,
        ColumnSpec,
        SourceSpecRegistry,
        SourceSpecDiff,
        SOURCE_SPECS,
        register_source_specs!,
        source_specs,
        source_spec,
        source_spec_registry,
        resolve_source_pattern,
        source_path,
        compare_source_specs,
        source_spec_records,
        source_spec_rows,
        source_spec_diff_rows,
        export_source_specs,
        export_source_spec_diff,
        read_xlsx_rows,
        read_xlsx_with_header,
        read_csv_source,
        validate_source_columns,
        build_pipeline,
        download_ISP24_reports,
        download_ISP26_reports,
        download_isp2026_assets
end
