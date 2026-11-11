function optimal = Optimiser(Growth)
%Growth Constants
%Outputs: Pounds This is a optimiser which optimises the reactor gassing
%rate membrane critical flux and both HRT and SRT for cost while keeping
%the cost as low as possible and being within the operating constraints.
%The constraints are as follows, 175000m^3d^-1 permeate flowrate, having
%the biomass concentration below 20gL^-1, Having the Dissolved oxygen
%concentration to be greater than 2mgL^-1, Having the COD pollutant to be <
%100mgL^-1 having a HRT betwee 0.8 and 1.1 days, having a SRT between 15-30
%days, having a critical membrane flux between 16-30 Lm^-2h^-1 and having a
%average TMP < 0.2 Bar.

%Initial State: Gassing rate, critical membrane flux, HRT, SRT
State0 = [0.015, 25, 1.0, 20];

%Lower bounded constraints for the parameters: Gassing rate, critical membrane flux, HRT, SRT 
LowerBound = [0.015, 16, 0.8, 15];

% Upper bounds
UpperBound = [0.2, 30, 1.1, 30];

% Optimiser settings this sets up the options for the optimiser, uses
% fmincon with sequential quadractic programming, iterative and max number
% of evaluations.
options = optimoptions('fmincon', ...
    'Algorithm', 'sqp', ...
    'Display', 'iter', ...
    'MaxFunctionEvaluations', 5000);

% Run optimisation
[x_opt, cost_min, exitflag, output] = fmincon( ...
    @MBR_Cost, ...
    State0, ...
    [], [], ...
    [], [], ...
    LowerBound, UpperBound, ...
    @MBR_Constraints, ...
    options);





end