function fl_view_rf_cross_section_depth_stack(ProjectDirectory,ProjectFile,FuncLabPreferences)
% fl_view_rf_cross_section_depth_stack.m
% Plots a cross section view consisting of migrated RFs along a given
% profile
% Think of this as an unstacked CCP profile
% Created Oct. 14, 2016. Robert W. Porritt

% Probably best to do some type of correction to common ray parameter and
% then stack in time and plot that time domain stack
% Or, alternatively, only have this work for depth migrated RFs

% Modified from fl_view_rf_cross_section to present RF profiles after depth
% migration and stacking with depth. Should be near identical to
% fl_view_rf_cross_section, but with the y-axis changed to depth from time.

% Saves figures as .png files in Figure directory
FileFormat = 'png';
isTexas = 1;

load([ProjectDirectory ProjectFile],'FuncLabPreferences')

edittedPositiveColor = [1 0 0];
edittedNegativeColor = [0 0 1];

%% Check for backwards compability
if length(FuncLabPreferences) < 21
    FuncLabPreferences{19} = 'vel.cpt';
    FuncLabPreferences{20} = false;
    FuncLabPreferences{21} = '1.8.1';
end

if FuncLabPreferences{20} == false
    cmap = cptcmap(FuncLabPreferences{19});
else
    cmap = cptcmap(FuncLabPreferences{19},'flip',true);
end
colormap(cmap);


SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
SetMetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
SetMetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
RecordMetadataDoubles = SetManagementCell{1,3};
RecordMetadataStrings = SetManagementCell{1,2};

% While stacking the RFs, we use a depth migration method for moveout
% correction. This requires a depth increment, but I don't want to code in
% that as a user option, but can be editted here:
dz = 1;


%% First, launch a map view for the user to select end points

% Use preferences to set projection and limits
MapDataPath = regexprep(which('funclab'),'funclab.m','map_data/');


% Set latitude and longitude limits
%--------------------------------------------------------------------------
NorthLat = str2double(FuncLabPreferences{13});
SouthLat = str2double(FuncLabPreferences{14});
WestLon = str2double(FuncLabPreferences{15});
EastLon = str2double(FuncLabPreferences{16});

% Set map projection
%--------------------------------------------------------------------------
MapProjection = FuncLabPreferences{10};

%--------------------------------------------------------------------------
figure('Units','characters','NumberTitle','off','Name','Select Profile Location','Units','characters',...
    'Position',[0 0 165 55],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

ProjectionListNames = {'Stereographic','Orthographic','Azimuthal Equal-area','Azimuthal Equidistant','Gnomonic',...
    'Satellite','Albers Equal-Area Conic','Lambert Conformal Conic','Mercator','Miller Cylindrical','Equidistant Cylindrical',...
    'Transverse Mercator','Sinusoidal','Gall-Peters','Hammer-Aitoff','Mollweide','Robinson','UTM'};
ProjectionListIDs = ProjectionListNames;
MapProjectionIDX = strmatch(MapProjection,ProjectionListNames,'exact');
MapProjectionID = ProjectionListIDs{MapProjectionIDX};

if strcmp(MapProjectionID,'Stereographic') || strcmp(MapProjectionID,'Orthographic') || strcmp(MapProjectionID,'Azimuthal Equal-area') || ...
        strcmp(MapProjectionID,'Azimuthal Equidistant') || strcmp(MapProjectionID,'Gnomonic') || strcmp(MapProjectionID,'Satellite')    
    [~, ~, xdeg] = distaz(SouthLat, WestLon, NorthLat, EastLon);
    m_proj(MapProjectionID,'latitude',(SouthLat + NorthLat)/2, 'longitude',(WestLon + EastLon) / 2,'radius',xdeg/2);
else
    m_proj(MapProjectionID,'latitude',[SouthLat NorthLat],'longitude',[WestLon EastLon]);
end
% Plot coastlines and base
m_gshhs_l('patch',[.9 .9 .9],'edgecolor','black');
m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');

% Plot stations
StationLatitudes = RecordMetadataDoubles(:,10);
StationLongitudes = RecordMetadataDoubles(:,11);
StationCoordinates = unique([StationLatitudes, StationLongitudes],'rows');
StationLatitudes = StationCoordinates(:,1);
StationLongitudes = StationCoordinates(:,2);
OnColor = [.3 .3 .3];
OffColor = [1 .5 .5];
CurrentColor = [ 1 .7 0];
SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
SetOffColor = abs(cross(SetOnColor,OnColor));
m_line(StationLongitudes,StationLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)

if isTexas == 1
    hold on
    for idx=0:27
        fname = sprintf('physio.us.%d',idx);
        physio = load([MapDataPath fname]);
        m_line(physio(:,1), physio(:,2));
    end
end

% Use ginput on two points to get profile location
% Start with message to user asking them to click on two points
screensize = get(0,'screensize');
figpos = [screensize(3) / 2 - 200 screensize(4) / 2 - 50 400 100];
tmpfig = figure('Name','Click 2 points for cross section','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.5 0.6 0.4],'String','Please click 2 points on the map view.','FontSize',12);
waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.4],'String','Click','FontSize',12,'Callback','gcbf.UserData=1; close');
waitfor(waitbutton,'Userdata');
[lon, lat] = ginput(2);

hold on
[lonstart, latstart] = m_xy2ll(lon(1), lat(1));
[lonend, latend] = m_xy2ll(lon(2), lat(2));
mainSegmentLongitude = linspace(lonstart, lonend, 100);
mainSegmentLatitude = linspace(latstart, latend, 100);
m_line(mainSegmentLongitude, mainSegmentLatitude,'LineStyle','-','Color','Black');
[x,y]=m_ll2xy(mainSegmentLongitude(1),mainSegmentLatitude(1));
scatter(x,y,100,'filled','MarkerFaceColor','Black','MarkerEdgeColor','Black');
[x,y]=m_ll2xy(mainSegmentLongitude(25),mainSegmentLatitude(25));
scatter(x,y,100,'filled','MarkerFaceColor','Red','MarkerEdgeColor','Black');
[x,y]=m_ll2xy(mainSegmentLongitude(50),mainSegmentLatitude(50));
scatter(x,y,100,'filled','MarkerFaceColor','Blue','MarkerEdgeColor','Black');
[x,y]=m_ll2xy(mainSegmentLongitude(75),mainSegmentLatitude(75));
scatter(x,y,100,'filled','MarkerFaceColor','Green','MarkerEdgeColor','Black');
[x,y]=m_ll2xy(mainSegmentLongitude(100),mainSegmentLatitude(100));
scatter(x,y,100,'filled','MarkerFaceColor','White','MarkerEdgeColor','Black');
%plot(lon,lat,'Color','Black')
% Add colored dots for reference
% scatter(lon(1), lat(1), 100,'filled','MarkerFaceColor','k','MarkerEdgeColor','k')
% scatter(lon(2), lat(2), 100,'filled','MarkerFaceColor','w','MarkerEdgeColor','k')
% scatter((lon(1)+lon(2))/2, (lat(1)+lat(2))/2, 100,'filled','MarkerFaceColor','b','MarkerEdgeColor','k')
% scatter((lon(2)-lon(1))/4+lon(1), (lat(2)-lat(1))/4+lat(1), 100,'filled','MarkerFaceColor','r','MarkerEdgeColor','k')
% scatter((lon(2)-lon(1))*3/4+lon(1), (lat(2)-lat(1))*3/4+lat(1), 100,'filled','MarkerFaceColor','g','MarkerEdgeColor','k')

% Print lat/lon locations to terminal for user
fprintf('Creating profile from [%3.3f, %3.3f] to [%3.3f, %3.3f]\n',latstart, lonstart, latend, lonend);

% Preset the profile options
assignin('base','ProfileWidth',1.0);
assignin('base','ProfileType','Radial RF');
assignin('base','ProfileGain',1.0);
DepthMin = '0';
DepthMax = 'Default';

assignin('base','DepthMin',0);
assignin('base','DepthMax',-1); % We'll use -1 as a flag to indicate when the maximum depth is set to default

% Need to get info about component and thickness
figpos = [screensize(3) / 2 - 200 screensize(4) / 2  400 200];
tmpfig = figure('Name','Set cross section parameters','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.025 0.8 0.3 0.1],'String','Box width (degrees):','FontSize',12);
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.34 0.8 0.2 0.1],'String','1.0','FontSize',12,'Tag','width_control_edit_box','Callback',@setprofilewidth);
%Components = {'Radial RF', 'Transverse RF', 'Vertical','Radial','Transverse'};
Components = {'Radial RF', 'Transverse RF'};
uicontrol('Style','Popupmenu','Parent',tmpfig,'Units','Normalized','Position',[0.6 0.8 0.35 0.1],'String',Components,'Value',1,'FontSize',12,'Tag','component_popupmenu','Callback',@setprofiletype);

uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.025 0.6 0.3 0.1],'String','Gain:','FontSize',12);
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.34 0.6 0.2 0.1],'String','1.0','FontSize',12,'Tag','gain_control_edit_box','Callback',@setprofilegain);

% Set text to separate min and max boxes
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.45 0.3 0.1],'String','Min:','FontSize',12);
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.55 0.45 0.3 0.1],'String','Max:','FontSize',12);
% Set min and max depth
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.025 0.35 0.3 0.1],'String','Depth Limits:','FontSize',12);
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.34 0.35 0.2 0.1],'String',DepthMin,'FontSize',12,'Tag','mindepth_control_edit_box','Callback',@setprofilemindepth);
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.6 0.35 0.2 0.1],'String',DepthMax,'FontSize',12,'Tag','maxdepth_control_edit_box','Callback',@setprofilemaxdepth);

waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.6 0.1 0.35 0.15],'String','Confirm','FontSize',12,'Callback','gcbf.UserData=1; close');
waitfor(waitbutton,'Userdata');

%% Extract RFs along profile
% Begin by defining a rectangle for the profile
ptright = [lonstart, latstart, 0];
ptleft = [lonend, latend, 0];
[FullProfileDistance, azi, xdeg] = distaz(ptright(2), ptright(1), ptleft(2), ptleft(1));
OffAxisDistance = evalin('base','ProfileWidth'); %degrees

% Define the normal vector to the plane. 
ptnorm = [ptright(1), ptright(2), 800];
normal = cross(ptnorm - ptright, ptnorm - ptleft);
ss = sqrt(normal(1) * normal(1) + normal(2) * normal(2) + normal(3) * normal(3));
normal = normal / ss;
pt1 = [ptright(1) + normal(1) * OffAxisDistance/2, ptright(2) + normal(2) * OffAxisDistance/2];
pt2 = [ptright(1) - normal(1) * OffAxisDistance/2, ptright(2) - normal(2) * OffAxisDistance/2];
pt3 = [ptleft(1) - normal(1) * OffAxisDistance/2, ptleft(2) - normal(2) * OffAxisDistance/2];
pt4 = [ptleft(1) + normal(1) * OffAxisDistance/2, ptleft(2) + normal(2) * OffAxisDistance/2];

% pts 1-4 are the vertices of the rectangle. However, if we don't connect
% them for the inpolygon call, then it will make a greater circle rather
% than a flattened circle.
% So lets manually connect all the vertices:
% 1->2->3->4->1
% [~, seg1Lon, seg1Lat] = m_geodesic(pt1(1), pt1(2), pt2(1), pt2(2), 40);
% [~, seg2Lon, seg2Lat] = m_geodesic(pt2(1), pt2(2), pt3(1), pt3(2), 40);
% [~, seg3Lon, seg3Lat] = m_geodesic(pt3(1), pt3(2), pt4(1), pt4(2), 40);
% [~, seg4Lon, seg4Lat] = m_geodesic(pt4(1), pt4(2), pt1(1), pt1(2), 40);
seg1Lon = linspace(pt1(1), pt2(1),40);
seg1Lat = linspace(pt1(2), pt2(2),40);
seg2Lon = linspace(pt2(1), pt3(1),40);
seg2Lat = linspace(pt2(2), pt3(2),40);
seg3Lon = linspace(pt3(1), pt4(1),40);
seg3Lat = linspace(pt3(2), pt4(2),40);
seg4Lon = linspace(pt4(1), pt1(1),40);
seg4Lat = linspace(pt4(2), pt1(2),40);

% Plot to make sure it works
%m_line([pt1(1), pt2(1), pt3(1), pt4(1), pt1(1)], [pt1(2), pt2(2), pt3(2), pt4(2), pt1(2)],'LineStyle','-');
m_line([seg1Lon, seg2Lon, seg3Lon, seg4Lon], [seg1Lat, seg2Lat, seg3Lat, seg4Lat],'LineStyle','-','Color','Red');

%RecordsInPolygon = inpolygon(RecordMetadataDoubles(:,11), RecordMetadataDoubles(:,10),[pt1(1), pt2(1), pt3(1), pt4(1), pt1(1)], [pt1(2), pt2(2), pt3(2), pt4(2), pt1(2)]);
RecordsInPolygon = inpolygon(RecordMetadataDoubles(:,11), RecordMetadataDoubles(:,10),[seg1Lon, seg2Lon, seg3Lon, seg4Lon], [seg1Lat, seg2Lat, seg3Lat, seg4Lat]);

ActiveRecordIndices = find(RecordsInPolygon == 1);
ActiveRecordDoubles = RecordMetadataDoubles(ActiveRecordIndices,:);
ActiveRecordStrings = RecordMetadataStrings(ActiveRecordIndices,:);

% Use these lines to determine the stations left in the profile and plot
% them with a different color on the map view
C=unique([ActiveRecordDoubles(:,11), ActiveRecordDoubles(:,10)],'rows');
m_line(C(:,1),C(:,2),'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[1 0 0])
drawnow
OutputFigureDir = [ProjectDirectory filesep 'FIGURES' filesep 'RF_Cross_Section_Depth_Stack'];
mkdir(OutputFigureDir);
locationMapFname = sprintf('LocationMap.%3.3f_%3.3f_%3.3f_%3.3f.%s',lonstart, latstart, lonend, latend, FileFormat);
saveas(gcf,[OutputFigureDir filesep locationMapFname],FileFormat);


%% Gather the records
%nStations = length(unique(ActiveRecordStrings(:,2)));
StationNames = unique(ActiveRecordStrings(:,2));
nStations = length(StationNames);
StationLongitudes = zeros(1,nStations);
StationLatitudes = zeros(1,nStations);
%StartTimeArray = sscanf(FuncLabPreferences{4},'%f');
%EndTimeArray = sscanf(FuncLabPreferences{5},'%f');
%StepTimeArray = sscanf(FuncLabPreferences{6},'%f');
%TimeArray = StartTimeArray:StepTimeArray:EndTimeArray;
StartDepthArray = evalin('base','DepthMin');
EndDepthArray = evalin('base','DepthMax');
if StartDepthArray < 0
    StartDepthArray = 0;
end
if EndDepthArray < 0
    EndDepthArray = 200;
end
StepDepthArray = dz;
DepthArray = StartDepthArray:StepDepthArray:EndDepthArray;
% Data Matrix, nstations x ntimes, will hold the stacked data for each
% station in the profile
DataMatrix = zeros(length(DepthArray),nStations);

% Go through each station and read all the seismograms for that station and
% that component. Stack and drop into DataMatrix

% In this case, we want to stack all RFs over all back azimuth and ray
% parameters. In order to correct for incidence variations, we'll first map
% to depth and then re-interpolate onto a common time array. We need a
% second function to plot them more in a 3D ray space.
VelModel = FuncLabPreferences{8};
oneDVel = load(VelModel,'-ascii');
ProfileType = evalin('base','ProfileType');

% Setup a waitbar to help the user track
wb=waitbar(0,'Please wait. Migrating and stacking records','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(wb,'canceling',0);

% Loop through stations
for istation = 1:nStations
    
    % Get indices for this station's records
    idx = strcmp(ActiveRecordStrings(:,2), StationNames(istation)); 
    CurrentStationIndices = find(idx==1);

    % Prepare empty cell arrays for this station
    nActiveRecords = 0;
    for irecord=1:length(CurrentStationIndices)
        thisIndex = CurrentStationIndices(irecord);
        if ActiveRecordDoubles(thisIndex,2) == 1
            nActiveRecords = nActiveRecords + 1;
        end
    end
    RFAmps = cell(1,nActiveRecords);
    RFTimes = cell(1,nActiveRecords);
    rayparams = zeros(1,nActiveRecords);
    % For counting the active records
    jrecord = 0;
    
    % Get location of this station
    StationLongitudes(istation) = ActiveRecordDoubles(CurrentStationIndices(1),11);
    StationLatitudes(istation) = ActiveRecordDoubles(CurrentStationIndices(1),10);
    
    % Loop through the receiver functions
    for irecord = 1:length(CurrentStationIndices)
        % This references it back to the main project RFs
        thisIndex = CurrentStationIndices(irecord);
        
        % Check to make sure this rf is active
        if ActiveRecordDoubles(thisIndex, 2) == 1
            jrecord = jrecord + 1;
            % Here we implement the switch between radial and transverse
            % RFs
            if strcmp(ProfileType,'Radial RF')
                fname = sprintf('%seqr',ActiveRecordStrings{thisIndex,1});
            elseif strcmp(ProfileType,'Transverse RF')
                fname = sprintf('%seqt',ActiveRecordStrings{thisIndex,1});
            else
                disp('Profile Type not coded properly. Defaulting to radial RF')
                fname = sprintf('%seqr',ActiveRecordStrings{thisIndex,1});
            end
            
            % Load the seismogram
            [EqAmpTime, EQTime] = fl_readseismograms([ProjectDirectory fname]);
            
            % Place into cell arrays for time, amplitude, and ray parameter
            RFAmps{jrecord} = EqAmpTime;
            RFTimes{jrecord} = EQTime;
            rayparams(jrecord) = ActiveRecordDoubles(thisIndex,18);
   
        end
    end
    
    % Finish this station by correcting for variable incidence, stacking,
    % and appending to the data matrix
    
    CorrectedSeismogramAmps = mapPsSeis2depth_1d_v2( RFTimes, RFAmps, rayparams, dz, oneDVel(:,1), oneDVel(:,2), oneDVel(:,3), DepthArray );
    stackArray = zeros(1,length(DepthArray));
    for itrace=1:length(CorrectedSeismogramAmps)
        stackArray = stackArray + CorrectedSeismogramAmps{itrace};
    end
    % Normalize the stack based on the max abs
    stackArray = stackArray / max(abs(stackArray));
    
    % append to main matrix
    DataMatrix(:,istation) = stackArray;
    
    % For the user to cancel
    if getappdata(wb,'canceling')
        delete(wb);
        disp('Canceled during stacking')
        return
    end
    waitbar(istation/nStations,wb);
    

end
delete(wb);

%% Now calculate the horizontal axis
%  This is distance (km) from the start location of the profile
%  We'll also need to project the station onto the profile
StationDistances = zeros(1,nStations);
for istation=1:nStations
    q=[StationLongitudes(istation), StationLatitudes(istation), 0];
    p=[ptright(1), ptright(2), 0];
    q_proj = q - dot(q-p, normal) * normal;
    [StationDistances(istation), ~, ~] = distaz(p(2), p(1), q_proj(2), q_proj(1));
end

%% Separate the positive and negative amplitudes
AMPS = DataMatrix;
AmplitudeFactor = FullProfileDistance / nStations;
MaximumAmplitude = max(abs(AMPS));
MaximumAmplitude = repmat(MaximumAmplitude,size(AMPS,1),1);
NormalizedAmplitudes = AMPS ./ MaximumAmplitude;
Gain = evalin('base','ProfileGain');
Amplitudes = NormalizedAmplitudes .* (AmplitudeFactor * Gain);
PositiveIndices = find (Amplitudes > 0);
NegativeIndices = find (Amplitudes < 0);
TempAmps = reshape(Amplitudes,[],1);
Pamps = zeros (size(TempAmps));
Pamps(PositiveIndices) = TempAmps(PositiveIndices);
Namps = zeros (size(TempAmps));
Namps(NegativeIndices) = TempAmps(NegativeIndices);
PFilledTrace = reshape(Pamps,size(Amplitudes));
NFilledTrace = reshape(Namps,size(Amplitudes));
DepthAxis = DepthArray';
PFilledTrace = [zeros(1,size(PFilledTrace,2)); PFilledTrace; zeros(1,size(PFilledTrace,2))];
NFilledTrace = [zeros(1,size(NFilledTrace,2)); NFilledTrace; zeros(1,size(NFilledTrace,2))];
DepthAxis = [ones(1,size(DepthAxis,2)) .* DepthAxis(1,:);
    DepthAxis;
    ones(1,size(DepthAxis,2)) .* DepthAxis(end,:)];

%% Now we make the profile
ProfileFigureHandles = figure('Units','characters','NumberTitle','off','Name','X-section','Units','characters',...
    'Position',[0 0 165 55],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});
ax = axes('Parent',ProfileFigureHandles);
xlim(ax,[0 FullProfileDistance])
ylim(ax,[StartDepthArray EndDepthArray])
set(ax,'YDir','Reverse')
grid(ax,'on')
grid(ax,'minor')
box(ax,'on')
ylabel(ax,'Depth (km)')
xlabel(ax,'Distance (km)')
if strcmp(ProfileType,'Radial RF')
    title('Radial RF')
else
    title ('Transverse RF')
end

% Plot amplitudes along profile
hold(ax,'on')
for istation=1:nStations
   n = StationDistances(istation);
   vp = [PFilledTrace(:,istation)'+n; DepthAxis'];
   vn = [NFilledTrace(:,istation)'+n; DepthAxis'];
   idx = length(vp);
   vvp = vp;
   vvn = vn;
   vvp(1,idx+1) = n;
   vvp(2,idx+1) = max(DepthAxis);
   vvp(1,idx+2) = n;
   vvp(2,idx+2) = min(DepthAxis);
   vvn(1,idx+1) = n;
   vvn(2,idx+1) = max(DepthAxis);
   vvn(1,idx+2) = n;
   vvn(2,idx+2) = min(DepthAxis);
   ff=length(vvp):-1:1;
   patch(ax,'Faces',ff,'Vertices',vvp','FaceColor',edittedPositiveColor,'EdgeColor','none','Tag','phandle');
   patch(ax,'Faces',ff,'Vertices',vvn','FaceColor',edittedNegativeColor,'EdgeColor','none','Tag','nhandle');
   line(ax,(Amplitudes(:,istation) + n),DepthArray,'Color',[0 0 0],'LineWidth',1)
end

% Plot the colored dots on top
x=0;
y=0;
scatter(ax,x,y,100,'filled','MarkerFaceColor','Black','MarkerEdgeColor','Black');
[x,~,~] = distaz(latstart, lonstart, mainSegmentLatitude(25),mainSegmentLongitude(25));
scatter(ax,x,y,100,'filled','MarkerFaceColor','Red','MarkerEdgeColor','Black');
[x,~,~] = distaz(latstart, lonstart, mainSegmentLatitude(50),mainSegmentLongitude(50));
scatter(ax,x,y,100,'filled','MarkerFaceColor','Blue','MarkerEdgeColor','Black');
[x,~,~] = distaz(latstart, lonstart, mainSegmentLatitude(75),mainSegmentLongitude(75));
scatter(ax,x,y,100,'filled','MarkerFaceColor','Green','MarkerEdgeColor','Black');
[x,~,~] = distaz(latstart, lonstart, mainSegmentLatitude(100),mainSegmentLongitude(100));
scatter(ax,x,y,100,'filled','MarkerFaceColor','White','MarkerEdgeColor','Black');

profileFname = sprintf('RFProfile.%3.3f_%3.3f_%3.3f_%3.3f.%s',lonstart, latstart, lonend, latend, FileFormat);
saveas(ProfileFigureHandles,[OutputFigureDir filesep profileFname],FileFormat);
end



function setprofilemindepth(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','DepthMin',val);
end

function setprofilemaxdepth(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','DepthMax',val);
end


function setprofilewidth(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','ProfileWidth',val);
end

function setprofilegain(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','ProfileGain',val);
end

function setprofiletype(source, callbackdata)
    val=source.Value;
    opts = source.String;
    assignin('base','ProfileType',opts{val});
end




