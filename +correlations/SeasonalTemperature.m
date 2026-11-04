function Temperature = SeasonalTemperature(day);
%Input: day Output: K
%Using the seasonal temperature model in the brief to calculate the
%temperature on a given day. Valid between 0 and 365
Temperature = 0.0003*day^2 -0.1057*day +309.2;
end