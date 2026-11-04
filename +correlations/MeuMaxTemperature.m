function meu = MeuMaxTemperature(Temperature)
%Input: K Output: d^-1
%This calculates the maximum specific growth rate of the biomas or meumax
%following the temperature adjusted growth constant and the following
%correlations: meumax = Yx_s * kt and kt = k20 * 1.04^(T-293) by
%rearranging the equation at 20 degrees C we can find that kt at 20 degrees
%C is 6/0.55 = 120/11 and subsequently k20 is thus kt/(1.04^293.15-293)

% =========================================================================
% TABLE 1: STOICHIOMETRIC AND KINETIC PARAMETERS AT 20°C
% =========================================================================
% Parameter                                   Symbol       Value    Unit
% -------------------------------------------------------------------------
% Maximum specific biomass growth rate        mu_max       6        d^-1
% Endogenous biomass decay rate               kd           0.075    d^-1
% Substrate affinity constant (COD)           Ks           1750     mg/L
% Stoichiometric yield coefficient (COD)      Yx_s         0.55     mg/mg
% Stoichiometric yield coefficient (Oxygen)   Yx_o         0.70     mg/mg
% =========================================================================

kt_20C = 6/0.55; %This is Kt at 20 degrees C
k20 = kt_20C/(1.04^(293.15-293));
kt = k20 * 1.04^(Temperature-293);
Yx_s = 0.55;
meu = Yx_s * kt;
end