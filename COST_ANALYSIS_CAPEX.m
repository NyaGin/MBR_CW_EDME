function [Membrane_Cost,Tank_Cost,AirBlower_Cost,Wastepump_Cost] = COST_ANALYSIS_CAPEX(Membrane_Area,Volumetric_Airflow,Tank_Volume,Volumetric_Wasteflow)
%Input: m^2, m^3h^-1, m^3, Ls^-1 Output: Pounds
%This is a capital cost analysis for the project. This assumes no
%depreciation and inflation for the cost calculation and a common Lang Factor of
%4.74 will be applied to find the total CAPEX. It should be noted that for
%Tank cost, Air Blower cost and Waste pump cost that these are costs for
%each airblow, tank and wastepump.
Membrane_Cost = 40 * Membrane_Area;
Tank_Cost = 7500 + 800*Tank_Volume^0.65;
AirBlower_Cost = 2900 + 38 * Volumetric_Airflow^0.8;
Wastepump_Cost = 5300 + 159 * Volumetric_Wasteflow^0.9;

end

