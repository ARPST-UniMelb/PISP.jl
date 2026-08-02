# # ISP 2024: Build-out defaults
#
# Optional build-out rows combine a small workbook contract with package-defined generator and storage defaults.
# The workbook identifies the technology, subregion, capacity, build year, and unit count.
# PISP supplies the remaining static-row values, generates identifiers and schedule keys, and computes capacity-dependent fields.
#
# The tables below read the current PISP dictionaries and build-out mappings directly.
# "Not defined in PISP" means that the active package supplies a value but does not define the field's meaning or unit.

using PISP
using DataFrames

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const BUILDOUT_PARSER = joinpath(REPO_ROOT, "src", "parsers", "PISP-2024buildout.jl")
PISPDocUtils.validate_buildout_defaults_contract(BUILDOUT_PARSER)
nothing #hide

# ## Source status
#
# The build-out workbook supplies `tech`, `subregion`, `capacity`, `year`, and `n`. The parser generates or looks up identifiers and locations, calculates capacity-dependent fields, and obtains the remaining values from `PISP.params_buildout_bess` or `PISP.params_buildout_gen`.
#
# Those template dictionaries are the current code authority for the displayed defaults. PISP does not encode an original external source for every numeric template value, so this page reports them as package-defined defaults rather than assigning an unsupported report or workbook citation. Fields labelled "Not defined in PISP" retain unverified meaning or units until a source or package contract establishes them.

# ## Supported workbook technology labels
#
# A workbook label selects one PISP template. Storage labels also select the duration used to calculate `ESS.emax`.

reference_tables = PISPDocUtils.buildout_reference_tables()
PISPDocUtils.markdown_table(reference_tables.technology; allow_markdown_in_cells = true)

# ## How a build-out row is assembled
#
# PISP does not copy a complete static row from the workbook. Each output field has one of four origins: workbook input, generated or looked-up identity, an explicit calculation, or a package template.

PISPDocUtils.markdown_table(reference_tables.origins; allow_markdown_in_cells = true)

# ## Template placeholders and their applied sources
#
# `nothing` values in the raw template dictionaries are placeholders. The parser replaces or bypasses them using workbook values, generated identifiers, bus lookup, capacity calculations, or explicit coordinates.

PISPDocUtils.markdown_table(reference_tables.placeholders; allow_markdown_in_cells = true)

# ## Storage defaults
#
# These fields are written from the selected entry in `PISP.params_buildout_bess` to every new `ESS` static row.
# The static `n = 0` value is distinct from the time-varying unit count supplied by the workbook.

# ### Defaults shared by every storage template

PISPDocUtils.markdown_table(reference_tables.ess_common; allow_markdown_in_cells = true)

# ### Defaults that vary by storage technology
#
# Meaning and unit of each varying field:

PISPDocUtils.markdown_table(reference_tables.ess_varying_fields; allow_markdown_in_cells = true)

# Value of each varying field by storage technology:

PISPDocUtils.markdown_table(reference_tables.ess_varying_values; allow_markdown_in_cells = true)

# ## Generator defaults
#
# These fields are written from the selected entry in `PISP.params_buildout_gen` to every new `Generator` static row.
# The static `n = 0` value is distinct from the time-varying unit count supplied by the workbook.

# ### Defaults shared by every generator template

PISPDocUtils.markdown_table(reference_tables.gen_common; allow_markdown_in_cells = true)

# ### Defaults that vary by generator technology

PISPDocUtils.markdown_table(reference_tables.gen_varying; allow_markdown_in_cells = true)

# ## Override and derivation rules
#
# The workbook cannot override template fields directly. Changing a template field requires changing PISP's build-out parameter dictionaries.
# Capacity affects `capacity`, `pmax`, and, for storage, `lmax` and `emax`; subregion affects `id_bus`; year and `n` affect only the unit-count schedule.
# Uniform mode applies one workbook sheet to every ISP scenario. Scenario-specific mode reads one sheet per scenario, unions static assets by generated name, and keeps each scenario's unit-count schedule separate.
#
# See the [preprocessing workflow](../../../editions/isp2024-preprocessing.md) for the stage at which build-outs are inserted, [assumptions and scope](../../../assumptions.md) for the modelling boundary, and [output tables](output-tables.md) for the complete static and schedule schemas.
