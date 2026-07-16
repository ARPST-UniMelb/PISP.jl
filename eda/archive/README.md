# Archived Python EDA scripts

These are the original Python versions of `eda/01_data_loading` through
`eda/08_4006_composite_map`. They are superseded by the paired Julia scripts
of the same name and number directly under `eda/` (e.g. `eda/01_data_loading.jl`),
which are the current, actively maintained analysis producers.

They are kept here only as a frozen rollback/comparison baseline, not as part
of the active docs build or analysis workflow. Two independent visual audits
(2026-07-16) confirmed the Julia ports are a faithful replacement: 26/26
figure pairs pass and 57/57 comparable tables match at `atol=1e-10, rtol=1e-8`.

They still run exactly as before the move, from the repository root:

```sh
python eda/archive/01_data_loading.py
```

Paths inside these scripts (input traces, output figures/tables) are literal
strings relative to the working directory the script is invoked from, not to
the script's own location, so moving them here does not change where they
read from or write to — they still produce `eda/tables/python/<stem>/` and
`eda/figures/python/<stem>/`, the same trees `eda/compare_tables.jl` compares
against the Julia output. `eda/table_utils.py` deliberately stays at
`eda/table_utils.py` (not moved here) since its output-root path is derived
from its own file location; each archived script's import of it was patched
with an explicit `sys.path` entry so it still resolves after the move.
