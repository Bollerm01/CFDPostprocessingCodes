
import numpy as np

def rossiter_modes(
    U_inf,
    L,
    M_inf,
    n_modes=5,
    alpha=0.25,
    kappa=0.57
):
    """
    Rossiter acoustic cavity mode calculator.

    Parameters
    ----------
    U_inf : float
        Freestream velocity [m/s]
    L : float
        Cavity length [m]
    M_inf : float
        Freestream Mach number [-]
    n_modes : int
        Number of Rossiter modes to compute
    alpha : float
        Phase delay constant (typ. ~0.25)
    kappa : float
        Convective velocity ratio (typ. ~0.57)

    Returns
    -------
    modes : ndarray
        Mode numbers
    freqs : ndarray
        Mode frequencies [Hz]
    """

    modes = np.arange(1, n_modes + 1)
    freqs = (U_inf / L) * (modes - alpha) / (M_inf + 1.0 / kappa)

    return modes, freqs


def main():
    print("\nRossiter Acoustic Cavity Mode Calculator\n")

    # ---- User Inputs ----
    U_inf = float(input("Freestream velocity U_inf [m/s]: "))
    L = float(input("Cavity length L [m]: "))
    M_inf = float(input("Freestream Mach number M_inf [-]: "))
    n_modes = int(input("Number of Rossiter modes to compute: "))

    # Optional advanced parameters
    use_defaults = input("Use default alpha=0.25 and kappa=0.57? (y/n): ").lower()

    if use_defaults == "n":
        alpha = float(input("Phase delay constant alpha [-]: "))
        kappa = float(input("Convective velocity ratio kappa [-]: "))
    else:
        alpha = 0.25
        kappa = 0.57

    # ---- Calculation ----
    modes, freqs = rossiter_modes(
        U_inf=U_inf,
        L=L,
        M_inf=M_inf,
        n_modes=n_modes,
        alpha=alpha,
        kappa=kappa
    )

    # ---- Output ----
    print("\nRossiter Mode Frequencies")
    print("-" * 32)
    for n, f in zip(modes, freqs):
        print(f"Mode {n:2d} : {f:10.2f} Hz")

    print("\nDone.\n")


if __name__ == "__main__":
    main()
