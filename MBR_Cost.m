function Total_Cost = MBR_Cost(Parameters, Number_of_Units, Growth, Electricity_Costs)
%Input: gassing rate = ms^-1, Jstar = Lm^-2h^-1,HRT = Days^-1,SRT = Days^-1.
Gassing_Rate = Parameters(1);
Critical_Membrane_Flux = Parameters(2);
Hydraulic_Residence_Time = Parameters(3);
Substrate_Residence_Time = Parameters(4);


%%Volumetric Calculations
Volumetric_Feed_Per_Tank = 175000 * (1 + (0.01)/100)/Number_of_Units; %Max volumetric Feed incoming m^3d^-1
Tank_Volume_Liquid = Hydraulic_Residence_Time * Volumetric_Feed_Per_Tank; %m^3
Volumetric_Wasteflow = Tank_Volume_Liquid / Substrate_Residence_Time; %m^3d^-1
Volumetric_Permeateflow = Volumetric_Feed_Per_Tank - Volumetric_Wasteflow; %m^3d^-1

%%Membrane Calculations
Membrane_Area = Volumetric_Permeateflow/(Critical_Membrane_Flux/1000); %m^2
Number_of_Membrane_units = fix(Membrane_Area/450) + 1; %Gives the number of required membrane units

%The dimensions of the membrane modules are 2.19m x 0.944m x 2.92m (Length
%x Width x Height) as the modules need to be spaced out on the base of the
%reactor in single file with the spacing between the membrane modules being
%equal to their width to ensure adequate space for aeration and mixing. An
%initial dimension calculation can be done based on the volume and the
%footprint. 
Width_Tank = Number_of_Membrane_units * 0.944 * 2 - 0.944; %m
Length_Tank = 2.19; %m
 
