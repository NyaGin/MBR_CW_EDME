function meu = purewaterViscosity(Temperature)
%Inputs: Kelvin Outputs: pas or nm^-2s
%This works out the viscosity of pure water as a function of temperature
%with an empirical correlation taken from Çengel, Y.A. and Cimbala, J.M. (2014)
%Fluid Mechanics: Fundamentals and Applications. 3rd edn. New York: McGraw-Hill Education. 
% Available at:
% https://studylib.net/doc/29014226/yunus-cengel-fluid-mechanics (Accessed:
% 3 November 2026): p53
%For liquids, the viscosity is approximated as
% Liquids: m 5 a10 b/(T 2c) (2–37)
% where again T is absolute temperature and a, b, and c are experimentally
% determined constants. For water, using the values a = 2.414 * 10^-5 Ns/m^2,
% b = 247.8 K, and c = 140 K results in less than 2.5 percent error in viscosity
% in the temperature range of 0°C to 370°C (Touloukian et al., 1975).
arguments
    Temperature (1,1) double {mustBeReal, mustBeFinite, ...
        mustBeGreaterThanOrEqual(Temperature,0), ...
        mustBeLessThanOrEqual(Temperature,370)}
    end

a = 2.2414 * 10^-5; %Nsm^-2
b = 247.8; %K
c = 140; %K
meu = a * 10^(b/(Temperature-c));

end