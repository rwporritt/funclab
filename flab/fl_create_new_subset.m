function fl_create_new_subset(h)
%% FL_CREATE_NEW_SUBSET 
%   Funclab function to launch a new window to take user parameters and
%   subset a project from the main project. Pass the guidata from the main
%   funclab window to this subroutine. Should be relatively quick as we
%   only need to operate on the metadata, not the actual data. 

% Color definition sets the color for the main funclab UI around the
% tables. While this may seem trivial, the purpose is to allow the user
% easy identification of which set they are working with.

%   Author:  Robert W. Porritt
%   Created: May 12th, 2015


%% Top level project info
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');

%% Prepare metadata
%load([ProjectDirectory ProjectFile],'RecordMetadataDoubles','RecordMetadataStrings');
load([ProjectDirectory ProjectFile],'SetManagementCell');
CurrentSubsetIndex = 1;
RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex, 2};
RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex, 3};

% Stations
AllStations = RecordMetadataStrings(:,2);
[AllStations, IAStations, ICStations] = unique(AllStations);
stationLatitudes = RecordMetadataDoubles(IAStations,10);
stationLongitudes = RecordMetadataDoubles(IAStations,11);
stationElevations = RecordMetadataDoubles(IAStations,12);

% Events
AllEvents = RecordMetadataStrings(:,3);
[AllEvents, IAEvents, ICEvents] = unique(AllEvents);
eventLatitudes = RecordMetadataDoubles(IAEvents,13);
eventLongitudes = RecordMetadataDoubles(IAEvents,14);
eventDepths = RecordMetadataDoubles(IAEvents,15);
eventMagnitudes = RecordMetadataDoubles(IAEvents,16);
eventOrigins = datetime(1:length(AllEvents),0,0,0,0,0); % Using datetime here so we can do normal math on dates within matlab
eventJdays = zeros(length(AllEvents),1);
for ide = 1:length(AllEvents)
    tmp = sscanf(AllEvents{ide},'%d/%d/%d:%d:%d');
    eventJdays(ide) = tmp(2);
    [mm, dd] = jul2cal(tmp(1), tmp(2));
    eventOrigins(ide) = datetime(tmp(1), mm, dd, tmp(3), tmp(4), tmp(5));
end

% Set default mins/maxs for the station info
MinStationLongitude = min(stationLongitudes);
MaxStationLongitude = max(stationLongitudes);
MinStationLatitude = min(stationLatitudes);
MaxStationLatitude = max(stationLatitudes);
MinStationElevation = min(stationElevations);
MaxStationElevation = max(stationElevations);


% Need to restructure station metadata into cell arrays
StationLatitudeCell = cell(length(AllStations),1);
StationLongitudeCell = cell(length(AllStations),1);
StationElevationCell = cell(length(AllStations),1);
StationOnOffTable = cell(length(AllStations),1);
for istation = 1:length(AllStations)
    StationLatitudeCell{istation} = stationLatitudes(istation);
    StationLongitudeCell{istation} = stationLongitudes(istation);
    StationElevationCell{istation} = stationElevations(istation) * 1000;
    StationOnOffTable{istation} = true;
end


% Set defaults for events
MinEventLongitude = min(eventLongitudes);
MaxEventLongitude = max(eventLongitudes);
MinEventLatitude = min(eventLatitudes);
MaxEventLatitude = max(eventLatitudes);
MinEventDepth = min(eventDepths);
MaxEventDepth = max(eventDepths);
MinEventMagnitude = min(eventMagnitudes);
MaxEventMagnitude = max(eventMagnitudes);
MinOriginTime = min(eventOrigins);
MaxOriginTime = max(eventOrigins);

% Restructure events into cell arrays for table and storage
EventLatitudeCell = cell(length(eventLatitudes),1);
EventLongitudeCell = cell(length(eventLongitudes),1);
EventDepthCell = cell(length(eventDepths),1);
EventMagnitudeCell = cell(length(eventMagnitudes),1);
EventOriginCell = cell(length(eventOrigins),1);
EventOnOffTable = cell(length(eventOrigins),1);
EventOriginTextCell = cell(length(eventOrigins),1);
for ievent=1:length(eventOrigins)
    EventLatitudeCell{ievent} = eventLatitudes(ievent);
    EventLongitudeCell{ievent} = eventLongitudes(ievent);
    EventDepthCell{ievent} = eventDepths(ievent);
    EventMagnitudeCell{ievent} = eventMagnitudes(ievent);
    EventOriginCell{ievent} = eventOrigins(ievent);
    EventOriginTextCell{ievent} = sprintf('%04d/%03d/%02d:%02d:%02d',eventOrigins(ievent).Year, ...
        eventJdays(ievent), eventOrigins(ievent).Hour, eventOrigins(ievent).Minute, ...
        eventOrigins(ievent).Second);
    EventOnOffTable{ievent} = true;
end

% Datetime info for origin
DateTimeStart = datetime(1900,1,1); % If you have seismic data before 1900, then you may need to edit this...
DateTimeEnd = datetime('today');
DateTimeStartJday = dayofyear(DateTimeStart.Year, DateTimeStart.Month, DateTimeStart.Day);
DateTimeEndJday = dayofyear(DateTimeEnd.Year, DateTimeEnd.Month, DateTimeEnd.Day);

%%
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% GUI initiation
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Setup dimensions of the GUI
%--------------------------------------------------------------------------
MainPos = [0 0 120 60];
ParamTitlePos = [3 MainPos(4)-3 50 1.75];
StationPanelPos = [2 45 116 11];
EventPanelPos = [2 28 116 17];

% This set of position vectors is a little bit out of hand.
ParamTextPos1 = [2 7 31 1.75];
ParamTextPos5 = [2 11.5 20 1.75];
ParamTextPos6 = [2 15 25 1.75];
ParamTextPos7 = [2 18 20 1.75];
ParamTextPos8 = [44 18 18 1.75];
ParamTextPos9 = [82 18 15 1.75];
ParamTextPos10 = [2 22.5 15 1.75];
ParamTextPos11 = [60 23 21 1.75];

ParamSubTextPos7 = [25 20 8 1.75];
ParamSubTextPos72 = [34 20 8 1.75];
ParamSubTextPos8 = [63 20 8 1.75];
ParamSubTextPos82 = [72 20 8 1.75];
ParamSubTextPos9 = [98 20 8 1.75];
ParamSubTextPos92 = [107 20 8 1.75];
ParamSubTextPos10 = [25 25 8 1.75];
ParamSubTextPos102 = [42 25 8 1.75];
ParamSubTextPos11 = [83 25 8 1.75];
ParamSubTextPos112 = [100 25 8 1.75];

ParamSubTextPos6 = [60 15 55 1.5];
ParamSubTextPos1 = [31 8.5 6 1.75];
ParamSubTextPos2 = [51 8.5 8 1.75];
ParamSubTextPos3 = [71 8.5 6 1.75];
ParamSubTextPos4 = [91 8.5 15 1.75];

ParamOptionPos1 = [30 7 15 1.75];
ParamOptionPos2 = [50 7 15 1.75];
ParamOptionPos3 = [70 7 15 1.75];
ParamOptionPos4 = [90 7 25 1.75];
ParamOptionPos5 = [30 12 85 1.75];
ParamOptionPos6 = [30 15 25 1.75];
ParamOptionPos7 = [25 18 8 1.75];
ParamOptionPos72 = [34 18 8 1.75];
ParamOptionPos8 = [63 18 8 1.75];
ParamOptionPos82 = [72 18 8 1.75];
ParamOptionPos9 = [98 18 8 1.75];
ParamOptionPos92 = [107 18 8 1.75];
ParamOptionPos10 = [25 23 15 1.75];
ParamOptionPos102 = [42 23 15 1.75];
ParamOptionPos11 = [83 23 15 1.75];
ParamOptionPos112 = [100 23 15 1.75];



TextFontSize = 0.6; % ORIGINAL
PanelTextFontSize = 0.5;
EditFontSize = 0.5;
AccentColor = [.6 0 0];

%%
%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
MainSubsetGUI = dialog('Name','Create a new subset','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

% Help menu
MHelp = uimenu(MainSubsetGUI,'Label','Help');
uimenu(MHelp,'Label','Help','Tag','subset_help_m','Enable','on','Callback',{@new_subset_help_callback});

% Putting all the default data into the gui main figure
setappdata(MainSubsetGUI,'SetColor',[0 0 0]);
setappdata(MainSubsetGUI,'SetName','Uncreative Default Set Name');

setappdata(MainSubsetGUI,'ActiveOrAllFlag','All');
setappdata(MainSubsetGUI,'MinRayParameter',0.04);
setappdata(MainSubsetGUI,'MaxRayParameter',0.08);
setappdata(MainSubsetGUI,'MinDistance',30);
setappdata(MainSubsetGUI,'MaxDistance',100);
setappdata(MainSubsetGUI,'MinBaz',0);
setappdata(MainSubsetGUI,'MaxBaz',360);
setappdata(MainSubsetGUI,'MinRFRadFit',0);
setappdata(MainSubsetGUI,'MinRFTransFit',0);
setappdata(MainSubsetGUI,'MaxRFRadFit',100);
setappdata(MainSubsetGUI,'MaxRFTransFit',100);

setappdata(MainSubsetGUI,'MinStationLongitude',MinStationLongitude);
setappdata(MainSubsetGUI,'MaxStationLongitude',MaxStationLongitude);
setappdata(MainSubsetGUI,'MinStationLatitude',MinStationLatitude);
setappdata(MainSubsetGUI,'MaxStationLatitude',MaxStationLatitude);
setappdata(MainSubsetGUI,'MinStationElevation',MinStationElevation);
setappdata(MainSubsetGUI,'MaxStationElevation',MaxStationElevation);
setappdata(MainSubsetGUI,'StationOnOffTable',StationOnOffTable);
setappdata(MainSubsetGUI,'StationNames',AllStations);
setappdata(MainSubsetGUI,'StationLatitudes',StationLatitudeCell);
setappdata(MainSubsetGUI,'StationLongitudes',StationLongitudeCell);
setappdata(MainSubsetGUI,'StationElevations',StationElevationCell);

setappdata(MainSubsetGUI,'MinEventLongitude',MinEventLongitude);
setappdata(MainSubsetGUI,'MaxEventLongitude',MaxEventLongitude);
setappdata(MainSubsetGUI,'MinEventLatitude',MinEventLatitude);
setappdata(MainSubsetGUI,'MaxEventLatitude',MaxEventLatitude);
setappdata(MainSubsetGUI,'MinEventDepth',MinEventDepth);
setappdata(MainSubsetGUI,'MaxEventDepth',MaxEventDepth);
setappdata(MainSubsetGUI,'MinEventMagnitude',MinEventMagnitude);
setappdata(MainSubsetGUI,'MaxEventMagnitude',MaxEventMagnitude);
setappdata(MainSubsetGUI,'MinOriginTime',MinOriginTime);
setappdata(MainSubsetGUI,'MaxOriginTime',MaxOriginTime);

setappdata(MainSubsetGUI,'EventLatitudes',EventLatitudeCell);
setappdata(MainSubsetGUI,'EventLongitudes',EventLongitudeCell);
setappdata(MainSubsetGUI,'EventDepths',EventDepthCell);
setappdata(MainSubsetGUI,'EventMagnitudes',EventMagnitudeCell);
setappdata(MainSubsetGUI,'OriginDateTimes',EventOriginCell);
setappdata(MainSubsetGUI,'OriginTimeStrings',EventOriginTextCell);
setappdata(MainSubsetGUI,'EventOnOffTable',EventOnOffTable);

setappdata(MainSubsetGUI,'MinEventYear',DateTimeStart.Year);
setappdata(MainSubsetGUI,'MinEventJday',DateTimeStartJday);
setappdata(MainSubsetGUI,'MinEventMonth',DateTimeStart.Month);
setappdata(MainSubsetGUI,'MinEventDay',DateTimeStart.Day);
setappdata(MainSubsetGUI,'MinEventHour',DateTimeStart.Hour);
setappdata(MainSubsetGUI,'MinEventMinute',DateTimeStart.Minute);
setappdata(MainSubsetGUI,'MinEventSecond',DateTimeStart.Second);

setappdata(MainSubsetGUI,'MaxEventYear',DateTimeEnd.Year);
setappdata(MainSubsetGUI,'MaxEventJday',DateTimeEndJday);
setappdata(MainSubsetGUI,'MaxEventMonth',DateTimeEnd.Month);
setappdata(MainSubsetGUI,'MaxEventDay',DateTimeEnd.Day);
setappdata(MainSubsetGUI,'MaxEventHour',DateTimeEnd.Hour);
setappdata(MainSubsetGUI,'MaxEventMinute',DateTimeEnd.Minute);
setappdata(MainSubsetGUI,'MaxEventSecond',DateTimeEnd.Second);



% Title
uicontrol ('Parent',MainSubsetGUI,'Style','text','Units','characters','Tag','title_t','String','Create a new subset',...
    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',.8,'HorizontalAlignment','left','BackgroundColor','white');

% Station panel
StationPanelHandles = uipanel('Parent',MainSubsetGUI,'Title','Stations Panel','Units','Characters',...
    'Position',StationPanelPos,'BackgroundColor','White','FontSize',12);

% Table. User editable and is adjusted in real time by the edit boxes and
% the polygon selection tool
StationTable = uitable(StationPanelHandles,'Data',[StationOnOffTable AllStations StationLatitudeCell StationLongitudeCell StationElevationCell],...
    'ColumnName',{'Active','Name', 'Latitude', 'Longitude','Elevation (m)'},...
    'ColumnEditable',[true, false, false, false, false],...
    'Units','Normalized','Position',[0.36 0.01 0.63 0.98],'Tag','subset_station_table');

% Set station geographic limits with edit boxes
ParamOptionPos = [3 52 12 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','south_lat_e','String','South Lat',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_station_geography_limit,StationTable,1});
ParamOptionPos = [16 52 12 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','north_lat_e','String','North Lat',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_station_geography_limit,StationTable,2});
ParamOptionPos = [3 50 12 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','west_lon_e','String','West Lon',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_station_geography_limit,StationTable,3});
ParamOptionPos = [16 50 12 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','east_lon_e','String','East Lon',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_station_geography_limit,StationTable,4});
ParamOptionPos = [3 48 12 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','min_elev_e','String','Min Elev',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_station_geography_limit,StationTable,5});
ParamOptionPos = [16 48 12 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','max_elev_e','String','Max Elev',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_station_geography_limit,StationTable,6});

% Button to turn all stations on
ParamOptionPos = [22 45.5 20 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Pushbutton','Units','Characters','Tag','all_on_pb','String','Turn all stations on',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',0.5,'HorizontalAlignment','center','BackgroundColor','white',...
    'ForegroundColor',AccentColor, ...
    'Callback',{@turn_all_stations_on,StationTable});

% Button to launch new figure for select by polygon
ParamOptionPos = [30 52 12 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Pushbutton','Units','Characters','Tag','polygon_pb','String','Polygon',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',0.5,'HorizontalAlignment','center','BackgroundColor','white',...
    'ForegroundColor',AccentColor, ...
    'Callback',{@select_stations_by_polygon,StationTable});


% Event panel
EventPanelHandles = uipanel('Parent',MainSubsetGUI,'Title','Events Panel','Units','Characters',...
    'Position',EventPanelPos,'BackgroundColor','White','FontSize',12);

% Start with an event table
EventTable = uitable(EventPanelHandles,'Data',[EventOnOffTable EventOriginTextCell EventLatitudeCell EventLongitudeCell EventDepthCell EventMagnitudeCell],...
    'ColumnName',{'Active','Origin Time', 'Latitude', 'Longitude','Depth (km)','Magnitude'},...
    'ColumnEditable',[true, false, false, false, false, false],...
    'Units','Normalized','Position',[0.36 0.01 0.63 0.9],'Tag','subset_event_table');

% Set origin start and end time windows with popup menus
% Min: year jday hour min sec
% max: year jday hour min sec
ParamTextPos = [3 41.5 12 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','start_time_t','String','Start Time: ',...
    'Position',ParamTextPos,'FontUnits','normalized','FontSize',PanelTextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
ParamOptionPos = [3 39.5 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','start_year_e','String','Year',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_time,1,1});
ParamOptionPos = [11 39.5 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','start_jday_e','String','Jday',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_time,1,2});
ParamOptionPos = [19 39.5 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','start_hour_e','String','Hour',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_time,1,3});
ParamOptionPos = [27 39.5 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','start_min_e','String','Minute',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_time,1,4});
ParamOptionPos = [35 39.5 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','start_sec_e','String','Second',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_time,1,5});

% End time
ParamTextPos = [3 37 12 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','end_time_t','String','End Time: ',...
    'Position',ParamTextPos,'FontUnits','normalized','FontSize',PanelTextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
ParamOptionPos = [3 35.5 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','end_year_e','String','Year',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_time,2,1});
ParamOptionPos = [11 35.5 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','end_jday_e','String','Jday',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_time,2,2});
ParamOptionPos = [19 35.5 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','end_hour_e','String','Hour',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_time,2,3});
ParamOptionPos = [27 35.5 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','end_min_e','String','Minute',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_time,2,4});
ParamOptionPos = [35 35.5 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','end_sec_e','String','Second',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_time,2,5});

% Button to turn all events on
ParamOptionPos = [22 33 18 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Pushbutton','Units','Characters','Tag','all_on_pb','String','Turn all events on',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',0.5,'HorizontalAlignment','center','BackgroundColor','white',...
    'ForegroundColor',AccentColor, ...
    'Callback',{@turn_all_events_on,EventTable});

% Button to apply time window
ParamOptionPos = [3 33 18 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Pushbutton','Units','Characters','Tag','all_on_pb','String','Apply time window',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',0.5,'HorizontalAlignment','center','BackgroundColor','white',...
    'ForegroundColor',AccentColor, ...
    'Callback',{@apply_time_window,EventTable});

% Set depth limits
ParamTextPos = [3 30.5 12 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','depth_limits_t','String','Depth (km): ',...
    'Position',ParamTextPos,'FontUnits','normalized','FontSize',PanelTextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
ParamOptionPos = [3 29 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','min_depth_e','String','Min',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_depth,EventTable,1});
ParamOptionPos = [11 29 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','max_depth_e','String','Max',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_depth,EventTable,2});

% Set magnitude limits
ParamTextPos = [19 30.5 12 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','mag_limits_t','String','Magnitude: ',...
    'Position',ParamTextPos,'FontUnits','normalized','FontSize',PanelTextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
ParamOptionPos = [19 29 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','min_mag_e','String','Min',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_mag,EventTable,1});
ParamOptionPos = [27 29 7 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','max_mag_e','String','Max',...
    'Position',ParamOptionPos,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_event_mag,EventTable,2});



% Radial Fit
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','radfit_t','String','Radial RF Fit: ',...
    'Position',ParamTextPos10,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','radfit_min_e','String','0',...
    'Position',ParamOptionPos10,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');setappdata(gcf,''MinRFRadFit'',str2double(v));');
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','radfit_max_e','String','100',...
    'Position',ParamOptionPos102,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');setappdata(gcf,''MaxRFRadFit'',str2double(v));');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','radfit_min_t','String','Min: ',...
    'Position',ParamSubTextPos10,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','radift_max_t','String','Max: ',...
    'Position',ParamSubTextPos102,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');

% % Transverse Fit
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','transfit_t','String','Transverse RF Fit: ',...
    'Position',ParamTextPos11,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','transfit_min_e','String','0',...
    'Position',ParamOptionPos11,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');setappdata(gcf,''MinRFTransFit'',str2double(v));');
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','transfit_max_e','String','100',...
    'Position',ParamOptionPos112,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');setappdata(gcf,''MaxRFTransFit'',str2double(v));');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','transfit_min_t','String','Min: ',...
    'Position',ParamSubTextPos11,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','transfit_max_t','String','Max: ',...
    'Position',ParamSubTextPos112,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');


% Other record metadata: isedited? status? time step? npts? begin time? end
% time? gaussian? 
% While these parameters seem like they should be free and are recorded in
% the RecordMetadata, random bits of codes will assume a constant value for
% all records in the project meaning these values can't really be easily
% altered.

% Set ray param, distance, back azimuth limits in edit boxes
% Ray parameter
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','rayp_t','String','Ray Parameter: ',...
    'Position',ParamTextPos7,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','rayp_min_e','String','0.04',...
    'Position',ParamOptionPos7,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');setappdata(gcf,''MinRayParameter'',str2double(v));');
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','rayp_max_e','String','0.08',...
    'Position',ParamOptionPos72,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');setappdata(gcf,''MaxRayParameter'',str2double(v));');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','rayp_min_t','String','Min: ',...
    'Position',ParamSubTextPos7,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','rayp_max_t','String','Max: ',...
    'Position',ParamSubTextPos72,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');

% Distance - going to assume degrees here; consider a popup menu to switch
% to km
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','distance_t','String','Distance (deg): ',...
    'Position',ParamTextPos8,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','dist_min_e','String','30',...
    'Position',ParamOptionPos8,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');setappdata(gcf,''MinDistance'',str2double(v));');
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','dist_max_e','String','100',...
    'Position',ParamOptionPos82,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');setappdata(gcf,''MaxDistance'',str2double(v));');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','dist_min_t','String','Min: ',...
    'Position',ParamSubTextPos8,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','dist_max_t','String','Max: ',...
    'Position',ParamSubTextPos82,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');

% back azimuth
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','baz_t','String','Backazimuth: ',...
    'Position',ParamTextPos9,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','baz_min_e','String','0',...
    'Position',ParamOptionPos9,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');setappdata(gcf,''MinBaz'',str2double(v));');
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','baz_max_e','String','360',...
    'Position',ParamOptionPos92,'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');setappdata(gcf,''MaxBaz'',str2double(v));');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','baz_min_t','String','Min: ',...
    'Position',ParamSubTextPos9,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','baz_max_t','String','Max: ',...
    'Position',ParamSubTextPos92,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');


% Popup menu for currently active or all traces
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','active_or_all_records_t','String','Active records or all: ',...
    'Position',ParamTextPos6,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Popupmenu','Units','Characters','Tag','active_or_all_records_pu','String',{'Active','All'},...
    'Position',ParamOptionPos6,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''Value'');vec=get(gcbo,''String'');setappdata(gcf,''ActiveOrAllFlag'',vec{v});');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','active_or_all_records_sub_t','String','Active is only those traces which have passed trace editing.',...
    'Position',ParamSubTextPos6,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');

% Edit box to set name
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','choose_name_t','String','Set name: ',...
    'Position',ParamTextPos5,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','choose_name_e','String','',...
    'Position',ParamOptionPos5,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');setappdata(gcf,''SetName'',v);');

% Edit boxes for color (and a popup menu for some default colors)
% Text boxes
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','choose_color_t','String','Color ID (0-255): ',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','choose_color_r_t','String','Red: ',...
    'Position',ParamSubTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','choose_color_g_t','String','Green: ',...
    'Position',ParamSubTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','choose_color_b_t','String','Blue: ',...
    'Position',ParamSubTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','choose_color_preset_t','String','Preset Color: ',...
    'Position',ParamSubTextPos4,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
% Edit boxes
RedColorEditBox = uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','choose_color_r_e','String','0',...
    'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');vec=getappdata(gcf,''SetColor'');vec(1) = str2double(v);setappdata(gcf,''SetColor'',vec);');
GreenColorEditBox = uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','choose_color_g_e','String','0',...
    'Position',ParamOptionPos2,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');vec=getappdata(gcf,''SetColor'');vec(2) = str2double(v);setappdata(gcf,''SetColor'',vec);');
BlueColorEditBox = uicontrol('Parent',MainSubsetGUI,'Style','Edit','Units','Characters','Tag','choose_color_b_e','String','0',...
    'Position',ParamOptionPos3,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''String'');vec=getappdata(gcf,''SetColor'');vec(3) = str2double(v);setappdata(gcf,''SetColor'',vec);');
% Popupmenu
ColorOptions = {'Blue','Green','Red','Cyan','Magenta','Yellow','Black','White','IRIS Purple',...
    'USC Gold','USC Red','Berkeley Gold','Berkeley Blue','ASU Gold','ASU Maroon','Northwestern',...
    'MTU Gold','MTU Black','MTU Silver','Maize', 'UM Blue'};
ColorDefinitions = {255 * [0 0 1], 255 * [0 1 0], 255 * [1 0 0], 255 * [0 1 1], 255 * [1 0 1], 255 * [1 1 0], 255 * [0 0 0], 255 * [1 1 1],...
    255 * [0.2863 0.1451 0.5333], 255 * [1.000 0.7961 0], 255 * [0.6 0 0], 255 * [0.9922 0.7098 0.0824], 255 * [0 0.1961 0.3843]...
    255 * [1.0000 0.7020 0.0627], 255 * [0.6 0 0.2], 255 * [0.3216 0 0.3882], 255 * [1.0000 0.8078 0], 255 * [0.0980 0.0980 0.0980], 255 * [0.6235 0.6275 0.6392],...
    255 * [0.9451 0.7686 0], 255 * [0.0157 0.1176 0.2588]};
uicontrol('Parent',MainSubsetGUI,'Style','Popupmenu','Units','Characters','Tag','choose_color_pu','String',ColorOptions,...
    'Position',ParamOptionPos4,'FontUnits','Normalized','FontSize',EditFontSize,'BackgroundColor','white',...
    'Callback',{@use_preset_color_callback, ColorDefinitions, RedColorEditBox, GreenColorEditBox, BlueColorEditBox});


% Pushbutton for cancel
% Close/go buttons
CloseButtonPosition = [70 2 20 3];
uicontrol('Parent',MainSubsetGUI,'Style','Pushbutton','Units','Characters','Tag','cancel_new_subset_pb','String','Cancel',...
    'Position',CloseButtonPosition,'FontUnits','normalized','FontSize',0.4,'ForegroundColor',AccentColor,'FontWeight','bold',...
    'Callback',{@cancel_new_subset_Callback});

% Pushbutton for create
CreateButtonPosition = [95 2 20 3];
uicontrol('Parent',MainSubsetGUI,'Style','Pushbutton','Units','Characters','Tag','create_new_subset_pb','String','Create',...
    'Position',CreateButtonPosition,'FontUnits','normalized','FontSize',0.4,'ForegroundColor',AccentColor,'FontWeight','bold',...
    'Callback',{@create_new_subset_Callback,StationTable, EventTable, h});

%--------------------------------------------------------------------------
% Callback subfunctions
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% apply_time_window,EventTable
% Uses the time window data stored in the appdata to turn events in the
% table off if they occur outside of the user chosen time window
%--------------------------------------------------------------------------
function apply_time_window(cbo, eventdata, table)
appdata = getappdata(gcbf);

% Get the date time for the start and end limits
% Start by converting the year, jday to year,month, day
[MinMonth, MinDay] = jul2cal(appdata.MinEventYear, appdata.MinEventJday);
[MaxMonth, MaxDay] = jul2cal(appdata.MaxEventYear, appdata.MaxEventJday);
TimeStart = datetime(appdata.MinEventYear, MinMonth, MinDay, appdata.MinEventHour, appdata.MinEventMinute, appdata.MinEventSecond);
TimeEnd = datetime(appdata.MaxEventYear, MaxMonth, MaxDay, appdata.MaxEventHour, appdata.MaxEventMinute, appdata.MaxEventSecond);

% Go through the events and turn them on or off with the OnOfTable
for ievent = 1:length(appdata.EventOnOffTable)
    if appdata.OriginDateTimes{ievent} < TimeStart || appdata.OriginDateTimes{ievent} > TimeEnd
        appdata.EventOnOffTable{ievent} = false;
    end
end

% Apply to the table
for idx=1:length(appdata.EventOnOffTable)
    table.Data{idx,1} = appdata.EventOnOffTable{idx};
end

% Return to the gui app data
setappdata(gcbf,'EventOnOffTable',appdata.EventOnOffTable);



%--------------------------------------------------------------------------
% set_event_mag(table, flag)
% turns off events in the table with mag less than (flag = 1) or greater
% than (flag = 2) the edit box string value.
%--------------------------------------------------------------------------
function set_event_mag(cbo, eventdata, table, flag)
appdata = getappdata(gcbf);
val = str2double(get(gcbo,'String'));
switch flag
    case 1
        setappdata(gcbf,'MinEventMagnitude',val);
        for ide = 1:length(appdata.EventOnOffTable)
            if appdata.EventMagnitudes{ide} < val
                appdata.EventOnOffTable{ide} = false;
            end
        end
    case 2
        setappdata(gcbf,'MaxEventMagnitude',val);
        for ide = 1:length(appdata.EventOnOffTable)
            if appdata.EventMagnitudes{ide} > val
                appdata.EventOnOffTable{ide} = false;
            end
        end
end

% Apply to the table
for idx=1:length(appdata.EventOnOffTable)
    table.Data{idx,1} = appdata.EventOnOffTable{idx};
end

% Return to the gui app data
setappdata(gcbf,'EventOnOffTable',appdata.EventOnOffTable);


%--------------------------------------------------------------------------
% set_event_depth(table, flag)
% turns off events in the table with depth less than (flag = 1) or greater
% than (flag = 2) the edit box string value.
%--------------------------------------------------------------------------
function set_event_depth(cbo, eventdata, table, flag)
appdata = getappdata(gcbf);
val = str2double(get(gcbo,'String'));
switch flag
    case 1
        setappdata(gcbf,'MinEventDepth',val);
        for ide = 1:length(appdata.EventOnOffTable)
            if appdata.EventDepths{ide} < val
                appdata.EventOnOffTable{ide} = false;
            end
        end
    case 2
        setappdata(gcbf,'MaxEventDepth',val);
        for ide = 1:length(appdata.EventOnOffTable)
            if appdata.EventDepths{ide} > val
                appdata.EventOnOffTable{ide} = false;
            end
        end
end

% Apply to the table
for idx=1:length(appdata.EventOnOffTable)
    table.Data{idx,1} = appdata.EventOnOffTable{idx};
end

% Return to the gui app data
setappdata(gcbf,'EventOnOffTable',appdata.EventOnOffTable);


%--------------------------------------------------------------------------
% turn_all_events_on(table)
% Turns all the events in the table (table) to the on position
%--------------------------------------------------------------------------
function turn_all_events_on(cbo, eventdata, table)
appdata = getappdata(gcbf);
for ievent=1:length(appdata.EventOnOffTable)
    appdata.EventOnOffTable{ievent} = true;
end

% Apply to the table
for idx=1:length(appdata.EventOnOffTable)
    table.Data{idx,1} = appdata.EventOnOffTable{idx};
end

% Return to the gui app data
setappdata(gcbf,'EventOnOffTable',appdata.EventOnOffTable);


%--------------------------------------------------------------------------
% set_event_time(startOrEndFlag, TimeTypeFlag)
% sets the min or max time of events in the appdata based on last two flags
% startOrEndFlag = 1 for start time, 2 for end time
% TimeTypeFlag = 1 for year, 2 for jday, 3 for hour, 4 for minute, 5 for
% seconds
%--------------------------------------------------------------------------
function set_event_time(cbo, eventdata, startOrEndFlag, TimeTypeFlag)
val = str2double(get(gcbo,'String'));
switch startOrEndFlag
    case 1
        % Start time
        switch TimeTypeFlag
            case 1
                % Year
                setappdata(gcbf,'MinEventYear',val);
            case 2
                % jday
                setappdata(gcbf,'MinEventJday',val);
            case 3
                % hour
                setappdata(gcbf,'MinEventHour',val);
            case 4
                % minute
                setappdata(gcbf,'MinEventMinute',val);
            case 5
                % second
                setappdata(gcbf,'MinEventSecond',val);
        end
        
    case 2
        % End time
        switch TimeTypeFlag
            case 1
                % Year
                setappdata(gcbf,'MaxEventYear',val);
            case 2
                % jday
                setappdata(gcbf,'MaxEventJday',val);
            case 3
                % hour
                setappdata(gcbf,'MaxEventHour',val);
            case 4
                % minute
                setappdata(gcbf,'MaxEventMinute',val);
            case 5
                % second
                setappdata(gcbf,'MaxEventSecond',val);
        end        
end



%--------------------------------------------------------------------------
% select_stations_by_polygon(table)
% Makes a new figure window for the user to select a subset of stations by
% clicking the vertices of a polygon. Loads the funclab preferences to put
% the stations in the user projection. Calls the "inpolygon" function to
% find which stations are located within the polygon. 
% Mapping work done in a subroutine descending from fl_view_station_map
% Updates both the main figure appdata and the table passed as arg3
%--------------------------------------------------------------------------
function select_stations_by_polygon(cbo, eventdata, table)
appdata = getappdata(gcbf);
% Calls a derivative of fl_view_station_map to get the vertices of a
% user-defined polygon.
[lons, lats] = fl_get_station_map_polygon(appdata);

% get the latitude and longitudes of stations from the appdata
nstations = length(appdata.StationLatitudes);
stationlatitudes = zeros(nstations,1);
stationlongitudes = zeros(nstations,1);
for istation=1:nstations
    stationlatitudes(istation) = appdata.StationLatitudes{istation};
    stationlongitudes(istation) = appdata.StationLongitudes{istation};
end

% call to inpolygon
in = inpolygon(stationlongitudes, stationlatitudes, lons, lats);

% set the on/off table
% Just turning off those stations outside of the polygon; NOT turning on
% stations within the polygon
for istation = 1:nstations
    if in(istation) == 0
        appdata.StationOnOffTable{istation} = false;
    end
end

% Apply to the table
for idx=1:nstations
    table.Data{idx,1} = appdata.StationOnOffTable{idx};
end

% Return to the gui app data
setappdata(gcbf,'StationOnOffTable',appdata.StationOnOffTable);



%--------------------------------------------------------------------------
% turn_all_stations_on(table)
% sets all the stations in the table and appdata to 'on'. Designed to undo
% the effects of other functions which trim the data
%--------------------------------------------------------------------------
function turn_all_stations_on(cbo, eventdata, table)
appdata = getappdata(gcbf);
for istation=1:length(appdata.StationOnOffTable)
    appdata.StationOnOffTable{istation} = true;
end

% Apply to the table
for idx=1:length(appdata.StationOnOffTable)
    table.Data{idx,1} = appdata.StationOnOffTable{idx};
end

% Return to the gui app data
setappdata(gcbf,'StationOnOffTable',appdata.StationOnOffTable);


%--------------------------------------------------------------------------
% set_station_geography_limit,StationTable,Flag
% Turns stations in the station table on or off based on geographic limits
% StationTable is the table handles which this adjusts
% Flag is used in a switch case to switch between min/max lat/lon/elev
%--------------------------------------------------------------------------
function set_station_geography_limit(cbo, eventdata, table, flag)
appdata = getappdata(gcbf);
val = str2double(get(gcbo,'String'));
switch flag
    case 1 % South latitude
        appdata.MinStationLatitude = val;
        setappdata(gcbf,'MinStationLatitude',val);
    case 2 % North latitude
        appdata.MaxStationLatitude = val;
        setappdata(gcbf,'MaxStationLatitude',val);
    case 3 % West longitude
        appdata.MinStationLongitude = val;
        setappdata(gcbf,'MinStationLongitude',val);
    case 4 % East longitude
        appdata.MaxStationLongitude = val;
        setappdata(gcbf,'MaxStationLongitude',val);
    case 5 % Min elevation
        appdata.MinStationElevation = val;
        setappdata(gcbf,'MinStationElevation',val);
    case 6 % Max elevation
        appdata.MaxStationElevation = val;
        setappdata(gcbf,'MaxStationElevation',val);
end

% go through the data, turning off stations outside the limits
switch flag
    case 1
        for istation = 1:length(appdata.StationOnOffTable)
            if appdata.StationLatitudes{istation} < val
                appdata.StationOnOffTable{istation} = false;
            end
        end
    case 2
        for istation = 1:length(appdata.StationOnOffTable)
            if appdata.StationLatitudes{istation} > val
                appdata.StationOnOffTable{istation} = false;
            end
        end
    case 3
        for istation = 1:length(appdata.StationOnOffTable)
            if appdata.StationLongitudes{istation} < val
                appdata.StationOnOffTable{istation} = false;
            end
        end
    case 4
        for istation = 1:length(appdata.StationOnOffTable)
            if appdata.StationLongitudes{istation} > val
                appdata.StationOnOffTable{istation} = false;
            end
        end
    case 5
        for istation = 1:length(appdata.StationOnOffTable)
            if appdata.StationElevations{istation} < val
                appdata.StationOnOffTable{istation} = false;
            end
        end
    case 6
        for istation = 1:length(appdata.StationOnOffTable)
            if appdata.StationElevations{istation} > val
                appdata.StationOnOffTable{istation} = false;
            end
        end
end

% Apply to the table
for idx=1:length(appdata.StationOnOffTable)
    table.Data{idx,1} = appdata.StationOnOffTable{idx};
end

% Return to the gui app data
setappdata(gcbf,'StationOnOffTable',appdata.StationOnOffTable);

%--------------------------------------------------------------------------
% new_subset_help_callback
% Displays a help message for creating a new subset
%--------------------------------------------------------------------------
function new_subset_help_callback(cbo, eventdata)
MainPos = [0 0 75 25];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','New subset help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['This feature is designed to create a new subset project out of a larger database. ' ...
    'Use the edit boxes and popup menus to set the limits of your desired subset. Once you select ' ...
    'the create button, these parameters will be used to select only those records within your chosen ' ...
    'parameter space. The rest of the functions in FuncLab can be used on this subset so you can '...
    'see the relative influence of various parameters. The set name and color are used for identification '...
    'of this set while working with multiple sets.'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Text','String',str,'Units','Characters',...
    'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','Ok','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close(gcf)');




%--------------------------------------------------------------------------
% use_preset_color_callback
% 
% Custom colors:
% Blue: [0 0 1]
% Green: [0 1 0]
% Red: [1 0 0]
% Cyan: [0 1 1]
% Magenta: [1 0 1]
% Yellow: [1 1 0]
% Black: [0 0 0]
% White: [1 1 1]
% IRIS Purple: [0.2863 0.1451 0.5333]
% USC Gold: [1.0000 0.7961 0]
% USC Red: [0.6 0 0]
% Berkeley Gold: [0.9922 0.7098 0.0824]
% Berkeley Blue: [0 0.1961 0.3843]
% ASU Gold: [1.0000 0.7020 0.0627]
% ASU Maroon: [0.6 0 0.2]
% Northwestern: [0.3216 0 0.3882]
% MTU Gold: [1.0000 0.8078 0]
% MTU Black: [0.0980 0.0980 0.0980]
% MTU Silver: [0.6235 0.6275 0.6392]
% Maize: [0.9451 0.7686 0]
% UM Blue:  [0.0157 0.1176 0.2588]
%--------------------------------------------------------------------------
function use_preset_color_callback(cbo, eventdata, ColorDefinitions, RedEdit, GreenEdit, BlueEdit)
v = get(gcbo,'Value');
vec = ColorDefinitions{v};
setappdata(gcbf,'SetColor',[round(vec(1)) round(vec(2)) round(vec(3))]);
set(RedEdit,'String',num2str(round(vec(1))));
set(GreenEdit,'String',num2str(round(vec(2))));
set(BlueEdit,'String',num2str(round(vec(3))));




%--------------------------------------------------------------------------
% create_new_subset_Callback
% Find the indices for the subset
%--------------------------------------------------------------------------
function create_new_subset_Callback(cbo, eventdata, stationtable, eventtable, h)

% This may take a while, so throwing up a wait gui
wbhdls = waitbar(0,'Please wait while creating the new set');


% Get main project information
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
load([ProjectDirectory ProjectFile],'SetManagementCell')

% Get the base data
CurrentSubsetIndex = 1;
RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex, 2};
RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex, 3};

% Get the size and get memory ready 
nrecords = size(RecordMetadataDoubles,1);
SubsetIndices = zeros(nrecords, 1);

% Data previously set by user
appdata = getappdata(gcbf);

% These are the tables after user input. The tools in the main gui simply
% update these tables
StationOnOffTable = stationtable.Data(:,1);
EventOnOffTable = eventtable.Data(:,1);

% Loop through the project records testing if this record should be in the
% subset. If it is, put the record into the subset.
% Coding style note: Here I'm just doing a continue to go onto the next
% record if the record is found to not fit in the subset. If no continue is
% hit, then the record should be kept and is added to the subset metadata.
% This should run fairly quickly because as soon as it hits a continue, its
% done with that record, although a vectorized version is usually faster.
for irecord = 1:nrecords
    % Check the station

    % update the wait bar  
    if mod(irecord, 1000) == 0
      waitbar(irecord / nrecords);
    end

    % Alternative way of matching the record to the keep information
    %strmatch(RecordMetadataStrings{irecord,2}, appdata.StationNames)
    stationIDX = find(strncmp(RecordMetadataStrings{irecord,2}, appdata.StationNames,length(RecordMetadataStrings{irecord,2})) == 1,1);
    if isempty(stationIDX)
        continue
    end
    if StationOnOffTable{stationIDX} == false
        continue
    end
    
    % Check the event
    eventIDX = find(strncmp(RecordMetadataStrings{irecord,3}, appdata.OriginTimeStrings,length(RecordMetadataStrings{irecord,3})) == 1,1);
    if isempty(eventIDX)
        continue
    end
    if EventOnOffTable{eventIDX} == false
        continue
    end
    
    % Check radial RF fit
    radialRFFit = RecordMetadataDoubles(irecord, 8);
    if radialRFFit < appdata.MinRFRadFit || radialRFFit > appdata.MaxRFRadFit
        continue
    end
    
    % Check transverse RF fit
    transverseRFFit = RecordMetadataDoubles(irecord, 9);
    if transverseRFFit < appdata.MinRFTransFit || transverseRFFit > appdata.MaxRFTransFit
        continue
    end
    
    % Check ray parameter
    rayparam = RecordMetadataDoubles(irecord, 18);
    if rayparam < appdata.MinRayParameter || rayparam > appdata.MaxRayParameter
        continue
    end
    
    % Check distance
    RecordDistance = RecordMetadataDoubles(irecord, 17);
    if RecordDistance < appdata.MinDistance || RecordDistance > appdata.MaxDistance
        continue
    end
    
    % Check baz
    RecordBaz = RecordMetadataDoubles(irecord,19);
    if RecordBaz < appdata.MinBaz || RecordBaz > appdata.MaxBaz
        continue
    end
    
    % Active or all
    if strcmp(appdata.ActiveOrAllFlag,'Active')
        RecordActiveFlag = RecordMetadataDoubles(irecord,2);
        if RecordActiveFlag == 0
            continue
        end
    end
    
    % All checks passed, so we include it
    SubsetIndices(irecord) = irecord;

    
end

disp('Removing empty entries')

% Loop back through removing empties
%for irecord = nrecords:-1:1
%    if SubsetIndices(irecord) == 0;
%        SubsetIndices(irecord) = [];
%    end
%end
SubsetIndices(SubsetIndices==0)=[];


disp('Updating metadata')

SubsetMetadataDoubles = RecordMetadataDoubles(SubsetIndices,:);
SubsetMetadataStrings = RecordMetadataStrings(SubsetIndices,:);
SubsetTablemenu = {'Station Tables','RecordMetadata',2,3,'Stations: ','Records (Listed by Event)','Events: ','fl_record_fields','string';
    'Event Tables','RecordMetadata',3,2,'Events: ','Records (Listed by Station)','Stations: ','fl_record_fields','string'};

% Push the set info into the project
nsets = size(SetManagementCell,1);
SetManagementCell{nsets+1,1} = SubsetIndices;
SetManagementCell{nsets+1,2} = SubsetMetadataStrings;
SetManagementCell{nsets+1,3} = SubsetMetadataDoubles;
SetManagementCell{nsets+1,4} = SubsetTablemenu;
SetManagementCell{nsets+1,5} = appdata.SetName;
SetManagementCell{nsets+1,6} = appdata.SetColor;
assignin('base','SetManagementCell',SetManagementCell)
assignin('base','CurrentSubsetIndex',nsets+1);
disp('Saving new set')
save([ProjectDirectory ProjectFile],'SetManagementCell','-append');
disp('Updating datainfo')
fl_datainfo(ProjectDirectory,ProjectFile,SubsetMetadataStrings,SubsetMetadataDoubles,nsets+1)

delete(wbhdls);
close(gcbf);

set(h.delete_subset_m,'Enable','on');
set(h.choose_subset_m,'Enable','on');
% settag = sprintf('%s_m',appdata.SetName);
% uimenu(SubsetMenu,'Label',appdata.SetName,'Tag',settag,'Enable','on','Separator','off');
% Update the Log File
%--------------------------------------------------------------------------
CreatedSetName = appdata.SetName;
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Created set %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6), CreatedSetName);
fl_edit_logfile(LogFile,NewLog)
set(h.message_t,'String',['Message: created set ',CreatedSetName])

tables_Callback(h);

%--------------------------------------------------------------------------
% cancel_new_subset_Callback
% Close without doing anything
%--------------------------------------------------------------------------
function cancel_new_subset_Callback(cbo, eventdata)
close(gcbf);




%--------------------------------------------------------------------------
% tables_Callback
%
% This callback function controls the display of records in the middle
% listbox for the selected table in the "Tables" listbox.
% Specially modified for use in fl_choose_subset.m
%--------------------------------------------------------------------------
function tables_Callback(h)
set(h.records_ls,'String','');
set(h.records_ls,'Value',1)
% Which table (stations/events/etc... is active
Value = get(h.tablemenu_pu,'Value');
% Get metadata about the subset
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
Tablemenu = SetManagementCell{CurrentSubsetIndex, 4};
assignin('base','Tablemenu',Tablemenu);
% Set colors
AccentColor = SetManagementCell{CurrentSubsetIndex, 6} / 255;
set(h.explorer_fm,'BackgroundColor',AccentColor);
set(h.project_t,'BackgroundColor',AccentColor);
set(h.tablesinfo_t,'BackgroundColor',AccentColor);
set(h.records_t,'BackgroundColor',AccentColor);
set(h.recordsinfo_t,'BackgroundColor',AccentColor);
set(h.info_t,'BackgroundColor',AccentColor);
set(h.message_t,'ForegroundColor',AccentColor);
% Available tables based on pre-processing
AvailableTables = cell(size(Tablemenu,1),1);
for idx=1:size(Tablemenu,1)
    AvailableTables{idx} = Tablemenu{idx};
end
% We're changing the subset, so returning the active table to "Stations"
set(h.tablemenu_pu,'Value',1);
set(h.tablemenu_pu,'String',AvailableTables);
% Get metadata for the subset
MetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
MetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
Tablemenu = evalin('base','Tablemenu');
% Repopulate the h.tables_ls to the new subset values
Tables = sort(unique(MetadataStrings(:,2)));
set(h.tables_ls,'String',Tables)
set(h.tables_ls,'Value',1);
% Match the entries to the currently active table to the metadata for this
% set
in = strmatch(Tables{1},MetadataStrings(:,Tablemenu{Value,3}),'exact');
CurrentRecords = [MetadataStrings(in,:) num2cell(MetadataDoubles(in,:))];
switch Tablemenu{Value,9}
    case 'string'
        [CurrentRecords,ind] = sortrows(CurrentRecords,Tablemenu{Value,4});
    case 'double'
        [CurrentRecords,ind] = sortrows(CurrentRecords,Tablemenu{Value,4});
        for n = 1:size(CurrentRecords,1)
            CurrentRecords{n,Tablemenu{Value,4}} = num2str(CurrentRecords{n,Tablemenu{Value,4}},'%.0f');
        end
end
CurrentIndices = in(ind);
assignin('base','CurrentRecords',CurrentRecords);
assignin('base','CurrentIndices',CurrentIndices);
RecordList = CurrentRecords(:,Tablemenu{Value,4});
Active = size(find(cat(1,CurrentRecords{:,5})),1);
set(h.records_ls,'String',RecordList)
set(h.records_ls,'Value',1);
set(h.recordsinfo_t,'String',{[Tablemenu{Value,7} num2str(length(RecordList))],['Active: ' num2str(Active)]})
records_Callback(h)

%--------------------------------------------------------------------------
% records_Callback
%
% This callback function controls the display of information, shown on the
% right, for selected record in the "Records" listbox.
% Specially modified for fl_choose_subset.
%--------------------------------------------------------------------------
function records_Callback(h)
Value = get(h.tablemenu_pu,'Value');
Tablemenu = evalin('base','Tablemenu');
CurrentRecords = evalin('base','CurrentRecords');
RecordIndex = get(h.records_ls,'Value');
Record = CurrentRecords(RecordIndex,:)';
eval(Tablemenu{Value,8})
Information = cell(length(RecordFields),1);
for n = 1:length(Record)
    if isnumeric(Record{n})
        Value = num2str(Record{n});
    else
        Value = Record{n};
    end
    Information{n} = [RecordFields{n} Value];
end
set(h.info_ls,'Value',1)
set(h.info_ls,'String',Information)




