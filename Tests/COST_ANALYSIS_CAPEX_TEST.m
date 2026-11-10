
clear;
clc;

%% Test inputs
Membrane_Area = 200;           % m^2
Volumetric_Airflow = 100;      % m^3/h
Tank_Volume = 100;             % m^3
Volumetric_Wasteflow = 10;     % L/s

Lang_Factor = 4.74;

%% Run function
[Membrane_Cost, Tank_Cost, AirBlower_Cost, Wastepump_Cost] = ...
    COST_ANALYSIS_CAPEX(Membrane_Area, Volumetric_Airflow, ...
                        Tank_Volume, Volumetric_Wasteflow);

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

assert(abs(Tank_Cost - 23462.098519751) < Tolerance, ...
    'Tank cost calculation incorrect');

assert(abs(AirBlower_Cost - 4412.807248103) < Tolerance, ...
    'Air blower cost calculation incorrect');

assert(abs(Wastepump_Cost - 6562.981893212) < Tolerance, ...
    'Waste pump cost calculation incorrect');

assert(abs(Total_CAPEX - 201155.587513453) < Tolerance, ...
    'Total CAPEX calculation incorrect');

disp('All CAPEX tests passed.');
