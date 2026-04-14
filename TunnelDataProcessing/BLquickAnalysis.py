import numpy as np
import pandas as pd

# ============================================
# CONFIGURATION
# ============================================

GAMMA = 1.4               # ratio of specific heats, air ~ 1.4
M_MIN = 1.00              # minimum Mach (Rayleigh Pitot is for M > 1)
M_MAX = 5.0               # maximum Mach
M_STEP = 0.01             # Mach increment
OUT_FILE = "TunnelDataProcessing/rayleigh_pitot_table.csv"


# ============================================
# RAYLEIGH PITOT FORMULA
# ============================================

def rayleigh_pitot_ratio(M, gamma=GAMMA):
    """
    Rayleigh–Pitot formula:
    Returns p0,2 / p1 for a given Mach number M > 1, where

      p1   = static pressure upstream of the normal shock
      p0,2 = total (stagnation) pressure measured by the Pitot tube
             after the normal shock and isentropic deceleration.

    gamma = ratio of specific heats.
    """
    M = np.asarray(M, dtype=float)
    M2 = M ** 2

    term1 = ((gamma + 1.0) * M2 / 2.0) ** (gamma / (gamma - 1.0))
    term2 = ((gamma + 1.0) / (2.0 * gamma * M2 - (gamma - 1.0))) ** (1.0 / (gamma - 1.0))

    return term1 * term2


# ============================================
# MAIN: TABULATE AND SAVE
# ============================================

def main():
    # Generate Mach number array
    M_values = np.arange(M_MIN, M_MAX + M_STEP, M_STEP)

    # Rayleigh Pitot ratio: p0,2 / p1
    P02_over_P1 = rayleigh_pitot_ratio(M_values, gamma=GAMMA)

    # Isentropic total/static: p0,1 / p1
    P01_over_P1 = (1.0 + (GAMMA - 1.0) / 2.0 * M_values**2) ** (GAMMA / (GAMMA - 1.0))

    # Desired column: P02/P01 = (P02/P1) / (P01/P1)
    P02_over_P01 = P02_over_P1 / P01_over_P1

    # Assemble table
    df = pd.DataFrame({
        "Mach": M_values,
        "Rayleigh_Pitot_P02_over_P1": P02_over_P1,
        "Isentropic_P01_over_P1": P01_over_P1,
        "P02_over_P01": P02_over_P01
    })

    # Save to CSV
    df.to_csv(OUT_FILE, index=False)
    print(f"Table saved to: {OUT_FILE}")

    # Print a small sample to screen
    print("\nSample of Rayleigh Pitot table:")
    print(df.head(10).to_string(index=False))


if __name__ == "__main__":
    main()