%% la_lon_rad_to_cart.m
%   [x, y, z] = lat_lon_rad_to_cart(latitude, longitude, radius)
%   given vectors of latitude, longitude, and radius, converts them to a
%   geocentric cartesian coordinate system
%   Rob Porritt, Nov 2014, when I should be getting ready for a group
%   meeting and Lithosphere Dynamics seminar talk
function [x, y, z] = lat_lon_rad_to_cart(latitude, longitude, radius)

% Check sizes
nlat = length(latitude);
nlon = length(longitude);
nrad = length(radius);
if nlat ~= nlon || nlat ~= nrad || nlon ~= nrad
    fprintf('Error, check vector lengths of latitude (%d) longitude (%d) and radius (%d)\n',nlat, nlon, nrad);
    return
end

%% allocate the output
x = zeros(1,nlon);
y = zeros(1,nlat);
z = zeros(1,nrad);

%% Do the transformation
for i=1:nlon
    x(i) = radius(i) * cosd(latitude(i)) * cosd(longitude(i));
    y(i) = radius(i) * cosd(latitude(i)) * sind(longitude(i));
    z(i) = radius(i) * sind(latitude(i));
end

