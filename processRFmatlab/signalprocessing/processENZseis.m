function [zseis, rseis, tseis, hdr, ierr] = processENZseis(eseis,nseis,zseis,hdr,opt,isVb,isPlot)

% From ENZ components and header info, chop around arrival, resample, band-pass and rotate 
% 
% [zseis, rseis, tseis, hdr] = processENZseis(eseis,nseis,zseis,hdr,opt,isVb,isPlot)
%
% IN: 
% eseis,nseis,zseis = seis amplitudes for the East North and Z components
% opt = structure containing ...
%     opt.PHASENM = name of arrival to chop around
%     opt.TBEFORE,opt.TAFTER = time before and after to chop
%     opt.TAPERW = taper width to use before bandpass
%     opt.FHP,opt.FLP = band pass high and low passes (Hz)
%     opt.FORDER = order of the band pass filter to use
%     opt.DTOUT = desired sample interval
%     opt.taperTypeFlag = 0 no taper, 1 hann taper, 2 hamming taper
% isVb = output description of steps
% isPlot = plot after each step
% ierr - 0 for data is ok, non-zero for errors
%
% OUT:
% zseis,rseis,tseis = seis amplitudes for the Z R and T components
% hdr = updated header 

%
%-- processENZseis.m --- 
%  
%  Filename: processENZseis.m
%  Author: Iain Bailey
%  Created: Sun Jul  3 23:05:23 2011 (-0700)
%  Version: 1
%  Last-Updated: Thu Sep  1 10:40:30 2011 (-0700)
%            By: Iain Bailey
%      Update #: 63
%  Compatibility: 
%
%---------------------------------------------------------
%  
%-- Change Log:
%  Sun Jul  3: Changed display when waiting for user input
%  Thu Sep  1: changed plotting call
%  Sat Aug  2 (2014): changed option to allowing hamming taper. 
%  Tue Aug  5 (2014): added ierr tracking
%
%---------------------------------------------------------
%  
%-- Code:

if( nargin < 7 ), isPlot = false; end % default don't plot
if( nargin < 6 ), isVb = false; end % default don't output info

% combine seismograms into one array
if( size( eseis, 2 ) > size( eseis, 1 ) ), eseis = eseis'; end 
if( size( nseis, 2 ) > size( nseis, 1 ) ), nseis = nseis'; end 
if( size( zseis, 2 ) > size( zseis, 1 ) ), zseis = zseis'; end 
enzseis = [ eseis, nseis, zseis ];

% outputs to init
%rseis, tseis, hdr
rseis = zeros(length(zseis),1);
tseis = zeros(length(zseis),1);

% get arrival times 
[t, ~, atimes, labels] = getTimes( hdr );

if( isPlot ), 
  figure()
  clf;
  plims = plot3seis(t, enzseis(:,1), t, enzseis(:,2), t, enzseis(:,3), ...
		    struct( 'clabs', ['E';'N';'Z'] ) ); hold on;
  input('Press a key to continue ');  
end

% chop around the specified arrival
tarr = getArrTime( opt.PHASENM, atimes, labels );

if( isVb ), 
  fprintf('\t\tAdjust time: %f -- %f\n',[ tarr-opt.TBEFORE, tarr+opt.TAFTER]); 
end
if(isVb),
    WarnFlag = 1;
else
    WarnFlag = 0;
end
[enzseis, t] = chopSeis( enzseis, t, tarr-opt.TBEFORE, tarr+opt.TAFTER, WarnFlag );

% adjust times
if numel(t) < 10 % force a minimum number of points (for filter at least)
    ierr = 1;
    return
else    
    hdr.times.b = t(1);
    hdr.trcLen = numel(t);
    hdr.times.e = t(end);
end
% now shift so that arrival is at t=0
hdr = shiftSacHdrTimes( hdr, -tarr ); % update times

if( isPlot ), plims = comparePlots( t, enzseis, plims );
end

% check there is a signal in all three components
if( any( max(enzseis) - min(enzseis) <= 0 ) ),
  %error('At least one of the components has no signal\n')
  ierr=1;
  return
end


% Remove DC component
if( isVb ), fprintf('\t\tRemove DC\n'); end
enzseis = removeSeisDC( enzseis );

if( isPlot ), plims = comparePlots( t, enzseis, plims );
end

% Taper 
if( isVb ), fprintf('\t\tTaper with %.1f percent\n',100*opt.TAPERW); end
enzseis = taperSeis( enzseis, opt.TAPERW, opt.taperTypeFlag );

if( isPlot ), plims = comparePlots( t, enzseis, plims );
end

% Bandpass 
% Note that the signal processing tool box is required here
if( isVb ), fprintf('\t\tBandpass from %.2f to %.2f Hz\n',[opt.FHP,opt.FLP]); end
enzseis = bandpassSeis( enzseis, hdr.times.delta, opt.FHP, opt.FLP, opt.FORDER);

if( isPlot ), plims = comparePlots( t, enzseis, plims );
end

% Remove DC component and taper again to be safe
if( isVb ), fprintf('\t\tRemove DC\n'); end
enzseis = removeSeisDC( enzseis );

if( isVb ), fprintf('\t\tTaper with %.1f percent\n',100*opt.TAPERW); end
enzseis = taperSeis( enzseis, opt.TAPERW, opt.taperTypeFlag );

% Resample
if( isVb ), fprintf('\t\tResampling from %.3f to %.3f s\n',...
			 [hdr.times.delta,opt.DTOUT]); 
end
[enzseis, delta, t]= resampleSeis(enzseis, t, opt.DTOUT);

nt = size(enzseis,1); % num samples
hdr.times.delta = delta; % new sampling rate
hdr.trcLen = nt; % new number of samples
hdr.times.e = t(end);  % new end time

if( isPlot ), plims = comparePlots( t, enzseis, plims );
end

% Rotate
if( isVb ), fprintf('\t\tRotating to TRZ\n'); end
[trzseis, seiskey] = rotateSeisENZtoTRZ( enzseis , hdr.evsta.baz );    

if( isPlot ), 
  plot3seis(t, enzseis(:,1), t, enzseis(:,2), t, enzseis(:,3), ...
	    struct( 'clabs', ['T';'R';'Z'] , 'ltype', '-r', 'lims', plims ) ); 

end


% Allocate
zseis = trzseis(:,3);
rseis = trzseis(:,2);
tseis = trzseis(:,1);

ierr=0;

return

%---------------------------------------------------------
function plims = comparePlots( t, enzseis, plims )

% overlay current seismogram on existing plot, pause, then clear and start again with
% working seismograms
plot3seis(t, enzseis(:,1), t, enzseis(:,2), t, enzseis(:,3), ...
	  struct( 'clabs', ['E';'N';'Z'] , 'ltype', '-r', 'lims', plims ) ); 

[~] = input('Press a key to continue ');  

clf;  
plims = plot3seis(t, enzseis(:,1), t, enzseis(:,2), t, enzseis(:,3), ...
		  struct( 'clabs', ['E';'N';'Z'] ) ); 
hold on; % start again

return
%---------------------------------------------------------
%  
%  This program is free software; you can redistribute it and/or
%  modify it under the terms of the GNU General Public License as
%  published by the Free Software Foundation; either version 3, or
%  (at your option) any later version.
%  
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%  General Public License for more details.
%  
%  You should have received a copy of the GNU General Public License
%  along with this program; see the file COPYING.  If not, write to
%  the Free Software Foundation, Inc., 51 Franklin Street, Fifth
%  Floor, Boston, MA 02110-1301, USA.
%  
%---------------------------------------------------------
%-- processENZseis.m ends here
