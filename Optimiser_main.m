%% - PARAMETER OPTIMISER

%---------------------- Input parameters ----------------------------------
% Optimisation settings
Corse_search_increment = 10;
Corse_search_trials = 100; %100
Fine_search_trials = 1000; %1000
top_n = 3;
Search_radius = 10;
Options = odeset('RelTol', 1e-6, 'AbsTol', 1e-8);
Rerun_optimiser = false; % true - optimiser will run and results will be saves, false - results will be loaded from the .mat file
file_name = "Optimisation_results_final.mat";
% 'parpool' enables multithreading, keep the Worker_count below the number
% of CPU cores on your computer e.g. For CPU cores = 6 Worker_count = 4
Worker_count = 6;
pool = gcp('nocreate');

if ~isempty(pool)
    if pool.NumWorkers ~= Worker_count
        % Deletes current worker pool if the number of workers has changed
        % inbetween runs.
        delete(pool);
        parpool('Processes', Worker_count);
    end
else
    parpool('Processes', Worker_count);
end  

%Lower bounded constraints for the parameters: Gassing rate, critical membrane flux, HRT, SRT 
LowerBound = [0.015, 0.8, 15];
% Upper bounds for the parameters: Gassing rate, critical membrane flux, HRT, SRT
UpperBound = [0.2, 1.1, 30];
%--------------------------------------------------------------------------

% -------------- Computes the minimum cost --------------------------------

% Creates a row vector containing the values of N to be optimized for the
% course search.
if Rerun_optimiser == true
    tic % Used to measure the code run time between the 'tic' and 'toc'
    N_membrane = unique([727:Corse_search_increment:985, 985]);
    
    % Optimises parameter for each N given in 'N_membrane' and picks the 3 most
    % promising N for a finer search with more multi-start iterations per N.
    Corse_search_result = N_search(N_membrane, Corse_search_trials, Options);
    Clean_course_result = clean_results(Corse_search_result);
    [~, indices] = mink(Clean_course_result(2, :), min(top_n, size(Clean_course_result, 2)));
    Best_corse_N = Clean_course_result(1, indices);
    
    % Creates the row vector containing the values of N to be optimised for the
    % fine search.
    Expanded = Best_corse_N(:) + (-Search_radius:Search_radius);
    Best_fine_N = unique(Expanded(:).');
    Fine_search_result = clean_results(N_search(Best_fine_N, Fine_search_trials, Options));
    
    % Picks the parameters (and N) corresponding to the lowest cost
    [Cost_opt, index] = min(Fine_search_result(2, :));
    X_opt = Fine_search_result(3:end, index);
    N_opt = Fine_search_result(1, index);
    Global_min = [N_opt; Cost_opt; X_opt;];
    
    

    % Save the important results in an .mat file for easy accessibly and
    % reusability
    save(file_name, "Global_min", "Clean_course_result", "Fine_search_result")

    % Printing the code run time to the terminal
    Elapsed_time = toc;
    fprintf('Optimisation completed in %.2f seconds\n', Elapsed_time);

end

% loads results from the .mat file
Saved_Results = load(file_name);

% Prints the Global minimum in the terminal

fprintf('\n--- Global Minimum ---\n');
fprintf('Number of membranes: %d\n', Saved_Results.Global_min(1));
fprintf('Cost: %.6f £/m^3\n', Saved_Results.Global_min(2));
fprintf('Gassing rate: %.6f m/s\n', Saved_Results.Global_min(3));
fprintf('HRT: %.4f days\n', Saved_Results.Global_min(4));
fprintf('SRT: %.4f days\n\n', Saved_Results.Global_min(5));

%--------------------------------------------------------------------------

% -----------------Plot Cost against N ------------------------------------

% Concatenates the fine and course N search into a single matrix then
% sorts the resulting matrix based off the price stored in row 2 low->high
% removes any columns with duplicate N - 'stable' retains the first column
% for each unique N, hence preserving the instance of N with the low cost
% finally resorts the matrix based off N stored in row 2 ready for plotting
concatenated = [Saved_Results.Clean_course_result, Saved_Results.Fine_search_result];
[~, indices] = sort(concatenated(2, :));
concatenated = concatenated(:, indices);
[~, indices] = unique(concatenated(1, :), 'stable');
concatenated = concatenated(:, indices);
[~, indices] = sort(concatenated(1, :));
Fine_Course_results = concatenated(:, indices);


% Building a struct to pass to 'Nice_plot' containing data to be plotted in
% fig1
fig1.x = Fine_Course_results(1, :);
fig1.y = Fine_Course_results(2, :);
fig1.x_label = 'Number of membrane modules';
fig1.y_label = '£ 10 year cost / m^3 permeate';
fig1.Title = 'Minimum cost vs membrane count';
plotting.optimiser_plot(fig1)
%--------------------------------------------------------------------------


%% - NUMERICAL SENSITIVITY ANALYSIS 

% Loading optimum design parameters 
Saved_Results = load(file_name);

% Initialing non-design parameters 
P = MBR_initialise();

% Initialises design parameters and optimal cost
N_membrane = Saved_Results.Global_min(1);
Cost_opt = Saved_Results.Global_min(2);
Gassing_Rate = Saved_Results.Global_min(3);
HRT = Saved_Results.Global_min(4);
SRT = Saved_Results.Global_min(5);
X_opt = [Gassing_Rate, HRT, SRT];
Z_opt = (X_opt - P.LowerBound)./(P.UpperBound - P.LowerBound);

% Initialise ode modeling functions 
[CostFcn, ConstraintsFcn, EvaluateFcn] = MBR_model(N_membrane, P, Options);


%------------------ Plot ODE states given Z_opt ---------------------------

[~, Raw_practical_states] = EvaluateFcn(Z_opt); % Evaluate takes normalised design parameters

% plot MBR States for the optimum design parameters 
plotting.plotMBRStates(Raw_practical_states.Time, Raw_practical_states.State, 2)

%--------------------------------------------------------------------------

%----------------------- Constraints analysis -----------------------------

Constraints_vector = ConstraintsFcn(Z_opt); % Evaluate takes un-normalised design parameters

Limits = [20000; 2.2; 18182; 100; 16; 30; 22.73;]; 

Usage = 100 .* (Constraints_vector./Limits + 1);

fprintf('Max TMP usage: %4f\n', Usage(1))
fprintf('Min DO usage: %4f\n', Usage(2))
fprintf('Max Biomass usage: %4f\n', Usage(3))
fprintf('Max COD: %4f\n', Usage(4))
fprintf('Min Critical membrane flux: %4f\n', Usage(5))
fprintf('Max Critical membrabe flux: %4f\n', Usage(6))
fprintf('Max Tank height: %4f\n\n', Usage(7))

%--------------------------------------------------------------------------

% ------------------ Local sensitivity analysis ---------------------------

Perturbation = 0.05;  % 5% of the permitted parameter range
Test_points = 40; % Number of points created within the total perturbation pf each parameter

% This function carries out the sensitivity analysis, the last to arguments
% are function handles so the cost and constraint function can be
% evaluated
Test_opt_sensitivity(Z_opt, Perturbation, Test_points, P, CostFcn, ConstraintsFcn)

%--------------------------------------------------------------------------

% ------------------ Multi-start sensitivity analysis ---------------------
Saved_Results = load(file_name);

Coarse = Saved_Results.Clean_course_result;
Fine = Saved_Results.Fine_search_result;

[N_shared, iC, iF] = intersect(Coarse(1,:), Fine(1,:));

Comparison = table( N_shared', Coarse(2,iC)', Fine(2,iF)', 'VariableNames', {'N', 'Cost_100', 'Cost_1000'});

Comparison.Improvement_pct = 100 * (Comparison.Cost_100 - Comparison.Cost_1000) ./ Comparison.Cost_100;

disp(Comparison)
%--------------------------------------------------------------------------

% -------------------- Optimum ode error analysis -------------------------

Options = odeset('RelTol', 1e-8, 'AbsTol', 1e-10);
N = Saved_Results.Global_min(1);

% Original optimum in physical units
X0 = Saved_Results.Global_min(3:5).';

% Normalise for the optimiser
Z0 = (X0 - P.LowerBound) ./ (P.UpperBound - P.LowerBound);

% Optimiser returns physical parameters
[X_new, Cost_new, Exitflag, Output] = Optimiser(N, Z0, P, Options);

% Normalise again only for EvaluateFcn
Z_new = (X_new - P.LowerBound) ./ (P.UpperBound - P.LowerBound);

[CostFcn, ConstraintsFcn, EvaluateFcn] = MBR_model(N, P, Options);

R = EvaluateFcn(Z_new);
c = ConstraintsFcn(Z_new);

fprintf('Cost: %.8f £/m^3\n', CostFcn(Z_new));
fprintf('Gassing rate: %.8f m/s\n', X_new(1));
fprintf('HRT: %.8f days\n', X_new(2));
fprintf('SRT: %.8f days\n', X_new(3));
fprintf('Minimum DO: %.8f mg/L\n', R.MinDO);
fprintf('Maximum biomass: %.8f mg/L\n', R.MaxBiomass);
fprintf('Feasible: %d\n', all(c <= 0));
fprintf('Exitflag: %d\n', Exitflag);

%--------------------------------------------------------------------------
%% - ENGINEERING ANALYSIS

P = MBR_initialise();

Options = odeset('RelTol', 1e-6, 'AbsTol', 1e-8);

% Practical design
N_practical = 816;
N_tanks = 34;

Membranes_per_tank = N_practical / N_tanks;

% Design parameter order: [Gassing rate, HRT, SRT]
X_practical = [0.0394, 0.8, 15];

% Feed flow rate per tank
P.Feed_VolumetricFlowrate = P.Feed_VolumetricFlowrate / N_tanks;

% Normalise the design variables
Z_practical = (X_practical - P.LowerBound) ./(P.UpperBound - P.LowerBound);

% Initialise the single-tank model
[CostFcn, ConstraintsFcn, EvaluateFcn] = MBR_model(Membranes_per_tank, P, Options);

% Evaluate practical design
[~, Raw_practical_states] = EvaluateFcn(Z_practical);

plotting.plotMBRStates(Raw_practical_states.Time, Raw_practical_states.State, 2);

% Check constraints
Constraints_practical = ConstraintsFcn(Z_practical);

fprintf('Practical design feasible: %d\n', ...
    all(Constraints_practical <= 0));

% Parameters for sensitivity analysis
N_opt = Membranes_per_tank;
X_opt = X_practical;

Qf_opt = P.Feed_VolumetricFlowrate;

% Operating volume per tank
V_opt = Qf_opt * X_opt(2);

% Define sensitivity scenarios
Scenario = [
    "Baseline"
    "Flow +10%, fixed V"
    "Flow -10%, fixed V"
    "Flow +10%, variable V"
    "Flow -10%, variable V"
    "COD +10%"
    "COD -10%"
    ];

Q_factor = [1; 1.1; 0.9; 1.1; 0.9; 1; 1];
COD_factor = [1; 1; 1; 1; 1; 1.1; 0.9];

% True means reactor volume remains fixed
Fixed_volume = [true; true; true; false; false; true; true];

Sensitivity = table(Scenario, Q_factor, COD_factor, Fixed_volume);

% This function carries out the operating conditions sensitivity analysis on the optimum design parameters 
Test_operating_sensitivity( Sensitivity, P, X_opt, Qf_opt, N_opt, V_opt, Limits, Options);







%% - LOCAL FUNCTIONS

% - Functions used in the 'FIND OPTIMAL PARAMETERS' section:

function result = N_search(N_range, Trials, Options)

% This initialises the parameters required for the ODE solving (not the
% design parameter!)
P = MBR_initialise();

N_min_cost = nan(5, length(N_range));
counter = 0;
for N = N_range

    Trial_min_cost = nan(1, Trials); % Stores the multi-start costs for each the current looped N
    Trial_min_results = nan(3, Trials);

    % parallel for loop to spread multi-start trials across multiple CPU
    % cores for reduced compute time.
    parfor Trial = 1:Trials

        % Rand generates a random 1x3 row vector with entries between 0 - 1
        Z0 = rand(1, 3); 
        
        % Optimise for the randomly generated Z0 and N
        [~, ~, ~, Output] = Optimiser(N, Z0, P, Options);
        
        % Checks if the optimiser was able to find an improved set of
        % design parameters
        if isstruct(Output.bestfeasible) && ~isempty(Output.bestfeasible)
            
            % Extract and best feasible design parameter set found and then
            % unnormalised it.
            Z_best = Output.bestfeasible.x(:).';
            X_best = P.LowerBound + (P.UpperBound - P.LowerBound) .* Z_best;
            
            % The cost and optimised parameters are stored outside the
            % scope of the parallel loop for later use.
            Trial_min_results(:, Trial) = X_best.';
            Trial_min_cost(1, Trial) = Output.bestfeasible.fval;

        else
            % If no optimised parameters exist store NAN in there place 
            Trial_min_results(:, Trial) = nan(3, 1);
            Trial_min_cost(1, Trial) = NaN;
        end

    end

    counter = counter + 1;
    % Record each iterated value of N in order
    N_min_cost(1, counter) = N;
    % For each N find the indicies of the multi-start trials that
    % successfully minimised the cost if no multi-start trials where
    % successful, Trial_min_cost will be filled with NANs and so
    % Valid_indices will be empty.
    Valid_indices = find(isfinite(Trial_min_cost));
    
    % Checks to see if any of the multi-start trials where successful 
    if ~isempty(Valid_indices)
        
        % Store the best optimised parameter and cost for each Nth column
        % of N_min_cost
        [Best_cost, Local_index] = min(Trial_min_cost(Valid_indices)); 
        Best_index = Valid_indices(Local_index);
        N_min_cost(2, counter) = Best_cost;
        N_min_cost(3:end, counter) = Trial_min_results(:, Best_index);

    end


end

result = N_min_cost;
end 

% This function is used to remove columns containing NAN values from a
% given 'dirty' matrix.
function Cleaned = clean_results(dirty)

dirty(:, any(isnan(dirty), 1)) = [];

Cleaned = dirty;

end 

% - Functions used in the 'DESIGN ANALYSIS' section:

function [] = Test_opt_sensitivity(Z_opt, Perturbation, Test_points, P, CostFcn, ConstraintsFcn)

figure;
tiledlayout(3, 1);

Parameter_names = {'Gassing rate', 'HRT', 'SRT'};
Parameter_units = {'m/s', 'days', 'days'};

    for i = 1:3
    
        % Generate perturbations in normalised coordinates whilst not
        % allowing the max and min normalised to move our of the 0 -> 1
        % range
        Z_values = linspace(max(0, Z_opt(i) - Perturbation), min(1, Z_opt(i) + Perturbation), Test_points);
    
        % Ensures the original optimum is included in the test points
        Z_values = unique([Z_values, Z_opt(i)]);
    
        Costs = nan(size(Z_values));
        % Feasible records for each point is the point feasible (true) or
        % unfeasible (false)
        Feasible = false(size(Z_values));
    
        for j = 1:numel(Z_values)
    
            % Varying each parameter independently
            Z = Z_opt;
            Z(i) = Z_values(j);
    
            % Evaluating cost and constraints functions
            Costs(j) = CostFcn(Z);
            c = ConstraintsFcn(Z);
    
            Feasible(j) = all(isfinite(c)) && all(c <= 0);
    
        end
    
        % Convert back to physical parameters for plotting
        X_values = P.LowerBound(i) + (P.UpperBound(i) - P.LowerBound(i)) .* Z_values;
        X_opt = P.LowerBound + (P.UpperBound - P.LowerBound) .* Z_opt;
        Cost_opt = CostFcn(Z_opt);

        nexttile; % Plot each graph on separate axis 
        hold on;
        
        % Plotting the feasible and unfeasible points separately but on the
        % same graph for each parameter so the the feasible and unfeasible
        % points can be marked differently (green 'o' and red 'x'
        % respectively)
        plot(X_values(Feasible), Costs(Feasible), 'go');
        plot(X_values(~Feasible), Costs(~Feasible), 'rx');
    
        plot(X_opt(i), Cost_opt, 'bx', 'MarkerSize', 10, 'MarkerFaceColor', 'k');
        
        % Adding lables 
        xlabel([Parameter_names{i}, ' (', Parameter_units{i}, ')']);
        ylabel('Cost (£/m^3)');
        
        % Adding legend
        legend('Feasible', 'Infeasible', 'Optimum');
        grid on;
    
    end

end


% - Functions used in the 'ENGINEERING ANALYSIS' section:


function [] = Test_operating_sensitivity(Sensitivity, P, X_opt, Qf_opt, N_opt, V_opt, Limits, Options)

% Number of sensitivity scenarios
N_scenarios = height(Sensitivity);

% Preallocate results
Constraints_results = nan(7, N_scenarios);
HRT_results = nan(N_scenarios, 1);
Volume_results = nan(N_scenarios, 1);
Bounds_results = false(N_scenarios, 1);

for i = 1:N_scenarios

    % Independent copy of model parameters
    P_test = P;

    % Apply changes to influent conditions
    P_test.Feed_VolumetricFlowrate = ...
        Qf_opt * Sensitivity.Q_factor(i);

    P_test.COD_factor = Sensitivity.COD_factor(i);

    % Design parameter order: [Gassing rate, HRT, SRT]
    X_test = X_opt;

    % Adjust HRT to maintain constant reactor volume
    if Sensitivity.Fixed_volume(i)

        X_test(2) = V_opt / P_test.Feed_VolumetricFlowrate;

    end

    % Check design-variable bounds
    Bounds_results(i) = ...
        all(X_test >= P.LowerBound) && ...
        all(X_test <= P.UpperBound);

    % Normalise design parameters
    Z_test = (X_test - P.LowerBound) ./ ...
             (P.UpperBound - P.LowerBound);

    % Reinitialise model for each scenario
    [~, ConstraintsFcn, ~] = ...
        MBR_model(N_opt, P_test, Options);

    % Evaluate nonlinear constraints
    Constraints_results(:, i) = ConstraintsFcn(Z_test);

    % Record HRT and operating volume
    HRT_results(i) = X_test(2);

    Volume_results(i) = ...
        X_test(2) * P_test.Feed_VolumetricFlowrate;

end

% Constraint names
Constraint_names = [
    "TMP"
    "DO"
    "Biomass"
    "COD"
    "Min flux"
    "Max flux"
    "Tank height"
];

% Percentage constraint violation
Violation = 100 * max(0, Constraints_results) ./ Limits;

% Signed constraint margins
% Positive = feasible
% Zero     = active
% Negative = violated
Margin = -100 * Constraints_results ./ Limits;

% Overall feasibility includes nonlinear constraints AND variable bounds
Feasible = all(isfinite(Constraints_results) & Constraints_results <= 0, 1).'& Bounds_results;

% Summary table
Summary = table(Sensitivity.Scenario, HRT_results, Volume_results, Bounds_results, Feasible, 'VariableNames', {'Scenario', 'HRT', 'Volume', 'BoundsFeasible', 'Feasible'});

disp(Summary)

% Constraint violation table
Violation_table = array2table(Violation.', 'VariableNames', cellstr(Constraint_names));

Violation_table = addvars(Violation_table, Sensitivity.Scenario, 'Before', 1, 'NewVariableNames', 'Scenario');
disp(Violation_table)

% Plot nonlinear constraint margins
figure;
heatmap(Sensitivity.Scenario, Constraint_names, Margin);
title('Constraint margins under altered feed conditions');

end


