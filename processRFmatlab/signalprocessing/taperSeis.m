function SEIS = taperSeis( SEIS, TAPERW, taperTypeFlag )
% 
% SEIS = taperSeis( SEIS, TAPERW )
%
% Taper the seismogram using a hanning window 
%
% In: 
%   SEIS = Seismogram array (NT x NC), 1 column for each component.  
%   TAPERW = proportion of seismogram length to apply taper to
%   taperTypeFlag = 0 - no taper, 1 - hann taper, 2 - hamming taper
%
% Out:
% SEIS = seismograms after taper
%

% Edit August 2nd, 2014, Rob Porritt
% Hann and Hamming are part of the signal processing toolbox.
% But are very easy to compute, so removed

nc = size(SEIS,2); % number of components
nt = size(SEIS,1); % number of samples
nw = 2*min( round(TAPERW*nt), nt); % width of filter


if taperTypeFlag == 0
    taper = ones(nw,1);
elseif taperTypeFlag == 1
    taper = fl_hann( nw )';
elseif taperTypeFlag == 2
    taper = fl_hamming( nw )';
end

for i=1:nc,
  % add to the start
  SEIS(1:0.5*nw,i) = SEIS(1:0.5*nw,i).*taper(1:0.5*nw); 
  
  % add to the end
  SEIS((nt+1-0.5*nw):nt,i) = SEIS((nt+1-0.5*nw):nt,i).*taper(1+0.5*nw:nw); 

end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


