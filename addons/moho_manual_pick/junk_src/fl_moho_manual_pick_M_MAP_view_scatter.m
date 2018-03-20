function fl_moho_manual_pick_M_MAP_view_scatter(longitudes,latitudes,zvalues,minlat,maxlat,minlon,maxlon,cptfile,cptflip,MapProjection,TitleString)
%% fl_moho_manual_pick_M_MAP_view_scatter
%    Function to make a map of scattered data without the mapping toolbox,
%    but with m_map


%   Author: Rob Porritt
%   Date Created: 05/08/2015
%   Last Updated: 05/08/2015

% Launch a new figure window
figure('Units','characters','NumberTitle','off','Name','Moho Map','Units','characters',...
    'Position',[0 0 165 55],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'},'color','white');

% Sets color map
if cptflip == true
    cptcmap(cptfile,'flip',true)
else
    cptcmap(cptfile);
end

% Projection options
ProjectionListNames = {'Stereographic','Orthographic','Azimuthal Equal-area','Azimuthal Equidistant','Gnomonic',...
    'Satellite','Albers Equal-Area Conic','Lambert Conformal Conic','Mercator','Miller Cylindrical','Equidistant Cylindrical',...
    'Transverse Mercator','Sinusoidal','Gall-Peters','Hammer-Aitoff','Mollweide','Robinson','UTM'};
ProjectionListIDs = ProjectionListNames;
% Finds active projection
MapProjectionIDX = strmatch(MapProjection,ProjectionListNames,'exact');
MapProjectionID = ProjectionListIDs{MapProjectionIDX};
% Opens map by setting projection
if strcmp(MapProjectionID,'Stereographic') || strcmp(MapProjectionID,'Orthographic') || strcmp(MapProjectionID,'Azimuthal Equal-area') || ...
    strcmp(MapProjectionID,'Azimuthal Equidistant') || strcmp(MapProjectionID,'Gnomonic') || strcmp(MapProjectionID,'Satellite')    
    [~, ~, xdeg] = distaz(minlat, minlon, maxlat, maxlon);
    m_proj(MapProjectionID,'latitude',(minlat + maxlat)/2, 'longitude',(minlon + maxlon) / 2,'radius',xdeg/2);
else
    m_proj(MapProjectionID,'latitude',[minlat maxlat],'longitude',[minlon maxlon]);
end

% de-nan-if-fy
% Cull out nan values
for idx=size(zvalues,1):-1:1
    if isnan(zvalues(idx))
        latitudes(idx) = [];
        longitudes(idx) = [];
        zvalues(idx) = [];
    end
end

hold on
load FL_plates
load FL_stateBoundaries
m_coast('patch',[.9 .9 .9],'edgecolor','black');
m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
[x,y] = m_ll2xy(longitudes, latitudes);
scatter(x,y,100,zvalues,'filled')
m_grid('box','on')
title(TitleString)
colorbar


