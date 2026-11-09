function dstatedt = MBR_ODE_SEASONAL_TEMPERATURE_BIOMASSANDSUBSTRATE(time, State, Growth, Membrane_Area, Critical_Membrane_Flux, Volume, Feed_VolumetricFlowrate,Gassing_Rate)
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

%% State establishment:
X = State(1);
S = State(2);
O = State(3);
P = State(4);


%% Subtrate and Biomass Parameters and Feed Variation
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
    error('Permeate flow exceeds feed flow. Check membrane area');
end

%Included seasonal temperature variations effect on meumax and consequently
%meu
Temperature = correlations.SeasonalTemperature(time);
Growth.meuMax = correlations.meuMaxTemperature(Temperature);
Growth.S = S;
meu = correlations.meu(Growth);

%Hydraulic residence time calculated
theta = correlations.HydraulicResidenceTime(Feed_VolumetricFlowrate_t,Volume);

%% Dissolved Oxygen Parameters
KLA = correlations.KLA(Gassing_Rate);
Temperature_DegreesC = correlations.degrees2Kelvin(Temperature);
O_star = correlations.SaturationoxygenConcentration(Temperature_DegreesC);


%% Membrane Flux Parameters
Purewater_Viscosity = correlations.purewaterViscosity(Temperature);
P0 = membrane.p0Darcy(Critical_Membrane_Flux,Purewater_Viscosity);


%% ODE Definitions
%Biomass and Substrate Transients
%From the well mixed assumption it is assumed that the biomass exiting the
%reactor is the same concentration as the biomass inside the reactor thus,
%Xw = X for the ODE involving dX/dt = meuX - Qw/V *Xw
dXdt = X * (meu - (Qw/Volume));
dSdt = (1/theta)*(Sf-S) - (meu*X)/Growth.Yx_s;

%Dissolved Oxygen Transient
%This current model assumes thyat there are off
%gasses for now from the broth to the air. It also assumes that there is no
%resistance to the oxygen dissolved in the broth as the broth moves through
%the membrane onto the permeate side, in other words the permeate side
%oxygen concentration is equal to the broth oxygen concentration. It is
%also assumed that the incoming broth has no oxygen in it thus the only
%input of oxygen into the tank is from the aerator, along with this it is
%assumed that no dissolved oxygen comes from the air the dissolved oxygen
%that comes from the air is neglected as a conservative assumption as it
%could potentially underestimate oxygen control demands provided the oxygen
%concentration in the broth is below the atmosphere saturation. It also
%assumes that the stoichiometric yield of X/O is not affected by
%temperature
dOdt = KLA*(O_star - O) - (meu * X)/Growth.Yx_o - (Feed_VolumetricFlowrate_t*O)/Volume;

%Transmembrane pressure requirement Transient
%This finds out the required Transmembrane pressures in order to maintain a
%constant critical flux with fouling accounted for. This is an empirical
%relation taken from a pilot plant as stated in the brief.
dPdt = 31.1 + 1.58 * Critical_Membrane_Flux + 30.2 * X - 1.74 * Gassing_Rate (P - P0);


dstatedt = [dXdt; dSdt;dOdt; dPdt;];

end

