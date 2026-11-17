function P = MBR_initialise()

    % Stoichiometric and kinetic parameters at 20°C
    P.Growth.meu_max_20 = 6;   % d^-1
    P.Growth.kd = 0.075;       % d^-1
    P.Growth.Ks = 1750;        % mg/L
    P.Growth.Yx_s = 0.55;      % mg/mg
    P.Growth.Yx_o = 0.7;       % mg/mg

    % ODE input parameters
    P.Feed_VolumetricFlowrate = 175000;
    P.Timespan = [0, 365];
    P.Startup_days = 15;

    % Design parameter bounds: [Gassing rate, HRT, SRT]
    P.LowerBound = [0.015, 0.8, 15];
    P.UpperBound = [0.2, 1.1, 30];
end