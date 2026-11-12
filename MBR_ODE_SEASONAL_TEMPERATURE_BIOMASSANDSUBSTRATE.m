function dstatedt = MBR_ODE_SEASONAL_TEMPERATURE_BIOMASSANDSUBSTRATE(time, State, Growth, Membrane_Area, Critical_Membrane_Flux, Volume, Feed_VolumetricFlowrate,Gassing_Rate)

% =========================================================================
% MBR DYNAMIC MODEL - PARAMETERS AND UNITS
% =========================================================================
%
% INPUT PARAMETERS
% -------------------------------------------------------------------------
% Parameter                              Symbol       Unit
% -------------------------------------------------------------------------
% Simulation time                        t            d
% Maximum specific growth rate           meu_max      d^-1
% Endogenous biomass decay rate          kd           d^-1
% Substrate affinity constant            Ks           mg COD/L
% Biomass/substrate yield coefficient    Yx_s         mg biomass/mg COD
% Biomass/oxygen yield coefficient       Yx_o         mg biomass/mg O2
% Critical membrane flux                 Jcrit        m/s
% Membrane area                          A            m^2
% Reactor volume                         V            m^3
% Feed volumetric flow rate              Qf           m^3/d
% Superficial gassing velocity           ug           m/s
%
% STATE VARIABLES
% -------------------------------------------------------------------------
% State(1) - Biomass concentration        X            mg biomass/L
% State(2) - Substrate concentration      S            mg COD/L
% State(3) - Dissolved oxygen             O            mg O2/L
% State(4) - Transmembrane pressure       P            Pa
%
% ALGEBRAIC VARIABLES
% -------------------------------------------------------------------------
% Net specific biomass growth rate       meu          d^-1
% Seasonal temperature                   T            K
% Oxygen saturation concentration        O_star       mg O2/L
% Volumetric oxygen transfer coefficient KLA          d^-1
% Hydraulic residence time               theta        d
% Permeate volumetric flow rate          Qp           m^3/d
% Sludge wasting flow rate               Qw           m^3/d
% Pure water dynamic viscosity           eta          Pa s
% Clean membrane pressure                P0           Pa
%
% OUTPUTS
% -------------------------------------------------------------------------
% dstatedt(1) - Biomass rate              dXdt         mg biomass/L/d
% dstatedt(2) - Substrate rate            dSdt         mg COD/L/d
% dstatedt(3) - Dissolved oxygen rate     dOdt         mg O2/L/d
% dstatedt(4) - TMP rate                  dPdt         Pa/d
%
% UNIT CONVERSIONS
% -------------------------------------------------------------------------
% Membrane flux:      m/s -> m/d          multiply by 86400
% Membrane flux:      m/s -> L/m^2/h      multiply by 3.6e6
% Biomass:            mg/L -> g/L         divide by 1000
% Temperature:        K -> deg C          subtract 273.15
%
% EMPIRICAL MEMBRANE PRESSURE CORRELATION
% -------------------------------------------------------------------------
% Jcrit must be supplied in L/m^2/h.
% X must be supplied in g/L.
% ug must be supplied in m/s.
% P and P0 must be supplied in Pa.
% dPdt is calculated in Pa/d.
%
% MODEL ASSUMPTIONS
% -------------------------------------------------------------------------
% The reactor is perfectly mixed and operates at constant liquid volume.
% The membrane operates at constant critical flux.
% The sludge wasting concentration equals the reactor biomass concentration.
% Biomass is completely retained by the membrane.
% Dissolved oxygen in the feed is negligible.
% Dissolved oxygen passes through the membrane into the permeate.
% Atmospheric surface oxygen transfer is neglected.
% Temperature varies seasonally.
% Level-control dynamics are neglected.
%
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

Qp = Critical_Membrane_Flux * 86400 * Membrane_Area;% as Qf = Qp + Qw we can thus calculate Qw after converting critical membrane flux to mday^-1
Qw = Feed_VolumetricFlowrate_t - Qp;
if Qw < 0
    error('Permeate flow exceeds feed flow. Check membrane area');
end

%Included seasonal temperature variations effect on meumax and consequently
%meu
Temperature = correlations.SeasonalTemperature(time);
Growth.meu_max = correlations.MeuMaxTemperature(Temperature);
Growth.S = S;
meu = correlations.meu(Growth);

%Hydraulic residence time calculated
theta = correlations.HydraulicResidenceTime(Feed_VolumetricFlowrate_t,Volume);

%% Dissolved Oxygen Parameters
KLA = correlations.KLA(Gassing_Rate);
Temperature_DegreesC = correlations.kelvin2Degrees(Temperature);
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
%This current model assumes that there are off
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
J_LMH = Critical_Membrane_Flux * 3.6e6;
X_g_L = X / 1000;
dPdt = 31.1 + 1.58 * J_LMH + 30.2 * X_g_L - 1.74 * Gassing_Rate * (P - P0);


dstatedt = [dXdt; dSdt;dOdt; dPdt;];

end

