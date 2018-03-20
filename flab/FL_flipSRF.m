%% Function to flip an SRF about the arrival index. Flips both in time and amplitude
% IGNORE - the functionality was placed within the regular SRF calculator
function [seisOut, ierr] = FL_flipSRF(seisIn, pivot)
%  Inputs:
%    seisIn - the receiver function data vector
%    pivot  - the index where to flip the vector about (ie the phase
%    arrival)
%  Outputs:
%    Flipped data vector
%    ierr = -1 if the pivot is negative, 1 if the pivot is beyond the
%    trace, and 0 if no error
% 
% Rob Porritt, August 5th, 2014


%% Error checking
if pivot <= 0
    ierr = -1;
    return
elseif pivot > length(seisIn)
    ierr = 1;
    return
end

%% Init the output
seisOut = zeros(1,length(seisIn));


%% Go through and reverse trace





