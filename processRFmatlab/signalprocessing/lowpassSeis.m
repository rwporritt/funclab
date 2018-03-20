function SEIS=lowpassSeis(SEIS, DT, FLP,NORD)
% low pass a seismogram
%
% SEIS = lowpassSeis(SEIS, DT, FLP)
% SEIS = lowpassSeis(SEIS, DT, FLP, NORD)
%
% Low pass all components of the seismogram using a (default) 2nd order
% butterworth filter with 2 passes.  The cutoff frequency must be 0.0
% < Wn <= 1.0, with 1.0 corresponding to half the sample rate, or will
% return an error.
%
% IN: 
% SEIS = Seismogram array (NT x NC), 1 column for each component.  
% DT = sample interval in s
% FLP = low pass freq in Hz (FHP<FLP)
% NORD = order of filter
%
% OUT:
% SEIS = seismogram after band pass
%
%

%   lowpassSeis.m --- 
%  
%  Filename: lowpassSeis.m
%  Description: low pass N component seismograms
%  Author: Robert W. Porritt 
%  Maintainer: I. W. Bailey
%  Created: Thurs June 23 15:00:26 2011 (-0800)
%  Version: 1
%----------------------------------------------------------------------
%  
%   Change Log:
%  
%  
%----------------------------------------------------------------------
%  
%   Code:

if( nargin < 4)
  norder=2;
else
  norder=NORD;
end

% Get the number of components read in
[nt, nc] = size(SEIS);% number of samples and components
if( nt == 1 ), 
  nt = nc; nc = 1; SEIS = SEIS.';
end

% Nyquist frequency
fny=0.5/DT;

% Passband array for butterworth filter
wn = FLP./fny;

% make the butterworth filter
[z, p, k] = butter( norder, wn, 'low' );
[sos,g] = zp2sos(z,p,k);% Convert to SOS form

%Apply the band pass filter to each component
SEIS = sosfilt( sos, SEIS, 1);

return;

%----------------------------------------------------------------------
%   lowpassSeis.m ends here
