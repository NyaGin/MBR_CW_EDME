function [X_opt, Cost_opt, Exitflag, Output, Constraints_vector] = Optimiser(Growth, Feed_VolumetricFlowrate, Timespan, N_membrane, Startup_days, Z0, LowerBound, UpperBound, Options)


% Membrane base dimensions:
L = 2.19;                   % m
W = 0.944;                  % m 
A = 0.994;                  % m - distance between the membrane and the long side of the reactor

% ODE parameter and solution caches to prevent duplicate ODE solves
X_cache = [];                                         % Cached current design parameter vector  
Result_cache = [];                                    % Cached ODE results 

% Common calculation cache

Temperature_initial = correlations.SeasonalTemperature(0);
Purewater_Viscosity_Initial = correlations.purewaterViscosity(Temperature_initial);



% Optimiser settings this sets up the options for the optimizer
options = optimoptions('fmincon', ...
    'Algorithm', 'sqp', ...
    'Display', 'off', ...
    'MaxFunctionEvaluations', 5000,...
    'UseParallel', false);

% Run optimization
[x_opt, cost_min, exitflag, output] = fmincon( ...
                                                @Cost, ...
                                                Z0, ...
                                                [], ...
                                                [], ...
                                                [], ...
                                                [], ...
                                                [0, 0, 0], [1, 1, 1], ...   % These are the normalised lower and upper bounds and so are all  0 - 1 by definition
                                                @Constraints, ...
                                                options ...
                                                );

% Reverse the normalized optimum found by fmincon.
X_opt = (UpperBound - LowerBound) .* x_opt + LowerBound;
Cost_opt = cost_min;
Exitflag = exitflag;
Output = output;
Constraints_vector = Constraints(x_opt);
% This function is used to solve the ODE only when necessary to generate 
% derived results that contain values that either need
% to be constrained or are needed by the cost function that fmincon is
% trying to minimize. This is achieved by solving the ODE once to generate
% all necessary values needed either by the Constraints function and the
% Cost function opposed to solving the same ODE in each function separately 
    function Results = Evaluate(Z0)
       
        % Reverses the normalised parameters for the ODE solving.
        X = (UpperBound - LowerBound) .* Z0 + LowerBound;
        
        
        % Check cache for potential repeated parameters.
        if (~isempty(X_cache) && isequal(X, X_cache))
            Results = Result_cache;
            return;
        end 
        
        % Extract parameters from the parameter vector and calculate
        % derived parameter needed for the ODE solve.
        Gassing_Rate = X(1);
        HRT = X(2);
        SRT = X(3);
        Critical_Membrane_Flux = ((1000 * Feed_VolumetricFlowrate)/(24 * 450 * N_membrane)) * (1 - (HRT/SRT));  % Units Lm^-2/h 
        Critical_Membrane_Flux_M = Critical_Membrane_Flux/3.6e6;                                                % Units m^3m^-2/s = m/s
        Volume = HRT * Feed_VolumetricFlowrate;
        
        P0 = membrane.p0Darcy(Critical_Membrane_Flux_M, Purewater_Viscosity_Initial);
        State0 = [50, 600, 2, P0];
        
        % Solve the ODE with the given design and derived parameters
        [Time,State] = ode15s(@(Time,State) MBR_ODE_SEASONAL_TEMPERATURE_BIOMASSANDSUBSTRATE_NOFEEDCHANGE(Time, State, Growth, Critical_Membrane_Flux_M, Volume, Feed_VolumetricFlowrate,HRT,SRT,Gassing_Rate)...
            , Timespan, State0, Options);

        %Verify the ODE solver completed the simulation
        Results.Valid = ~isempty(Time) && Time(end) >= (Timespan(end) - 1e-6);

        if ~Results.Valid

            fprintf('ODE integration failed at t = %.6f days\n', Time(end));

            % Still store invalid result in cache
            X_cache = X;
            Result_cache = Results;

            return;
        end


        
        % This truncates the solution the start of solution vector to
        % remove the says required for biomass to grow during start up 
        Running_indices = Time >= Startup_days;
        Running_state = State(Running_indices, :);
        
        % Extract the new ODE min/max values for comparison against
        % constraints 

        Results.MaxBiomass = max(Running_state(:, 1));
        Results.MaxCOD = max(Running_state(:, 2));
        Results.MinDO = min(Running_state(:, 3));
        Results.MaxTMP = max(Running_state(:, 4));



        % Store values needed in the Cost function
        Results.Volume = Volume;
        Results.Tank_base = (2 * W * N_membrane + W) * (L + 2 * A);
        Results.Tank_height = Volume/Results.Tank_base;
        Results.Gassing_rate = Gassing_Rate;
        Results.Permeate_flow = Feed_VolumetricFlowrate * (1 - (HRT/SRT));
        Results.Waste_flow = Feed_VolumetricFlowrate * (HRT/SRT);
        
        % Store derived parameters for comparison against constraints
        Results.Critical_Membrane_Flux = Critical_Membrane_Flux;
        

        % Update cache with new ODE parameters and corresponding results 
        X_cache = X;
        Result_cache = Results;

    end 

    % Constraints function required by fmincon
    function [C, C_eq] = Constraints(X)

        R = Evaluate(X);

        if ~R.Valid
            C = 1000 * ones(7,1);
            C_eq = [];

            return;
        end

        C = [
            R.MaxTMP - 20000;
            2 - R.MinDO;
            R.MaxBiomass - 20000;
            R.MaxCOD - 100;
            16 - R.Critical_Membrane_Flux;
            R.Critical_Membrane_Flux - 30;
            R.Tank_height - 25;
            ];
        
        C_eq = [];
    end 

    % This is the function is fmincon is trying to minimize subject to
    % constraints (£)
    function Total_cost = Cost(X)
    
        R = Evaluate(X);

        if ~R.Valid
            Total_cost = 1000;
            return;
        end

        % Calculating volumetric gassing rate 
        Volumetric_gassing_rate = R.Gassing_rate * R.Tank_base * 3600;
        
        % Calculating individual capital costs 
        C_membrane = 40 * (450 * N_membrane);
        C_tank = 7500 + 800 * (R.Volume)^0.65;
        C_blower = 2900 + 38 * (Volumetric_gassing_rate)^0.8;
        C_waste_pump = 5300 + 159 * (R.Waste_flow * 1000/86400)^0.9;
        
        % Applying a Lang factor of 4.74 to the total capital cost
        CAPX = 4.74 * (C_membrane + C_tank + C_blower + C_waste_pump);

        % Calculating individual operating costs
        C_aeration = 2.8 * (10^-3) * (Volumetric_gassing_rate);
        C_waste = 0.2 * (R.Waste_flow);
        C_periphery = 0.11 * 1.1 * (R.Permeate_flow);
        
        % Calculating the total operating costs over 10 years 
        OPEX = 3650 * (C_aeration + C_waste + C_periphery);
        
        % Total cost of the plant per m^3 of permeate produced
        Total_cost = (CAPX + OPEX)/(3650 * R.Permeate_flow);
    end 

end



