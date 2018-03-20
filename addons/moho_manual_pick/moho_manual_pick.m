function moho_manual_pick(MainGui)
%% moho_manual_pick
%   Funclab add on to facilitate picking a moho manually from receiver
%   functions that have already been mapped into depth. The interface is
%   functionally similar to the visualizer, but the user tools are for
%   picking an interface rather than just visual plots. 
%   This is a bit iffy because it can only be done on data that has been
%   mapped to depth, which requires some 1-D (or 3-D) velocity model. 
%   Anyway, the tools we need to include are a station stack where the user
%   can choose one station at a time to pick, "RF cross-sections" where the
%   user selects a line for the cross-section, then picks the moho at a
%   series of depth-mapped stations along that line, a "RF Ray
%   cross-section" which is similar to the RF cross-section, but plots the
%   projected results of depth stacked RFs into the section, accounting for
%   moveout and backazimuth, and CCP volume tools for either a 1D option or
%   cross sections through the CCP. 
%   The results from each method are kept in separate variables and then an
%   aggregator tool can be used to combine them, particularily smoothing,
%   clustering, bootstrapping, etc... (make accessible via uimenu)

%   Author: Robert W. Porritt
%   Date Created: 11/01/2016
%   Last Updated: 12/08/2016

% Update 12/08/2016:
% Changed ray diagram code to 2D CCP. Backend organization is unchanged,
% but algorithm for making plots is easier to handle.

% Update 12/26/2016:
% Changed the about boxes to edit boxes to allow scrolling

% Update 05/05/2017:
% Added button to purge picks and option to load a Moho Function to guide
% picks. Also added a new column to each pick for logical 1 (active) or 0
% (inactive)

%%
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
SetManagementCell = evalin('base','SetManagementCell');
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

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Initialize a global structure to be used for passing around information
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
global PickingStructure
PickingStructure.ModelSelected = 0; % Need to choose a model before any plots will work
PickingStructure.ncst = ncst;
PickingStructure.PBlong = PBlong;
PickingStructure.PBlat = PBlat;
PickingStructure.HasCCPV2Flag = 0;
PickingStructure.HasRayInfoFlag = 0;
PickingStructure.stateBoundaries = stateBoundaries;
PickingStructure.ProjectDirectory = ProjectDirectory;
PickingStructure.ProjectFile = ProjectFile;
if exist('RecordMetadataStrings','var')
    PickingStructure.RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
    PickingStructure.RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
end
if exist('CCPV2MetadataCell','var')
    %VisualizerStructure.CCPV2File = CCPV2MetadataCell{CurrentSubsetIndex,2};
    CCPV2MetadataStrings = CCPV2MetadataCell{CurrentSubsetIndex};
    PickingStructure.CCPV2File = CCPV2MetadataStrings{2};
    PickingStructure.HasCCPV2Flag = 1;
end
if exist('ThreeDRayInfoFile','var')
    PickingStructure.RayInfoFile = ThreeDRayInfoFile;
    PickingStructure.HasRayInfoFlag = 1;
end
PickingStructure.Colormap = FuncLabPreferences{19};
PickingStructure.ColormapFlipped = FuncLabPreferences{20};
PickingStructure.MinimumLatitude = sscanf(FuncLabPreferences{14},'%f');
PickingStructure.MaximumLatitude = sscanf(FuncLabPreferences{13},'%f');
PickingStructure.MinimumLongitude = sscanf(FuncLabPreferences{15},'%f');
PickingStructure.MaximumLongitude = sscanf(FuncLabPreferences{16},'%f');

PickingStructure.Background = false;
PickingStructure.InitialThickness = 35; % default crustal thickness


%--------------------------------------------------------------------------
% Check if various picking tools have been run and then set flag for
% plotability
%--------------------------------------------------------------------------
all_source_moho_enable = 'off';
aggregator_enable = 'off';
purge_all_picks_enable = 'off';
purge_station_depth_stack_picks_enable = 'off';
purge_rf_cross_section_picks_enable = 'off';
purge_ccp_cross_section_picks_enable = 'off';
purge_1d_ccp_picks_enable = 'off';
purge_ray_diagram_picks_enable = 'off';
try
    ManualPickMohoCCPoneDArray=evalin('base','ManualPickMohoCCPoneDArray');
catch
    ManualPickMohoCCPoneDArray = [];
end
if isempty(ManualPickMohoCCPoneDArray)
    ccp_oned_plot_enable = 'off';
else
    ccp_oned_plot_enable = 'on';
    purge_all_picks_enable = 'on';
    purge_1d_ccp_picks_enable = 'on';
    if strcmp(all_source_moho_enable,'off')
        all_source_moho_enable = 'on';
        aggregator_enable = 'on';
    end
end

try
    ManualPickMohoCCPCrossSectionArray=evalin('base','ManualPickMohoCCPCrossSectionArray');
catch
    ManualPickMohoCCPCrossSectionArray=[];
end
if isempty(ManualPickMohoCCPCrossSectionArray)
    ccp_cross_section_plot_enable = 'off';
else
    ccp_cross_section_plot_enable = 'on';
    purge_all_picks_enable = 'on';
    purge_ccp_cross_section_picks_enable = 'on';
    if strcmp(all_source_moho_enable,'off')
        all_source_moho_enable = 'on';
        aggregator_enable = 'on';
    end
end

try
    ManualPickMohoRayCrossSectionArray=evalin('base','ManualPickMohoRayCrossSectionArray');
catch
    ManualPickMohoRayCrossSectionArray=[];
end
if isempty(ManualPickMohoRayCrossSectionArray)
    ray_cross_section_plot_enable = 'off';
else
    ray_cross_section_plot_enable = 'on';
    purge_all_picks_enable = 'on';
    purge_ray_diagram_picks_enable = 'on';
    if strcmp(all_source_moho_enable,'off')
        all_source_moho_enable = 'on';
        aggregator_enable = 'on';
    end
end

try
    ManualPickMohoRFCrossSectionArray=evalin('base','ManualPickMohoRFCrossSectionArray');
catch
    ManualPickMohoRFCrossSectionArray=[];
end
if isempty(ManualPickMohoRFCrossSectionArray)
    rf_cross_section_plot_enable = 'off';
else
    rf_cross_section_plot_enable = 'on';
    purge_all_picks_enable = 'on';
    purge_rf_cross_section_picks_enable = 'on';
    if strcmp(all_source_moho_enable,'off')
        all_source_moho_enable = 'on';
        aggregator_enable = 'on';
    end
end

try
    ManualPickMohoStationStackCell=evalin('base','ManualPickMohoStationStackCell');
catch
    ManualPickMohoStationStackCell=[];
end
if isempty(ManualPickMohoStationStackCell)
    station_stack_plot_enable = 'off';
else
    station_stack_plot_enable = 'on';
    purge_all_picks_enable = 'on';
    purge_station_depth_stack_picks_enable = 'on';
    if strcmp(all_source_moho_enable,'off')
        all_source_moho_enable = 'on';
        aggregator_enable = 'on';
    end
end

%--------------------------------------------------------------------------
% Setup dimensions of the GUI
%--------------------------------------------------------------------------
MainPos = [0 0 130 37];

%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
PickerGui = dialog('Name','Manual Moho Picking','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white','NextPlot','add');

% Add menu items
MHelp = uimenu(PickerGui,'Label','Help');
uimenu(MHelp,'Label','About','Tag','moho_manual_pick_about_m','Enable','on','Callback',{@moho_manual_pick_about_callback});
uimenu(MHelp,'Label','About: station depth stack','Tag','moho_manual_pick_about_station_depth_stack_m','Enable','on','Callback',{@moho_manual_pick_about_station_depth_stack_callback});
uimenu(MHelp,'Label','About: RF cross section','Tag','moho_manual_pick_about_rf_cross_section_m','Enable','on','Callback',{@moho_manual_pick_about_rf_cross_section});
uimenu(MHelp,'Label','About: 2D CCP cross section','Tag','moho_manual_pick_about_ray_diagram_cross_section_m','Enable','on','Callback',{@moho_manual_pick_about_ray_diagram_cross_section_callback});
uimenu(MHelp,'Label','About: 1D depth profile','Tag','moho_manual_pick_about_one_d_depth_profile_m','Enable','on','Callback',{@moho_manual_pick_about_one_d_depth_profile_callback});
uimenu(MHelp,'Label','About: CCP Cross section','Tag','moho_manual_pick_about_ccp_cross_section_m','Enable','on','Callback',{@moho_manual_pick_about_ccp_cross_section_callback});
uimenu(MHelp,'Label','About: Purge','Tag','moho_manual_pick_about_purge_m','Enable','on','Callback',{@moho_manual_pick_about_purge_callback});
uimenu(MHelp,'Label','About: Load Background','Tag','moho_manual_pick_about_load_initial_m','Enable','on','Callback',{@moho_manual_pick_about_load_initial_callback});
uimenu(MHelp,'Label','Warning!','Tag','moho_manual_pick_warning_m','Separator','on','Enable','on','Callback',{@moho_manual_pick_warning_callback});
MAggregate = uimenu(PickerGui,'Label','Aggregator');
uimenu(MAggregate,'Label','Aggregate thickness estimates','Tag','moho_manual_pick_aggregator','Enable',aggregator_enable,'Callback',{@aggregator_callback});
uimenu(MAggregate,'Label','About','Tag','moho_manual_pick_aggregator_help','Enable','on','Callback',{@aggregator_help_callback});
MPlot = uimenu(PickerGui,'Label','Plot');
uimenu(MPlot,'Label','Plot moho from station depth stacks','Tag','plot_moho_station_stack_m','Enable',station_stack_plot_enable,'Callback',{@plot_station_stack_moho_callback});
uimenu(MPlot,'Label','Plot moho from RF cross sections','Tag','plot_moho_rf_cross_sections_m','Enable',rf_cross_section_plot_enable,'Callback',{@plot_rf_cross_section_moho_callback});
uimenu(MPlot,'Label','Plot moho from 2D CCP cross sections','Tag','plot_moho_ray_diagram_cross_sections_m','Enable',ray_cross_section_plot_enable,'Callback',{@plot_ray_diagram_cross_section_moho_callback});
uimenu(MPlot,'Label','Plot moho from 1D CCP','Tag','plot_moho_one_d_ccp_m','Enable',ccp_oned_plot_enable,'Callback',{@plot_ccp_oned_moho_callback});
uimenu(MPlot,'Label','Plot moho from CCP cross sections','Tag','plot_moho_ccp_cross_sections_m','Enable',ccp_cross_section_plot_enable,'Callback',{@plot_ccp_cross_section_moho_callback});
uimenu(MPlot,'Label','Plot moho from all sources','Tag','plot_moho_all_sources_m','Enable',all_source_moho_enable,'Separator','on','Callback',{@plot_all_picks_moho_callback});
MExport = uimenu(PickerGui,'Label','Export');
uimenu(MExport,'Label','Export moho from station depth stacks','Tag','export_moho_station_stack_m','Enable',station_stack_plot_enable,'Callback',{@export_station_stack_picks_moho_callback});
uimenu(MExport,'Label','Export moho from RF cross sections','Tag','export_moho_rf_cross_sections_m','Enable',rf_cross_section_plot_enable,'Callback',{@export_rf_cross_section_picks_moho_callback});
uimenu(MExport,'Label','Export moho from 2D CCP cross sections','Tag','export_moho_ray_diagram_cross_sections_m','Enable',ray_cross_section_plot_enable,'Callback',{@export_ray_diagram_picks_moho_callback});
uimenu(MExport,'Label','Export moho from 1D CCP','Tag','export_moho_one_d_ccp_m','Enable',ccp_oned_plot_enable,'Callback',{@export_ccp_oned_moho_callback});
uimenu(MExport,'Label','Export moho from CCP cross sections','Tag','export_moho_ccp_cross_sections_m','Enable',ccp_cross_section_plot_enable,'Callback',{@export_ccp_cross_section_moho_callback});
uimenu(MExport,'Label','Export moho from all sources','Tag','export_moho_all_sources_m','Enable',all_source_moho_enable,'Separator','on','Callback',{@export_all_picks_moho_callback});
MPurge = uimenu(PickerGui,'Label','Purge Picks');
uimenu(MPurge,'Label','Purge all','Tag','purge_all_picks_m','Enable',purge_all_picks_enable,'Callback',{@purge_all_picks_callback});
uimenu(MPurge,'Label','Purge station depth stack picks','Tag','purge_station_depth_stack_picks_m','Enable',purge_station_depth_stack_picks_enable,'Callback',{@purge_station_depth_stack_picks_callback});
uimenu(MPurge,'Label','Purge RF cross section picks','Tag','purge_rf_cross_section_picks_m','Enable',purge_rf_cross_section_picks_enable,'Callback',{@purge_rf_cross_section_picks_callback});
uimenu(MPurge,'Label','Purge 2D CCP cross section picks','Tag','purge_ray_diagram_picks_m','Enable',purge_ray_diagram_picks_enable,'Callback',{@purge_ray_diagram_picks_callback});
uimenu(MPurge,'Label','Purge 1D CCP picks','Tag','purge_1d_ccp_picks_m','Enable',purge_1d_ccp_picks_enable,'Callback',{@purge_1d_ccp_picks_callback});
uimenu(MPurge,'Label','Purge CCP cross section picks','Tag','purge_ccp_cross_section_picks_m','Enable',purge_ccp_cross_section_picks_enable,'Callback',{@purge_ccp_cross_section_picks_callback});
uimenu(MPurge,'Label','Purge by polygon','Tag','purge_picks_by_polygon_m','Separator','on','Enable',purge_all_picks_enable,'Callback',{@purge_picks_by_polygon_callback});
MLoadInitial = uimenu(PickerGui,'Label','Load Background');
uimenu(MLoadInitial,'Label','Load ascii xyz file','Tag','load_ascii_xyz_file_m','Enable','on','Callback',{@load_initial_ascii_xyz_callback});
uimenu(MLoadInitial,'Label','Load scattedInterpolant','Tag','load_scatteredInterpolant_file_m','Enable','on','Callback',{@load_initial_scatteredInterpolant_callback});


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
PickingStructure.MapProjectionID = MapProjectionID;

% Create a map view axis
MapViewPanel = uipanel('Title','Map view','FontSize',12,'BackgroundColor','White','Units','Normalized','Position',[0.01 0.1 0.79 0.85]);
MapViewAxesHandles = axes('Parent',MapViewPanel,'Units','Normalized','Position',[.05 .05 .9 .9]);
minlon = floor(PickingStructure.MinimumLongitude);
maxlon = ceil(PickingStructure.MaximumLongitude);
minlat = floor(PickingStructure.MinimumLatitude);
maxlat = ceil(PickingStructure.MaximumLatitude);
m_proj(MapProjection,'latitude',[minlat maxlat], 'longitude', [minlon maxlon]);
%m_proj('Hammer-Aitoff','latitude',[-90 90],'longitude',[-180 180]);

% Makes the initial plot view - global coast lines and a shaded box for the
% CCP image volume
%plot(ncst(:,1),ncst(:,2),'k')
hold on
%m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
m_coast('patch',[.9 .9 .9],'edgecolor','black');
m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
%axis([-180 180 -90 90])
%m_grid('xtick',floor((maxlon-minlon)/10),'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
m_grid('xtick',4,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');


OnColor = [.3 .3 .3];
OffColor = [1 .5 .5];
CurrentColor = [ 1 .7 0];
SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
SetOffColor = abs(cross(SetOnColor,OnColor));
% Add the stations
StationLocations = unique([PickingStructure.RecordMetadataDoubles(:,10), PickingStructure.RecordMetadataDoubles(:,11)],'rows');
m_line(StationLocations(:,2),StationLocations(:,1),'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)

%% Add the picking UI elements
uicontrol('Style','Text','Parent',PickerGui,'Units','Normalized','Position',[0.82 0.79 0.15 0.15],'String','Station depth stack:','BackgroundColor','White')
AvailableStations = unique(RecordMetadataStrings(:,2));
uicontrol('Style','popupmenu','Parent',PickerGui,'Units','Normalized','Position',[0.82 0.75 0.15 0.15],'String',AvailableStations,'Value',1,'Callback',{@manual_pick_station_stack_callback})

% RF cross section
uicontrol('Style','Pushbutton','Parent',PickerGui,'Units','Normalized','Position',[0.82 0.7 0.15 0.1],'String','RF cross section','Callback',{@manual_pick_rf_cross_section_callback});

% Ray diagram cross section
uicontrol('Style','Pushbutton','Parent',PickerGui,'Units','Normalized','Position',[0.82 0.6 0.15 0.1],'String','2D CCP cross section','Callback',{@manual_pick_ray_cross_section_callback});

% CCP
% Text
uicontrol('Style','Text','Parent',PickerGui,'Units','Normalized','Position',[0.82 0.45 0.15 0.10],'String','CCP Volume','BackgroundColor','White')

% Load a volume
uicontrol('Style','Pushbutton','Parent',PickerGui,'Units','Normalized','Position',[0.82 0.4 0.15 0.1],'String','Load CCP Volume','Enable','on','Callback',{@manual_pick_load_ccp_volume});

% 1D profile
uicontrol('Style','Pushbutton','Parent',PickerGui,'Units','Normalized','Position',[0.82 0.3 0.15 0.1],'String','1D depth profile','Enable','off','Tag','moho_manual_pick_ccp_oned_button','Callback',{@manual_moho_pick_ccp_oned});

% Cross section
uicontrol('Style','Pushbutton','Parent',PickerGui,'Units','Normalized','Position',[0.82 0.2 0.15 0.1],'String','CCP cross section','Enable','off','Tag','moho_manual_pick_ccp_cross_section_button','Callback',{@manual_moho_pick_ccp_cross_section});

% Close/cancel
uicontrol('Style','Pushbutton','Parent',PickerGui,'Units','Normalized','Position',[0.82 0.1 0.15 0.1],'String','Close','Callback',{@close_moho_manual_pick_gui});

%% Callback functions live down here

%% Aggregator
% This may be a little too ambitious, but goal here is to provide a UI to
% control interpolation to try and make a surface out of moho picks. We'll
% need common geometry tools to set geographic limits. We'll also need
% smoothing and outlier rejection. Final products will be map views of the
% moho surface and control points, a mat file with the scatteredInterpolant
% function, and a text file with the surface.
% Add option to import a text file such as output from the export menu
% Also, add an import initial model to remove outliers
function aggregator_callback(cbo, eventdata, handles)
    % Gather project metadata
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
    
    % Check for existance of various types of picks
    % Updates the checkboxes
    try
        ManualPickMohoStationStackCell=evalin('base','ManualPickMohoStationStackCell');
    catch
        ManualPickMohoStationStackCell=[];
    end
    if isempty(ManualPickMohoStationStackCell)
        station_stack_flag = 0;
        station_stack_enable = 'off';
    else
        station_stack_flag = 1;
        station_stack_enable = 'on';
    end
    
    try
        ManualPickMohoRFCrossSectionArray=evalin('base','ManualPickMohoRFCrossSectionArray');
    catch
        ManualPickMohoRFCrossSectionArray=[];
    end
    if isempty(ManualPickMohoRFCrossSectionArray)
        rf_cross_section_flag = 0;
        rf_cross_section_enable = 'off';
    else
        rf_cross_section_flag = 1;
        rf_cross_section_enable = 'on';
    end
    
    try
        ManualPickMohoRayCrossSectionArray=evalin('base','ManualPickMohoRayCrossSectionArray');
    catch
        ManualPickMohoRayCrossSectionArray=[];
    end
    if isempty(ManualPickMohoRayCrossSectionArray)
        ray_diagram_flag = 0;
        ray_diagram_enable = 'off';
    else
        ray_diagram_flag = 1;
        ray_diagram_enable = 'on';
    end
    
    try
        ManualPickMohoCCPoneDArray=evalin('base','ManualPickMohoCCPoneDArray');
    catch
        ManualPickMohoCCPoneDArray=[];
    end
    if isempty(ManualPickMohoCCPoneDArray)
        ccp_oned_flag = 0;
        ccp_oned_enable = 'off';
    else
        ccp_oned_flag = 1;
        ccp_oned_enable = 'on';
    end
    
    try
        ManualPickMohoCCPCrossSectionArray=evalin('base','ManualPickMohoCCPCrossSectionArray');
    catch
        ManualPickMohoCCPCrossSectionArray=[];
    end
    if isempty(ManualPickMohoCCPCrossSectionArray)
        ccp_cross_section_flag = 0;
        ccp_cross_section_enable = 'off';
    else
        ccp_cross_section_flag = 1;
        ccp_cross_section_enable = 'on';
    end
    
    % GUI will have a handful of elements:
    % Text and edit box:
    % lat/lon min/max/increment
    % Smooth in longitude nodes, smooth in latitude nodes
    % Make strings out of the geographic limits
    
    % Get map view parameters from strings in the preferences to floats
    MinLatitude = sscanf(FuncLabPreferences{14},'%f');
    MaxLatitude = sscanf(FuncLabPreferences{13},'%f');
    MinLongitude = sscanf(FuncLabPreferences{15},'%f');
    MaxLongitude = sscanf(FuncLabPreferences{16},'%f');
    % Not sure of a good way to initialize these, so just going with
    % something reasonable for *most* studies
    IncLatitude = 0.5;
    IncLongitude = 0.5;
    
    % Convert from floats to strings
    MinimumLatitude_s = sprintf('%3.1f',MinLatitude);
    MaximumLatitude_s = sprintf('%3.1f',MaxLatitude);
    IncrementLatitude_s = sprintf('%3.1f',IncLatitude);
    MinimumLongitude_s = sprintf('%3.1f',MinLongitude);
    MaximumLongitude_s = sprintf('%3.1f',MaxLongitude);
    IncrementLongitude_s = sprintf('%3.1f',IncLongitude);
    
    % Smoothing
    nsmoothx_s = sprintf('%3.0f',1);
    nsmoothy_s = sprintf('%3.0f',1);    
    
    % Popup menu:
    % Interpolation Method
    % Extrapolation Method
    InterpolationMethods = {'linear','nearest','natural'};
    ExtrapolationMethods = {'linear','nearest','none'};
    
    % Check boxes and text:
    % Use each one of the 5 methods
    
    % Need option to load hk export file
    % Need option to load exported manual moho pick files
    % Need option to load some reference model and then pack with crust1.0
    % or crust2.0
    % Use reference models for finding and rejecting outliers
    
    % Buttons for cancel and go

    MainPos = [0 0 130 28];
    ParamTitlePos = [2 MainPos(4)-2.1 80 2];
    ParamTextPos1 = [2 0 31 1.75];
    ParamOptionPos1 = [32 0 7 1.75];
    ParamTextPos2 = [41 0 30 1.75];
    ParamOptionPos2 = [72 0 7 1.75];
    ParamTextPos3 = [80 0 30 1.75];
    ParamOptionPos3 = [111 0 7 1.75];
    ProcTitlePos = [80 MainPos(4)-2 50 1.25];
    ProcButtonPos = [105 2 20 3];
    CloseButtonPos = [90 3 30 3];
    % Setting font sizes
    TextFontSize = 0.6; % ORIGINAL
    EditFontSize = 0.5;
    AccentColor = [.6 0 0];
    % Ok, we have the geographic boundaries set. 
    % Setup new figure for entering data.
    GeometryFigure = figure('Name','Manual Moho Pick Aggregator','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'DockControls','off','MenuBar','none','NumberTitle','off','color','white');

    %text and edit boxes
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','title_t','String','Aggregator',...
        'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    
    % Starting model - text, select button, edit box
    % Text for max deviation (km) and edit box
    uicontrol('Parent',GeometryFigure,'Style','text','units','characters','Tag','starting_model_t','String','Starting Model:',...
        'Position',[2 24 21 1.5],'FontUnits','normalized','FontSize',0.75,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol('Parent',GeometryFigure,'Style','Pushbutton','units','characters','Tag','starting_model_pb','String','Select',...
        'Position',[24 24 15 2],'ForegroundColor',AccentColor,'FontWeight','bold','FontUnits','Normalized','FontSize',0.3,'HorizontalAlignment','Center','BackgroundColor','White',...
        'Callback',{@aggregator_import_starting_model_callback});
    uicontrol('Parent',GeometryFigure,'Style','Edit','units','characters','Tag','starting_model_e','String','This will be populated when you select a file',...
        'Position',[40 24 40 2],'FontUnits','Normalized','FontSize',0.4,'HorizontalAlignment','left','BackgroundColor','White','Enable','off');
    uicontrol('Parent',GeometryFigure,'Style','text','units','characters','Tag','max_deviation_t','String','Max deviation (km):',...
        'Position',[86 24 25 1.5],'FontUnits','normalized','FontSize',0.75,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol('Parent',GeometryFigure,'Style','Edit','units','characters','Tag','max_deviation_e','String','10',...
        'Position',[110 24 5 2],'FontUnits','Normalized','FontSize',0.4,'HorizontalAlignment','left','BackgroundColor','White','Enable','on');
    
    
    % Import text file - text, select button, edit box
    uicontrol('Parent',GeometryFigure,'Style','text','units','characters','Tag','import_text_file_t','String','Import text file:',...
        'Position',[2 21 25 1.5],'FontUnits','normalized','FontSize',0.75,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol('Parent',GeometryFigure,'Style','Pushbutton','units','characters','Tag','import_file_pb','String','Select',...
        'Position',[24 21 15 2],'ForegroundColor',AccentColor,'FontWeight','bold','FontUnits','Normalized','FontSize',0.3,'HorizontalAlignment','Center','BackgroundColor','White',...
        'Callback',{@aggregator_import_text_file_callback});
    uicontrol('Parent',GeometryFigure,'Style','Edit','units','characters','Tag','import_file_e','String','Select a file',...
        'Position',[40 21 20 2],'FontUnits','Normalized','FontSize',0.4,'HorizontalAlignment','left','BackgroundColor','White','Enable','off');
    uicontrol('Parent',GeometryFigure,'Style','CheckBox','units','characters','Tag','import_file_cb',...
        'Position',[61 21 4 2],'Value',0,'BackgroundColor','White','Enable','off');
    
    % Import hk text file - text, select button, edit box
    uicontrol('Parent',GeometryFigure,'Style','text','units','characters','Tag','import_hk_file_t','String','Import Hk file:',...
        'Position',[70 21 25 1.5],'FontUnits','normalized','FontSize',0.75,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol('Parent',GeometryFigure,'Style','Pushbutton','units','characters','Tag','import_hk_file_pb','String','Select',...
        'Position',[87 21 15 2],'ForegroundColor',AccentColor,'FontWeight','bold','FontUnits','Normalized','FontSize',0.3,'HorizontalAlignment','Center','BackgroundColor','White',...
        'Callback',{@aggregator_select_hk_file_callback});
    uicontrol('Parent',GeometryFigure,'Style','Edit','units','characters','Tag','import_hk_file_e','String','Select a file',...
        'Position',[103 21 20 2],'FontUnits','Normalized','FontSize',0.4,'HorizontalAlignment','left','BackgroundColor','White','Enable','off');
    uicontrol('Parent',GeometryFigure,'Style','CheckBox','units','characters','Tag','import_hk_file_cb',...
        'Position',[124 21 4 2],'Value',0,'BackgroundColor','White','Enable','off');
    
    % check boxes for datasets to include
    % Text and check box for:
    % station stack, rf cross section, ray diagram, ccp 1D, ccp cross
    % section, hk, and imported file
    % Checkboxes are default set to off (false?) but switch to on (true?)
    % when we find if the dataset is available.
    uicontrol('Parent',GeometryFigure,'Style','text','units','characters','Tag','use_station_stack_t','String','Use station stack',...
        'Position',[6 18 25 1.5],'FontUnits','normalized','FontSize',0.75,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol('Parent',GeometryFigure,'Style','CheckBox','units','characters','Tag','use_station_stack_cb',...
        'Position',[2 18 4 2],'Value',station_stack_flag,'BackgroundColor','White','Enable',station_stack_enable);
    
    uicontrol('Parent',GeometryFigure,'Style','text','units','characters','Tag','use_rf_cross_section_t','String','Use RF cross section',...
        'Position',[32 18 25 1.5],'FontUnits','normalized','FontSize',0.75,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol('Parent',GeometryFigure,'Style','CheckBox','units','characters','Tag','use_rf_cross_section_cb',...
        'Position',[28 18 4 2],'Value',rf_cross_section_flag,'BackgroundColor','White','Enable',rf_cross_section_enable);
    
    uicontrol('Parent',GeometryFigure,'Style','text','units','characters','Tag','use_ray_diagram_t','String','Use 2D CCP',...
        'Position',[60 18 25 1.5],'FontUnits','normalized','FontSize',0.75,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol('Parent',GeometryFigure,'Style','CheckBox','units','characters','Tag','use_ray_diagram_cb',...
        'Position',[56 18 4 2],'Value',ray_diagram_flag,'BackgroundColor','White','Enable',ray_diagram_enable);
    
    uicontrol('Parent',GeometryFigure,'Style','text','units','characters','Tag','use_ccp_oned_t','String','Use CCP 1D',...
        'Position',[84 18 25 1.5],'FontUnits','normalized','FontSize',0.75,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol('Parent',GeometryFigure,'Style','CheckBox','units','characters','Tag','use_ccp_oned_cb',...
        'Position',[80 18 4 2],'Value',ccp_oned_flag,'BackgroundColor','White','Enable',ccp_oned_enable);

    uicontrol('Parent',GeometryFigure,'Style','text','units','characters','Tag','use_ccp_cross_section_t','String','Use CCP cross section',...
        'Position',[103 18 28 1.5],'FontUnits','normalized','FontSize',0.75,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol('Parent',GeometryFigure,'Style','CheckBox','units','characters','Tag','use_ccp_cross_section_cb',...
        'Position',[99 18 4 2],'Value',ccp_cross_section_flag,'BackgroundColor','White','Enable',ccp_cross_section_enable);

    ParamTextPos1(2) = 15;
    ParamOptionPos1(2) = 15;
    ParamTextPos2(2) = 15;
    ParamOptionPos2(2) = 15;
    ParamTextPos3(2) = 15;
    ParamOptionPos3(2) = 15;

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

    ParamTextPos1(2) = 12;
    ParamOptionPos1(2) = 12;
    ParamTextPos2(2) = 12;
    ParamOptionPos2(2) = 12;
    ParamTextPos3(2) = 12;
    ParamOptionPos3(2) = 12;

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

    ParamTextPos2(2) = 9;
    ParamTextPos2(3) = ParamTextPos2(3)+1;
    ParamOptionPos2(2) = 9;
    ParamTextPos3(2) = 9;
    ParamOptionPos3(2) = 9;
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','smooth_x_t','String','Longitude smoothing (nodes):',...
        'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','nsmoothx_edit','String',nsmoothx_s,...
        'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','smooth_y_t','String','Latitude smoothing (nodes):',...
        'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','nsmoothy_edit','String',nsmoothy_s,...
        'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')

    
    ParamTextPos1(2) = 9;
    ParamOptionPos1(1) = 25;
    ParamOptionPos1(2) = 9;
    ParamOptionPos1(3) = 15;
    ParamTextPos2(2) = 6;
    ParamOptionPos2(2) = 6;
    ParamTextPos3(2) = 6;
    ParamOptionPos3(2) = 6;
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','extrapolation_methods_t','String','Extrapolation:',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',GeometryFigure,'Style','Popupmenu','String',ExtrapolationMethods,'Tag','extrapolation_pu','Value',3,'Units','characters',...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');

    ParamTextPos1(2) = 6;
    ParamOptionPos1(1) = 25;
    ParamOptionPos1(2) = 6;
    ParamOptionPos1(3) = 15;
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','interpolation_methods_t','String','Interpolation:',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',GeometryFigure,'Style','Popupmenu','String',InterpolationMethods,'Tag','interpolation_pu','Value',1,'Units','characters',...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');

    
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','percent_resample_t','String','Percent resampling:',...
        'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','percent_resample_edit','String','100',...
        'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')
    uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','n_bootstraps_t','String','Number of bootstraps:',...
        'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','n_bootstraps_edit','String','100',...
        'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on')

    
    
    % Add buttons for "Save Geometry" and "Cancel"
    uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','savegeometry_pb','String','Run',...
        'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
        'Callback',{@aggregator_run_callback});

    ProcButtonPos(1) = 80;
    uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','cancel_pb','String','Cancel',...
        'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
        'Callback',{@cancel_new_view,GeometryFigure});
   
%% Aggregator callbacks
% -------------------------------------------------------------------------
% First three tie to pushbuttons and use the uigetfile function to have the
% user select a file. The file name is then written into the associated
% edit box. We'll also set a flag (in base set or aggregator figure window)
% for each to indicate that this dataset is available.
% Select starting model
% Select import text file
% Select Hk file
% This will be the main routine. First gather all the user parameters,
% remove outliers, and use scatteredInterpolant to make a function out of
% it. Use the geometry to make a mesh and then evaluate the function on the
% mesh and save the function, mesh, and smoothed moho to mat files after
% getting file names from uiputfile. Also save the x,y,z values to a text
% file. As I'm looking at this and thinking, I should probably add
% bootstrapping parameters.
% Run aggregator
% -------------------------------------------------------------------------
function aggregator_import_starting_model_callback(cbo, eventdata, handles)

    [addonpath,~,~] = fileparts(mfilename('fullpath'));

    % First, we have the user select an input file to read from. If this is
    % canceled, then we just return
    [filename, pathname, filterindex] = uigetfile(fullfile(addonpath,'*.txt'),'Import starting model (longitude, latitude, thickness)');
    
    if isequal(filename,0) || isequal(pathname,0)
        disp('Cancelled select starting model.')
        return
    end
    
    fid = fopen([pathname filename],'r');
    if fid == -1
        disp('Unable to read starting model.');
        return
    end
    fclose(fid);

    hdls = findobj('Tag','starting_model_e');
    set(hdls,'String',[pathname filename]);
    set(hdls,'Enable','on');
    
function aggregator_import_text_file_callback(cbo, eventdata, handles)
    ProjectDirectory = evalin('base','ProjectDirectory');
     % First, we have the user select an input file to read from. If this is
    % canceled, then we just return
    [filename, pathname, filterindex] = uigetfile(fullfile(ProjectDirectory,'*.txt'),'Import a text file (longitude, latitude, thickness)');
    
    if isequal(filename,0) || isequal(pathname,0)
        disp('Cancelled select a text file.')
        return
    end
    
    fid = fopen([pathname filename],'r');
    if fid == -1
        disp('Unable to read text file.');
        return
    end
    fclose(fid);

    hdls = findobj('Tag','import_file_e');
    set(hdls,'String',[pathname filename]);
    set(hdls,'Enable','on');
    hdls = findobj('Tag','import_file_cb');
    set(hdls,'Value',1);
    set(hdls,'Enable','on');

function aggregator_select_hk_file_callback(cbo, eventdata, handles)
    ProjectDirectory = evalin('base','ProjectDirectory');
     % First, we have the user select an input file to read from. If this is
    % canceled, then we just return
    [filename, pathname, filterindex] = uigetfile(fullfile(ProjectDirectory,'*.txt'),'Import Hk stack output file');
    
    if isequal(filename,0) || isequal(pathname,0)
        disp('Cancelled select an Hk file.')
        return
    end
    
    fid = fopen([pathname filename],'r');
    if fid == -1
        disp('Unable to read hk file.');
        return
    end
    fclose(fid);

    hdls = findobj('Tag','import_hk_file_e');
    set(hdls,'String',[pathname filename]);
    set(hdls,'Enable','on');
    hdls = findobj('Tag','import_hk_file_cb');
    set(hdls,'Value',1);
    set(hdls,'Enable','on');

%% Really the main aggregator command. Activates when user hits the run
% pushbutton. 
function aggregator_run_callback(cbo, eventdata, handles)
    % Gather project metadata
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
  
    % Gather user inputs
    hdls = findobj('Tag','extrapolation_pu');
    MyExtrapolationMethod = hdls.String{hdls.Value};
    
    hdls = findobj('Tag','interpolation_pu');
    MyInterpolationMethod = hdls.String{hdls.Value};
    
    hdls = findobj('Tag','MinimumLatitude_edit');
    MinLatitude = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','MaximumLatitude_edit');
    MaxLatitude = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','IncrementLatitude_edit');
    IncLatitude = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','MinimumLongitude_edit');
    MinLongitude = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','MaximumLongitude_edit');
    MaxLongitude = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','IncrementLongitude_edit');
    IncLongitude = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','nsmoothy_edit');
    nsmoothy = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','nsmoothx_edit');
    nsmoothx = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','percent_resample_edit');
    percentResample = sscanf(hdls.String,'%f');
    
    hdls = findobj('Tag','n_bootstraps_edit');
    nBootstrap = sscanf(hdls.String,'%f');
    
    % Starting model - find if used, get file name, and set max deviation
    hdls = findobj('Tag','starting_model_e');
    if strcmp(hdls.String, 'This will be populated when you select a file')
        disp('Running without a starting model. No outliers will be rejected.')
        do_starting_model_rejection = 0;
    else
        % Get the file name and set a flag for later
        StartingModelFileName = hdls.String;
        % Get the max deviation from the edit box
        hdls = findobj('Tag','max_deviation_e');
        max_deviation = sscanf(hdls.String,'%f');
        % Read the starting model and make into function with
        % scatteredInterpolant
        try
            fid = fopen(StartingModelFileName,'r');
        catch
            disp('Unable to read starting model.')
            return
        end
        C = textscan(fid,'%f %f %f');
        fclose(fid);
        StartingModelFunction = scatteredInterpolant(C{1}, C{2}, C{3});
        StartingModelFunction.Method = MyInterpolationMethod;
        StartingModelFunction.ExtrapolationMethod = MyExtrapolationMethod;
        do_starting_model_rejection = 1;
    end
    
    % Get an imported text file
    UseImportFileFlag = 0;
    nPicksImport = 0;
    hdls = findobj('Tag','import_file_cb');
    if hdls.Value == 1
        hdls = findobj('Tag','import_file_e');
        ImportFileName = hdls.String;
        try
            fid = fopen(ImportFileName,'r');
        catch
            disp('Unable to read import file');
            return
        end
        C = textscan(fid,'%f %f %f');
        fclose(fid);
        ImportFileLongitudes =  C{1};
        ImportFileLatitudes = C{2};
        ImportFileThicknesses = C{3};
        nPicksImport = length(ImportFileLongitudes);
        UseImportFileFlag = 1;
    end
    
    % Get an Hk output text file
    UseHkFileFlag = 0;
    nPicksHk = 0;
    hdls = findobj('Tag','import_hk_file_cb');
    if hdls.Value == 1
        hdls = findobj('Tag','import_hk_file_e');
        HkFileName = hdls.String;
        try
            fid = fopen(HkFileName,'r');
        catch
            disp('Unable to read Hk file');
            return
        end
        C = textscan(fid,'%f %f %f %s %f %f %f %f %f %f %f %f %f %f %f %s %s');
        fclose(fid);
        HkFileLongitudes =  C{1};
        HkFileLatitudes = C{2};
        HkFileThicknesses = C{5};
        nPicksHk = length(HkFileLongitudes);
        UseHkFileFlag = 1;
    end
    
    % Check all the check boxes for whether or not to use the various
    % datasets
    hdls = findobj('Tag','use_station_stack_cb');
    if hdls.Value == 1
        use_station_stack_flag = 1;
    else
        use_station_stack_flag = 0;
    end
    hdls = findobj('Tag','use_rf_cross_section_cb');
    if hdls.Value == 1
        use_rf_cross_section_flag = 1;
    else
        use_rf_cross_section_flag = 0;
    end
    hdls = findobj('Tag','use_ray_diagram_cb');
    if hdls.Value == 1
        use_ray_diagram_flag = 1;
    else
        use_ray_diagram_flag = 0;
    end
    hdls = findobj('Tag','use_ccp_oned_cb');
    if hdls.Value == 1
        use_ccp_oned_flag = 1;
    else
        use_ccp_oned_flag = 0;
    end
    hdls = findobj('Tag','use_ccp_cross_section_cb');
    if hdls.Value == 1
        use_ccp_cross_section_flag = 1;
    else
        use_ccp_cross_section_flag = 0;
    end
    
    % Gather up all the selected picks into an npicks by 3 array
    % First, lets load the selected datasets from the base. Then we'll
    % count them and sum up the picks so we can allocate memory for the
    % main matrix
    
    npicksStationStacks = 0;
    if use_station_stack_flag == 1
        ManualPickMohoStationStackCell = evalin('base','ManualPickMohoStationStackCell');
        a = size(ManualPickMohoStationStackCell);
        pickflagsStationStacks = zeros(1,length(ManualPickMohoStationStackCell));
        for idx=1:length(ManualPickMohoStationStackCell)
            if a(2) == 5
                if ~isempty(ManualPickMohoStationStackCell{idx,2})
                    pickflagsStationStacks(idx) = 1;
                end
            else
                if ~isempty(ManualPickMohoStationStackCell{idx,2}) && ManualPickMohoStationStackCell{idx,6} == 1
                    pickflagsStationStacks(idx) = 1;
                end
            end
        end
        npicksStationStacks = sum(pickflagsStationStacks);
    end
    
    npicksRFCrossSection = 0;
    if use_rf_cross_section_flag == 1
        ManualPickMohoRFCrossSectionArray = evalin('base','ManualPickMohoRFCrossSectionArray');
        a = size(ManualPickMohoRFCrossSectionArray);
        pickflagsRFCrossSection = zeros(1,length(ManualPickMohoRFCrossSectionArray));
        for idx=1:length(ManualPickMohoRFCrossSectionArray)
            if a(2) == 3
                if ManualPickMohoRFCrossSectionArray(idx,1) ~= 0
                    pickflagsRFCrossSection(idx) = 1;
                end
            else
                if ManualPickMohoRFCrossSectionArray(idx,1) ~= 0 && ManualPickMohoRFCrossSectionArray(idx,4) == 1
                    pickflagsRFCrossSection(idx) = 1;
                end
            end
        end
        npicksRFCrossSection = sum(pickflagsRFCrossSection);
    end

    npicksRayDiagram = 0;
    if use_ray_diagram_flag == 1
        ManualPickMohoRayCrossSectionArray = evalin('base','ManualPickMohoRayCrossSectionArray');
        a=size(ManualPickMohoRayCrossSectionArray); 
        pickflagsRayDiagram = zeros(1,length(ManualPickMohoRayCrossSectionArray));
        for idx=1:length(ManualPickMohoRayCrossSectionArray)
            if a(2) == 3
                if ManualPickMohoRayCrossSectionArray(idx,1) ~= 0
                    pickflagsRayDiagram(idx) = 1;
                end
            else
                if ManualPickMohoRayCrossSectionArray(idx,1) ~= 0 && ManualPickMohoRayCrossSectionArray(idx,4) == 1
                    pickflagsRayDiagram(idx) = 1;
                end
            end
        end
        npicksRayDiagram = sum(pickflagsRayDiagram);
    end
    
    npicksCCPOneD = 0;
    if use_ccp_oned_flag == 1
        ManualPickMohoCCPoneDArray = evalin('base','ManualPickMohoCCPoneDArray');
        a=size(ManualPickMohoCCPoneDArray);
        pickflagsCCPOneD = zeros(1,length(ManualPickMohoCCPoneDArray));
        for idx=1:length(ManualPickMohoCCPoneDArray)
            if a(2) == 3
                if ManualPickMohoCCPoneDArray(idx,1) ~= 0
                    pickflagsCCPOneD(idx) = 1;
                end
            else
                if ManualPickMohoCCPoneDArray(idx,1) ~= 0 && ManualPickMohoCCPoneDArray(idx,4) == 1 
                    pickflagsCCPOneD(idx) = 1;
                end
            end
        end
        npicksCCPOneD = sum(pickflagsCCPOneD);
    end
    
    npicksCCPCrossSection = 0;
    if use_ccp_cross_section_flag == 1
        ManualPickMohoCCPCrossSectionArray = evalin('base','ManualPickMohoCCPCrossSectionArray');
        a=size(ManualPickMohoCCPCrossSectionArray);
        pickflagsCCPCrossSection = zeros(1,length(ManualPickMohoCCPCrossSectionArray));
        for idx=1:length(ManualPickMohoCCPCrossSectionArray)
            if a(2) == 3
                if ManualPickMohoCCPCrossSectionArray(idx,1) ~= 0
                    pickflagsCCPCrossSection(idx) = 1;
                end
            else
                if ManualPickMohoCCPCrossSectionArray(idx,1) ~= 0 && ManualPickMohoCCPCrossSectionArray(idx,4) == 1
                    pickflagsCCPCrossSection(idx) = 1;
                end
            end
        end
        npicksCCPCrossSection = sum(pickflagsCCPCrossSection);
    end
    
    % Total up the picks
    npicks = npicksCCPCrossSection + npicksCCPOneD + npicksRayDiagram + npicksRFCrossSection + npicksStationStacks + nPicksHk + nPicksImport;
    
    % gather picks into an npicks x 3 array
    AllPicks = zeros(npicks, 3);
    jdx = 1;
    if UseImportFileFlag == 1
        for idx=1:nPicksImport
            AllPicks(jdx,1) = ImportFileLongitudes(idx);
            AllPicks(jdx,2) = ImportFileLatitudes(idx);
            AllPicks(jdx,3) = ImportFileThicknesses(idx);
            jdx = jdx + 1;
        end
    end
    if UseHkFileFlag == 1
        for idx=1:nPicksHk
            AllPicks(jdx,1) = HkFileLongitudes(idx);
            AllPicks(jdx,2) = HkFileLatitudes(idx);
            AllPicks(jdx,3) = HkFileThicknesses(idx);
            jdx = jdx + 1;
        end
    end
    if use_station_stack_flag == 1
        for idx=1:npicksStationStacks
            if pickflagsStationStacks(idx) == 1
                AllPicks(jdx,1) = ManualPickMohoStationStackCell{idx,2};
                AllPicks(jdx,2) = ManualPickMohoStationStackCell{idx,3};
                AllPicks(jdx,3) = ManualPickMohoStationStackCell{idx,4};
                jdx = jdx + 1;
            end
        end
    end
    if use_rf_cross_section_flag == 1
        for idx=1:npicksRFCrossSection
            if pickflagsRFCrossSection(idx) == 1
                AllPicks(jdx,1) = ManualPickMohoRFCrossSectionArray(idx,1);
                AllPicks(jdx,2) = ManualPickMohoRFCrossSectionArray(idx,2);
                AllPicks(jdx,3) = ManualPickMohoRFCrossSectionArray(idx,3);
                jdx = jdx + 1;
            end
        end
    end
    if use_ray_diagram_flag == 1
        for idx=1:npicksRayDiagram
            if pickflagsRayDiagram(idx) == 1
                AllPicks(jdx,1) = ManualPickMohoRayCrossSectionArray(idx,1);
                AllPicks(jdx,2) = ManualPickMohoRayCrossSectionArray(idx,2);
                AllPicks(jdx,3) = ManualPickMohoRayCrossSectionArray(idx,3);
                jdx = jdx + 1;
            end
        end
    end
    if use_ccp_oned_flag == 1
        for idx=1:npicksCCPOneD
            if pickflagsCCPOneD(idx) == 1
                AllPicks(jdx,1) = ManualPickMohoCCPoneDArray(idx,1);
                AllPicks(jdx,2) = ManualPickMohoCCPoneDArray(idx,2);
                AllPicks(jdx,3) = ManualPickMohoCCPoneDArray(idx,3);
                jdx = jdx + 1;
            end
        end
    end
    if use_ccp_cross_section_flag == 1
        for idx=1:npicksCCPCrossSection
            if pickflagsCCPCrossSection(idx) == 1
                AllPicks(jdx,1) = ManualPickMohoCCPCrossSectionArray(idx,1);
                AllPicks(jdx,2) = ManualPickMohoCCPCrossSectionArray(idx,2);
                AllPicks(jdx,3) = ManualPickMohoCCPCrossSectionArray(idx,3);
                jdx = jdx + 1;
            end
        end
    end
    
    % Now to remove outliers
    if do_starting_model_rejection == 1
        % Populate an array of predicted crustal thicknesses from starting
        % model
        npicksPre = length(AllPicks);
        StartingModelPicks = zeros(1,npicks);
        for idx=1:npicks
            StartingModelPicks(idx) = StartingModelFunction(AllPicks(idx,1), AllPicks(idx,2));
        end
        % Compare the picks and remove outliers
        for idx=npicks:-1:1
            if abs(AllPicks(idx,3)-StartingModelPicks(idx)) > max_deviation
                StartingModelPicks(idx) = [];
                AllPicks(idx,:) = [];
            end
        end
        npicksPost = length(AllPicks);
        fprintf('Removed %d picks.\n', npicksPre - npicksPost);
        npicks = npicksPost;
    else
        disp('Not doing rejection of outliers');
    end
    
    % Prepare spatial vectors and meshes for the Moho
    xvector = MinLongitude:IncLongitude:MaxLongitude;
    yvector = MinLatitude:IncLatitude:MaxLatitude;
    [xmesh, ymesh] = meshgrid(xvector, yvector);
    if length(yvector) < length(xvector)
        BootStrapMaps = zeros(length(yvector), length(xvector), nBootstrap);
    else
        BootStrapMaps = zeros(length(xvector), length(yvector), nBootstrap);
    end
        
    % Now do a bootstrap resampling of the AllPicks matrix
    nSamplesBootStrap = round(npicks * percentResample / 100);
    BootStrapPicksMatrix = zeros(nSamplesBootStrap, 3);
    rng('shuffle'); % RWP note, many researchers seem to prefer a repeatable seed; I prefer a random seed. Deal with it. 
    % Likely to get an annoying warning
    warning('off','MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId');
    if nBootstrap > 999
        h = waitbar(0,'Please wait....');
    end
    % Iterates over the desired number of iterations
    for idx=1:nBootstrap
        % Chooses the indices
        BootIDX = randi(npicks,[nSamplesBootStrap,1]);
        for jdx = 1:nSamplesBootStrap
            BootStrapPicksMatrix(jdx,1) = AllPicks(BootIDX(jdx),1);
            BootStrapPicksMatrix(jdx,2) = AllPicks(BootIDX(jdx),2);
            BootStrapPicksMatrix(jdx,3) = AllPicks(BootIDX(jdx),3);
        end
        % Make a scatteredInterpolant function out of the picks
        MohoFunction = scatteredInterpolant(BootStrapPicksMatrix(:,1), BootStrapPicksMatrix(:,2), BootStrapPicksMatrix(:,3));
        MohoFunction.Method = MyInterpolationMethod;
        MohoFunction.ExtrapolationMethod = MyExtrapolationMethod;
        % Evaluate on the mesh
        tmpMap = MohoFunction(xmesh, ymesh);
        smoothMap = smooth_nxm_matrix(tmpMap, nsmoothx, nsmoothy);
        BootStrapMaps(:,:,idx) = smoothMap;
        if nBootstrap > 999 && mod(idx,100) == 0
            waitbar(idx/nBootstrap);
        end
    end
    if nBootstrap > 999
        close(h);
    end
    % Get the mean and standard deviation
    MeanMohoMap = mean(BootStrapMaps,3);
    StdMohoMap = std(BootStrapMaps,1,3,'omitnan');

    % Plot the maps and use uiputfile to prompt the user to save data
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
    figure('Name','Mean Crustal Thickness Map','Color','White')
    load FL_coasts
    load FL_plates
    load FL_stateBoundaries
    minlat = MinLatitude;
    maxlat = MaxLatitude;
    minlon = MinLongitude;
    maxlon = MaxLongitude;
    m_proj(MapProjection,'latitude',[minlat maxlat], 'longitude', [minlon maxlon]);
    %m_proj('Hammer-Aitoff','latitude',[-90 90],'longitude',[-180 180]);

    % Makes the initial plot view - global coast lines and a shaded box for the
    % CCP image volume
    %plot(ncst(:,1),ncst(:,2),'k')
    hold on
    m_pcolor(xmesh, ymesh, MeanMohoMap);
    shading interp;
    c=colorbar;
    xlabel(c,'Crustal Thickness (km)');
    %m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
    m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
    m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
    m_line(ncst(:,1), ncst(:,2),'Color',[0 0 0])
    %m_coast('patch',[.9 .9 .9],'edgecolor','black');
    %axis([-180 180 -90 90])
    %m_grid('xtick',floor((maxlon-minlon)/10),'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
    m_grid('xtick',4,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
    
    figure('Name','Standard Deviation of Crustal Thickness Map','Color','White')
    m_proj(MapProjection,'latitude',[minlat maxlat], 'longitude', [minlon maxlon]);
    hold on
    m_pcolor(xmesh, ymesh, StdMohoMap);
    shading interp;
    c=colorbar;
    xlabel(c,'Standard Deviation (km)');
    m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
    m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
    m_line(ncst(:,1), ncst(:,2),'Color',[0 0 0])
    m_grid('xtick',4,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
    
    % Warning before throughing save buttons in the user's face
    screensize = get(0,'screensize');
    figpos = [screensize(3) / 2 - 200 screensize(4) / 2 - 50 400 200];
    tmpfig = figure('Name','You are about to be prompted to save files','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
    uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.5 0.6 0.4],'String','Please choose filenames to save the aggregator outputs. The first is a matfile with the various run time parameters and the second is an ascii file with the mean and standard deviation of the moho.','FontSize',12);
    waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.2],'String','Click','FontSize',12,'Callback','gcbf.UserData=1; close');
    waitfor(waitbutton,'Userdata');

    
    % Finally, lets go ahead and save things
    % Mat file with mean and standard deviation, spatial vectors and
    % matrices, bootstrap and smoothing parameters, and a function using
    % all pick points
    [filename, pathname, ~] = uiputfile('*.mat','Save matlab variables');
    if isequal(filename,0) || isequal(pathname,0)
        disp('Cancelled exporting aggregated moho matlab variables')
    else
        MohoFunction = scatteredInterpolant(AllPicks(:,1), AllPicks(:,2), AllPicks(:,3));
        MohoFunction.Method = MyInterpolationMethod;
        MohoFunction.ExtrapolationMethod = MyExtrapolationMethod;
        save([pathname filename],'xvector','yvector','MohoFunction','nsmoothx','nsmoothy','nBootstrap','npicks','nSamplesBootStrap',...
            'do_starting_model_rejection','use_station_stack_flag','use_rf_cross_section_flag','use_ray_diagram_flag','use_ccp_oned_flag',...
            'use_ccp_cross_section_flag','xmesh','ymesh','UseHkFileFlag','UseImportFileFlag');   
    end
    
    % Ascii file with longitude, latitude, thickness, standard deviation
    [filename, pathname, ~] = uiputfile('*.txt','write moho mean and standard deviation');
    if isequal(filename,0) || isequal(pathname,0)
        disp('Cancelled exporting ascii moho')
    else
        fid = fopen([pathname filename],'w');
        if length(xvector) < length(yvector)
            for idx=1:length(xvector)
                for idy=1:length(yvector)
                    fprintf(fid,'%f %f %f %f\n',xvector(idx), yvector(idy), MeanMohoMap(idx,idy), StdMohoMap(idx,idy));
                end
            end
        else
            for idx=1:length(xvector)
                for idy=1:length(yvector)
                    fprintf(fid,'%f %f %f %f\n',xvector(idx), yvector(idy), MeanMohoMap(idy,idx), StdMohoMap(idy, idx));
                end
            end
        end
    end
    
    % All done!
    hdls = findobj('Name','Manual Moho Pick Aggregator');
    close(hdls);
    
function aggregator_help_callback(cbo, eventdata, handles)
    MainPos = [0 0 75 30];
    ProcButtonPos = [30 1 25 2];

    HelpDlg = dialog('Name','Aggregator help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
        'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    str = ['Aggregator provides a user interface to combine crustal thickness picks into one continuous surface. Controls allow you to set desired geometry, smoothing,'...
        ' and choose which of the crustal thickness elements to include. This interface is only active after one of the pick tools has been used and results saved.' ...
        ' The starting model is a (coarse) estimate of crustal thickness and datapoints more than max deviation (km) away from the starting are rejected.' ...
        ' Import text file allows you to use any file with 3 columns for longitude, latitude, and crustal thickness as a dataset. This is designed so you can hand edit the' ...
        ' exported files and re-use them.'];
        
    HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters',...
        'Position',[5 4 65 25],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.05,'HorizontalAlignment','left',...
        'Max',100,'Min',1);

    OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','OK','Units','Characters',...
        'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
        'Callback','close');    
              
%% ------------------------------------------------------------------------
% export_ccp_oned_moho_callback
% writes pick information to a user specified text file
% -------------------------------------------------------------------------
function export_ccp_oned_moho_callback(cbo, eventdata, handles)
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

    % First, we have the user select an output file to write to. If this is
    % canceled, then we just return
    [filename, pathname, filterindex] = uiputfile('*.txt','ccp 1D picks output text file');
    
    % Checks the filename / cancel
    if isequal(filename,0) || isequal(pathname,0)
        disp('Cancelled export ccp 1D manual moho picks.')
        return
    end
    
    % Tries to open the file for writing
    fid = fopen([pathname filename],'w');
    if fid == -1
        disp('Unable to write file.');
        return
    end
    
    % See if we have picks (we should, or else this won't be enabled)
    try
        ManualPickMohoCCPoneDArray=evalin('base','ManualPickMohoCCPoneDArray');
    catch
        ManualPickMohoCCPoneDArray=[];
    end
    if isempty(ManualPickMohoCCPoneDArray)
        return
    end
    a = size(ManualPickMohoCCPoneDArray);
    if a(2) == 3
        ManualPickMohoCCPoneDArrayTmp = ManualPickMohoCCPoneDArray;
        ManualPickMohoCCPoneDArray = zeros(a(1),4);
        for idx=1:a(1)
            ManualPickMohoCCPoneDArray(idx, 1) = ManualPickMohoCCPoneDArrayTmp(idx,1);
            ManualPickMohoCCPoneDArray(idx, 2) = ManualPickMohoCCPoneDArrayTmp(idx,2);
            ManualPickMohoCCPoneDArray(idx, 3) = ManualPickMohoCCPoneDArrayTmp(idx,3);
            ManualPickMohoCCPoneDArray(idx, 4) = 1;
        end
        clear ManualPickMohoCCPoneDArrayTmp
    end
    
    % Now get the locations of stations with picks
    % First need to find the number of picks
    pickflags = zeros(1,length(ManualPickMohoCCPoneDArray));
    for idx=1:length(ManualPickMohoCCPoneDArray)
        if ManualPickMohoCCPoneDArray(idx,1) ~= 0 && ManualPickMohoCCPoneDArray(idx,4) == 1
            pickflags(idx) = 1;
        end
    end
    npicks = sum(pickflags);
      
    % Now get smaller arrays with just the picks
    picklons = zeros(1,npicks);
    picklats = zeros(1,npicks);
    pickthicknesses = zeros(1,npicks);
    
    jdx = 1;
    for idx=1:length(ManualPickMohoCCPoneDArray)
        if pickflags(idx) == 1
            picklons(jdx) = ManualPickMohoCCPoneDArray(idx,1);
            picklats(jdx) = ManualPickMohoCCPoneDArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoCCPoneDArray(idx,3);
            jdx = jdx+1;
        end
    end
    
    % All the pick information is gathered into arrays for latitude,
    % longitude, and crustal thickness. Now we write to the file chosen by
    % the user.
    for idx=1:npicks
        fprintf(fid,'%f %f %f\n',picklons(idx), picklats(idx), pickthicknesses(idx));
    end
    
    fclose(fid);

%% ------------------------------------------------------------------------
% export_ccp_cross_section_moho_callback
% writes pick information to a user specified text file
% -------------------------------------------------------------------------
function export_ccp_cross_section_moho_callback(cbo, eventdata, handles)
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

    % First, we have the user select an output file to write to. If this is
    % canceled, then we just return
    [filename, pathname, filterindex] = uiputfile('*.txt','ccp cross section picks output text file');
    
    % Checks the filename / cancel
    if isequal(filename,0) || isequal(pathname,0)
        disp('Cancelled export ccp cross section manual moho picks.')
        return
    end
    
    % Tries to open the file for writing
    fid = fopen([pathname filename],'w');
    if fid == -1
        disp('Unable to write file.');
        return
    end
    
    % See if we have picks (we should, or else this won't be enabled)
    try
        ManualPickMohoCCPCrossSectionArray=evalin('base','ManualPickMohoCCPCrossSectionArray');
    catch
        ManualPickMohoCCPCrossSectionArray=[];
    end
    if isempty(ManualPickMohoCCPCrossSectionArray)
        return
    end
    a = size(ManualPickMohoCCPCrossSectionArray);
    if a(2) == 3
        ManualPickMohoCCPCrossSectionArrayTmp = ManualPickMohoCCPCrossSectionArray;
        ManualPickMohoCCPCrossSectionArray = zeros(a(1),4);
        for idx=1:a(1)
            ManualPickMohoCCPCrossSectionArray(idx, 1) = ManualPickMohoCCPCrossSectionArrayTmp(idx,1);
            ManualPickMohoCCPCrossSectionArray(idx, 2) = ManualPickMohoCCPCrossSectionArrayTmp(idx,2);
            ManualPickMohoCCPCrossSectionArray(idx, 3) = ManualPickMohoCCPCrossSectionArrayTmp(idx,3);
            ManualPickMohoCCPCrossSectionArray(idx, 4) = 1;
        end
        clear ManualPickMohoCCPCrossSectionArrayTmp
    end
    
    % Now get the locations of stations with picks
    % First need to find the number of picks
    pickflags = zeros(1,length(ManualPickMohoCCPCrossSectionArray));
    for idx=1:length(ManualPickMohoCCPCrossSectionArray)
        if ManualPickMohoCCPCrossSectionArray(idx,1) ~= 0 && ManualPickMohoCCPCrossSectionArray(idx,4) == 1
            pickflags(idx) = 1;
        end
    end
    npicks = sum(pickflags);
      
    % Now get smaller arrays with just the picks
    picklons = zeros(1,npicks);
    picklats = zeros(1,npicks);
    pickthicknesses = zeros(1,npicks);
    
    jdx = 1;
    for idx=1:length(ManualPickMohoCCPCrossSectionArray)
        if pickflags(idx) == 1
            picklons(jdx) = ManualPickMohoCCPCrossSectionArray(idx,1);
            picklats(jdx) = ManualPickMohoCCPCrossSectionArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoCCPCrossSectionArray(idx,3);
            jdx = jdx+1;
        end
    end
    
    % All the pick information is gathered into arrays for latitude,
    % longitude, and crustal thickness. Now we write to the file chosen by
    % the user.
    for idx=1:npicks
        fprintf(fid,'%f %f %f\n',picklons(idx), picklats(idx), pickthicknesses(idx));
    end
    
    fclose(fid);
    
%% ------------------------------------------------------------------------
% export_ray_diagram_picks_moho_callback
% writes pick information to a user specified text file
% -------------------------------------------------------------------------
function export_ray_diagram_picks_moho_callback(cbo, eventdata, handles)
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

    % First, we have the user select an output file to write to. If this is
    % canceled, then we just return
    [filename, pathname, filterindex] = uiputfile('*.txt','2D CCP picks output text file');
    
    % Checks the filename / cancel
    if isequal(filename,0) || isequal(pathname,0)
        disp('Cancelled export 2D CCP manual moho picks.')
        return
    end
    
    % Tries to open the file for writing
    fid = fopen([pathname filename],'w');
    if fid == -1
        disp('Unable to write file.');
        return
    end
    
    % See if we have picks (we should, or else this won't be enabled)
    try
        ManualPickMohoRayCrossSectionArray=evalin('base','ManualPickMohoRayCrossSectionArray');
    catch
        ManualPickMohoRayCrossSectionArray=[];
    end
    if isempty(ManualPickMohoRayCrossSectionArray)
        return
    end
    a = size(ManualPickMohoRayCrossSectionArray);
    if a(2) == 3
        ManualPickMohoRayCrossSectionArrayTmp = ManualPickMohoRayCrossSectionArray;
        ManualPickMohoRayCrossSectionArray = zeros(a(1),4);
        for idx=1:a(1)
            ManualPickMohoRayCrossSectionArray(idx, 1) = ManualPickMohoRayCrossSectionArrayTmp(idx,1);
            ManualPickMohoRayCrossSectionArray(idx, 2) = ManualPickMohoRayCrossSectionArrayTmp(idx,2);
            ManualPickMohoRayCrossSectionArray(idx, 3) = ManualPickMohoRayCrossSectionArrayTmp(idx,3);
            ManualPickMohoRayCrossSectionArray(idx, 4) = 1;
        end
        clear ManualPickMohoRayCrossSectionArrayTmp
    end
    
    % Now get the locations of stations with picks
    % First need to find the number of picks
    pickflags = zeros(1,length(ManualPickMohoRayCrossSectionArray));
    for idx=1:length(ManualPickMohoRayCrossSectionArray)
        if ManualPickMohoRayCrossSectionArray(idx,1) ~= 0 && ManualPickMohoRayCrossSectionArray(idx,4) == 1
            pickflags(idx) = 1;
        end
    end
    npicks = sum(pickflags);
      
    % Now get smaller arrays with just the picks
    picklons = zeros(1,npicks);
    picklats = zeros(1,npicks);
    pickthicknesses = zeros(1,npicks);
    
    jdx = 1;
    for idx=1:length(ManualPickMohoRayCrossSectionArray)
        if pickflags(idx) == 1
            picklons(jdx) = ManualPickMohoRayCrossSectionArray(idx,1);
            picklats(jdx) = ManualPickMohoRayCrossSectionArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoRayCrossSectionArray(idx,3);
            jdx = jdx+1;
        end
    end
    
    % All the pick information is gathered into arrays for latitude,
    % longitude, and crustal thickness. Now we write to the file chosen by
    % the user.
    for idx=1:npicks
        fprintf(fid,'%f %f %f\n',picklons(idx), picklats(idx), pickthicknesses(idx));
    end
    
    fclose(fid);

%% ------------------------------------------------------------------------
% export_rf_cross_section_picks_moho_callback
% writes pick information to a user specified text file
% -------------------------------------------------------------------------
function export_rf_cross_section_picks_moho_callback(cbo, eventdata, handles)
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

    % First, we have the user select an output file to write to. If this is
    % canceled, then we just return
    [filename, pathname, filterindex] = uiputfile('*.txt','rf cross section picks output text file');
    
    % Checks the filename / cancel
    if isequal(filename,0) || isequal(pathname,0)
        disp('Cancelled export rf cross section manual moho picks.')
        return
    end
    
    % Tries to open the file for writing
    fid = fopen([pathname filename],'w');
    if fid == -1
        disp('Unable to write file.');
        return
    end
    
    % See if we have picks (we should, or else this won't be enabled)
    try
        ManualPickMohoRFCrossSectionArray=evalin('base','ManualPickMohoRFCrossSectionArray');
    catch
        ManualPickMohoRFCrossSectionArray=[];
    end
    if isempty(ManualPickMohoRFCrossSectionArray)
        return
    end
    a = size(ManualPickMohoRFCrossSectionArray);
    if a(2) == 3
        ManualPickMohoRFCrossSectionArrayTmp = ManualPickMohoRFCrossSectionArray;
        ManualPickMohoRFCrossSectionArray = zeros(a(1),4);
        for idx=1:a(1)
            ManualPickMohoRFCrossSectionArray(idx, 1) = ManualPickMohoRFCrossSectionArrayTmp(idx,1);
            ManualPickMohoRFCrossSectionArray(idx, 2) = ManualPickMohoRFCrossSectionArrayTmp(idx,2);
            ManualPickMohoRFCrossSectionArray(idx, 3) = ManualPickMohoRFCrossSectionArrayTmp(idx,3);
            ManualPickMohoRFCrossSectionArray(idx, 4) = 1;
        end
        clear ManualPickMohoRFCrossSectionArrayTmp
    end
    
    % Now get the locations of stations with picks
    % First need to find the number of picks
    pickflags = zeros(1,length(ManualPickMohoRFCrossSectionArray));
    for idx=1:length(ManualPickMohoRFCrossSectionArray)
        if ManualPickMohoRFCrossSectionArray(idx,1) ~= 0 && ManualPickMohoRFCrossSectionArray(idx,4) == 1
            pickflags(idx) = 1;
        end
    end
    npicks = sum(pickflags);
      
    % Now get smaller arrays with just the picks
    picklons = zeros(1,npicks);
    picklats = zeros(1,npicks);
    pickthicknesses = zeros(1,npicks);
    
    jdx = 1;
    for idx=1:length(ManualPickMohoRFCrossSectionArray)
        if pickflags(idx) == 1
            picklons(jdx) = ManualPickMohoRFCrossSectionArray(idx,1);
            picklats(jdx) = ManualPickMohoRFCrossSectionArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoRFCrossSectionArray(idx,3);
            jdx = jdx+1;
        end
    end
    
    % All the pick information is gathered into arrays for latitude,
    % longitude, and crustal thickness. Now we write to the file chosen by
    % the user.
    for idx=1:npicks
        fprintf(fid,'%f %f %f\n',picklons(idx), picklats(idx), pickthicknesses(idx));
    end
    
    fclose(fid);

%% ------------------------------------------------------------------------
% export_station_stack_picks_moho_callback
% writes pick information to a user specified text file
% -------------------------------------------------------------------------
function export_station_stack_picks_moho_callback(cbo, eventdata, handles)
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

    % First, we have the user select an output file to write to. If this is
    % canceled, then we just return
    [filename, pathname, filterindex] = uiputfile('*.txt','station stack picks output text file');
    
    % Checks the filename / cancel
    if isequal(filename,0) || isequal(pathname,0)
        disp('Cancelled export station stack manual moho picks.')
        return
    end
    
    % Tries to open the file for writing
    fid = fopen([pathname filename],'w');
    if fid == -1
        disp('Unable to write file.');
        return
    end
    
    % See if we have picks (we should, or else this won't be enabled)
    try
        ManualPickMohoStationStackCell=evalin('base','ManualPickMohoStationStackCell');
    catch
        ManualPickMohoStationStackCell=[];
    end
    if isempty(ManualPickMohoStationStackCell)
        return
    end
    a = size(ManualPickMohoStationStackCell);
    if a(2) < 6
        ManualPickMohoStationStackCellTmp = ManualPickMohoStationStackCell;
        ManualPickMohoStationStackCell = cell(a(1),7);
        for idx=1:a(1)
            ManualPickMohoStationStackCell{idx, 1} = ManualPickMohoStationStackCellTmp{idx,1};
            ManualPickMohoStationStackCell{idx, 2} = ManualPickMohoStationStackCellTmp{idx,2};
            ManualPickMohoStationStackCell{idx, 3} = ManualPickMohoStationStackCellTmp{idx,3};
            ManualPickMohoStationStackCell{idx, 4} = ManualPickMohoStationStackCellTmp{idx,4};
            ManualPickMohoStationStackCell{idx, 5} = ManualPickMohoStationStackCellTmp{idx,5};
            ManualPickMohoStationStackCell{idx, 6} = 1;
        end
        clear ManualPickMohoStationStackCellTmp
    end
    
    % Now get the locations of stations with picks
    % First need to find the number of picks
    pickflags = zeros(1,length(ManualPickMohoStationStackCell));
    for idx=1:length(ManualPickMohoStationStackCell)
        if ~isempty(ManualPickMohoStationStackCell{idx,2}) && ManualPickMohoStationStackCell{idx,6} == 1
            pickflags(idx) = 1;
        end
    end
    npicks = sum(pickflags);
      
    % Now get smaller arrays with just the picks
    picklons = zeros(1,npicks);
    picklats = zeros(1,npicks);
    pickthicknesses = zeros(1,npicks);
    pickcounts = zeros(1,npicks);
    StationNames = cell(1,npicks);
    jdx = 1;
    for idx=1:length(ManualPickMohoStationStackCell)
        if pickflags(idx) == 1
            picklons(jdx) = ManualPickMohoStationStackCell{idx,2};
            picklats(jdx) = ManualPickMohoStationStackCell{idx,3};
            pickthicknesses(jdx) = ManualPickMohoStationStackCell{idx,4};
            kdx = find(RecordMetadataDoubles(:,11) == ManualPickMohoStationStackCell{idx,2} & RecordMetadataDoubles(:,10) == ManualPickMohoStationStackCell{idx,3} & RecordMetadataDoubles(:,2) == 1);
            pickcounts(jdx) = length(kdx);
            StationNames{jdx} =  ManualPickMohoStationStackCell{idx,1};
            jdx = jdx+1;
        end
    end
    
    % All the pick information is gathered into arrays for latitude,
    % longitude, and crustal thickness. Now we write to the file chosen by
    % the user.
    for idx=1:npicks
        fprintf(fid,'%f %f %f %d %s\n',picklons(idx), picklats(idx), pickthicknesses(idx), pickcounts(idx), StationNames{idx});
    end
    
    fclose(fid);

%% ------------------------------------------------------------------------
% export_all_picks_moho_callback
% writes pick information to a user specified text file
% -------------------------------------------------------------------------
function export_all_picks_moho_callback(cbo, eventdata, handles)
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

    % First, we have the user select an output file to write to. If this is
    % canceled, then we just return
    [filename, pathname, filterindex] = uiputfile('*.txt','All picks output text file');
    
    if isequal(filename,0) || isequal(pathname,0)
        disp('Cancelled export all manual moho picks.')
        return
    end
    
    fid = fopen([pathname filename],'w');
    if fid == -1
        disp('Unable to write file.');
        return
    end
    
    
    % Setting flags for whether or not each dataset exists. Initiate to 0
    % and flip to 1 if the data is found
    ccp_cross_section_flag = 0;
    ccp_oned_flag = 0;
    ray_diagram_flag = 0;
    rf_cross_section_flag = 0;
    station_stack_flag = 0;
    
    try
        ManualPickMohoStationStackCell=evalin('base','ManualPickMohoStationStackCell');
    catch
        ManualPickMohoStationStackCell=[];
    end
    if isempty(ManualPickMohoStationStackCell)
        station_stack_flag = 0;
    else
        station_stack_flag = 1;
        a = size(ManualPickMohoStationStackCell);
        if a(2) == 5
            ManualPickMohoStationStackCellTmp = evalin('base','ManualPickMohoStationStackCell');
            ManualPickMohoStationStackCell = cell(a(1), 6);
            for idx=1:a(1)
                ManualPickMohoStationStackCell{idx,1} = ManualPickMohoStationStackCellTmp{idx,1};
                ManualPickMohoStationStackCell{idx,2} = ManualPickMohoStationStackCellTmp{idx,2};
                ManualPickMohoStationStackCell{idx,3} = ManualPickMohoStationStackCellTmp{idx,3};
                ManualPickMohoStationStackCell{idx,4} = ManualPickMohoStationStackCellTmp{idx,4};
                ManualPickMohoStationStackCell{idx,5} = ManualPickMohoStationStackCellTmp{idx,5};
                ManualPickMohoStationStackCell{idx,6} = 1;
            end
            clear ManualPickMohoStationStackCellTmp
        end
    end
    
    try
        ManualPickMohoRFCrossSectionArray=evalin('base','ManualPickMohoRFCrossSectionArray');
    catch
        ManualPickMohoRFCrossSectionArray=[];
    end
    if isempty(ManualPickMohoRFCrossSectionArray)
        rf_cross_section_flag = 0;
    else
        rf_cross_section_flag = 1;
        a = size(ManualPickMohoRFCrossSectionArray);
        if a(2) == 3
            ManualPickMohoRFCrossSectionArrayTmp = ManualPickMohoRFCrossSectionArray;
            ManualPickMohoRFCrossSectionArray = zeros(a(1), 4);
            for idx=1:a(1)
                ManualPickMohoRFCrossSectionArray(idx,1) = ManualPickMohoRFCrossSectionArrayTmp(idx,1);
                ManualPickMohoRFCrossSectionArray(idx,2) = ManualPickMohoRFCrossSectionArrayTmp(idx,2);
                ManualPickMohoRFCrossSectionArray(idx,3) = ManualPickMohoRFCrossSectionArrayTmp(idx,3);
                ManualPickMohoRFCrossSectionArray(idx,4) = 1;
            end
            clear ManualPickMohoRFCrossSectionArrayTmp
        end
    end
    
    try
        ManualPickMohoRayCrossSectionArray=evalin('base','ManualPickMohoRayCrossSectionArray');
    catch
        ManualPickMohoRayCrossSectionArray=[];
    end
    if isempty(ManualPickMohoRayCrossSectionArray)
        ray_diagram_flag = 0;
    else
        ray_diagram_flag = 1;
        a = size(ManualPickMohoRayCrossSectionArray);
        if a(2) == 3
            ManualPickMohoRayCrossSectionArrayTmp = ManualPickMohoRayCrossSectionArray;
            ManualPickMohoRayCrossSectionArray = zeros(a(1), 4);
            for idx=1:a(1)
                ManualPickMohoRayCrossSectionArray(idx,1) = ManualPickMohoRayCrossSectionArrayTmp(idx,1);
                ManualPickMohoRayCrossSectionArray(idx,2) = ManualPickMohoRayCrossSectionArrayTmp(idx,2);
                ManualPickMohoRayCrossSectionArray(idx,3) = ManualPickMohoRayCrossSectionArrayTmp(idx,3);
                ManualPickMohoRayCrossSectionArray(idx,4) = 1;
            end
            clear ManualPickMohoRayCrossSectionArrayTmp
        end
    end
    
    try
        ManualPickMohoCCPoneDArray=evalin('base','ManualPickMohoCCPoneDArray');
    catch
        ManualPickMohoCCPoneDArray=[];
    end
    if isempty(ManualPickMohoCCPoneDArray)
        ccp_oned_flag = 0;
    else
        ccp_oned_flag = 1;
        a = size(ManualPickMohoCCPoneDArray);
        if a(2) == 3
            ManualPickMohoCCPoneDArrayTmp = ManualPickMohoCCPoneDArray;
            ManualPickMohoCCPoneDArray = zeros(a(1), 4);
            for idx=1:a(1)
                ManualPickMohoCCPoneDArray(idx,1) = ManualPickMohoCCPoneDArrayTmp(idx,1);
                ManualPickMohoCCPoneDArray(idx,2) = ManualPickMohoCCPoneDArrayTmp(idx,2);
                ManualPickMohoCCPoneDArray(idx,3) = ManualPickMohoCCPoneDArrayTmp(idx,3);
                ManualPickMohoCCPoneDArray(idx,4) = 1;
            end
            clear ManualPickMohoCCPoneDArrayTmp
        end
    end
    
    try
        ManualPickMohoCCPCrossSectionArray=evalin('base','ManualPickMohoCCPCrossSectionArray');
    catch
        ManualPickMohoCCPCrossSectionArray=[];
    end
    if isempty(ManualPickMohoCCPCrossSectionArray)
        ccp_cross_section_flag = 0;
    else
        ccp_cross_section_flag = 1;
        a = size(ManualPickMohoCCPCrossSectionArray);
        if a(2) == 3
            ManualPickMohoCCPCrossSectionArrayTmp = ManualPickMohoCCPCrossSectionArray;
            ManualPickMohoCCPCrossSectionArray = zeros(a(1), 4);
            for idx=1:a(1)
                ManualPickMohoCCPCrossSectionArray(idx,1) = ManualPickMohoCCPCrossSectionArrayTmp(idx,1);
                ManualPickMohoCCPCrossSectionArray(idx,2) = ManualPickMohoCCPCrossSectionArrayTmp(idx,2);
                ManualPickMohoCCPCrossSectionArray(idx,3) = ManualPickMohoCCPCrossSectionArrayTmp(idx,3);
                ManualPickMohoCCPCrossSectionArray(idx,4) = 1;
            end
            clear ManualPickMohoCCPCrossSectionArrayTmp
        end
    end
    
    % Now get the locations of stations with picks
    % First need to find the number of picks
    if ccp_cross_section_flag == 1
        pickflagsCCPCrossSection = zeros(1,length(ManualPickMohoCCPCrossSectionArray));
        for idx=1:length(ManualPickMohoCCPCrossSectionArray)
            if ManualPickMohoCCPCrossSectionArray(idx,1) ~= 0 && ManualPickMohoCCPCrossSectionArray(idx,4) == 1
                pickflagsCCPCrossSection(idx) = 1;
            end
        end
        npicksCCPCrossSection = sum(pickflagsCCPCrossSection);
    else
        npicksCCPCrossSection = 0;
    end
    
    if ccp_oned_flag == 1
        pickflagsCCPOneD = zeros(1,length(ManualPickMohoCCPoneDArray));
        for idx=1:length(ManualPickMohoCCPoneDArray)
            if ManualPickMohoCCPoneDArray(idx,1) ~= 0 && ManualPickMohoCCPoneDArray(idx,4) == 1
                pickflagsCCPOneD(idx) = 1;
            end
        end
        npicksCCPOneD = sum(pickflagsCCPOneD);
    else
        npicksCCPOneD = 0;
    end
    
    if ray_diagram_flag == 1
        pickflagsRayDiagram = zeros(1,length(ManualPickMohoRayCrossSectionArray));
        for idx=1:length(ManualPickMohoRayCrossSectionArray)
            if ManualPickMohoRayCrossSectionArray(idx,1) ~= 0 && ManualPickMohoRayCrossSectionArray(idx,4) == 1
                pickflagsRayDiagram(idx) = 1;
            end
        end
        npicksRayDiagram = sum(pickflagsRayDiagram);
    else
        npicksRayDiagram = 0;
    end
    
    if rf_cross_section_flag == 1
        pickflagsRFCrossSection = zeros(1,length(ManualPickMohoRFCrossSectionArray));
        for idx=1:length(ManualPickMohoRFCrossSectionArray)
            if ManualPickMohoRFCrossSectionArray(idx,1) ~= 0 && ManualPickMohoRFCrossSectionArray(idx,4) == 1
                pickflagsRFCrossSection(idx) = 1;
            end
        end
        npicksRFCrossSection = sum(pickflagsRFCrossSection);
    else
        npicksRFCrossSection = 0;
    end
    
    if station_stack_flag == 1
        pickflagsStationStacks = zeros(1,length(ManualPickMohoStationStackCell));
        for idx=1:length(ManualPickMohoStationStackCell)
            if ~isempty(ManualPickMohoStationStackCell{idx,2}) && ManualPickMohoStationStackCell{idx,6} == 1
                pickflagsStationStacks(idx) = 1;
            end
        end
        npicksStationStacks = sum(pickflagsStationStacks);
    else
        npicksStationStacks = 0;
    end
    
    % Sum up the picks
    npicks = npicksStationStacks + npicksRFCrossSection + npicksRayDiagram + npicksCCPOneD + npicksCCPCrossSection;
    
    % Now get smaller arrays with just the picks
    picklons = zeros(1,npicks);
    picklats = zeros(1,npicks);
    pickthicknesses = zeros(1,npicks);
    
    jdx = 1;
    for idx=1:length(ManualPickMohoCCPCrossSectionArray)
        if pickflagsCCPCrossSection(idx) == 1
            picklons(jdx) = ManualPickMohoCCPCrossSectionArray(idx,1);
            picklats(jdx) = ManualPickMohoCCPCrossSectionArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoCCPCrossSectionArray(idx,3);
            jdx = jdx+1;
        end
    end
    for idx=1:length(ManualPickMohoCCPoneDArray)
        if pickflagsCCPOneD(idx) == 1
            picklons(jdx) = ManualPickMohoCCPoneDArray(idx,1);
            picklats(jdx) = ManualPickMohoCCPoneDArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoCCPoneDArray(idx,3);
            jdx = jdx+1;
        end
    end
    for idx=1:length(ManualPickMohoRayCrossSectionArray)
        if pickflagsRayDiagram(idx) == 1
            picklons(jdx) = ManualPickMohoRayCrossSectionArray(idx,1);
            picklats(jdx) = ManualPickMohoRayCrossSectionArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoRayCrossSectionArray(idx,3);
            jdx = jdx+1;
        end
    end
    for idx=1:length(ManualPickMohoRFCrossSectionArray)
        if pickflagsRFCrossSection(idx) == 1
            picklons(jdx) = ManualPickMohoRFCrossSectionArray(idx,1);
            picklats(jdx) = ManualPickMohoRFCrossSectionArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoRFCrossSectionArray(idx,3);
            jdx = jdx+1;
        end
    end
    for idx=1:length(ManualPickMohoStationStackCell)
        if pickflagsStationStacks(idx) == 1
            picklons(jdx) = ManualPickMohoStationStackCell{idx,2};
            picklats(jdx) = ManualPickMohoStationStackCell{idx,3};
            pickthicknesses(jdx) = ManualPickMohoStationStackCell{idx,4};
            jdx = jdx+1;
        end
    end
    
    % All the pick information is gathered into arrays for latitude,
    % longitude, and crustal thickness. Now we write to the file chosen by
    % the user.
    for idx=1:npicks
        fprintf(fid,'%f %f %f\n',picklons(idx), picklats(idx), pickthicknesses(idx));
    end
    
    fclose(fid);
    
%% ------------------------------------------------------------------------
% plot_all_picks_moho_callback
% pops up a quick plot of moho depths
% -------------------------------------------------------------------------
function plot_all_picks_moho_callback(cbo, eventdata, handles)
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
    load FL_coasts
    load FL_plates
    load FL_stateBoundaries

    % Setting flags for whether or not each dataset exists. Initiate to 0
    % and flip to 1 if the data is found
    ccp_cross_section_flag = 0;
    ccp_oned_flag = 0;
    ray_diagram_flag = 0;
    rf_cross_section_flag = 0;
    station_stack_flag = 0;
    
    try
        ManualPickMohoStationStackCell=evalin('base','ManualPickMohoStationStackCell');
    catch
        ManualPickMohoStationStackCell=[];
    end
    if isempty(ManualPickMohoStationStackCell)
        station_stack_flag = 0;
    else
        station_stack_flag = 1;
        a = size(ManualPickMohoStationStackCell);
        if a(2) == 5
            ManualPickMohoStationStackCellTmp = evalin('base','ManualPickMohoStationStackCell');
            ManualPickMohoStationStackCell = cell(a(1), 6);
            for idx=1:a(1)
                ManualPickMohoStationStackCell{idx,1} = ManualPickMohoStationStackCellTmp{idx,1};
                ManualPickMohoStationStackCell{idx,2} = ManualPickMohoStationStackCellTmp{idx,2};
                ManualPickMohoStationStackCell{idx,3} = ManualPickMohoStationStackCellTmp{idx,3};
                ManualPickMohoStationStackCell{idx,4} = ManualPickMohoStationStackCellTmp{idx,4};
                ManualPickMohoStationStackCell{idx,5} = ManualPickMohoStationStackCellTmp{idx,5};
                ManualPickMohoStationStackCell{idx,6} = 1;
            end
            clear ManualPickMohoStationStackCellTmp
        end
    end
    
    try
        ManualPickMohoRFCrossSectionArray=evalin('base','ManualPickMohoRFCrossSectionArray');
    catch
        ManualPickMohoRFCrossSectionArray=[];
    end
    if isempty(ManualPickMohoRFCrossSectionArray)
        rf_cross_section_flag = 0;
    else
        rf_cross_section_flag = 1;
        a = size(ManualPickMohoRFCrossSectionArray);
        if a(2) == 3
            ManualPickMohoRFCrossSectionArrayTmp = ManualPickMohoRFCrossSectionArray;
            ManualPickMohoRFCrossSectionArray = zeros(a(1), 4);
            for idx=1:a(1)
                ManualPickMohoRFCrossSectionArray(idx,1) = ManualPickMohoRFCrossSectionArrayTmp(idx,1);
                ManualPickMohoRFCrossSectionArray(idx,2) = ManualPickMohoRFCrossSectionArrayTmp(idx,2);
                ManualPickMohoRFCrossSectionArray(idx,3) = ManualPickMohoRFCrossSectionArrayTmp(idx,3);
                ManualPickMohoRFCrossSectionArray(idx,4) = 1;
            end
            clear ManualPickMohoRFCrossSectionArrayTmp
        end
    end
    
    try
        ManualPickMohoRayCrossSectionArray=evalin('base','ManualPickMohoRayCrossSectionArray');
    catch
        ManualPickMohoRayCrossSectionArray=[];
    end
    if isempty(ManualPickMohoRayCrossSectionArray)
        ray_diagram_flag = 0;
    else
        ray_diagram_flag = 1;
        a = size(ManualPickMohoRayCrossSectionArray);
        if a(2) == 3
            ManualPickMohoRayCrossSectionArrayTmp = ManualPickMohoRayCrossSectionArray;
            ManualPickMohoRayCrossSectionArray = zeros(a(1), 4);
            for idx=1:a(1)
                ManualPickMohoRayCrossSectionArray(idx,1) = ManualPickMohoRayCrossSectionArrayTmp(idx,1);
                ManualPickMohoRayCrossSectionArray(idx,2) = ManualPickMohoRayCrossSectionArrayTmp(idx,2);
                ManualPickMohoRayCrossSectionArray(idx,3) = ManualPickMohoRayCrossSectionArrayTmp(idx,3);
                ManualPickMohoRayCrossSectionArray(idx,4) = 1;
            end
            clear ManualPickMohoRayCrossSectionArrayTmp
        end
    end
    
    try
        ManualPickMohoCCPoneDArray=evalin('base','ManualPickMohoCCPoneDArray');
    catch
        ManualPickMohoCCPoneDArray=[];
    end
    if isempty(ManualPickMohoCCPoneDArray)
        ccp_oned_flag = 0;
    else
        ccp_oned_flag = 1;
        a = size(ManualPickMohoCCPoneDArray);
        if a(2) == 3
            ManualPickMohoCCPoneDArrayTmp = ManualPickMohoCCPoneDArray;
            ManualPickMohoCCPoneDArray = zeros(a(1), 4);
            for idx=1:a(1)
                ManualPickMohoCCPoneDArray(idx,1) = ManualPickMohoCCPoneDArrayTmp(idx,1);
                ManualPickMohoCCPoneDArray(idx,2) = ManualPickMohoCCPoneDArrayTmp(idx,2);
                ManualPickMohoCCPoneDArray(idx,3) = ManualPickMohoCCPoneDArrayTmp(idx,3);
                ManualPickMohoCCPoneDArray(idx,4) = 1;
            end
            clear ManualPickMohoCCPoneDArrayTmp
        end
    end
    
    try
        ManualPickMohoCCPCrossSectionArray=evalin('base','ManualPickMohoCCPCrossSectionArray');
    catch
        ManualPickMohoCCPCrossSectionArray=[];
    end
    if isempty(ManualPickMohoCCPCrossSectionArray)
        ccp_cross_section_flag = 0;
    else
        ccp_cross_section_flag = 1;
        a = size(ManualPickMohoCCPCrossSectionArray);
        if a(2) == 3
            ManualPickMohoCCPCrossSectionArrayTmp = ManualPickMohoCCPCrossSectionArray;
            ManualPickMohoCCPCrossSectionArray = zeros(a(1), 4);
            for idx=1:a(1)
                ManualPickMohoCCPCrossSectionArray(idx,1) = ManualPickMohoCCPCrossSectionArrayTmp(idx,1);
                ManualPickMohoCCPCrossSectionArray(idx,2) = ManualPickMohoCCPCrossSectionArrayTmp(idx,2);
                ManualPickMohoCCPCrossSectionArray(idx,3) = ManualPickMohoCCPCrossSectionArrayTmp(idx,3);
                ManualPickMohoCCPCrossSectionArray(idx,4) = 1;
            end
            clear ManualPickMohoCCPCrossSectionArrayTmp
        end
    end
    
    %--------------------------------------------------------------------------
    % Setup dimensions of the map
    %--------------------------------------------------------------------------
    MainPos = [0 0 130 37];
    
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
    
    % Create a map view axis
    MapFigure = figure('Name','CCP cross sections moho','Color','White','Units','Normalized','Position',[0.1 0.1 0.5 0.5800],'CreateFcn',{@movegui_kce,'center'});
    MapViewPanel = uipanel('Title','Map view','FontSize',12,'BackgroundColor','White','Units','Normalized','Position',[0.01 0.1 0.95 0.85]);
    MapViewAxesHandles = axes('Parent',MapViewPanel,'Units','Normalized','Position',[.02 .05 .96 .9]);
    
    MyColormap = FuncLabPreferences{19};
    MyColormapFlipped = FuncLabPreferences{20};
    MinimumLatitude = sscanf(FuncLabPreferences{14},'%f');
	MaximumLatitude = sscanf(FuncLabPreferences{13},'%f');
	MinimumLongitude = sscanf(FuncLabPreferences{15},'%f');
	MaximumLongitude = sscanf(FuncLabPreferences{16},'%f');

    minlon = floor(MinimumLongitude);
    maxlon = ceil(MaximumLongitude);
    minlat = floor(MinimumLatitude);
    maxlat = ceil(MaximumLatitude);
    m_proj(MapProjection,'latitude',[minlat maxlat], 'longitude', [minlon maxlon]);
    %m_proj('Hammer-Aitoff','latitude',[-90 90],'longitude',[-180 180]);

    % Makes the initial plot view - global coast lines and a shaded box for the
    % CCP image volume
    %plot(ncst(:,1),ncst(:,2),'k')
    hold on
    %m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
    m_coast('patch',[.9 .9 .9],'edgecolor','black');
    m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
    m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
    %axis([-180 180 -90 90])
    m_grid('xtick',4,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');

    OnColor = [.3 .3 .3];
    OffColor = [1 .5 .5];
    CurrentColor = [ 1 .7 0];
    SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
    SetOffColor = abs(cross(SetOnColor,OnColor));
    % Add the stations
    %StationLocations = unique([RecordMetadataDoubles(:,10), RecordMetadataDoubles(:,11)],'rows');
    %m_line(StationLocations(:,2),StationLocations(:,1),'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
    
    % Background is set    
    % Now get the locations of stations with picks
    % First need to find the number of picks
    if ccp_cross_section_flag == 1
        pickflagsCCPCrossSection = zeros(1,length(ManualPickMohoCCPCrossSectionArray));
        for idx=1:length(ManualPickMohoCCPCrossSectionArray)
            if ManualPickMohoCCPCrossSectionArray(idx,1) ~= 0 && ManualPickMohoCCPCrossSectionArray(idx,4) == 1
                pickflagsCCPCrossSection(idx) = 1;
            end
        end
        npicksCCPCrossSection = sum(pickflagsCCPCrossSection);
    else
        npicksCCPCrossSection = 0;
    end
    
    if ccp_oned_flag == 1
        pickflagsCCPOneD = zeros(1,length(ManualPickMohoCCPoneDArray));
        for idx=1:length(ManualPickMohoCCPoneDArray)
            if ManualPickMohoCCPoneDArray(idx,1) ~= 0 && ManualPickMohoCCPoneDArray(idx,4) == 1
                pickflagsCCPOneD(idx) = 1;
            end
        end
        npicksCCPOneD = sum(pickflagsCCPOneD);
    else
        npicksCCPOneD = 0;
    end
    
    if ray_diagram_flag == 1
        pickflagsRayDiagram = zeros(1,length(ManualPickMohoRayCrossSectionArray));
        for idx=1:length(ManualPickMohoRayCrossSectionArray)
            if ManualPickMohoRayCrossSectionArray(idx,1) ~= 0 && ManualPickMohoRayCrossSectionArray(idx,4) == 1
                pickflagsRayDiagram(idx) = 1;
            end
        end
        npicksRayDiagram = sum(pickflagsRayDiagram);
    else
        npicksRayDiagram = 0;
    end
    
    if rf_cross_section_flag == 1
        pickflagsRFCrossSection = zeros(1,length(ManualPickMohoRFCrossSectionArray));
        for idx=1:length(ManualPickMohoRFCrossSectionArray)
            if ManualPickMohoRFCrossSectionArray(idx,1) ~= 0 && ManualPickMohoRFCrossSectionArray(idx,4) == 1
                pickflagsRFCrossSection(idx) = 1;
            end
        end
        npicksRFCrossSection = sum(pickflagsRFCrossSection);
    else
        npicksRFCrossSection = 0;
    end
    
    if station_stack_flag == 1
        pickflagsStationStacks = zeros(1,length(ManualPickMohoStationStackCell));
        for idx=1:length(ManualPickMohoStationStackCell)
            if ~isempty(ManualPickMohoStationStackCell{idx,2}) && ManualPickMohoStationStackCell{idx,6} == 1
                pickflagsStationStacks(idx) = 1;
            end
        end
        npicksStationStacks = sum(pickflagsStationStacks);
    else
        npicksStationStacks = 0;
    end
    
    % Sum up the picks
    npicks = npicksStationStacks + npicksRFCrossSection + npicksRayDiagram + npicksCCPOneD + npicksCCPCrossSection;
    
    % Now get smaller arrays with just the picks
    picklons = zeros(1,npicks);
    picklats = zeros(1,npicks);
    pickthicknesses = zeros(1,npicks);
    
    jdx = 1;
    for idx=1:length(ManualPickMohoCCPCrossSectionArray)
        if pickflagsCCPCrossSection(idx) == 1
            picklons(jdx) = ManualPickMohoCCPCrossSectionArray(idx,1);
            picklats(jdx) = ManualPickMohoCCPCrossSectionArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoCCPCrossSectionArray(idx,3);
            jdx = jdx+1;
        end
    end
    for idx=1:length(ManualPickMohoCCPoneDArray)
        if pickflagsCCPOneD(idx) == 1
            picklons(jdx) = ManualPickMohoCCPoneDArray(idx,1);
            picklats(jdx) = ManualPickMohoCCPoneDArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoCCPoneDArray(idx,3);
            jdx = jdx+1;
        end
    end
    for idx=1:length(ManualPickMohoRayCrossSectionArray)
        if pickflagsRayDiagram(idx) == 1
            picklons(jdx) = ManualPickMohoRayCrossSectionArray(idx,1);
            picklats(jdx) = ManualPickMohoRayCrossSectionArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoRayCrossSectionArray(idx,3);
            jdx = jdx+1;
        end
    end
    for idx=1:length(ManualPickMohoRFCrossSectionArray)
        if pickflagsRFCrossSection(idx) == 1
            picklons(jdx) = ManualPickMohoRFCrossSectionArray(idx,1);
            picklats(jdx) = ManualPickMohoRFCrossSectionArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoRFCrossSectionArray(idx,3);
            jdx = jdx+1;
        end
    end
    for idx=1:length(ManualPickMohoStationStackCell)
        if pickflagsStationStacks(idx) == 1
            picklons(jdx) = ManualPickMohoStationStackCell{idx,2};
            picklats(jdx) = ManualPickMohoStationStackCell{idx,3};
            pickthicknesses(jdx) = ManualPickMohoStationStackCell{idx,4};
            jdx = jdx+1;
        end
    end
    
    % convert to map projection
    picklonsxy = zeros(1,npicks);
    picklatsxy = zeros(1,npicks);
    for idx=1:npicks
        [picklonsxy(idx), picklatsxy(idx)] = m_ll2xy(picklons(idx), picklats(idx));
    end
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    if FuncLabPreferences{20} == 0
        cmap = cptcmap(FuncLabPreferences{19});
    else
        cmap = cptcmap(FuncLabPreferences{19},'flip',true);
    end
    colormap(cmap);
    scatter(picklonsxy', picklatsxy', 100, pickthicknesses', 'filled')
    c=colorbar;
    xlabel(c,'Crustal Thickness, km')
    
%% ------------------------------------------------------------------------
% plot_ccp_cross_section_moho_callback
% pops up a quick plot of moho depths
% -------------------------------------------------------------------------
function plot_ccp_cross_section_moho_callback(cbo, eventdata, handles)
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
    load FL_coasts
    load FL_plates
    load FL_stateBoundaries

    % First we need to evaluate if a structure to hold all this information
    % exists in the base set. If not, we'll create it and provide entries for
    % all the stations
    try
        ManualPickMohoCCPCrossSectionArray=evalin('base','ManualPickMohoCCPCrossSectionArray');
    catch
        ManualPickMohoCCPCrossSectionArray=[];
    end
    if isempty(ManualPickMohoCCPCrossSectionArray)
        disp('Error, picks not found!');
        return
    end
    a = size(ManualPickMohoCCPCrossSectionArray);
    if a(2) == 3
        ManualPickMohoCCPCrossSectionArrayTmp = ManualPickMohoCCPCrossSectionArray;
        ManualPickMohoCCPCrossSectionArray = zeros(a(1),4);
        for idx=1:a(1)
            ManualPickMohoCCPCrossSectionArray(idx, 1) = ManualPickMohoCCPCrossSectionArrayTmp(idx,1);
            ManualPickMohoCCPCrossSectionArray(idx, 2) = ManualPickMohoCCPCrossSectionArrayTmp(idx,2);
            ManualPickMohoCCPCrossSectionArray(idx, 3) = ManualPickMohoCCPCrossSectionArrayTmp(idx,3);
            ManualPickMohoCCPCrossSectionArray(idx, 4) = 1;
        end
        clear ManualPickMohoCCPCrossSectionArrayTmp
    end
    
    
    %--------------------------------------------------------------------------
    % Setup dimensions of the map
    %--------------------------------------------------------------------------
    MainPos = [0 0 130 37];
    
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
    
    % Create a map view axis
    MapFigure = figure('Name','CCP cross sections moho','Color','White','Units','Normalized','Position',[0.1 0.1 0.5 0.5800],'CreateFcn',{@movegui_kce,'center'});
    MapViewPanel = uipanel('Title','Map view','FontSize',12,'BackgroundColor','White','Units','Normalized','Position',[0.01 0.1 0.95 0.85]);
    MapViewAxesHandles = axes('Parent',MapViewPanel,'Units','Normalized','Position',[.02 .05 .96 .9]);
    
    MyColormap = FuncLabPreferences{19};
    MyColormapFlipped = FuncLabPreferences{20};
    MinimumLatitude = sscanf(FuncLabPreferences{14},'%f');
	MaximumLatitude = sscanf(FuncLabPreferences{13},'%f');
	MinimumLongitude = sscanf(FuncLabPreferences{15},'%f');
	MaximumLongitude = sscanf(FuncLabPreferences{16},'%f');

    minlon = floor(MinimumLongitude);
    maxlon = ceil(MaximumLongitude);
    minlat = floor(MinimumLatitude);
    maxlat = ceil(MaximumLatitude);
    m_proj(MapProjection,'latitude',[minlat maxlat], 'longitude', [minlon maxlon]);
    %m_proj('Hammer-Aitoff','latitude',[-90 90],'longitude',[-180 180]);

    % Makes the initial plot view - global coast lines and a shaded box for the
    % CCP image volume
    %plot(ncst(:,1),ncst(:,2),'k')
    hold on
    %m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
    m_coast('patch',[.9 .9 .9],'edgecolor','black');
    m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
    m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
    %axis([-180 180 -90 90])
    m_grid('xtick',4,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');

    OnColor = [.3 .3 .3];
    OffColor = [1 .5 .5];
    CurrentColor = [ 1 .7 0];
    SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
    SetOffColor = abs(cross(SetOnColor,OnColor));
    % Add the stations
    %StationLocations = unique([RecordMetadataDoubles(:,10), RecordMetadataDoubles(:,11)],'rows');
    %m_line(StationLocations(:,2),StationLocations(:,1),'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
    
    % Background is set
    % Now get the locations of stations with picks
    % First need to find the number of picks
    pickflags = zeros(1,length(ManualPickMohoCCPCrossSectionArray));
    for idx=1:length(ManualPickMohoCCPCrossSectionArray)
        if ManualPickMohoCCPCrossSectionArray(idx,1) ~= 0 && ManualPickMohoCCPCrossSectionArray(idx,4) == 1
            pickflags(idx) = 1;
        end
    end
    npicks = sum(pickflags);
    % Now get smaller arrays with just the picks
    picklons = zeros(1,npicks);
    picklats = zeros(1,npicks);
    pickthicknesses = zeros(1,npicks);
    jdx = 1;
    for idx=1:length(ManualPickMohoCCPCrossSectionArray)
        if pickflags(idx) == 1
            picklons(jdx) = ManualPickMohoCCPCrossSectionArray(idx,1);
            picklats(jdx) = ManualPickMohoCCPCrossSectionArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoCCPCrossSectionArray(idx,3);
            jdx = jdx+1;
        end
    end
    % convert to map projection
    picklonsxy = zeros(1,npicks);
    picklatsxy = zeros(1,npicks);
    for idx=1:npicks
        [picklonsxy(idx), picklatsxy(idx)] = m_ll2xy(picklons(idx), picklats(idx));
    end
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    if FuncLabPreferences{20} == 0
        cmap = cptcmap(FuncLabPreferences{19});
    else
        cmap = cptcmap(FuncLabPreferences{19},'flip',true);
    end
    colormap(cmap);
    scatter(picklonsxy', picklatsxy', 100, pickthicknesses', 'filled')
    c=colorbar;
    xlabel(c,'Crustal Thickness, km')

%% ------------------------------------------------------------------------
% plot_ccp_oned_moho_callback
% pops up a quick plot of moho depths
% -------------------------------------------------------------------------
function plot_ccp_oned_moho_callback(cbo, eventdata, handles)
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
    load FL_coasts
    load FL_plates
    load FL_stateBoundaries

    % First we need to evaluate if a structure to hold all this information
    % exists in the base set. If not, we'll create it and provide entries for
    % all the stations
    try
        ManualPickMohoCCPoneDArray=evalin('base','ManualPickMohoCCPoneDArray');
    catch
        ManualPickMohoCCPoneDArray=[];
    end
    if isempty(ManualPickMohoCCPoneDArray)
        disp('Error, picks not found!');
        return
    end
    a = size(ManualPickMohoCCPoneDArray);
    if a(2) == 3
        ManualPickMohoCCPoneDArrayTmp = ManualPickMohoCCPoneDArray;
        ManualPickMohoCCPoneDArray = zeros(a(1),4);
        for idx=1:a(1)
            ManualPickMohoCCPoneDArray(idx, 1) = ManualPickMohoCCPoneDArrayTmp(idx,1);
            ManualPickMohoCCPoneDArray(idx, 2) = ManualPickMohoCCPoneDArrayTmp(idx,2);
            ManualPickMohoCCPoneDArray(idx, 3) = ManualPickMohoCCPoneDArrayTmp(idx,3);
            ManualPickMohoCCPoneDArray(idx, 4) = 1;
        end
        clear ManualPickMohoCCPoneDArrayTmp
    end
    
    %--------------------------------------------------------------------------
    % Setup dimensions of the map
    %--------------------------------------------------------------------------
    MainPos = [0 0 130 37];
    
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
    
    % Create a map view axis
    MapFigure = figure('Name','CCP 1D points moho','Color','White','Units','Normalized','Position',[0.1 0.1 0.5 0.5800],'CreateFcn',{@movegui_kce,'center'});
    MapViewPanel = uipanel('Title','Map view','FontSize',12,'BackgroundColor','White','Units','Normalized','Position',[0.01 0.1 0.95 0.85]);
    MapViewAxesHandles = axes('Parent',MapViewPanel,'Units','Normalized','Position',[.02 .05 .96 .9]);
    
    MyColormap = FuncLabPreferences{19};
    MyColormapFlipped = FuncLabPreferences{20};
    MinimumLatitude = sscanf(FuncLabPreferences{14},'%f');
	MaximumLatitude = sscanf(FuncLabPreferences{13},'%f');
	MinimumLongitude = sscanf(FuncLabPreferences{15},'%f');
	MaximumLongitude = sscanf(FuncLabPreferences{16},'%f');

    minlon = floor(MinimumLongitude);
    maxlon = ceil(MaximumLongitude);
    minlat = floor(MinimumLatitude);
    maxlat = ceil(MaximumLatitude);
    m_proj(MapProjection,'latitude',[minlat maxlat], 'longitude', [minlon maxlon]);
    %m_proj('Hammer-Aitoff','latitude',[-90 90],'longitude',[-180 180]);

    % Makes the initial plot view - global coast lines and a shaded box for the
    % CCP image volume
    %plot(ncst(:,1),ncst(:,2),'k')
    hold on
    %m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
    m_coast('patch',[.9 .9 .9],'edgecolor','black');
    m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
    m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
    %axis([-180 180 -90 90])
    m_grid('xtick',4,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');

    OnColor = [.3 .3 .3];
    OffColor = [1 .5 .5];
    CurrentColor = [ 1 .7 0];
    SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
    SetOffColor = abs(cross(SetOnColor,OnColor));
    % Add the stations
    %StationLocations = unique([RecordMetadataDoubles(:,10), RecordMetadataDoubles(:,11)],'rows');
    %m_line(StationLocations(:,2),StationLocations(:,1),'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
    
    % Background is set
    % Now get the locations of stations with picks
    % First need to find the number of picks
    pickflags = zeros(1,length(ManualPickMohoCCPoneDArray));
    for idx=1:length(ManualPickMohoCCPoneDArray)
        if ManualPickMohoCCPoneDArray(idx,1) ~= 0 && ManualPickMohoCCPoneDArray(idx,4) == 1
            pickflags(idx) = 1;
        end
    end
    npicks = sum(pickflags);
    % Now get smaller arrays with just the picks
    picklons = zeros(1,npicks);
    picklats = zeros(1,npicks);
    pickthicknesses = zeros(1,npicks);
    jdx = 1;
    for idx=1:length(ManualPickMohoCCPoneDArray)
        if pickflags(idx) == 1
            picklons(jdx) = ManualPickMohoCCPoneDArray(idx,1);
            picklats(jdx) = ManualPickMohoCCPoneDArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoCCPoneDArray(idx,3);
            jdx = jdx+1;
        end
    end
    % convert to map projection
    picklonsxy = zeros(1,npicks);
    picklatsxy = zeros(1,npicks);
    for idx=1:npicks
        [picklonsxy(idx), picklatsxy(idx)] = m_ll2xy(picklons(idx), picklats(idx));
    end
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    if FuncLabPreferences{20} == 0
        cmap = cptcmap(FuncLabPreferences{19});
    else
        cmap = cptcmap(FuncLabPreferences{19},'flip',true);
    end
    colormap(cmap);
    scatter(picklonsxy', picklatsxy', 100, pickthicknesses', 'filled')
    c=colorbar;
    xlabel(c,'Crustal Thickness, km')
    
%% ------------------------------------------------------------------------
% plot_ray_diagram_cross_section_moho_callback
% pops up a quick plot of moho depths
% -------------------------------------------------------------------------
function plot_ray_diagram_cross_section_moho_callback(cbo, eventdata, handles)
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
    load FL_coasts
    load FL_plates
    load FL_stateBoundaries

    % First we need to evaluate if a structure to hold all this information
    % exists in the base set. If not, we'll create it and provide entries for
    % all the stations
    try
        ManualPickMohoRayCrossSectionArray=evalin('base','ManualPickMohoRayCrossSectionArray');
    catch
        ManualPickMohoRayCrossSectionArray=[];
    end
    if isempty(ManualPickMohoRayCrossSectionArray)
        disp('Error, picks not found!');
        return
    end
    a = size(ManualPickMohoRayCrossSectionArray);
    if a(2) == 3
        ManualPickMohoRayCrossSectionArrayTmp = ManualPickMohoRayCrossSectionArray;
        ManualPickMohoRayCrossSectionArray = zeros(a(1),4);
        for idx=1:a(1)
            ManualPickMohoRayCrossSectionArray(idx, 1) = ManualPickMohoRayCrossSectionArrayTmp(idx,1);
            ManualPickMohoRayCrossSectionArray(idx, 2) = ManualPickMohoRayCrossSectionArrayTmp(idx,2);
            ManualPickMohoRayCrossSectionArray(idx, 3) = ManualPickMohoRayCrossSectionArrayTmp(idx,3);
            ManualPickMohoRayCrossSectionArray(idx, 4) = 1;
        end
        clear ManualPickMohoRayCrossSectionArrayTmp
    end
    
    %--------------------------------------------------------------------------
    % Setup dimensions of the map
    %--------------------------------------------------------------------------
    MainPos = [0 0 130 37];
    
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
    
    % Create a map view axis
    MapFigure = figure('Name','2D CCP cross section moho','Color','White','Units','Normalized','Position',[0.1 0.1 0.5 0.5800],'CreateFcn',{@movegui_kce,'center'});
    MapViewPanel = uipanel('Title','Map view','FontSize',12,'BackgroundColor','White','Units','Normalized','Position',[0.01 0.1 0.95 0.85]);
    MapViewAxesHandles = axes('Parent',MapViewPanel,'Units','Normalized','Position',[.02 .05 .96 .9]);
    
    MyColormap = FuncLabPreferences{19};
    MyColormapFlipped = FuncLabPreferences{20};
    MinimumLatitude = sscanf(FuncLabPreferences{14},'%f');
	MaximumLatitude = sscanf(FuncLabPreferences{13},'%f');
	MinimumLongitude = sscanf(FuncLabPreferences{15},'%f');
	MaximumLongitude = sscanf(FuncLabPreferences{16},'%f');

    minlon = floor(MinimumLongitude);
    maxlon = ceil(MaximumLongitude);
    minlat = floor(MinimumLatitude);
    maxlat = ceil(MaximumLatitude);
    m_proj(MapProjection,'latitude',[minlat maxlat], 'longitude', [minlon maxlon]);
    %m_proj('Hammer-Aitoff','latitude',[-90 90],'longitude',[-180 180]);

    % Makes the initial plot view - global coast lines and a shaded box for the
    % CCP image volume
    %plot(ncst(:,1),ncst(:,2),'k')
    hold on
    %m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
    m_coast('patch',[.9 .9 .9],'edgecolor','black');
    m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
    m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
    %axis([-180 180 -90 90])
    m_grid('xtick',4,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');

    OnColor = [.3 .3 .3];
    OffColor = [1 .5 .5];
    CurrentColor = [ 1 .7 0];
    SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
    SetOffColor = abs(cross(SetOnColor,OnColor));
    % Add the stations
    %StationLocations = unique([RecordMetadataDoubles(:,10), RecordMetadataDoubles(:,11)],'rows');
    %m_line(StationLocations(:,2),StationLocations(:,1),'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
    
    % Background is set
    % Now get the locations of stations with picks
    % First need to find the number of picks
    pickflags = zeros(1,length(ManualPickMohoRayCrossSectionArray));
    for idx=1:length(ManualPickMohoRayCrossSectionArray)
        if ManualPickMohoRayCrossSectionArray(idx,1) ~= 0 && ManualPickMohoRayCrossSectionArray(idx,4) == 1
            pickflags(idx) = 1;
        end
    end
    npicks = sum(pickflags);
    % Now get smaller arrays with just the picks
    picklons = zeros(1,npicks);
    picklats = zeros(1,npicks);
    pickthicknesses = zeros(1,npicks);
    jdx = 1;
    for idx=1:length(ManualPickMohoRayCrossSectionArray)
        if pickflags(idx) == 1
            picklons(jdx) = ManualPickMohoRayCrossSectionArray(idx,1);
            picklats(jdx) = ManualPickMohoRayCrossSectionArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoRayCrossSectionArray(idx,3);
            jdx = jdx+1;
        end
    end
    % convert to map projection
    picklonsxy = zeros(1,npicks);
    picklatsxy = zeros(1,npicks);
    for idx=1:npicks
        [picklonsxy(idx), picklatsxy(idx)] = m_ll2xy(picklons(idx), picklats(idx));
    end
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    if FuncLabPreferences{20} == 0
        cmap = cptcmap(FuncLabPreferences{19});
    else
        cmap = cptcmap(FuncLabPreferences{19},'flip',true);
    end
    colormap(cmap);
    scatter(picklonsxy', picklatsxy', 100, pickthicknesses', 'filled')
    c=colorbar;
    xlabel(c,'Crustal Thickness, km')
    
%% ------------------------------------------------------------------------
% plot_rf_cross_section_moho_callback
% pops up a quick plot of moho depths
% -------------------------------------------------------------------------
function plot_rf_cross_section_moho_callback(cbo, eventdata, handles)
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
    load FL_coasts
    load FL_plates
    load FL_stateBoundaries

    % First we need to evaluate if a structure to hold all this information
    % exists in the base set. If not, we'll create it and provide entries for
    % all the stations
    try
        ManualPickMohoRFCrossSectionArray=evalin('base','ManualPickMohoRFCrossSectionArray');
    catch
        ManualPickMohoRFCrossSectionArray=[];
    end
    if isempty(ManualPickMohoRFCrossSectionArray)
        disp('Error, picks not found!');
        return
    end
    a = size(ManualPickMohoRFCrossSectionArray);
    if a(2) == 3
        ManualPickMohoRFCrossSectionArrayTmp = ManualPickMohoRFCrossSectionArray;
        ManualPickMohoRFCrossSectionArray = zeros(a(1),4);
        for idx=1:a(1)
            ManualPickMohoRFCrossSectionArray(idx, 1) = ManualPickMohoRFCrossSectionArrayTmp(idx,1);
            ManualPickMohoRFCrossSectionArray(idx, 2) = ManualPickMohoRFCrossSectionArrayTmp(idx,2);
            ManualPickMohoRFCrossSectionArray(idx, 3) = ManualPickMohoRFCrossSectionArrayTmp(idx,3);
            ManualPickMohoRFCrossSectionArray(idx, 4) = 1;
        end
        clear ManualPickMohoRFCrossSectionArrayTmp
    end
    
    %--------------------------------------------------------------------------
    % Setup dimensions of the map
    %--------------------------------------------------------------------------
    MainPos = [0 0 130 37];
    
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
    
    % Create a map view axis
    MapFigure = figure('Name','RF cross section moho','Color','White','Units','Normalized','Position',[0.1 0.1 0.5 0.5800],'CreateFcn',{@movegui_kce,'center'});
    MapViewPanel = uipanel('Title','Map view','FontSize',12,'BackgroundColor','White','Units','Normalized','Position',[0.01 0.1 0.95 0.85]);
    MapViewAxesHandles = axes('Parent',MapViewPanel,'Units','Normalized','Position',[.02 .05 .96 .9]);
    
    MyColormap = FuncLabPreferences{19};
    MyColormapFlipped = FuncLabPreferences{20};
    MinimumLatitude = sscanf(FuncLabPreferences{14},'%f');
	MaximumLatitude = sscanf(FuncLabPreferences{13},'%f');
	MinimumLongitude = sscanf(FuncLabPreferences{15},'%f');
	MaximumLongitude = sscanf(FuncLabPreferences{16},'%f');

    minlon = floor(MinimumLongitude);
    maxlon = ceil(MaximumLongitude);
    minlat = floor(MinimumLatitude);
    maxlat = ceil(MaximumLatitude);
    m_proj(MapProjection,'latitude',[minlat maxlat], 'longitude', [minlon maxlon]);
    %m_proj('Hammer-Aitoff','latitude',[-90 90],'longitude',[-180 180]);

    % Makes the initial plot view - global coast lines and a shaded box for the
    % CCP image volume
    %plot(ncst(:,1),ncst(:,2),'k')
    hold on
    %m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
    m_coast('patch',[.9 .9 .9],'edgecolor','black');
    m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
    m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
    %axis([-180 180 -90 90])
    m_grid('xtick',4,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');

    OnColor = [.3 .3 .3];
    OffColor = [1 .5 .5];
    CurrentColor = [ 1 .7 0];
    SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
    SetOffColor = abs(cross(SetOnColor,OnColor));
    % Add the stations
    %StationLocations = unique([RecordMetadataDoubles(:,10), RecordMetadataDoubles(:,11)],'rows');
    %m_line(StationLocations(:,2),StationLocations(:,1),'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
    
    % Background is set
    % Now get the locations of stations with picks
    % First need to find the number of picks
    pickflags = zeros(1,length(ManualPickMohoRFCrossSectionArray));
    for idx=1:length(ManualPickMohoRFCrossSectionArray)
        if ManualPickMohoRFCrossSectionArray(idx,1) ~= 0 && ManualPickMohoRFCrossSectionArray(idx,4) == 1
            pickflags(idx) = 1;
        end
    end
    npicks = sum(pickflags);
    % Now get smaller arrays with just the picks
    picklons = zeros(1,npicks);
    picklats = zeros(1,npicks);
    pickthicknesses = zeros(1,npicks);
    jdx = 1;
    for idx=1:length(ManualPickMohoRFCrossSectionArray)
        if pickflags(idx) == 1
            picklons(jdx) = ManualPickMohoRFCrossSectionArray(idx,1);
            picklats(jdx) = ManualPickMohoRFCrossSectionArray(idx,2);
            pickthicknesses(jdx) = ManualPickMohoRFCrossSectionArray(idx,3);
            jdx = jdx+1;
        end
    end
    % convert to map projection
    picklonsxy = zeros(1,npicks);
    picklatsxy = zeros(1,npicks);
    for idx=1:npicks
        [picklonsxy(idx), picklatsxy(idx)] = m_ll2xy(picklons(idx), picklats(idx));
    end
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    if FuncLabPreferences{20} == 0
        cmap = cptcmap(FuncLabPreferences{19});
    else
        cmap = cptcmap(FuncLabPreferences{19},'flip',true);
    end
    colormap(cmap);
    scatter(picklonsxy', picklatsxy', 100, pickthicknesses', 'filled')
    c=colorbar;
    xlabel(c,'Crustal Thickness, km')
    
%% ------------------------------------------------------------------------
% plot_station_stack_moho_callback
% Pops up a quick plot of moho depths
% -------------------------------------------------------------------------
function plot_station_stack_moho_callback(cbo, eventdata, handles)
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
    load FL_coasts
    load FL_plates
    load FL_stateBoundaries

    % First we need to evaluate if a structure to hold all this information
    % exists in the base set. If not, we'll create it and provide entries for
    % all the stations
    try
        ManualPickMohoStationStackCell=evalin('base','ManualPickMohoStationStackCell');
    catch
        ManualPickMohoStationStackCell=[];
    end
    if isempty(ManualPickMohoStationStackCell)
        disp('Error, picks not found!');
        return
    end
    a = size(ManualPickMohoStationStackCell);
    if a(2) == 5
        ManualPickMohoStationStackCellTmp = ManualPickMohoStationStackCell;
        ManualPickMohoStationStackCell = cell(a(1),6);
        for idx=1:a(1)
            ManualPickMohoStationStackCell{idx, 1} = ManualPickMohoStationStackCellTmp{idx,1};
            ManualPickMohoStationStackCell{idx, 2} = ManualPickMohoStationStackCellTmp{idx,2};
            ManualPickMohoStationStackCell{idx, 3} = ManualPickMohoStationStackCellTmp{idx,3};
            ManualPickMohoStationStackCell{idx, 4} = ManualPickMohoStationStackCellTmp{idx,4};
            ManualPickMohoStationStackCell{idx, 5} = ManualPickMohoStationStackCellTmp{idx,5};
            ManualPickMohoStationStackCell{idx, 6} = 1;
        end
        clear ManualPickMohoStationStackCellTmp
    end
    
    %--------------------------------------------------------------------------
    % Setup dimensions of the map
    %--------------------------------------------------------------------------
    MainPos = [0 0 130 37];
    
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
    
    % Create a map view axis
    MapFigure = figure('Name','Station stack moho','Color','White','Units','Normalized','Position',[0.1 0.1 0.5 0.5800],'CreateFcn',{@movegui_kce,'center'});
    MapViewPanel = uipanel('Title','Map view','FontSize',12,'BackgroundColor','White','Units','Normalized','Position',[0.01 0.1 0.95 0.85]);
    MapViewAxesHandles = axes('Parent',MapViewPanel,'Units','Normalized','Position',[.02 .05 .96 .9]);
    
    MyColormap = FuncLabPreferences{19};
    MyColormapFlipped = FuncLabPreferences{20};
    MinimumLatitude = sscanf(FuncLabPreferences{14},'%f');
	MaximumLatitude = sscanf(FuncLabPreferences{13},'%f');
	MinimumLongitude = sscanf(FuncLabPreferences{15},'%f');
	MaximumLongitude = sscanf(FuncLabPreferences{16},'%f');

    minlon = floor(MinimumLongitude);
    maxlon = ceil(MaximumLongitude);
    minlat = floor(MinimumLatitude);
    maxlat = ceil(MaximumLatitude);
    m_proj(MapProjection,'latitude',[minlat maxlat], 'longitude', [minlon maxlon]);
    %m_proj('Hammer-Aitoff','latitude',[-90 90],'longitude',[-180 180]);

    % Makes the initial plot view - global coast lines and a shaded box for the
    % CCP image volume
    %plot(ncst(:,1),ncst(:,2),'k')
    hold on
    %m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
    m_coast('patch',[.9 .9 .9],'edgecolor','black');
    m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
    m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
    %axis([-180 180 -90 90])
    m_grid('xtick',4,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');

    OnColor = [.3 .3 .3];
    OffColor = [1 .5 .5];
    CurrentColor = [ 1 .7 0];
    SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
    SetOffColor = abs(cross(SetOnColor,OnColor));
    % Add the stations
    %StationLocations = unique([RecordMetadataDoubles(:,10), RecordMetadataDoubles(:,11)],'rows');
    %m_line(StationLocations(:,2),StationLocations(:,1),'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
    
    % Background is set
    % Now get the locations of stations with picks
    % First need to find the number of picks
    pickflags = zeros(1,length(ManualPickMohoStationStackCell));
    for idx=1:length(ManualPickMohoStationStackCell)
        if ~isempty(ManualPickMohoStationStackCell{idx,2})
            pickflags(idx) = 1;
        end
    end
    npicks = sum(pickflags);
    % Now get smaller arrays with just the picks
    picklons = zeros(1,npicks);
    picklats = zeros(1,npicks);
    pickthicknesses = zeros(1,npicks);
    jdx = 1;
    for idx=1:length(ManualPickMohoStationStackCell)
        if pickflags(idx) == 1 && ManualPickMohoStationStackCell{idx,6} == 1
            picklons(jdx) = ManualPickMohoStationStackCell{idx,2};
            picklats(jdx) = ManualPickMohoStationStackCell{idx,3};
            pickthicknesses(jdx) = ManualPickMohoStationStackCell{idx,4};
            jdx = jdx+1;
        end
    end
    % convert to map projection
    picklonsxy = zeros(1,npicks);
    picklatsxy = zeros(1,npicks);
    for idx=1:npicks
        [picklonsxy(idx), picklatsxy(idx)] = m_ll2xy(picklons(idx), picklats(idx));
    end
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    if FuncLabPreferences{20} == 0
        cmap = cptcmap(FuncLabPreferences{19});
    else
        cmap = cptcmap(FuncLabPreferences{19},'flip',true);
    end
    colormap(cmap);
    scatter(picklonsxy', picklatsxy', 100, pickthicknesses', 'filled')
    c = colorbar;
    xlabel(c,'Crustal Thickness, km')

%% ------------------------------------------------------------------------
% manual_pick_load_ccp_volume
% Load ccp volume and set geometry
% In the visualizer add-on, I popup a geometry menu and then use those
% parameters to re-interpolate the ccp volume. We'll do that here as well.
% First step is to popup a file selector. User selects a file, and then we
% figure out if it is from the original ccp tools (ccp, gccp) or the new
% ccpv2 based on the stored variables. Then we use those geometry variables
% to initialize prompts in a set geometry window. Once the geometry
% parameters are set, the volume is re-interpolated and stored in the base
% set for gathering into picking tools. Once this is completed, we'll find
% the tags for the 1D profile and cross section tools and set them to
% enabled.
% -------------------------------------------------------------------------
function manual_pick_load_ccp_volume(cbo, eventdata, handles)            
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    % Have the user input a file and check for existance
    [filename, pathname, filterindex] = uigetfile('*.mat','Load the CCP volume mat file',ProjectDirectory);
    if filename == 0
        return
    end
    if exist([pathname filename],'file')
        % Use the variables within the mat file to check if its gccp/ccp or
        % ccpv2
        varlist = whos('-file',[pathname filename]);
        % loop through each variable and check for ccp version and if it is
        % even a ccp voluem
        isccpv1flag = 0;
        isccpv2flag = 0;
        for idx=1:length(varlist)
            if strcmp('Longitudes',varlist(idx).name)
                isccpv1flag = 1;
                break
            end
        end
        for idx=1:length(varlist)
            if strcmp('xvector',varlist(idx).name)
                isccpv2flag = 1;
                break
            end
        end

        % If either both flags are true or neither flag is true, we've got a
        % problem
        if isccpv1flag == 0 && isccpv2flag == 0
            disp('Input file is not a ccp volume from FuncLab! (both flags 0)')
            return
        end
        if isccpv1flag == 1 && isccpv2flag == 1
            disp('Input file is not a ccp volume from FuncLab! (both flags 1)')
            return
        end  
    else
        disp('File not found. Weird.com')
        return
    end

    % Go ahead and load the matfile now
    load([pathname filename]);

    % Switch to decide between reading original ccp versions or ccpv2
    % At this stage, our goal is to get min/max/increment for
    % latitude/longitude/depth. Also, we can ignore the transverse component as
    % we are focusing on Moho, which is most strongly observed on the radial
    % component.
    if isccpv1flag == 1
        % In this case, we have 7 variables:
        % Longitudes, Latitudes, Depths, RRFAmpMean, RRFAmpSigma, TRFAmpMean,
        % TRFAmpSigma
        % All are N x 1 double vectors

        % Min and maxes are easy:
        MinLongitude = min(Longitudes);
        MaxLongitude = max(Longitudes);
        MinLatitude = min(Latitudes);
        MaxLatitude = max(Latitudes);
        MinDepth = min(Depths);
        MaxDepth = max(Depths);

        % Increments are harder, but we don't need to use the data increment
        % because we are just preparing a value to suggest to the user. So how
        % about if we just use a static number of nodes and then use that to
        % suggest an increment?
        nx = 40;
        ny = 40;
        nz = 40;
        IncLongitude = (MaxLongitude - MinLongitude) / nx;
        IncLatitude = (MaxLatitude - MinLatitude) / ny;
        IncDepth = (MaxDepth - MinDepth) / nz;

    elseif isccpv2flag == 1
        % In this case, we have 9 variables:
        % xvector, yvector, zvector, CCPStackR, CCPStackT, CCPHits,
        % CCPStackKernelR, CCPStackKernelT, CCPHitsKernel
        % In this case, xvector, yvector, and zvector contain the geographic
        % information and all are equally sampled.
        MinLongitude = min(xvector);
        MaxLongitude = max(xvector);
        MinLatitude = min(yvector);
        MaxLatitude = max(yvector);
        MinDepth = min(zvector);
        MaxDepth = max(zvector);

        % Increments are a little easier
        IncLongitude = xvector(2) - xvector(1);
        IncLatitude = yvector(2) - yvector(1);
        IncDepth = zvector(2) - zvector(1);
    else
        disp('WTF mate?')
        return
    end

    % Make strings out of the geographic limits
    MinimumLatitude_s = sprintf('%3.1f',MinLatitude);
    MaximumLatitude_s = sprintf('%3.1f',MaxLatitude);
    IncrementLatitude_s = sprintf('%3.1f',IncLatitude);
    MinimumLongitude_s = sprintf('%3.1f',MinLongitude);
    MaximumLongitude_s = sprintf('%3.1f',MaxLongitude);
    IncrementLongitude_s = sprintf('%3.1f',IncLongitude);
    MinimumDepth_s = sprintf('%3.1f',MinDepth);
    MaximumDepth_s = sprintf('%3.1f',MaxDepth);
    IncrementDepth_s = sprintf('%3.1f',IncDepth);

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
    % Ok, we have the geographic boundaries set. 
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
    uicontrol ('Parent',GeometryFigure,'Style','Popupmenu','String',{'Radial RF'},'Tag','radial_or_transverse_pu','Value',1,'Units','characters',...
        'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');

    % Add buttons for "Save Geometry" and "Cancel"
    % But switch between ccpv1 or ccpv2
    if isccpv1flag == 1
        uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','savegeometry_pb','String','Save Geometry',...
            'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
            'Callback',{@get_geometry_params, GeometryFigure, Longitudes, Latitudes, Depths, RRFAmpMean, TRFAmpMean});

    else
        uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','savegeometry_pb','String','Save Geometry',...
            'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
            'Callback',{@get_geometry_params_ccpv2, GeometryFigure, xvector, yvector, zvector, CCPHits, CCPStackR, CCPStackT, CCPHitsKernel, CCPStackKernelR, CCPStackKernelT});
    end

    ProcButtonPos(1) = 60;
    uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','cancel_pb','String','Cancel',...
        'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
        'Callback',{@cancel_new_view,GeometryFigure});

% Do 1D pick of ccp volume
function manual_moho_pick_ccp_oned(cbo, eventdata, handles)
    % Get project data
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    global PickingStructure;
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');

    try
        ManualPickMohoCCPoneDArray=evalin('base','ManualPickMohoCCPoneDArray');
    catch
        ManualPickMohoCCPoneDArray=[];
    end
    npicks = 10000;
    if isempty(ManualPickMohoCCPoneDArray)
        ManualPickMohoCCPoneDArray = zeros(npicks, 4);
        assignin('base','ManualPickMohoCCPoneDArray',ManualPickMohoCCPoneDArray);
    else
        a = size(ManualPickMohoCCPoneDArray);
        if a(2) == 3
            ManualPickMohoCCPoneDArray = zeros(npicks,4);
            ManualPickMohoCCPoneDArrayTmp = evalin('base','ManualPickMohoCCPoneDArray');
            for idx=1:npicks
                ManualPickMohoCCPoneDArray(idx, 1) = ManualPickMohoCCPoneDArrayTmp(idx,1);
                ManualPickMohoCCPoneDArray(idx, 2) = ManualPickMohoCCPoneDArrayTmp(idx,2);
                ManualPickMohoCCPoneDArray(idx, 3) = ManualPickMohoCCPoneDArrayTmp(idx,3);
                ManualPickMohoCCPoneDArray(idx, 4) = 1;
            end
            clear ManualPickMohoCCPoneDArrayTmp
        else
            ManualPickMohoCCPoneDArray = evalin('base','ManualPickMohoCCPoneDArray');
        end
    end

    
    % Get CCP from base workspace
    Amplitude = evalin('base','Amplitude');
    Lats = evalin('base','Lats');
    Lons = evalin('base','Lons');
    Depths = evalin('base','Depths');
    
    % Has the uesr pick a point
    screensize = get(0,'screensize');
    figpos = [screensize(3) / 2 - 200 screensize(4) / 2 - 50 400 100];
    tmpfig = figure('Name','Click a point for a 1D plot','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
    uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.5 0.6 0.4],'String','Please click a single point on the map view.','FontSize',12);
    waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.4],'String','Click','FontSize',12,'Callback','gcbf.UserData=1; close');
    waitfor(waitbutton,'Userdata');
    [lon, lat] = ginput(1);
    
    % Plots the picked point
    hold on
    scatter(lon, lat, 100, [1, 204/255,0],'filled');

    % Convert from xy to map coordinates
    [x,y] = m_xy2ll(lon, lat);
    lon = x;
    lat = y;
    
    % Look up the predicted crustal thickness
    if PickingStructure.Background == true
        EstimatedThickness = PickingStructure.BackgroundFunction(lon, lat);
    else
        EstimatedThickness = PickingStructure.InitialThickness;
    end
    
    TmpAmplitude = double(permute(Amplitude,[1,2,3]));
    TmpLon = double(permute(Lons,[1,2,3]));
    TmpLat = double(permute(Lats,[1,2,3]));
    TmpDep = double(permute(Depths,[1,2,3]));
              
    dep = double(linspace(min(min(min(Depths))), max(max(max(Depths))), size(Depths,3)));
    
    amp = interp3(TmpLon, TmpLat, TmpDep, TmpAmplitude, lon, lat, dep);
    tmp = zeros(length(dep),1);
    for idx=1:length(dep)
        tmp(idx) = amp(1,1,idx);
    end
    PositiveIndices = find (tmp > 0);
    NegativeIndices = find (tmp < 0);
    TempAmps = reshape(tmp,[],1);
    Pamps = zeros (size(TempAmps));
    Pamps(PositiveIndices) = TempAmps(PositiveIndices);
    Namps = zeros (size(TempAmps));
    Namps(NegativeIndices) = TempAmps(NegativeIndices);
    PFilledTrace = reshape(Pamps,size(tmp));
    NFilledTrace = reshape(Namps,size(tmp));
    PFilledTrace = [zeros(1,length(PFilledTrace)), PFilledTrace', zeros(1,length(PFilledTrace))];
    NFilledTrace = [zeros(1,length(NFilledTrace)), NFilledTrace', zeros(1,length(NFilledTrace))];
    DepthAxis = dep';
    DepthAxis = [ones(1,length(DepthAxis)) * DepthAxis(1), ...
        DepthAxis', ...
        ones(1,length(DepthAxis)) * DepthAxis(end)];
    
    % Actual figure
    ProfileFigureHandles = figure('Units','characters','NumberTitle','off','Name','CCP Depth Profile','Units','characters',...
        'Position',[0 0 70 70],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});
    ax = axes('Parent',ProfileFigureHandles);
    xlim(ax,[-1 1])
    ylim(ax,[min(dep) max(dep)])
    set(ax,'YDir','Reverse')
    grid(ax,'on')
    grid(ax,'minor')
    box(ax,'on')
    ylabel(ax,'Depth (km)')
    xlabel(ax,'RF Amplitude')
    title('Radial RF')

    % Plot amplitudes along profile
    % % plotting
    hold on
    vp = [PFilledTrace; DepthAxis];
    vn = [NFilledTrace; DepthAxis];
    idx = length(vp);
    vvp = vp;
    vvn = vn;
    vvp(1,idx+1) = 0;
    vvp(2,idx+1) = max(DepthAxis);
    vvp(1,idx+2) = 0;
    vvp(2,idx+2) = min(DepthAxis);
    vvn(1,idx+1) = 0;
    vvn(2,idx+1) = max(DepthAxis);
    vvn(1,idx+2) = 0;
    vvn(2,idx+2) = min(DepthAxis);
    ff=length(vvp):-1:1;
    patch(ax,'Faces',ff,'Vertices',vvp','FaceColor',[1 0 0],'EdgeColor','none','Tag','phandle');
    patch(ax,'Faces',ff,'Vertices',vvn','FaceColor',[0 0 1],'EdgeColor','none','Tag','nhandle');
    line(ax,tmp,dep,'Color',[0 0 0],'LineWidth',1)
    line(ax,[-1 1], [EstimatedThickness EstimatedThickness],'Color',[191/255 87/255 0],'LineWidth',2,'LineStyle','-.')
    
    
    % Ok, now ginput to select the moho
    [~, CrustalThickness] = ginput(1);
    TmpAmp = interp1(dep, tmp, CrustalThickness);
    scatter(ax, TmpAmp, CrustalThickness,200,'filled');
    
    % Fill output array
    % first find, the first empty point
    for idx=1:length(ManualPickMohoCCPoneDArray)
        if ManualPickMohoCCPoneDArray(idx,1) == 0
            ManualPickMohoCCPoneDArray(idx,1) = lon;
            ManualPickMohoCCPoneDArray(idx,2) = lat;
            ManualPickMohoCCPoneDArray(idx,3) = CrustalThickness;
            ManualPickMohoCCPoneDArray(idx,4) = 1;
            break
        end
    end

    % Save
    assignin('base','ManualPickMohoCCPoneDArray',ManualPickMohoCCPoneDArray);
    save([ProjectDirectory ProjectFile], 'ManualPickMohoCCPoneDArray','-append');

    hdls = findobj('Tag','plot_moho_one_d_ccp_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','plot_moho_all_sources_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','export_moho_one_d_ccp_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','export_moho_all_sources_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','moho_manual_pick_aggregator');
    set(hdls,'Enable','on');
 
% Make cross section through ccp volume
function manual_moho_pick_ccp_cross_section(cbo, eventdata, handles)
    % Get project data
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    
    % May comment this out and move to plot callback
    try
        ManualPickMohoCCPCrossSectionArray=evalin('base','ManualPickMohoCCPCrossSectionArray');
    catch
        ManualPickMohoCCPCrossSectionArray=[];
    end
    npicks = 10000;    
    if isempty(ManualPickMohoCCPCrossSectionArray)
        ManualPickMohoCCPCrossSectionArray = zeros(npicks, 4);
        assignin('base','ManualPickMohoCCPCrossSectionArray',ManualPickMohoCCPCrossSectionArray);
    else
        a = size(ManualPickMohoCCPCrossSectionArray);
        if a(2) == 3
            ManualPickMohoCCPCrossSectionArray = zeros(npicks,4);
            ManualPickMohoCCPCrossSectionArrayTmp = evalin('base','ManualPickMohoCCPCrossSectionArray');
            for idx=1:npicks
                ManualPickMohoCCPCrossSectionArray(idx, 1) = ManualPickMohoCCPCrossSectionArrayTmp(idx,1);
                ManualPickMohoCCPCrossSectionArray(idx, 2) = ManualPickMohoCCPCrossSectionArrayTmp(idx,2);
                ManualPickMohoCCPCrossSectionArray(idx, 3) = ManualPickMohoCCPCrossSectionArrayTmp(idx,3);
                ManualPickMohoCCPCrossSectionArray(idx, 4) = 1;
            end
            clear ManualPickMohoCCPCrossSectionArrayTmp
        else
            ManualPickMohoCCPCrossSectionArray = evalin('base','ManualPickMohoCCPCrossSectionArray');
        end
    end
    

    % Start with message to user asking them to click on two points
    screensize = get(0,'screensize');
    figpos = [screensize(3) / 2 - 200 screensize(4) / 2 - 50 400 100];
    tmpfig = figure('Name','Click 2 points for cross section','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
    uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.5 0.6 0.4],'String','Please click 2 points on the map view.','FontSize',12);
    waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.4],'String','Click','FontSize',12,'Callback','gcbf.UserData=1; close');
    waitfor(waitbutton,'Userdata');
    [lon, lat] = ginput(2);

    % Create the line for the map view
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
    uicontrol ('Parent',GeometryFigure,'Style','popupmenu','Units','characters','Tag','projection_method_popup','String',{'Linear'},...
        'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on');
    ParamOptionPos2(1) = 84;

    
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
    Depths = evalin('base','Depths');
    min_depth_s = sprintf('%3.1f',min(min(min(Depths))));
    max_depth_s = sprintf('%3.1f',max(max(max(Depths))));
    inc_depth_s = sprintf('%3.1f',Depths(1,1,2) - Depths(1,1,1));

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
    
function plot_cross_section_view(src, evt,callinghdls, lon, lat)
    global PickingStructure;
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
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
 
    % close the calling handles
    close(callinghdls);
    
    % Prepare the data set
    Amplitude = evalin('base','Amplitude');
    Lats = evalin('base','Lats');
    Lons = evalin('base','Lons');
    Depths = evalin('base','Depths');
    SmoothMatrix = smooth_nxmxk_matrix(Amplitude,nsmoothx, nsmoothy, nsmoothz);
    
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
    CrossSectionMoho = zeros(nptsAlongSection,1);
    
    % Alternatively, assume latitude and longitude are cartesian to fit what the map view looks like
    tmpLats2 = linspace(startLat, endLat, nptsAlongSection);
    tmpLons2 = linspace(startLong, endLong, nptsAlongSection);
    
    % Rearrange to make it look like a proper mesh grid
    TmpAmplitude = permute(SmoothMatrix,[1,2,3]);
    TmpLon = permute(Lons,[1,2,3]);
    TmpLat = permute(Lats,[1,2,3]);
    TmpDep = permute(Depths,[1,2,3]);
    
    
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
        
        if PickingStructure.Background == true
            CrossSectionMoho(imeasurement) = PickingStructure.BackgroundFunction(tmpLong, tmpLat);
        else
            CrossSectionMoho(imeasurement) = PickingStructure.InitialThickness;
        end

        % here is where we get the data from the model as a function of
        % depth
        CrossSectionData(imeasurement,:) = interp3(TmpLon, TmpLat, TmpDep, TmpAmplitude,tmpLong, tmpLat, zvector,'linear');
        [CrossSectionDistance(imeasurement),~,~] = distaz(startLat, startLong, tmpLat, tmpLong);
        %CrossSectionDistance(imeasurement) = gcdist(startLat, startLong, tmpLat, tmpLong);
        
    end
    
    % Close the wait gui as we are ready to plot
    close(TmpWaitGui)
 
    % make the plot
    % Get the x and y arrays for the plot
    xx = repmat(CrossSectionDistance,1,size(zvector,2));
    yy = repmat(zvector,size(CrossSectionDistance,1),1);
    % Gets a new figure
    xsectionFigureHandles = figure('Name','Cross Section','Units','Normalized','Position',[0.1 0.5 0.8 0.4],'Color','white');
    axesHandles = axes('Position',[0.05 0.1 0.9 0.8]);
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
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    if FuncLabPreferences{20} == 0
        cmap = cptcmap(FuncLabPreferences{19});
    else
        cmap = cptcmap(FuncLabPreferences{19},'flip',true);
    end
    colormap(cmap);
    caxis([-max(max(abs(abs(CrossSectionData))))*0.8 0.8*max(max(abs(abs(CrossSectionData))))])
    line(CrossSectionDistance, CrossSectionMoho,'Color',[191/255, 87/255,0],'LineWidth',2,'LineStyle','-.');
    xlabel('Distance along profile (km)')
    ylabel('Depth (km)')
    colorbar
    
    % Use ginput on two points to get profile location
    % Start with message to user asking them to click on two points
    screensize = get(0,'screensize');
    figpos = [screensize(3) / 2 - 200 screensize(4) / 2 - 50 400 150];
    tmpfig = figure('Name','Info','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
    uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.6 0.6 0.4],'String','Click on moho conversions along the profile. Hit enter when finished.','FontSize',12);
    waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.4],'String','Click','FontSize',12,'Callback','gcbf.UserData=1; close');
    waitfor(waitbutton,'Userdata');
    [xlocations, crustalthickness] = ginput();
    
    % Here we use interpolation to associate distance along profile with the
    % corresponding longitude, latitude, point
    PickLongitudes = zeros(1,length(xlocations));
    PickLatitudes = zeros(1,length(xlocations));
    for ipick=1:length(xlocations)
        PickLongitudes(ipick) = interp1(CrossSectionDistance, CrossSectionLongitudes,xlocations(ipick));
        PickLatitudes(ipick) = interp1(CrossSectionDistance, CrossSectionLatitudes,xlocations(ipick));
    end

    % Fill output array
    % first find, the first empty point
    ManualPickMohoCCPCrossSectionArray = evalin('base','ManualPickMohoCCPCrossSectionArray');
    for idx=1:length(ManualPickMohoCCPCrossSectionArray)
        if ManualPickMohoCCPCrossSectionArray(idx,1) == 0
            break
        end
    end
    for jdx=1:length(xlocations)
        ManualPickMohoCCPCrossSectionArray(jdx+idx-1,1) = PickLongitudes(jdx);
        ManualPickMohoCCPCrossSectionArray(jdx+idx-1,2) = PickLatitudes(jdx);
        ManualPickMohoCCPCrossSectionArray(jdx+idx-1,3) = crustalthickness(jdx);
        ManualPickMohoCCPCrossSectionArray(jdx+idx-1,4) = 1;
    end

    % Save
    assignin('base','ManualPickMohoCCPCrossSectionArray',ManualPickMohoCCPCrossSectionArray);
    save([ProjectDirectory ProjectFile], 'ManualPickMohoCCPCrossSectionArray','-append');

    % Update plot with picks
    scatter(xlocations, crustalthickness,100,'filled')
    
    hdls = findobj('Tag','plot_moho_ccp_cross_sections_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','plot_moho_all_sources_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','export_moho_ccp_cross_sections_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','export_moho_all_sources_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','moho_manual_pick_aggregator');
    set(hdls,'Enable','on');
    
function get_geometry_params_ccpv2(src,evt, fighdls, xorig, yorig, zorig, CCPHits, CCPStackR, CCPStackT, CCPHitsKernel, CCPStackKernelR, CCPStackKernelT)    
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
                if CCPHitsKernel(ix,iy,iz) >= 1
                    CCPStackKernelR(ix,iy,iz) = CCPStackKernelR(ix,iy,iz) / CCPHitsKernel(ix,iy,iz);
                else
                    CCPStackKernelR(ix,iy,iz) = 0.0;
                end
            end
        end
    end

    % peak-to-peak normalization for each column in depth. 
    CCPStackTempR = CCPStackKernelR;
    for ix=1:length(xorig)
        for iy=1:length(yorig)
            % Get peak at this point
            peakAmpR = -9001;
            for iz=1:length(zorig)
                if abs(CCPStackTempR(ix,iy,iz)) > peakAmpR
                    peakAmpR = abs(CCPStackTempR(ix,iy,iz));
                end
            end
            % Now do normalization
            if peakAmpR > 0.001
                for iz=1:length(zorig)
                    CCPStackKernelR(ix,iy,iz) = CCPStackTempR(ix,iy,iz) / peakAmpR;
                end
            else
                CCPStackKernelR(ix,iy,iz) = 0.0;
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
    RFType = 'Radial';
    
    % Get ray theory or gaussian
    RGChoice = 'Gaussian';
    
    [LonsTmp, LatsTmp, DepthsTmp] = meshgrid(xorig, yorig, zorig);

    % Make vectors for the geometry
    xvector = MinimumLongitude:IncrementLongitude:MaximumLongitude;
    yvector = MinimumLatitude:IncrementLatitude:MaximumLatitude;
    zvector = MinimumDepth:IncrementDepth:MaximumDepth;
    
    % And mesh them
    [Lons, Lats, Depths] = meshgrid(xvector, yvector, zvector);

    CCPTmp = permute(CCPStackKernelR,[2,1,3]);
    CCPStack = interp3(LonsTmp, LatsTmp, DepthsTmp, CCPTmp, Lons, Lats, Depths);
    
    % Put into the global structure
    assignin('base','Amplitude',CCPStack);
    assignin('base','Depths',Depths);
    assignin('base','Lats',Lats);
    assignin('base','Lons',Lons);
    assignin('base','AmplitudeType','RadialRF');
    
    % Close the dialog so we can replot the geometry
    close(fighdls)
    close(TmpWaitGui)

    % Enable the CCP picking tools
    hdls = findobj('Tag','moho_manual_pick_ccp_oned_button');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','moho_manual_pick_ccp_cross_section_button');
    set(hdls,'Enable','on');
    
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
    RFType = 'Radial';
    
    % Make vectors for the geometry
    xvector = MinimumLongitude:IncrementLongitude:MaximumLongitude;
    yvector = MinimumLatitude:IncrementLatitude:MaximumLatitude;
    zvector = MinimumDepth:IncrementDepth:MaximumDepth;
    
    % And mesh them
    [Lons, Lats, Depths] = meshgrid(xvector, yvector, zvector);

    % Make a function for the CCP
    idx = find(isnan(rrf));
    lon(idx) = [];
    lat(idx) = [];
    dep(idx) = [];
    rrf(idx) = [];
    CCPFunction = scatteredInterpolant(lon, lat, dep, rrf);
    
    % Evaluate on desired geometry
    CCPStack = CCPFunction(Lons, Lats, Depths);
    
    % Put into the global structure
    assignin('base','Amplitude',CCPStack);
    assignin('base','Depths',Depths);
    assignin('base','Lats',Lats);
    assignin('base','Lons',Lons);
    assignin('base','AmplitudeType','RadialRF');
    
    % Close the dialog so we can replot the geometry
    close(fighdls)
    close(TmpWaitGui)
    
    % Enable CCP picking tools
    hdls = findobj('Tag','moho_manual_pick_ccp_oned_button');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','moho_manual_pick_ccp_cross_section_button');
    set(hdls,'Enable','on');
     
%% ------------------------------------------------------------------------
% manual_pick_ray_cross_section_callback
% Follows from fl_view_rf_cross_section_depth, but adds picking and storing
% of moho picks
% -------------------------------------------------------------------------
function manual_pick_ray_cross_section_callback(cbo, eventdata, handles)
    % Get project data
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    global PickingStructure;
    
    
    % Initiate the output
    try
        ManualPickMohoRayCrossSectionArray=evalin('base','ManualPickMohoRayCrossSectionArray');
    catch
        ManualPickMohoRayCrossSectionArray=[];
    end
    % This version limits the number of pick points to the number of
    % stations.
    % Unless we make the amplitude and depth cell elements into vectors, but
    % that might get over complicated
    % Here we just use a big static array allocation
    npicks = 10000;
    if isempty(ManualPickMohoRayCrossSectionArray)
        ManualPickMohoRayCrossSectionArray = zeros(npicks, 4);
        assignin('base','ManualPickMohoRayCrossSectionArray',ManualPickMohoRayCrossSectionArray);
    else
        a = size(ManualPickMohoRayCrossSectionArray);
        if a(2) == 3
            ManualPickMohoRayCrossSectionArray = zeros(npicks,4);
            ManualPickMohoRayCrossSectionArrayTmp = evalin('base','ManualPickMohoRayCrossSectionArray');
            for idx=1:npicks
                ManualPickMohoRayCrossSectionArray(idx, 1) = ManualPickMohoRayCrossSectionArrayTmp(idx,1);
                ManualPickMohoRayCrossSectionArray(idx, 2) = ManualPickMohoRayCrossSectionArrayTmp(idx,2);
                ManualPickMohoRayCrossSectionArray(idx, 3) = ManualPickMohoRayCrossSectionArrayTmp(idx,3);
                ManualPickMohoRayCrossSectionArray(idx, 4) = 1;
            end
            clear ManualPickMohoRayCrossSectionArrayTmp
        else
            ManualPickMohoRayCrossSectionArray = evalin('base','ManualPickMohoRayCrossSectionArray');
        end
    end

    % Check for backwards compability
    if length(FuncLabPreferences) < 21
        FuncLabPreferences{19} = 'vel.cpt';
        FuncLabPreferences{20} = false;
        FuncLabPreferences{21} = '1.8.1';
    end

    % Load colormap
    if FuncLabPreferences{20} == false
        cmap = cptcmap(FuncLabPreferences{19});
    else
        cmap = cptcmap(FuncLabPreferences{19},'flip',true);
    end
    colormap(cmap);

    % Load the RayInfo file - may take a long time, but hopefully faster than
    % recomputing PRF to depth
    load([ProjectDirectory ProjectFile], 'ThreeDRayInfoFile');
    if ~exist(ThreeDRayInfoFile{1},'file')
        fprintf('Error, file %s not found!\n',ThreeDRayInfoFile{1});
        return
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
    
    % We can use the main segment longitude and latitude to define the moho
    if PickingStructure.Background == true
        CrossSectionMoho = PickingStructure.BackgroundFunction(mainSegmentLongitude, mainSegmentLatitude);
        CrossSectionDistanceMoho = zeros(1,100);
        for idx=1:100
            [CrossSectionDistanceMoho(idx),~,~] = distaz(latstart, lonstart, mainSegmentLatitude(idx), mainSegmentLongitude(idx));
        end
    else
        CrossSectionMoho = zeros(1,100);
        for idx=1:100
            CrossSectionMoho(idx) = PickingStructure.InitialThickness;
            [CrossSectionDistanceMoho(idx),~,~] = distaz(latstart, lonstart, mainSegmentLatitude(idx), mainSegmentLongitude(idx));
        end
    end

    
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
    Components = {'Radial RF'};
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
    ActiveAmplitudesR = ActiveAmplitudesR / max(abs(ActiveAmplitudesR));

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
    DepthMin = evalin('base','DepthMin');
    DepthMax = evalin('base','DepthMax');
    if DepthMax < 0
        DepthMax = max(ActiveDepths);
    end
    ColorMin = evalin('base','ColorMin');
    ColorMax = evalin('base','ColorMax');
    %scatter(ax,PointDistances, ActiveDepths,dotsize,ActiveAmplitudesR,'filled')
    pcolor(ax,xmesh, ymesh, CCPMatrix');
    shading interp
    title(ax,'Radial RF Cross Section')
    xlim(ax,[0 FullProfileDistance])
    ylim(ax,[DepthMin DepthMax])
    line(CrossSectionDistanceMoho, CrossSectionMoho,'Color',[191/255, 87/255, 0], 'LineWidth',2,'LineStyle','-.');
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


    % Use ginput on two points to get profile location
    % Start with message to user asking them to click on two points
    screensize = get(0,'screensize');
    figpos = [screensize(3) / 2 - 200 screensize(4) / 2 - 50 400 150];
    tmpfig = figure('Name','Info','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
    uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.6 0.6 0.4],'String','Click on moho conversions along the profile. Hit enter when finished. Thicknesses will be projected along profile.','FontSize',12);
    waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.4],'String','Click','FontSize',12,'Callback','gcbf.UserData=1; close');
    waitfor(waitbutton,'Userdata');
    [xlocations, crustalthickness] = ginput();

    % Here we use interpolation to associate distance along profile with the
    % corresponding longitude, latitude, point
    mainSegmentDistances = zeros(1,100);
    for idx=1:100
        mainSegmentDistances(idx) = distaz(latstart, lonstart, mainSegmentLatitude(idx), mainSegmentLongitude(idx));
    end
    PickLongitudes = zeros(1,length(xlocations));
    PickLatitudes = zeros(1,length(xlocations));
    for ipick=1:length(xlocations)
        PickLongitudes(ipick) = interp1(mainSegmentDistances, mainSegmentLongitude,xlocations(ipick));
        PickLatitudes(ipick) = interp1(mainSegmentDistances, mainSegmentLatitude,xlocations(ipick));
    end

    % Fill output array
    % first find, the first empty point
    for idx=1:length(ManualPickMohoRayCrossSectionArray)
        if ManualPickMohoRayCrossSectionArray(idx,1) == 0
            break
        end
    end
    for jdx=1:length(xlocations)
        ManualPickMohoRayCrossSectionArray(jdx+idx-1,1) = PickLongitudes(jdx);
        ManualPickMohoRayCrossSectionArray(jdx+idx-1,2) = PickLatitudes(jdx);
        ManualPickMohoRayCrossSectionArray(jdx+idx-1,3) = crustalthickness(jdx);
        ManualPickMohoRayCrossSectionArray(jdx+idx-1,4) = 1;
        
    end

    % Save
    assignin('base','ManualPickMohoRayCrossSectionArray',ManualPickMohoRayCrossSectionArray);
    save([ProjectDirectory ProjectFile], 'ManualPickMohoRayCrossSectionArray','-append');

    % Update plot with picks
    scatter(xlocations, crustalthickness,100,'filled')

    hdls = findobj('Tag','plot_moho_ray_diagram_cross_sections_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','plot_moho_all_sources_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','export_moho_ray_diagram_cross_sections_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','export_moho_all_sources_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','moho_manual_pick_aggregator');
    set(hdls,'Enable','on');
    
%% ------------------------------------------------------------------------
% manual_pick_rf_cross_section_callback
% This version is largely copied from
% fl_view_rf_cross_section_depth_stack.m
% But once the profile figure is plotted, a dialog box pops up and then we
% go into ginput mode. User clicks all the moho conversions they want, and
% then hits enter. The moho picks are then mapped to under the nearest
% station and the data is saved to the project
% -------------------------------------------------------------------------
function manual_pick_rf_cross_section_callback(cbo, eventdata, handles)
    global PickingStructure;
    % Get project data
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');

    % Initiate the output
    try
        ManualPickMohoRFCrossSectionArray=evalin('base','ManualPickMohoRFCrossSectionArray');
    catch
        ManualPickMohoRFCrossSectionArray=[];
    end
    % This version limits the number of pick points to the number of
    % stations.
    % Unless we make the amplitude and depth cell elements into vectors, but
    % that might get over complicated
    % Here we just use a big static array allocation
    npicks = 10000;
    if isempty(ManualPickMohoRFCrossSectionArray)
        ManualPickMohoRFCrossSectionArray = zeros(npicks, 4);
        assignin('base','ManualPickMohoRFCrossSectionArray',ManualPickMohoRFCrossSectionArray);
    else
        a = size(ManualPickMohoRFCrossSectionArray);
        if a(2) == 3
            ManualPickMohoRFCrossSectionArray = zeros(npicks,4);
            ManualPickMohoRFCrossSectionArrayTmp = evalin('base','ManualPickMohoRFCrossSectionArray');
            for idx=1:npicks
                ManualPickMohoRFCrossSectionArray(idx, 1) = ManualPickMohoRFCrossSectionArrayTmp(idx,1);
                ManualPickMohoRFCrossSectionArray(idx, 2) = ManualPickMohoRFCrossSectionArrayTmp(idx,2);
                ManualPickMohoRFCrossSectionArray(idx, 3) = ManualPickMohoRFCrossSectionArrayTmp(idx,3);
                ManualPickMohoRFCrossSectionArray(idx, 4) = 1;
            end
            clear ManualPickMohoRFCrossSectionArrayTmp
        else
            ManualPickMohoRFCrossSectionArray = evalin('base','ManualPickMohoRFCrossSectionArray');
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
    
    % We can use the main segment longitude and latitude to define the moho
    if PickingStructure.Background == true
        CrossSectionMoho = PickingStructure.BackgroundFunction(mainSegmentLongitude, mainSegmentLatitude);
        CrossSectionDistanceMoho = zeros(1,100);
        for idx=1:100
            [CrossSectionDistanceMoho(idx),~,~] = distaz(latstart, lonstart, mainSegmentLatitude(idx), mainSegmentLongitude(idx));
        end
    else
        CrossSectionMoho = zeros(1,100);
        for idx=1:100
            CrossSectionMoho(idx) = PickingStructure.InitialThickness;
            [CrossSectionDistanceMoho(idx),~,~] = distaz(latstart, lonstart, mainSegmentLatitude(idx), mainSegmentLongitude(idx));
        end
    end
    
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
    dz = 1;
    assignin('base','DepthMin',0);
    assignin('base','DepthMax',-1); % We'll use -1 as a flag to indicate when the maximum depth is set to default
    assignin('base','DoPlot','True');
    assignin('base','PlotStationNames','Off');
    
    % Need to get info about component and thickness
    figpos = [screensize(3) / 2 - 200 screensize(4) / 2  400 300];
    tmpfig = figure('Name','Set cross section parameters','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
    uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.025 0.8 0.3 0.1],'String','Box width (degrees):','FontSize',12);
    uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.34 0.8 0.2 0.1],'String','1.0','FontSize',12,'Tag','width_control_edit_box','Callback',@setprofilewidth);
    %Components = {'Radial RF', 'Transverse RF', 'Vertical','Radial','Transverse'};
    Components = {'Radial RF'};
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

    % Option to turn station names on/off
    uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.025 0.2 0.3 0.1],'String','Station names:','FontSize',12);
    uicontrol('Style','PopupMenu','Parent',tmpfig,'Units','Normalized','Value',2,'Position',[0.34 0.2 0.2 0.1],'String',{'On','Off'},'FontSize',12,'Tag','station_name_popup_menu','Callback',@setstationnames);
    
    waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.6 0.1 0.35 0.1],'String','Confirm','FontSize',12,'Callback','gcbf.UserData=1; close');
    uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.1 0.1 0.35 0.1],'String','Cancel','FontSize',12,'Callback','gcbf.UserData=0; close;assignin(''base'',''DoPlot'',''False'')');
    
    waitfor(waitbutton,'Userdata');
    DoPlot = evalin('base','DoPlot');
    if strcmp(DoPlot,'False')
        disp('Canceled')
        return
    end
    
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
        EndDepthArray = 100;
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
                fname = sprintf('%seqr',ActiveRecordStrings{thisIndex,1});

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
    title('Radial RF')

    edittedPositiveColor = [1 0 0];
    edittedNegativeColor = [0 0 1];

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
       %plot(ax,(Amplitudes(:,istation) + n),DepthArray,'kd')
    end
    
    % Plots the predicted Moho on the cross section
    line(CrossSectionDistanceMoho, CrossSectionMoho,'Color',[191/255, 87/255, 0], 'LineWidth',2,'LineStyle','-.');
    
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

    % Plot station names
    PlotStationNames = evalin('base','PlotStationNames');
    if strcmp(PlotStationNames,'On')
        for istation=1:nStations
            text(StationDistances(istation), 10, StationNames(istation),'FontSize',20);
        end
    end
    
    
    % Use ginput on two points to get profile location
    % Start with message to user asking them to click on two points
    screensize = get(0,'screensize');
    figpos = [screensize(3) / 2 - 200 screensize(4) / 2 - 50 400 150];
    tmpfig = figure('Name','Info','Units','Pixel','Position',figpos,'DockControls','off','MenuBar','none','NumberTitle','off');
    uicontrol('Style','Text','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.6 0.6 0.4],'String','Click on moho conversions along the profile. Hit enter when finished. Thicknesses will be projected at the station location.','FontSize',12);
    waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.1 0.4 0.4],'String','Click','FontSize',12,'Callback','gcbf.UserData=1; close');
    waitfor(waitbutton,'Userdata');
    figure(ProfileFigureHandles)
    [xlocations, crustalthickness] = ginput();

    % Associate the picks with latitudes and longitudes
    PickLongitudes = zeros(1,length(xlocations));
    PickLatitudes = zeros(1,length(xlocations));
    for ipick=1:length(xlocations)
        OffsetDistance = 1000000000;
        for istation=1:length(StationDistances)
            if abs(xlocations(ipick)-StationDistances(istation)) < OffsetDistance
                OffsetDistance = abs(xlocations(ipick)-StationDistances(istation));
                PickLongitudes(ipick) = StationLongitudes(istation);
                PickLatitudes(ipick) = StationLatitudes(istation);
            end
        end
    end

    % Fill output array
    % first find, the first empty point
    for idx=1:length(ManualPickMohoRFCrossSectionArray)
        if ManualPickMohoRFCrossSectionArray(idx,1) == 0
            break
        end
    end
    for jdx=1:length(xlocations)
        ManualPickMohoRFCrossSectionArray(jdx+idx-1,1) = PickLongitudes(jdx);
        ManualPickMohoRFCrossSectionArray(jdx+idx-1,2) = PickLatitudes(jdx);
        ManualPickMohoRFCrossSectionArray(jdx+idx-1,3) = crustalthickness(jdx);
    end

    % Save
    assignin('base','ManualPickMohoRFCrossSectionArray',ManualPickMohoRFCrossSectionArray);
    save([ProjectDirectory ProjectFile], 'ManualPickMohoRFCrossSectionArray','-append');

    for istation=1:nStations
        q=[StationLongitudes(istation), StationLatitudes(istation), 0];
        p=[ptright(1), ptright(2), 0];
        q_proj = q - dot(q-p, normal) * normal;
        [StationDistances(istation), ~, ~] = distaz(p(2), p(1), q_proj(2), q_proj(1));
    end
    
    plotxlocations = zeros(1,length(xlocations));
    for idx=1:length(xlocations)
        q=[PickLongitudes(idx), PickLatitudes(idx), 0];
        p=[ptright(1), ptright(2), 0];
        q_proj = q - dot(q-p, normal) * normal;
        [plotxlocations(idx), ~, ~] = distaz(p(2), p(1), q_proj(2), q_proj(1));
    end
    scatter(plotxlocations, crustalthickness,100,'filled');

    hdls = findobj('Tag','plot_moho_rf_cross_sections_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','plot_moho_all_sources_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','export_moho_rf_cross_sections_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','export_moho_all_sources_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','moho_manual_pick_aggregator');
    set(hdls,'Enable','on');
    
%% ------------------------------------------------------------------------
% manual_pick_station_stack
% This callback function uses the metadata to find all active traces for
% the selected station. It then stacks them in depth space and provides a
% 1D plot of RF amp vs. depth and ginput for the user to select the moho
% -------------------------------------------------------------------------
function manual_pick_station_stack_callback(cbo, eventdata, handles)
    global PickingStructure;
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    % First we need to evaluate if a structure to hold all this information
    % exists in the base set. If not, we'll create it and provide entries for
    % all the stations
    try
        ManualPickMohoStationStackCell=evalin('base','ManualPickMohoStationStackCell');
    catch
        ManualPickMohoStationStackCell=[];
    end
    if isempty(ManualPickMohoStationStackCell)
        ManualPickMohoStationStackCell = cell(length(cbo.String),6);
        for istation = 1:length(cbo.String)
            ManualPickMohoStationStackCell{istation, 1} = cbo.String{istation};
        end
        assignin('base','ManualPickMohoStationStackCell',ManualPickMohoStationStackCell);
    else
        a=size(ManualPickMohoStationStackCell);
        if a(2) < 6 && a(1) == length(cbo.String)
            ManualPickMohoStationStackCell = cell(length(cbo.String),6);
            ManualPickMohoStationStackCellTmp = evalin('base','ManualPickMohoStationStackCell');
            for istation = 1:length(cbo.String)
                for jstation=1:length(cbo.String)
                    if strcmp(cbo.String{istation}, ManualPickMohoStationStackCellTmp{jstation,1})
                        kstation = jstation;
                        break;
                    end
                end
                ManualPickMohoStationStackCell{istation, 1} = ManualPickMohoStationStackCellTmp{kstation, 1};
                ManualPickMohoStationStackCell{istation, 2} = ManualPickMohoStationStackCellTmp{kstation, 2};
                ManualPickMohoStationStackCell{istation, 3} = ManualPickMohoStationStackCellTmp{kstation, 3};
                ManualPickMohoStationStackCell{istation, 4} = ManualPickMohoStationStackCellTmp{kstation, 4};
                ManualPickMohoStationStackCell{istation, 5} = ManualPickMohoStationStackCellTmp{kstation, 5};
                ManualPickMohoStationStackCell{istation, 6} = 1;
            end
            clear ManualPickMohoStationStackCellTmp
            assignin('base','ManualPickMohoStationStackCell',ManualPickMohoStationStackCell);
        elseif a(1) < length(cbo.String)
            ManualPickMohoStationStackCell = cell(length(cbo.String),6);
            ManualPickMohoStationStackCellTmp = evalin('base','ManualPickMohoStationStackCell');
            b = size(ManualPickMohoStationStackCellTmp);
            for istation = 1:length(cbo.String)
                StationFoundFlag = 0;
                for jstation=1:b(1)
                    if strcmp(cbo.String{istation}, ManualPickMohoStationStackCellTmp{jstation,1})
                        kstation = jstation;
                        StationFoundFlag = 1;
                        break;
                    end
                end
                if StationFoundFlag == 1
                    ManualPickMohoStationStackCell{istation, 1} = ManualPickMohoStationStackCellTmp{kstation, 1};
                    ManualPickMohoStationStackCell{istation, 2} = ManualPickMohoStationStackCellTmp{kstation, 2};
                    ManualPickMohoStationStackCell{istation, 3} = ManualPickMohoStationStackCellTmp{kstation, 3};
                    ManualPickMohoStationStackCell{istation, 4} = ManualPickMohoStationStackCellTmp{kstation, 4};
                    ManualPickMohoStationStackCell{istation, 5} = ManualPickMohoStationStackCellTmp{kstation, 5};
                    ManualPickMohoStationStackCell{istation, 6} = 1;
                else
                    ManualPickMohoStationStackCell{istation, 1} = cbo.String{istation};
                end
            end
            clear ManualPickMohoStationStackCellTmp
            assignin('base','ManualPickMohoStationStackCell',ManualPickMohoStationStackCell);
        elseif a(2) == 6 && a(1) == length(cbo.String)
            ManualPickMohoStationStackCell = evalin('base','ManualPickMohoStationStackCell');
        end
    end

    StationName = cbo.String{cbo.Value};
    VelModel = FuncLabPreferences{8};
    oneDVel = load(VelModel,'-ascii');
    CurrentStationIndices=find(strcmp(StationName, RecordMetadataStrings(:,2)));
    StartDepthArray = 0;
    EndDepthArray = 100;
    dz=1;
    StepDepthArray = dz;
    DepthArray = StartDepthArray:StepDepthArray:EndDepthArray;

    % Prepare empty cell arrays for this station
    nActiveRecords = 0;
    for irecord=1:length(CurrentStationIndices)
        thisIndex = CurrentStationIndices(irecord);
        if RecordMetadataDoubles(thisIndex,2) == 1
            nActiveRecords = nActiveRecords + 1;
        end
    end
    if nActiveRecords == 0
        disp('No active records!')
        return
    end
    RFAmps = cell(1,nActiveRecords);
    RFTimes = cell(1,nActiveRecords);
    rayparams = zeros(1,nActiveRecords);
    % For counting the active records
    jrecord = 0;

    % Get location of this station
    StationLongitude = RecordMetadataDoubles(CurrentStationIndices(1),11);
    StationLatitude = RecordMetadataDoubles(CurrentStationIndices(1),10);

    % Get background moho
    if PickingStructure.Background == true
        EstimatedThickness = PickingStructure.BackgroundFunction(StationLongitude, StationLatitude);
    else
        EstimatedThickness = PickingStructure.InitialThickness;
    end 
    
    % Loop through the receiver functions
    for irecord = 1:length(CurrentStationIndices)
        % This references it back to the main project RFs
        thisIndex = CurrentStationIndices(irecord);

        % Check to make sure this rf is active
        if RecordMetadataDoubles(thisIndex, 2) == 1
            jrecord = jrecord + 1;
            fname = sprintf('%seqr',RecordMetadataStrings{thisIndex,1});

            % Load the seismogram
            [EqAmpTime, EQTime] = fl_readseismograms([ProjectDirectory fname]);

            % Place into cell arrays for time, amplitude, and ray parameter
            RFAmps{jrecord} = EqAmpTime;
            RFTimes{jrecord} = EQTime;
            rayparams(jrecord) = RecordMetadataDoubles(thisIndex,18);

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

    AMPS = stackArray;
    AmplitudeFactor = 1;
    MaximumAmplitude = max(abs(AMPS));
    MaximumAmplitude = repmat(MaximumAmplitude,size(AMPS,1),1);
    NormalizedAmplitudes = AMPS ./ MaximumAmplitude;
    Gain = 1.0;
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
    PFilledTrace = [zeros(1,length(PFilledTrace)), PFilledTrace, zeros(1,length(PFilledTrace))];
    NFilledTrace = [zeros(1,length(NFilledTrace)), NFilledTrace, zeros(1,length(NFilledTrace))];
    DepthAxis = DepthArray';
    DepthAxis = [ones(1,length(DepthAxis)) * DepthAxis(1), ...
        DepthAxis', ...
        ones(1,length(DepthAxis)) * DepthAxis(end)];

    % Actual figure
    ProfileFigureHandles = figure('Units','characters','NumberTitle','off','Name',StationName,'Units','characters',...
        'Position',[0 0 70 70],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});
    ax = axes('Parent',ProfileFigureHandles);
    xlim(ax,[-1 1])
    ylim(ax,[StartDepthArray EndDepthArray])
    line(ax, [-1 1], [EstimatedThickness, EstimatedThickness],'Color',[191/255, 87/255, 0], 'LineWidth',2,'LineStyle','-.');
    set(ax,'YDir','Reverse')
    grid(ax,'on')
    grid(ax,'minor')
    box(ax,'on')
    ylabel(ax,'Depth (km)')
    xlabel(ax,'RF Amplitude')
    title('Radial RF')
    % Add text for longitude, latitude, and N RFs. Also add N RFs to cell.
    % add both station name and N RFs to export
    nrfs = length(CorrectedSeismogramAmps);
    tmpstr = sprintf('N RFs: %d',nrfs);
    text(0.55, 90, tmpstr,'FontSize',14);
    tmpstr = sprintf('Location %3.2f%c %3.2f%c',StationLatitude, char(176),StationLongitude,char(176));
    text(0.15, 95, tmpstr,'FontSize',14);

    % Plot amplitudes along profile
    % % plotting
    hold on
    vp = [PFilledTrace; DepthAxis];
    vn = [NFilledTrace; DepthAxis];
    idx = length(vp);
    vvp = vp;
    vvn = vn;
    vvp(1,idx+1) = 0;
    vvp(2,idx+1) = max(DepthAxis);
    vvp(1,idx+2) = 0;
    vvp(2,idx+2) = min(DepthAxis);
    vvn(1,idx+1) = 0;
    vvn(2,idx+1) = max(DepthAxis);
    vvn(1,idx+2) = 0;
    vvn(2,idx+2) = min(DepthAxis);
    ff=length(vvp):-1:1;
    patch(ax,'Faces',ff,'Vertices',vvp','FaceColor',[1 0 0],'EdgeColor','none','Tag','phandle');
    patch(ax,'Faces',ff,'Vertices',vvn','FaceColor',[0 0 1],'EdgeColor','none','Tag','nhandle');
    line(ax,Amplitudes,DepthArray,'Color',[0 0 0],'LineWidth',1)

    % Ok, now ginput to select the moho
    [~, CrustalThickness] = ginput(1);
    TmpAmp = interp1(DepthArray, Amplitudes, CrustalThickness);
    scatter(ax, TmpAmp, CrustalThickness,200,'filled');

    % Return to base variable
    idx = find(strcmp(ManualPickMohoStationStackCell(:,1), StationName));
    ManualPickMohoStationStackCell{idx,2} = StationLongitude;
    ManualPickMohoStationStackCell{idx,3} = StationLatitude;
    ManualPickMohoStationStackCell{idx,4} = CrustalThickness;
    ManualPickMohoStationStackCell{idx,5} = TmpAmp;
    ManualPickMohoStationStackCell{idx,6} = 1;
    assignin('base','ManualPickMohoStationStackCell',ManualPickMohoStationStackCell);
    save([ProjectDirectory ProjectFile], 'ManualPickMohoStationStackCell','-append');

    hdls = findobj('Tag','plot_moho_station_stack_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','plot_moho_all_sources_m');
    set(hdls,'Enable','on');

    hdls = findobj('Tag','export_moho_station_stack_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','export_moho_all_sources_m');
    set(hdls,'Enable','on');
    hdls = findobj('Tag','moho_manual_pick_aggregator');
    set(hdls,'Enable','on');

%% ------------------------------------------------------------------------
% -------------------------------------------------------------------------
% moho_manual_pick_about_ccp_cross_section_callback
%
% This callback function displays a short message and closes once the ok
% button is pressed
% -------------------------------------------------------------------------
function moho_manual_pick_about_ccp_cross_section_callback(cbo, eventdata, handles)
MainPos = [0 0 75 25];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','Moho auto pick help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['This tool asks you to select a start and end point in map view and then makes a cross section through a CCP volume. Requires a CCP volume to have been loaded before the function is available.'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
    'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','OK','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close');

%% ------------------------------------------------------------------------
% -------------------------------------------------------------------------
% moho_manual_pick_about_one_d_depth_profile_callback
%
% This callback function displays a short message and closes once the ok
% button is pressed
% -------------------------------------------------------------------------
function moho_manual_pick_about_one_d_depth_profile_callback(cbo, eventdata, handles)
MainPos = [0 0 75 25];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','Moho auto pick help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['This tool asks you to select a location and plots a 1D curve through a CCP volume. Requires a CCP volume to have been loaded before the function is available.'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
    'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','OK','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close');

%% ------------------------------------------------------------------------
% -------------------------------------------------------------------------
% moho_manual_pick_about_ray_diagram_cross_section
%
% This callback function displays a short message and closes once the ok
% button is pressed
% -------------------------------------------------------------------------
function moho_manual_pick_about_ray_diagram_cross_section_callback(cbo, eventdata, handles)
MainPos = [0 0 75 25];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','Moho auto pick help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['This tool asks you to select start and end points for a cross section, then loads the ray info file from PRF to depth mapping. Give it binning information to compute a 2D CCP on the fly and it will plot a cross section for you to pick. Picks are mapped to their spatial location along the profile.'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
    'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','OK','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close');

%% ------------------------------------------------------------------------
% -------------------------------------------------------------------------
% moho_manual_pick_about_rf_cross_section
%
% This callback function displays a short message and closes once the ok
% button is pressed
% -------------------------------------------------------------------------
function moho_manual_pick_about_rf_cross_section(cbo, eventdata, handles)
MainPos = [0 0 75 25];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','Moho auto pick help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['This tool asks you to select start and end points for a cross section, then selects stations within that cross section. Selected stations are mapped to depth via a 1D model and plotted at their distance along the profile. Picks are then mapped to the spatial location of the nearest station.'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
    'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','OK','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close');

%%
% -------------------------------------------------------------------------
% moho_manual_pick_about_station_depth_stack_callback
%
% This callback function displays a short message and closes once the ok
% button is pressed
% -------------------------------------------------------------------------
function moho_manual_pick_about_station_depth_stack_callback(cbo, eventdata, handles)
MainPos = [0 0 75 25];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','Moho auto pick help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['This tool, upon selecting a station, will convert all active receiver functions for that station from time to depth via a 1D model and stack. A plot is then made of that stack and upon clicking on the plot, a crustal thickness is recorded. Re-running for the station overwrites the previous pick.'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
    'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','OK','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close');

%%
% -------------------------------------------------------------------------
% moho_manual_pick_about_callback
%
% This callback function displays a short message and closes once the ok
% button is pressed
% -------------------------------------------------------------------------
function moho_manual_pick_about_callback(cbo, eventdata, handles)

MainPos = [0 0 75 25];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','Moho auto pick help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['This addon allows the user to manually pick a moho. Tools along the right hand side allow picking '...
    'based on either the depth mapped PRF, the spatially mapped PRF, or the CCP volume. '...
    'Use the Aggregator menu to combine the estimates into a continuous surface.'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
    'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','OK','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close');

% -------------------------------------------------------------------------
% moho_manual_pick_about_purge_callback
%
% This callback function displays a short message and closes once the ok
% button is pressed
% -------------------------------------------------------------------------
function moho_manual_pick_about_purge_callback(cbo, eventdata, handles)
MainPos = [0 0 75 25];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','Moho auto pick help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['The purge function will remove previously moho picks. '...
    'These functions can be undune with purge by polygon. '...
    'The purge by polygon function allows you to choose a region and then. '...
    'sorts the picks within that polygon into a table for fine edits.'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
    'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','OK','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close');

% -------------------------------------------------------------------------
% moho_manual_pick_about_load_initial_callback
%
% This callback function displays a short message and closes once the ok
% button is pressed
% -------------------------------------------------------------------------
function moho_manual_pick_about_load_initial_callback(cbo, eventdata, handles)
MainPos = [0 0 75 25];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','Moho auto pick help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['This function allows you load an expected Moho structure. '...
    'The xyz file assumes longitude, latitude, crustal thickness. '...
    'scatteredInterpolant is a Matlab function that can be evaluated '...
    'at arbirtrary locations. The predictions are plotted, but not '...
    'included in analysis.'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
    'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','OK','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close');

%% ------------------------------------------------------------------------
% moho_manual_pick_warning_callback
%
% This callback function displays a short message and closes once the ok
% button is pressed
% -------------------------------------------------------------------------
function moho_manual_pick_warning_callback(cbo, eventdata, handles)

MainPos = [0 0 75 25];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','Moho auto pick help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['This addon uses depth mapped receiver functions. This requires a velocity model, which may influence your results.'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
    'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','I have been warned.','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close');

%% ------------------------------------------------------------------------
%  Removes all picks from the project file.
%  This cannot be undone.
%  ------------------------------------------------------------------------
function purge_all_picks_callback(cbo, eventdata, handles)

    MainPos = [0 0 75 25];
    ProcButtonPos = [35 2 35 3];
    CancelButtonPos = [5 2 25 3];
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');


    HelpDlg = dialog('Name','Warning','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
        'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    str = ['Warning, this will make all picks inactive. Are you sure you wish to proceed?'];

    HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
        'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

    OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','I have been warned. Proceed.','Units','Characters',...
        'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','assignin(''base'',''doit'',1); close');
    
    CancelButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','Cancel!','Units','Characters',...
        'Position',CancelButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','assignin(''base'',''doit'',0); close');

    waitfor(HelpDlg);
    
    doit = evalin('base','doit');
    if doit == 1 % Just setting the logic element to 0 from 1
        ManualPickMohoCCPoneDArray = evalin('base','ManualPickMohoCCPoneDArray');
        for idx=1:length(ManualPickMohoCCPoneDArray)
            ManualPickMohoCCPoneDArray(idx,4) = 0;
        end
        assignin('base','ManualPickMohoCCPoneDArray',ManualPickMohoCCPoneDArray);
        
        ManualPickMohoRFCrossSectionArray = evalin('base','ManualPickMohoRFCrossSectionArray');
        for idx=1:length(ManualPickMohoRFCrossSectionArray)
            ManualPickMohoRFCrossSectionArray(idx,4) = 0;
        end
        assignin('base','ManualPickMohoRFCrossSectionArray',ManualPickMohoRFCrossSectionArray);
        
        ManualPickMohoRayCrossSectionArray = evalin('base','ManualPickMohoRayCrossSectionArray');
        for idx=1:length(ManualPickMohoRayCrossSectionArray)
            ManualPickMohoRayCrossSectionArray(idx,4) = 0;
        end
        assignin('base','ManualPickMohoRayCrossSectionArray',ManualPickMohoRayCrossSectionArray);
        
        ManualPickMohoCCPCrossSectionArray = evalin('base','ManualPickMohoCCPCrossSectionArray');
        for idx=1:length(ManualPickMohoCCPCrossSectionArray)
            ManualPickMohoCCPCrossSectionArray(idx,4) = 0;
        end
        assignin('base','ManualPickMohoCCPCrossSectionArray',ManualPickMohoCCPCrossSectionArray);
        
        ManualPickMohoStationStackCell = evalin('base','ManualPickMohoStationStackCell');
        for idx=1:length(ManualPickMohoStationStackCell)
            ManualPickMohoStationStackCell{idx,6} = 0;
        end
        assignin('base','ManualPickMohoStationStackCell',ManualPickMohoStationStackCell);
        % Saves to project file
        save([ProjectDirectory ProjectFile], 'ManualPickMohoCCPoneDArray', 'ManualPickMohoRFCrossSectionArray','ManualPickMohoRayCrossSectionArray','ManualPickMohoCCPCrossSectionArray','ManualPickMohoStationStackCell','-append');
    
        
    elseif doit == 2 % This shouldn't trigger
    
        %Clears from the base workspace
        assignin('base','ManualPickMohoCCPoneDArray',[]);
        assignin('base','ManualPickMohoRFCrossSectionArray',[]);
        assignin('base','ManualPickMohoRayCrossSectionArray',[]);
        assignin('base','ManualPickMohoCCPCrossSectionArray',[]);
        assignin('base','ManualPickMohoStationStackCell',[]);

        % Clears current workspace
        ManualPickMohoCCPoneDArray = [];
        ManualPickMohoRFCrossSectionArray = [];
        ManualPickMohoRayCrossSectionArray = [];
        ManualPickMohoCCPCrossSectionArray = [];
        ManualPickMohoStationStackCell = [];

        % Saves to project file
        save([ProjectDirectory ProjectFile], 'ManualPickMohoCCPoneDArray', 'ManualPickMohoRFCrossSectionArray','ManualPickMohoRayCrossSectionArray','ManualPickMohoCCPCrossSectionArray','ManualPickMohoStationStackCell','-append');
    
    end

%% ------------------------------------------------------------------------
%  Removes StationStack picks from the project file.
%  This cannot be undone.
%  ------------------------------------------------------------------------
function purge_station_depth_stack_picks_callback(cbo, eventdata, handles)

    MainPos = [0 0 75 25];
    ProcButtonPos = [35 2 35 3];
    CancelButtonPos = [5 2 25 3];
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');


    HelpDlg = dialog('Name','Warning','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
        'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    str = ['Warning, this will make all station stack picks inactive. Are you sure you wish to proceed?'];

    HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
        'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

    OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','I have been warned. Proceed.','Units','Characters',...
        'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','assignin(''base'',''doit'',1); close');
    
    CancelButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','Cancel!','Units','Characters',...
        'Position',CancelButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','assignin(''base'',''doit'',0); close');

    waitfor(HelpDlg);
    
    doit = evalin('base','doit');
    
    if doit == 1
        ManualPickMohoStationStackCell = evalin('base','ManualPickMohoStationStackCell');
        for idx=1:length(ManualPickMohoStationStackCell)
            ManualPickMohoStationStackCell{idx,6} = 0;
        end
        assignin('base','ManualPickMohoStationStackCell',ManualPickMohoStationStackCell);
        save([ProjectDirectory ProjectFile], 'ManualPickMohoStationStackCell','-append');

    elseif doit == 2
    
        %Clears from the base workspace
        assignin('base','ManualPickMohoStationStackCell',[]);

        % Clears current workspace
        ManualPickMohoStationStackCell = [];

        % Saves to project file
        save([ProjectDirectory ProjectFile], 'ManualPickMohoStationStackCell','-append');
    
    end

%% ------------------------------------------------------------------------
%  Removes rf cross section picks from the project file.
%  This cannot be undone.
%  ------------------------------------------------------------------------
function purge_rf_cross_section_picks_callback(cbo, eventdata, handles)

    MainPos = [0 0 75 25];
    ProcButtonPos = [35 2 35 3];
    CancelButtonPos = [5 2 25 3];
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');


    HelpDlg = dialog('Name','Warning','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
        'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    str = ['Warning, this will make all RF Cross Section picks inactive. Are you sure you wish to proceed?'];

    HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
        'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

    OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','I have been warned. Proceed.','Units','Characters',...
        'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','assignin(''base'',''doit'',1); close');
    
    CancelButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','Cancel!','Units','Characters',...
        'Position',CancelButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','assignin(''base'',''doit'',0); close');

    waitfor(HelpDlg);
    
    doit = evalin('base','doit');
    
    if doit == 1 
        ManualPickMohoRFCrossSectionArray = evalin('base','ManualPickMohoRFCrossSectionArray');
        for idx=1:length(ManualPickMohoRFCrossSectionArray)
            ManualPickMohoRFCrossSectionArray(idx,4) = 0;
        end
        assignin('base','ManualPickMohoRFCrossSectionArray',ManualPickMohoRFCrossSectionArray);
        save([ProjectDirectory ProjectFile], 'ManualPickMohoRFCrossSectionArray','-append');

    elseif doit == 2
    
        %Clears from the base workspace
        assignin('base','ManualPickMohoRFCrossSectionArray',[]);

        % Clears current workspace
        ManualPickMohoRFCrossSectionArray = [];

        % Saves to project file
        save([ProjectDirectory ProjectFile], 'ManualPickMohoRFCrossSectionArray','-append');
    
    end  

%% ------------------------------------------------------------------------
%  Removes rf cross section picks from the project file.
%  This cannot be undone.
%  ------------------------------------------------------------------------
function purge_ccp_cross_section_picks_callback(cbo, eventdata, handles)

    MainPos = [0 0 75 25];
    ProcButtonPos = [35 2 35 3];
    CancelButtonPos = [5 2 25 3];
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');


    HelpDlg = dialog('Name','Warning','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
        'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    str = ['Warning, this will make all CCP Cross Section picks inactive. Are you sure you wish to proceed?'];

    HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
        'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

    OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','I have been warned. Proceed.','Units','Characters',...
        'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','assignin(''base'',''doit'',1); close');
    
    CancelButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','Cancel!','Units','Characters',...
        'Position',CancelButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','assignin(''base'',''doit'',0); close');

    waitfor(HelpDlg);
    
    doit = evalin('base','doit');
    
    if doit == 1
        ManualPickMohoCCPCrossSectionArray = evalin('base','ManualPickMohoCCPCrossSectionArray');
        for idx=1:length(ManualPickMohoCCPCrossSectionArray)
            ManualPickMohoCCPCrossSectionArray(idx,4) = 0;
        end
        assignin('base','ManualPickMohoCCPCrossSectionArray',ManualPickMohoCCPCrossSectionArray);
        save([ProjectDirectory ProjectFile], 'ManualPickMohoCCPCrossSectionArray','-append');

    elseif doit == 2
    
        %Clears from the base workspace
        assignin('base','ManualPickMohoCCPCrossSectionArray',[]);

        % Clears current workspace
        ManualPickMohoCCPCrossSectionArray = [];

        % Saves to project file
        save([ProjectDirectory ProjectFile], 'ManualPickMohoCCPCrossSectionArray','-append');
    
    end  
    
%% ------------------------------------------------------------------------
%  removes on the fly 2D ccp picks. Remember, this was originally called
%  ray diagram, but the ray diagram was too slow and therefore changed to
%  2D ccp
%  ------------------------------------------------------------------------
function purge_ray_diagram_picks_callback(cbo, eventdata, handles)

    MainPos = [0 0 75 25];
    ProcButtonPos = [35 2 35 3];
    CancelButtonPos = [5 2 25 3];
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');

    HelpDlg = dialog('Name','Warning','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
        'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    str = ['Warning, this will make all 2D CCP Cross Section picks inactive. Are you sure you wish to proceed?'];

    HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
        'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

    OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','I have been warned. Proceed.','Units','Characters',...
        'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','assignin(''base'',''doit'',1); close');
    
    CancelButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','Cancel!','Units','Characters',...
        'Position',CancelButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','assignin(''base'',''doit'',0); close');

    waitfor(HelpDlg);
    
    doit = evalin('base','doit');
    
    if doit == 1
        
        ManualPickMohoRayCrossSectionArray = evalin('base','ManualPickMohoRayCrossSectionArray');
        for idx=1:length(ManualPickMohoRayCrossSectionArray)
            ManualPickMohoRayCrossSectionArray(idx,4) = 0;
        end
        assignin('base','ManualPickMohoRayCrossSectionArray',ManualPickMohoRayCrossSectionArray);
        save([ProjectDirectory ProjectFile], 'ManualPickMohoRayCrossSectionArray','-append');
            
    elseif doit == 2
    
        %Clears from the base workspace
        assignin('base','ManualPickMohoRayCrossSectionArray',[]);

        % Clears current workspace
        ManualPickMohoRayCrossSectionArray = [];

        % Saves to project file
        save([ProjectDirectory ProjectFile], 'ManualPickMohoRayCrossSectionArray','-append');
    
    end
    
%% ------------------------------------------------------------------------
%  Removes rf cross section picks from the project file.
%  This cannot be undone.
%  ------------------------------------------------------------------------
function purge_1d_ccp_picks_callback(cbo, eventdata, handles)

    MainPos = [0 0 75 25];
    ProcButtonPos = [35 2 35 3];
    CancelButtonPos = [5 2 25 3];
    ProjectDirectory = evalin('base','ProjectDirectory');   
    ProjectFile = evalin('base','ProjectFile');

    HelpDlg = dialog('Name','Warning','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
        'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    str = ['Warning, this will make all CCP 1D depth profile picks inactive. Are you sure you wish to proceed?'];

    HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
        'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

    OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','I have been warned. Proceed.','Units','Characters',...
        'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','assignin(''base'',''doit'',1); close');
    
    CancelButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','Cancel!','Units','Characters',...
        'Position',CancelButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','assignin(''base'',''doit'',0); close');

    waitfor(HelpDlg);
    
    doit = evalin('base','doit');
    
    if doit == 1
        ManualPickMohoCCPoneDArray = evalin('base','ManualPickMohoCCPoneDArray');
        for idx=1:length(ManualPickMohoCCPoneDArray)
            ManualPickMohoCCPoneDArray(idx,4) = 0;
        end
        assignin('base','ManualPickMohoCCPoneDArray',ManualPickMohoCCPoneDArray);
        save([ProjectDirectory ProjectFile], 'ManualPickMohoCCPoneDArray','-append');
        
    elseif doit == 2
    
        %Clears from the base workspace
        assignin('base','ManualPickMohoCCPoneDArray',[]);

        % Clears current workspace
        ManualPickMohoCCPoneDArray = [];

        % Saves to project file
        save([ProjectDirectory ProjectFile], 'ManualPickMohoCCPoneDArray','-append');
    
    end
    
%% ------------------------------------------------------------------------
%  purge_picks_by_polygon_callback
%  Bit more nuanced purge tool. 
%  Pops up a new map and has the user click a polygon. All picks within
%  that polygon are then added to a table and selection tools allow picking
%  by the table.
%  ------------------------------------------------------------------------
function purge_picks_by_polygon_callback(cbo, eventdata, handles)
    % Gather project metadata
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
    global PickingStructure;
    
    % Check for existance of various types of picks
    % Updates the checkboxes
    try
        ManualPickMohoStationStackCell=evalin('base','ManualPickMohoStationStackCell');
    catch
        ManualPickMohoStationStackCell=[];
    end
    if isempty(ManualPickMohoStationStackCell)
        station_stack_flag = 0;
        station_stack_enable = 'off';
    else
        station_stack_flag = 1;
        station_stack_enable = 'on';
    end
    
    try
        ManualPickMohoRFCrossSectionArray=evalin('base','ManualPickMohoRFCrossSectionArray');
    catch
        ManualPickMohoRFCrossSectionArray=[];
    end
    if isempty(ManualPickMohoRFCrossSectionArray)
        rf_cross_section_flag = 0;
        rf_cross_section_enable = 'off';
    else
        rf_cross_section_flag = 1;
        rf_cross_section_enable = 'on';
    end
    
    try
        ManualPickMohoRayCrossSectionArray=evalin('base','ManualPickMohoRayCrossSectionArray');
    catch
        ManualPickMohoRayCrossSectionArray=[];
    end
    if isempty(ManualPickMohoRayCrossSectionArray)
        ray_diagram_flag = 0;
        ray_diagram_enable = 'off';
    else
        ray_diagram_flag = 1;
        ray_diagram_enable = 'on';
    end
    
    try
        ManualPickMohoCCPoneDArray=evalin('base','ManualPickMohoCCPoneDArray');
    catch
        ManualPickMohoCCPoneDArray=[];
    end
    if isempty(ManualPickMohoCCPoneDArray)
        ccp_oned_flag = 0;
        ccp_oned_enable = 'off';
    else
        ccp_oned_flag = 1;
        ccp_oned_enable = 'on';
    end
    
    try
        ManualPickMohoCCPCrossSectionArray=evalin('base','ManualPickMohoCCPCrossSectionArray');
    catch
        ManualPickMohoCCPCrossSectionArray=[];
    end
    if isempty(ManualPickMohoCCPCrossSectionArray)
        ccp_cross_section_flag = 0;
        ccp_cross_section_enable = 'off';
    else
        ccp_cross_section_flag = 1;
        ccp_cross_section_enable = 'on';
    end
    
    % GUI will have a handful of elements:
    % Text and edit box:
    % lat/lon min/max/increment
    % Smooth in longitude nodes, smooth in latitude nodes
    % Make strings out of the geographic limits
    
    % Get map view parameters from strings in the preferences to floats
    MinLatitude = sscanf(FuncLabPreferences{14},'%f');
    MaxLatitude = sscanf(FuncLabPreferences{13},'%f');
    MinLongitude = sscanf(FuncLabPreferences{15},'%f');
    MaxLongitude = sscanf(FuncLabPreferences{16},'%f');
    
    load FL_coasts
    load FL_plates
    load FL_stateBoundaries
    
    % Prepare a figure for picking
    MainPos = [0 0 130 37];
    
    PickerPolygonGui = dialog('Name','Choose polygon','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
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

    % Create a map view axis
    MapViewPanel = uipanel('Title','Map view','FontSize',12,'BackgroundColor','White','Units','Normalized','Position',[0.01 0.1 0.79 0.85]);
    MapViewAxesHandles = axes('Parent',MapViewPanel,'Units','Normalized','Position',[.05 .05 .9 .9]);
    minlon = floor(PickingStructure.MinimumLongitude);
    maxlon = ceil(PickingStructure.MaximumLongitude);
    minlat = floor(PickingStructure.MinimumLatitude);
    maxlat = ceil(PickingStructure.MaximumLatitude);
    m_proj(MapProjection,'latitude',[minlat maxlat], 'longitude', [minlon maxlon]);
    %m_proj('Hammer-Aitoff','latitude',[-90 90],'longitude',[-180 180]);

    % Makes the initial plot view - global coast lines and a shaded box for the
    % CCP image volume
    %plot(ncst(:,1),ncst(:,2),'k')
    hold on
    %m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
    m_coast('patch',[.9 .9 .9],'edgecolor','black');
    m_line(PBlong, PBlat,'Color',[0.2 0.2 0.8])
    m_line(stateBoundaries.longitude, stateBoundaries.latitude,'Color',[0 0 0])
    %axis([-180 180 -90 90])
    %m_grid('xtick',floor((maxlon-minlon)/10),'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
    m_grid('xtick',4,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');


    OnColor = [.3 .3 .3];
    OffColor = [1 .5 .5];
    CurrentColor = [ 1 .7 0];
    SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
    SetOffColor = abs(cross(SetOnColor,OnColor));
    % Add the stations
    StationLocations = unique([PickingStructure.RecordMetadataDoubles(:,10), PickingStructure.RecordMetadataDoubles(:,11)],'rows');
    m_line(StationLocations(:,2),StationLocations(:,1),'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
    
    % Add the UI elements
    % New Polygon
    uicontrol('Style','Pushbutton','Parent',PickerPolygonGui,'Units','Normalized','Position',[0.82 0.3 0.15 0.1],'String','New Polygon','Callback',{@purge_polygon_new_polygon_callback});

    % Confirm
    uicontrol('Style','Pushbutton','Parent',PickerPolygonGui,'Units','Normalized','Position',[0.82 0.2 0.15 0.1],'String','Confirm','Callback',{@purge_polygon_confirm_callback});

    % Close/cancel
    uicontrol('Style','Pushbutton','Parent',PickerPolygonGui,'Units','Normalized','Position',[0.82 0.1 0.15 0.1],'String','Cancel','Callback',{@purge_polygon_cancel_callback});

%% ------------------------------------------------------------------------
%  purge_polygon_new_polygon_callback
%  launches a ginput until user hits return. Then plots a field around the
%  polygon and sets a variable that allows confirm to actually work
%  ------------------------------------------------------------------------
function purge_polygon_new_polygon_callback(cbo, eventdata, handles)
    MainPos = [0 0 80 25];
    ProcButtonPos = [20 2 40 3];
    
    PauseDlg = dialog('Name','Warning','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
        'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    str = ['Please click at least three points to create a polygon and then hit enter.'];

    HelpText = uicontrol('Parent',PauseDlg,'Style','Edit','String',str,'Units','Characters','Max',100,'Min',1,...
        'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

    OkButton = uicontrol('Parent',PauseDlg,'Style','Pushbutton','String','OK','Units','Characters',...
        'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.3,'ForegroundColor',[0.6 0 0],...
        'Callback','close');
    
    waitfor(PauseDlg);
    
    % Get the vertices of a polygon
    [x, y] = ginput();
    
    % Convert vertices to map coordiants
    % Gather project metadata
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
    global PickingStructure;
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

    % Bits to finish converting from the pick points into latitude and
    % longitude
    minlon = floor(PickingStructure.MinimumLongitude);
    maxlon = ceil(PickingStructure.MaximumLongitude);
    minlat = floor(PickingStructure.MinimumLatitude);
    maxlat = ceil(PickingStructure.MaximumLatitude);
    m_proj(MapProjection,'latitude',[minlat maxlat], 'longitude', [minlon maxlon]);
    [p_lon, p_lat] = m_xy2ll(x,y);
    
    % Assign the values to the base set. We'll pull them up once we confirm
    assignin('base','p_lon',p_lon);
    assignin('base','p_lat',p_lat);
    
    % Plot the points as vertices with lines connecting them.
    hold on
    m_line([p_lon; p_lon(1)], [p_lat; p_lat(1)],'LineWidth',1.5,'Marker','*','MarkerSize',12);
    m_patch([p_lon; p_lon(1)], [p_lat; p_lat(1)], [.7490 .3412 0])
                
%% ------------------------------------------------------------------------
%  purge_polygon_confirm_callback
%  evaluates the polygon set by new_polygon. If there is no polygon
%  defined, it sends a warning and defaults to all picks. Once the picks
%  are all found, it then populates a table that the user can turn
%  individual picks on or off. Also has tools for quickly setting lots of
%  picks on or off (all, none, invert selection...)
%  ------------------------------------------------------------------------
function purge_polygon_confirm_callback(cbo, eventdata, handles)
    p_lon = evalin('base','p_lon');
    p_lat = evalin('base','p_lat');
    close(gcf);
    
    % Need to get the pick data
    try
        ManualPickMohoStationStackCell=evalin('base','ManualPickMohoStationStackCell');
    catch
        ManualPickMohoStationStackCell=[];
    end

    try
        ManualPickMohoRFCrossSectionArray=evalin('base','ManualPickMohoRFCrossSectionArray');
    catch
        ManualPickMohoRFCrossSectionArray=[];
    end
    
    try
        ManualPickMohoRayCrossSectionArray=evalin('base','ManualPickMohoRayCrossSectionArray');
    catch
        ManualPickMohoRayCrossSectionArray=[];
    end
    
    try
        ManualPickMohoCCPoneDArray=evalin('base','ManualPickMohoCCPoneDArray');
    catch
        ManualPickMohoCCPoneDArray=[];
    end

    try
        ManualPickMohoCCPCrossSectionArray=evalin('base','ManualPickMohoCCPCrossSectionArray');
    catch
        ManualPickMohoCCPCrossSectionArray=[];
    end
    
    % Watch out for earlier versions which didn't have the on/off flag
    a = size(ManualPickMohoStationStackCell);
    if a(2) == 5
        ManualPickMohoStationStackCellTmp = evalin('base','ManualPickMohoStationStackCell');
        ManualPickMohoStationStackCell = cell(a(1), 6);
        for idx=1:a(1)
            ManualPickMohoStationStackCell{idx,1} = ManualPickMohoStationStackCellTmp{idx,1};
            ManualPickMohoStationStackCell{idx,2} = ManualPickMohoStationStackCellTmp{idx,2};
            ManualPickMohoStationStackCell{idx,3} = ManualPickMohoStationStackCellTmp{idx,3};
            ManualPickMohoStationStackCell{idx,4} = ManualPickMohoStationStackCellTmp{idx,4};
            ManualPickMohoStationStackCell{idx,5} = ManualPickMohoStationStackCellTmp{idx,5};
            ManualPickMohoStationStackCell{idx,6} = 1;
        end
        clear ManualPickMohoStationStackCellTmp
    end
    a = size(ManualPickMohoRFCrossSectionArray);
    if a(2) == 3
        ManualPickMohoRFCrossSectionArrayTmp = ManualPickMohoRFCrossSectionArray;
        ManualPickMohoRFCrossSectionArray = zeros(a(1), 4);
        for idx=1:a(1)
            ManualPickMohoRFCrossSectionArray(idx,1) = ManualPickMohoRFCrossSectionArrayTmp(idx,1);
            ManualPickMohoRFCrossSectionArray(idx,2) = ManualPickMohoRFCrossSectionArrayTmp(idx,2);
            ManualPickMohoRFCrossSectionArray(idx,3) = ManualPickMohoRFCrossSectionArrayTmp(idx,3);
            ManualPickMohoRFCrossSectionArray(idx,4) = 1;
        end
        clear ManualPickMohoRFCrossSectionArrayTmp
    end
    a = size(ManualPickMohoRayCrossSectionArray);
    if a(2) == 3
        ManualPickMohoRayCrossSectionArrayTmp = ManualPickMohoRayCrossSectionArray;
        ManualPickMohoRayCrossSectionArray = zeros(a(1), 4);
        for idx=1:a(1)
            ManualPickMohoRayCrossSectionArray(idx,1) = ManualPickMohoRayCrossSectionArrayTmp(idx,1);
            ManualPickMohoRayCrossSectionArray(idx,2) = ManualPickMohoRayCrossSectionArrayTmp(idx,2);
            ManualPickMohoRayCrossSectionArray(idx,3) = ManualPickMohoRayCrossSectionArrayTmp(idx,3);
            ManualPickMohoRayCrossSectionArray(idx,4) = 1;
        end
        clear ManualPickMohoRayCrossSectionArrayTmp
    end
    a = size(ManualPickMohoCCPoneDArray);
    if a(2) == 3
        ManualPickMohoCCPoneDArrayTmp = ManualPickMohoCCPoneDArray;
        ManualPickMohoCCPoneDArray = zeros(a(1), 4);
        for idx=1:a(1)
            ManualPickMohoCCPoneDArray(idx,1) = ManualPickMohoCCPoneDArrayTmp(idx,1);
            ManualPickMohoCCPoneDArray(idx,2) = ManualPickMohoCCPoneDArrayTmp(idx,2);
            ManualPickMohoCCPoneDArray(idx,3) = ManualPickMohoCCPoneDArrayTmp(idx,3);
            ManualPickMohoCCPoneDArray(idx,4) = 1;
        end
        clear ManualPickMohoCCPoneDArrayTmp
    end
    a = size(ManualPickMohoCCPCrossSectionArray);
    if a(2) == 3
        ManualPickMohoCCPCrossSectionArrayTmp = ManualPickMohoCCPCrossSectionArray;
        ManualPickMohoCCPCrossSectionArray = zeros(a(1), 4);
        for idx=1:a(1)
            ManualPickMohoCCPCrossSectionArray(idx,1) = ManualPickMohoCCPCrossSectionArrayTmp(idx,1);
            ManualPickMohoCCPCrossSectionArray(idx,2) = ManualPickMohoCCPCrossSectionArrayTmp(idx,2);
            ManualPickMohoCCPCrossSectionArray(idx,3) = ManualPickMohoCCPCrossSectionArrayTmp(idx,3);
            ManualPickMohoCCPCrossSectionArray(idx,4) = 1;
        end
        clear ManualPickMohoCCPCrossSectionArrayTmp
    end
    
    % StationStackCell is different - it is
    % ManualPickMohoRFCrossSectionArray{istation, column}
    % columns, 1 = station name, 2 = longitude, 3 = latitude, 4 =
    % thickness, 5 = amplitude, 6 = 1 or 0 for active or not
    
    % Others are matrices of
    % (nstation, 4)
    % four columns are longitude, latitude, thickness, on/off

    % Need to combine all picks into a table with 5 elements - 
    % lon, lat, thick, method/station, on/off
    % Kick out zeros and picks outside the polygon!
    
    nPicksTotal = length(ManualPickMohoCCPCrossSectionArray) + length(ManualPickMohoCCPoneDArray) + length(ManualPickMohoRayCrossSectionArray) + ...
        length(ManualPickMohoRFCrossSectionArray) + length(ManualPickMohoStationStackCell);
    PicksLongitudes = cell(1,nPicksTotal);
    PicksLatitudes = cell(1,nPicksTotal);
    PicksThickness = cell(1,nPicksTotal);
    PicksMethod = cell(1,nPicksTotal);
    PicksOnOff = cell(1,nPicksTotal);
    
    jdx = 1;
    for idx=1:length(ManualPickMohoStationStackCell)
        PicksLongitudes{jdx} = ManualPickMohoStationStackCell{idx, 2};
        PicksLatitudes{jdx} = ManualPickMohoStationStackCell{idx, 3};
        PicksThickness{jdx} = ManualPickMohoStationStackCell{idx, 4};
        PicksMethod{jdx} = ManualPickMohoStationStackCell{idx, 1};
        if ManualPickMohoStationStackCell{idx, 6} == 1
            PicksOnOff{jdx} = true;
        else
            PicksOnOff{jdx} = false;
        end
        jdx = jdx+1;
    end
    for idx=1:length(ManualPickMohoRFCrossSectionArray)
        PicksLongitudes{jdx} = ManualPickMohoRFCrossSectionArray(idx, 1);
        PicksLatitudes{jdx} = ManualPickMohoRFCrossSectionArray(idx, 2);
        PicksThickness{jdx} = ManualPickMohoRFCrossSectionArray(idx, 3);
        PicksMethod{jdx} = 'RF cross section';
        if ManualPickMohoRFCrossSectionArray(idx,4) == 1
            PicksOnOff{jdx} = true;
        else
            PicksOnOff{jdx} = false;
        end
        jdx = jdx+1;
    end
    for idx=1:length(ManualPickMohoRayCrossSectionArray)
        PicksLongitudes{jdx} = ManualPickMohoRayCrossSectionArray(idx, 1);
        PicksLatitudes{jdx} = ManualPickMohoRayCrossSectionArray(idx, 2);
        PicksThickness{jdx} = ManualPickMohoRayCrossSectionArray(idx, 3);
        PicksMethod{jdx} = '2D CCP cross section';
        if ManualPickMohoRayCrossSectionArray(idx,4) == 1
            PicksOnOff{jdx} = true;
        else
            PicksOnOff{jdx} = false;
        end

        jdx = jdx+1;
    end
    for idx=1:length(ManualPickMohoCCPoneDArray)
        PicksLongitudes{jdx} = ManualPickMohoCCPoneDArray(idx, 1);
        PicksLatitudes{jdx} = ManualPickMohoCCPoneDArray(idx, 2);
        PicksThickness{jdx} = ManualPickMohoCCPoneDArray(idx, 3);
        PicksMethod{jdx} = '1D depth profile';
        if ManualPickMohoCCPoneDArray(idx,4) == 1
            PicksOnOff{jdx} = true;
        else
            PicksOnOff{jdx} = false;
        end       
        jdx = jdx+1;
    end
    for idx=1:length(ManualPickMohoCCPCrossSectionArray)
        PicksLongitudes{jdx} = ManualPickMohoCCPCrossSectionArray(idx, 1);
        PicksLatitudes{jdx} = ManualPickMohoCCPCrossSectionArray(idx, 2);
        PicksThickness{jdx} = ManualPickMohoCCPCrossSectionArray(idx, 3);
        PicksMethod{jdx} = 'CCP Cross Section';
        if ManualPickMohoCCPCrossSectionArray(idx,4) == 1
            PicksOnOff{jdx} = true;
        else
            PicksOnOff{jdx} = false;
        end
        jdx = jdx+1;
    end
    
    % First, kick out picks outside of the polygon
    PicksLongitudesVec = zeros(1,nPicksTotal);
    PicksLatitudesVec = zeros(1,nPicksTotal);
    for idx=1:nPicksTotal
        if ~isempty(PicksLongitudes{idx})
            PicksLongitudesVec(idx) = PicksLongitudes{idx};
            PicksLatitudesVec(idx) = PicksLatitudes{idx};
        else
            PicksLongitudesVec(idx) = 0.0;
            PicksLatitudesVec(idx) = 0.0;
        end
    end
        
    in = inpolygon(PicksLongitudesVec, PicksLatitudesVec, p_lon, p_lat);
    jdx = 0;
    for idx=1:nPicksTotal
        if in(idx) == 1 && PicksThickness{idx} ~= 0
            jdx = jdx+1;
        end
    end
    nPicksKept = jdx;
    PicksLongitudesClean = cell(1,nPicksKept);
    PicksLatitudesClean = cell(1,nPicksKept);
    PicksThicknessClean = cell(1,nPicksKept);
    PicksMethodClean = cell(1,nPicksKept);
    PicksOnOffClean = cell(1,nPicksKept);
    jdx=1;
    for idx=1:nPicksTotal
        if in(idx) == 1 && PicksThickness{idx} ~= 0
            PicksLongitudesClean{jdx} = PicksLongitudes{idx};
            PicksLatitudesClean{jdx} = PicksLatitudes{idx};
            PicksThicknessClean{jdx} = PicksThickness{idx};
            PicksMethodClean{jdx} = PicksMethod{idx};
            PicksOnOffClean{jdx} = PicksOnOff{idx};
            jdx = jdx+1;
        end
    end
    
    
    figHdls = figure('Name','Please select picks to keep','Tag','purge_by_polygon_table_figure');
    figPos = get(figHdls,'Position');
    
    % uitable...
    % Each element in data is a cell array
    tableHdls = uitable('Parent',figHdls,'Data',[PicksLongitudesClean', PicksLatitudesClean', PicksThicknessClean', PicksMethodClean', PicksOnOffClean'],...
        'ColumnName',{'Longitude','Latitude','Thickness','Method','Active'},...
        'ColumnEditable',[false, false, false, false, true],...
        'Units','Normalized','Position',[0.05 0.05 0.8 0.9],...
        'Tag','purge_by_polygon_table');

    pbHdls = uicontrol('Parent',figHdls,'Style','PushButton','String','OK','Units','Normalized',...
        'Position',[0.85 0.05 0.15 0.1],'FontSize',12,...
        'Callback',@purge_by_table_execute_callback);

    selectAllPbHandles = uicontrol('Parent',figHdls,'Style','Pushbutton','String','Select All','Units','Normalized',...
        'Position',[0.85 0.15 0.15 0.1],'FontSize',12,...
        'Callback',@purge_by_table_turn_on_all_callback);

    selectNonePbHandles = uicontrol('Parent',figHdls,'Style','Pushbutton','String','Select None','Units','Normalized',...
        'Position',[0.85 0.25 0.15 0.1],'FontSize',12,...
        'Callback',@purge_by_table_turn_off_all_callback);

    invertSelectionPbHandles = uicontrol('Parent',figHdls,'Style','Pushbutton','String','Invert Selection','Units','Normalized',...
        'Position',[0.85 0.35 0.15 0.1],'FontSize',12,...
        'Callback',@purge_by_table_invert_selection_callback);

    sortStationsByText = uicontrol('Parent',figHdls,'Style','Text','String','Sort by:','Units','Normalized',...
        'Position',[0.85 0.49 0.1 0.1]);

    sortStationsByPopupMenu = uicontrol('Parent',figHdls,'Style','PopupMenu','Units','Normalized',...
        'Position',[0.85 0.45 0.15 0.1],'FontSize',12,'BackgroundColor',[1 1 1], ...
        'String',{'Longitude','Latitude','Thickness','Method'},'Value',1,'Tag','sortStationPopup',...
        'Callback',@purge_by_table_sort_callback);

    CancelPushbutton = uicontrol('Parent',figHdls,'Style','Pushbutton','String','Cancel','Units','Normalized',...
        'Position',[0.85 0.6 0.15 0.1],'FontSize',12,...
        'Callback',{@purge_by_table_cancel_callback});

function purge_by_table_execute_callback(cbo, eventdata, handles)
    tableHdls = findobj('Tag','purge_by_polygon_table');
	picksData = get(tableHdls,'Data');
    
    % Split the data back into its original structures, update the logic
    % flag, and save to base workspace and project file
    
    % Need to get the pick data
    try
        ManualPickMohoStationStackCell=evalin('base','ManualPickMohoStationStackCell');
    catch
        ManualPickMohoStationStackCell=[];
    end

    try
        ManualPickMohoRFCrossSectionArray=evalin('base','ManualPickMohoRFCrossSectionArray');
    catch
        ManualPickMohoRFCrossSectionArray=[];
    end
    
    try
        ManualPickMohoRayCrossSectionArray=evalin('base','ManualPickMohoRayCrossSectionArray');
    catch
        ManualPickMohoRayCrossSectionArray=[];
    end
    
    try
        ManualPickMohoCCPoneDArray=evalin('base','ManualPickMohoCCPoneDArray');
    catch
        ManualPickMohoCCPoneDArray=[];
    end

    try
        ManualPickMohoCCPCrossSectionArray=evalin('base','ManualPickMohoCCPCrossSectionArray');
    catch
        ManualPickMohoCCPCrossSectionArray=[];
    end
        
    % Initialize the station table
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    AvailableStations = unique(RecordMetadataStrings(:,2));
    for idx=1:length(AvailableStations)
        ManualPickMohoStationStackCell{idx,1} = AvailableStations{idx};
    end
    
    % Loop through the table and drop the corresponding pick back to its
    % proper type
    a=size(picksData);
    npicks = a(1);
    for ipick = 1:npicks
        if strcmp(picksData{ipick, 4},'RF cross section')
            jPickRFCrossSection = find(picksData{ipick,1}==ManualPickMohoRFCrossSectionArray(:,1));
            if picksData{ipick,5} == true
                ManualPickMohoRFCrossSectionArray(jPickRFCrossSection,4) = 1;
            else
                ManualPickMohoRFCrossSectionArray(jPickRFCrossSection,4) = 0;
            end
        elseif strcmp(picksData{ipick, 4},'2D CCP cross section')
            jPickRayCrossSection = find(picksData{ipick,1}==ManualPickMohoRayCrossSectionArray(:,1));
            if picksData{ipick,5} == true
                ManualPickMohoRayCrossSectionArray(jPickRayCrossSection,4) = 1;
            else
                ManualPickMohoRayCrossSectionArray(jPickRayCrossSection,4) = 0;
            end
        elseif strcmp(picksData{ipick, 4},'1D depth profile')
            jPickCCPOneD = find(picksData{ipick,1}==ManualPickMohoCCPoneDArray(:,1));
            if picksData{ipick,5} == true
                ManualPickMohoCCPoneDArray(jPickCCPOneD,4) = 1;
            else
                ManualPickMohoCCPoneDArray(jPickCCPOneD,4) = 0;
            end
        elseif strcmp(picksData{ipick, 4},'CCP Cross Section')
            jPickCCPCrossSection = find(picksData{ipick,1}==ManualPickMohoCCPCrossSectionArray(:,1));
            if picksData{ipick,5} == true
                ManualPickMohoCCPCrossSectionArray(jPickCCPCrossSection,4) = 1;
            else
                ManualPickMohoCCPCrossSectionArray(jPickCCPCrossSection,4) = 0;
            end
        else
            jPickStationStack = find(strcmp(picksData{ipick,4}, AvailableStations));
            if picksData{ipick,5} == true
                ManualPickMohoStationStackCell{jPickStationStack,6} = 1;
            else
                ManualPickMohoStationStackCell{jPickStationStack,6} = 0;
            end
        end
    end
    
    % Assign back to the base workspace
    assignin('base','ManualPickMohoStationStackCell',ManualPickMohoStationStackCell);
    assignin('base','ManualPickMohoCCPCrossSectionArray',ManualPickMohoCCPCrossSectionArray);
    assignin('base','ManualPickMohoCCPoneDArray',ManualPickMohoCCPoneDArray);
    assignin('base','ManualPickMohoRayCrossSectionArray',ManualPickMohoRayCrossSectionArray);
    assignin('base','ManualPickMohoRFCrossSectionArray',ManualPickMohoRFCrossSectionArray);
    
    % Save to project file
    ProjectFile = evalin('base','ProjectFile');
    ProjectDirectory = evalin('base','ProjectDirectory');
    save([ProjectDirectory ProjectFile],'ManualPickMohoStationStackCell','ManualPickMohoCCPCrossSectionArray',...
        'ManualPickMohoCCPoneDArray','ManualPickMohoRayCrossSectionArray','ManualPickMohoRFCrossSectionArray',...
        '-append');
    
    
    close(gcf);
    
function purge_by_table_sort_callback(cbo, eventdata)
    tableHdls = findobj('Tag','purge_by_polygon_table');
    popupHdls = gcbo;
    logicInfo = get(tableHdls,'Data');
    sortChoice = get(popupHdls,'Value');
    dims = size(logicInfo);
    npicks = dims(1);
    tmpStr = cell(1,npicks);
    tmpFloats = zeros(1,npicks);
    % Determine the order of indices for output
    switch sortChoice
        case 1 
            for ipick = 1:npicks
                tmpFloats(ipick) = logicInfo{ipick,1};
            end
            [~, iPickSort] = sort(tmpFloats);
        case 2
            for ipick = 1:npicks
                tmpFloats(ipick) = logicInfo{ipick,2};
            end
            [~, iPickSort] = sort(tmpFloats);
        case 3
            for ipick = 1:npicks
                tmpFloats(ipick) = logicInfo{ipick,3};
            end
            [~, iPickSort] = sort(tmpFloats);
        case 4
            for ipick = 1:npicks
                tmpStr{ipick} = logicInfo{ipick,4};
            end
            [~, iPickSort] = sort(tmpStr);
    end
    % create new cell arrays sorted in iEventSort order
    % Structure of cells for output
    picks=cell(npicks,5);
    for ipick=1:npicks
        jpick = iPickSort(ipick);
        picks{ipick,1} = logicInfo{jpick,1};
        picks{ipick,2} = logicInfo{jpick,2};
        picks{ipick,3} = logicInfo{jpick,3};
        picks{ipick,4} = logicInfo{jpick,4};
        picks{ipick,5} = logicInfo{jpick,5};
    end
    set(tableHdls,'Data',picks);
    drawnow

function purge_by_table_turn_on_all_callback(cbo, eventdata)
    tableHdls = findobj('Tag','purge_by_polygon_table');
    dataTable = get(tableHdls,'Data');
    dims = size(dataTable);
    for idx=1:dims(1)
        dataTable{idx,5} = true;
    end
    set(tableHdls,'Data',dataTable);
    drawnow

function purge_by_table_turn_off_all_callback(cbo, eventdata)
    tableHdls = findobj('Tag','purge_by_polygon_table');
    dataTable = get(tableHdls,'Data');
    dims = size(dataTable);
    for idx=1:dims(1)
        dataTable{idx,5} = false;
    end
    set(tableHdls,'Data',dataTable);
    drawnow

function purge_by_table_invert_selection_callback(cbo, eventdata)
    tableHdls = findobj('Tag','purge_by_polygon_table');
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

%% ------------------------------------------------------------------------
%  purge_by_table_cancel_callback
%  Initially not doing much, but can be used to clear variables while
%  closing ui
%  ------------------------------------------------------------------------
function purge_by_table_cancel_callback(cbo, eventdata, handles)
    close(gcf)
    
%% ------------------------------------------------------------------------
%  purge_polygon_cancel_callback
%  just cancel
%  ------------------------------------------------------------------------
function purge_polygon_cancel_callback(cbo, eventdata, handles)
    close(gcf);

%% ------------------------------------------------------------------------
%  load_initial_ascii_xyz_callback
%  uses uigetfile to have the user input a file in xyz format. 
%  drops that data into a scatteredInterpolant function so that we can look
%  up data points in visual functions
%  ------------------------------------------------------------------------
function load_initial_ascii_xyz_callback(cbo, eventdata, handles)
    global PickingStructure
    
    [filename, pathname, ~] = uigetfile('*','Please input an initial crustal thickness estimate ascii file.');
    if pathname == 0
        disp('User canceled')
        return
    end
    
    try 
        fid=fopen([pathname filename],'r');
    catch
        disp('File not found!')
        return
    end
    
    % Actually scans the file
    C = textscan(fid,'%f %f %f');
    % Remove nan and inf
    tmplon = zeros(1,length(C{1}));
    tmplat = zeros(1,length(C{2}));
    tmpthick = zeros(1,length(C{3}));
    jdx = 0;
    for idx=1:length(C{1})
        if ~isnan(C{1}(idx)) && ~isinf(C{1}(idx)) && ~isnan(C{2}(idx)) && ~isinf(C{2}(idx)) && ~isnan(C{3}(idx)) && ~isinf(C{3}(idx))
            jdx = jdx+1;
            tmplon(jdx) = C{1}(idx);
            tmplat(jdx) = C{2}(idx);
            tmpthick(jdx) = C{3}(idx);
        end
    end
    tmplon(jdx+1:length(C{1})) = [];
    tmplat(jdx+1:length(C{1})) = [];
    tmpthick(jdx+1:length(C{1})) = [];
    % Drop to a function
    F = scatteredInterpolant(tmplon', tmplat', tmpthick');
    F.Method = 'natural';
    F.ExtrapolationMethod = 'nearest';
    PickingStructure.Background = true;
    PickingStructure.BackgroundFunction = F;

%% ------------------------------------------------------------------------
%  load_initial_scatteredInterpolant_callback
%  uses uigetfile to have the user input a file in mat format. Assumes the
%  matfile contains a variable called MohoFunction
%  ------------------------------------------------------------------------
function load_initial_scatteredInterpolant_callback(cbo, eventdata, handles)
    global PickingStructure
    
    [filename, pathname, ~] = uigetfile('*.mat','Please input an initial crustal thickness estimate mat file.');
    if pathname == 0
        disp('User canceled')
        return
    end
    
    try
        load([pathname filename])
    catch
        disp('File not found!')
        return
    end
    
    % Checks that the mat file loaded a variable called "MohoFunction"
    if exist('MohoFunction','var')
        % Puts the function into the global structure
        PickingStructure.Background = true;
        PickingStructure.BackgroundFunction = MohoFunction;    
    else
        disp('MohoFunction not found in .mat file')
        return
    end
     
%% ------------------------------------------------------------------------
% close_moho_manual_pick_gui
% Just closes the gui
% -------------------------------------------------------------------------
function close_moho_manual_pick_gui(cbo, eventdata, handles)
    close(gcf)

function setstationnames(source, callbackdata)
    if source.Value == 1
        assignin('base','PlotStationNames','On');
    else
        assginin('base','PlotStationNames','Off');
    end
    
function setprofilexbin(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','xbin',val);

function setprofileybin(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','ybin',val);
    
function cancel_new_view(src,evt,hdls)
    close(hdls)

function setprofilemindepth(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','DepthMin',val);

function setprofilemaxdepth(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','DepthMax',val);

function setprofilewidth(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','ProfileWidth',val);

function setprofilegain(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','ProfileGain',val);

function setprofiletype(source, callbackdata)
    val=source.Value;
    opts = source.String;
    assignin('base','ProfileType',opts{val});

function setprofilemincolor(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','ColorMin',val);

function setprofilemaxcolor(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','ColorMax',val);

function setprofiledotsize(source, callbackdata)
    val = sscanf(source.String,'%f');
    assignin('base','DotSize',val);
    
