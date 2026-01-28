import numpy as np

# ==========================================================
# USER-DEFINED PARAMETERS
# ==========================================================

# Freestream Mach number (INPUT)
Mach = 3.75

# Number of Rossiter modes to calculate
n_modes = 5

# Flow properties
a = 340.0               # Speed of sound [m/s]

# Cavity properties
L = 0.068               # Cavity length [m]

# Rossiter constants
alpha = 0.25            # Phase delay constant
kappa = 0.57            # Convective velocity ratio

# ==========================================================
# AIRSPEED FROM MACH
# ==========================================================

U_inf = Mach * a

# ==========================================================
# ROSSITER MODE CALCULATION
# ==========================================================

modes = np.arange(1, n_modes + 1)

freqs = (U_inf / L) * (modes - alpha) / (Mach + 1.0 / kappa)

# ==========================================================
# OUTPUT
# ==========================================================

print("\nRossiter Mode Predictions (Mach Input)")
print("-" * 52)
print(f"Input Mach        = {Mach:.4f}")
print(f"Speed of sound a = {a:.1f} m/s")
print(f"Airspeed U_inf   = {U_inf:.2f} m/s")
print(f"Cavity length L  = {L:.3f} m")
print(f"alpha            = {alpha:.3f}")
print(f"kappa            = {kappa:.3f}")
print("-" * 52)

for n, f in zip(modes, freqs):
    print(f"Mode {n:2d} → {f:9.2f} Hz")

print("\nDone.\n")
