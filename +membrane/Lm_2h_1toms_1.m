function metres_per_second = Lm_2h_1toms_1(Flux)
%Input: Lm^-2h^-1 Output: ms^-1
%This function converts liquid flux from litres per metre squared per hour
%to metres per second 
metres_per_second = Flux * 1e-3 / 3600;

end
