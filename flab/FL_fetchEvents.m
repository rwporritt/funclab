function FL_fetchEvents(cbo,eventdata)
%% Callback function for when the Find Events button is pressed.
%  Obtains search parameters from other ui objects to call irisFetch.Events
%  gives the user the list of found event and asks them to select active
%  ones in the same way as when they find stations (whose callbacks are
%  buried in the main funclab.m!)



%% get timing
%  start
startYearHandle = findobj('Tag','new_fetch_start_year_pu');
startYear = get(startYearHandle,'Value') + 1975;

startMonthHandle = findobj('Tag','new_fetch_start_month_pu');
startMonth = get(startMonthHandle,'Value');

startDayHandle = findobj('Tag','new_fetch_start_day_pu');
startDay = get(startDayHandle,'Value');

startJday = dayofyear(startYear, startMonth, startDay);
startTimeString = epochTimeToIrisString(datenum(startYear, startMonth, startDay));

%  end
endYearHandle = findobj('Tag','new_fetch_end_year_pu');
endYear = get(endYearHandle,'Value') + 1975;

endMonthHandle = findobj('Tag','new_fetch_end_month_pu');
endMonth = get(endMonthHandle,'Value');

endDayHandle = findobj('Tag','new_fetch_end_day_pu');
endDay = get(endDayHandle,'Value');

endJday = dayofyear(endYear, endMonth, endDay);
endTimeString = epochTimeToIrisString(datenum(endYear, endMonth, endDay));


%% Get magnitude range
mag = 5.5:0.25:10;
minMagHandle = findobj('Tag','new_fetch_min_mag_pu');
minMagnitudeIdx = get(minMagHandle,'Value');
minMag = mag(minMagnitudeIdx);

maxMagHandle = findobj('Tag','new_fetch_max_mag_pu');
maxMagnitudeIdx = get(maxMagHandle,'Value');
maxMag = mag(maxMagnitudeIdx);

%% Distance window
%  start by finding the network center and distance to corners
stationInfoHandles = findobj('Tag','new_fetch_get_stations_pb');
stationInfo = get(stationInfoHandles,'UserData');
if isempty(stationInfo)
    str=sprintf('Error, find your stations first.');
    errordlg(str)
    return
end
stationLongitudes = zeros(1,length(stationInfo.longitudes));
stationLatitudes = zeros(1,length(stationInfo.latitudes));
for i=1:length(stationInfo.longitudes)
    stationLongitudes(i) = stationInfo.longitudes{i};
    stationLatitudes(i) = stationInfo.latitudes{i};
end
medianLongitude = median(stationLongitudes);
medianLatitude = median(stationLatitudes);
maxWidthLongitude = max(diff(stationLongitudes));
maxHeightLatitude = max(diff(stationLatitudes));
ExtraSpace = sqrt(maxWidthLongitude^2/4+maxHeightLatitude^2/4);

minDistanceHandles = findobj('Tag','new_fetch_min_dist_e');
minDistance = str2double(get(minDistanceHandles,'String'));

maxDistanceHandles = findobj('Tag','new_fetch_max_dist_e');
maxDistance = str2double(get(maxDistanceHandles,'String'));


%% Depth window
minDepthHandles = findobj('Tag','new_fetch_min_depth_e');
minDepth = str2double(get(minDepthHandles,'String'));

maxDepthHandles = findobj('Tag','new_fetch_max_depth_e');
maxDepth = str2double(get(maxDepthHandles,'String'));


%% Error checking
if irisTimeStringToEpoch(startTimeString) > irisTimeStringToEpoch(endTimeString)
    str = sprintf('Error, %s must be earlier than %s',startTimeString, endTimeString);
    errordlg(str);
    return
end

if minMag > maxMag
    str = sprintf('Error, your minimum magnitude must be less than your max!');
    errordlg(str);
    return
end

if minDepth > maxDepth
    str = sprintf('Error, your minimum depth must be less than your max!');
    errordlg(str);
    return
end

if minDistance > maxDistance
    str = sprintf('Error, your minimum distance must be less than your max!');
    errordlg(str);
    return
end

if minDistance-ExtraSpace/2 < 0
    minDistanceSearch = 0;
else
    minDistanceSearch = minDistance - ExtraSpace/2;
end

if maxDistance+ExtraSpace/2 > 180
    maxDistanceSearch = 180;
else
    maxDistanceSearch = maxDistance + ExtraSpace/2;
end

%% Prepare call
%events = irisFetch.Events('MinimumMagnitude',minMag, 'MaximumMagnitude',maxMag,...
%    'startTime',startTimeString,'endTime',endTimeString,...
%    'radialcoordinates',[medianLatitude, medianLongitude, maxDistanceSearch, minDistanceSearch],...
%    'BASEURL','http://service.iris.edu/fdsnws/event/1/');
% The radial coordinates causes a time out on large numbers of events
ev = irisFetch.Events('MinimumMagnitude',minMag, 'MaximumMagnitude',maxMag,...
    'startTime',startTimeString,'endTime',endTimeString,...
    'BASEURL','http://service.iris.edu/fdsnws/event/1/');
% Here we remove events that are outside the distance window
nevents = length(ev);
fprintf('Removing events outside of the desired window...\n');
for ievt = nevents:-1:1
    [~, ~, xdeg] = distaz(medianLatitude, medianLongitude, ev(ievt).PreferredLatitude, ev(ievt).PreferredLongitude);
    if xdeg > maxDistanceSearch | xdeg < minDistanceSearch
        ev(ievt) = [];
    end  
end

jevent = 0;
for ievent = 1:length(ev)
    if ev(ievent).PreferredDepth >= minDepth && ev(ievent).PreferredDepth <= maxDepth
        jevent = jevent + 1;
    end
end
newevents = repmat(ev(1),1,jevent);
jevent = 0;
for ievent = 1:length(ev)
    if ev(ievent).PreferredDepth >= minDepth && ev(ievent).PreferredDepth <= maxDepth
        jevent = jevent + 1;
        newevents(jevent) = ev(ievent);
    end
end

% The Min/max depth arguments cause irisFetch to behave weirdly slow. 
%events = irisFetch.Events('MinimumMagnitude',minMag, 'MaximumMagnitude',maxMag,...
%    'startTime',startTimeString,'endTime',endTimeString,...
%    'minimumDepth',minDepth,'maximumDepth',maxDepth,...
%    'radialcoordinates',[medianLatitude, medianLongitude, maxDistanceSearch, minDistanceSearch],...
%    'BASEURL','http://service.iris.edu/fdsnws/event/1/');
% for idx=1:10
%     events(idx).FlinnEngdahlRegionName = sprintf('neverland_%d',idx);
%     events(idx).PreferredTime = sprintf('2007-07-07 42:42:42',idx);
%     events(idx).PreferredLongitude = -120.0*idx;
%     events(idx).PreferredLatitude = 42.0/idx';
%     events(idx).PreferredDepth = mod(10,idx);
%     events(idx).PreferredMagnitudeValue = 10.4+idx;
% end
clear ev;
ev = newevents;

fprintf('Found %d events in the desired window.\n',length(ev));

set(gcbo,'UserData',ev);
%str = sprintf('Found %d events!',length(events));
%msgbox(str);

%% Here is where we can ask the user to subset events...
figHdls = figure('Name','Select Events','Tag','fetchEvents_table_figure','Units','Pixels','Position',[528 480 931 469]);
OriginName = cell(1,length(ev));
OriginTime = cell(1,length(ev));
OriginLatitude = cell(1,length(ev));
OriginLongitude = cell(1,length(ev));
OriginDepth = cell(1,length(ev));
OriginMagnitude = cell(1,length(ev));
OriginMeanBaz = cell(1,length(ev));
OriginMeanGcarc = cell(1,length(ev));
truthTable = cell(1,length(ev));
for i=1:length(ev)
    OriginName{i} = sprintf('%s',ev(i).FlinnEngdahlRegionName);
    OriginTime{i} = sprintf('%s',ev(i).PreferredTime);
    OriginLatitude{i} = ev(i).PreferredLatitude;
    OriginLongitude{i} = ev(i).PreferredLongitude;
    OriginDepth{i} = ev(i).PreferredDepth;
    OriginMagnitude{i} = ev(i).PreferredMagnitudeValue;
    [~, OriginMeanBaz{i}, OriginMeanGcarc{i}] = distaz(medianLatitude, medianLongitude, OriginLatitude{i}, OriginLongitude{i});
    truthTable{i} = true;
end
tableHdls = uitable('Parent',figHdls,'Data',[OriginTime', OriginLatitude', OriginLongitude', OriginDepth', OriginMagnitude', OriginMeanBaz',OriginMeanGcarc', OriginName',truthTable'],...
            'ColumnName',{'Origin Time','Latitude','Longitude','Depth','Magnitude','||Baz||','||GCARC||','Region Name','Active'},...
            'ColumnEditable',[false, false, false, false, false, false, false,false,true],...
            'Units','Normalized','Position',[0.05 0.05 0.8 0.9],...
            'UserData',ev,'Tag','new_fetch_get_events_table');

pbHdls = uicontrol('Parent',figHdls,'Style','PushButton','String','OK','Units','Normalized',...
            'Position',[0.85 0.05 0.15 0.1],'FontSize',12,...
            'Callback',@return_event_selection_to_funclab_and_plot);
        
        selectAllPbHandles = uicontrol('Parent',figHdls,'Style','Pushbutton','String','Select All','Units','Normalized',...
            'Position',[0.85 0.15 0.15 0.1],'FontSize',12,...
            'Callback',@turn_on_all_events);
        
        selectNonePbHandles = uicontrol('Parent',figHdls,'Style','Pushbutton','String','Select None','Units','Normalized',...
            'Position',[0.85 0.25 0.15 0.1],'FontSize',12,...
            'Callback',@turn_off_all_events);
        
        invertSelectionPbHandles = uicontrol('Parent',figHdls,'Style','Pushbutton','String','Invert Selection','Units','Normalized',...
            'Position',[0.85 0.35 0.15 0.1],'FontSize',12,...
            'Callback',@invert_event_choices);        
        
        sortEventsByText = uicontrol('Parent',figHdls,'Style','Text','String','Sort by:','Units','Normalized',...
            'Position',[0.85 0.49 0.05 0.1]);
        
        sortEventByPopupMenu = uicontrol('Parent',figHdls,'Style','PopupMenu','Units','Normalized',...
            'Position',[0.85 0.45 0.15 0.1],'FontSize',12,'BackgroundColor',[1 1 1], ...
            'String',{'Origin Time (recent to historic)','Origin Time (historic to recent)','Latitude (N->S)','Latitude (S->N',...
            'Longitude (E->W)','Longitude (W->E)','Depth (shallow to deep)','Depth (deep to shallow)','Magnitude (big to small)',...
            'Magnitude (small to big)','Mean Baz (ascending)','Mean Baz (descending)', 'mean distance (near to far)','mean distance (far to near)',...
            'Region Name (alphabetical)','Region Name (reverse alphabetical)'},'Value',1,'Tag','sortEventPopup',...
            'Callback',@sort_event_choices_callback);
        
        

%% make a plot; as a check, pull the event info from where it should now be
% stored
%  Set to callback for table 'ok' button
function return_event_selection_to_funclab_and_plot(cbo, eventdata)
% Handles to the original calling button
hdls = findobj('Tag','new_fetch_find_events_pb');
% Handles to the table so we can get logic info
tableHdls = findobj('Tag','new_fetch_get_events_table');
logicInfo = get(tableHdls,'Data');
% And the raw event information from the irisFetch command
evInfo = get(hdls,'UserData');
% Count the kept events
neventsTotal = length(evInfo);
nevents = 0;
for i=1:length(evInfo)
    if logicInfo{i,9} == true
        nevents = nevents + 1;
    end
end

% Structure of cells for output
ev.OriginName = cell(1,nevents);
ev.OriginTime = cell(1,nevents);
ev.OriginLatitude = cell(1,nevents);
ev.OriginLongitude = cell(1,nevents);
ev.OriginDepth = cell(1,nevents);
ev.OriginMagnitude = cell(1,nevents);

% store min/max distances
minDistanceHandles = findobj('Tag','new_fetch_min_dist_e');
minDistance = str2double(get(minDistanceHandles,'String'));
maxDistanceHandles = findobj('Tag','new_fetch_max_dist_e');
maxDistance = str2double(get(maxDistanceHandles,'String'));
ev.minDistance = minDistance;
ev.maxDistance = maxDistance;

% vectors for plotting
evLongitudes = zeros(1,nevents);
evLatitudes = zeros(1,nevents);
evDepths = zeros(1,nevents);
jdx=1;
for idx=1:neventsTotal
    if logicInfo{idx,9} == true
        ev.OriginName{jdx} = logicInfo{idx,8};
        ev.OriginTime{jdx} = logicInfo{idx,1};
        ev.OriginLatitude{jdx} = logicInfo{idx,2};
        ev.OriginLongitude{jdx} = logicInfo{idx,3};
        ev.OriginDepth{jdx} = logicInfo{idx,4};
        ev.OriginMagnitude{jdx} = logicInfo{idx,5};
        evLongitudes(jdx) = logicInfo{idx,3};
        evLatitudes(jdx) = logicInfo{idx,2};
        evDepths(jdx) = logicInfo{idx,4};
        jdx = jdx + 1;
    end
end
close(findobj('Tag','fetchEvents_table_figure'))
% Store ev
panelHandles = findobj('Tag','new_fetch_events_panel');
set(panelHandles,'UserData',ev);

% Just plotting:
stationInfoHandles = findobj('Tag','new_fetch_station_panel');
stationInfo = get(stationInfoHandles,'UserData');
stationLatitudes = zeros(1,length(stationInfo.latitudes));
stationLongitudes = zeros(1,length(stationInfo.longitudes));
for i=1:length(stationInfo.longitudes)
    stationLongitudes(i) = stationInfo.longitudes{i};
    stationLatitudes(i) = stationInfo.latitudes{i};
end

load('FL_coasts.mat');
load('FL_stateBoundaries.mat');
load('FL_plates.mat');
figure('Name','Events found:','Toolbar','Figure','Units','Pixels','Position',[528 480 931 469]);
hold on
plot(ncst(:,1),ncst(:,2),'k',stateBoundaries.longitude, stateBoundaries.latitude,'k', PBlong, PBlat, 'b',stationLongitudes,stationLatitudes,'r^');
%scatter(evLongitudes, evLatitudes,10,evDepths,'filled');
plot(evLongitudes, evLatitudes, 'r*')
axis([-180 180 -90 90]);
legend('Coast lines','Political Boundaries','Plate Boundaries','Stations','Earthquakes')
%colormap(flipud(colormap));
%colorbar

function sort_event_choices_callback(cbo, eventdata)
tableHdls = findobj('Tag','new_fetch_get_events_table');
popupHdls = gcbo;
logicInfo = get(tableHdls,'Data');
sortChoice = get(popupHdls,'Value');
dims = size(logicInfo);
nevents = dims(1);
tmpStr = cell(1,nevents);
tmpFloats = zeros(1,nevents);
% Determine the order of indices for output
switch sortChoice
    case 1 %time recent to historic (also note this is the default from irisFetch.event)
        for ievent = 1:nevents
            tmpFloats(ievent) = irisTimeStringToEpoch(logicInfo{ievent,1});
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
        iEventSort = fliplr(iEventSort);
    case 2
        for ievent = 1:nevents
            tmpFloats(ievent) = irisTimeStringToEpoch(logicInfo{ievent,1});
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
    case 3
        for ievent = 1:nevents
            tmpFloats(ievent) = logicInfo{ievent,2};
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
        iEventSort = fliplr(iEventSort);
    case 4
        for ievent = 1:nevents
            tmpFloats(ievent) = logicInfo{ievent,2};
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
    case 5
        for ievent = 1:nevents
            tmpFloats(ievent) = logicInfo{ievent,3};
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
        iEventSort = fliplr(iEventSort);
    case 6
        for ievent = 1:nevents
            tmpFloats(ievent) = logicInfo{ievent,3};
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
    case 7
        for ievent = 1:nevents
            tmpFloats(ievent) = logicInfo{ievent,4};
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
    case 8
        for ievent = 1:nevents
            tmpFloats(ievent) = logicInfo{ievent,4};
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
        iEventSort = fliplr(iEventSort);
    case 9        
        for ievent = 1:nevents
            tmpFloats(ievent) = logicInfo{ievent,5};
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
        iEventSort = fliplr(iEventSort);
    case 10
        for ievent = 1:nevents
            tmpFloats(ievent) = logicInfo{ievent,5};
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
    case 11        
        for ievent = 1:nevents
            tmpFloats(ievent) = logicInfo{ievent,6};
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
        iEventSort = fliplr(iEventSort);
    case 12
        for ievent = 1:nevents
            tmpFloats(ievent) = logicInfo{ievent,6};
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
    case 13       
        for ievent = 1:nevents
            tmpFloats(ievent) = logicInfo{ievent,7};
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
    case 14
        for ievent = 1:nevents
            tmpFloats(ievent) = logicInfo{ievent,7};
        end
        [tmpSort, iEventSort] = sort(tmpFloats);
        iEventSort = fliplr(iEventSort);
    case 15      
        for ievent = 1:nevents
            tmpStr{ievent} = logicInfo{ievent,8};
        end
        [tmpSort, iEventSort] = sort(tmpStr);
    case 16
        for ievent = 1:nevents
            tmpStr{ievent} = logicInfo{ievent,8};
        end
        [tmpSort, iEventSort] = sort(tmpStr);
        iEventSort = fliplr(iEventSort);
end
% create new cell arrays sorted in iEventSort order
% Structure of cells for output
ev=cell(nevents,9);
for ievent=1:nevents
    jevent = iEventSort(ievent);
    ev{ievent,1} = logicInfo{jevent,1};
    ev{ievent,2} = logicInfo{jevent,2};
    ev{ievent,3} = logicInfo{jevent,3};
    ev{ievent,4} = logicInfo{jevent,4};
    ev{ievent,5} = logicInfo{jevent,5};
    ev{ievent,6} = logicInfo{jevent,6};
    ev{ievent,7} = logicInfo{jevent,7};
    ev{ievent,8} = logicInfo{jevent,8};
    ev{ievent,9} = logicInfo{jevent,9};
end
set(tableHdls,'Data',ev);
drawnow

    

function turn_on_all_events(cbo, eventdata)
tableHdls = findobj('Tag','new_fetch_get_events_table');
dataTable = get(tableHdls,'Data');
dims = size(dataTable);
for idx=1:dims(1)
    dataTable{idx,9} = true;
end
set(tableHdls,'Data',dataTable);
drawnow


function turn_off_all_events(cbo, eventdata)
tableHdls = findobj('Tag','new_fetch_get_events_table');
dataTable = get(tableHdls,'Data');
dims = size(dataTable);
for idx=1:dims(1)
    dataTable{idx,9} = false;
end
set(tableHdls,'Data',dataTable);
drawnow


function invert_event_choices(cbo, eventdata)
tableHdls = findobj('Tag','new_fetch_get_events_table');
dataTable = get(tableHdls,'Data');
dims = size(dataTable);
for idx=1:dims(1)
    if dataTable{idx,9} == true
        dataTable{idx,9} = false;
    else
        dataTable{idx,9} = true;
    end
end
set(tableHdls,'Data',dataTable);
drawnow





