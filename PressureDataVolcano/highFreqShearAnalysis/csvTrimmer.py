#!/usr/bin/env python3
"""
Process CSV files and filter probes per location into new CSVs.

Naming convention: [Line Location]_[Plane].csv
- Only processes planes: _MP
- Extracts probe numbers defined per-location in a JSON config file
- Input CSV columns are expected in the format: [probenumber]_[variable]
  e.g. 000_pressure, 001_velocity, 023_temperature, ...
- Keeps only the specified probes and reorders columns so that all variables
  for the first probe appear first, then all for the second probe, etc.
- Saves filtered CSVs to a 'csv_output' subfolder within the input folder

Usage:
    python process_csv_files.py /path/to/csv/folder --config probes.json

Config file format (probes.json):
    {
        "LineA":   [0, 5, 23, 67, 99],
        "LineB":   [1, 12, 34, 56, 78],
        "default": [0, 1, 2, 3, 4]
    }

    Keys are location names as they appear in the CSV filenames.
    The optional "default" key is used for any location not explicitly listed.
    If a location has no entry and no default, it is skipped with a warning.
"""

import argparse
import json
import re
import sys
from pathlib import Path

import pandas as pd


# --- Configuration -----------------------------------------------------------

ALLOWED_PLANES    = {"_MP", "_z25", "_z75"}
PROBE_COL_PATTERN = re.compile(r"^(\d+)_(.+)$")   # e.g. "023_pressure"
OUTPUT_SUBFOLDER  = "csv_output"


# --- Helpers -----------------------------------------------------------------

def parse_filename(filename: str):
    """
    Parse a CSV filename into (location, plane).

    Expected format: [Location]_[Plane].csv
    E.g. "LineA_MP.csv" -> ("LineA", "_MP")

    Returns None if the filename doesn't match or should be skipped.
    """
    if not filename.lower().endswith(".csv"):
        return None

    stem = filename[:-4]  # strip ".csv"

    underscore_idx = stem.rfind("_")
    if underscore_idx == -1:
        return None

    location = stem[:underscore_idx]
    plane    = stem[underscore_idx:]   # includes leading '_'

    if plane not in ALLOWED_PLANES:
        return None

    return location, plane


def load_probe_config(config_path: Path) -> dict[str, list[int]]:
    """
    Load and validate a JSON probe config file.

    Returns a dict mapping location name (or "default") -> list of probe ints.
    """
    try:
        raw = json.loads(config_path.read_text())
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON in config file: {exc}") from exc

    if not isinstance(raw, dict):
        raise ValueError("Config file must be a JSON object mapping location names to probe lists.")

    result: dict[str, list[int]] = {}
    for location, probes in raw.items():
        if not isinstance(probes, list) or not all(isinstance(p, int) for p in probes):
            raise ValueError(f"Probe list for '{location}' must be a JSON array of integers.")
        if len(set(probes)) != len(probes):
            raise ValueError(f"Duplicate probe numbers found for '{location}'.")
        for p in probes:
            if not (0 <= p <= 499):
                raise ValueError(
                    f"Probe number {p} for '{location}' is out of range (0–499)."
                )
        result[location] = probes   # list — order is preserved

    return result


def get_probes_for_location(location: str, probe_config: dict[str, list[int]]) -> list[int] | None:
    """
    Return the probe list for a location, falling back to 'default' if present.
    Returns None if neither the location nor 'default' is configured.
    """
    if location in probe_config:
        return probe_config[location]
    if "default" in probe_config:
        return probe_config["default"]
    return None


def filter_and_reorder(df: pd.DataFrame, probe_numbers: list[int]) -> pd.DataFrame:
    """
    Keep the time column, any non-probe passthrough columns (e.g. nondimtime),
    and columns belonging to the specified probes.

    Columns are reordered as:
        time | <passthrough cols in original order> | <probe cols>

    Probe cols are grouped by probe (in config-specified order), with variables
    sorted alphabetically within each probe group.

    Probe columns are expected to follow the pattern: NNN_variable
    where NNN is a zero-padded (or unpadded) integer.
    """
    # Separate columns into: time, passthrough (non-probe non-time), and probe cols
    passthrough_cols: list[str] = []
    probe_cols: dict[int, list[tuple[str, str]]] = {}   # probe_int -> [(variable, col_name)]

    for col in df.columns:
        if col == "time":
            continue
        m = PROBE_COL_PATTERN.match(col)
        if m:
            probe_int = int(m.group(1))
            variable  = m.group(2)
            probe_cols.setdefault(probe_int, []).append((variable, col))
        else:
            passthrough_cols.append(col)

    if passthrough_cols:
        print(f"    Passthrough columns (preserved as-is): {', '.join(passthrough_cols)}")

    # Build ordered list of columns to keep
    ordered_cols = ["time"] + passthrough_cols
    missing_probes = []

    for num in probe_numbers:
        if num not in probe_cols:
            missing_probes.append(num)
            continue
        # Sort variables alphabetically within each probe
        for _variable, col_name in sorted(probe_cols[num], key=lambda x: x[0]):
            ordered_cols.append(col_name)

    if missing_probes:
        missing_fmt = ", ".join(f"{p:03d}" for p in sorted(missing_probes))
        print(
            f"    WARNING: probe(s) {missing_fmt} not found in this file; "
            "they will be absent from the output.",
            file=sys.stderr,
        )

    return df[ordered_cols]


# --- Core processing ---------------------------------------------------------

def process_folder(csv_folder: Path, probe_config: dict[str, list[int]]) -> None:
    csv_files = sorted(csv_folder.glob("*.csv"))
    if not csv_files:
        print(f"No .csv files found in {csv_folder}", file=sys.stderr)
        return

    # Create output directory
    output_dir = csv_folder / OUTPUT_SUBFOLDER
    output_dir.mkdir(exist_ok=True)
    print(f"Output directory: {output_dir}\n")

    for filepath in csv_files:
        parsed = parse_filename(filepath.name)
        if parsed is None:
            print(f"  Skipping: {filepath.name}")
            continue

        location, plane = parsed
        group_key = f"{location}{plane}"

        probe_numbers = get_probes_for_location(location, probe_config)
        if probe_numbers is None:
            print(
                f"  WARNING: No probe config for location '{location}' and no 'default' set; "
                f"skipping {filepath.name}.\n",
                file=sys.stderr,
            )
            continue

        probe_display = ", ".join(f"{p:03d}" for p in probe_numbers)
        print(f"Processing: {filepath.name}  (probes: {probe_display})")

        try:
            df = pd.read_csv(filepath)
        except Exception as exc:
            print(f"  ERROR reading {filepath.name}: {exc}", file=sys.stderr)
            continue

        # Normalise column names to lowercase
        df.columns = [c.lower() for c in df.columns]

        if "time" not in df.columns:
            print(
                f"  WARNING: 'time' column not found in {filepath.name}; skipping.",
                file=sys.stderr,
            )
            continue

        df = filter_and_reorder(df, probe_numbers)

        out_path = output_dir / filepath.name
        df.to_csv(out_path, index=False)
        print(f"  Saved: {out_path}  ({len(df)} rows, {len(df.columns)} columns)\n")

    print("Done.")


# --- Entry point -------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Filter and reorder probe columns in CSV files using a per-location probe config.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Config file format (probes.json):\n"
            "  {\n"
            '      "LineA":   [0, 5, 23, 67, 99],\n'
            '      "LineB":   [1, 12, 34, 56, 78],\n'
            '      "default": [0, 1, 2, 3, 4]\n'
            "  }\n\n"
            "  Keys are location names as they appear in the CSV filenames.\n"
            '  The optional "default" key applies to any unlisted location.\n\n'
            "Examples:\n"
            "  python process_csv_files.py /data/runs --config probes.json\n"
        ),
    )
    parser.add_argument(
        "folder",
        type=Path,
        help="Path to the folder containing the CSV files.",
    )
    parser.add_argument(
        "--config",
        type=Path,
        required=True,
        metavar="FILE",
        help="JSON config file mapping location names to lists of probe numbers (0–499).",
    )
    args = parser.parse_args()

    csv_folder = args.folder.resolve()
    if not csv_folder.is_dir():
        print(f"ERROR: '{csv_folder}' is not a directory.", file=sys.stderr)
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
        probe_display = ", ".join(f"{p:03d}" for p in probes)
        label = f"{loc}" if loc != "default" else "default (fallback)"
        print(f"  {label}: [{probe_display}]")
    print()

    print(f"Scanning folder: {csv_folder}\n")
    process_folder(csv_folder, probe_config)


if __name__ == "__main__":
    main()