# # ISP 2024 and ISP 2026 downloaded source layout
#
# Each ISP edition keeps downloaded source material and extracted source
# directories under `data/<edition>/pisp-downloads/`. The ISP 2024 tree also
# contains `Auxiliary/`, which ParseISP generates from the outlook workbooks during
# preprocessing.
#
# The main directory roles are:
#
# ```text
# pisp-downloads/
# ├── Core/ or Core scenarios/   # extracted outlook workbooks
# ├── Sensitivities/             # extracted outlook sensitivities
# ├── Auxiliary/                 # ISP 2024 ParseISP-generated intermediates
# ├── Traces/                    # extracted trace inputs
# └── zip/                       # retained source archives
# ```
#
# The extracted `<edition> ISP Model/` directory is a separate model-archive
# source family.

const REPO_ROOT = normpath(
    get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..", "..")),
)
include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils
nothing #hide

# ## Observed outlook directories and source archives
#
# The inventory is read from the configured edition roots. The outlook column
# contains the top-level extracted workbook directories after separating
# `Auxiliary`, `Traces`, `zip`, manifest directories, and directories ending in
# `ISP Model` into their own source families. The archive column lists direct
# ZIP files under `pisp-downloads/zip/`; trace archives stored below
# `zip/Traces/` remain part of the trace source family.

download_layouts = [
    ParseISPDocUtils.inspect_download_layout(profile.label, profile.download_root)
    for profile in ParseISPDocUtils.edition_profiles(REPO_ROOT)
]

layout_rows = [
    Any[
        layout.edition,
        ParseISPDocUtils.markdown_items(layout.outlook_directories; nothing_text = "nothing"),
        ParseISPDocUtils.markdown_items(layout.source_archives; nothing_text = "nothing"),
    ]
    for layout in download_layouts
]

ParseISPDocUtils.markdown_table(
    ["Edition", "Extracted outlook directories", "Retained source archives"],
    layout_rows;
    nothing_text = "nothing",
)

# `Core` or `Core scenarios` and `Sensitivities` contain the extracted
# generation-and-storage-outlook workbooks. The other branches have distinct
# source or preprocessing roles.
