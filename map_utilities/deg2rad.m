function rad = deg2rad (deg)
%DEG2RAD       convert from deg to rad
%
%    DEG2RAD converts from units of degrees to radians.
%
%    USAGE:
%           rad = deg2rad (deg);
%
%    INPUT:
%           deg = degrees
%
%    OUTPUT:
%           rad = radians
%
%    EXAMPLE:
%           rad = deg2rad (6.4172);            ANS: rad =  367.68
%
%    Kevin C. Eagar
%    January 26, 2007
%    Last Updated: 01/26/2007
%    Error caught by Alex Blanchette after noticing KCE had used the same code
%    as rad2deg instead of swapping it
%rad = deg * (360 / (2*pi));
rad = deg * ( pi / 180);
