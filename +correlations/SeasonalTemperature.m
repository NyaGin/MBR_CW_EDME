function Temperature = SeasonalTemperature(day)
%Input: day Output: K
%Using the seasonal temperature model in the brief to calculate the
%temperature on a given day. Valid between 0 and 365
arguments
    day (1,1) double {mustBeReal, mustBeFinite, ...
        mustBeGreaterThanOrEqual(day,0), ...
        mustBeLessThanOrEqual(day,365)}
    end
Temperature = 0.0003*day^2 -0.1057*day +309.2;
end