function [X_opt, Cost_opt] = Optimiser(Growth, Feed_VolumetricFlowrate, Timespan, State0, N_membrane)


%Initial State: Gassing rate, HRT, SRT
X0 = [0.015, 1.0, 20];

%Lower bounded constraints for the parameters: Gassing rate, critical membrane flux, HRT, SRT 
LowerBound = [0.015, 16, 0.8, 15];

% Upper bounds
UpperBound = [0.2, 30, 1.1, 30];

% ODE parameter and solution caches to prevent duplicate ODE solves
X = [];                                         % Current parameter vector  
Y = [];                                         % ODE solution vector 



% Optimiser settings this sets up the options for the optimiser
options = optimoptions('fmincon', ...
    'Algorithm', 'sqp', ...
    'Display', 'iter', ...
    'MaxFunctionEvaluations', 5000);

% Run optimisation
[x_opt, cost_min, exitflag, output] = fmincon( ...
                                                @Cost, ...
                                                X0, ...
                                                [], ...
                                                [], ...
                                                [], ...
                                                [], ...
                                                LowerBound, UpperBound, ...
                                                @MBR_Constraints, ...
                                                options ...
                                                );

    function E = Evaluate(X)
        Gassing_Rate = X(1);
        theta = X(2);
        theta_c = X(3);

        Membrane_Area = 450 * N_membrane;        
        Critical_Membrane_Flux = ((1000 * Feed_VolumetricFlowrate)/(24 * Membrane_Area)) * (1 - ())
        Volume = 1;

        

        [Time,State] = ode45(@(Time,State) MBR_ODE_SEASONAL_TEMPERATURE_BIOMASSANDSUBSTRATE(Time, State,Growth, Membrane_Area, Critical_Membrane_Flux, Volume, Feed_VolumetricFlowrate, Gassing_Rate)...
            ,Timespan, State0);
        Y = State;



    end 

    function C = Cost(X)


    end 

    function R = Constraints(X)


    end 

end



