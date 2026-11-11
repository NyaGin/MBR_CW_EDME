clear;
clc;

%% Test inputs
Membrane_Area = 200;           % m^2 (total membrane area)
Volumetric_Airflow = 100;      % m^3/h (per unit)
Tank_Volume = 100;             % m^3 (per unit)
Volumetric_Wasteflow = 10;     % L/s (per unit)
Number_of_Units = 3;

Lang_Factor = 4.74;

%% Run function
[Membrane_Cost, Tank_Cost, AirBlower_Cost, Wastepump_Cost] = ...
    COST_ANALYSIS_CAPEX(Membrane_Area, Volumetric_Airflow, ...
                        Tank_Volume, Volumetric_Wasteflow, ...
                        Number_of_Units);

%% Total CAPEX
Equipment_Cost = Membrane_Cost + Tank_Cost + ...
                 AirBlower_Cost + Wastepump_Cost;

Total_CAPEX = Lang_Factor * Equipment_Cost;

%% Display results
fprintf('Membrane Cost:     £%.2f\n', Membrane_Cost);
fprintf('Tank Cost:         £%.2f\n', Tank_Cost);
fprintf('Air Blower Cost:   £%.2f\n', AirBlower_Cost);
fprintf('Waste Pump Cost:   £%.2f\n', Wastepump_Cost);
fprintf('Equipment Cost:    £%.2f\n', Equipment_Cost);
fprintf('Total CAPEX:       £%.2f\n', Total_CAPEX);

%% Verify results
Tolerance = 1e-4;

assert(abs(Membrane_Cost - 8000) < Tolerance, ...
    'Membrane cost calculation incorrect');

assert(abs(Tank_Cost - 70386.295559253) < Tolerance, ...
    'Tank cost calculation incorrect');

assert(abs(AirBlower_Cost - 13238.421744310) < Tolerance, ...
    'Air blower cost calculation incorrect');

assert(abs(Wastepump_Cost - 19688.945679635) < Tolerance, ...
    'Waste pump cost calculation incorrect');

assert(abs(Equipment_Cost - 111313.662983198) < Tolerance, ...
    'Equipment cost calculation incorrect');

assert(abs(Total_CAPEX - 527626.762540358) < Tolerance, ...
    'Total CAPEX calculation incorrect');

disp('All CAPEX tests passed.');