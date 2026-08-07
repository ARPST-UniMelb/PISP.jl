# Map SQL-like schema types to Julia types
const SQL2JL = Dict(
                    r"INTEGER"  => Int,
                    r"REAL"     => Float64,
                    r"BOOLEAN"  => Bool,
                    r"VARCHAR"  => String,
                    r"DATETIME" => DateTime,
)