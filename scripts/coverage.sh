# Remove previous coverage results
find src -type f -name '*.cov' -delete

# Run the complete test suite
julia --project=. -e 'using Pkg; Pkg.test(; coverage=true)'

# Process all generated coverage files
julia -e '
using Coverage, Coverage.LCOV

coverage = process_folder("src")
covered, total = get_summary(coverage)
percentage = total == 0 ? 0.0 : 100 * covered / total

println("Covered lines: $covered / $total")
println("Coverage: $(round(percentage; digits=2))%")

LCOV.writefile("coverage-lcov.info", coverage)
'
