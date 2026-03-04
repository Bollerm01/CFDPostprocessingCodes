#!/usr/bin/env python3
"""
Chapman-Enskog Binary Diffusivity for Air–C2H4

Computes the binary mass diffusivity D_AB for air–ethylene using the
Chapman-Enskog equation.

Units:
- Temperature T: K
- Pressure P: atm
- Output D_AB: cm^2/s
"""

import math


def diffusion_collision_integral(T_star: float) -> float:
    """
    Diffusion collision integral Omega_D as a function of reduced temperature T*.

    Parameters
    ----------
    T_star : float
        Reduced temperature (dimensionless), T* = T / epsilon_AB (K/K).

    Returns
    -------
    float
        Omega_D (dimensionless)
    """
    term1 = 1.06036 / (T_star ** 0.15610)
    term2 = 0.19300 / math.exp(0.47635 * T_star)
    term3 = 1.03587 / math.exp(1.52996 * T_star)
    term4 = 1.76474 / math.exp(3.89411 * T_star)
    return term1 + term2 + term3 + term4


def chapman_enskog_diffusivity_air_c2h4(T: float, P: float) -> float:
    """
    Binary diffusion coefficient D_AB for air–C2H4 using Chapman-Enskog.

    Parameters
    ----------
    T : float
        Temperature in K.
    P : float
        Pressure in atm.

    Returns
    -------
    float
        Binary diffusion coefficient D_AB in cm^2/s.
    """

    # ---- Constants for air and C2H4 ----
    # Molecular weights (g/mol)
    M_air = 28.97
    M_c2h4 = 28.05

    # Lennard-Jones parameters
    # epsilon/k_B in K
    epsilon_air = 78.6     # representative for air (N2/O2 mixture) ( # Langenberg et. al. 2020 (Poling et al 2004))
    epsilon_c2h4 = 224.7   # ethylene

    # sigma in Angstroms
    sigma_air = 3.711 # Langenberg et. al. 2020 (Poling et al 2004)
    sigma_c2h4 = 4.163

    # ---- Mixing rules ----
    epsilon_ab = math.sqrt(epsilon_air * epsilon_c2h4)      # K
    sigma_ab = 0.5 * (sigma_air + sigma_c2h4)               # Å

    # Reduced temperature
    T_star = T / epsilon_ab

    # Collision integral
    Omega_D = diffusion_collision_integral(T_star)

    # Chapman-Enskog equation (engineering form)
    D_ab = (
        0.001858
        * (T ** 1.5)
        / (P * (sigma_ab ** 2) * Omega_D)
        * math.sqrt(1.0 / M_air + 1.0 / M_c2h4)
    )

    return D_ab


def main():
    print("Chapman-Enskog Binary Diffusivity: Air–C2H4")
    print("------------------------------------------")

    try:
        T = float(input("Temperature T [K]: "))
        P = float(input("Pressure P [atm]: "))
    except ValueError:
        print("Invalid numeric input. Please re-run and enter valid numbers.")
        return

    D_ab = chapman_enskog_diffusivity_air_c2h4(T, P)

    print(f"\nBinary diffusivity D_air-C2H4 = {D_ab:.4e} cm^2/s")


if __name__ == "__main__":
    main()