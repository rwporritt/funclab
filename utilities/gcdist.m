function gcarc = gcdist(lat1, lon1, lat2, lon2)


gcarc = 180/pi * acos(sind(lat1)*sind(lat2) + cosd(lat1)*cosd(lat2)*cosd(abs(lon1-lon2)));
