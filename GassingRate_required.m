function u_gRequired = GassingRate_Required(Temperature, Oxygen_Concentrationmin_forcellgrowth, Growth, Volume, Feed_Volumetric_Flowrate)
%Input:K mgL^-1, Growth.Yx_o = mgmg^-1 Growth.meu = d^-1 Growth.X = mgL^-1, m^3,m^3d^-1,K Output:d^-1
%This formula calculates the Gassing rate required off of the minimum KLA
%requirement set by a minimum oxygen concentration for cell growth for that
%day or state. This assumes that there is no surface area mass transfer as
%a note.
theta = correlations.HydraulicResidenceTime(Feed_Volumetric_Flowrate, Volume);

% Calculate minimum oxygen saturation concentration
Temperature = correlations.kelvin2Degrees(Temperature);
Oxygen_Saturation = correlations.SaturationoxygenConcentration(Temperature);

% Calculate required KLa
KlaRequired = (Growth.meu * Growth.X * theta + Oxygen_Concentrationmin_forcellgrowth * Growth.Yx_o) /(Growth.Yx_o * theta *(Oxygen_Saturation - Oxygen_Concentrationmin_forcellgrowth));

% Calculate required gassing rate
u_gRequired = (KlaRequired / (1.7e6))^(1/2.66);

if ug_required > 0.2
    error('Required gassing rate exceeds maximum permitted value');
end

end




