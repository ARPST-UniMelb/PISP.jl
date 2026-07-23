#!/usr/bin/env bash
set -euo pipefail

# Remove stale coverage data.
find src -type f -name '*.cov' -delete
find test -type f -name '*.cov' -delete

# Run tests and collect coverage.
julia --project=. -e 'using Pkg; Pkg.test(; coverage=true)'

# Process coverage and generate reports.
# Currently, the `Uncovered lines` section is commented out due to low coverage.
julia -e '
using Coverage
using Coverage.LCOV

coverage = sort(process_folder("src"); by = fc -> fc.filename)

println("\nPer-file coverage")
println("=================")

for fc in coverage
    covered, total = get_summary(fc)
    percentage = total == 0 ? 0.0 : 100 * covered / total

    println(
        rpad(relpath(fc.filename), 60),
        lpad("$covered / $total", 12),
        lpad("$(round(percentage; digits=2))%", 10),
    )
end

covered, total = get_summary(coverage)
percentage = total == 0 ? 0.0 : 100 * covered / total

println("\nOverall coverage")
println("================")
println("Covered lines: $covered / $total")
println("Coverage: $(round(percentage; digits=2))%")

# println("\nUncovered lines")
# println("================")

# for fc in coverage
#     missed = findall(==(0), fc.coverage)
#     isempty(missed) && continue

#     source_lines = split(fc.source, '\''\n'\''; keepempty = true)

#     println("\n$(relpath(fc.filename))")

#     for line_number in missed
#         source = line_number <= length(source_lines) ?
#             strip(source_lines[line_number]) : ""

#         println(
#             lpad(line_number, 6),
#             " | ",
#             source,
#         )
#     end
# end

LCOV.writefile("coverage-lcov.info", coverage)

println("\nLCOV report: coverage-lcov.info")
'
