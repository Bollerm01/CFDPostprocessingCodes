"""
Choked ethylene injector design into Mach 2 crossflow

This script computes:
- Required ethylene plenum stagnation pressure p0j
- Jet exit conditions (Tj, pj, Uj, rho_j) for choked flow (Mj = 1)
- Mass flow rate per injector and total for N identical injectors

Momentum flux ratio definition (per injector):
    J = (rho_j * U_j^2) / (rho_a * U_a^2)

For the crossflow (air, assumed ideal gas):
    rho_a * U_a^2 = gamma_a * M_a^2 * p_a

For a choked jet (Mj = 1, isentropic, ideal gas):
    rho_j * U_j^2 = gamma_j * C_crit_j * p0j

where
    C_crit_j = (2 / (gamma_j + 1))^(gamma_j / (gamma_j - 1))

Thus:
    p0j = J * (gamma_a * M_a^2 * p_a) / (gamma_j * C_crit_j)
"""

import math


def choked_jet_design(
    J,
    Ma,
    pa,
    Ta,
    gamma_a,
    Ra,
    gamma_j,
    Rj,
    T0j,
    N_injectors,
    d_injector,
):
    """
    Parameters
    ----------
    J : float
        Target momentum flux ratio (per injector), dimensionless.
    Ma : float
        Crossflow Mach number.
    pa : float
        Crossflow static pressure [Pa].
    Ta : float
        Crossflow static temperature [K].
    gamma_a : float
        Specific heat ratio of crossflow gas (air).
    Ra : float
        Gas constant of crossflow gas [J/(kg·K)].
    gamma_j : float
        Specific heat ratio of jet gas (ethylene).
    Rj : float
        Gas constant of jet gas [J/(kg·K)].
    T0j : float
        Jet plenum stagnation temperature [K].
    N_injectors : int
        Number of identical injectors.
    d_injector : float
        Diameter of each injector [m].

    Returns
    -------
    results : dict
        Dictionary containing computed values.
    """

    # ---- Crossflow (air) properties ----
    # Speed of sound in air
    a_a = math.sqrt(gamma_a * Ra * Ta)  # [m/s]

    # Crossflow velocity
    U_a = Ma * a_a  # [m/s]

    # Crossflow density
    rho_a = pa / (Ra * Ta)  # [kg/m^3]

    # Crossflow momentum flux
    # rho_a * U_a^2 = gamma_a * Ma^2 * pa
    rhoU2_a = gamma_a * Ma**2 * pa  # [Pa] (kg/(m·s^2))

    # ---- Choked jet (ethylene) injector ----
    # Critical pressure coefficient C_crit_j at M = 1
    # C_crit_j = (2/(gamma_j + 1))^(gamma_j/(gamma_j - 1))
    C_crit_j = (2.0 / (gamma_j + 1.0)) ** (gamma_j / (gamma_j - 1.0))

    # Required jet stagnation pressure p0j for target J
    # p0j = J * (gamma_a * Ma^2 * pa) / (gamma_j * C_crit_j)
    p0j = J * rhoU2_a / (gamma_j * C_crit_j)  # [Pa]

    # Jet exit static temperature (Mj = 1)
    # Tj = T0j * 2/(gamma_j + 1)
    Tj = T0j * (2.0 / (gamma_j + 1.0))  # [K]

    # Jet exit static pressure
    # pj = C_crit_j * p0j
    pj = C_crit_j * p0j  # [Pa]

    # Jet exit density
    # rho_j = pj / (Rj * Tj)
    rho_j = pj / (Rj * Tj)  # [kg/m^3]

    # Jet exit velocity (Mj = 1)
    # Uj = sqrt(gamma_j * Rj * Tj)
    Uj = math.sqrt(gamma_j * Rj * Tj)  # [m/s]

    # Jet momentum flux per injector
    # rho_j * Uj^2 = gamma_j * pj = gamma_j * C_crit_j * p0j
    rhoU2_j = gamma_j * pj  # [Pa]

    # Check J from these values for sanity
    J_check = rhoU2_j / rhoU2_a

    # ---- Injector geometry and mass flow ----
    # Area of each injector: A = pi * d^2 / 4
    A_inj = math.pi * d_injector**2 / 4.0  # [m^2]

    # Choked mass flux for an ideal gas:
    # m_dot'' = p0j * sqrt(gamma_j / (Rj * T0j)) *
    #           (2/(gamma_j + 1))^((gamma_j + 1)/(2*(gamma_j - 1)))
    exponent = (gamma_j + 1.0) / (2.0 * (gamma_j - 1.0))
    mass_flux = (
        p0j
        * math.sqrt(gamma_j / (Rj * T0j))
        * (2.0 / (gamma_j + 1.0)) ** exponent
    )  # [kg/(m^2·s)]

    # Mass flow per injector
    m_dot_per_inj = mass_flux * A_inj  # [kg/s]

    # Total mass flow for N injectors
    m_dot_total = N_injectors * m_dot_per_inj  # [kg/s]

    return {
        "p0j_required_Pa": p0j,
        "T0j_K": T0j,
        "Tj_exit_K": Tj,
        "pj_exit_Pa": pj,
        "rhoj_exit_kg_m3": rho_j,
        "Uj_exit_m_s": Uj,
        "rhoU2_jet_Pa": rhoU2_j,
        "rhoU2_air_Pa": rhoU2_a,
        "J_target": J,
        "J_check_from_solution": J_check,
        "N_injectors": N_injectors,
        "injector_diameter_m": d_injector,
        "injector_area_per_hole_m2": A_inj,
        "mass_flux_choked_kg_m2_s": mass_flux,
        "m_dot_per_injector_kg_s": m_dot_per_inj,
        "m_dot_total_kg_s": m_dot_total,
        "Ua_m_s": U_a,
        "rhoa_kg_m3": rho_a,
    }


if __name__ == "__main__":
    # Example usage:
    # You should replace these with your actual values.

    # Crossflow (air) conditions at Mach 2
    Ma = 2.0              # Mach number of crossflow
    pa = 20320            # static pressure [Pa]
    Ta = 300.0            # static temperature [K]
    gamma_a = 1.4         # air
    Ra = 287.0            # [J/(kg·K)]

    # Jet (ethylene) properties (approximate ideal-gas values; update as needed)
    gamma_j = 1.24         # example value for ethylene; check your data
    Rj = 296.4            # [J/(kg·K)] approximate; adjust from real-gas data
    T0j = 300.0           # plenum stagnation temperature [K]

    # Target momentum flux ratio (per injector)
    J_target = 1.4      # example value

    # Injector configuration
    N_injectors = 5
    d_injector_mm = 2.5
    d_injector = d_injector_mm * 1e-3  # convert mm to m

    results = choked_jet_design(
        J=J_target,
        Ma=Ma,
        pa=pa,
        Ta=Ta,
        gamma_a=gamma_a,
        Ra=Ra,
        gamma_j=gamma_j,
        Rj=Rj,
        T0j=T0j,
        N_injectors=N_injectors,
        d_injector=d_injector,
    )

    # Pretty-print results
    print("=== Choked Ethylene Injector Design ===")
    print(f"Target J (per injector):                 {results['J_target']:.3f}")
    print(f"Check J from solution:                   {results['J_check_from_solution']:.3f}")
    print()
    print(f"Required jet stagnation pressure p0j:    {results['p0j_required_Pa']:.1f} Pa")
    print(f"Jet stagnation temperature T0j:          {results['T0j_K']:.1f} K")
    print()
    print(f"Jet exit temperature Tj:                 {results['Tj_exit_K']:.1f} K")
    print(f"Jet exit pressure pj:                    {results['pj_exit_Pa']:.1f} Pa")
    print(f"Jet exit density rho_j:                  {results['rhoj_exit_kg_m3']:.4f} kg/m^3")
    print(f"Jet exit velocity Uj:                    {results['Uj_exit_m_s']:.2f} m/s")
    print()
    print(f"Crossflow momentum flux rho_a U_a^2:     {results['rhoU2_air_Pa']:.1f} Pa")
    print(f"Jet momentum flux rho_j U_j^2:           {results['rhoU2_jet_Pa']:.1f} Pa")
    print()
    print(f"Number of injectors:                     {results['N_injectors']}")
    print(f"Injector diameter:                       {results['injector_diameter_m']*1e3:.2f} mm")
    print(f"Area per injector:                       {results['injector_area_per_hole_m2']:.6e} m^2")
    print()
    print(f"Choked mass flux (per area):             {results['mass_flux_choked_kg_m2_s']:.4f} kg/(m^2·s)")
    print(f"Mass flow per injector:                  {results['m_dot_per_injector_kg_s']:.6f} kg/s")
    print(f"Total mass flow (all injectors):         {results['m_dot_total_kg_s']:.6f} kg/s")
    print()
    print(f"Air Density Check:                       {results['rhoa_kg_m3']:.6f} kg/m3")
    print(f"Air velocity Check:                       {results['Ua_m_s']:.6f} m/s")
