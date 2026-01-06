import os
import numpy as np
import matplotlib.pyplot as plt

# ============================================================
# ===================== USER SETTINGS ========================
# ============================================================

INPUT_DAT_FILE = r"E:\Boller CFD\AVIATION CFD\PressureProbeData\floorLine.pressure.dat"
OUTPUT_FOLDER  = r"E:\Boller CFD\AVIATION CFD\PressureProbeData\PressureOutput"

# ============================================================
# ===================== FUNCTIONS ============================
# ============================================================

def read_probe_dat(filepath):
    """
    Reads a space-delimited probe .dat file with a header line
    starting with '#'.

    Returns:
        time (np.ndarray)
        probe_data (dict): {probe_name: np.ndarray}
    """
    with open(filepath, "r") as f:
        lines = f.readlines()

    # Find header line
    header_line = None
    for line in lines:
        if line.strip().startswith("#"):
            header_line = line
            break

    if header_line is None:
        raise ValueError("No header line starting with '#' found in DAT file.")

    # Parse header
    header = header_line.replace("#", "").split()

    # Load numerical data
    data = np.loadtxt(filepath, comments="#")

    time = data[:, 0]
    probe_data = {}

    for i, name in enumerate(header[1:], start=1):
        probe_data[name] = data[:, i]

    return time, probe_data


def plot_and_save(time, probe_name, pressure, out_dir):
    """
    Generates and saves a pressure vs time plot for one probe.
    """
    plt.figure(figsize=(8, 5))
    plt.plot(time, pressure)
    plt.xlabel("Time [s]")
    plt.ylabel("Pressure")
    plt.title(f"Pressure vs Time – {probe_name}")
    plt.grid(True)

    out_path = os.path.join(out_dir, f"{probe_name}.jpg")
    plt.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close()

# ============================================================
# ========================== MAIN ============================
# ============================================================

def main():
    if not os.path.isfile(INPUT_DAT_FILE):
        raise FileNotFoundError(f"Input file not found:\n{INPUT_DAT_FILE}")

    os.makedirs(OUTPUT_FOLDER, exist_ok=True)

    time, probe_data = read_probe_dat(INPUT_DAT_FILE)

    for probe_name, pressure in probe_data.items():
        plot_and_save(time, probe_name, pressure, OUTPUT_FOLDER)

    print(f"\n✔ Generated {len(probe_data)} probe plots")
    print(f"✔ Output directory:\n{OUTPUT_FOLDER}\n")

if __name__ == "__main__":
    main()
