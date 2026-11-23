# MBR_CW_EDME

This file should be read before reading invidiual script or function files.
In this file there is: A description of the code base layout, summaries of the 
functionality of indiviual files (or folders) and Descritions of important 
programming techiques used to simulate the MBR.

File Tree:

This is the file layout of the codebase used to simulate the MBR throughout
the cousework 

CW_MBR/
│
├── README.md
├── CW_MBR.prj
├── .gitignore
├── .gitattributes
│
├── Main.m 
├── Optimiser_main.m
├── Optimiser.m
├── MBR_initialise.m
├── MBR_model.m
├── MBR_ODE_SEASONAL_TEMPERATURE_BIOMASSANDSUBSTRATE_NOFEEDCHANGE.m
│
├── Optimisation_results_final.mat
├── Optimisation_results_10_50.mat
│
├── Optimiser.asv
├── Optimiser_main.asv
│
├── +plotting/
│   ├── plotMBRStates.m
│   ├── optimiser_plot.m
│   └── Nice_plot.asv
│
├── +membrane/
│   ├── p0Darcy.m
│   └── Lm_2h_1toms_1.m
│
├── +correlations/ 
│   ├── SeasonalTemperature.m
│   ├── SaturationoxygenConcentration.m.
│   ├── purewaterViscosity.m
│   ├── MeuMaxTemperature.m
│   ├── meu.m
│   ├── KLa.m
│   ├── kelvin2Degrees.m
│   ├── HydraulicResidenceTime.m
│   └── degrees2Kelvin.m
│
├── Tests/
│
└── resources/


Folders:

plotting/ contains functions used to plot varius types of graphs.

membrane/ contains functions used in computing membrane properties.

correlations/ contains functions that evaluate correllations required 
throughout the code base.    

.mat Files:

Optimisation_results_final.mat -> This contains the saved optimised parameters
and associated cost using 100 course and 1000 fine multi-start trails. This 
simulation took approximately 8H to complete so was saved for later analysis. 

Optimisation_results_10_50.mat -> This contains the saved optimised parameters
and associated cost using 10 course and 50 fine multi-start trails as the 
preliminary optisation used to understand the behaviour of the optermiser.
It was also used to generate the contraint usage limit data found in table 3
of the report.

Other Functions:

Optimiser.m -> This function is used to initialise fmincon and convert 
its normalised outputs back into physical design parameters.

MBR_initialise.m -> This functions is used to initialise a matlab struct 
containing input parameters and design parameter upper and lower bounds this 
was done to try and avoid declaring the same input parameters and bounds in
multiple places in Omptimiser_main or its supporting functions. The struct 
can the passed to functions requiring those parameters.

MBR_model.m -> This function file contains the constraints and cost function
required by fmincon for optermisation. It returns function handles (sometimes 
called function references or pointers in other programming languages) 
to the cost, constraint and elvauate functions initialised with fixed parameters
outlined in the breif.

MBR_ODE_SEASONAL_TEMPERATURE_BIOMASSANDSUBSTRATE_NOFEEDCHANGE.m -> This function 
defines the ODE system that is passed to ode15s or ode45 in a anonymous function
wrapper.



Scripts: 

Main.m -> This is used to integrate a single the MBR ODE system with either 
ode45 or ode15s 

Optimiser_main.m -> This contains 3 sections: PARAMETER OPTIMISER,
NUMERICAL SENSITIVITY ANALYSIS and ENGINEERING ANALYSIS.

PARAMETER OPTIMISER
    
    The optimisation procedure determines the membrane bioreactor (MBR) design parameters that minimise the estimated **10-year cost per cubic metre of permeate**, while satisfying the prescribed operating and design constraints.
    
    Four design parameters are optimised:
    
    - **Number of membrane modules 
    - **Superficial gas velocity 
    - **Hydraulic retention time 
    - **Solids retention time 
    
    ### Optimisation Method
    
    The optimisation uses MATLAB's `fmincon` function with the Sequential Quadratic Programming (SQP) algorithm.
    
    Since the number of membrane modules must be an integer, it is optimised separately from the three continuous design variables. For each candidate membrane count, the remaining parameters are optimised subject to the nonlinear constraints evaluated using the dynamic MBR model.
    
    The procedure uses a two-stage multistart search to reduce the risk of converging to local minima:
    
    1. Coarse search: Candidate membrane counts between 727 and 985 are sampled at intervals of 10, with 100 randomly initialised optimisation trials performed for each membrane count.
    2. Fine search: The three most promising membrane counts are selected, and their surrounding ranges (±10 modules) are searched using 1,000 randomly initialised optimisation trials per membrane count.
    
    The continuous design variables are normalised to the interval [0, 1] to improve numerical conditioning. MATLAB's `parfor` distributes the multistart trials across available parallel workers, while caching is used to avoid unnecessary repeated ODE integrations.
    
    The lowest-cost feasible solution identified by the search is retained. Although the multistart procedure improves the reliability of the result, it does not mathematically guarantee a global minimum.
    
    ### Running the Optimisation
    
    The optimisation is controlled from `Optimiser_main.m`, with the following setting:
    
        Rerun_optimiser = true;
    
    Setting this to `true` executes the full coarse and fine searches and saves the results to file_name.mat`.where file_name is a string that is user defined
    
    Setting it to `false` loads the previously saved results without repeating the computationally expensive optimisation.
    
    The saved results include:
    
    - `Global_min` – Best membrane count, specific cost and continuous design parameters.
    - `Clean_course_result` – Coarse-search results.
    - `Fine_search_result` – Fine-search results.
    
    The program also produces a plot of minimum specific cost against membrane count, allowing the economic influence of membrane quantity to be examined.
    
    ### Main Functions
    
  
    Optimiser_main.m`-> Controls the multistart optimisation and processes the results. 
    Optimiser.m` -> Executes constrained optimisation using `fmincon`. 
    MBR_model.m` -> Evaluates the design, solves the governing ODEs and returns the cost and constraint functions. 
    MBR_Cost.m` -> Calculates the economic objective function. 
    MBR_initialise.m` -> Initialises the model parameters and design-variable bounds. 
    
    Note: The optimisation uses the idealised single-tank cost model. The practical 34-tank design is subsequently selected and evaluated separately; it is not the direct output of the optimisation procedure.

NUMERICAL SENSITIVITY ANALYSIS
    
    This section assesses the numerical reliability of the optimised design and its sensitivity to changes in design parameters.
    
    The following analyses are performed:
    
    - Dynamic performance: Solves and plots the four governing ODE states over 365 days.
    - Parameter sensitivity: Independently varies gas velocity, HRT and SRT by ±5% of their permitted ranges, evaluating cost and feasibility.
    - Multistart convergence: Compares optimisation results from 100 and 1,000 trials per membrane count.
    - Solver accuracy:** Repeats the optimisation with tighter `ode15s` tolerances to assess numerical accuracy.
    
    The section produces reactor-state plots, sensitivity graphs and numerical convergence results.

ENGINEERING ANALYSIS    
    
    This section evaluates the selected practical design of 816 membrane modules distributed across 34 parallel tanks.
    
    One representative tank containing 24 modules is modelled using the following parameters:
    
    - Gas velocity: 0.0394 m/s
    - HRT: 0.8 days
    - SRT: 15 days
    
    The dynamic model is solved to assess operating performance and constraint compliance.
    
    A sensitivity analysis then examines ±10% changes in influent flow and COD concentration. Flow changes are evaluated under both fixed-volume and variable-volume conditions.
    
    The section produces reactor-state plots, a feasibility summary, constraint violation percentages and a constraint-margin heatmap to assess operational robustness.

Important coding techniques:

### 1. Parallel Computing

MATLAB's `parpool` and `parfor` were used to distribute independent multistart optimisation trials across six parallel workers. Each worker executes an independent `fmincon` optimisation from a randomly generated initial guess.

This reduces the total optimisation time by allowing multiple trials to run simultaneously. Each worker maintains its own model and cache, preventing interference between trials.

Although this is commonly called multithreading, the implementation uses **process-based parallel computing**, rather than conventional multithreading.

### 2. ODE Solution Caching

Evaluating the cost function and nonlinear constraints often requires the same dynamic ODE solution. Without caching, `ode15s` could repeatedly solve the same system for identical design parameters.

The `Evaluate` function stores the most recently evaluated design vector (`X_cache`), its derived results (`Result_cache`) and the raw ODE solution (`Raw_cache`).

When the same design vector is requested again, the stored results are returned without rerunning `ode15s`.

This reduces redundant numerical integration and improves optimisation efficiency.

### 3. Function Handles and Nested Functions

`MBR_model` contains three nested functions:

- `Evaluate` – Solves the ODE system and calculates derived design quantities.
- `Cost` – Calculates the ten-year specific cost.
- `Constraints` – Evaluates the nonlinear operating constraints.

MATLAB function handles are returned using:

```
matlab
CostFcn = @Cost;
ConstraintsFcn = @Constraints;
EvaluateFcn = @Evaluate;
```

These handles allow `fmincon` to evaluate the cost and constraints without needing to pass every model parameter explicitly.

Because the functions are nested within `MBR_model`, they can access shared parameters such as `N_membrane`, `P` and `Options`, as well as the cached ODE results.

This approach keeps the optimisation interface simple, avoids duplicating model calculations and allows cost and constraints to share the same dynamic solution.
