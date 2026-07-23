#!/usr/bin/env julia

using CSV
using DataFrames
using Printf

const DEFAULT_ATOL = 1.0e-10
const DEFAULT_RTOL = 1.0e-8
const DEFAULT_MAX_DIAGNOSTICS = 50

struct CompareOptions
    tables_root::String
    atol::Float64
    rtol::Float64
    write_manifest::Bool
    max_diagnostics::Int
end

function usage()
    println("""
    Usage:
      julia --project=. eda/compare_tables.jl [options] <script_stem>
      julia --project=. eda/compare_tables.jl --self-test

    Compare ignored EDA table CSVs for one script stem:
      eda/tables/python/<script_stem>/*.csv
      eda/tables/julia/<script_stem>/*.csv

    Rules:
      - files: Python and Julia directories must contain the same CSV filenames.
      - columns: column names and column order must match exactly.
      - rows: row order is not significant; both tables are sorted by all columns
        using missing-aware canonical values before cell comparison.
      - missing values: blank CSV fields, Julia missing values, and parsed NaN
        values are equivalent to each other; missing is not equal to non-missing.
      - numeric values: numeric or numeric-looking cells pass when
        abs(julia - python) <= atol + rtol * abs(python).
      - non-numeric values: compared as exact strings after string conversion.

    Options:
      --help                 Show this help.
      --self-test            Run tiny generated match/mismatch checks.
      --tables-root PATH     Override table root. Default: eda/tables.
      --atol VALUE           Absolute tolerance. Default: $(DEFAULT_ATOL).
      --rtol VALUE           Relative tolerance. Default: $(DEFAULT_RTOL).
      --no-write-manifest    Print only; do not write eda/tables/compare output.
    """)
end

function parse_args(args)
    root = joinpath(@__DIR__, "tables")
    atol = DEFAULT_ATOL
    rtol = DEFAULT_RTOL
    write_manifest = true
    self_test = false
    stem = nothing

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--help" || arg == "-h"
            usage()
            exit(0)
        elseif arg == "--self-test"
            self_test = true
        elseif arg == "--no-write-manifest"
            write_manifest = false
        elseif arg == "--tables-root"
            i += 1
            i <= length(args) || error("--tables-root requires a path")
            root = args[i]
        elseif startswith(arg, "--tables-root=")
            root = split(arg, "=", limit = 2)[2]
        elseif arg == "--atol"
            i += 1
            i <= length(args) || error("--atol requires a value")
            atol = parse(Float64, args[i])
        elseif startswith(arg, "--atol=")
            atol = parse(Float64, split(arg, "=", limit = 2)[2])
        elseif arg == "--rtol"
            i += 1
            i <= length(args) || error("--rtol requires a value")
            rtol = parse(Float64, args[i])
        elseif startswith(arg, "--rtol=")
            rtol = parse(Float64, split(arg, "=", limit = 2)[2])
        elseif startswith(arg, "-")
            error("unknown option: $arg")
        elseif stem === nothing
            stem = arg
        else
            error("expected one script stem, got extra argument: $arg")
        end
        i += 1
    end

    options = CompareOptions(root, atol, rtol, write_manifest, DEFAULT_MAX_DIAGNOSTICS)
    return (; options, self_test, stem)
end

read_table(path) = CSV.read(path, DataFrame; missingstring = [""])

function csv_files(dir)
    isdir(dir) || return String[]
    return sort(filter(name -> endswith(lowercase(name), ".csv"), readdir(dir)))
end

is_missing_like(x) = x === missing || (x isa AbstractFloat && isnan(x))

function maybe_float(x)
    is_missing_like(x) && return missing
    x isa Number && return Float64(x)
    if x isa AbstractString
        stripped = strip(x)
        isempty(stripped) && return missing
        parsed = tryparse(Float64, stripped)
        parsed === nothing || return parsed
    end
    return nothing
end

function cell_text(x)
    is_missing_like(x) && return ""
    return string(x)
end

function sort_token(x)
    is_missing_like(x) && return ""
    if x isa Number
        return @sprintf("%.17g", Float64(x))
    end
    return string(x)
end

function sorted_rows(df::DataFrame)
    cols = names(df)
    keys = [join((sort_token(row[col]) for col in cols), "|") for row in eachrow(df)]
    return df[sortperm(keys), :]
end

function compare_cells(py, jl, options::CompareOptions)
    py_missing = is_missing_like(py)
    jl_missing = is_missing_like(jl)
    py_missing && jl_missing && return (; ok = true, reason = "missing", abs_diff = missing)
    py_missing != jl_missing && return (; ok = false, reason = "missing-vs-value", abs_diff = missing)

    py_num = maybe_float(py)
    jl_num = maybe_float(jl)
    if py_num !== nothing && py_num !== missing && jl_num !== nothing && jl_num !== missing
        if isinf(py_num) || isinf(jl_num)
            ok = py_num == jl_num
            return (; ok, reason = ok ? "numeric" : "infinite-mismatch", abs_diff = ok ? 0.0 : Inf)
        end
        diff = abs(jl_num - py_num)
        limit = options.atol + options.rtol * abs(py_num)
        return (; ok = diff <= limit, reason = "numeric", abs_diff = diff)
    end

    ok = cell_text(py) == cell_text(jl)
    return (; ok, reason = ok ? "string" : "string-mismatch", abs_diff = missing)
end

function diagnostics_path(compare_dir, filename)
    stem = replace(filename, r"\.csv$"i => "")
    return joinpath(compare_dir, "$(stem)_mismatches.csv")
end

function compare_file(py_path, jl_path, filename, compare_dir, options::CompareOptions)
    py = read_table(py_path)
    jl = read_table(jl_path)
    py_cols = names(py)
    jl_cols = names(jl)
    column_status = py_cols == jl_cols ? "match" : "mismatch"
    mismatch_count = 0
    diag_rows = DataFrame(
        row = Int[],
        column = String[],
        python = String[],
        julia = String[],
        reason = String[],
        abs_diff = Union{Missing, Float64}[],
    )

    if column_status == "match"
        py_sorted = sorted_rows(py)
        jl_sorted = sorted_rows(jl)
        shared_rows = min(nrow(py_sorted), nrow(jl_sorted))

        for row_idx in 1:shared_rows
            for col in py_cols
                result = compare_cells(py_sorted[row_idx, col], jl_sorted[row_idx, col], options)
                if !result.ok
                    mismatch_count += 1
                    if nrow(diag_rows) < options.max_diagnostics
                        push!(
                            diag_rows,
                            (
                                row_idx,
                                col,
                                cell_text(py_sorted[row_idx, col]),
                                cell_text(jl_sorted[row_idx, col]),
                                result.reason,
                                result.abs_diff,
                            ),
                        )
                    end
                end
            end
        end
        mismatch_count += abs(nrow(py_sorted) - nrow(jl_sorted))
    else
        mismatch_count += 1
    end

    diag_path = missing
    if options.write_manifest && nrow(diag_rows) > 0
        mkpath(compare_dir)
        diag_path = diagnostics_path(compare_dir, filename)
        CSV.write(diag_path, diag_rows)
    end

    status = (column_status == "match" && nrow(py) == nrow(jl) && mismatch_count == 0) ? "pass" : "fail"
    return (
        file = filename,
        status = status,
        python_path = py_path,
        julia_path = jl_path,
        python_rows = nrow(py),
        julia_rows = nrow(jl),
        python_columns = length(py_cols),
        julia_columns = length(jl_cols),
        column_status = column_status,
        atol = options.atol,
        rtol = options.rtol,
        mismatches = mismatch_count,
        diagnostics_path = diag_path,
    )
end

function missing_file_rows(filenames, py_dir, jl_dir, options::CompareOptions)
    rows = NamedTuple[]
    for filename in filenames
        py_path = joinpath(py_dir, filename)
        jl_path = joinpath(jl_dir, filename)
        push!(
            rows,
            (
                file = filename,
                status = isfile(py_path) ? "missing-julia" : "missing-python",
                python_path = py_path,
                julia_path = jl_path,
                python_rows = isfile(py_path) ? nrow(read_table(py_path)) : missing,
                julia_rows = isfile(jl_path) ? nrow(read_table(jl_path)) : missing,
                python_columns = isfile(py_path) ? length(names(read_table(py_path))) : missing,
                julia_columns = isfile(jl_path) ? length(names(read_table(jl_path))) : missing,
                column_status = "not-compared",
                atol = options.atol,
                rtol = options.rtol,
                mismatches = 1,
                diagnostics_path = missing,
            ),
        )
    end
    return rows
end

function compare_stem(stem::AbstractString, options::CompareOptions)
    py_dir = joinpath(options.tables_root, "python", stem)
    jl_dir = joinpath(options.tables_root, "julia", stem)
    compare_dir = joinpath(options.tables_root, "compare", stem)

    py_files = csv_files(py_dir)
    jl_files = csv_files(jl_dir)
    common = intersect(py_files, jl_files)
    missing_py = setdiff(jl_files, py_files)
    missing_jl = setdiff(py_files, jl_files)

    rows = NamedTuple[]
    append!(rows, missing_file_rows(missing_py, py_dir, jl_dir, options))
    append!(rows, missing_file_rows(missing_jl, py_dir, jl_dir, options))
    for filename in common
        push!(rows, compare_file(joinpath(py_dir, filename), joinpath(jl_dir, filename), filename, compare_dir, options))
    end

    if isempty(rows)
        push!(
            rows,
            (
                file = "",
                status = "no-files",
                python_path = py_dir,
                julia_path = jl_dir,
                python_rows = missing,
                julia_rows = missing,
                python_columns = missing,
                julia_columns = missing,
                column_status = "not-compared",
                atol = options.atol,
                rtol = options.rtol,
                mismatches = 1,
                diagnostics_path = missing,
            ),
        )
    end

    manifest = DataFrame(rows)
    if options.write_manifest
        mkpath(compare_dir)
        CSV.write(joinpath(compare_dir, "manifest.csv"), manifest)
    end
    return manifest
end

function print_manifest(stem, manifest::DataFrame, options::CompareOptions)
    total_files = nrow(manifest)
    failures = count(!=("pass"), manifest.status)
    mismatches = sum(skipmissing(manifest.mismatches))
    compact_cols = [
        :file,
        :status,
        :python_rows,
        :julia_rows,
        :python_columns,
        :julia_columns,
        :column_status,
        :mismatches,
        :diagnostics_path,
    ]
    compact = manifest[:, compact_cols]

    println("Comparison manifest for '$stem'")
    println("table root: ", options.tables_root)
    println("tolerance: atol=$(options.atol), rtol=$(options.rtol)")
    println("files: $total_files, failures: $failures, mismatches: $mismatches")
    println()
    show(stdout, compact; allrows = true, allcols = true, truncate = 80)
    println()
end

function write_self_test_table(path, rows)
    mkpath(dirname(path))
    CSV.write(path, DataFrame(rows))
end

function run_self_test()
    mktempdir() do root
        options = CompareOptions(root, DEFAULT_ATOL, DEFAULT_RTOL, true, DEFAULT_MAX_DIAGNOSTICS)

        write_self_test_table(
            joinpath(root, "python", "match_demo", "summary.csv"),
            [(id = 2, value = 2.0, label = "b", note = missing), (id = 1, value = 1.0, label = "a", note = "ok")],
        )
        write_self_test_table(
            joinpath(root, "julia", "match_demo", "summary.csv"),
            [(id = 1, value = 1.0 + 1.0e-12, label = "a", note = "ok"), (id = 2, value = 2.0, label = "b", note = missing)],
        )

        match_manifest = compare_stem("match_demo", options)
        match_ok = all(==("pass"), match_manifest.status)

        write_self_test_table(
            joinpath(root, "python", "mismatch_demo", "summary.csv"),
            [(id = 1, value = 1.0, label = "a")],
        )
        write_self_test_table(
            joinpath(root, "julia", "mismatch_demo", "summary.csv"),
            [(id = 1, value = 1.1, label = "a")],
        )

        mismatch_manifest = compare_stem("mismatch_demo", options)
        mismatch_caught = any(!=("pass"), mismatch_manifest.status)

        println("Self-test match manifest:")
        print_manifest("match_demo", match_manifest, options)
        println("Self-test mismatch manifest:")
        print_manifest("mismatch_demo", mismatch_manifest, options)

        if match_ok && mismatch_caught
            println("Self-test passed.")
            return true
        end
        println("Self-test failed.")
        return false
    end
end

function main(args)
    parsed = try
        parse_args(args)
    catch err
        println(stderr, err)
        println(stderr, "Run with --help for usage.")
        exit(2)
    end

    if parsed.self_test
        if parsed.stem !== nothing
            println(stderr, "--self-test does not accept a script stem")
            exit(2)
        end
        exit(run_self_test() ? 0 : 1)
    end

    if parsed.stem === nothing
        usage()
        exit(2)
    end

    manifest = compare_stem(parsed.stem, parsed.options)
    print_manifest(parsed.stem, manifest, parsed.options)
    exit(all(==("pass"), manifest.status) ? 0 : 1)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
