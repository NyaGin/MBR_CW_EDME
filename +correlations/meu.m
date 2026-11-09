function meu = meu(Growth)
% =========================================================================
% GROWTH PARAMETERS - INPUT UNITS
% =========================================================================
% Parameter                                   Symbol       Unit
% -------------------------------------------------------------------------
% Maximum specific biomass growth rate        meu_max      d^-1
% Actual specific biomass growth rate         meu          d^-1
% Endogenous biomass decay rate               kd           d^-1
% Substrate affinity constant (COD)           Ks           mg COD/L
% Biomass concentration                       X            mg biomass/L
% Substrate concentration (COD)               S            mg COD/L
% Stoichiometric yield coefficient (COD)      Yx_s         mg biomass/mg COD
% Stoichiometric yield coefficient (Oxygen)   Yx_o         mg biomass/mg O2
% =========================================================================
%Output: d^-1
%using the monod equation for meu we can thus get that meu is equal to
%(meumax*S)/(Ks+S) - kd
meumax = Growth.meu_max;
S = Growth.S;
kd = Growth.kd;
Ks = Growth.Ks;
meu = (meumax*S)/(Ks+S) - kd;
end