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


%Time Span
Timespan = [0 365];

%Initial Parameters picked assumed to be 1 reactor for now
Critical_Membrane_Flux_Litres = 26;                                             %lm^-2h^-1
Critical_Membrane_Flux = membrane.Lm_2h_1toms_1(Critical_Membrane_Flux_Litres); %Converting flux to ms^-1
Feed_VolumetricFlowrate = 175000;                                               %m^3d^-1
Gassing_Rate = 0.045;                                                           %ms^-1
HRT = 1;                                                                        %day^-1
Volume = Feed_VolumetricFlowrate * HRT;                                         %m^3
SRT = 20;                                                                       %day^-1

%Initial Temperatures for P0 calculation
Temperature_initial = correlations.SeasonalTemperature(0);
Purewater_Viscosity_Initial = correlations.purewaterViscosity(Temperature_initial);
P0_initial = membrane.p0Darcy(Critical_Membrane_Flux, Purewater_Viscosity_Initial); %An initial value of P0 was used for the initial conditions of the startup this makes 
% it so that it looks at membrane operation 
% of a newly inputed MBR in a sense

%Initial Conditions
State0 = [50,600,2,P0_initial]; %[Initial biomass conc mgL^-1 , CODinitial mgL^-1 ,Initial Dissolved Oxygen Conc mgL^-1 ,Initial Transmembrane pressure Pa]

%Solving the coupled ODEs for Biomass and Substrate concentration
tic

for k = 1:20
    clear Time;
    clear State;
    [Time,State] = ode15s(@(Time,State) MBR_ODE_SEASONAL_TEMPERATURE_BIOMASSANDSUBSTRATE_NOFEEDCHANGE(Time, State,Growth, Critical_Membrane_Flux, Volume, Feed_VolumetricFlowrate,HRT,SRT,Gassing_Rate)...
                    , Timespan, State0);
end
average_Time = toc/20;
fprintf('Average ODE15s runtime: %.4f seconds\n',average_Time);

%plotting
plotting.plotMBRStates(Time, State, 2);


ODE = @(t,y) MBR_ODE_SEASONAL_TEMPERATURE_BIOMASSANDSUBSTRATE_NOFEEDCHANGE( ...
    t, y, Growth, Critical_Membrane_Flux, Volume, ...
    Feed_VolumetricFlowrate, HRT, SRT, Gassing_Rate);


RelTols = [1e-3, 1e-5, 1e-7, 1e-9];
AbsTols = [1e-6, 1e-8, 1e-10, 1e-12];

nTests = numel(RelTols);

% Preallocate Results
% Columns:
% 1 - Final biomass (g/L)
% 2 - Final substrate (mg/L)
% 3 - Minimum dissolved oxygen (mg/L)
% 4 - Maximum TMP (bar)
% 5 - Final simulation time (days)
% 6 - Solver runtime (seconds)

Results = zeros(nTests, 6);

for k = 1:nTests

    options = odeset( ...
        'RelTol', RelTols(k), ...
        'AbsTol', AbsTols(k));

    tic;

    [Time, State] = ode15s(ODE, Timespan, State0, options);

    Runtime = toc;

    % Extract results and convert units
    Biomass_Final = State(end,1) / 1000;  % mg/L -> g/L
    Substrate_Final = State(end,2);       % mg/L
    Oxygen_Min = min(State(:,3));        % mg/L
    TMP_Max = max(State(:,4)) / 1e5;     % Pa -> bar
    Final_Time = Time(end);              % days

    Results(k,:) = [ ...
        Biomass_Final, ...
        Substrate_Final, ...
        Oxygen_Min, ...
        TMP_Max, ...
        Final_Time, ...
        Runtime];

end
ResultsTable = array2table(Results, ...
    'VariableNames', { ...
        'Biomass_gL', ...
        'Substrate_mgL', ...
        'OxygenMin_mgL', ...
        'TMPMax_bar', ...
        'FinalTime_days', ...
        'Runtime_s'}, ...
    'RowNames', compose('RelTol_%.0e', RelTols));

fprintf('\n========== ODE15s CONVERGENCE STUDY ==========\n');
disp(ResultsTable);




