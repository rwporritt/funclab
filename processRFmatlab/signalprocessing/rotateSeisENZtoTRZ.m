function [SEIS, KEY] = rotateSeisENZtoTRZ( SEIS , BAZ )
%
% SEIS = rotateSeisENZtoTRZ( SEIS , BAZ )
%
% Rotate channels from East-North-Z(up) to Transverse-Radial-Z(up)
% coordinate system
%
% IN:
% SEIS = Seismogram array (NT x 3), 1 column for each component,
%        must have correct order [ E, N, Z ]  
% BAZ = Back azimuth of ray at station in degrees
%
% OUT:
% SEIS = rotated seismogram in new coord system [ T, R, Z ]
% KEY = labels for which component is in which column

% Modified from Levander's code by IWB, Oct 2010

%% IWB version
% % get components
E=SEIS(:,1);
N=SEIS(:,2);
Z=SEIS(:,3);

% Flip the angle by 180 degrees and get in range 0 - 360 degrees
angle = mod( BAZ+180, 360);

% get the radial and transverse components
R = N.*cosd( angle ) + E.*sind(angle);
T = E.*cosd( angle ) - N.*sind(angle);

SEIS = [ T, R, Z];
KEY = strvcat('T', 'R', 'Z' );
return;


%% RWP version
% Modfiied from IWB's code by RWP
% After testing, going with IWB version. Possibly the early mis-matches
% were due to mis-rotations from input azimuth to E,N.
% E=SEIS(:,1);
% N=SEIS(:,2);
% Z=SEIS(:,3);
% angle = mod( BAZ, 360 );
% der = angle * pi/180.0;  % radians over which to rotate
% rotationMatrix = [cos(-der) -sin(-der) 0; sin(-der) cos(-der) 0; 0 0 1];
% dataToRotate=[E, N, Z];
% rotated = rotationMatrix * dataToRotate';
% SEIS = rotated';
% KEY = strvcat('T','R','Z');
%% Following splitlab example
% Z           L
% E  =  M  *  Q
% N           T
%
%
% After Plesinger, Hellweg, Seidl; 1986 
% "Interactive high-resolution polarisation analysis of broad band seismograms"; 
% Journal of Geophysics (59) 129-139
% E=SEIS(:,1);
% N=SEIS(:,2);
% Z=SEIS(:,3);
% 
% inc  = 0/180*pi;
% bazi = BAZ/180*pi; 
% 
% M = [cos(inc)     -sin(inc)*sin(bazi)    -sin(inc)*cos(bazi);
%      sin(inc)      cos(inc)*sin(bazi)     cos(inc)*cos(bazi);
%         0              -cos(bazi)             sin(bazi)];
% 
% dataToRotate=[Z, E, N];
% rotated = M^-1 * dataToRotate';
% SEIS = [rotated(3,:)', rotated(2,:)', rotated(1,:)'];
% KEY = strvcat('T','R','Z');
% % 

return
