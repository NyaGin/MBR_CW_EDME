
function plotMBRStates(Time, State, Omin)
% =========================================================================
% MBR DYNAMIC SIMULATION - STATE VARIABLE PLOTS
% =========================================================================
% Inputs:
% Time  - Simulation time [days]
% State - ODE45/ODE15s solution matrix
% Omin  - Minimum dissolved oxygen concentration [mg/L]
%
% State(:,1) = Biomass concentration [mg/L]
% State(:,2) = Substrate concentration [mg COD/L]
% State(:,3) = Dissolved oxygen concentration [mg/L]
% State(:,4) = Transmembrane pressure [Pa]
%
% Operating Constraints:
% Biomass concentration < 20 g/L
% Substrate COD < 100 mg/L
% Dissolved oxygen >= 2 mg/L
%
% Plot Formatting:
% Blue solid lines  - ODE simulation results
% Black dotted lines - Maximum constraints
% Black dashed line - Minimum oxygen constraint
% =========================================================================

%% Extract States and Convert Units
X = State(:,1) / 1000;  % mg/L -> g/L
S = State(:,2);         % mg/L
O = State(:,3);         % mg/L
P = State(:,4) / 1e5;   % Pa -> bar

%% Operating Constraints
Xmax = 20;    % g/L
Smax = 100;   % mg/L
Omin = 2;     % mg/L

%% Create Figure
figure('Name', 'MBR Dynamic Simulation', 'Color', 'w');

tiledlayout(2,2);

% -------------------------------------------------------------------------
% Biomass Concentration
% -------------------------------------------------------------------------
nexttile;

plot(Time, X, 'LineWidth', 1.5);
hold on;

yline(Xmax, 'k:', 'Maximum Biomass', ...
    'LineWidth', 1.5);

hold off;

xlabel('Time [days]');
ylabel('Biomass [g/L]');
title('Biomass Concentration');
grid on;

% Ensure maximum constraint is visible
ylim([min(0, min(X)), max(max(X), Xmax) * 1.1]);

% -------------------------------------------------------------------------
% Substrate Concentration
% -------------------------------------------------------------------------
nexttile;

plot(Time, S, 'LineWidth', 1.5);
hold on;

yline(Smax, 'k:', 'Maximum COD', ...
    'LineWidth', 1.5);

hold off;

xlabel('Time [days]');
ylabel('COD [mg/L]');
title('Substrate Concentration');
grid on;

% Ensure maximum constraint is visible
ylim([min(0, min(S)), max(max(S), Smax) * 1.1]);

% -------------------------------------------------------------------------
% Dissolved Oxygen Concentration
% -------------------------------------------------------------------------
nexttile;

plot(Time, O, 'LineWidth', 1.5);
hold on;

yline(Omin, 'k--', 'Minimum O_2', ...
    'LineWidth', 1.5);

hold off;

xlabel('Time [days]');
ylabel('Dissolved Oxygen [mg/L]');
title('Dissolved Oxygen Concentration');
grid on;

% Ensure minimum oxygen constraint is visible
Olower = min(min(O), Omin);
Oupper = max(max(O), Omin);

Opad = max(0.1 * (Oupper - Olower), 0.1);

ylim([Olower - Opad, Oupper + Opad]);

% -------------------------------------------------------------------------
% Transmembrane Pressure
% -------------------------------------------------------------------------
nexttile;

plot(Time, P, 'LineWidth', 1.5);

xlabel('Time [days]');
ylabel('TMP [bar]');
title('Transmembrane Pressure');
grid on;

%% Overall Title
sgtitle('MBR Seasonal Dynamic Simulation');

end
