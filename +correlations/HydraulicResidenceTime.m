function theta = HydraulicResidenceTime(Feed_VolumentricFlowrate, Volume)
%Input: m^3d^-1, m^3Output:d^-1
%This function calculates the residence time of the broth in the reactor

theta = Volume/Feed_VolumentricFlowrate;
if Feed_VolumentricFlowrate <= 0 || Volume < 0
    error('Flow rate must be positive and volume must be nonnegative.');

end