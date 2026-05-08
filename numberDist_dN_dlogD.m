function [ new_nN ] = numberDist_dN_dlogD( param, D )
k=0; %changed k to 0
Dbar = param(1);
s = param(2); N = param(3);
% This function calculates n_N(log Dp) (Seinfeld and Pandis, 1998, p. 421)
%
% This function requires the function, numberDist_dN_dD( D, Dbar, s, N )
%
%     nN(log Dp) = dN / d(log Dp)
%
% D    = a vector holding diameter values (Dp in book)
% Dbar = mode diameter (Dp-overbar in book)
% s    = the standard deviation (sigma_g in book)
% N    = the total number distribution integrated over all diameters
% k    = decay constant for an exponential cutoff
% NOTE: in MATLAB, log() is the natural logarithm



% Calculate the original nN(Dp) = dN / dDp
nN = numberDist_dN_dD( D, Dbar, s, N);

% Exponential decay factor (P)
P = exp(-k * D);

% Cutoff factor P to nN(log Dp) = dN / d(log Dp)
new_nN = P .* (log(10) * D .* nN);

end