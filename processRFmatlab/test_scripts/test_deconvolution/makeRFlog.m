function [RFt, rms, nwl] = makeRFlog( UIN, WIN, TDEL, DT, NT, ARRIVAL,...
					     LBASE, F0, VB)
% Uses log(A/B) = log(A) - log(B) for Rfs
%
% [RFt, rms, nwl] = makeRFlog( UIN, WIN, TDEL, DT, NT, ARRIVAL, LBASE, F0, VB)
%
% Do water level deconvolution using the method of langston (1979)
%
% IN: 
% UIN = numeratory amplitudes 
% WIN = denominator amplitudes
% TDEL = time delay to add (s)
% DT = sample interval (s)
% NT = number samples
% ARRIVAL = The time of the source arrival used to determine when the noise
% ends
% LBASE = base of the logarithm
% F0 = gaussian filter width parameter (Hz)
% VB = verbose output
%
% OUT:
% RFt = receiver function
% rms = percentage of numerator power not fit by conv(RFt,WIN)
% nlw = number of samples set to water level

%--- makeRFwater.m --- 
% 
% Filename: makeRFwaterOptimized.m
% Description: 
% Author: T Owens (1982), G Randall, C Ammon, IW Bailey (2010), RW Porritt
% (2015)
% Maintainer: RW Porritt
% Created: Fri Apr 24 08:03 2015 (+0900)
% Version: 1
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%--- Change Log:
% 
% 
%--- Code:
if( nargin < 9 ), VB = true; end
isUnitAmp = 0;

% get dimensions right
if( size(UIN,1) > size(UIN,2) ), UIN = UIN.'; end
if( size(WIN,1) > size(WIN,2) ), WIN = WIN.'; end

% ft params
nft = 2^nextpow2(2*NT);  % nearest greater power of 2, use double time to avoid overlap
nfpts = nft/2 + 1;     % number of freq samples in this range
fny = 1./(2.*DT);      % nyquist
delf = fny/(0.5*nft);

if( VB ),
  fprintf('nt: %i, nfpts: %i, nft: %i, fny: %.2f, df: %.3f\n',...
	  [NT, nfpts, nft, fny, delf]);
end

% frequencies
freq = delf*(0:1:(nfpts-1));
w = 2*pi*freq;

% containers
RFf = zeros(1,nft); % Rfn in freq domain
UPf = zeros(1,nft); % predicted numer in freq domain

% Convert seismograms to freq domain
Uf = fft( UIN(1:NT), nft );
Wf = fft( WIN(1:NT), nft );

% denominator
Df = Wf.* conj(Wf);
dmax = max( real( Df ) );

% compute gaussian filter
gaussF = gaussFilter( DT, nft, F0 );

% numerator
Nf = gaussF .* Uf .* conj(Wf);

% compute RF
%RFf = Nf ./ Df;
RFf = 2.^(log2(Nf) - log2(Df));

% compute predicted numerator
UPf = RFf.*Wf;

% add phase shift to RF
w = [w, -fliplr(w(2:end-1))];
RFf = RFf .* exp(-1i*w*TDEL);

% back to time domain
RFt = ifft( RFf , nft );
RFt = real(RFt(1:NT));

% compute the fit
Uf = gaussF.*Uf; % compare to filtered numerator
Ut=real( ifft(Uf, nft ) );
UPt=real( ifft(UPf, nft ) );

powerU = sum((Ut(1:NT)).^2);
rms = sum( (UPt(1:NT) - Ut(1:NT) ).^2 )/powerU;

if( VB ),
  fprintf('Finished. Misfit = %.2f per cent \n',100*rms)
end

% if we want a unit amplitude gaussian filter apply the following
if isUnitAmp,
  gnorm = sum(gaussF)*delf*DT;
  RFt = real(RFt)/gnorm;
end

return 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License as
% published by the Free Software Foundation; either version 3, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; see the file COPYING.  If not, write to
% the Free Software Foundation, Inc., 51 Franklin Street, Fifth
% Floor, Boston, MA 02110-1301, USA.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%--- makeRFwaterOptimized.m ends here