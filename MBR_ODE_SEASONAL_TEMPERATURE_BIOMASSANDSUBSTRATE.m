function dstatedt = MBR_ODE_SEASONAL_TEMPERATURE_BIOMASSANDSUBSTRATE(time, State, Growth, Membrane_Area, Critical_Membrane_Flux, Volume, Feed_VolumetricFlowrate)
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
% Additional inputs:
% Critical_Membrane_Flux    m^3 m^-2 d^-1
% Membrane_Area             m^2
% Volume                    m^3
% Feed_VolumetricFlowrate   m^3 d^-1
%
% Outputs:
% dXdt                      mg biomass L^-1 d^-1
% dSdt                      mg COD L^-1 d^-1

% =========================================================================

%State establishment:
X = State(1);
S = State(2);
O = State(3);
P = State(4);


%Disruptions in feed - between the months of october and january the COD
%concentration increases to 1800mgL^-1 and the volumtric flowrate requirement of feed wastewater
%increases by 0.01%. Assuming that it is a non leap year october starts on
%Day 92 and the 31st of january is on day 214

Sf = 600; %mgL^-1
Feed_VolumetricFlowrate_t = Feed_VolumetricFlowrate;

if (time >= 92 && time < 215)
    Sf = 1800; %mgL^-1
    Feed_VolumetricFlowrate_t = Feed_VolumetricFlowrate * 1.0001;
end

%As stated in the brief the membranes are operated at a constant cricital
%flux with TMP control

Qp = Critical_Membrane_Flux * Membrane_Area;% as Qf = Qp + Qw we can thus calculate Qw
Qw = Feed_VolumetricFlowrate_t - Qp;
if Qw < 0
    error('Permeate flow exceeds feed flow.');
end

%Included seasonal temperature variations effect on meumax and consequently
%meu
Temperature = correlations.SeasonalTemperature(time);
Growth.meuMax = correlations.meuMaxTemperature(Temperature);
Growth.S = S;
meu = correlations.meu(Growth);

%Hydraulic residence time calculated
theta = correlations.HydraulicResidenceTime(Feed_VolumetricFlowrate_t,Volume);


%From the well mixed assumption it is assumed that the biomass exiting the
%reactor is the same concentration as the biomass inside the reactor thus,
%Xw = X for the ODE involving dX/dt = meuX - Qw/V *Xw
dXdt = X * (meu - (Qw/Volume));
dSdt = (1/theta)*(Sf-S) - (meu*X)/Growth.Yx_s;

%Dissolved Oxygen Transient

%Transmembrane pressure requirement Transient



dstatedt = [dXdt; dSdt;];


end

