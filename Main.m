%Notes The MBR is assumed to operate at a constant liquid volume maintained by an ideal level-control system,
% with permeate withdrawal regulated to balance the feed and sludge-wasting flows.
%  The selected operating volume includes an allowance above the minimum required process volume.
%  Consequently, liquid-level control dynamics are excluded from the process model,
%  while the effect of the selected working volume is retained in the governing mass balances.
%Assumed ideal control for the models with V = Vsetpoint Qp = Qf-Qw and
%O>=Omin.



% Stoichiometric and kinetic parameters at 20°C
Growth.meu_max_20 = 6;  % d^-1
Growth.kd = 0.075;      % d^-1
Growth.Ks = 1750;       % mg/L
Growth.Yx_s = 0.55;     % mg/mg
Growth.Yx_o = 0.7;      % mg/mg

%Initial Conditions
state0 = [50,600]; %[Initial biomass conc mgL^-1, CODinitial mgL^-1]
