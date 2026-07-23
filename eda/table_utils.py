"""Helpers for writing Python baseline EDA comparison tables.

Python EDA scripts should write baseline CSVs under
``eda/tables/python/<script_stem>/<table_name>.csv``. Julia EDA ports should
write the same table names under ``eda/tables/julia/<script_stem>/`` and then
run ``julia --project=. eda/compare_tables.jl <script_stem>``.

Comparison conventions:

- table filenames must match between Python and Julia outputs;
- column names and column order must match exactly;
- row order does not matter because the comparator sorts rows by all columns;
- missing values should be written as blank CSV fields;
- numeric values are compared by the Julia comparator with its configured
  absolute and relative tolerances.
"""

from pathlib import Path


TABLE_ROOT = Path(__file__).resolve().parent / "tables"


def table_dir(script_stem, producer="python", root=TABLE_ROOT):
    """Return the output directory for one producer and EDA script stem."""
    path = Path(root) / producer / script_stem
    path.mkdir(parents=True, exist_ok=True)
    return path


def table_path(script_stem, table_name, producer="python", root=TABLE_ROOT):
    """Return the CSV path for one named comparison table."""
    filename = table_name if str(table_name).endswith(".csv") else f"{table_name}.csv"
    return table_dir(script_stem, producer=producer, root=root) / filename


def write_table(frame, script_stem, table_name, producer="python", root=TABLE_ROOT, **to_csv_kwargs):
    """Write a DataFrame-like object as a comparison CSV and return its path."""
    path = table_path(script_stem, table_name, producer=producer, root=root)
    kwargs = {"index": False, "na_rep": ""}
    kwargs.update(to_csv_kwargs)
    frame.to_csv(path, **kwargs)
    return path
