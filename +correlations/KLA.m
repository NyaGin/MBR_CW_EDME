function Kla = KLA(Gassing_Rate)
%Input: ms^-1 Output: days ^-1
%Calculates the oxygen mass transfer coefficient as a function of gassing
%rate via the empirical correlation given in the brief
Kla = 1.7 * 10^6 * (Gassing_Rate ^ 2.66);
end