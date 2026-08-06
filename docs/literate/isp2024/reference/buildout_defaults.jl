# # ISP 2024: Build-out defaults
#
# Optional build-out rows combine a user-supplied workbook with the generator and storage defaults used by ParseISP.
# The workbook supplies the technology, subregion, capacity, build year, and unit count.
# ParseISP uses the selected template to complete the static asset row and create the corresponding unit-count schedule.

using ParseISP
using DataFrames

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const BUILDOUT_PARSER = joinpath(REPO_ROOT, "src", "parsers", "ParseISP-2024buildout.jl")
ParseISPDocUtils.validate_buildout_defaults_contract(BUILDOUT_PARSER)
nothing #hide

# ## Parameter sources
#
# The build-out workbook is user-supplied and is separate from AEMO's ISP workbooks.
# Stored template values are classified as `ISP workbook`, `Published report`, or `ParseISP default`.
# `ParseISP default` denotes a value currently maintained in ParseISP whose upstream workbook or report source has not yet been identified.
#
# Field meanings and units are defined in the [output tables](output-tables.md).

# ## Supported build-out technology labels
#
# A workbook label selects one ParseISP template. Storage labels also select the duration used to calculate `ESS.emax`.

reference_tables = ParseISPDocUtils.buildout_reference_tables()
ParseISPDocUtils.markdown_table(reference_tables.technology; allow_markdown_in_cells = true)

# ## How a build-out row is assembled
#
# ParseISP does not copy a complete static row from the workbook. Each output field is supplied by the build-out workbook, generated or looked up, calculated explicitly, or read from the selected stored defaults.

ParseISPDocUtils.markdown_table(reference_tables.origins; allow_markdown_in_cells = true)

# ## Template placeholders and applied rules
#
# `nothing` values in the raw template dictionaries are placeholders. The parser replaces them using workbook values, generated identifiers, bus lookup, capacity calculations, or explicit coordinates.

ParseISPDocUtils.markdown_table(reference_tables.placeholders; allow_markdown_in_cells = true)

# ## Storage defaults
#
# These fields are written from the selected entry in `ParseISP.params_buildout_bess` to every new `ESS` static row.
# The static `n = 0` value is distinct from the time-varying unit count supplied by the workbook.

# ### Defaults shared by every storage template

ParseISPDocUtils.markdown_table(reference_tables.ess_common; allow_markdown_in_cells = true)

# ### Defaults that vary by storage technology
#
# Source of each varying field:

ParseISPDocUtils.markdown_table(reference_tables.ess_varying_fields; allow_markdown_in_cells = true)

# Value of each varying field by storage technology:

ParseISPDocUtils.markdown_table(reference_tables.ess_varying_values; allow_markdown_in_cells = true)

# ## Generator defaults
#
# These fields are written from the selected entry in `ParseISP.params_buildout_gen` to every new `Generator` static row.
# The static `n = 0` value is distinct from the time-varying unit count supplied by the workbook.

# ### Defaults shared by every generator template

ParseISPDocUtils.markdown_table(reference_tables.gen_common; allow_markdown_in_cells = true)

# ### Defaults that vary by generator technology

ParseISPDocUtils.markdown_table(reference_tables.gen_varying; allow_markdown_in_cells = true)

# ## Override and derivation rules
#
# The workbook cannot override stored defaults directly. Changing one requires changing ParseISP's build-out parameter dictionaries.
# Capacity affects `capacity`, `pmax`, and, for storage, `lmax` and `emax`; subregion affects `id_bus`; year and `n` affect only the unit-count schedule.
# Uniform mode applies one workbook sheet to every ISP scenario. Scenario-specific mode reads one sheet per scenario, unions static assets by generated name, and keeps each scenario's unit-count schedule separate.
#
# See the [preprocessing workflow](../../../editions/isp2024-preprocessing.md) for the stage at which build-outs are inserted, [assumptions and scope](../../../assumptions.md) for the modelling boundary, and [output tables](output-tables.md) for the complete static and schedule schemas.
