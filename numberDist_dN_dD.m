function [ nN ] = numberDist_dN_dD( D, Dbar, s, N )
% This function calculates n_N(Dp) (Seinfeld and Pandis, 1998, p. 421)
%
%     nN(Dp) = dN / dDp
%
% D    = a vector holding diameter values (Dp in book)
% Dbar = mode diameter (Dp-overbar in book)
% s    = the standard deviation (sigma_g in book)
% N    = the total number distribution integrated over all diameters
%
% NOTE: in MATLAB, log() is the natural logarithm

term1 = N;
term2 = sqrt(2*pi) * D * log(s);

term12 = term1 ./ term2; % Combine terms

term3 = ( log(D) - log(Dbar) ).^2;
term4 = 2 * log(s)^2;

term34 = -1 * term3 / term4; % Combine terms

% Final answer
nN = term12 .* exp( term34 );

end