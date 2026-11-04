function O_star = SaturationoxygenConcentration(Temperature)
%Input: Degrees C Output: mgL^-1
%Empirical relation taken from the brief relating the temperature
%dependence of the dissolved oxygen concentration in water
O_star = 0.0017 * Temperature^2 - 0.2331 * Temperature + 13.019;
end
