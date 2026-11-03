function p0 = p0Darcy(Critical_Flux, Purewater_Viscosity)
%Inputs: ms^-1, pas Outputs: Pa
%Works out p0, defined as the transmembrane pressure to achieve critical
%flux in the abcense of fouling calculated with a membrane resistance of
%R_m of 7*10^-11m^-1 in pure water so no osmotic pressure.
%Due to this the permeate flux for porous membranes simplifies down to
%J=TMP/(meu*R_M),where TMP is p0 in this case, as it has no resistance from concentration polarisation,
%cake formation, absorbed solutes, or resistance from blocked pores.

R_m = 7*10^11;%m^-1 Membrane resistance
p0 = Purewater_Viscosity * R_m * Critical_Flux;
end