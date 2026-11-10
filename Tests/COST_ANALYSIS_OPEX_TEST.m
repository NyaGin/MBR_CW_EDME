clear;
clc;

%% Test inputs
Volumetric_Airflow = 500;       % m^3/h
Volumetric_Permeateflow = 100;   % m^3/day
Volumetric_Wasteflow = 5;       % m^3/day
Electricity_Costs = 0.110;      % GBP/kWh

%% Run function
[Aeration_Costs, SludgeDisposal_Costs, Periphery_Costs] = ...
    COST_ANALYSIS_OPEX(Volumetric_Airflow,Volumetric_Wasteflow,Volumetric_Permeateflow,Electricity_Costs);

%% Total OPEX
Total_OPEX = Aeration_Costs + SludgeDisposal_Costs + Periphery_Costs;

%% Display results
fprintf('Aeration Costs:       £%.2f/day\n', Aeration_Costs);
fprintf('Sludge Disposal Costs: £%.2f/day\n', SludgeDisposal_Costs);
fprintf('Periphery Costs:      £%.2f/day\n', Periphery_Costs);
fprintf('Total OPEX:           £%.2f/day\n', Total_OPEX);

%% Verify results
assert(abs(Aeration_Costs - 1.40) < 1e-10);
assert(abs(SludgeDisposal_Costs - 1.00) < 1e-10);
assert(abs(Periphery_Costs - 12.10) < 1e-10);

disp('All tests passed.');