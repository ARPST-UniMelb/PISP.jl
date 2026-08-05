using Test

function reader_text(markdown::AbstractString)
    lines = split(markdown, '\n'; keepempty = true)
    kept = String[]
    fence_ticks = 0
    stripping = false
    for line in lines
        if fence_ticks > 0
            close_match = match(r"^(`{3,})\s*$", line)
            if close_match !== nothing && length(close_match.captures[1]) >= fence_ticks
                stripping || push!(kept, line)
                fence_ticks = 0
                stripping = false
            elseif !stripping
                push!(kept, line)
            end
            continue
        end
        open_match = match(r"^(`{3,})(.*)$", line)
        if open_match === nothing
            push!(kept, line)
            continue
        end
        fence_ticks = length(open_match.captures[1])
        stripping = occursin(r"^@(meta|setup)\b", open_match.captures[2])
        stripping || push!(kept, line)
    end
    return join(kept, '\n')
end

@testset "reader_text strips only non-rendered fenced blocks" begin
    @test reader_text("before\n```@meta\nhidden\n```\nafter") == "before\nafter"
    @test reader_text("before\n```@setup demo\nhidden\n```\nafter") == "before\nafter"
    @test reader_text("before\n```@raw html\n<div>visible</div>\n```\nafter") ==
          "before\n```@raw html\n<div>visible</div>\n```\nafter"
    @test reader_text("before\n````\n```@meta\n````\nafter") ==
          "before\n````\n```@meta\n````\nafter"
    @test reader_text("plain text, no fences") == "plain text, no fences"
end

const PROSE_WARNING_RULES = (
    (
        id = :generic_validation_hedge,
        pattern = r"(?i)\b(?:need|needs|require|requires)\b.{0,80}\b(?:validation|review)\b",
    ),
)

const PROSE_WARNING_EXCEPTIONS = Set{NamedTuple{(:path, :rule, :text), Tuple{String, Symbol, String}}}()

function warn_on_prose_candidates(relative_path::AbstractString, text::AbstractString)
    for (line_number, line) in enumerate(split(text, '\n'))
        candidate = strip(line)
        isempty(candidate) && continue
        for rule in PROSE_WARNING_RULES
            occursin(rule.pattern, candidate) || continue
            (path = relative_path, rule = rule.id, text = candidate) in PROSE_WARNING_EXCEPTIONS && continue
            @warn(
                "Documentation prose review candidate",
                path = relative_path,
                line = line_number,
                rule = rule.id,
                text = candidate,
            )
        end
    end
    return nothing
end
