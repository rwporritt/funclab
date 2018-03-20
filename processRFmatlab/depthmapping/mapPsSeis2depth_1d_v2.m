function seisout = mapPsSeis2depth_1d_v2( time, seis, p, dz, z, vp, vs, DepthOutVector )
% seisouts = mapPsSeis2time_1d( time, seis, p, dz, z, vp, vs, timeOutVec )

% Edit from mapPsSeis2depth_1d
% Proceeds similarily, but returns receiver functions in time domain (timeOutVec)
% after correcting for variable ray parameters
% Rob Porritt, Oct. 18, 2016

EPS = 1e-6;

nseis = numel( p );

seisout = cell(1,nseis);

for iseis = 1:nseis
    seisout{iseis} = zeros(1,length(DepthOutVector));
end

% get the depths
zout = (0.0:dz:2800);

% deal with discontinuities in the vel model
idisc = find( z(1:end-1) == z(2:end) );
z(idisc) = z(idisc) - EPS;

% interpolate the vel model in middle of each interval
vp = interp1( z, vp, zout(1:end-1)+0.5*dz, 'linear','extrap');
vs = interp1( z, vs, zout(1:end-1)+0.5*dz, 'linear','extrap');  

for iseis = 1:nseis

  % get vertical slowness for each depth point at this rayp
  qa = sqrt(1./vp.^2 - p(iseis).^2);
  qb = sqrt(1./vs.^2 - p(iseis).^2);

  % get time difference
  dt = dz*(qb - qa); % time difference at each depth interval

  % get time at bottom of each layer
  tout = cumsum(dt) ;
  
  % get time at top of each layer
  tout = tout - dt;

  % get rid of times and depths beyond the end of the seismogram
  idx = find( tout < max( time{iseis} ) );
  tout = tout( idx );
  depths = zout( idx );
  
  tout( imag(tout)~=0 ) = Inf;   % correct for evernecent waves

  seistmp = interp1( time{iseis}, seis{iseis}, tout , 'pchip' );
  seisout{iseis} = interp1( depths, seistmp, DepthOutVector , 'pchip' );

end
  
return

% ---------------------------------------------------------------------- 
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
% ---------------------------------------------------------------------- 

