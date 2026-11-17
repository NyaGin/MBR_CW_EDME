%% - FIND OPTIMAL PARAMETERS

%---------------------- Input parameters ----------------------------------
% Optimisation settings
Corse_search_increment = 25;
Corse_search_trials = 100;
Fine_search_trials = 100;
top_n = 3;
Search_radius = 25;
Options = odeset('RelTol', 1e-3, 'AbsTol', 1e-6);
Rerun_optimiser = true; % true - optimiser will run and results will be saves, false - results will be loaded from the .mat file

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
    N_membrane = unique([600:Corse_search_increment:1000, 1000]);
    
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
    
    % This is a small test to see if the global minimum changes significantly
    % with ode15 tolerance.
    Options = odeset('RelTol', 1e-6, 'AbsTol', 1e-8);
    Optimum_test = N_search(N_opt, Fine_search_trials, Options);

    % Save the important results in an .mat file for easy accessibly and
    % reusability
    save('Optimisation_results.mat', "Global_min", "Optimum_test", "Clean_course_result", "Fine_search_result")

    % Printing the code run time to the terminal
    Elapsed_time = toc;
    fprintf('Optimisation completed in %.2f seconds\n', Elapsed_time);

end

% loads results from the .mat file
Results = load('Optimisation_results.mat');

% Prints the Global minimum in the terminal

fprintf('\n--- Global Minimum ---\n');
fprintf('Number of membranes: %d\n', Results.Global_min(1));
fprintf('Cost: %.6f £/m^3\n', Results.Global_min(2));
fprintf('Gassing rate: %.6f m/s\n', Results.Global_min(3));
fprintf('HRT: %.4f days\n', Results.Global_min(4));
fprintf('SRT: %.4f days\n', Results.Global_min(5));

% Prints the tested global minimum in the terminal
fprintf('\n--- Global Minimum (increased ode15 tolerances) ---\n');
fprintf('Number of membranes: %d\n', Results.Optimum_test(1));
fprintf('Cost: %.6f £/m^3\n', Results.Optimum_test(2));
fprintf('Gassing rate: %.6f m/s\n', Results.Optimum_test(3));
fprintf('HRT: %.4f days\n', Results.Optimum_test(4));
fprintf('SRT: %.4f days\n', Results.Optimum_test(5));
%--------------------------------------------------------------------------

% -----------------Plot Cost against N ------------------------------------

% Concatenates the fine and course N search into a single matrix then
% sorts the resulting matrix based off the price stored in row 2 low->high
% removes any columns with duplicate N - 'stable' retains the first column
% for each unique N, hence preserving the instance of N with the low cost
% finally resorts the matrix based off N stored in row 2 ready for plotting
concatenated = [Results.Clean_course_result, Results.Fine_search_result];
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


%% - DESIGN ANALYSIS 

% Loading optimum design parameters 
Results = load('Optimisation_results.mat');

% Initialing non-design parameters 
P = MBR_initialise();

% Initialises design parameters and optimal cost
N_membrane = Results.Optimum_test(1);
Cost_opt = Results.Optimum_test(2);
Gassing_Rate = Results.Optimum_test(3);
HRT = Results.Optimum_test(4);
SRT = Results.Optimum_test(5);
X_opt = [Gassing_Rate, HRT, SRT];
Z_opt = (X_opt - P.LowerBound)./(P.UpperBound - P.LowerBound);

% Initialise ode modeling functions 
[CostFcn, ConstraintsFcn, EvaluateFcn] = MBR_model(N_membrane, P, Options);


%------------------ Plot ODE states given Z_opt ---------------------------

[Results, Raw_states] = EvaluateFcn(Z_opt);

% plotMBRStates

%--------------------------------------------------------------------------

%----------------------- Constraints analysis -----------------------------

Constraints = Constraints

%--------------------------------------------------------------------------




%% - ENGINEERING ANALYSIS 





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

        [~, ~, ~, Output] = Optimiser(N, Z0, P, Options);

        if isstruct(Output.bestfeasible) && ~isempty(Output.bestfeasible)

            Z_best = Output.bestfeasible.x(:).';

            X_best = P.LowerBound + (P.UpperBound - P.LowerBound) .* Z_best;

            Trial_min_results(:, Trial) = X_best.';

            Trial_min_cost(1, Trial) = Output.bestfeasible.fval;

        else
            Trial_min_results(:, Trial) = nan(3, 1);
            Trial_min_cost(1, Trial) = NaN;
        end

    end

    counter = counter + 1;

    N_min_cost(1, counter) = N;

    Valid_indices = find(isfinite(Trial_min_cost));

    if ~isempty(Valid_indices)

        [Best_cost, Local_index] = min(Trial_min_cost(Valid_indices)); 

        Best_index = Valid_indices(Local_index);

        N_min_cost(2, counter) = Best_cost;
        N_min_cost(3:end, counter) = Trial_min_results(:, Best_index);

    end


end

result = N_min_cost;
end 

function Cleaned = clean_results(dirty)

dirty(:, any(isnan(dirty), 1)) = [];

Cleaned = dirty;

end 

% - Functions used in the 'DESIGN ANALYSIS' section:


% - Functions used in the 'ENGINEERING ANALYSIS' section: