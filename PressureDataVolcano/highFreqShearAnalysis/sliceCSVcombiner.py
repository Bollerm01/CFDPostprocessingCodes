#!/usr/bin/env python3
"""
Process DAT files and combine variables per location into CSVs.

Naming convention: [Line Location]_[Plane].[Variable].dat
- Only processes planes: _mid, _zWp25, _zWp75
- Ignores variable: coords
- Extracts probe numbers defined per-location in a JSON config file
- Combines all variables for a given location+plane into one CSV
- Renames selected probe columns to: [3-digit probe number]_[variable]
- Saves CSVs to a 'csv_output' subfolder within the DAT folder

Usage:
    python process_dat_files.py /path/to/dat/folder --config probes.json

Config file format (probes.json):
    {
        "LineA":  [0, 5, 23, 67, 99],
        "LineB":  [1, 12, 34, 56, 78],
        "default": [0, 1, 2, 3, 4]
    }

    Keys are location names as they appear in the DAT filenames.
    The optional "default" key is used for any location not explicitly listed.
    If a location has no entry and no default, it is skipped with a warning.
"""

import argparse
import json
import re
import sys
from collections import defaultdict
from io import StringIO
from pathlib import Path

import pandas as pd


# --- Configuration -----------------------------------------------------------

ALLOWED_PLANES   = {"_MP"}
IGNORED_VARIABLES = {"coords"}
PROBE_PATTERN    = re.compile(r"^probe(\d+)$")
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
    plane    = location_plane[underscore_idx:]  # includes leading '_'

    if plane not in ALLOWED_PLANES:
        return None

    if variable in IGNORED_VARIABLES:
        return None

    return location, plane, variable


def load_probe_config(config_path: Path) -> dict[str, set[int]]:
    """
    Load and validate a JSON probe config file.

    Returns a dict mapping location name (or "default") -> set of probe ints.
    """
    try:
        raw = json.loads(config_path.read_text())
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON in config file: {exc}") from exc

    if not isinstance(raw, dict):
        raise ValueError("Config file must be a JSON object mapping location names to probe lists.")

    result: dict[str, set[int]] = {}
    for location, probes in raw.items():
        if not isinstance(probes, list) or not all(isinstance(p, int) for p in probes):
            raise ValueError(f"Probe list for '{location}' must be a JSON array of integers.")
        if len(probes) != 5:
            raise ValueError(
                f"Exactly 5 probe numbers required for '{location}'; got {len(probes)}."
            )
        if len(set(probes)) != len(probes):
            raise ValueError(f"Duplicate probe numbers found for '{location}'.")
        for p in probes:
            if not (0 <= p <= 99):
                raise ValueError(
                    f"Probe number {p} for '{location}' is out of range (0–99)."
                )
        result[location] = set(probes)

    return result


def get_probes_for_location(location: str, probe_config: dict[str, set[int]]) -> set[int] | None:
    """
    Return the probe set for a location, falling back to 'default' if present.
    Returns None if neither the location nor 'default' is configured.
    """
    if location in probe_config:
        return probe_config[location]
    if "default" in probe_config:
        return probe_config["default"]
    return None


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


# --- Core processing ---------------------------------------------------------

def process_folder(dat_folder: Path, probe_config: dict[str, set[int]]) -> None:
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

        probe_numbers = get_probes_for_location(location, probe_config)
        if probe_numbers is None:
            print(
                f"  WARNING: No probe config for location '{location}' and no 'default' set; "
                f"skipping group {group_key}.\n",
                file=sys.stderr,
            )
            continue

        probe_display = ", ".join(f"{p:03d}" for p in sorted(probe_numbers))
        print(f"Processing group: {group_key}  (probes: {probe_display})")

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

            # Warn about any requested probes missing from this file
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
        description="Combine DAT probe files into per-location CSVs with per-location probe selection.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Config file format (probes.json):\n"
            "  {\n"
            '      "LineA":   [0, 5, 23, 67, 99],\n'
            '      "LineB":   [1, 12, 34, 56, 78],\n'
            '      "default": [0, 1, 2, 3, 4]\n'
            "  }\n\n"
            "  Keys are location names as they appear in the DAT filenames.\n"
            '  The optional "default" key applies to any unlisted location.\n\n'
            "Examples:\n"
            "  python process_dat_files.py /data/runs --config probes.json\n"
        ),
    )
    parser.add_argument(
        "folder",
        type=Path,
        help="Path to the folder containing the DAT files.",
    )
    parser.add_argument(
        "--config",
        type=Path,
        required=True,
        metavar="FILE",
        help="JSON config file mapping location names to lists of 5 probe numbers (0–99).",
    )
    args = parser.parse_args()

    dat_folder = args.folder.resolve()
    if not dat_folder.is_dir():
        print(f"ERROR: '{dat_folder}' is not a directory.", file=sys.stderr)
        sys.exit(1)

    if not args.config.is_file():
        print(f"ERROR: Config file '{args.config}' not found.", file=sys.stderr)
        sys.exit(1)

    try:
        probe_config = load_probe_config(args.config)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)

    # Print the loaded config so the user can verify it
    print("Probe config loaded:")
    for loc, probes in sorted(probe_config.items()):
        probe_display = ", ".join(f"{p:03d}" for p in sorted(probes))
        label = f"{loc}" if loc != "default" else "default (fallback)"
        print(f"  {label}: [{probe_display}]")
    print()

    print(f"Scanning folder: {dat_folder}\n")
    process_folder(dat_folder, probe_config)


if __name__ == "__main__":
    main()