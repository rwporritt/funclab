function [lons, lats] = fl_get_station_map_polygon(appdata)
%% FL_GET_STATION_MAP_POLYGON
%  fl_get_station_map_polygon(appdata)
%    Function to display a map view and query the user to click the
%    vertices of a polygon.
%
%  appdata is a structure which requires a few elements:
%    MinStationLongitude
%    MaxStationLongitude
%    MinStationLatitude
%    MaxStationLatitude
%    StationsOnOffTable
%    StationLongitudes
%    StationLatitudes
%
%  Output [lons, lats] are the longitude and latitude coordinates of the
%    vertices of the polygon. 
%
%  Requires FuncLabPreferences to be set in the base workspace for
%    projection information
%
%  Author: Rob Porritt
%  Created May 13th, 2015

% Prepares the call to fl_view_station_map
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
load([ProjectDirectory ProjectFile],'RecordMetadataStrings','RecordMetadataDoubles')
CurrentRecords = evalin('base','CurrentRecords');
Record = CurrentRecords(1,:);

fl_view_station_map(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles,Record)

% Prompts the user to click the vertices and then hit enter
% Has the user click around the map to create a polygon
screensize = get(0,'screensize');
figpos = [screensize(3) / 2 - 200 screensize(4) / 2 - 50 400 100];
tmpfig = figure('Name','Click 3 or more points for polygon','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off','Color','white');
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.5 0.6 0.4],'String','Please click 3 or more points on the map view. Hit enter when done.','FontSize',12,'BackgroundColor','white');
waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.4],'String','Click','FontSize',12,'Callback','gcbf.UserData=1; close');
waitfor(waitbutton,'Userdata');

% Plot on the map
if license('Test','MAP_Toolbox')
    [lats, lons] = inputm();
    npts = size(lats,1);
    lats(npts+1) = lats(1);
    lons(npts+1) = lons(1);
    linem(lats,lons,'LineStyle','--','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[1 0.8 0]);
else
    [x, y] = ginput();
    npts = size(x,1);
    x(npts+1) = x(1);
    y(npts+1) = y(1);
    [lons, lats] = m_xy2ll(x, y);
    m_line(lons, lats, 'LineStyle','--','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[1 0.8 0]) 
    m_patch(lons, lats, [0.6 0 0])
    alpha(0.3)
end






