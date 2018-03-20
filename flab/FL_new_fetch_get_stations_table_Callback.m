function FL_new_fetch_get_stations_table_Callback( cbo, eventdata )
%% Creates a table with logical check boxes for the user to turn a station on or off.
%  By default, all stations are on

figHdls = figure('Name','Please select stations to keep','Tag','new_fetch_get_stations_table_figure');
figPos = get(figHdls,'Position');
% Gets the limits
hdl = findobj('Tag','new_fetch_lat_max_e');
latmax = sscanf(char(get(hdl,'String')),'%f');

hdl = findobj('Tag','new_fetch_lat_min_e');
latmin = sscanf(char(get(hdl,'String')),'%f');

hdl = findobj('Tag','new_fetch_lon_max_e');
lonmax = sscanf(char(get(hdl,'String')),'%f');

hdl = findobj('Tag','new_fetch_lon_min_e');
lonmin = sscanf(char(get(hdl,'String')),'%f');

stationBoxRange = [latmin latmax lonmin lonmax];

% Checks for sensible limits; throws a message box on error
if ~isempty(stationBoxRange) && isfloat(stationBoxRange)
    if length(stationBoxRange) == 4
            %stas = irisFetch.Stations('STATION','*','*','*','LHZ,BHZ,HHZ','boxcoordinates',stationBoxRange,'BASEURL','http://service.scedc.caltech.edu/fdsnws/station/1/');  % note: this limits to only broadband stations  

           stas = irisFetch.Stations('STATION','*','*','*','LHZ,BHZ,HHZ','boxcoordinates',stationBoxRange,'BASEURL','http://service.iris.edu/fdsnws/station/1/');  % note: this limits to only broadband stations  
%         for idx=1:10
%             stas(idx).StationCode = sprintf('test_%d',idx);
%             stas(idx).NetworkCode = 'nn';
%             stas(idx).Latitude = idx;
%             stas(idx).Longitude = -idx;
%         end
         hdl = findobj('Tag','new_fetch_get_stations_pb');
        
        stationCell = cell(1,length(stas));
        networkCell = cell(1,length(stas));
        latitudes = cell(1,length(stas));
        longitudes = cell(1,length(stas));
        %truthTable = cell(1,length(stas));
        for i=1:length(stas)
            stationCell{i} = sprintf('%s',stas(i).StationCode);
            networkCell{i} = sprintf('%s',stas(i).NetworkCode);
            latitudes{i} = stas(i).Latitude;
            longitudes{i} = stas(i).Longitude;
            %truthTable{i} = true;
        end
        
        % Keep only unique station names
        uniqueStations = unique(stationCell);
        CleanStations = cell(1,length(uniqueStations));
        CleanNetworks = cell(1,length(uniqueStations));
        CleanLatitudes = cell(1,length(uniqueStations));
        CleanLongitudes = cell(1,length(uniqueStations));
        truthTable = cell(1,length(uniqueStations));
        for istation = 1:length(uniqueStations)
            for jstation = 1:length(stas)
                if strcmp(uniqueStations{istation},stationCell{jstation})
                    CleanStations{istation} = stationCell{jstation};
                    CleanNetworks{istation} = networkCell{jstation};
                    CleanLatitudes{istation} = latitudes{jstation};
                    CleanLongitudes{istation} = longitudes{jstation};
                    truthTable{istation} = true;
                    break
                end
            end
        end
        
        
        tableHdls = uitable('Parent',figHdls,'Data',[CleanNetworks', CleanStations', CleanLatitudes', CleanLongitudes', truthTable'],...
            'ColumnName',{'Networks','Stations','Latitude','Longitude','Active'},...
            'ColumnEditable',[false, false, false, false, true],...
            'Units','Normalized','Position',[0.05 0.05 0.8 0.9],...
            'UserData',stas,'Tag','new_fetch_get_stations_table');
        
        pbHdls = uicontrol('Parent',figHdls,'Style','PushButton','String','OK','Units','Normalized',...
            'Position',[0.85 0.05 0.15 0.1],'FontSize',12,...
            'Callback',@return_station_selection_to_funclab);
        
        selectAllPbHandles = uicontrol('Parent',figHdls,'Style','Pushbutton','String','Select All','Units','Normalized',...
            'Position',[0.85 0.15 0.15 0.1],'FontSize',12,...
            'Callback',@turn_on_all_stations);
        
        selectNonePbHandles = uicontrol('Parent',figHdls,'Style','Pushbutton','String','Select None','Units','Normalized',...
            'Position',[0.85 0.25 0.15 0.1],'FontSize',12,...
            'Callback',@turn_off_all_stations);
        
        invertSelectionPbHandles = uicontrol('Parent',figHdls,'Style','Pushbutton','String','Invert Selection','Units','Normalized',...
            'Position',[0.85 0.35 0.15 0.1],'FontSize',12,...
            'Callback',@invert_station_choices);
        
        sortStationsByText = uicontrol('Parent',figHdls,'Style','Text','String','Sort by:','Units','Normalized',...
            'Position',[0.85 0.49 0.1 0.1]);
        
        sortStationsByPopupMenu = uicontrol('Parent',figHdls,'Style','PopupMenu','Units','Normalized',...
            'Position',[0.85 0.45 0.15 0.1],'FontSize',12,'BackgroundColor',[1 1 1], ...
            'String',{'Network (alphabetical)','Network (reverse alphabetical','Station (alphabetical)','Station (reverse alphabetical',...
            'Latitude (N->S)','Latitude (S->N)','Longitude (E->W)','Longitude (W->E)'},'Value',1,'Tag','sortStationPopup',...
            'Callback',@sort_station_choices_callback);
        
        PolygonSelectionPushbutton = uicontrol('Parent',figHdls,'Style','Pushbutton','String','Select by Polygon','Units','Normalized',...
            'Position',[0.85 0.6 0.15 0.1],'FontSize',12,...
            'Callback',{@select_by_polygon_Callback,stationBoxRange});
         

    else
        msgbox('Need 4 limits for station range');
    end
else
    msgbox('Please limit the station geographic window first!');
end


% function return_station_selection_to_funclab(cbo, eventdata)
% % Function to combine the truth table info from the table and the stations
% % and pack a stations variable back with its active or inactive state
% % passed along
% % Get handles:
% tableHdls = findobj('Tag','new_fetch_get_stations_table');
% dataTable = get(tableHdls,'Data');
% buttonHandles = findobj('Tag','new_fetch_get_stations_pb');
% panelHandles = findobj('Tag','new_fetch_station_panel');
% figHdls = findobj('Tag','new_fetch_get_stations_table_figure');
% 
% % Get info about stations to keep:
% nstations = 0;
% dims = size(dataTable);
% for idx = 1:dims(1)
%     if dataTable{idx,5} == true
%         nstations = nstations + 1;
%     end
% end
% 
% % Prepare output
% userdata.stations = cell(1,nstations);
% userdata.networks = cell(1,nstations);
% userdata.latitudes = cell(1,nstations);
% userdata.longitudes = cell(1,nstations);
% jdx=1;
% for idx = 1:dims(1)
%     if (dataTable{idx,5} == true)
%         userdata.stations{jdx} = dataTable{idx,2};
%         userdata.networks{jdx} = dataTable{idx,1};
%         userdata.latitudes{jdx} = dataTable{idx,3};
%         userdata.longitudes{jdx} = dataTable{idx,4};
%         jdx = jdx + 1;
%     end
% end
% set(panelHandles,'UserData',userdata);
% set(buttonHandles,'UserData',userdata);
% close(figHdls);

function return_station_selection_to_funclab(cbo, eventdata)
% Function to combine the truth table info from the table and the stations
% and pack a stations variable back with its active or inactive state
% passed along
% Get handles:
tableHdls = findobj('Tag','new_fetch_get_stations_table');
dataTable = get(tableHdls,'Data');
buttonHandles = findobj('Tag','new_fetch_get_stations_pb');
panelHandles = findobj('Tag','new_fetch_station_panel');
figHdls = findobj('Tag','new_fetch_get_stations_table_figure');

% Get info about stations to keep:
nstations = 0;
dims = size(dataTable);
for idx = 1:dims(1)
    if dataTable{idx,5} == true
        nstations = nstations + 1;
    end
end

% Prepare output
userdata.stations = cell(1,nstations);
userdata.networks = cell(1,nstations);
userdata.latitudes = cell(1,nstations);
userdata.longitudes = cell(1,nstations);
jdx=1;
for idx = 1:dims(1)
    if (dataTable{idx,5} == true)
        userdata.stations{jdx} = dataTable{idx,2};
        userdata.networks{jdx} = dataTable{idx,1};
        userdata.latitudes{jdx} = dataTable{idx,3};
        userdata.longitudes{jdx} = dataTable{idx,4};
        jdx = jdx + 1;
    end
end
set(panelHandles,'UserData',userdata);
set(buttonHandles,'UserData',userdata);
close(figHdls);
% - update needed to integrate m_map!!
% Pop up a map of the stations
load FL_coasts
load FL_plates
load FL_stateBoundaries
figMap = figure();
plot(ncst(:,1),ncst(:,2),'k');
hold on
plot(PBlong, PBlat, 'r')
plot(stateBoundaries.longitude, stateBoundaries.latitude,'k--')
tmpLon = zeros(1,jdx-1);
tmpLat = zeros(1,jdx-1);
for idx = 1:jdx-1
    tmpLon(idx) = userdata.longitudes{idx};
    tmpLat(idx)  = userdata.latitudes{idx};
end
plot(tmpLon, tmpLat,'bv');
if length(tmpLon)>1
    axis([min(tmpLon) max(tmpLon) min(tmpLat) max(tmpLat)]);
else
    axis([tmpLon-0.5 tmpLon+0.5 tmpLat-0.5 tmpLat+0.5]);
end
title('Selected Stations')
xlabel('Longitude')
ylabel('Latitude')
legend('Coast lines','Plate Boundaries','State boundaries', 'Stations')




function turn_on_all_stations(cbo, eventdata)
tableHdls = findobj('Tag','new_fetch_get_stations_table');
dataTable = get(tableHdls,'Data');
dims = size(dataTable);
for idx=1:dims(1)
    dataTable{idx,5} = true;
end
set(tableHdls,'Data',dataTable);
drawnow




function turn_off_all_stations(cbo, eventdata)
tableHdls = findobj('Tag','new_fetch_get_stations_table');
dataTable = get(tableHdls,'Data');
dims = size(dataTable);
for idx=1:dims(1)
    dataTable{idx,5} = false;
end
set(tableHdls,'Data',dataTable);
drawnow



function invert_station_choices(cbo, eventdata)
tableHdls = findobj('Tag','new_fetch_get_stations_table');
dataTable = get(tableHdls,'Data');
dims = size(dataTable);
for idx=1:dims(1)
    if dataTable{idx,5} == true
        dataTable{idx,5} = false;
    else
        dataTable{idx,5} = true;
    end
end
set(tableHdls,'Data',dataTable);
drawnow

% Presents a new figure for the user to select an N point polygon. Then
% calls inpolygon to turn all those stations within the polygon on and
% those outside the polygon off
function select_by_polygon_Callback(cbo, eventdata,limits)

% Gui elements..
MainPos = [0 0 80 25];
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];


tableHdls = findobj('Tag','new_fetch_get_stations_table');
dataTable = get(tableHdls,'Data');
buttonHandles = findobj('Tag','new_fetch_get_stations_pb');
panelHandles = findobj('Tag','new_fetch_station_panel');
figHdls = findobj('Tag','new_fetch_get_stations_table_figure');
% Get info about stations to keep:
nstations = 0;
dims = size(dataTable);
for idx = 1:dims(1)
    if dataTable{idx,5} == true
        nstations = nstations + 1;
    end
end
% And stations to reject
nstationsReject = 0;
for idx = 1:dims(1)
    if dataTable{idx,5} == false
        nstationsReject = nstationsReject + 1;
    end
end

% Prepare output
userdata.stations = cell(1,nstations);
userdata.networks = cell(1,nstations);
userdata.latitudes = cell(1,nstations);
userdata.longitudes = cell(1,nstations);
jdx=1;
for idx = 1:dims(1)
    if (dataTable{idx,5} == true)
        userdata.stations{jdx} = dataTable{idx,2};
        userdata.networks{jdx} = dataTable{idx,1};
        userdata.latitudes{jdx} = dataTable{idx,3};
        userdata.longitudes{jdx} = dataTable{idx,4};
        jdx = jdx + 1;
    end
end

% And for the turned off stations
stationsReject = cell(1,nstationsReject);
networksReject = cell(1,nstationsReject);
latitudesReject = cell(1,nstationsReject);
longitudesReject = cell(1,nstationsReject);
kdx=1;
for idx = 1:dims(1)
    if (dataTable{idx,5} == false)
        stationsReject{kdx} = dataTable{idx,2};
        networksReject{kdx} = dataTable{idx,1};
        latitudesReject{kdx} = dataTable{idx,3};
        longitudesReject{kdx} = dataTable{idx,4};
        kdx = kdx + 1;
    end
end


PolygonSelectionFigure = figure('Name','Select an N point polygon','Color','white','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'});
mapAxes = axes('Parent',PolygonSelectionFigure,'Units','Normalized','Position',[0.01 0.01 0.98 0.98]);
% - update needed to integrate m_map!!
% Pop up a map of the stations
load FL_coasts
load FL_plates
load FL_stateBoundaries
plot(mapAxes, ncst(:,1),ncst(:,2),'k');
hold on
plot(mapAxes, PBlong, PBlat, 'r')
plot(mapAxes, stateBoundaries.longitude, stateBoundaries.latitude,'k--')
tmpLon = zeros(1,jdx-1);
tmpLat = zeros(1,jdx-1);
for idx = 1:jdx-1
    tmpLon(idx) = userdata.longitudes{idx};
    tmpLat(idx)  = userdata.latitudes{idx};
end
plot(mapAxes, tmpLon, tmpLat,'bv');
tmpLonR = zeros(1,kdx-1);
tmpLatR = zeros(1,kdx-1);
for idx = 1:kdx-1
    tmpLonR(idx) = longitudesReject{idx};
    tmpLatR(idx) = latitudesReject{idx};
end
plot(mapAxes, tmpLonR, tmpLatR,'r+');
axis(mapAxes, [limits(3) limits(4) limits(1) limits(2)]);
title(mapAxes, 'Stations')
xlabel(mapAxes, 'Longitude')
ylabel(mapAxes, 'Latitude')
legend(mapAxes, 'Coast lines','Plate Boundaries','State boundaries', 'Stations on','Stations off')

% Has the user click around the map to create a polygon
screensize = get(0,'screensize');
figpos = [screensize(3) / 2 - 200 screensize(4) / 2 - 50 400 100];
tmpfig = figure('Name','Click 3 or more points for polygon','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.5 0.6 0.4],'String','Please click 3 or more points on the map view. Hit enter when done.','FontSize',12);
waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.4],'String','Click','FontSize',12,'Callback','gcbf.UserData=1; close');
waitfor(waitbutton,'Userdata');
[lons, lats] = ginput();

% Drop all stations to lat,lon
tmpLonA = zeros(1,dims(1));
tmpLatA = zeros(1,dims(1));
for idx=1:dims(1)
    tmpLonA(idx) = dataTable{idx,4};
    tmpLatA(idx) = dataTable{idx,3};
end

% Call to inpolygon
in = inpolygon(tmpLonA, tmpLatA, lons, lats);

% Update
% Note that this does not change previously turned off stations on!
for idx=1:dims(1)
    if in(idx) == 0
        dataTable{idx,5} = false;
    end    
end

cla
% Get info about stations to keep:
nstations = 0;
dims = size(dataTable);
for idx = 1:dims(1)
    if dataTable{idx,5} == true
        nstations = nstations + 1;
    end
end
% And stations to reject
nstationsReject = 0;
for idx = 1:dims(1)
    if dataTable{idx,5} == false
        nstationsReject = nstationsReject + 1;
    end
end

% Prepare output
userdata.stations = cell(1,nstations);
userdata.networks = cell(1,nstations);
userdata.latitudes = cell(1,nstations);
userdata.longitudes = cell(1,nstations);
jdx=1;
for idx = 1:dims(1)
    if (dataTable{idx,5} == true)
        userdata.stations{jdx} = dataTable{idx,2};
        userdata.networks{jdx} = dataTable{idx,1};
        userdata.latitudes{jdx} = dataTable{idx,3};
        userdata.longitudes{jdx} = dataTable{idx,4};
        jdx = jdx + 1;
    end
end

% And for the turned off stations
stationsReject = cell(1,nstationsReject);
networksReject = cell(1,nstationsReject);
latitudesReject = cell(1,nstationsReject);
longitudesReject = cell(1,nstationsReject);
kdx=1;
for idx = 1:dims(1)
    if (dataTable{idx,5} == false)
        stationsReject{kdx} = dataTable{idx,2};
        networksReject{kdx} = dataTable{idx,1};
        latitudesReject{kdx} = dataTable{idx,3};
        longitudesReject{kdx} = dataTable{idx,4};
        kdx = kdx + 1;
    end
end

% - update needed to integrate m_map!!
% Pop up a map of the stations
plot(mapAxes, ncst(:,1),ncst(:,2),'k');
hold on
plot(mapAxes, PBlong, PBlat, 'r')
plot(mapAxes, stateBoundaries.longitude, stateBoundaries.latitude,'k--')
tmpLon = zeros(1,jdx-1);
tmpLat = zeros(1,jdx-1);
for idx = 1:jdx-1
    tmpLon(idx) = userdata.longitudes{idx};
    tmpLat(idx)  = userdata.latitudes{idx};
end
plot(mapAxes, tmpLon, tmpLat,'bv');
tmpLonR = zeros(1,kdx-1);
tmpLatR = zeros(1,kdx-1);
for idx = 1:kdx-1
    tmpLonR(idx) = longitudesReject{idx};
    tmpLatR(idx) = latitudesReject{idx};
end
plot(mapAxes, tmpLonR, tmpLatR,'r+');
axis(mapAxes, [limits(3) limits(4) limits(1) limits(2)]);
scatter(mapAxes,lons,lats,100,'filled')
plot(mapAxes,lons,lats,'k--')
patch(lons,lats,[0.6 0 0]);
alpha(0.2);
title(mapAxes, 'Stations')
xlabel(mapAxes, 'Longitude')
ylabel(mapAxes, 'Latitude')
legend(mapAxes, 'Coast lines','Plate Boundaries','State boundaries', 'Stations on','Stations off','Polygon')




set(tableHdls,'Data',dataTable);
drawnow





function sort_station_choices_callback(cbo, eventdata)
tableHdls = findobj('Tag','new_fetch_get_stations_table');
popupHdls = gcbo;
logicInfo = get(tableHdls,'Data');
sortChoice = get(popupHdls,'Value');
dims = size(logicInfo);
nstations = dims(1);
tmpStr = cell(1,nstations);
tmpFloats = zeros(1,nstations);
% Determine the order of indices for output
switch sortChoice
    case 1 
        for istation = 1:nstations
            tmpStr{istation} = logicInfo{istation,1}; % network sort up
        end
        [tmpSort, iStationSort] = sort(tmpStr);
    case 2
        for istation = 1:nstations
            tmpStr{istation} = logicInfo{istation,1};
        end
        [tmpSort, iStationSort] = sort(tmpStr);
        iStationSort = fliplr(iStationSort);
    case 3
        for istation = 1:nstations
            tmpStr{istation} = logicInfo{istation,2};
        end
        [tmpSort, iStationSort] = sort(tmpStr);
    case 4
        for istation = 1:nstations
            tmpStr{istation} = logicInfo{istation,2};
        end
        [tmpSort, iStationSort] = sort(tmpStr);
        iStationSort = fliplr(iStationSort);
    case 5
        for istation = 1:nstations
            tmpFloats(istation) = logicInfo{istation,3};
        end
        [tmpSort, iStationSort] = sort(tmpFloats);
        iStationSort = fliplr(iStationSort);
    case 6
        for istation = 1:nstations
            tmpFloats(istation) = logicInfo{istation,3};
        end
        [tmpSort, iStationSort] = sort(tmpFloats);
    case 7
        for istation = 1:nstations
            tmpFloats(istation) = logicInfo{istation,4};
        end
        [tmpSort, iStationSort] = sort(tmpFloats);
        iStationSort = fliplr(iStationSort);
    case 8
        for istation = 1:nstations
            tmpFloats(istation) = logicInfo{istation,4};
        end
        [tmpSort, iStationSort] = sort(tmpFloats);
end
% create new cell arrays sorted in iEventSort order
% Structure of cells for output
stas=cell(nstations,5);
for istation=1:nstations
    jstation = iStationSort(istation);
    stas{istation,1} = logicInfo{jstation,1};
    stas{istation,2} = logicInfo{jstation,2};
    stas{istation,3} = logicInfo{jstation,3};
    stas{istation,4} = logicInfo{jstation,4};
    stas{istation,5} = logicInfo{jstation,5};
end
set(tableHdls,'Data',stas);
drawnow





