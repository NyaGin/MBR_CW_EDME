function [Aeration_Costs, SludgeDisposal_Costs,Periphery_Costs] = COST_ANALYSIS_OPEX(Volumetric_Airflow,Volumetric_Wasteflow,Volumetric_Permeateflow,Electricity_Costs)
%Input: m^3h^-1, m^3d^-1, pounds/kWh Output: Pounds per day
%This is the opex cost analysis for the project. It takes into account sludge disposal costs,
% aeration costs per day, energy costs for the control panel, the pump and other periphery needed to run the MBR.
Aeration_Costs = 2.8 * 10^-3 * Volumetric_Airflow;
SludgeDisposal_Costs = 0.2 * Volumetric_Wasteflow;
%The energy consumption for the control panel, pump and other peripheries
%are at a constant of 1.1kWhm^-3 of permeate.
Periphery_Energy = 1.1 * Volumetric_Permeateflow; %kWhd^-1
Periphery_Costs = Electricity_Costs * Periphery_Energy;

end