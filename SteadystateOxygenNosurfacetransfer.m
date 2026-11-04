function Oxygen_Conc_Steadystate = SteadystateOxygenNosurfacetransfer(KLA, Temperature, Growth, Volume, Volumetric_Feed_Flowrate)
%Input:d^-1, K, Growth.Yx_o = mgmg^-1 Growth.meu = d^-1 Growth.X = mgL^-1, m^3,m^3d^-1  
%Output: mgL^-1
%This assumes a steady state operation with the following equation 
%dO/dt = kla(O* - O) - OUR - QfO/V assumes that Qf = Qw + Qp, as steady state dO/dt = 0 
%and assumes that there is no transfer of oxygen between the atmosphere air and the
%broth. This will be used to look at the oxygen conc that is required for
%steady state operation. This will give you the Oxygen steady state at a given KLA.

Temperature = correlations.kelvin2Degrees(Temperature); % Conversion from kelvin to degrees C
Saturation_Oxygen_Concentration = correlations.SaturationoxygenConcentration(Temperature);
theta = correlations.HydraulicResidenceTime(Volumetric_Feed_Flowrate, Volume);
Oxygen_Conc_Steadystate = ((KLA * Saturation_Oxygen_Concentration * Growth.Yx_o - Growth.meu * Growth.X) * theta)/(Growth.Yx_o *(KLA*theta + 1));
end
