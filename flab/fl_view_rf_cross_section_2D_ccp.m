function fl_view_rf_cross_section_2D_CCP(ProjectDirectory,ProjectFile,FuncLabPreferences)
% fl_view_rf_cross_section_2D_CCP.m
% Plots a cross section view consisting of migrated RFs along a given
% profile
% Based on fl_view_rf_cross_section_depth()
% But once the data is gathered from the cross section, it stacks in the 2D
% plane for an on-the-fly ccp cross section
% Created Dec. 5, 2016. Robert W. Porritt

% This version is modified from fl_view_rf_cross_section 
% Rather than plot a over all back azimuths corrected for move-out, here we
% plot RF amplitudes projected onto the profile. Don't think we can use a
% wiggle plot, so it'll be colored scatter plot.

% Saves figures as .png files in Figure directory
FileFormat = 'png';
isAlaska=0;
isTexas=1;

load([ProjectDirectory ProjectFile],'FuncLabPreferences')

%% Check for backwards compability
if length(FuncLabPreferences) < 21
    FuncLabPreferences{19} = 'vel.cpt';
    FuncLabPreferences{20} = false;
    FuncLabPreferences{21} = '1.8.2';
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

% Load the RayInfo file - may take a long time, but hopefully faster than
% recomputing PRF to depth
load([ProjectDirectory ProjectFile], 'ThreeDRayInfoFile');
if ~exist(ThreeDRayInfoFile{1},'file')
    fprintf('Error, file %s not found!\n',ThreeDRayInfoFile{1});
    return
end

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
m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
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
if isAlaska == 1  
    hold on
    % Alaska province information from Colpron et al 2007
    % Digitized by Leland O'Driscoll
    yk = load([MapDataPath 'YAKoutlineFuis.txt']);
    %    vv = load([MapDataPath 'AKvolcs_lonlat.txt']);
    ff = load([MapDataPath 'faults_subset.txt']);
    %    eq = load([MapDataPath 'akeqs_wvf_ak4']);
    aaM = load([MapDataPath 'aaM.txt']); % arctic alaska
    axM = load([MapDataPath 'axM.txt']); % Alexandria
    in = inpolygon(axM(:,1), axM(:,2), [WestLon WestLon EastLon EastLon WestLon], [SouthLat NorthLat NorthLat SouthLat SouthLat]);
    axMT = axM(in==1,:);
    axM = axMT;
    chM = load([MapDataPath 'chM.txt']); % Chugach
    in = inpolygon(chM(:,1), chM(:,2), [WestLon WestLon EastLon EastLon WestLon], [SouthLat NorthLat NorthLat SouthLat SouthLat]);
    chMT = chM(in==1,:);
    chM = chMT;
    kyM = load([MapDataPath 'kyM.txt']); % Koyukuk
    peM = load([MapDataPath 'peM.txt']); % Peninsular
    rbocM = load([MapDataPath 'rbocM.txt']); % Ruby oceanic
    wrM = load([MapDataPath 'wrM.txt']); % Wrangellia
    ytM = load([MapDataPath 'ytM.txt']); % Yukon Tanana
    ytupM = load([MapDataPath 'ytupM.txt']); % Yukon Tanana Upland (older)
    m_line(yk(:,2),yk(:,1),'LineWidth',3,'Color','Red');
    m_plot(ff(:,1),ff(:,2),'MarkerFaceColor','Blue','Marker','.','MarkerSize',20,'LineStyle','none');
    % Colpron terranes:
    % aaM, axM, chM, kyM, peM, rbocM, wrM, ytM, ytupM
    m_patch(aaM(:,1),aaM(:,2),[133/255, 174/255, 187/255])
    m_patch(axM(:,1),axM(:,2),[133/255, 174/255, 187/255])
    m_patch(chM(:,1), chM(:,2), [234/255, 217/255, 146/255])
    m_patch(kyM(:,1), kyM(:,2), [234/255, 217/255, 146/255])
    m_patch(peM(:,1), peM(:,2), [133/255, 174/255, 187/255])
    m_patch(wrM(:,1), wrM(:,2), [133/255, 174/255, 187/255])
    m_patch(ytM(:,1), ytM(:,2), [124/255, 119/255, 168/255])
    m_patch(ytupM(:,1), ytupM(:,2), [211/255, 221/255, 230/255])
    m_patch(rbocM(:,1), rbocM(:,2), [133/255, 174/255, 187/255])
end

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
assignin('base','DoPlot','True');

% Need to get info about component and thickness
figpos = [screensize(3) / 2 - 200 screensize(4)/2 400 300];
tmpfig = figure('Name','Set cross section parameters','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.025 0.8 0.3 0.1],'String','Box width (degrees):','FontSize',12);
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.34 0.8 0.2 0.1],'String','1.0','FontSize',12,'Tag','width_control_edit_box','Callback',@setprofilewidth);
%Components = {'Radial RF', 'Transverse RF', 'Vertical','Radial','Transverse'};
Components = {'Radial RF', 'Transverse RF'};
uicontrol('Style','Popupmenu','Parent',tmpfig,'Units','Normalized','Position',[0.6 0.8 0.35 0.1],'String',Components,'Value',1,'FontSize',12,'Tag','component_popupmenu','Callback',@setprofiletype);

% Edit box and text to set the size of the points to be pplotted
DotSize = '5.0';
assignin('base','DotSize',5.0);
DepthMin = '0';
DepthMax = 'Default';
ColorMin = '-1';
ColorMax = '1';
assignin('base','DepthMin',0);
assignin('base','DepthMax',-1); % We'll use -1 as a flag to indicate when the maximum depth is set to default
assignin('base','ColorMin',-1);
assignin('base','ColorMax',1);
assignin('base','xbin',70.0);
assignin('base','ybin',3.0);
% Set dot size
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.025 0.6 0.3 0.1],'String','Point Size:','FontSize',12);
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.34 0.6 0.2 0.1],'String',DotSize,'FontSize',12,'Tag','dotsize_control_edit_box','Callback',@setprofiledotsize);
% Set text to separate min and max boxes
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.5 0.3 0.1],'String','Min:','FontSize',12);
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.55 0.5 0.3 0.1],'String','Max:','FontSize',12);
% Set min and max depth
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.025 0.4 0.3 0.1],'String','Depth Limits:','FontSize',12);
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.34 0.4 0.2 0.1],'String',DepthMin,'FontSize',12,'Tag','mindepth_control_edit_box','Callback',@setprofilemindepth);
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.6 0.4 0.2 0.1],'String',DepthMax,'FontSize',12,'Tag','maxdepth_control_edit_box','Callback',@setprofilemaxdepth);
% Set min and max colors
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.025 0.3 0.3 0.1],'String','Amplitude Limits:','FontSize',12);
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.34 0.3 0.2 0.1],'String',ColorMin,'FontSize',12,'Tag','mincolor_control_edit_box','Callback',@setprofilemincolor);
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.6 0.3 0.2 0.1],'String',ColorMax,'FontSize',12,'Tag','maxcolor_control_edit_box','Callback',@setprofilemaxcolor);
% Set x and y binning
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.025 0.2 0.3 0.1],'String','X bin size (km):','FontSize',12);
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.34 0.2 0.2 0.1],'String','70.0','FontSize',12,'Tag','xbin_control_edit_box','Callback',@setprofilexbin);
uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.6 0.2 0.2 0.1],'String','Y bin size (km):','FontSize',12);
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.8 0.2 0.15 0.1],'String','3.0','FontSize',12,'Tag','ybin_control_edit_box','Callback',@setprofileybin);

waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.6 0.1 0.35 0.1],'String','Confirm','FontSize',12,'Callback','gcbf.UserData=1; close');
uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.1 0.1 0.35 0.1],'String','Cancel','FontSize',12,'Callback','gcbf.UserData=0; close;assignin(''base'',''DoPlot'',''False'')');

waitfor(waitbutton,'Userdata');
DoPlot = evalin('base','DoPlot');
if strcmp(DoPlot,'False')
    disp('Canceled')
    return
end

%% Get the rays and reformat so they can be used with inpolygon
load(ThreeDRayInfoFile{1});
nrays = length(RayInfo);
% First is a check to count the number of active traces. We're going to use
% this to set memory allocation for speed
nRaysActive = 0;
for iray=1:nrays
    if RayInfo{iray}.isActive == 1
        nRaysActive = nRaysActive + 1;
    end
end
% Each ray should have the same number of points...
nRayPoints = length(RayInfo{1}.Latitude);
% Pre-allocate memory for ray data
RayLongitudes = zeros(1,nRayPoints * nRaysActive);
RayLatitudes = zeros(1,nRayPoints * nRaysActive);
RayDepths = zeros(1,nRayPoints * nRaysActive);
RayAmplitudesR = zeros(1,nRayPoints * nRaysActive);
RayAmplitudesT = zeros(1,nRayPoints * nRaysActive);
% Now we reloop through the rays and drop data to the above vectors
istart = 1;
iend = nRayPoints;
for iray=1:nrays
    if RayInfo{iray}.isActive == 1
        RayLongitudes(istart:iend) = RayInfo{iray}.Longitude;
        RayLatitudes(istart:iend) = RayInfo{iray}.Latitude;
        RayDepths(istart:iend) = 6371-RayInfo{iray}.Radius;
        RayAmplitudesR(istart:iend) = RayInfo{iray}.AmpR;
        RayAmplitudesT(istart:iend) = RayInfo{iray}.AmpT;
        istart = iend+1;
        iend = iend+nRayPoints;
    end
end

%% Extract RFs along profile
% Begin by defining a rectangle for the profile
ptright = [lonstart, latstart, 0];
ptleft = [lonend, latend, 0];
[FullProfileDistance, ~, ~] = distaz(ptright(2), ptright(1), ptleft(2), ptleft(1));
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

RecordsInPolygon = inpolygon(RecordMetadataDoubles(:,11), RecordMetadataDoubles(:,10),[seg1Lon, seg2Lon, seg3Lon, seg4Lon], [seg1Lat, seg2Lat, seg3Lat, seg4Lat]);
PointsInPolygon = inpolygon(RayLongitudes,RayLatitudes,[seg1Lon, seg2Lon, seg3Lon, seg4Lon], [seg1Lat, seg2Lat, seg3Lat, seg4Lat]);

ActiveRecordIndices = find(RecordsInPolygon == 1);
ActiveRecordDoubles = RecordMetadataDoubles(ActiveRecordIndices,:);
ActiveRecordStrings = RecordMetadataStrings(ActiveRecordIndices,:);

ActivePointIndices = find(PointsInPolygon == 1);

% Use these lines to determine the stations left in the profile and plot
% them with a different color on the map view
C=unique([ActiveRecordDoubles(:,11), ActiveRecordDoubles(:,10)],'rows');
m_line(C(:,1),C(:,2),'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[1 0 0])
drawnow

OutputFigureDir = [ProjectDirectory filesep 'FIGURES' filesep 'RF_Cross_Section_2D_CCP'];
mkdir(OutputFigureDir);
locationMapFname = sprintf('LocationMap.%3.3f_%3.3f_%3.3f_%3.3f.%s',lonstart, latstart, lonend, latend, FileFormat);
saveas(gcf,[OutputFigureDir filesep locationMapFname],FileFormat);


%% Now calculate the horizontal axis
%  This is distance (km) from the start location of the profile
%  We'll also need to project the station onto the profile
PointDistances = zeros(1,length(ActivePointIndices));
for ipt=1:length(ActivePointIndices)
    q=[RayLongitudes(ActivePointIndices(ipt)), RayLatitudes(ActivePointIndices(ipt)), 0];
    p=[ptright(1), ptright(2), 0];
    q_proj = q - dot(q-p, normal) * normal;
    [PointDistances(ipt), ~, ~] = distaz(p(2), p(1), q_proj(2), q_proj(1));
end

%% Need to normalize amplitudes before plotting?
ActiveLongitudes = RayLongitudes(ActivePointIndices);
ActiveLatitudes = RayLatitudes(ActivePointIndices);
ActiveDepths = RayDepths(ActivePointIndices);
%MaxDepth = max(ActiveDepths);
ActiveAmplitudesR = RayAmplitudesR(ActivePointIndices);
ActiveAmplitudesT = RayAmplitudesT(ActivePointIndices);

ActiveAmplitudesR = ActiveAmplitudesR / max(abs(ActiveAmplitudesR));
ActiveAmplitudesT = ActiveAmplitudesT / max(abs(ActiveAmplitudesT));

%% Do CCP Stacking
% PointDistances, ActiveDepths,ActiveAmplitudes{R/T}
DepthMin = evalin('base','DepthMin');
DepthMax = evalin('base','DepthMax');
if DepthMax < 0
    DepthMax = max(ActiveDepths);
end
xbin = evalin('base','xbin');
ybin = evalin('base','ybin');
xvector = 0:xbin:FullProfileDistance;
yvector = DepthMin:ybin:DepthMax;
[xmesh, ymesh] = meshgrid(xvector, yvector);
CCPMatrix = zeros(length(xvector), length(yvector));
CCPHits = zeros(length(xvector), length(yvector));
for ipt=1:length(PointDistances)
    idx = floor((PointDistances(ipt) - 0) / xbin+1.5);
    idy = floor((ActiveDepths(ipt) - DepthMin) / ybin+1.5);
    if idx < 1
        idx = 1;
    elseif idx > length(xvector)
        idx = length(xvector);
    end
    if idy < 1
        idy = 1;
    elseif idy > length(yvector)
        idy = length(yvector);
    end
    if strcmp(evalin('base','ProfileType'),'Radial RF')
        CCPMatrix(idx, idy) = CCPMatrix(idx, idy) + ActiveAmplitudesR(ipt);
    else
        CCPMatrix(idx, idy) = CCPMatrix(idx, idy) + ActiveAmplitudesT(ipt);
    end
    CCPHits(idx,idy) = CCPHits(idx,idy) + 1;
end

% Normalize by hit count
for idx=1:length(xvector)
    for idy=1:length(yvector)
        if CCPHits(idx, idy) > 0
            CCPMatrix(idx, idy) = CCPMatrix(idx,idy) / CCPHits(idx,idy);
        else
            CCPMatrix(idx, idy) = 0;
        end
    end
end

% Normalize by max in vertical column
for idx=1:length(xvector)
    nn = max(abs(CCPMatrix(idx,:)));
    if (nn > 0)
        for idy=1:length(yvector)
            CCPMatrix(idx, idy) = CCPMatrix(idx,idy) / nn;
        end
    end
end

%% Here we do the actual plot
ProfileFigureHandles = figure('Units','characters','NumberTitle','off','Name','X-section','Units','characters',...
    'Position',[0 0 165 55],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});
ax=axes('Parent',ProfileFigureHandles);
%dotsize = evalin('base','DotSize');
ColorMin = evalin('base','ColorMin');
ColorMax = evalin('base','ColorMax');
pcolor(ax,xmesh, ymesh, CCPMatrix');
shading interp
if strcmp(evalin('base','ProfileType'),'Radial RF')
    %scatter(ax,PointDistances, ActiveDepths,dotsize,ActiveAmplitudesR,'filled')
    title(ax,'Radial RF Cross Section')
elseif strcmp(evalin('base','ProfileType'),'Transverse RF')
    %scatter(ax,PointDistances, ActiveDepths,dotsize,ActiveAmplitudesT,'filled')
    title(ax,'Transverse RF Cross Section')
end
xlim(ax,[0 FullProfileDistance])
ylim(ax,[DepthMin DepthMax])
set(ax,'YDir','Reverse')
grid(ax,'on')
grid(ax,'minor')
box(ax,'on')
ylabel(ax,'Depth (km)')
xlabel(ax,'Distance (km)')
colormap(cmap);
c=colorbar('peer',ax);
xlabel(c,'RF Amplitude');
caxis(ax,[ColorMin ColorMax])
hold on
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


plotHitCount = 0;
if plotHitCount == 1
    % Here we plot the hit count as a debug
    HitCountFigureHandles = figure('Units','characters','NumberTitle','off','Name','X-section hit count','Units','characters',...
        'Position',[0 0 165 55],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});
    ax=axes('Parent',HitCountFigureHandles);
    %dotsize = evalin('base','DotSize');
    %ColorMin = evalin('base','ColorMin');
    %ColorMax = evalin('base','ColorMax');
    ColorMin = 0;
    ColorMax = 100;
    pcolor(ax,xmesh, ymesh, CCPHits');
    shading interp
    title(ax,'Hit Count')
    xlim(ax,[0 FullProfileDistance])
    ylim(ax,[DepthMin DepthMax])
    set(ax,'YDir','Reverse')
    grid(ax,'on')
    grid(ax,'minor')
    box(ax,'on')
    ylabel(ax,'Depth (km)')
    xlabel(ax,'Distance (km)')
    colormap(cmap);
    c=colorbar('peer',ax);
    xlabel(c,'RF Hit Count');
    caxis(ax,[ColorMin ColorMax])
    hold on
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

    profileFname = sprintf('RFProfileHitCount.%3.3f_%3.3f_%3.3f_%3.3f.%s',lonstart, latstart, lonend, latend, FileFormat);
    saveas(ProfileFigureHandles,[OutputFigureDir filesep profileFname],FileFormat);

end

end

function setprofilexbin(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','xbin',val);
end

function setprofileybin(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','ybin',val);
end


function setprofilemindepth(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','DepthMin',val);
end

function setprofilemaxdepth(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','DepthMax',val);
end

function setprofilemincolor(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','ColorMin',val);
end

function setprofilemaxcolor(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','ColorMax',val);
end


function setprofiledotsize(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','DotSize',val);
end

function setprofilewidth(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','ProfileWidth',val);
end

function setprofiletype(source, callbackdata)
    val=source.Value;
    opts = source.String;
    assignin('base','ProfileType',opts{val});
end




