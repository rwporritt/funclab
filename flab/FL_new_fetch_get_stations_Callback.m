%--------------------------------------------------------------------------
% Calls irisFetch to create a list of available stations
% This SHOULD incorporate start and end times of the stations, but these
% features don't always seem to work right (assumed because station
% metadata is incorrect)
%
% Function depreciated for much easier to use uitable
%

function FL_new_fetch_get_stations_Callback(cbo, eventdata)
%hdl = findobj('Tag','new_fetch_get_map_coords_pb');
%stationBoxRange = get(hdl,'Userdata');

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
        stas = irisFetch.Stations('STATION','*','*','*','LHZ,BHZ,HHZ','boxcoordinates',stationBoxRange,'BASEURL','http://service.iris.edu/fdsnws/station/1/');  % note: this limits to only broadband stations  
        hdl = findobj('Tag','new_fetch_get_stations_pb');
        
        % Get the station info from the stas structure
        sncls = repmat('NN.SSSS    ',length(stas),1);
        stationCell = cell(1,length(stas));
        networkCell = cell(1,length(stas));
        latitudes = zeros(1,length(stas));
        longitudes = zeros(1,length(stas));
        for i=1:length(stas)
            stationCell{i} = sprintf('%s',stas(i).StationCode);
            networkCell{i} = sprintf('%s',stas(i).NetworkCode);
            latitudes(i) = stas(i).Latitude;
            longitudes(i) = stas(i).Longitude;
            sncls(i,:) = sprintf('%2s.%8s',stas(i).NetworkCode,deblank(stas(i).StationCode));
        end
        
        % pack the station data into a structure
        userdata.networks = networkCell;
        userdata.stations = stationCell;
        userdata.latitudes = latitudes;
        userdata.longitudes = longitudes;
        userdata.leftOrRight = zeros(1,length(stationCell));
        userdata.sncls = sncls;

        % create a list box too choose stations on or off
        h = figure('Name','Select stations to request.','Tag','station_list_box_figure');
        pos = get(h,'Position');
        set(h,'UserData',userdata);
        availableStationsList = uicontrol('Tag','availableStationsList','Style','Listbox','Max',30000,'BackgroundColor','w','String',sncls,'Units','Pixel','Position',[10 50 pos(3)*.45 pos(4)*.8],'Parent',h);
        uicontrol('Style','Text','String','Found Stations:','FontAngle','Italic','ForegroundColor',[.6 0 .2],'FontSize',12,'Position',[10 pos(4)*.8+50 pos(3)*.45 12]);
        requestedStationsList = uicontrol('Tag','requestedStationsList','Style','Listbox','Max',30000,'BackgroundColor','w','Units','Pixel','Position',[30+pos(3)*.45 50 pos(3)*.45 pos(4)*.8],'Parent',h);
        uicontrol('Style','Text','String','Stations to request:','FontAngle','Italic','ForegroundColor',[.6 0 .2],'FontSize',12,'Position',[30+pos(3)*.45 pos(4)*.8+50 pos(3)*.45 12]);
        
        % Buttons to control flow of station selections
        requestButton = uicontrol('Style','Pushbutton', 'Position',[pos(3)*.8 20 pos(3)*.1 20],...
            'Parent',h,'String','OK', 'Tag','confirm_stations_to_request_pb','Callback',@confirm_stations_to_request);
        moveRightButton = uicontrol('Style','Pushbutton', 'Position',[pos(3)*.2 20 pos(3)*.1 20],...
            'Parent',h,'String','-->', 'Callback',@move_stations_right);
        moveLeftButton = uicontrol('Style','Pushbutton', 'Position',[pos(3)*.6 20 pos(3)*.1 20],...
            'Parent',h,'String','<--', 'Callback',@move_stations_left);
    else
        msgbox('Need 4 limits for station range');
    end
else
    msgbox('Please limit the station geographic window first!');
end

function confirm_stations_to_request(cbo, eventdata, handles)
figureHandles = findobj('Tag','station_list_box_figure');
buttonHandles = findobj('Tag','confirm_stations_to_request_pb');
outHandles = findobj('Tag','new_fetch_get_stations_pb');
panelHandles = findobj('Tag','new_fetch_station_panel');
netsta = get(figureHandles,'UserData');
% count stations in the right fig
nstations = 0;
for idx = 1:length(netsta.stations)
    if (netsta.leftOrRight(idx) == 1)
        nstations = nstations + 1;
    end
end
userdata.stations = cell(1,nstations);
userdata.networks = cell(1,nstations);
userdata.latitudes = zeros(1,nstations);
userdata.longitudes = zeros(1,nstations);
jdx=1;
for idx = 1:length(netsta.stations);
    if (netsta.leftOrRight(idx) == 1)
        userdata.stations{jdx} = netsta.stations{idx};
        userdata.networks{jdx} = netsta.networks{idx};
        userdata.latitudes(jdx) = netsta.latitudes(idx);
        userdata.longitudes(jdx) = netsta.longitudes(idx);
        jdx = jdx + 1;
    end
end
%disp('here')
set(buttonHandles,'UserData',userdata);
set(outHandles,'UserData',userdata);
set(panelHandles,'UserData',userdata);
close(figureHandles)

% pop up a figure to show the station coverage
figure('Name','Station Map')
load('FL_coasts.mat');
load('FL_stateBoundaries.mat');
load('FL_plates.mat');
plot(ncst(:,1),ncst(:,2),'k',stateBoundaries.longitude, stateBoundaries.latitude,'k', PBlong, PBlat, 'b',userdata.longitudes,userdata.latitudes,'r^');
axis([min(userdata.longitudes) max(userdata.longitudes), min(userdata.latitudes), max(userdata.latitudes)]);
xlabel('Longitude')
ylabel('Latitude')
legend('Coast lines','Political Boundaries','Plate Boundaries','Stations')




function move_stations_right(cbo, eventdata, handles)
LeftListHandles = findobj('Tag','availableStationsList');
RightListHandles = findobj('Tag','requestedStationsList');
figureHandles = findobj('Tag','station_list_box_figure');
netsta = get(figureHandles,'UserData');
% Get the indices of the stations to move
indices = get(LeftListHandles,'Value');
strs = get(LeftListHandles,'String');
for idx = indices
    strTmp = strs(idx,:);
    for jdx=1:length(netsta.stations)
        if strcmp(strTmp,netsta.sncls(jdx,:))
            netsta.leftOrRight(jdx) = 1;
            break
        end
    end
end

% count number on right or left
nleft=0;
nright=0;
for idx = 1:length(netsta.stations)
    if netsta.leftOrRight(idx) == 0
        nleft = nleft+1;
    else
        nright = nright+1;
    end
end

% Create the strings for the right and left sides
ldx = zeros(1,nleft);
jdx = 1;
for idx = 1:length(netsta.stations)
    if netsta.leftOrRight(idx) == 0
        ldx(jdx) = idx;
        jdx = jdx + 1;
    end
end
rdx = zeros(1,nright);
jdx = 1;
for idx = 1:length(netsta.stations)
    if netsta.leftOrRight(idx) == 1
        rdx(jdx) = idx;
        jdx = jdx + 1;
    end
end


% init the print outputs
rightStationsList = repmat('NN.SSSS    ',length(rdx),1);
leftStationsList = repmat('NN.SSSS    ',length(ldx),1);

% write the string lists
for idx = 1:length(rdx)
    if (rdx(idx)  > 0 )
        rightStationsList(idx,:) = sprintf('%s',netsta.sncls(rdx(idx),:));
    end
end
for idx = 1:length(ldx)
    if (ldx(idx) > 0 )
        leftStationsList(idx,:) = sprintf('%s',netsta.sncls(ldx(idx),:));
    end
end

if isempty(rightStationsList)
    rightStationsList = repmat('Empty',1,1);
end
if isempty(leftStationsList)
    leftStationsList = repmat('Empty',1,1);
end

set(figureHandles,'UserData',netsta);
set(RightListHandles,'String',rightStationsList);
set(LeftListHandles,'String',leftStationsList);






function move_stations_left(cbo, eventdata, handles)
LeftListHandles = findobj('Tag','availableStationsList');
RightListHandles = findobj('Tag','requestedStationsList');
figureHandles = findobj('Tag','station_list_box_figure');
netsta = get(figureHandles,'UserData');
% Get the indices of the stations to move
indices = get(RightListHandles,'Value');
strs = get(RightListHandles,'String');
for idx = indices
    strTmp = strs(idx,:);
    for jdx=1:length(netsta.stations)
        if strcmp(strTmp,netsta.sncls(jdx,:))
            netsta.leftOrRight(jdx) = 0;
            break
        end
    end
end

% count number on right or left
nleft=0;
nright=0;
for idx = 1:length(netsta.stations)
    if netsta.leftOrRight(idx) == 0
        nleft = nleft+1;
    else
        nright = nright+1;
    end
end

% Create the strings for the right and left sides
ldx = zeros(1,nleft);
jdx = 1;
for idx = 1:length(netsta.stations)
    if netsta.leftOrRight(idx) == 0
        ldx(jdx) = idx;
        jdx = jdx + 1;
    end
end
rdx = zeros(1,nright);
jdx = 1;
for idx = 1:length(netsta.stations)
    if netsta.leftOrRight(idx) == 1
        rdx(jdx) = idx;
        jdx = jdx + 1;
    end
end


% init the print outputs
rightStationsList = repmat('NN.SSSS    ',length(rdx),1);
leftStationsList = repmat('NN.SSSS    ',length(ldx),1);

% write the string lists
for idx = 1:length(rdx)
    if (rdx(idx)  > 0 )
        rightStationsList(idx,:) = sprintf('%s',netsta.sncls(rdx(idx),:));
    end
end
for idx = 1:length(ldx)
    if (ldx(idx) > 0 )
        leftStationsList(idx,:) = sprintf('%s',netsta.sncls(ldx(idx),:));
    end
end

if isempty(rightStationsList)
    rightStationsList = repmat('Empty',1,1);
end
if isempty(leftStationsList)
    leftStationsList = repmat('Empty',1,1);
end

set(figureHandles,'UserData',netsta);
set(RightListHandles,'String',rightStationsList);
set(LeftListHandles,'String',leftStationsList);
