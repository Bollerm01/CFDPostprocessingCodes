# ==========================================================
# USER-DEFINED PARAMETERS
# ==========================================================

# Required Strouhal number (based on cavity length)
St = 0.25

# Rossiter constants
alpha = 0.25          # Phase delay constant
kappa = 0.57          # Convective velocity ratio

# Rossiter mode number (FIRST MODE ONLY)
n = 1

# ==========================================================
# MACH NUMBER CALCULATION (FROM STROUHAL)
# ==========================================================

numerator = St * (n - alpha)
denominator = 1.0 - St / kappa

Mach = numerator / denominator

# ==========================================================
# OUTPUT
# ==========================================================

print("\nRossiter First-Mode Mach from Strouhal Number")
print("-" * 48)
print(f"Mode number n        = {n}")
print(f"Required Strouhal   = {St:.4f}")
print(f"alpha               = {alpha:.3f}")
print(f"kappa               = {kappa:.3f}")
print("-" * 48)
print(f"Required Mach       = {Mach:.4f}")
print("\nDone.\n")
