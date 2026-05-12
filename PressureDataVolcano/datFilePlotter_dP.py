import os
import numpy as np
import matplotlib.pyplot as plt
import csv

# ============================================================
# ===================== USER SETTINGS ========================
# ============================================================

INPUT_DAT_FILE = r"E:\Boller CFD\AVIATION CFD\PressureProbeData\floorLine.pressure.dat"
OUTPUT_FOLDER  = r"E:\Boller CFD\AVIATION CFD\PressureProbeData\PressureOutput_FloorDP_11May26"

REFERENCE_PRESSURE_PA = 19777.0   # Mean / zero-reference pressure

PA_TO_PSI = 1.0 / 6894.757

# ============================================================
# ===================== FUNCTIONS ============================
# ============================================================

def read_probe_dat(filepath):
    """
    Reads OpenFOAM-style probe .dat file.

    Returns:
        time (np.ndarray)
        probe_data (dict)
    """

    with open(filepath, "r") as f:
        lines = f.readlines()

    header_line = None
    for line in lines:
        if line.strip().startswith("#"):
            header_line = line
            break

    if header_line is None:
        raise ValueError("No header line found.")

    header = header_line.replace("#", "").split()

    data = np.loadtxt(filepath, comments="#")

    time = data[:, 0]

    probe_data = {}

    for i, name in enumerate(header[1:], start=1):
        probe_data[name] = data[:, i]

    return time, probe_data


def compute_rms(signal):
    """
    Computes RMS of fluctuating component.

    RMS = sqrt(mean(x'^2))
    where x' = x - mean(x)
    """

    fluctuation = signal - np.mean(signal)

    rms = np.sqrt(np.mean(fluctuation**2))

    return rms


def plot_and_save(time, probe_name, pressure_pa, out_dir):
    """
    Creates ΔP plot and computes RMS.
    """

    # Pressure fluctuation relative to reference pressure
    delta_p_pa = pressure_pa - np.mean(pressure_pa)

    # Convert to PSI
    delta_p_psi = delta_p_pa * PA_TO_PSI

    # RMS calculations
    rms_pa = compute_rms(delta_p_pa)
    rms_psi = rms_pa * PA_TO_PSI

    # Plot
    plt.figure(figsize=(9,5))

    plt.plot(time, delta_p_psi, linewidth=1)

    plt.xlabel("Time [s]")
    plt.ylabel("ΔP [PSI]")

    plt.title(
        f"{probe_name}\n"
        f"RMS = {rms_psi:.6f} PSI"
    )

    plt.grid(True)

    plt.xlim((0.1,0.2))
    plt.ylim((-1,3))

    out_path = os.path.join(
        out_dir,
        f"{probe_name}_deltaP_PSI.jpg"
    )

    plt.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close()

    return rms_pa, rms_psi


# ============================================================
# ========================== MAIN ============================
# ============================================================

def main():

    if not os.path.isfile(INPUT_DAT_FILE):
        raise FileNotFoundError(
            f"Input file not found:\n{INPUT_DAT_FILE}"
        )

    os.makedirs(OUTPUT_FOLDER, exist_ok=True)

    time, probe_data = read_probe_dat(INPUT_DAT_FILE)

    # CSV output table
    csv_path = os.path.join(
        OUTPUT_FOLDER,
        "Probe_RMS_Results.csv"
    )

    results = []

    for probe_name, pressure_pa in probe_data.items():

        rms_pa, rms_psi = plot_and_save(
            time,
            probe_name,
            pressure_pa,
            OUTPUT_FOLDER
        )

        results.append([
            probe_name,
            rms_pa,
            rms_psi
        ])

        print(
            f"{probe_name:<20}"
            f" RMS = {rms_pa:12.4f} Pa"
            f" | {rms_psi:12.6f} PSI"
        )

    # Save RMS table
    with open(csv_path, "w", newline="") as f:

        writer = csv.writer(f)

        writer.writerow([
            "Probe Name",
            "RMS Pressure (Pa)",
            "RMS Pressure (PSI)"
        ])

        writer.writerows(results)

    print("\n================================================")
    print(f"Processed {len(probe_data)} probes")
    print(f"Reference pressure = {REFERENCE_PRESSURE_PA:.2f} Pa")
    print(f"Saved RMS table:\n{csv_path}")
    print("================================================\n")


if __name__ == "__main__":
    main()