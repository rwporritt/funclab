function visualizer(MainGui)
% funclab add-on visualizer.m
% Designed to allow one, two, and three dimensional visualizations of
% receiver functions and bundled datasets
%
%  To add: Cross-section ray diagrams.
%    Give start and end points
%    Give off-axis width
%    Plots the rays geographical
%      But requires the rays defined in space rather than time...
%
%  Coding style note:
%    This add-on uses a global structure to pass information between
%    subroutines whereas most funclab functions use the project file and
%    evalin to evaluate variables from the matlab base workspace. In order
%    to clear this global structure, you will need to exit matlab or use
%    the global clear command:
%    >> clear GLOBAL VisualizerStructure
%
%   Author: Robert W. Porritt
%   Date Created: 04/05/2015
%   Last Updated: 10/31/2016

ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
load([ProjectDirectory,filesep,ProjectFile])
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% GUI initiation
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

load FL_coasts
load FL_plates
load FL_stateBoundaries

% A global variable for passing visualizer info
global VisualizerStructure
VisualizerStructure.ModelSelected = 0; % Need to choose a model before any plots will work
VisualizerStructure.ncst = ncst;
VisualizerStructure.PBlong = PBlong;
VisualizerStructure.PBlat = PBlat;
VisualizerStructure.HasCCPFlag = 0;
VisualizerStructure.HasGCCPFlag = 0;
VisualizerStructure.HasCCPV2Flag = 0;
VisualizerStructure.HasHk = 0;
VisualizerStructure.stateBoundaries = stateBoundaries;
VisualizerStructure.ProjectDirectory = ProjectDirectory;
VisualizerStructure.ProjectFile = ProjectFile;
if exist('CCPMetadataCell','var')
    VisualizerStructure.CCPMetadataStrings = CCPMetadataCell{CurrentSubsetIndex,1};
    VisualizerStructure.CCPMetadataDoubles = CCPMetadataCell{CurrentSubsetIndex,2};
    VisualizerStructure.HasCCPFlag = 1;
end
if exist('GCCPMetadataCell','var')
    VisualizerStructure.GCCPMetadataStrings = GCCPMetadataCell{CurrentSubsetIndex,1};
    VisualizerStructure.GCCPMetadataDoubles = GCCPMetadataCell{CurrentSubsetIndex,2};
    VisualizerStructure.HasGCCPFlag = 1;
end
if exist('RecordMetadataStrings','var')
    VisualizerStructure.RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
    VisualizerStructure.RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
end
if exist('HkMetadataCell','var')
    VisualizerStructure.HkMetadataStrings = HkMetadataCell{CurrentSubsetIndex,1};
    VisualizerStructure.HkMetadataDoubles = HkMetadataCell{CurrentSubsetIndex,2};
    VisualizerStructure.HasHk = 1;
end
if exist('CCPV2MetadataCell','var')
    %VisualizerStructure.CCPV2File = CCPV2MetadataCell{CurrentSubsetIndex,2};
    CCPV2MetadataStrings = CCPV2MetadataCell{CurrentSubsetIndex};
    VisualizerStructure.CCPV2File = CCPV2MetadataStrings{2};
    VisualizerStructure.HasCCPV2Flag = 1;
end
VisualizerStructure.Colormap = FuncLabPreferences{19};
VisualizerStructure.ColormapFlipped = FuncLabPreferences{20};

TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];


%--------------------------------------------------------------------------
% Setup dimensions of the GUI
%--------------------------------------------------------------------------
MainPos = [0 0 130 37];

%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
VisualizerGui = dialog('Name','Visualizer','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');


% Set map projection
%--------------------------------------------------------------------------
if license('test', 'MAP_Toolbox')
    MapProjection = 'Mercator'; % should deal with switching between whether or not the mapping toolbox is available.
    % RWP is writing this assuming only m_map is available
else
    MapProjection = FuncLabPreferences{10};
end
ProjectionListNames = {'Stereographic','Orthographic','Azimuthal Equal-area','Azimuthal Equidistant','Gnomonic',...
        'Satellite','Albers Equal-Area Conic','Lambert Conformal Conic','Mercator','Miller Cylindrical','Equidistant Cylindrical',...
        'Transverse Mercator','Sinusoidal','Gall-Peters','Hammer-Aitoff','Mollweide','Robinson','UTM'};
ProjectionListIDs = ProjectionListNames;
MapProjectionIDX = strmatch(MapProjection,ProjectionListNames,'exact');
MapProjectionID = ProjectionListIDs{MapProjectionIDX};
VisualizerStructure.MapProjectionID = MapProjectionID;

% Create a map view axis
MapViewPanel = uipanel('Title','Global map view','FontSize',12,'BackgroundColor','White','Units','Normalized','Position',[0.01 0.1 0.79 0.85]);
MapViewAxesHandles = axes('Parent',MapViewPanel,'Units','Normalized','Position',[.05 .05 .9 .9]);

m_proj('Hammer-Aitoff','latitude',[-90 90],'longitude',[-180 180]);

% Makes the initial plot view - global coast lines and a shaded box for the
% CCP image volume
%plot(ncst(:,1),ncst(:,2),'k')
hold on
%m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
m_coast('patch',[.9 .9 .9],'edgecolor','black');
m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
%axis([-180 180 -90 90])
m_grid('xtick',30,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');


% Create a popup menu for data set to plot
% - Options: 
%   1D velocity models (automatically plots them in a new pop out axis)
%   3D Tomography models
%   CCP model
%   GCCP model
VelocityModelPath = regexprep(which('funclab'),'funclab.m','VELMODELS/');
VelModelList = dir([VelocityModelPath '*.vel']);
VelModelList = sortrows({VelModelList.name}');
CCPModels = {'CCP', 'GCCP','CCPV2'};
AvailableModels = CCPModels;
for idx=1:length(VelModelList)
    AvailableModels{idx+length(CCPModels)} = VelModelList{idx};
end
VisualizerStructure.VelModels = VelModelList;
TomoModelPath = regexprep(which('funclab'),'funclab.m','TOMOMODELS/');
TomoModelList = dir([TomoModelPath '*.mat']);
TomoModelList = sortrows({TomoModelList.name}');
jdx = length(CCPModels) + length(VelModelList);
for idx=1:length(TomoModelList)
    jdx = jdx + 1;
    %AvailableModels{idx+2+length(VelModelList)} = TomoModelList{idx};
    AvailableModels{jdx} = sprintf('%s-P',TomoModelList{idx});
    jdx = jdx + 1;
    AvailableModels{jdx} = sprintf('%s-S',TomoModelList{idx});
end
VisualizerStructure.TomoModels = TomoModelList;
VisualizerStructure.AvailableModels = AvailableModels;

uicontrol('Style','Text','Parent',VisualizerGui,'Units','Normalized','Position',[0.8 0.75 0.1 0.15],'String','Select Model:','BackgroundColor','white')
uicontrol('Style','popupmenu','Parent',VisualizerGui,'Units','Normalized','Position',[0.9 0.75 0.1 0.15],'String',AvailableModels,'Value',1,'Callback',{@update_data_set});

% Create a button for a 1D plot
%   Goes to ginput and allows user to click and makes a plot of
%   VisualizerStructure.Amplitude at the clicked location versus depth
uicontrol('Style','Pushbutton','Parent',VisualizerGui,'Units','Normalized','Position',[0.82 0.76 0.16 0.07],'String','New 1D Depth Profile','Enable','off','Tag','OneDPlotButton','Callback',{@plot_new_1d_model});


% Maps, cross sections, and fence diagrams need options to swap the color palette, set min/max amplitudes from the plot, and a cross-sections need a switcher between x-axis as distance, latitude, or longitude and then a button to re-draw the the image.
% Create a button for a constant depth map
%  Opens a new dialog box where the user inputs the depth
%  Program then interpolates to get the estimate at the user depth
uicontrol('Style','Pushbutton','Parent',VisualizerGui,'Units','Normalized','Position',[0.82 0.68 0.16 0.07],'String','New Depth map','Enable','off','Tag','NewMapViewPlotButton','Callback',{@launch_map_view_gui});

% Create a button for a point to point cross section
%   Goes to ginput to select two points
uicontrol('Style','Pushbutton','Parent',VisualizerGui,'Units','Normalized','Position',[0.82 0.60 0.16 0.07],'String','New Cross-Section','Enable','off','Tag','NewCrossSectionViewPlotButton','Callback',{@make_new_cross_section,MapViewAxesHandles});


% Create a button for a fence diagram
%   Goes to ginput to select N points
uicontrol('Style','Pushbutton','Parent',VisualizerGui,'Units','Normalized','Position',[0.82 0.52 0.16 0.07],'String','New Fence Diagram','Enable','off','Tag','NewFenceDiagramViewPlotButton','Callback',{@make_new_fence_diagram,MapViewAxesHandles});


% Create a button for 3D ray diagram?

% Create a button for 3D isovolume?

% uicontrols to make map view plots of hk results
crustalThicknessPlotButton = uicontrol('Style','Pushbutton','Parent',VisualizerGui,'Units','Normalized','Position',[0.82 0.44 0.16 0.07],'String','H-k H map','Enable','off','Tag','crustalThicknessPlot_pb','Callback',{@plot_hk_results,1});
crustalThicknessErrorPlotButton = uicontrol('Style','Pushbutton','Parent',VisualizerGui,'Units','Normalized','Position',[0.82 0.36 0.16 0.07],'String','H-k H error map','Enable','off','Tag','crustalThicknessErrorPlot_pb','Callback',{@plot_hk_results,2});
VpVsPlotButton = uicontrol('Style','Pushbutton','Parent',VisualizerGui,'Units','Normalized','Position',[0.82 0.28 0.16 0.07],'String','H-k VpVs map','Enable','off','Tag','VpVsPlot_pb','Callback',{@plot_hk_results,3});
VpVsErrorPlotButton = uicontrol('Style','Pushbutton','Parent',VisualizerGui,'Units','Normalized','Position',[0.82 0.2 0.16 0.07],'String','H-k VpVs error map','Enable','off','Tag','VpVsErrorPlot_pb','Callback',{@plot_hk_results,4});
if VisualizerStructure.HasHk == 1
    set(crustalThicknessPlotButton,'Enable','on');
    set(crustalThicknessErrorPlotButton,'Enable','on');
    set(VpVsPlotButton,'Enable','on');
    set(VpVsErrorPlotButton,'Enable','on');
end



% Redraw the map view - ie remove all the elements that have been plotted
% on top
uicontrol('Style','Pushbutton','Parent',VisualizerGui,'Units','Normalized','Position',[0.82 0.1 0.16 0.07],'String','Clean map','Callback',{@clean_up_map_view,MapViewAxesHandles})


end









%% Callbacks
function plot_hk_results(src, evt, flag)
    global VisualizerStructure
    
    % Get the tables from the main structure
    RecordMetadataStrings = VisualizerStructure.RecordMetadataStrings;
    RecordMetadataDoubles = VisualizerStructure.RecordMetadataDoubles;
    HkMetadataStrings = VisualizerStructure.HkMetadataStrings;
    HkMetadataDoubles = VisualizerStructure.HkMetadataDoubles;
    ProjectDirectory = VisualizerStructure.ProjectDirectory;
    
    % Get space for data
    longitudes = zeros(size(HkMetadataStrings,1),1);
    latitudes = zeros(size(HkMetadataStrings,1),1);
    zvalues = zeros(size(HkMetadataStrings,1),1);
    
    % Get the data
    for n = 1:size(HkMetadataStrings,1)
        % Load H-k Table from the Project Directory
        %----------------------------------------------------------------------
        load([ProjectDirectory,filesep,HkMetadataStrings{n,1}])
        Indices = strmatch(HkMetadataStrings{n,2},RecordMetadataStrings(:,2));
        Index = Indices(1);
        longitudes(n) = RecordMetadataDoubles(Index,11);
        latitudes(n) = RecordMetadataDoubles(Index,10);
        if flag == 1
            zvalues(n) = HkMetadataDoubles(n,15);
        elseif flag == 2
            zvalues(n) = HkMetadataDoubles(n,16);
        elseif flag == 3
            zvalues(n) = HkMetadataDoubles(n,17);
        elseif flag == 4
            zvalues(n) = HkMetadataDoubles(n,18);
        end
    end
       
    % Make the plot
    figure();
    if VisualizerStructure.ColormapFlipped == false
        cmap = cptcmap(VisualizerStructure.Colormap);
    else
        cmap = cptcmap(VisualizerStructure.Colormap,'flip',true);
    end
    colormap(cmap);
    
    minlat = min(latitudes);
    maxlat = max(latitudes);
    minlon = min(longitudes);
    maxlon = max(longitudes);
    
    MapProjectionID = VisualizerStructure.MapProjectionID;
    if strcmp(MapProjectionID,'Stereographic') || strcmp(MapProjectionID,'Orthographic') || strcmp(MapProjectionID,'Azimuthal Equal-area') || ...
        strcmp(MapProjectionID,'Azimuthal Equidistant') || strcmp(MapProjectionID,'Gnomonic') || strcmp(MapProjectionID,'Satellite')    
        [~, ~, xdeg] = distaz(minlat, minlon, maxlat, maxlon);
        m_proj(MapProjectionID,'latitude',(minlat + maxlat)/2, 'longitude',(minlon + maxlon) / 2,'radius',xdeg/2);
    else
        m_proj(MapProjectionID,'latitude',[minlat maxlat],'longitude',[minlon maxlon]);
    end
    PBlong = VisualizerStructure.PBlong;
    PBlat = VisualizerStructure.PBlat;
    stateBoundaries = VisualizerStructure.stateBoundaries;
    % Makes the initial plot view - global coast lines and a shaded box for the
    hold on
    %m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
    m_coast('patch',[.9 .9 .9],'edgecolor','black');
    m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
    m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
    [x,y] = m_ll2xy(longitudes, latitudes);
    scatter(x,y,100,zvalues,'filled')
    m_grid('box','on')
    colorbar
    

end

function clean_up_map_view(src, evt, MapViewAxesHandles)
    global VisualizerStructure
    cla(MapViewAxesHandles)
    Lats = VisualizerStructure.Lats;
    Lons = VisualizerStructure.Lons;
    MinimumLatitude = min(min(min(Lats)));
    MaximumLatitude = max(max(max(Lats)));
    MinimumLongitude = min(min(min(Lons)));
    MaximumLongitude = max(max(max(Lons)));
    minlat = MinimumLatitude;
    maxlat = MaximumLatitude;
    minlon = MinimumLongitude;
    maxlon = MaximumLongitude;
    
    MapProjectionID = VisualizerStructure.MapProjectionID;
    if strcmp(MapProjectionID,'Stereographic') || strcmp(MapProjectionID,'Orthographic') || strcmp(MapProjectionID,'Azimuthal Equal-area') || ...
        strcmp(MapProjectionID,'Azimuthal Equidistant') || strcmp(MapProjectionID,'Gnomonic') || strcmp(MapProjectionID,'Satellite')    
        [~, ~, xdeg] = distaz(minlat, minlon, maxlat, maxlon);
        m_proj(MapProjectionID,'latitude',(minlat + maxlat)/2, 'longitude',(minlon + maxlon) / 2,'radius',xdeg/2);
    else
        m_proj(MapProjectionID,'latitude',[minlat maxlat],'longitude',[minlon maxlon]);
    end

    %m_proj(VisualizerStructure.MapProjectionID,'latitude',[MinimumLatitude-1 MaximumLatitude+1],'longitude',[MinimumLongitude-1 MaximumLongitude+1]);
    hold on
    m_coast('patch',[.9 .9 .9],'edgecolor','black');
    %plot(VisualizerStructure.ncst(:,1),VisualizerStructure.ncst(:,2),'k')
    m_line(VisualizerStructure.PBlong, VisualizerStructure.PBlat,'Color',[0.2 0.2 0.8])
    %plot(VisualizerStructure.PBlong, VisualizerStructure.PBlat, 'b')
    m_line(VisualizerStructure.stateBoundaries.longitude, VisualizerStructure.stateBoundaries.latitude,'Color',[0 0 0])
    %plot(VisualizerStructure.stateBoundaries.longitude, VisualizerStructure.stateBoundaries.latitude,'k--')
    boxlon = [MinimumLongitude * ones(1,100) linspace(MinimumLongitude, MaximumLongitude,100) MaximumLongitude * ones(1,100) linspace(MaximumLongitude, MinimumLongitude,100)];
    boxlat = [linspace(MinimumLatitude, MaximumLatitude, 100) MaximumLatitude * ones(1,100) linspace(MaximumLatitude, MinimumLatitude, 100) MinimumLatitude * ones(1,100)];
    m_patch(boxlon,...
        boxlat,...
        [153/255 0 0])
    %m_patch([MinimumLongitude MinimumLongitude MaximumLongitude MaximumLongitude MinimumLongitude],...
    %    [MinimumLatitude MaximumLatitude MaximumLatitude MinimumLatitude MinimumLatitude],...
    %    [153/255 0 0])
    %axis([MinimumLongitude-1 MaximumLongitude+1 MinimumLatitude-1 MaximumLatitude+1])
    alpha(0.5)
    m_grid('box','on')
end


function make_new_fence_diagram(src, evt,MapViewAxesHandles)
    global VisualizerStructure
   
    
    % Relatively simple user controls, but more complicated backend
    % User needs to determine:
    %   Click for start and end
    %   Edit box for number of points to find between start and end
    %   Smoothing applied before the section is made.
    % We actually have enough room to put these controls in the main
    % visualizer gui. This will make both this cross section plot and the
    % fence diagram plot simpler.
    
    
    % Start with message to user asking them to click on two points
    screensize = get(0,'screensize');
    figpos = [screensize(3) / 2 - 200 screensize(4) / 2 - 50 400 100];
    tmpfig = figure('Name','Click 2 or more points for fence diagram','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
    uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.5 0.6 0.4],'String','Please click 2 or more points on the map view. Hit enter when done.','FontSize',12);
    waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.4],'String','Click','FontSize',12,'Callback','gcbf.UserData=1; close');
    waitfor(waitbutton,'Userdata');
    [lons, lats] = ginput();
    
    % End function if only one or 0 inputs
    if length(lons) < 2
        tmpfig = figure('Name','Fence Diagram Error','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
        uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.5 0.6 0.4],'String','Error, please choose at least 2 points.','FontSize',12);
        waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.4],'String','I screwed up.','FontSize',12,'Callback','gcbf.UserData=1; close');
        waitfor(waitbutton,'Userdata');
        return;
    end
    
    hold on
    plot(MapViewAxesHandles,lons,lats,'Color','Black')
    
    % determine the colors for the dots - black to bright red. 
    cols = zeros(length(lons),3);
    cc = linspace(0,1,length(lons));
    cols(:,1) = cc;
    
    % And colored dots for reference
    for i=1:length(lons)
        scatter(MapViewAxesHandles, lons(i), lats(i), 100, 'filled','MarkerFaceColor',[cols(i,1) cols(i,2) cols(i,3)], 'MarkerEdgeColor','k')
    end
    
    [x,y] = m_xy2ll(lons, lats);
    lons = x;
    lats = y;
    
        % Pop up a temporary figure with a bunch of edit boxes, a cancel
    % button, and a confirm button
    % nsmoothx
    % nsmoothy
    % nsmoothz
    % npts along section
    % min depth
    % max depth
    % depth sampling
%uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latmax_t','String','Latitude Max. (deg)',...
%    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
%uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','latmax_e','String',NorthLat,...
%    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
%    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.latmax = v; set(gcf,''UserData'',vec);');


    % Positions from calling figure
    MainPos = [0 0 140 18];
    ParamTitlePos = [2 MainPos(4)-3 80 2];
    ParamTextPos1 = [1 0 34 1.75];
    ParamOptionPos1 = [37 0 7 1.75];
    ParamTextPos2 = [47 0 34 1.75];
    ParamOptionPos2 = [84 0 7 1.75];
    ParamTextPos3 = [94 0 34 1.75];
    ParamOptionPos3 = [131 0 7 1.75];
    ProcTitlePos = [80 MainPos(4)-2 50 1.25];
    ProcButtonPos = [100 2 35 3];
    CloseButtonPos = [90 3 30 3];

    % Setting font sizes
    TextFontSize = 0.6; % ORIGINAL
    EditFontSize = 0.5;
    AccentColor = [.6 0 0];
    GeometryFigure = figure('Name','Enter fence diagram parameters','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'DockControls','off','MenuBar','none','NumberTitle','off','Color','White');

    %text and edit boxes
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','title_t','String','Set fence parameters',...
        'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.85,'HorizontalAlignment','left','BackgroundColor','White');
    ParamTextPos1(2) = 12;
    ParamOptionPos1(2) = 12;
    ParamTextPos2(2) = 12;
    ParamOptionPos2(2) = 12;
    ParamTextPos3(2) = 12;
    ParamOptionPos3(2) = 12;

    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','smoothing_lon_t','String','Smoothing in longitude (nodes):',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','nsmoothx_edit','String','1',...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','smoothing_lat_t','String','Smoothing in latitude (nodes):',...
        'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','nsmoothy_edit','String','1',...
        'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','smoothing_depth_t','String','Smoothing in depth (nodes):',...
        'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','nsmoothz_edit','String','1',...
        'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
     ParamTextPos1(2) = 9;
     ParamOptionPos1(2) = 9;
     ParamTextPos2(2) = 9;
     ParamOptionPos2(2) = 9;
     ParamTextPos3(2) = 9;
     ParamOptionPos3(2) = 9;

    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','npts_along_section_t','String','NPTS in section:',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','npts_section_edit','String','40',...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
    ParamOptionPos2(3) = 18;
    ParamOptionPos2(1) = 74;
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','linear_or_gc_t','String','Linear or Great Circle:',...
        'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','popupmenu','Units','characters','Tag','projection_method_popup','String',{'Linear','Great Circle'},...
        'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    ParamOptionPos2(1) = 84;
    
    % Switch between 2D plot and 3D plot
    ParamOptionPos3(3) = 18;
    ParamOptionPos3(2) = 9;
    ParamOptionPos3(1) = 121;
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','twod_or_threed_text','String','2D or 3D:',...
        'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','popupmenu','Units','characters','Tag','twod_or_threed_popup','String',{'2D','3D'},...
        'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    ParamOptionPos3(1) = 131;
    ParamOptionPos3(3) = 7;
    
     ParamTextPos1(2) = 6;
     ParamOptionPos1(2) = 6;
     ParamTextPos2(2) = 6;
     ParamOptionPos2(2) = 6;
     ParamOptionPos2(3) = 7;
     ParamTextPos3(2) = 6;
     ParamOptionPos3(2) = 6;

     % Find the depth limits from the data set
     min_depth_s = sprintf('%3.0f',min(min(min(VisualizerStructure.Depths))));
     max_depth_s = sprintf('%3.0f',max(max(max(VisualizerStructure.Depths))));
     inc_depth_s = sprintf('%3.0f',VisualizerStructure.Depths(1,1,2) - VisualizerStructure.Depths(1,1,1));

     uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','min_depth_t','String','Minimum depth (km):',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
     uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','minimum_depth_edit','String',min_depth_s,...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
     uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','max_depth_t','String','Maximum depth (km):',...
        'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
     uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','maximum_depth_edit','String',max_depth_s,...
        'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
     uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','inc_depth_t','String','Increment in depth (km):',...
        'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
     uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','increment_depth_edit','String',inc_depth_s,...
        'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');    

    % Add buttons for "plot" and "Cancel"
    uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','create_fence_pb','String','Make diagram',...
        'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
        'Callback',{@plot_fence_diagram_view,GeometryFigure, lons, lats});

    ProcButtonPos(1) = 60;
    uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','cancel_fence_pb','String','Cancel',...
        'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
        'Callback',{@cancel_new_view,GeometryFigure});

end

function plot_fence_diagram_view(src, evt,callinghdls, lon, lat)
    global VisualizerStructure
  
    TmpWaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',TmpWaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait while making the fence diagram...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    
    % Get values from the edit boxes
    hdls = findobj('Tag','nsmoothx_edit');
    nsmoothx = sscanf(hdls.String,'%d');
    
    hdls = findobj('Tag','nsmoothy_edit');
    nsmoothy = sscanf(hdls.String,'%d');
    
    hdls = findobj('Tag','nsmoothz_edit');
    nsmoothz = sscanf(hdls.String,'%d');
    
    hdls = findobj('Tag','npts_section_edit');
    nptsAlongSection = sscanf(hdls.String,'%d');
    
    hdls = findobj('Tag','minimum_depth_edit');
    mindepth = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','maximum_depth_edit');
    maxdepth = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','increment_depth_edit');
    incdepth = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','projection_method_popup');
    extractMethodFlag = hdls.Value; % 1 = linear, 2 = great circle

    hdls = findobj('Tag','twod_or_threed_popup');
    twodOrThreeDFlag = hdls.Value; % 1 = 2D, 2 = 3D
    
    % close the calling handles
    close(callinghdls);
    
    % Prepare the data set
    SmoothMatrix = smooth_nxmxk_matrix(VisualizerStructure.Amplitude,nsmoothx, nsmoothy, nsmoothz);
    
    % Get the depth vector
    zvector = mindepth:incdepth:maxdepth;
    
    % Running the extraction code
    nsegments  = length(lon)-1;
    stepDistances = zeros(1,nsegments+1);
    EARTH_RADIUS = 6371;

    % Get memory for the cross section array which is nptsAlongSection x nDepths
    CrossSectionData = zeros(nptsAlongSection*nsegments, length(zvector));
    CrossSectionDistance = zeros(nptsAlongSection*nsegments,1);
    CrossSectionLatitudes = zeros(nptsAlongSection*nsegments,1);
    CrossSectionLongitudes = zeros(nptsAlongSection*nsegments,1);
    
     % Rearrange to make it look like a proper mesh grid
    if strcmp(VisualizerStructure.AmplitudeType,'VelocityPerturbation')
        TmpAmplitude = permute(SmoothMatrix,[2,1,3]);
        TmpLon = permute(VisualizerStructure.Lons,[2,1,3]);
        TmpLat = permute(VisualizerStructure.Lats,[2,1,3]);
        TmpDep = permute(VisualizerStructure.Depths,[2,1,3]);
    else
        TmpAmplitude = permute(SmoothMatrix,[1,2,3]);
        TmpLon = permute(VisualizerStructure.Lons,[1,2,3]);
        TmpLat = permute(VisualizerStructure.Lats,[1,2,3]);
        TmpDep = permute(VisualizerStructure.Depths,[1,2,3]);
    end

    % Main loop through all segments and points
    accumulatedDistance = 0;
    for isegment=1:nsegments
        startLat = lat(isegment);
        startLong = lon(isegment);
        endLat = lat(isegment+1);
        endLong = lon(isegment+1);
        
        % The first and last points in a cartesian system (but used in the
        % great circle extraction option!)
        xOrig = EARTH_RADIUS * cosd(startLat) * cosd(startLong);
        yOrig = EARTH_RADIUS * cosd(startLat) * sind(startLong);
        zOrig = EARTH_RADIUS * sind(startLat);

        xTarget = EARTH_RADIUS * cosd(endLat) * cosd(endLong);
        yTarget = EARTH_RADIUS * cosd(endLat) * sind(endLong);
        zTarget = EARTH_RADIUS * sind(endLat);

        % Initial point in the calculation
        if isegment == 1
            prevLat = startLat;
            prevLong = startLong;
        end
        
        % for cartesian extraction method
        tmpLats2 = linspace(startLat, endLat, nptsAlongSection);
        tmpLons2 = linspace(startLong, endLong, nptsAlongSection);

        % Get all the points along this leg of the fence
        for imeasurement=1:nptsAlongSection
            
            % Where is this measurement in the grand scheme of things
            jmeasurement = (isegment-1) * nptsAlongSection + imeasurement;
        
            % finds the cartesian coordinates of current step
            xStep = xOrig + (imeasurement-1) * (xTarget - xOrig) / (nptsAlongSection-1);
            yStep = yOrig + (imeasurement-1) * (yTarget - yOrig) / (nptsAlongSection-1);
            zStep = zOrig + (imeasurement-1) * (zTarget - zOrig) / (nptsAlongSection-1);

            % returns to latitude and longitude
            tmpLong = 180.0 / pi * atan2(yStep,xStep);
            tmpLat = 90 - 180.0 / pi * acos(zStep / sqrt(xStep*xStep + yStep * yStep + zStep * zStep)); 

            % adjustments for the start of the profile
            if imeasurement == 1
                tmpLong = lon(isegment);
                tmpLat = lat(isegment);
            end

            % Adjust at the end of the profile
            if imeasurement == nptsAlongSection
                tmpLong = lon(isegment+1);
                tmpLat = lat(isegment+1);
            end

            % Use the linear interpolation instead for the location
            if extractMethodFlag == 1
                tmpLat = tmpLats2(imeasurement);
                tmpLong = tmpLons2(imeasurement);
            end

            CrossSectionLatitudes(jmeasurement) = tmpLat;
            CrossSectionLongitudes(jmeasurement) = tmpLong;

            % Compute how far along we've gone on the profile relative to the last
            % point
            [tmpdist, ~, ~] = distaz(prevLat, prevLong, tmpLat, tmpLong);
            accumulatedDistance = accumulatedDistance + tmpdist;
            
            % record the current point for the next step in the loop
            prevLat = tmpLat;
            prevLong = tmpLong;
            
            % here is where we get the data from the model as a function of
            % depth
            CrossSectionData(jmeasurement,:) = interp3(TmpLon, TmpLat, TmpDep, TmpAmplitude,tmpLong, tmpLat, zvector,'linear');
            CrossSectionDistance(jmeasurement) = accumulatedDistance;

        end
        stepDistances(isegment+1) = accumulatedDistance;
    end
    
    % Close the wait gui as we are ready to plot
    close(TmpWaitGui)
    
    % Store the matrices/vectors we want to keep if we update the plot
    VisualizerStructure.CrossSectionData = CrossSectionData;
    VisualizerStructure.CrossSectionDistance = CrossSectionDistance;
    VisualizerStructure.CrossSectionLatitudes = CrossSectionLatitudes;
    VisualizerStructure.CrossSectionLongitudes = CrossSectionLongitudes;
    VisualizerStructure.fenceLon = lon;
    VisualizerStructure.fenceLat = lat;
    VisualizerStructure.fenceSteps = stepDistances;
    VisualizerStructure.zvector = zvector;
    
    % make the plot
    if twodOrThreeDFlag == 1
        % Get the x and y arrays for the plot
        xx = repmat(CrossSectionDistance,1,size(zvector,2));
        yy = repmat(zvector,size(CrossSectionDistance,1),1);
        % Gets a new figure
        xsectionFigureHandles = figure('Name','Fence Diagram','Units','Normalized','Position',[0.1 0.5 0.8 0.4],'Color','white');
        axesHandles = axes('Position',[0.05 0.1 0.85 0.8]);
        pcolor(axesHandles, xx,yy, CrossSectionData)
        % Add a line of markers to the top to match the view on the map
        % determine the colors for the dots - black to bright red. 
        hold on
        cols = zeros(length(lon),3);
        cc = linspace(0,1,length(lon));
        cols(:,1) = cc;

        % And colored dots for reference
        for i=1:length(lon)
            scatter(stepDistances(i), 0, 100, 'filled','MarkerFaceColor',[cols(i,1) cols(i,2) cols(i,3)], 'MarkerEdgeColor','k')
            plot([stepDistances(i) stepDistances(i)], [0, zvector(end)],'k')
        end

        % Pretty up a little
        shading interp
        set(gca,'ydir','reverse')
        if VisualizerStructure.ColormapFlipped == false
            cmap = cptcmap(VisualizerStructure.Colormap);
        else
            cmap = cptcmap(VisualizerStructure.Colormap,'flip',true);
        end
        colormap(cmap);
        caxis([-max(max(abs(abs(CrossSectionData))))*0.8 0.8*max(max(abs(abs(CrossSectionData))))])
        xlabel('Distance along profile (km)')
        ylabel('Depth (km)')
        colorbar


        % Here we set uicontrols to allow the user to update the view "on the
        % fly"
        % Setting the min/max of the color map
        minamp_s = sprintf('%3.3f',-max(max(abs(abs(CrossSectionData))))*0.8);
        maxamp_s = sprintf('%3.3f', max(max(abs(abs(CrossSectionData))))*0.8);
        uicontrol('Style','Text','Parent',xsectionFigureHandles,'Units','Normalized','Position',[0.92 0.65 0.06 0.08],'String','Max amp:','BackgroundColor','White');
        uicontrol('Style','Edit','Parent',xsectionFigureHandles,'Units','Normalized','Position',[0.92 0.64 0.06 0.04],'String',maxamp_s,'Tag','max_color_e');
        uicontrol('Style','Text','Parent',xsectionFigureHandles,'Units','Normalized','Position',[0.92 0.51 0.06 0.08],'String','Min amp:','BackgroundColor','White');
        uicontrol('Style','Edit','Parent',xsectionFigureHandles,'Units','Normalized','Position',[0.92 0.50 0.06 0.04],'String',minamp_s,'Tag','min_color_e');

        % popup menu to change the color palette
        cptmapdir = regexprep(which('funclab'),'funclab.m','cptcmap');
        cptmapdir = [cptmapdir,filesep,'cptfiles'];
        D = dir([cptmapdir filesep '*.cpt']);
        cptfiles = sortrows({D.name});
        List = cptfiles;
        uicontrol('Parent',xsectionFigureHandles,'Style','Text','Units','Normalized','Position',[0.92 0.42 0.06 0.08],'String','Colormap:','BackgroundColor','White');
        uicontrol('Parent',xsectionFigureHandles,'Style','Popupmenu','Units','Normalized','Position',[0.92 0.36 0.06 0.08],'String',List,'Value',1,'Tag','colormap_popup')
        uicontrol('Parent',xsectionFigureHandles,'Style','Popupmenu','Units','Normalized','Position',[0.92 0.28 0.06 0.08],'String',{'Normal','Reverse'},'Value',1,'Tag','colormap_flip_popup')

        % Popup to allow changing the x-axis
    %    uicontrol('Parent',xsectionFigureHandles,'Style','Text','Units','Normalized','Position',[0.92 0.23 0.06 0.08],'String','X-axis:');
    %    uicontrol('Parent',xsectionFigureHandles,'Style','Popupmenu','Units','Normalized','Position',[0.92 0.17 0.06 0.08],'String',{'Distance (km)','Latitude (deg)','Longitude (deg)'},'Value',1,'Tag','xaxis_popup');

        % Add a button to re-draw
        uicontrol('Parent',xsectionFigureHandles,'Style','Pushbutton','Units','Normalized','Position',[0.92 0.1 0.06 0.05],'String','Redraw','Callback',{@update_fence_diagram,axesHandles});

        % Add a button to export for gmt
        % ... coming soon!
    
    else
        
%         % Makes a 3D view.
%         % Didn't really look good
%         % Attempts to faithfully show the 3D geometry by mapping into a
%         % cartesian space
%         % Get coastline data
%         
         ncst = VisualizerStructure.ncst;

%         % Gets the data into the cartesian space
        xsectionX = zeros(length(CrossSectionDistance)*length(zvector),1);
        xsectionY = zeros(length(CrossSectionDistance)*length(zvector),1);
        xsectionZ = zeros(length(CrossSectionDistance)*length(zvector),1);
        xsectionA = zeros(length(CrossSectionDistance)*length(zvector),1);
        
        % load the xsection data
        i = 0;
        for idx=1:length(CrossSectionDistance)
            for idy=1:length(zvector)
                i=i+1;
                xsectionX(i) = CrossSectionLongitudes(idx);
                xsectionY(i) = CrossSectionLatitudes(idx);
                xsectionZ(i) = zvector(idy);
                xsectionA(i) = CrossSectionData(idx,idy);
            end
        end
%         

        cartOrSphereFlag = 'Sphere';
        %cartOrSphereFlag = 'Cart';
        if strcmp(cartOrSphereFlag,'Cart')
            [x, y, z] = lat_lon_rad_to_cart(ncst(:,2),ncst(:,1),6371*ones(length(ncst(:,1))));

            % Get limits in cartesian space
            [xlim(1), ylim(1), zlim(1)] = lat_lon_rad_to_cart(VisualizerStructure.MinLat, VisualizerStructure.MinLon, 6371-zvector(end));
            [xlim(2), ylim(2), zlim(2)] = lat_lon_rad_to_cart(VisualizerStructure.MaxLat, VisualizerStructure.MinLon, 6371-zvector(end));
            [xlim(3), ylim(3), zlim(3)] = lat_lon_rad_to_cart(VisualizerStructure.MaxLat, VisualizerStructure.MaxLon, 6371-zvector(end));
            [xlim(4), ylim(4), zlim(4)] = lat_lon_rad_to_cart(VisualizerStructure.MinLat, VisualizerStructure.MaxLon, 6371-zvector(end));
            [xlim(5), ylim(5), zlim(5)] = lat_lon_rad_to_cart(VisualizerStructure.MinLat, VisualizerStructure.MinLon, zvector(end));
            [xlim(6), ylim(6), zlim(6)] = lat_lon_rad_to_cart(VisualizerStructure.MaxLat, VisualizerStructure.MinLon, zvector(end));
            [xlim(7), ylim(7), zlim(7)] = lat_lon_rad_to_cart(VisualizerStructure.MaxLat, VisualizerStructure.MaxLon, zvector(end));
            [xlim(8), ylim(8), zlim(8)] = lat_lon_rad_to_cart(VisualizerStructure.MinLat, VisualizerStructure.MaxLon, zvector(end));

            % Convert to cartesian
            [xsectionXX, xsectionYY, xsectionZZ] = lat_lon_rad_to_cart(xsectionY, xsectionX, 6371-xsectionZ);

            % Makes the plot
            xsectionFigureHandles = figure('Name','Fence Diagram','Units','Normalized','Position',[0.1 0.1 0.8 0.8],'Color','white');
            axesHandles = axes('Parent',xsectionFigureHandles,'Position',[0.1 0.1 0.8 0.8]);

            scatter3(axesHandles,x,y,z,100,[.6 0 0],'filled')
            hold on
            scatter3(axesHandles,xsectionXX, xsectionYY, xsectionZZ, 100, xsectionA, 'filled')

            %axis(axesHandles,[min(xlim) max(xlim) min(ylim) max(ylim) min(zlim) max(zlim)])
            axis(axesHandles,[min(xsectionXX) max(xsectionXX) min(xsectionYY) max(xsectionYY) min(xsectionZZ) max(xsectionZZ)])

            xlabel(axesHandles,'X (km) (pseudo-spherical)');
            ylabel(axesHandles,'Y (km) (pseudo-spherical)');
            zlabel(axesHandles,'Z (km) (pseudo-spherical)');
            title(axesHandles,'3D Cross Section');
            caxis([min(xsectionA)*0.8 max(xsectionA) * 0.8])
        else        
            % Not sure I want to even write this, but does a 3D view without
            % accounting for the sphericity of the earth
            xsectionFigureHandles = figure('Name','Fence Diagram','Units','Normalized','Position',[0.1 0.1 0.8 0.8],'Color','white');
            axesHandles = axes('Parent',xsectionFigureHandles,'Position',[0.1 0.1 0.8 0.8]);
            scatter3(axesHandles, ncst(:,1),ncst(:,2),zeros(length(ncst),1),100,[0.6 0 0],'filled')
            hold on
            scatter3(axesHandles, xsectionX, xsectionY, xsectionZ, 100,xsectionA,'filled')
            axis(axesHandles,[min(xsectionX) max(xsectionX) min(xsectionY) max(xsectionY) min(xsectionZ) max(xsectionZ)+2])
            xlabel(axesHandles,'Longitude')
            ylabel(axesHandles,'Latitude')
            zlabel(axesHandles,'Depth')
            title(axesHandles,'3D Cross Section')
            set(axesHandles,'Zdir','Reverse')
            caxis([min(xsectionA)*0.8 max(xsectionA) * 0.8])
        end
        
    end
end

function update_fence_diagram(src,evt,axeshdls)
    global VisualizerStructure

    % unpack
    CrossSectionData = VisualizerStructure.CrossSectionData;
    CrossSectionDistance = VisualizerStructure.CrossSectionDistance;
    CrossSectionLatitudes = VisualizerStructure.CrossSectionLatitudes;
    CrossSectionLongitudes = VisualizerStructure.CrossSectionLongitudes;
    lon = VisualizerStructure.fenceLon;
    lat = VisualizerStructure.fenceLat;
    zvector = VisualizerStructure.zvector;
    stepDistances = VisualizerStructure.fenceSteps;


    % Get new data from tags
    hdls = findobj('Tag','max_color_e');
    caxismax = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','min_color_e');
    caxismin = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','colormap_popup');
    cptmapdir = regexprep(which('funclab'),'funclab.m','cptcmap');
    cptmapdir = [cptmapdir,filesep,'cptfiles'];
    D = dir([cptmapdir filesep '*.cpt']);
    cptfiles = sortrows({D.name});
    List = cptfiles;
    TmpColorMap = List{hdls.Value};
    
    hdls = findobj('Tag','colormap_flip_popup');
    colormapFlipFlag = hdls.Value;
    
    % Replot
    cla(axeshdls)
    xx = repmat(CrossSectionDistance,1,size(zvector,2));
    xlab = 'Distance along profile (km)';
    
    yy = repmat(zvector,size(CrossSectionDistance,1),1);
    pcolor(axeshdls, xx, yy, CrossSectionData)
    shading interp
    set(gca,'ydir','reverse')
    axis tight
    hold on
    
    % Add a line of markers to the top to match the view on the map
    % Add a line of markers to the top to match the view on the map
    % determine the colors for the dots - black to bright red. 
    hold on
    cols = zeros(length(lon),3);
    cc = linspace(0,1,length(lon));
    cols(:,1) = cc;

    % And colored dots for reference
    for i=1:length(lon)
        scatter(stepDistances(i), 0, 100, 'filled','MarkerFaceColor',[cols(i,1) cols(i,2) cols(i,3)], 'MarkerEdgeColor','k')
        plot([stepDistances(i) stepDistances(i)], [0, zvector(end)],'k')
    end


    if colormapFlipFlag == 1
        cmap = cptcmap(TmpColorMap);
    else
        cmap = cptcmap(TmpColorMap,'flip',true);
    end
    colormap(cmap);
    caxis([caxismin caxismax])
    xlabel(xlab)
    ylabel('Depth (km)')
    colorbar
end

function make_new_cross_section(src, evt,MapViewAxesHandles)
    global VisualizerStructure
    
    % Relatively simple user controls, but more complicated backend
    % User needs to determine:
    %   Click for start and end
    %   Edit box for number of points to find between start and end
    %   Smoothing applied before the section is made.
    % We actually have enough room to put these controls in the main
    % visualizer gui. This will make both this cross section plot and the
    % fence diagram plot simpler.
    
    
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
    
%     hold on
%     plot(MapViewAxesHandles,lon,lat,'Color','Black')
%     % Add colored dots for reference
%     scatter(MapViewAxesHandles,lon(1), lat(1), 100,'filled','MarkerFaceColor','k','MarkerEdgeColor','k')
%     scatter(MapViewAxesHandles,lon(2), lat(2), 100,'filled','MarkerFaceColor','w','MarkerEdgeColor','k')
%     scatter(MapViewAxesHandles,(lon(1)+lon(2))/2, (lat(1)+lat(2))/2, 100,'filled','MarkerFaceColor','b','MarkerEdgeColor','k')
%     scatter(MapViewAxesHandles,(lon(2)-lon(1))/4+lon(1), (lat(2)-lat(1))/4+lat(1), 100,'filled','MarkerFaceColor','r','MarkerEdgeColor','k')
%     scatter(MapViewAxesHandles,(lon(2)-lon(1))*3/4+lon(1), (lat(2)-lat(1))*3/4+lat(1), 100,'filled','MarkerFaceColor','g','MarkerEdgeColor','k')

    % Convert lon and lat to map projection
    [x,y] = m_xy2ll(lon, lat);
    lon = x;
    lat = y;
    
    
    % Positions from calling figure
    MainPos = [0 0 140 18];
    ParamTitlePos = [2 MainPos(4)-3 80 2];
    ParamTextPos1 = [1 0 34 1.75];
    ParamOptionPos1 = [37 0 7 1.75];
    ParamTextPos2 = [47 0 34 1.75];
    ParamOptionPos2 = [84 0 7 1.75];
    ParamTextPos3 = [94 0 34 1.75];
    ParamOptionPos3 = [131 0 7 1.75];
    ProcTitlePos = [80 MainPos(4)-2 50 1.25];
    ProcButtonPos = [100 2 35 3];
    CloseButtonPos = [90 3 30 3];

    % Setting font sizes
    TextFontSize = 0.6; % ORIGINAL
    EditFontSize = 0.5;
    AccentColor = [.6 0 0];
    GeometryFigure = figure('Name','Enter cross-section diagram parameters','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'DockControls','off','MenuBar','none','NumberTitle','off','Color','White');

    %text and edit boxes
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','title_t','String','Set cross-section parameters',...
        'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.85,'HorizontalAlignment','left','BackgroundColor','White');
    ParamTextPos1(2) = 12;
    ParamOptionPos1(2) = 12;
    ParamTextPos2(2) = 12;
    ParamOptionPos2(2) = 12;
    ParamTextPos3(2) = 12;
    ParamOptionPos3(2) = 12;

    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','smoothing_lon_t','String','Smoothing in longitude (nodes):',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','nsmoothx_edit','String','1',...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','smoothing_lat_t','String','Smoothing in latitude (nodes):',...
        'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','nsmoothy_edit','String','1',...
        'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','smoothing_depth_t','String','Smoothing in depth (nodes):',...
        'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','nsmoothz_edit','String','1',...
        'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
     ParamTextPos1(2) = 9;
     ParamOptionPos1(2) = 9;
     ParamTextPos2(2) = 9;
     ParamOptionPos2(2) = 9;
     ParamTextPos3(2) = 9;
     ParamOptionPos3(2) = 9;

    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','npts_along_section_t','String','NPTS in section:',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','npts_section_edit','String','40',...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
    ParamOptionPos2(3) = 18;
    ParamOptionPos2(1) = 74;
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','linear_or_gc_t','String','Linear or Great Circle:',...
        'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','popupmenu','Units','characters','Tag','projection_method_popup','String',{'Linear','Great Circle'},...
        'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    ParamOptionPos2(1) = 84;

    
    % Switch between 2D plot and 3D plot
    ParamOptionPos3(3) = 18;
    ParamOptionPos3(2) = 9;
    ParamOptionPos3(1) = 121;
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','twod_or_threed_text','String','2D or 3D:',...
        'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','popupmenu','Units','characters','Tag','twod_or_threed_popup','String',{'2D','3D'},...
        'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    ParamOptionPos3(1) = 131;
    ParamOptionPos3(3) = 7;
    
    
     ParamTextPos1(2) = 6;
     ParamOptionPos1(2) = 6;
     ParamTextPos2(2) = 6;
     ParamOptionPos2(2) = 6;
     ParamOptionPos2(3) = 7;
     ParamTextPos3(2) = 6;
     ParamOptionPos3(2) = 6;

     % Find the depth limits from the data set
     min_depth_s = sprintf('%3.1f',min(min(min(VisualizerStructure.Depths))));
     max_depth_s = sprintf('%3.1f',max(max(max(VisualizerStructure.Depths))));
     inc_depth_s = sprintf('%3.1f',VisualizerStructure.Depths(1,1,2) - VisualizerStructure.Depths(1,1,1));

     uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','min_depth_t','String','Minimum depth (km):',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
     uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','minimum_depth_edit','String',min_depth_s,...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
     uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','max_depth_t','String','Maximum depth (km):',...
        'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
     uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','maximum_depth_edit','String',max_depth_s,...
        'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
     uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','inc_depth_t','String','Increment in depth (km):',...
        'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
     uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','increment_depth_edit','String',inc_depth_s,...
        'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');


    % Add buttons for "plot" and "Cancel"
    uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','create_cross_section_pb','String','Make diagram',...
        'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
        'Callback',{@plot_cross_section_view,GeometryFigure, lon, lat});

    ProcButtonPos(1) = 60;
    uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','cancel_cross_section_pb','String','Cancel',...
        'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
        'Callback',{@cancel_new_view,GeometryFigure});
    

end

function plot_cross_section_view(src, evt,callinghdls, lon, lat)
    global VisualizerStructure
  
    TmpWaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',TmpWaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait while making the cross section...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    
    % Get values from the edit boxes
    hdls = findobj('Tag','nsmoothx_edit');
    nsmoothx = sscanf(hdls.String,'%d');
    
    hdls = findobj('Tag','nsmoothy_edit');
    nsmoothy = sscanf(hdls.String,'%d');
    
    hdls = findobj('Tag','nsmoothz_edit');
    nsmoothz = sscanf(hdls.String,'%d');
    
    hdls = findobj('Tag','npts_section_edit');
    nptsAlongSection = sscanf(hdls.String,'%d');
    
    hdls = findobj('Tag','minimum_depth_edit');
    mindepth = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','maximum_depth_edit');
    maxdepth = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','increment_depth_edit');
    incdepth = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','projection_method_popup');
    extractMethodFlag = hdls.Value; % 1 = linear, 2 = great circle

    hdls = findobj('Tag','twod_or_threed_popup');
    twodOrThreeDFlag = hdls.Value; % 1 = 2D, 2 = 3D
    
    % close the calling handles
    close(callinghdls);
    
    % Prepare the data set
    SmoothMatrix = smooth_nxmxk_matrix(VisualizerStructure.Amplitude,nsmoothx, nsmoothy, nsmoothz);
    
    % Get the depth vector
    zvector = mindepth:incdepth:maxdepth;
    
    % Running the extraction code
    % Just little simplify of the latitude and longitude (ie to mirror raytracerrp.c)
    startLat = lat(1);
    startLong = lon(1);
    endLat = lat(2);
    endLong = lon(2);

    % The first and last points in cartesian (but used in the
        % spherical extraction option!)
    EARTH_RADIUS = 6371;
    xOrig = EARTH_RADIUS * cosd(startLat) * cosd(startLong);
    yOrig = EARTH_RADIUS * cosd(startLat) * sind(startLong);
    zOrig = EARTH_RADIUS * sind(startLat);

    xTarget = EARTH_RADIUS * cosd(endLat) * cosd(endLong);
    yTarget = EARTH_RADIUS * cosd(endLat) * sind(endLong);
    zTarget = EARTH_RADIUS * sind(endLat);
    
    % Initial point in the calculation
    prevLat = startLat;
    prevLong = startLong;
    accumulatedDistance = 0;

    % Get memory for the cross section array which is nptsAlongSection x nDepths
    CrossSectionData = zeros(nptsAlongSection, length(zvector));
    CrossSectionDistance = zeros(nptsAlongSection,1);
    CrossSectionLatitudes = zeros(nptsAlongSection,1);
    CrossSectionLongitudes = zeros(nptsAlongSection,1);
    
    % Alternatively, assume latitude and longitude are cartesian to fit what the map view looks like
    tmpLats2 = linspace(startLat, endLat, nptsAlongSection);
    tmpLons2 = linspace(startLong, endLong, nptsAlongSection);
    
    % Rearrange to make it look like a proper mesh grid
    if strcmp(VisualizerStructure.AmplitudeType,'VelocityPerturbation')
        TmpAmplitude = permute(SmoothMatrix,[2,1,3]);
        TmpLon = permute(VisualizerStructure.Lons,[2,1,3]);
        TmpLat = permute(VisualizerStructure.Lats,[2,1,3]);
        TmpDep = permute(VisualizerStructure.Depths,[2,1,3]);
    else
        TmpAmplitude = permute(SmoothMatrix,[1,2,3]);
        TmpLon = permute(VisualizerStructure.Lons,[1,2,3]);
        TmpLat = permute(VisualizerStructure.Lats,[1,2,3]);
        TmpDep = permute(VisualizerStructure.Depths,[1,2,3]);
    end

    
    for imeasurement=1:nptsAlongSection
    
        % finds the cartesian coordinates of current step
        xStep = xOrig + (imeasurement-1) * (xTarget - xOrig) / (nptsAlongSection-1);
        yStep = yOrig + (imeasurement-1) * (yTarget - yOrig) / (nptsAlongSection-1);
        zStep = zOrig + (imeasurement-1) * (zTarget - zOrig) / (nptsAlongSection-1);

        % returns to latitude and longitude
        tmpLong = 180.0 / pi * atan2(yStep,xStep);
        tmpLat = 90 - 180.0 / pi * acos(zStep / sqrt(xStep*xStep + yStep * yStep + zStep * zStep)); 

        % adjustments for the start of the profile
        if imeasurement == 1
            tmpLong = lon(1);
            tmpLat = lat(1);
        end

        % Adjust at the end of the profile
        if imeasurement == nptsAlongSection
            tmpLong = lon(2);
            tmpLat = lat(2);
        end
        

        % Use the linear interpolation instead for the location
        if extractMethodFlag == 1
            tmpLat = tmpLats2(imeasurement);
            tmpLong = tmpLons2(imeasurement);
        end
        
        CrossSectionLatitudes(imeasurement) = tmpLat;
        CrossSectionLongitudes(imeasurement) = tmpLong;

        % here is where we get the data from the model as a function of
        % depth
        CrossSectionData(imeasurement,:) = interp3(TmpLon, TmpLat, TmpDep, TmpAmplitude,tmpLong, tmpLat, zvector,'linear');
        %[CrossSectionDistance(imeasurement),~,~] = distaz(startLat, startLong, tmpLat, tmpLong);
        CrossSectionDistance(imeasurement) = gcdist(startLat, startLong, tmpLat, tmpLong);
        
    end
    
    % Close the wait gui as we are ready to plot
    close(TmpWaitGui)

    % Store the matrices/vectors we want to keep if we update the plot
    VisualizerStructure.CrossSectionData = CrossSectionData;
    VisualizerStructure.CrossSectionDistance = CrossSectionDistance;
    VisualizerStructure.CrossSectionLatitudes = CrossSectionLatitudes;
    VisualizerStructure.CrossSectionLongitudes = CrossSectionLongitudes;
    VisualizerStructure.CrossSectionLon = lon;
    VisualizerStructure.CrossSectionLat = lat;
    VisualizerStructure.zvector = zvector;
    
    if twodOrThreeDFlag == 1

            % make the plot
            % Get the x and y arrays for the plot
            xx = repmat(CrossSectionDistance,1,size(zvector,2));
            yy = repmat(zvector,size(CrossSectionDistance,1),1);
            % Gets a new figure
            xsectionFigureHandles = figure('Name','Cross Section','Units','Normalized','Position',[0.1 0.5 0.8 0.4],'Color','white');
            axesHandles = axes('Position',[0.05 0.1 0.85 0.8]);
            pcolor(axesHandles, xx,yy, CrossSectionData)

            hold on
            % Add a line of markers to the top to match the view on the map
            scatter(0, 0, 100,'filled','MarkerFaceColor','k','MarkerEdgeColor','k')
            scatter(CrossSectionDistance(end), 0, 100,'filled','MarkerFaceColor','w','MarkerEdgeColor','k')
            scatter(CrossSectionDistance(end)/2, 0, 100,'filled','MarkerFaceColor','b','MarkerEdgeColor','k')
            scatter(CrossSectionDistance(end)/4, 0, 100,'filled','MarkerFaceColor','r','MarkerEdgeColor','k')
            scatter(CrossSectionDistance(end)*3/4, 0, 100,'filled','MarkerFaceColor','g','MarkerEdgeColor','k')

            % Pretty up a little
            shading interp
            set(gca,'ydir','reverse')
            if VisualizerStructure.ColormapFlipped == false
                cmap = cptcmap(VisualizerStructure.Colormap);
            else
                cmap = cptcmap(VisualizerStructure.Colormap,'flip',true);
            end
            colormap(cmap);
            caxis([-max(max(abs(abs(CrossSectionData))))*0.8 0.8*max(max(abs(abs(CrossSectionData))))])
            xlabel('Distance along profile (km)')
            ylabel('Depth (km)')
            colorbar

            % Here we set uicontrols to allow the user to update the view "on the
            % fly"
            % Setting the min/max of the color map
            minamp_s = sprintf('%3.3f',-max(max(abs(abs(CrossSectionData))))*0.8);
            maxamp_s = sprintf('%3.3f', max(max(abs(abs(CrossSectionData))))*0.8);
            uicontrol('Style','Text','Parent',xsectionFigureHandles,'Units','Normalized','Position',[0.92 0.65 0.06 0.08],'String','Max amp:','BackgroundColor','White');
            uicontrol('Style','Edit','Parent',xsectionFigureHandles,'Units','Normalized','Position',[0.92 0.64 0.06 0.04],'String',maxamp_s,'Tag','max_color_e');
            uicontrol('Style','Text','Parent',xsectionFigureHandles,'Units','Normalized','Position',[0.92 0.51 0.06 0.08],'String','Min amp:','BackgroundColor','White');
            uicontrol('Style','Edit','Parent',xsectionFigureHandles,'Units','Normalized','Position',[0.92 0.50 0.06 0.04],'String',minamp_s,'Tag','min_color_e');

            % popup menu to change the color palette
            cptmapdir = regexprep(which('funclab'),'funclab.m','cptcmap');
            cptmapdir = [cptmapdir,filesep,'cptfiles'];
            D = dir([cptmapdir filesep '*.cpt']);
            cptfiles = sortrows({D.name});
            List = cptfiles;
            uicontrol('Parent',xsectionFigureHandles,'Style','Text','Units','Normalized','Position',[0.92 0.42 0.06 0.08],'String','Colormap:','BackgroundColor','White');
            uicontrol('Parent',xsectionFigureHandles,'Style','Popupmenu','Units','Normalized','Position',[0.92 0.36 0.06 0.08],'String',List,'Value',1,'Tag','colormap_popup')
            uicontrol('Parent',xsectionFigureHandles,'Style','Popupmenu','Units','Normalized','Position',[0.92 0.28 0.06 0.08],'String',{'Normal','Reverse'},'Value',1,'Tag','colormap_flip_popup')


            % Popup to allow changing the x-axis
            uicontrol('Parent',xsectionFigureHandles,'Style','Text','Units','Normalized','Position',[0.92 0.23 0.06 0.08],'String','X-axis:','BackgroundColor','White');
            uicontrol('Parent',xsectionFigureHandles,'Style','Popupmenu','Units','Normalized','Position',[0.92 0.17 0.06 0.08],'String',{'Distance (km)','Latitude (deg)','Longitude (deg)'},'Value',1,'Tag','xaxis_popup');

            % Add a button to re-draw
            uicontrol('Parent',xsectionFigureHandles,'Style','Pushbutton','Units','Normalized','Position',[0.92 0.1 0.06 0.05],'String','Redraw','Callback',{@update_cross_section,axesHandles});

            % Add a button to export for gmt
            % ... coming soon!
    
        else
        
%         % Makes a 3D view.
%         % Didn't really look good
%         % Attempts to faithfully show the 3D geometry by mapping into a
%         % cartesian space
%         % Get coastline data
%         
         ncst = VisualizerStructure.ncst;

%         % Gets the data into the cartesian space
        xsectionX = zeros(length(CrossSectionDistance)*length(zvector),1);
        xsectionY = zeros(length(CrossSectionDistance)*length(zvector),1);
        xsectionZ = zeros(length(CrossSectionDistance)*length(zvector),1);
        xsectionA = zeros(length(CrossSectionDistance)*length(zvector),1);
        
        % load the xsection data
        i = 0;
        for idx=1:length(CrossSectionDistance)
            for idy=1:length(zvector)
                i=i+1;
                xsectionX(i) = CrossSectionLongitudes(idx);
                xsectionY(i) = CrossSectionLatitudes(idx);
                xsectionZ(i) = zvector(idy);
                xsectionA(i) = CrossSectionData(idx,idy);
            end
        end
%         

        cartOrSphereFlag = 'Sphere';
        %cartOrSphereFlag = 'Cart';
        if strcmp(cartOrSphereFlag,'Cart')
            [x, y, z] = lat_lon_rad_to_cart(ncst(:,2),ncst(:,1),6371*ones(length(ncst(:,1))));

            % Get limits in cartesian space
            [xlim(1), ylim(1), zlim(1)] = lat_lon_rad_to_cart(VisualizerStructure.MinLat, VisualizerStructure.MinLon, 6371-zvector(end));
            [xlim(2), ylim(2), zlim(2)] = lat_lon_rad_to_cart(VisualizerStructure.MaxLat, VisualizerStructure.MinLon, 6371-zvector(end));
            [xlim(3), ylim(3), zlim(3)] = lat_lon_rad_to_cart(VisualizerStructure.MaxLat, VisualizerStructure.MaxLon, 6371-zvector(end));
            [xlim(4), ylim(4), zlim(4)] = lat_lon_rad_to_cart(VisualizerStructure.MinLat, VisualizerStructure.MaxLon, 6371-zvector(end));
            [xlim(5), ylim(5), zlim(5)] = lat_lon_rad_to_cart(VisualizerStructure.MinLat, VisualizerStructure.MinLon, zvector(end));
            [xlim(6), ylim(6), zlim(6)] = lat_lon_rad_to_cart(VisualizerStructure.MaxLat, VisualizerStructure.MinLon, zvector(end));
            [xlim(7), ylim(7), zlim(7)] = lat_lon_rad_to_cart(VisualizerStructure.MaxLat, VisualizerStructure.MaxLon, zvector(end));
            [xlim(8), ylim(8), zlim(8)] = lat_lon_rad_to_cart(VisualizerStructure.MinLat, VisualizerStructure.MaxLon, zvector(end));

            % Convert to cartesian
            [xsectionXX, xsectionYY, xsectionZZ] = lat_lon_rad_to_cart(xsectionY, xsectionX, 6371-xsectionZ);

            % Makes the plot
            xsectionFigureHandles = figure('Name','Fence Diagram','Units','Normalized','Position',[0.1 0.1 0.8 0.8],'Color','white');
            axesHandles = axes('Parent',xsectionFigureHandles,'Position',[0.1 0.1 0.8 0.8]);

            scatter3(axesHandles,x,y,z,100,[.6 0 0],'filled')
            hold on
            scatter3(axesHandles,xsectionXX, xsectionYY, xsectionZZ, 100, xsectionA, 'filled')

            %axis(axesHandles,[min(xlim) max(xlim) min(ylim) max(ylim) min(zlim) max(zlim)])
            axis(axesHandles,[min(xsectionXX) max(xsectionXX) min(xsectionYY) max(xsectionYY) min(xsectionZZ) max(xsectionZZ)])

            xlabel(axesHandles,'X (km) (pseudo-spherical)');
            ylabel(axesHandles,'Y (km) (pseudo-spherical)');
            zlabel(axesHandles,'Z (km) (pseudo-spherical)');
            title(axesHandles,'3D Cross Section');
            caxis([min(xsectionA)*0.8 max(xsectionA) * 0.8])
        else        
            % Not sure I want to even write this, but does a 3D view without
            % accounting for the sphericity of the earth
            xsectionFigureHandles = figure('Name','Fence Diagram','Units','Normalized','Position',[0.1 0.1 0.8 0.8],'Color','white');
            axesHandles = axes('Parent',xsectionFigureHandles,'Position',[0.1 0.1 0.8 0.8]);
            scatter3(axesHandles, ncst(:,1),ncst(:,2),zeros(length(ncst),1),100,[0.6 0 0],'filled')
            hold on
            scatter3(axesHandles, xsectionX, xsectionY, xsectionZ, 100,xsectionA,'filled')
            axis(axesHandles,[min(xsectionX) max(xsectionX) min(xsectionY) max(xsectionY) min(xsectionZ) max(xsectionZ)+2])
            xlabel(axesHandles,'Longitude')
            ylabel(axesHandles,'Latitude')
            zlabel(axesHandles,'Depth')
            title(axesHandles,'3D Cross Section')
            set(axesHandles,'Zdir','Reverse')
            caxis([min(xsectionA)*0.8 max(xsectionA) * 0.8])
        end
        
    end
    
    
end

function update_cross_section(src,evt,axeshdls)
    global VisualizerStructure

    % unpack
    CrossSectionData = VisualizerStructure.CrossSectionData;
    CrossSectionDistance = VisualizerStructure.CrossSectionDistance;
    CrossSectionLatitudes = VisualizerStructure.CrossSectionLatitudes;
    CrossSectionLongitudes = VisualizerStructure.CrossSectionLongitudes;
    lon = VisualizerStructure.CrossSectionLon;
    lat = VisualizerStructure.CrossSectionLat;
    zvector = VisualizerStructure.zvector;

    % Get new data from tags
    hdls = findobj('Tag','max_color_e');
    caxismax = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','min_color_e');
    caxismin = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','colormap_popup');
    cptmapdir = regexprep(which('funclab'),'funclab.m','cptcmap');
    cptmapdir = [cptmapdir,filesep,'cptfiles'];
    D = dir([cptmapdir filesep '*.cpt']);
    cptfiles = sortrows({D.name});
    List = cptfiles;
    TmpColorMap = List{hdls.Value};
    
    hdls = findobj('Tag','colormap_flip_popup');
    colormapFlipFlag = hdls.Value;
    
    hdls = findobj('Tag','xaxis_popup');
    xaxislogic = hdls.Value;
    
    % Replot
    cla(axeshdls)
    if xaxislogic == 1
        xx = repmat(CrossSectionDistance,1,size(zvector,2));
        xlab = 'Distance along profile (km)';
    elseif xaxislogic == 2
        xx = repmat(CrossSectionLatitudes,1,size(zvector,2));
        xlab = 'Latitude (deg)';
    else
        xx = repmat(CrossSectionLongitudes,1,size(zvector,2));
        xlab = 'Longitude (deg)';
    end
    yy = repmat(zvector,size(CrossSectionDistance,1),1);
    pcolor(axeshdls, xx, yy, CrossSectionData)
    shading interp
    set(gca,'ydir','reverse')
    axis tight
    hold on
    % Add a line of markers to the top to match the view on the map
    if xaxislogic == 1
        scatter(0, 0, 100,'filled','MarkerFaceColor','k','MarkerEdgeColor','k')
        scatter(CrossSectionDistance(end), 0, 100,'filled','MarkerFaceColor','w','MarkerEdgeColor','k')
        scatter(CrossSectionDistance(end)/2, 0, 100,'filled','MarkerFaceColor','b','MarkerEdgeColor','k')
        scatter(CrossSectionDistance(end)/4, 0, 100,'filled','MarkerFaceColor','r','MarkerEdgeColor','k')
        scatter(CrossSectionDistance(end)*3/4, 0, 100,'filled','MarkerFaceColor','g','MarkerEdgeColor','k')
    elseif xaxislogic == 2
        scatter(CrossSectionLatitudes(1), 0, 100,'filled','MarkerFaceColor','k','MarkerEdgeColor','k')
        scatter(CrossSectionLatitudes(end), 0, 100,'filled','MarkerFaceColor','w','MarkerEdgeColor','k')
        scatter((CrossSectionLatitudes(end)-CrossSectionLatitudes(1))/2+CrossSectionLatitudes(1), 0, 100,'filled','MarkerFaceColor','b','MarkerEdgeColor','k')
        scatter((CrossSectionLatitudes(end)-CrossSectionLatitudes(1))/4+CrossSectionLatitudes(1), 0, 100,'filled','MarkerFaceColor','r','MarkerEdgeColor','k')
        scatter((CrossSectionLatitudes(end)-CrossSectionLatitudes(1))*3/4+CrossSectionLatitudes(1), 0, 100,'filled','MarkerFaceColor','g','MarkerEdgeColor','k')
    else
        scatter(CrossSectionLongitudes(1), 0, 100,'filled','MarkerFaceColor','k','MarkerEdgeColor','k')
        scatter(CrossSectionLongitudes(end), 0, 100,'filled','MarkerFaceColor','w','MarkerEdgeColor','k')
        scatter((CrossSectionLongitudes(end)-CrossSectionLongitudes(1))/2+CrossSectionLongitudes(1), 0, 100,'filled','MarkerFaceColor','b','MarkerEdgeColor','k')
        scatter((CrossSectionLongitudes(end)-CrossSectionLongitudes(1))/4+CrossSectionLongitudes(1), 0, 100,'filled','MarkerFaceColor','r','MarkerEdgeColor','k')
        scatter((CrossSectionLongitudes(end)-CrossSectionLongitudes(1))*3/4+CrossSectionLongitudes(1), 0, 100,'filled','MarkerFaceColor','g','MarkerEdgeColor','k');
    end

    if colormapFlipFlag == 1
        cmap = cptcmap(TmpColorMap);
    else
        cmap = cptcmap(TmpColorMap,'flip',true);
    end
    colormap(cmap);
    caxis([caxismin caxismax])
    xlabel(xlab)
    ylabel('Depth (km)')
    colorbar
    
end


function launch_map_view_gui(src,evt)
    global VisualizerStructure
    % We need edit boxes for north latitude, south latitude, west
    % longitude, and east longitude. Edit box for nsmoothx,  nsmoothy, and
    % nsmoothz. Edit box for depth (km)
    % Confirm button and cancel button
    % Cancel will close this gui, confirm will pop up a new window with a
    % map view of amplitude at depth. The map view should be in a new
    % figure with an "export for GMT4" and "export for GMT5" button
    
    % Strings for default geographic limits
    SouthLat = sprintf('%3.1f',min(min(min(VisualizerStructure.Lats))));
    NorthLat = sprintf('%3.1f',max(max(max(VisualizerStructure.Lats))));
    WestLon = sprintf('%3.1f',min(min(min(VisualizerStructure.Lons))));
    EastLon = sprintf('%3.1f',max(max(max(VisualizerStructure.Lons))));
    
    % Positions from calling figure
    MainPos = [0 0 140 18];
    ParamTitlePos = [2 MainPos(4)-3 80 3];
    ParamTextPos1 = [1 0 34 1.75];
    ParamOptionPos1 = [37 0 7 1.75];
    ParamTextPos2 = [47 0 34 1.75];
    ParamOptionPos2 = [84 0 7 1.75];
    ParamTextPos3 = [94 0 34 1.75];
    ParamOptionPos3 = [131 0 7 1.75];
    ProcTitlePos = [80 MainPos(4)-2 50 1.25];
    ProcButtonPos = [100 2 35 3];
    CloseButtonPos = [90 3 30 3];

    % Setting font sizes
    TextFontSize = 0.6; % ORIGINAL
    EditFontSize = 0.5;
    AccentColor = [.6 0 0];
    GeometryFigure = figure('Name','Enter map view parameters','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'DockControls','off','MenuBar','none','NumberTitle','off','Color','White');

    %text and edit boxes
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','title_t','String','Set map view geometry',...
        'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',.7,'HorizontalAlignment','left','BackgroundColor','White');
    ParamTextPos1(2) = 12;
    ParamOptionPos1(2) = 12;
    ParamTextPos2(2) = 12;
    ParamOptionPos2(2) = 12;
    ParamTextPos3(2) = 12;
    ParamOptionPos3(2) = 12;

    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','smoothing_lon_t','String','Smoothing in longitude (nodes):',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','smooth_longitude_e','String','1',...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','smoothing_lat_t','String','Smoothing in latitude (nodes):',...
        'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','smooth_latitude_e','String','1',...
        'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','smoothing_depth_t','String','Smoothing in depth (nodes):',...
        'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','smooth_depth_e','String','1',...
        'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
   
    ParamTextPos1(2) = 9;
    ParamOptionPos1(2) = 9;
    ParamTextPos2(2) = 9;
    ParamOptionPos2(2) = 9;
   
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latmin_t','String','South Latitude (deg)',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MinimumLatitude_e','String',SouthLat,...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latmax_t','String','North Latitude (deg)',...
        'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MaximumLatitude_e','String',NorthLat,...
        'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
    ParamTextPos1(2) = 6;
    ParamOptionPos1(2) = 6;
    ParamTextPos2(2) = 6;
    ParamOptionPos2(2) = 6;

    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','lonmin_t','String','West Longitude (deg)',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MinimumLongitude_e','String',WestLon,...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','lonmax_t','String','East Longitude (deg)',...
        'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MaximumLongitude_e','String',EastLon,...
        'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    
    ParamTextPos1(2) = 3;
    ParamOptionPos1(2) = 3;
    
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depth_t','String','Depth (km)',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','White');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','SetDepth_e','String','200',...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');

    % Add buttons for "Save Geometry" and "Cancel"
    uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','savegeometry_pb','String','Plot Map',...
        'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
        'Callback',{@plot_visualizer_map_view,GeometryFigure});

    ProcButtonPos(1) = 60;
    uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','cancel_pb','String','Cancel',...
        'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
        'Callback',{@cancel_new_view,GeometryFigure});
end

function plot_visualizer_map_view(src,evt,callinghdls)
    global VisualizerStructure
    
    TmpWaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',TmpWaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait while making the map...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow

    
    % Get parameters from user inputs in the edit boxes
    hdls = findobj('Tag','MinimumLatitude_e');
    minlat = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','MaximumLatitude_e');
    maxlat = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','MinimumLongitude_e');
    minlon = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','MaximumLongitude_e');
    maxlon = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','SetDepth_e');
    plotDepth = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','smooth_latitude_e');
    nsmoothy = sscanf(hdls.String,'%d');
    hdls = findobj('Tag','smooth_longitude_e');
    nsmoothx = sscanf(hdls.String,'%d');
    hdls = findobj('Tag','smooth_depth_e');
    nsmoothz = sscanf(hdls.String,'%d');
    
    % Don't need the calling handles anymore
    close(callinghdls)
    
    % get input node spacing
    if strcmp(VisualizerStructure.AmplitudeType,'VelocityPerturbation')
        deltaLon = VisualizerStructure.Lons(2,1,1) - VisualizerStructure.Lons(1,1,1);
        deltaLat = VisualizerStructure.Lats(1,2,1) - VisualizerStructure.Lats(1,1,1);
        deltaDep = VisualizerStructure.Depths(1,1,2) - VisualizerStructure.Depths(1,1,1);
    else
        deltaLon = VisualizerStructure.Lons(1,2,1) - VisualizerStructure.Lons(1,1,1);
        deltaLat = VisualizerStructure.Lats(2,1,1) - VisualizerStructure.Lats(1,1,1);
        deltaDep = VisualizerStructure.Depths(1,1,2) - VisualizerStructure.Depths(1,1,1);
    end
    % Smooth the matrix
    AmplitudeMatrix = smooth_nxmxk_matrix(VisualizerStructure.Amplitude,nsmoothx, nsmoothy, nsmoothz);
    
    % Avoid bad spatial parameters
    if minlat > maxlat | minlon > maxlon
        close(TmpWaitGui)
        d=dialog('Position',[0 0 300 150],'Name','Visualizer Error.','CreateFcn',{@movegui_kce,'center'});
        txt=uicontrol('Parent',d,'Style','Text','Units','Normalized','Position',[.1 .4 .8 .4],'String','Error with geographic input.','FontSize',16);
        btn=uicontrol('Parent',d,'Style','Pushbutton','String','My bad','Units','Normalized','ForegroundColor',[.6 0 0],'Position',[0.25 0.1 0.5 0.25],'Callback','delete(gcf)');
        return
    end
    
    % Make vectors for the plot space
    latitudeVector = minlat:deltaLat:maxlat;
    longitudeVector = minlon:deltaLon:maxlon;
    
    % Create a mesh for the plot space
    [lonmesh, latmesh] = meshgrid(longitudeVector, latitudeVector);
    
    % Rearrange to make it look like a proper mesh grid
    if strcmp(VisualizerStructure.AmplitudeType,'VelocityPerturbation')
        TmpAmplitude = permute(AmplitudeMatrix,[2,1,3]);
        TmpLon = permute(VisualizerStructure.Lons,[2,1,3]);
        TmpLat = permute(VisualizerStructure.Lats,[2,1,3]);
        TmpDep = permute(VisualizerStructure.Depths,[2,1,3]);
    else
        TmpAmplitude = permute(AmplitudeMatrix,[1,2,3]);
        TmpLon = permute(VisualizerStructure.Lons,[1,2,3]);
        TmpLat = permute(VisualizerStructure.Lats,[1,2,3]);
        TmpDep = permute(VisualizerStructure.Depths,[1,2,3]);
    end
    
    % Does the interpolation onto the desired plot area
    AmplitudeMatrixTwoD = interp3(TmpLon, TmpLat, TmpDep, TmpAmplitude, lonmesh, latmesh, repmat(plotDepth,size(lonmesh)));
    
    % Store the map data
    VisualizerStructure.MapAmplitude = AmplitudeMatrixTwoD;
    VisualizerStructure.LongitudeVector = longitudeVector;
    VisualizerStructure.LatitudeVector = latitudeVector;
    
    close(TmpWaitGui)
    
    % Actual plot
    % If someone with the mapping toolbox wants to make a cleaner map, feel
    % free, but remember to add a license check so that this crude map
    % still works.
    fighdls = figure('Name','Map view','Color','White');
    ax = axes('Units','Normalized','Position',[0.05 0.05 0.75 0.85]);
    MapProjectionID = VisualizerStructure.MapProjectionID;
    if strcmp(MapProjectionID,'Stereographic') || strcmp(MapProjectionID,'Orthographic') || strcmp(MapProjectionID,'Azimuthal Equal-area') || ...
        strcmp(MapProjectionID,'Azimuthal Equidistant') || strcmp(MapProjectionID,'Gnomonic') || strcmp(MapProjectionID,'Satellite')    
        [~, ~, xdeg] = distaz(minlat, minlon, maxlat, maxlon);
        m_proj(MapProjectionID,'latitude',(minlat + maxlat)/2, 'longitude',(minlon + maxlon) / 2,'radius',xdeg/2);
    else
        m_proj(MapProjectionID,'latitude',[minlat maxlat],'longitude',[minlon maxlon]);
    end
    m_pcolor(longitudeVector, latitudeVector, AmplitudeMatrixTwoD);
    %pcolor(longitudeVector, latitudeVector, AmplitudeMatrixTwoD)
    shading interp
    hold on
    if VisualizerStructure.ColormapFlipped == false
        cmap = cptcmap(VisualizerStructure.Colormap);
    else
        cmap = cptcmap(VisualizerStructure.Colormap,'flip',true);
    end
    colormap(cmap);
    caxis([-max(max(abs(abs(AmplitudeMatrixTwoD))))*0.8 0.8*max(max(abs(abs(AmplitudeMatrixTwoD))))])
    m_coast('line','Color','black');
    m_line(VisualizerStructure.PBlong, VisualizerStructure.PBlat,'Color',[0.2 0.2 0.8])
    m_line(VisualizerStructure.stateBoundaries.longitude, VisualizerStructure.stateBoundaries.latitude,'Color','black')
    m_grid('box','on')
    %plot(VisualizerStructure.ncst(:,1),VisualizerStructure.ncst(:,2),'k')
    %plot(VisualizerStructure.PBlong, VisualizerStructure.PBlat, 'b')
    %plot(VisualizerStructure.stateBoundaries.longitude, VisualizerStructure.stateBoundaries.latitude,'k--')
    colorbar
    
    VisualizerStructure.MinLat = minlat;
    VisualizerStructure.MaxLat = maxlat;
    VisualizerStructure.MinLon = minlon;
    VisualizerStructure.MaxLon = maxlon;
    
    % Here we set uicontrols to allow the user to update the view "on the
    % fly"
    % Setting the min/max of the color map
    minamp_s = sprintf('%3.3f',-max(max(abs(abs(AmplitudeMatrixTwoD))))*0.8);
    maxamp_s = sprintf('%3.3f', max(max(abs(abs(AmplitudeMatrixTwoD))))*0.8);
    uicontrol('Style','Text','Parent',fighdls,'Units','Normalized','Position',[0.825 0.82 0.15 0.08],'String','Max amp:','BackgroundColor','White');
    uicontrol('Style','Edit','Parent',fighdls,'Units','Normalized','Position',[0.825 0.8 0.15 0.04],'String',maxamp_s,'Tag','max_color_e');
    uicontrol('Style','Text','Parent',fighdls,'Units','Normalized','Position',[0.825 0.66 0.15 0.08],'String','Min amp:','BackgroundColor','White');
    uicontrol('Style','Edit','Parent',fighdls,'Units','Normalized','Position',[0.825 0.64 0.15 0.04],'String',minamp_s,'Tag','min_color_e');
    
    % popup menu to change the color palette
    cptmapdir = regexprep(which('funclab'),'funclab.m','cptcmap');
    cptmapdir = [cptmapdir,filesep,'cptfiles'];
    D = dir(cptmapdir);
    DD = D(3:end);
    cptfiles = cell(length(DD),1);
    for idx=1:length(DD)
        cptfiles{idx} = DD(idx).name;
    end
    List = cptfiles;
    uicontrol('Parent',fighdls,'Style','Text','Units','Normalized','Position',[0.825 0.50 0.15 0.08],'String','Colormap:','BackgroundColor','White');
    uicontrol('Parent',fighdls,'Style','Popupmenu','Units','Normalized','Position',[0.825 0.43 0.15 0.08],'String',List,'Value',1,'Tag','colormap_popup')
    uicontrol('Parent',fighdls,'Style','Popupmenu','Units','Normalized','Position',[0.825 0.35 0.15 0.08],'String',{'Normal','Reverse'},'Value',1,'Tag','colormap_flip_popup')

    % Add a button to re-draw
    uicontrol('Parent',fighdls,'Style','Pushbutton','Units','Normalized','Position',[0.825 0.25 0.15 0.075],'String','Redraw','Callback',{@update_map_view,ax});

    
    % Export buttons so user can create publication quality GMT maps
    % ... coming soon!
    uicontrol('Parent',fighdls,'Style','Pushbutton','String','Export GMT5','Units','Normalized','Position',[0.825 0.05 0.15 0.075],'Callback',{@not_yet_done_message})
    uicontrol('Parent',fighdls,'Style','Pushbutton','String','Export GMT4','Units','Normalized','Position',[0.825 0.15 0.15 0.075],'Callback',{@not_yet_done_message})
    
    
end

function update_map_view(src,evt,axesToUpdate)
    global VisualizerStructure
    cla(axesToUpdate)

    % unpack
    AmplitudeMatrixTwoD = VisualizerStructure.MapAmplitude;
    longitudeVector = VisualizerStructure.LongitudeVector;
    latitudeVector = VisualizerStructure.LatitudeVector;
    
    % get from control boxes
    % Get new data from tags
    hdls = findobj('Tag','max_color_e');
    caxismax = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','min_color_e');
    caxismin = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','colormap_popup');
    cptmapdir = regexprep(which('funclab'),'funclab.m','cptcmap');
    cptmapdir = [cptmapdir,filesep,'cptfiles'];
    D = dir(cptmapdir);
    DD = D(3:end);
    cptfiles = cell(length(DD),1);
    for idx=1:length(DD)
        cptfiles{idx} = DD(idx).name;
    end
    List = cptfiles;
    TmpColorMap = List{hdls.Value};
    
    hdls = findobj('Tag','colormap_flip_popup');
    colormapFlipFlag = hdls.Value;
    
    % plot
    % Get map limits
    minlat = VisualizerStructure.MinLat;
    maxlat = VisualizerStructure.MaxLat;
    minlon = VisualizerStructure.MinLon;
    maxlon = VisualizerStructure.MaxLon;
    MapProjectionID = VisualizerStructure.MapProjectionID;
    if strcmp(MapProjectionID,'Stereographic') || strcmp(MapProjectionID,'Orthographic') || strcmp(MapProjectionID,'Azimuthal Equal-area') || ...
        strcmp(MapProjectionID,'Azimuthal Equidistant') || strcmp(MapProjectionID,'Gnomonic') || strcmp(MapProjectionID,'Satellite')    
        [~, ~, xdeg] = distaz(minlat, minlon, maxlat, maxlon);
        m_proj(MapProjectionID,'latitude',(minlat + maxlat)/2, 'longitude',(minlon + maxlon) / 2,'radius',xdeg/2);
    else
        m_proj(MapProjectionID,'latitude',[minlat maxlat],'longitude',[minlon maxlon]);
    end
    if colormapFlipFlag == 1
        cmap = cptcmap(TmpColorMap);
    else
        cmap = cptcmap(TmpColorMap,'flip',true);
    end
    colormap(cmap);
    caxis([caxismin caxismax])
    m_pcolor(longitudeVector, latitudeVector, AmplitudeMatrixTwoD);
    %pcolor(longitudeVector, latitudeVector, AmplitudeMatrixTwoD)
    shading interp
    hold on
    m_coast('line','Color','black');
    m_line(VisualizerStructure.PBlong, VisualizerStructure.PBlat,'Color',[0.2 0.2 0.8])
    m_line(VisualizerStructure.stateBoundaries.longitude, VisualizerStructure.stateBoundaries.latitude,'Color','black')
    m_grid('box','on')

%     pcolor(axesToUpdate,longitudeVector, latitudeVector, AmplitudeMatrixTwoD)   
%     shading interp
%     hold on
%     if colormapFlipFlag == 1
%         cmap = cptcmap(TmpColorMap);
%     else
%         cmap = cptcmap(TmpColorMap,'flip',true);
%     end
%     colormap(cmap);
%     caxis([caxismin caxismax])
%     plot(VisualizerStructure.ncst(:,1),VisualizerStructure.ncst(:,2),'k')
%     plot(VisualizerStructure.PBlong, VisualizerStructure.PBlat, 'b')
%     plot(VisualizerStructure.stateBoundaries.longitude, VisualizerStructure.stateBoundaries.latitude,'k--')
    colorbar


end



function not_yet_done_message(src,evt)
    screensize = get(0,'screensize');
    figpos = [screensize(3) / 2 - 200 screensize(4) / 2 - 50 400 100];
    tmpfig = figure('Name','Sorry, that function is not ready yet.','Units','Pixel','Position',figpos, 'DockControls','off','MenuBar','none','NumberTitle','off');
    uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.5 0.6 0.4],'String','Sorry, that function is not ready yet.','FontSize',12);
    waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.4],'String','Shake fist menacingly','FontSize',12,'Callback','gcbf.UserData=1; close');
    waitfor(waitbutton,'Userdata');
end


function cancel_new_view(src,evt,hdls)
    close(hdls)
end

function plot_new_1d_model(src,evt)
    global VisualizerStructure
    screensize = get(0,'screensize');
    figpos = [screensize(3) / 2 - 200 screensize(4) / 2 - 50 400 100];
    tmpfig = figure('Name','Click a point for a 1D plot','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
    uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.5 0.6 0.4],'String','Please click a single point on the map view.','FontSize',12);
    waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.4],'String','Click','FontSize',12,'Callback','gcbf.UserData=1; close');
    waitfor(waitbutton,'Userdata');
    [lon, lat] = ginput(1);
    
    hold on
    scatter(lon, lat, 100, [1, 204/255,0],'filled');

    [x,y] = m_xy2ll(lon, lat);
    lon = x;
    lat = y;
    
    if strcmp(VisualizerStructure.AmplitudeType,'VelocityPerturbation')
        TmpAmplitude = double(permute(VisualizerStructure.Amplitude,[2,1,3]));
        TmpLon = double(permute(VisualizerStructure.Lons,[2,1,3]));
        TmpLat = double(permute(VisualizerStructure.Lats,[2,1,3]));
        TmpDep = double(permute(VisualizerStructure.Depths,[2,1,3]));
    else
        TmpAmplitude = double(permute(VisualizerStructure.Amplitude,[1,2,3]));
        TmpLon = double(permute(VisualizerStructure.Lons,[1,2,3]));
        TmpLat = double(permute(VisualizerStructure.Lats,[1,2,3]));
        TmpDep = double(permute(VisualizerStructure.Depths,[1,2,3]));
    end
              
    dep = double(linspace(min(min(min(VisualizerStructure.Depths))), max(max(max(VisualizerStructure.Depths))), size(VisualizerStructure.Depths,3)));
    
    amp = interp3(TmpLon, TmpLat, TmpDep, TmpAmplitude, lon, lat, dep);
    tmp = zeros(length(dep),1);
    for idx=1:length(dep)
        tmp(idx) = amp(1,1,idx);
    end
    
    figure('Name','1D View','Color','White')
    plot(tmp, dep)
    set(gca,'ydir','reverse')
    ylabel('Depth (km)')
    if strcmp(VisualizerStructure.AmplitudeType,'VelocityPerturbation')
        xlabel('Velocity Perturbation (%)')
    elseif strcmp(VisualizerStructure.AmplitudeType,'RadialRF')
        xlabel('Radial RF')
    elseif strcmp(VisualizerStructure.AmplitudeType,'TransverseRF')
        xlabel('Transverse RF')
    end

end

function update_data_set(src, evt) 
    global VisualizerStructure
    
    
    % Positions from calling figure
    MainPos = [0 0 130 18];
    ParamTitlePos = [2 MainPos(4)-2 80 1.5];
    ParamTextPos1 = [1 0 31 1.75];
    ParamOptionPos1 = [32 0 7 1.75];
    ParamTextPos2 = [41 0 30 1.75];
    ParamOptionPos2 = [72 0 7 1.75];
    ParamTextPos3 = [80 0 30 1.75];
    ParamOptionPos3 = [111 0 7 1.75];
    ProcTitlePos = [80 MainPos(4)-2 50 1.25];
    ProcButtonPos = [95 2 30 3];
    CloseButtonPos = [90 3 30 3];
    % Setting font sizes
    TextFontSize = 0.6; % ORIGINAL
    EditFontSize = 0.5;
    AccentColor = [.6 0 0];

    idx = src.Value;
    str = VisualizerStructure.AvailableModels{idx};
    if strcmp(str,'CCP')
        if VisualizerStructure.HasCCPFlag == 0
            VisualizerStructure.ModelSelected = 0;
            %errordlg('Error, CCP model has not been calculated.');
            d=dialog('Position',[0 0 300 150],'Name','Visualizer Error.','CreateFcn',{@movegui_kce,'center'},'Color','white');
            txt=uicontrol('Parent',d,'Style','Text','Units','Normalized','Position',[.1 .4 .8 .4],'String','CCP Model has not been calculated.','FontSize',16,'BackgroundColor','white');
            btn=uicontrol('Parent',d,'Style','Pushbutton','String','My bad','Units','Normalized','ForegroundColor',[.6 0 0],'Position',[0.25 0.1 0.5 0.25],'Callback','delete(gcf)');
        else
            % Has the user enter a file which was created in the gccp_stack
            % callback
            [filename, pathname, filterindex] = uigetfile('*.mat','Load the CCP mat file',VisualizerStructure.ProjectDirectory);
            if filterindex ~= 0
                load([pathname,filesep,filename]);
                % Prepare a dialog box for the user to specify the geometry
                % for the ccp stacking. 
                MinimumLatitude_s = sprintf('%3.1f',min(Latitudes));
                IncrementLatitude_s = sprintf('1');
                MaximumLatitude_s = sprintf('%3.1f',max(Latitudes));
                MinimumLongitude_s = sprintf('%3.1f',min(Longitudes));
                IncrementLongitude_s = sprintf('1');
                MaximumLongitude_s = sprintf('%3.1f',max(Longitudes));
                MinimumDepth_s = sprintf('%3.1f',min(Depths));
                IncrementDepth_s = sprintf('10');
                MaximumDepth_s = sprintf('%3.1f',max(Depths));
                
                % Setup new figure for entering data.
                GeometryFigure = figure('Name','Enter CCP Geometry','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'DockControls','off','MenuBar','none','NumberTitle','off','color','white');

                %text and edit boxes
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','title_t','String','Set CCP Geometry',...
                    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.85,'HorizontalAlignment','left','BackgroundColor','white');
                ParamTextPos1(2) = 12;
                ParamOptionPos1(2) = 12;
                ParamTextPos2(2) = 12;
                ParamOptionPos2(2) = 12;
                ParamTextPos3(2) = 12;
                ParamOptionPos3(2) = 12;

                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latmin_t','String','Latitude Min. (deg)',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MinimumLatitude_edit','String',MinimumLatitude_s,...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latmax_t','String','Latitude Max. (deg)',...
                    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MaximumLatitude_edit','String',MaximumLatitude_s,...
                    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latinc_t','String','Latitude Inc. (deg)',...
                    'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');               
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','IncrementLatitude_edit','String',IncrementLatitude_s,...
                    'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                
                ParamTextPos1(2) = 9;
                ParamOptionPos1(2) = 9;
                ParamTextPos2(2) = 9;
                ParamOptionPos2(2) = 9;
                ParamTextPos3(2) = 9;
                ParamOptionPos3(2) = 9;
                
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','lonmin_t','String','Longitude Min. (deg)',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MinimumLongitude_edit','String',MinimumLongitude_s,...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','lonmax_t','String','Longitude Max. (deg)',...
                    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MaximumLongitude_edit','String',MaximumLongitude_s,...
                    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','loninc_t','String','Longitude Inc. (deg)',...
                    'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');               
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','IncrementLongitude_edit','String',IncrementLongitude_s,...
                    'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                
                ParamTextPos1(2) = 6;
                ParamOptionPos1(2) = 6;
                ParamTextPos2(2) = 6;
                ParamOptionPos2(2) = 6;
                ParamTextPos3(2) = 6;
                ParamOptionPos3(2) = 6;
                
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depthmin_t','String','Depth Min. (km)',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MinimumDepth_edit','String',MinimumDepth_s,...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depthmax_t','String','Depth Max. (km)',...
                    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MaximumDepth_edit','String',MaximumDepth_s,...
                    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depthinc_t','String','Depth Inc. (km)',...
                    'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');               
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','IncrementDepth_edit','String',IncrementDepth_s,...
                    'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
             
                ParamTextPos1(2) = 3;
                ParamOptionPos1(2) = 3;
                ParamOptionPos1(3) = 25;
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','radial_transverse_t','String','Radial or Transverse:',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','Popupmenu','String',{'Radial RF','Transverse RF'},'Tag','radial_or_transverse_pu','Value',1,'Units','characters',...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');

                % Add buttons for "Save Geometry" and "Cancel"
                uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','savegeometry_pb','String','Save Geometry',...
                    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
                    'Callback',{@get_geometry_params, GeometryFigure, Longitudes, Latitudes, Depths, RRFAmpMean, TRFAmpMean});

                ProcButtonPos(1) = 60;
                uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','cancel_pb','String','Cancel',...
                    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
                    'Callback',{@cancel_new_view,GeometryFigure});

                % Enable other options
                VisualizerStructure.ModelSelected = 1;

                hdls = findobj('Tag','OneDPlotButton');
                set(hdls,'Enable','on');
                hdls = findobj('Tag','NewMapViewPlotButton');
                set(hdls,'Enable','on');
                hdls = findobj('Tag','NewCrossSectionViewPlotButton');
                set(hdls,'Enable','on');
                hdls = findobj('Tag','NewFenceDiagramViewPlotButton');
                set(hdls,'Enable','on');
                
            end
        end        
    elseif strcmp(str,'GCCP')
        if VisualizerStructure.HasGCCPFlag == 0
            VisualizerStructure.ModelSelected = 0;
            %errordlg('Error, GCCP model has not been calculated.');
            d=dialog('Position',[0 0 300 150],'Name','Visualizer Error.','CreateFcn',{@movegui_kce,'center'},'Color','white');
            txt=uicontrol('Parent',d,'Style','Text','Units','Normalized','Position',[.1 .4 .8 .4],'String','GCCP Model has not been calculated.','FontSize',16);
            btn=uicontrol('Parent',d,'Style','Pushbutton','String','My bad','Units','Normalized','ForegroundColor',[.6 0 0],'Position',[0.25 0.1 0.5 0.25],'Callback','delete(gcf)');
        else
            % Has the user enter a file which was created in the gccp_stack
            % callback
            [filename, pathname, filterindex] = uigetfile('*.mat','Load the GCCP mat file',VisualizerStructure.ProjectDirectory);
            if filterindex ~= 0
                load([pathname,filesep,filename]);
                % Prepare a dialog box for the user to specify the geometry
                % for the ccp stacking. 
                MinimumLatitude_s = sprintf('%3.1f',min(Latitudes));
                IncrementLatitude_s = sprintf('1');
                MaximumLatitude_s = sprintf('%3.1f',max(Latitudes));
                MinimumLongitude_s = sprintf('%3.1f',min(Longitudes));
                IncrementLongitude_s = sprintf('1');
                MaximumLongitude_s = sprintf('%3.1f',max(Longitudes));
                MinimumDepth_s = sprintf('%3.1f',min(Depths));
                IncrementDepth_s = sprintf('10');
                MaximumDepth_s = sprintf('%3.1f',max(Depths));
               % Setup new figure for entering data.
                GeometryFigure = figure('Name','Enter GCCP Geometry','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'DockControls','off','MenuBar','none','NumberTitle','off','Color','white');

                %text and edit boxes
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','title_t','String','Set GCCP Geometry',...
                    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.85,'HorizontalAlignment','left','BackgroundColor','white');
                ParamTextPos1(2) = 12;
                ParamOptionPos1(2) = 12;
                ParamTextPos2(2) = 12;
                ParamOptionPos2(2) = 12;
                ParamTextPos3(2) = 12;
                ParamOptionPos3(2) = 12;

                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latmin_t','String','Latitude Min. (deg)',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MinimumLatitude_edit','String',MinimumLatitude_s,...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latmax_t','String','Latitude Max. (deg)',...
                    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MaximumLatitude_edit','String',MaximumLatitude_s,...
                    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latinc_t','String','Latitude Inc. (deg)',...
                    'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');               
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','IncrementLatitude_edit','String',IncrementLatitude_s,...
                    'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                
                ParamTextPos1(2) = 9;
                ParamOptionPos1(2) = 9;
                ParamTextPos2(2) = 9;
                ParamOptionPos2(2) = 9;
                ParamTextPos3(2) = 9;
                ParamOptionPos3(2) = 9;
                
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','lonmin_t','String','Longitude Min. (deg)',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MinimumLongitude_edit','String',MinimumLongitude_s,...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','lonmax_t','String','Longitude Max. (deg)',...
                    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MaximumLongitude_edit','String',MaximumLongitude_s,...
                    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','loninc_t','String','Longitude Inc. (deg)',...
                    'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');               
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','IncrementLongitude_edit','String',IncrementLongitude_s,...
                    'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                
                ParamTextPos1(2) = 6;
                ParamOptionPos1(2) = 6;
                ParamTextPos2(2) = 6;
                ParamOptionPos2(2) = 6;
                ParamTextPos3(2) = 6;
                ParamOptionPos3(2) = 6;
                
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depthmin_t','String','Depth Min. (km)',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MinimumDepth_edit','String',MinimumDepth_s,...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depthmax_t','String','Depth Max. (km)',...
                    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MaximumDepth_edit','String',MaximumDepth_s,...
                    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depthinc_t','String','Depth Inc. (km)',...
                    'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');               
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','IncrementDepth_edit','String',IncrementDepth_s,...
                    'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
             
                ParamTextPos1(2) = 3;
                ParamOptionPos1(2) = 3;
                ParamOptionPos1(3) = 25;
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','radial_transverse_t','String','Radial or Transverse:',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','Popupmenu','String',{'Radial RF','Transverse RF'},'Tag','radial_or_transverse_pu','Value',1,'Units','characters',...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');

                % Add buttons for "Save Geometry" and "Cancel"
                uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','savegeometry_pb','String','Save Geometry',...
                    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
                    'Callback',{@get_geometry_params, GeometryFigure, Longitudes, Latitudes, Depths, RRFAmpMean, TRFAmpMean});

                ProcButtonPos(1) = 60;
                uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','cancel_pb','String','Cancel',...
                    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
                    'Callback',{@cancel_new_view,GeometryFigure});
              
               % Enable visualization elements
                VisualizerStructure.ModelSelected = 1;
                hdls = findobj('Tag','OneDPlotButton');
                set(hdls,'Enable','on');
                hdls = findobj('Tag','NewMapViewPlotButton');
                set(hdls,'Enable','on');
                hdls = findobj('Tag','NewCrossSectionViewPlotButton');
                set(hdls,'Enable','on');
                hdls = findobj('Tag','NewFenceDiagramViewPlotButton');
                set(hdls,'Enable','on');
            end
        end
    elseif strcmp(str,'CCPV2')
        if VisualizerStructure.HasCCPV2Flag == 0
            VisualizerStructure.ModelSelected = 0;
            %errordlg('Error, GCCP model has not been calculated.');
            d=dialog('Position',[0 0 300 150],'Name','Visualizer Error.','CreateFcn',{@movegui_kce,'center'},'Color','White');
            txt=uicontrol('Parent',d,'Style','Text','Units','Normalized','Position',[.1 .4 .8 .4],'String','GCCP Model has not been calculated.','FontSize',16);
            btn=uicontrol('Parent',d,'Style','Pushbutton','String','My bad','Units','Normalized','ForegroundColor',[.6 0 0],'Position',[0.25 0.1 0.5 0.25],'Callback','delete(gcf)');
        else
            % Has the user enter a file which was created in the gccp_stack
            % callback
            [filename, pathname, filterindex] = uigetfile('*.mat','Load the CCPV2 mat file',VisualizerStructure.ProjectDirectory);
            if filterindex ~= 0
                load([pathname,filesep,filename]);
                % Prepare a dialog box for the user to specify the geometry
                % for the ccp stacking. 
                MinimumLatitude_s = sprintf('%3.1f',min(yvector));
                IncrementLatitude_s = sprintf('%3.1f',abs(yvector(2)-yvector(1)));
                MaximumLatitude_s = sprintf('%3.1f',max(yvector));
                MinimumLongitude_s = sprintf('%3.1f',min(xvector));
                IncrementLongitude_s = sprintf('%3.1f',abs(xvector(2)-xvector(1)));
                MaximumLongitude_s = sprintf('%3.1f',max(xvector));
                MinimumDepth_s = sprintf('%3.1f',min(zvector));
                IncrementDepth_s = sprintf('%3.1f',abs(zvector(2)-zvector(1)));
                MaximumDepth_s = sprintf('%3.1f',max(zvector));
               % Setup new figure for entering data.
                GeometryFigure = figure('Name','Enter CCPV2 Geometry','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'DockControls','off','MenuBar','none','NumberTitle','off','color','white');

                %text and edit boxes
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','title_t','String','Set GCCP Geometry',...
                    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.85,'HorizontalAlignment','left','BackgroundColor','white');
                ParamTextPos1(2) = 12;
                ParamOptionPos1(2) = 12;
                ParamTextPos2(2) = 12;
                ParamOptionPos2(2) = 12;
                ParamTextPos3(2) = 12;
                ParamOptionPos3(2) = 12;

                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latmin_t','String','Latitude Min. (deg)',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MinimumLatitude_edit','String',MinimumLatitude_s,...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latmax_t','String','Latitude Max. (deg)',...
                    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MaximumLatitude_edit','String',MaximumLatitude_s,...
                    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latinc_t','String','Latitude Inc. (deg)',...
                    'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');               
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','IncrementLatitude_edit','String',IncrementLatitude_s,...
                    'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                
                ParamTextPos1(2) = 9;
                ParamOptionPos1(2) = 9;
                ParamTextPos2(2) = 9;
                ParamOptionPos2(2) = 9;
                ParamTextPos3(2) = 9;
                ParamOptionPos3(2) = 9;
                
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','lonmin_t','String','Longitude Min. (deg)',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MinimumLongitude_edit','String',MinimumLongitude_s,...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','lonmax_t','String','Longitude Max. (deg)',...
                    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MaximumLongitude_edit','String',MaximumLongitude_s,...
                    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','loninc_t','String','Longitude Inc. (deg)',...
                    'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');               
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','IncrementLongitude_edit','String',IncrementLongitude_s,...
                    'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                
                ParamTextPos1(2) = 6;
                ParamOptionPos1(2) = 6;
                ParamTextPos2(2) = 6;
                ParamOptionPos2(2) = 6;
                ParamTextPos3(2) = 6;
                ParamOptionPos3(2) = 6;
                
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depthmin_t','String','Depth Min. (km)',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MinimumDepth_edit','String',MinimumDepth_s,...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depthmax_t','String','Depth Max. (km)',...
                    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','MaximumDepth_edit','String',MaximumDepth_s,...
                    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depthinc_t','String','Depth Inc. (km)',...
                    'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');               
                uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','IncrementDepth_edit','String',IncrementDepth_s,...
                    'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
             
                ParamTextPos1(2) = 3;
                ParamOptionPos1(2) = 3;
                ParamOptionPos1(3) = 25;
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','radial_transverse_hits_t','String','Component:',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','Popupmenu','String',{'Radial RF','Transverse RF','Hits'},'Tag','radial_transverse_hits_pu','Value',1,'Units','characters',...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');

                ParamTextPos1(2) = 1;
                ParamOptionPos1(2) = 1;
                ParamOptionPos1(3) = 25;
                uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','ray_or_kernel','String','Ray or Gaussian:',...
                    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
                uicontrol ('Parent',GeometryFigure,'Style','Popupmenu','String',{'Ray Theory','Gaussian'},'Tag','ray_or_gaussian_pu','Value',1,'Units','characters',...
                    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');

                
                % Add buttons for "Save Geometry" and "Cancel"
                uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','savegeometry_pb','String','Save Geometry',...
                    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
                    'Callback',{@get_geometry_params_ccpv2, GeometryFigure, xvector, yvector, zvector, CCPHits, CCPStackR, CCPStackT, CCPHitsKernel, CCPStackKernelR, CCPStackKernelT});

                ProcButtonPos(1) = 60;
                uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','cancel_pb','String','Cancel',...
                    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
                    'Callback',{@cancel_new_view,GeometryFigure});
              
               % Enable visualization elements
                VisualizerStructure.ModelSelected = 1;
                hdls = findobj('Tag','OneDPlotButton');
                set(hdls,'Enable','on');
                hdls = findobj('Tag','NewMapViewPlotButton');
                set(hdls,'Enable','on');
                hdls = findobj('Tag','NewCrossSectionViewPlotButton');
                set(hdls,'Enable','on');
                hdls = findobj('Tag','NewFenceDiagramViewPlotButton');
                set(hdls,'Enable','on');
            end
        end
 
        
    elseif strcmp(str(end-3:end),'.vel')
        % If its a 1D model, create a new figure window
        figure('Name',str,'Color','White')
        % Read the data
        fid = fopen(str,'r');
        C=textscan(fid,'%f %f %f'); % depth, vp, vs
        fclose(fid);
        depth = C{1};
        Vp = C{2};
        Vs = C{3};
        plot(Vp,depth,'r')
        hold on
        plot(Vs,depth,'b')
        set(gca,'Ydir','reverse')
        axis([0 12 0 1000])
        ylabel('Depth (km)')
        xlabel('Velocity (km/s)')
        legend('Vp','Vs')
    elseif strcmp(str(end-5:end),'.mat-S') || strcmp(str(end-5:end),'.mat-P')
        % Reads the included tomo model file
        VisualizerStructure.ModelSelected = 1;
        ModelMatFile = str(1:end-2);
        load(ModelMatFile)
        if strcmp(str(end-1:end),'-P')
            VelType = 1;
        else
            VelType = 2;
        end
        VisualizerStructure.Depths = Depths;
        VisualizerStructure.Lats = Lats;
        VisualizerStructure.Lons = Lons;
        if VelType == 1
            VisualizerStructure.Amplitude = ModelP;
        else
            VisualizerStructure.Amplitude = ModelS;
        end
        VisualizerStructure.AmplitudeType = 'VelocityPerturbation';
        % Plot the limits of the model in the map
        cla
        %plot(VisualizerStructure.ncst(:,1),VisualizerStructure.ncst(:,2),'k')
        %hold on
        %plot(VisualizerStructure.PBlong, VisualizerStructure.PBlat, 'b')
        %plot(VisualizerStructure.stateBoundaries.longitude, VisualizerStructure.stateBoundaries.latitude,'k--')
        MinimumLatitude = min(min(min(Lats)));
        MaximumLatitude = max(max(max(Lats)));
        MinimumLongitude = min(min(min(Lons)));
        MaximumLongitude = max(max(max(Lons)));
        
        minlat = MinimumLatitude;
        maxlat = MaximumLatitude;
        minlon = MinimumLongitude;
        maxlon = MaximumLongitude;
        if minlat == -90 && maxlat == 90 && minlon == -180 && maxlon == 180 % Not sure how to deal with global maps!
            MapProjectionID = 'Hammer-Aitoff';
        else
            MapProjectionID = VisualizerStructure.MapProjectionID;
        end
        if strcmp(MapProjectionID,'Stereographic') || strcmp(MapProjectionID,'Orthographic') || strcmp(MapProjectionID,'Azimuthal Equal-area') || ...
            strcmp(MapProjectionID,'Azimuthal Equidistant') || strcmp(MapProjectionID,'Gnomonic') || strcmp(MapProjectionID,'Satellite')    
            [~, ~, xdeg] = distaz(minlat, minlon, maxlat, maxlon);
            m_proj(MapProjectionID,'latitude',(minlat + maxlat)/2, 'longitude',(minlon + maxlon) / 2,'radius',xdeg/2);
        else
            if minlat == -90 && maxlat == 90 && minlon == -180 && maxlon == 180
                m_proj(MapProjectionID,'latitude',[-85 85],'longitude',[-180 180]);
            else
                m_proj(MapProjectionID,'latitude',[minlat maxlat],'longitude',[minlon maxlon]);
            end
        end
        m_coast('line','Color',[0 0 0]);
        m_line(VisualizerStructure.PBlong, VisualizerStructure.PBlat,'Color',[0.2 0.2 0.8]);
        m_line(VisualizerStructure.stateBoundaries.longitude, VisualizerStructure.stateBoundaries.latitude,'Color',[0 0 0]);
        
        m_patch([MinimumLongitude MinimumLongitude MaximumLongitude MaximumLongitude MinimumLongitude],...
            [MinimumLatitude MaximumLatitude MaximumLatitude MinimumLatitude MinimumLatitude],...
            [153/255 0 0])
        m_grid('box','on')
        
        %axis([MinimumLongitude-1 MaximumLongitude+1 MinimumLatitude-1 MaximumLatitude+1])
        alpha(0.5)
        
        hdls = findobj('Tag','OneDPlotButton');
        set(hdls,'Enable','on');
        hdls = findobj('Tag','NewMapViewPlotButton');
        set(hdls,'Enable','on');
        hdls = findobj('Tag','NewCrossSectionViewPlotButton');
        set(hdls,'Enable','on');
        hdls = findobj('Tag','NewFenceDiagramViewPlotButton');
        set(hdls,'Enable','on');
    end 
end


function get_geometry_params_ccpv2(src,evt, fighdls, xorig, yorig, zorig, CCPHits, CCPStackR, CCPStackT, CCPHitsKernel, CCPStackKernelR, CCPStackKernelT)
    global VisualizerStructure
    
    TmpWaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',TmpWaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait while computing the CCP stacking geometry...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    
    % Normalize by hit count first
    for ix=1:length(xorig)
        for iy=1:length(yorig)
            for iz=1:length(zorig)
                if CCPHits(ix,iy,iz) >= 1
                    CCPStackR(ix,iy,iz) = CCPStackR(ix,iy,iz) / CCPHits(ix,iy,iz);
                    CCPStackT(ix,iy,iz) = CCPStackT(ix,iy,iz) / CCPHits(ix,iy,iz);
                else
                    CCPStackR(ix,iy,iz) = 0.0;
                    CCPStackT(ix,iy,iz) = 0.0;
                end
                if CCPHitsKernel(ix,iy,iz) >= 1
                    CCPStackKernelR(ix,iy,iz) = CCPStackKernelR(ix,iy,iz) / CCPHitsKernel(ix,iy,iz);
                    CCPStackKernelT(ix,iy,iz) = CCPStackKernelT(ix,iy,iz) / CCPHitsKernel(ix,iy,iz);
                else
                    CCPStackKernelR(ix,iy,iz) = 0.0;
                    CCPStackKernelT(ix,iy,iz) = 0.0;
                end
            end
        end
    end

    % peak-to-peak normalization for each column in depth. 
    CCPStackTempR = CCPStackR;
    CCPStackTempT = CCPStackT;
    for ix=1:length(xorig)
        for iy=1:length(yorig)
            % Get peak at this point
            peakAmpR = -9001;
            peakAmpT = -9001;
            for iz=1:length(zorig)
                if abs(CCPStackTempR(ix,iy,iz)) > peakAmpR
                    peakAmpR = abs(CCPStackTempR(ix,iy,iz));
                end
                if abs(CCPStackTempT(ix,iy,iz)) > peakAmpT
                    peakAmpT = abs(CCPStackTempT(ix,iy,iz));
                end
            end
            % Now do normalization
            if peakAmpR > 0.001
                for iz=1:length(zorig)
                    CCPStackR(ix,iy,iz) = CCPStackTempR(ix,iy,iz) / peakAmpR;
                    CCPStackT(ix,iy,iz) = CCPStackTempT(ix,iy,iz) / peakAmpT;
    %                CCPStack(ix, iy, iz) = CCPStackTemp(ix, iy, iz);
                end
            else
                CCPStackR(ix,iy,iz) = 0.0;
                CCPStackT(ix,iy,iz) = 0.0;
            end
        end
    end

    % Repeat for FF
    CCPStackTempR = CCPStackKernelR;
    CCPStackTempT = CCPStackKernelT;
    for ix=1:length(xorig)
        for iy=1:length(yorig)
            % Get peak at this point
            peakAmpR = -9001;
            peakAmpT = -9001;
            for iz=1:length(zorig)
                if abs(CCPStackTempR(ix,iy,iz)) > peakAmpR
                    peakAmpR = abs(CCPStackTempR(ix,iy,iz));
                end
                if abs(CCPStackTempT(ix,iy,iz)) > peakAmpT
                    peakAmpT = abs(CCPStackTempT(ix,iy,iz));
                end
            end
            % Now do normalization
            if peakAmpR > 0.001
                for iz=1:length(zorig)
                    CCPStackKernelR(ix,iy,iz) = CCPStackTempR(ix,iy,iz) / peakAmpR;
                    CCPStackKernelT(ix,iy,iz) = CCPStackTempT(ix,iy,iz) / peakAmpT;
    %                CCPStack(ix, iy, iz) = CCPStackTemp(ix, iy, iz);
                end
            else
                CCPStackKernelR(ix,iy,iz) = 0.0;
                CCPStackKernelT(ix,iy,iz) = 0.0;
            end
        end
    end  
    
    % Get latitude info
    hdls = findobj('Tag','MinimumLatitude_edit');
    MinimumLatitude = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','IncrementLatitude_edit');
    IncrementLatitude = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','MaximumLatitude_edit');
    MaximumLatitude = sscanf(hdls.String,'%f');
    
    % Get longitude info
    hdls = findobj('Tag','MinimumLongitude_edit');
    MinimumLongitude = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','IncrementLongitude_edit');
    IncrementLongitude = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','MaximumLongitude_edit');
    MaximumLongitude = sscanf(hdls.String,'%f');
    
    % Get depth info
    hdls = findobj('Tag','MinimumDepth_edit');
    MinimumDepth = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','IncrementDepth_edit');
    IncrementDepth = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','MaximumDepth_edit');
    MaximumDepth = sscanf(hdls.String,'%f');
    
    % Get radial or transverse
    hdls = findobj('Tag','radial_transverse_hits_pu');
    if hdls.Value == 1
        RFType = 'Radial';
    elseif hdls.Value == 2
        RFType = 'Transverse';
    else
        RFType = 'Hits';
    end
    
    % Get ray theory or gaussian
    hdls = findobj('Tag','ray_or_gaussian_pu');
    if hdls.Value == 1
        RGChoice = 'Ray';
    else
        RGChoice = 'Gaussian';
    end
    
    [LonsTmp, LatsTmp, DepthsTmp] = meshgrid(xorig, yorig, zorig);

    % Make vectors for the geometry
    xvector = MinimumLongitude:IncrementLongitude:MaximumLongitude;
    yvector = MinimumLatitude:IncrementLatitude:MaximumLatitude;
    zvector = MinimumDepth:IncrementDepth:MaximumDepth;
    
    % And mesh them
    [Lons, Lats, Depths] = meshgrid(xvector, yvector, zvector);

    if strcmp(RGChoice,'Ray')
        if strcmp(RFType,'Radial')
            CCPTmp = permute(CCPStackR,[2,1,3]);
        elseif strcmp(RFType,'Transverse')
            CCPTmp = permute(CCPStackT,[2,1,3]);
        else
            CCPTmp = permute(CCPHits,[2,1,3]);
        end
    else
        if strcmp(RFType,'Radial')
            CCPTmp = permute(CCPStackKernelR,[2,1,3]);
        elseif strcmp(RFType,'Transverse')
            CCPTmp = permute(CCPStackKernelT,[2,1,3]);
        else
            CCPTmp = permute(CCPHitsKernel,[2,1,3]);
        end
    end
    CCPStack = interp3(LonsTmp, LatsTmp, DepthsTmp, CCPTmp, Lons, Lats, Depths);
    
    
    % Put into the global structure
    VisualizerStructure.Amplitude = CCPStack;
    VisualizerStructure.Depths = Depths;
    VisualizerStructure.Lats = Lats;
    VisualizerStructure.Lons = Lons;
    if strcmp(RFType,'Radial')
        VisualizerStructure.AmplitudeType = 'RadialRF';
    elseif strcmp(RFType,'Transverse')
        VisualizerStructure.AmplitudeType = 'TransverseRF';
    else
        VisualizerStructure.AmplitudeType = 'Hit Count';
    end
    
    % Close the dialog so we can replot the geometry
    close(fighdls)
    close(TmpWaitGui)
    
    % Plot the limits of the model in the map
    cla
    MinimumLatitude = min(min(min(Lats)));
    MaximumLatitude = max(max(max(Lats)));
    MinimumLongitude = min(min(min(Lons)));
    MaximumLongitude = max(max(max(Lons)));

    minlat = MinimumLatitude;
    maxlat = MaximumLatitude;
    minlon = MinimumLongitude;
    maxlon = MaximumLongitude;
    if minlat == -90 & maxlat == 90 & minlon == -180 & maxlon == 180 % Not sure how to deal with global maps!
        MapProjectionID = 'Hammer-Aitoff';
    else
        MapProjectionID = VisualizerStructure.MapProjectionID;
    end
    if strcmp(MapProjectionID,'Stereographic') || strcmp(MapProjectionID,'Orthographic') || strcmp(MapProjectionID,'Azimuthal Equal-area') || ...
        strcmp(MapProjectionID,'Azimuthal Equidistant') || strcmp(MapProjectionID,'Gnomonic') || strcmp(MapProjectionID,'Satellite')    
        [~, ~, xdeg] = distaz(minlat, minlon, maxlat, maxlon);
        m_proj(MapProjectionID,'latitude',(minlat + maxlat)/2, 'longitude',(minlon + maxlon) / 2,'radius',xdeg/2);
    else
        if minlat == -90 && maxlat == 90 && minlon == -180 && maxlon == 180
            m_proj(MapProjectionID,'latitude',[-85 85],'longitude',[-180 180]);
        else
            m_proj(MapProjectionID,'latitude',[minlat maxlat],'longitude',[minlon maxlon]);
        end
    end
    m_coast('line','Color',[0 0 0]);
    m_line(VisualizerStructure.PBlong, VisualizerStructure.PBlat,'Color',[0.2 0.2 0.8]);
    m_line(VisualizerStructure.stateBoundaries.longitude, VisualizerStructure.stateBoundaries.latitude,'Color',[0 0 0]);

    %boxlon = [MinimumLongitude * ones(1,round(MaximumLatitude-MinimumLatitude+1)) MinimumLongitude:MaximumLongitude MaximumLongitude * ones(1,round(MaximumLatitude-MinimumLatitude+1)) MaximumLongitude:-1:MinimumLongitude];
    %boxlat = [MinimumLatitude:MaximumLatitude MaximumLatitude * ones(1,round(MaximumLongitude-MinimumLongitude)) MaximumLatitude:-1:MinimumLatitude MinimumLatitude * ones(1,round(MaximumLongitude-MinimumLongitude))];
    boxlon = [MinimumLongitude * ones(1,100) linspace(MinimumLongitude, MaximumLongitude,100) MaximumLongitude * ones(1,100) linspace(MaximumLongitude, MinimumLongitude,100)];
    boxlat = [linspace(MinimumLatitude, MaximumLatitude, 100) MaximumLatitude * ones(1,100) linspace(MaximumLatitude, MinimumLatitude, 100) MinimumLatitude * ones(1,100)];
    %    m_patch([MinimumLongitude MinimumLongitude MaximumLongitude MaximumLongitude MinimumLongitude],...
%        [MinimumLatitude MaximumLatitude MaximumLatitude MinimumLatitude MinimumLatitude],...
%        [153/255 0 0])
    m_patch(boxlon,...
        boxlat,...
        [153/255 0 0])

    m_grid('box','on')
    %axis([MinimumLongitude-1 MaximumLongitude+1 MinimumLatitude-1 MaximumLatitude+1])
    alpha(0.5)
    hold on
    %EQloc = [140.493 27.831 677.6];
    %m_plot(EQloc(1), EQloc(2),'bd')
 

end

function get_geometry_params(src, evt, fighdls,lon, lat, dep, rrf, trf)
    global VisualizerStructure
    
    TmpWaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',TmpWaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait while computing the CCP stacking geometry...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    
    % Get latitude info
    hdls = findobj('Tag','MinimumLatitude_edit');
    MinimumLatitude = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','IncrementLatitude_edit');
    IncrementLatitude = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','MaximumLatitude_edit');
    MaximumLatitude = sscanf(hdls.String,'%f');
    
    % Get longitude info
    hdls = findobj('Tag','MinimumLongitude_edit');
    MinimumLongitude = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','IncrementLongitude_edit');
    IncrementLongitude = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','MaximumLongitude_edit');
    MaximumLongitude = sscanf(hdls.String,'%f');
    
    % Get depth info
    hdls = findobj('Tag','MinimumDepth_edit');
    MinimumDepth = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','IncrementDepth_edit');
    IncrementDepth = sscanf(hdls.String,'%f');
    hdls = findobj('Tag','MaximumDepth_edit');
    MaximumDepth = sscanf(hdls.String,'%f');
    
    % Get radial or transverse
    hdls = findobj('Tag','radial_or_transverse_pu');
    if hdls.Value == 1
        RFType = 'Radial';
    else
        RFType = 'Transverse';
    end

    % Make vectors for the geometry
    xvector = MinimumLongitude:IncrementLongitude:MaximumLongitude;
    yvector = MinimumLatitude:IncrementLatitude:MaximumLatitude;
    zvector = MinimumDepth:IncrementDepth:MaximumDepth;
    
    % And mesh them
    [Lons, Lats, Depths] = meshgrid(xvector, yvector, zvector);

    % Make a function for the CCP
    if strcmp(RFType,'Radial')
        idx = find(isnan(rrf));
        lon(idx) = [];
        lat(idx) = [];
        dep(idx) = [];
        rrf(idx) = [];
        CCPFunction = scatteredInterpolant(lon, lat, dep, rrf);
    else
        idx = find(isnan(trf));
        lon(idx) = [];
        lat(idx) = [];
        dep(idx) = [];
        trf(idx) = [];
        CCPFunction = scatteredInterpolant(lon, lat, dep, trf);
    end
    
    % Evaluate on desired geometry
    CCPStack = CCPFunction(Lons, Lats, Depths);
    
    % Put into the global structure
    VisualizerStructure.Amplitude = CCPStack;
    VisualizerStructure.Depths = Depths;
    VisualizerStructure.Lats = Lats;
    VisualizerStructure.Lons = Lons;
    if strcmp(RFType,'Radial')
        VisualizerStructure.AmplitudeType = 'RadialRF';
    else
        VisualizerStructure.AmplitudeType = 'TransverseRF';
    end
    
    % Close the dialog so we can replot the geometry
    close(fighdls)
    close(TmpWaitGui)
    
    % Plot the limits of the model in the map
    cla
    MinimumLatitude = min(min(min(Lats)));
    MaximumLatitude = max(max(max(Lats)));
    MinimumLongitude = min(min(min(Lons)));
    MaximumLongitude = max(max(max(Lons)));

    minlat = MinimumLatitude;
    maxlat = MaximumLatitude;
    minlon = MinimumLongitude;
    maxlon = MaximumLongitude;
    if minlat == -90 && maxlat == 90 && minlon == -180 && maxlon == 180 % Not sure how to deal with global maps!
        MapProjectionID = 'Hammer-Aitoff';
    else
        MapProjectionID = VisualizerStructure.MapProjectionID;
    end
    if strcmp(MapProjectionID,'Stereographic') || strcmp(MapProjectionID,'Orthographic') || strcmp(MapProjectionID,'Azimuthal Equal-area') || ...
        strcmp(MapProjectionID,'Azimuthal Equidistant') || strcmp(MapProjectionID,'Gnomonic') || strcmp(MapProjectionID,'Satellite')    
        [~, ~, xdeg] = distaz(minlat, minlon, maxlat, maxlon);
        m_proj(MapProjectionID,'latitude',(minlat + maxlat)/2, 'longitude',(minlon + maxlon) / 2,'radius',xdeg/2);
    else
        if minlat == -90 && maxlat == 90 && minlon == -180 && maxlon == 180
            m_proj(MapProjectionID,'latitude',[-85 85],'longitude',[-180 180]);
        else
            m_proj(MapProjectionID,'latitude',[minlat maxlat],'longitude',[minlon maxlon]);
        end
    end
    m_coast('line','Color',[0 0 0]);
    m_line(VisualizerStructure.PBlong, VisualizerStructure.PBlat,'Color',[0.2 0.2 0.8]);
    m_line(VisualizerStructure.stateBoundaries.longitude, VisualizerStructure.stateBoundaries.latitude,'Color',[0 0 0]);
    
    %boxlon = [MinimumLongitude * ones(1,round(MaximumLatitude-MinimumLatitude+1)) MinimumLongitude:MaximumLongitude MaximumLongitude * ones(1,round(MaximumLatitude-MinimumLatitude+1)) MaximumLongitude:-1:MinimumLongitude];
    %boxlat = [MinimumLatitude:MaximumLatitude MaximumLatitude * ones(1,round(MaximumLongitude-MinimumLongitude)) MaximumLatitude:-1:MinimumLatitude MinimumLatitude * ones(1,round(MaximumLongitude-MinimumLongitude))];
    boxlon = [MinimumLongitude * ones(1,100) linspace(MinimumLongitude, MaximumLongitude,100) MaximumLongitude * ones(1,100) linspace(MaximumLongitude, MinimumLongitude,100)];
    boxlat = [linspace(MinimumLatitude, MaximumLatitude, 100) MaximumLatitude * ones(1,100) linspace(MaximumLatitude, MinimumLatitude, 100) MinimumLatitude * ones(1,100)];
    m_patch(boxlon,...
        boxlat,...
        [153/255 0 0])
%     m_patch([MinimumLongitude MinimumLongitude MaximumLongitude MaximumLongitude MinimumLongitude],...
%         [MinimumLatitude MaximumLatitude MaximumLatitude MinimumLatitude MinimumLatitude],...
%         [153/255 0 0])
%     m_grid('box','on')
    %axis([MinimumLongitude-1 MaximumLongitude+1 MinimumLatitude-1 MaximumLatitude+1])
    alpha(0.5)
    %EQloc = [140.493 27.831 677.6];
    %m_plot(EQloc(1), EQloc(2),'bd')
    
end



