function plotMBRStates(Time, State, Omin)
% =========================================================================
% MBR DYNAMIC SIMULATION - STATE VARIABLE PLOTS
% =========================================================================
% Inputs:
% Time  - Simulation time [days]
% State - ODE45 solution matrix
% Omin  - Minimum dissolved oxygen concentration [mg/L]
%
% State(:,1) = Biomass concentration [mg/L]
% State(:,2) = Substrate concentration [mg COD/L]
% State(:,3) = Dissolved oxygen concentration [mg/L]
% State(:,4) = Transmembrane pressure [Pa]
% =========================================================================

X = State(:,1);
S = State(:,2);
O = State(:,3);
P = State(:,4);

figure('Name','MBR Dynamic Simulation','Color','w');

tiledlayout(2,2);

% -------------------------------------------------------------------------
% Biomass concentration
% -------------------------------------------------------------------------
nexttile;
plot(Time, (X/1000), 'LineWidth', 1.5);
xlabel('Time [days]');
ylabel('Biomass [g/L]');
title('Biomass Concentration');
grid on;

% -------------------------------------------------------------------------
% Substrate concentration
% -------------------------------------------------------------------------
nexttile;
plot(Time, S, 'LineWidth', 1.5);
xlabel('Time [days]');
ylabel('COD [mg/L]');
title('Substrate Concentration');
grid on;

% -------------------------------------------------------------------------
% Dissolved oxygen concentration
% -------------------------------------------------------------------------
nexttile;
plot(Time, O, 'LineWidth', 1.5);
hold on;
yline(Omin, '--', 'Minimum O_2');
hold off;
xlabel('Time [days]');
ylabel('Dissolved Oxygen [mg/L]');
title('Dissolved Oxygen Concentration');
grid on;

% -------------------------------------------------------------------------
% Transmembrane pressure
% -------------------------------------------------------------------------
nexttile;
plot(Time, P/1000, 'LineWidth', 1.5);
xlabel('Time [days]');
ylabel('TMP [kPa]');
title('Transmembrane Pressure');
grid on;

sgtitle('MBR Seasonal Dynamic Simulation');

end