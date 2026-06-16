#!/usr/bin/env python3
"""
Process DAT files and combine variables per location into CSVs.

Naming convention: [Line Location]_[Plane].[Variable].dat
- Only processes planes: _MP
- Ignores variable: coords
- Only extracts the probe numbers specified via --probes
- Combines all variables for a given location+plane into one CSV
- Renames selected probe columns to: [3-digit probe number]_[variable]
- Saves CSVs to a 'csv_output' subfolder within the DAT folder

Usage:
    python process_dat_files.py /path/to/dat/folder --probes 0 5 23 67 99
"""

import argparse
import re
import sys
from collections import defaultdict
from io import StringIO
from pathlib import Path

import pandas as pd


# --- Configuration -----------------------------------------------------------

ALLOWED_PLANES = {"_MP"}
IGNORED_VARIABLES = {"coords"}
PROBE_PATTERN = re.compile(r"^probe(\d+)$")
OUTPUT_SUBFOLDER = "csv_output"


# --- Helpers -----------------------------------------------------------------

def parse_filename(filename: str):
    """
    Parse a DAT filename into (location, plane, variable).

    Expected format: [Location]_[Plane].[Variable].dat
    E.g. "LineA_mid.pressure.dat" -> ("LineA", "_mid", "pressure")

    Returns None if the filename doesn't match or should be skipped.
    """
    stem = filename[:-4] if filename.lower().endswith(".dat") else None
    if stem is None:
        return None

    if "." not in stem:
        return None

    dot_idx = stem.index(".")
    location_plane = stem[:dot_idx]
    variable = stem[dot_idx + 1:]

    # The plane is everything from the last underscore onward
    underscore_idx = location_plane.rfind("_")
    if underscore_idx == -1:
        return None

    location = location_plane[:underscore_idx]
    plane = location_plane[underscore_idx:]  # includes leading '_'

    if plane not in ALLOWED_PLANES:
        return None

    if variable in IGNORED_VARIABLES:
        return None

    return location, plane, variable


def read_dat_file(filepath: Path) -> pd.DataFrame:
    """
    Read a whitespace-delimited DAT file where the header line is prefixed
    with '#'.

    Format example:
        #    time    probe00000    probe00001    ...
           6.119e-02   6.064e+02   5.410e+02   ...

    The '#' is stripped from the header and used as column names; all
    subsequent non-comment lines are data rows.
    """
    header = None
    data_lines = []

    with filepath.open() as fh:
        for line in fh:
            stripped = line.strip()
            if not stripped:
                continue
            if stripped.startswith("#"):
                # Use the last comment line before data as the header
                header = stripped.lstrip("#").split()
            else:
                data_lines.append(stripped)

    if header is None:
        raise ValueError(f"No header line (starting with '#') found in {filepath}")

    data_text = "\n".join(data_lines)
    df = pd.read_csv(StringIO(data_text), sep=r"\s+", header=None, names=header, engine="python")
    return df


def select_and_rename_probes(df: pd.DataFrame, variable: str, probe_numbers: set[int]) -> pd.DataFrame:
    """
    Keep only the time column and the specified probe columns, renaming
    each selected probe from 'probeNNNNN' to 'NNN_variable'.
    """
    rename_map = {}
    selected_probe_cols = []

    for col in df.columns:
        m = PROBE_PATTERN.match(col)
        if m:
            num = int(m.group(1))
            if num in probe_numbers:
                new_name = f"{num:03d}_{variable}"
                rename_map[col] = new_name
                selected_probe_cols.append(new_name)

    df = df.rename(columns=rename_map)
    return df[["time"] + selected_probe_cols]


def validate_probes(probe_numbers: list[int]) -> set[int]:
    """Validate that probe numbers are in range 0–99 and there are exactly 5."""
    if len(probe_numbers) != 5:
        raise ValueError(f"Exactly 5 probe numbers required; got {len(probe_numbers)}.")
    for p in probe_numbers:
        if not (0 <= p <= 99):
            raise ValueError(f"Probe number {p} is out of range (0–99).")
    if len(set(probe_numbers)) != len(probe_numbers):
        raise ValueError("Duplicate probe numbers are not allowed.")
    return set(probe_numbers)


# --- Core processing ---------------------------------------------------------

def process_folder(dat_folder: Path, probe_numbers: set[int]) -> None:
    probe_display = ", ".join(f"{p:03d}" for p in sorted(probe_numbers))
    print(f"Selected probes: {probe_display}\n")

    # Collect DAT files grouped by (location, plane)
    groups: dict[tuple[str, str], list[tuple[str, Path]]] = defaultdict(list)

    dat_files = list(dat_folder.glob("*.dat"))
    if not dat_files:
        print(f"No .dat files found in {dat_folder}", file=sys.stderr)
        return

    for filepath in sorted(dat_files):
        parsed = parse_filename(filepath.name)
        if parsed is None:
            print(f"  Skipping: {filepath.name}")
            continue
        location, plane, variable = parsed
        groups[(location, plane)].append((variable, filepath))

    if not groups:
        print("No matching DAT files to process (check plane/variable filters).")
        return

    # Create output directory
    output_dir = dat_folder / OUTPUT_SUBFOLDER
    output_dir.mkdir(exist_ok=True)
    print(f"Output directory: {output_dir}\n")

    # Process each (location, plane) group
    for (location, plane), var_files in sorted(groups.items()):
        group_key = f"{location}{plane}"
        print(f"Processing group: {group_key}")

        merged_df: pd.DataFrame | None = None

        for variable, filepath in sorted(var_files, key=lambda x: x[0]):
            print(f"  Reading variable '{variable}' from {filepath.name}")
            try:
                df = read_dat_file(filepath)
            except Exception as exc:
                print(f"    ERROR reading {filepath.name}: {exc}", file=sys.stderr)
                continue

            # Normalise column names to lowercase
            df.columns = [c.lower() for c in df.columns]

            if "time" not in df.columns:
                print(
                    f"    WARNING: 'time' column not found in {filepath.name}; skipping.",
                    file=sys.stderr,
                )
                continue

            # Check that the requested probes actually exist in this file
            available = {int(m.group(1)) for c in df.columns if (m := PROBE_PATTERN.match(c))}
            missing = probe_numbers - available
            if missing:
                missing_fmt = ", ".join(f"{p:03d}" for p in sorted(missing))
                print(
                    f"    WARNING: probe(s) {missing_fmt} not found in {filepath.name}; "
                    "they will be absent from this variable's contribution.",
                    file=sys.stderr,
                )

            df = select_and_rename_probes(df, variable, probe_numbers)

            if merged_df is None:
                merged_df = df
            else:
                merged_df = pd.merge(merged_df, df, on="time", how="outer")

        if merged_df is None:
            print(f"  No data merged for group {group_key}; skipping.\n")
            continue

        # Sort by time for a clean output
        merged_df = merged_df.sort_values("time").reset_index(drop=True)

        # Sort data columns by probe number then variable name
        data_cols = [c for c in merged_df.columns if c != "time"]
        data_cols.sort(key=lambda c: (int(c.split("_")[0]), c.split("_", 1)[1]))
        merged_df = merged_df[["time"] + data_cols]

        csv_name = f"{group_key}.csv"
        csv_path = output_dir / csv_name
        merged_df.to_csv(csv_path, index=False)
        print(f"  Saved: {csv_path}  ({len(merged_df)} rows, {len(merged_df.columns)} columns)\n")

    print("Done.")


# --- Entry point -------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Combine DAT probe files into per-location CSVs, extracting specified probes.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  python process_dat_files.py /data/runs --probes 0 5 23 67 99\n"
            "  python process_dat_files.py /data/runs --probes 1 2 3 4 5\n"
        ),
    )
    parser.add_argument(
        "folder",
        type=Path,
        help="Path to the folder containing the DAT files.",
    )
    parser.add_argument(
        "--probes",
        type=int,
        nargs=5,
        required=True,
        metavar=("P1", "P2", "P3", "P4", "P5"),
        help="Exactly 5 probe numbers to extract (0–99), e.g. --probes 0 5 23 67 99",
    )
    args = parser.parse_args()

    dat_folder = args.folder.resolve()
    if not dat_folder.is_dir():
        print(f"ERROR: '{dat_folder}' is not a directory.", file=sys.stderr)
        sys.exit(1)

    try:
        probe_numbers = validate_probes(args.probes)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)

    print(f"Scanning folder: {dat_folder}\n")
    process_folder(dat_folder, probe_numbers)


if __name__ == "__main__":
    main()