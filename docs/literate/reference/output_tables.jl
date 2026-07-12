# # Output tables
#
# A PISP build writes static asset tables once per build and time-varying schedule tables under one or more schedule directories. The tables below list the current output names, identifiers, relationships, and columns.

using PISP
using DataFrames

function container_inventory(container)
    rows = NamedTuple[]
    for field in fieldnames(typeof(container))
        table = getfield(container, field)
        table isa DataFrame || continue
        output_name = get(PISP.alt_names, field, string(field))
        columns = string.(names(table))
        id_columns = filter(name -> startswith(name, "id"), columns)
        relationship_ids = length(id_columns) > 1 ? id_columns[2:end] : String[]
        push!(
            rows,
            (
                output_table = output_name,
                container_field = string(field),
                primary_id = isempty(id_columns) ? "" : first(id_columns),
                relationship_ids = join(relationship_ids, ", "),
                columns = join(columns, ", "),
            ),
        )
    end
    return DataFrame(rows)
end

_tc, static_container, schedule_container = PISP.initialise_time_structures()

# ## Static asset tables
#
# Static tables define asset identity and time-invariant attributes. Schedule rows should be joined back to these tables through the relationship identifier shown in the generated schema.

static_tables = container_inventory(static_container)
static_tables

# ## Schedule tables
#
# Schedule tables carry scenario- and time-dependent values. The output filename is taken from the same `alt_names` mapping used by the CSV and Arrow writers.

schedule_tables = container_inventory(schedule_container)
schedule_tables

# ## Output directory pattern
#
# Static tables are written directly under a format directory such as `csv/` or `arrow/`. Time-varying tables are written under `schedule-<tag>/`, where the tag is either a planning year or an explicit date range.
#
# A schedule is an overlay, not an independent asset inventory. Reconstruct a system state by selecting the required scenario and timestamp, joining the schedule to its static table, and replacing only the quantity represented by the schedule.

# ## Using the output tables
#
# - Identifier columns define table relationships; row order does not.
# - `scenario` and `date` are part of the schedule key even when an analysis displays only one scenario or period.
# - Units follow the represented quantity: power and transfer limits are in MW, storage energy and inflow quantities are in MWh, and unit-count schedules are counts.
# - Solar and wind schedule values should not be normalised by static `Generator.pmax` without applying the modelling convention described in [Assumptions and scope](@ref).
