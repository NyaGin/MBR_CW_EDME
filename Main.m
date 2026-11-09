% =========================================================================
% MODEL ASSUMPTIONS
% =========================================================================
% The MBR operates at constant liquid volume, maintained by ideal level
% control.
%
% The membrane operates at constant critical flux, maintained by ideal
% transmembrane pressure control.
%
% Permeate flowrate is therefore determined by membrane area and flux:
% Qp = Jcrit * A
%
% Sludge wasting is adjusted to satisfy the constant-volume balance:
% Qw = Qf - Qp
%
% The selected operating volume includes an allowance above the minimum
% required process volume.
%
% Level-control dynamics are neglected.
% =========================================================================
% and O>=Omin.



% Stoichiometric and kinetic parameters at 20°C
Growth.meu_max_20 = 6;  % d^-1
Growth.kd = 0.075;      % d^-1
Growth.Ks = 1750;       % mg/L
Growth.Yx_s = 0.55;     % mg/mg
Growth.Yx_o = 0.7;      % mg/mg

%Initial Conditions
State0 = [50,600]; %[Initial biomass conc mgL^-1, CODinitial mgL^-1]

%Time Span
Timespan = [0 365];

%Solving the coupled ODEs for Biomass and Substrate concentration
[Time,State] = ode45(@(Time,State) MBR_ODE_SEASONAL_TEMPERATURE_BIOMASSANDSUBSTRATE(Time, State,Growth, Membrane_Area, Critical_Membrane_Flux, Volume, Feed_VolumetricFlowrate)...
                    , Timespan, State0);

X = State(:,1);
S = State(:,2);

%plotting

%oxygen

%membrane TMP

