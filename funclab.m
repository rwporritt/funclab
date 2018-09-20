function funclab
%FUNCLAB Start the FuncLab GUI
%   FUNCLAB initiates the FuncLab GUI to begin or load a project.  The
%   user is able to run all of the FuncLab commands from this interface.

%   Author: Kevin C. Eagar
%   Date Created: 01/02/2008
%   Updated: 11/12/2011
%   Updated: 10/02/2012 (MJF)(included check for newer matlab versions - read statement changed)
%   Updated: 11/19/2013 RWP - added options for colormaps in pref
%   Updated: 07/18/2014 Rob Porritt - updated to reduce reliance on
%   mapping toolbox, added capabilities to fetch data via irisFetch.m,
%   added capabilities to compute new PRF on the fly with processRFmatlab
%   from Iain Bailey, add capabilities to compute empirical source for an
%   array, added option to convert to depth with assumed 1D velocity
%   models, and allowed viewing of images in depth space rather than time.
%   Updated: 06/23/2016 Rob Porritt - see updates below. There's been
%   a long sequence between my initial updates and this version. Key
%   updates are noted with version changes. This note is for version 1.7.8
%   Updated: 10/19/2016 Rob Porritt - Added RF cross section tools under the view menu.
%   Update: 11/04/2016 Rob Porritt. Added new addon to manually pick a moho
%   Update: 06/05/2016 Rob Porritt. Added option to remove picks from moho
%   manual pick addon. Fixed H.figure return error in fl_traceedit_gui.m
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% GUI initiation
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

% TODO:
% irisFetch Callback and populate ui             WORKS!
% fetch new data calback with ui                 WORKS!
% map to depth                                   WORKS!
% adjust map background (simplify as I don't want to distribute a 3gb
% program just for coasts/topo!)                 WORKS - m_map!
% Adjust available color tables with cptcmap     WORKS!
% Put DNA13 in the TOMOMODELS dir                WORKS!
% Add-on to plot cross sections                  WORKS!
% Add select/de-select all on station/event selection tables    DONE
% Cross sections add vp/vs along section and crustal thickness along
% section? - WORKS/ish - see RF Cross sections
% Error bars / distribution for stacks in 1D plot
% Add error messages if some metadata is missing   DONE
% Be able to enlarge the map to select Stations    DONE
% Compute the RFs from existing waveform data      DONE
% Update the Manual
% Make tutorial
% SAVE button for HK stacking complete!                  DONE
% Add in trace edit export ray parameter and backazimuth   DONE
% Added in the compute menu an option to set the P ray parameter fresh. Fixes an inconsistency in ray parameter definition. DONE!

% Add a select by sub-region to the station selection app within the new project via fetch. Allow the user
% to click N points to define a polygon then set the stations within the
% polygon to on and those outside it to off         DONE
% Requires image processing toolbox?

% Trace editing gui:
%   Sort by pull down                               DONE
% Trace editing:
%   Option to turn off dead traces                  Done
%   Option to use only the RMS fit to turn off traces  DONE
%   Option for auto trace editing by coherence and variance reduction DONE
%   Option to use non-RF components                DONE
%   Avoid color fill on wrong side                 DONE

% Add on:
%export stacks by rayparameter and back azimuth     DONE
% Visualizer to make 1D, 2D and 3D views            DONE
% GYPSUM 3D global model included                   DONE

% CCP/GCCP
%   Seems to fail on large datasets/slow computers.
%   Parameters do not seem to stick between the various buttons during the work flow
%   Version 1.7.4 includes a new CCP/GCCP gui to maintain geometry more intuitively
%   Considering adding app to import arbitrary CCP mesh; either a in-house tool for interactive
%   creation or import from some third party app.

% To do:
%   Manual moho picking from ray diagram - DONE
%   Ray cross sections - DONE
%      Rather than the 3D view, this would act as a 2D CCP Stack image. We
%      can have the user enter the geometry, then go to the ray info and
%      stack "on the fly" into the 2D view
%   CCP Adaptive meshing
%     Would like to allow either a mesh which adapts to the data or has
%     more fine user control. This is motivated by a project in Japan where
%     making a simple box around the islands would heavily oversample the
%     sea between japan and mainland eurasia
%   Subsetting - DONE
%     Pull down menu to create new subsets of the project. Ideally these
%     subsets only need indices of records in the main project and a few
%     parameters. Goal here is you can easily slice up your data set and
%     then run the rest of the funclab tools on the sliced subset.
%     Intuitively, this should be its own top level menu item. Initially in
%     the project there is only the "Create new" and "Base" options, but
%     each time the user adds a new subset, we add a choice to this menu.
%     However, as this may not be possible, an alternative is to create a
%     popup menu in the main gui   -- DONE!
%  Fix Java path adding for IRIS WS and matTaup


% For version 1.8.0
% Versions 1.7.x have been pretty substantial, so here'll we'll increment
% the second number
% Note that this version is being tested on MACOSX and Matlab 2016b
% Add a main menu for citations
% Add dilating CCP code from Jon Delph
% Version 1.8.1:
%   Found bug in trace editing when sorting. This related to how the data
%   is passed around within that function. Fixed in this version
%   moho manual picking adjusted to allow proper handling of added stations
%   after the GUI has already been run.
% Version 1.8.2: MSM found an error when downloading BH1, BH2, BHZ
% restricted data. RWP updated to make encrypted info sticky and properly
% do rotation assuming BH1 is north.

%--------------------------------------------------------------------------
% Setup dimensions of the GUI
%--------------------------------------------------------------------------
%Version = 'FuncLab 1.5.3';  %11/12/2011: UPDATED VERSION NUMBER FROM 1.5.2 TO 1.5.3
%Version = 'FuncLab 1.5.4';  % 10/02/2012: UPDATED VERSION NUMBER FROM 1.5.3 TO 1.5.4
%Version = 'FuncLab 1.5.5'; % 11/19/2013: UPDATED VERSION NUMBER FROM 1.5.4 to 1.5.5
%Version = 'Funclab 1.6.0'; % 7/18/2014
%Version = 'Funclab 1.7.0'; % Oct 22, 2014 - updated to work with matlab R2014b
%Version = 'Funclab1.7.2'; % April 2015 - updated for visualizer add on and integration of cptcmap
%Version = 'Funclab1.7.3'; % May 1st, 2015
%Version = 'Funclab1.7.4'; % May 2nd, 2015 - finished CCPV2 for beta release. Parallel computing not implemented. IRIS Web services jar updated. Matlab classpath.txt replaced with javaclasspath
%Version = 'Funclab1.7.5'; % May 7th, 2015 - Depth mapping and 3D ray diagrams added. New RFs can now be computed fully within funclab. irisFetch project creation now allows user to click through a polygon to turn on those stations within the polygon. Plus, bug fixes.
%Version = 'Funclab1.7.6'; %May 12th, 2015 - Added options to sort within the trace editing gui
%Version = 'Funclab1.7.7'; %June 26th, 2015 - subsetting and various other new tools
%Version = 'Funclab1.7.8'; % June 23rd, 2016 - Allowed trace editing by raw .r, .t, or .z waveforms and fixed trace editing error that sometimes fills the wrong side of the wiggle.
%Version = 'Funclab1.7.9'; % October 19th, 2016 - New view tools to view cross sections of groups of receiver functions either in the depth or time domain
%Version = 'Funclab1.7.10'; % November 4th, 2016. New addon to allower user to manually pick the moho
%Version = 'Funclab1.8.0'; % December 26th, 2016. Addition of citations menu and dilating CCP addon
%Version = 'Funclab1.8.1'; % October 24th, 2017. Fixed bug when sorting trace editing and in moho manual pick
Version = 'Funclab1.8.2'; % September 19th, 2018. Fixed downloading bugs and updated NWUS mod. Also found fl_hann was missing from utilities in version 1.8.1
MainPos = [0 0 165 55];
WelcomePos1 = [0 40 MainPos(3) 3];
WelcomePos2 = [5 30 MainPos(3) 1.5];
WelcomePos3 = [5 25 MainPos(3) 1.5];
WelcomePos4 = [5 20 MainPos(3) 1.5];
StartButtonPos = [MainPos(3)/2-15 2 30 4];
GetCoordsButtonPos = [5 40 (MainPos(3)-10)/4 3];
NewFetchStationPanelPosition = [4 27 (MainPos(3)-10)/4+2 17];
NewFetchEventPanelPosition = [4 8 (MainPos(3)-10)/2.2 19];
NewFetchTracePanelPosition = [NewFetchStationPanelPosition(1) + NewFetchStationPanelPosition(3) + 1 NewFetchStationPanelPosition(2) NewFetchStationPanelPosition(3)*1.4 NewFetchStationPanelPosition(4)];
NewFetchRFProcessingPanelPosition = [NewFetchTracePanelPosition(1)+NewFetchTracePanelPosition(3)+1 NewFetchEventPanelPosition(2) MainPos(3)-(NewFetchTracePanelPosition(1)+NewFetchTracePanelPosition(3)+1)-1 36];
NewFetchEncryptedPanelPosition = [NewFetchRFProcessingPanelPosition(1) 44 NewFetchRFProcessingPanelPosition(3) 5];
NewTitlePos = [0 51 MainPos(3) 2];
NewProjTextPos = [5 48 MainPos(3)-10 1];
NewProjPos = [5 45 MainPos(3)-10 2];
NewFetchProjPos = [5 45 (MainPos(3)-10)/2 2 ];
NewDirTextPos = [5 43 MainPos(3)-10 1];
NewBrowsePos = [5 0 25 2];
NewPathPos = [NewBrowsePos(3)+6 0 MainPos(3)-NewBrowsePos(3)-11 2];
DataPos = [1 2.5 MainPos(3)-2 52];
PopupPos = [2 52.5 50 1.5];
TablesPos = [2 5.5 50 46.5];
TableInfoPos = [2 3 50 2];
RecordsTitlePos = [52 52.5 40 1.2];
RecordsPos = [52 5.5 40 46.5];
RecordInfoPos = [52 3 40 2];
InfoTitlePos = [92 52.5 71 1.2];
InfoPos = [92 5.5 71 46.5];
MessagePos = [1 0.5 MainPos(3)-2 1.5];
EditColor = [.7 .7 .7];
% Accent colors for USC colors ^_^
AccentColor = [.6 0 0];
AccentColor2 = [1.0000 0.7961 0];

%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
MainGui = dialog('Name',Version,'Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Color',[1 1 1],'Position',MainPos,'CreateFcn',{@movegui_kce,'center'});
BackColor = get(MainGui,'Color');
MFile = uimenu(MainGui,'Label','File');
uimenu(MFile,'Label','About FuncLab','Tag','about_m','Enable','on','Callback',{@about_Callback});
uimenu(MFile,'Label','New Project from existing RFs','Tag','new_m','Separator','on','Enable','on','Callback',{@new_project_window_Callback});
uimenu(MFile,'Label','New Project via irisFetch','Tag','new_fetch_m','Enable','on','Callback',{@new_project_fetch_window_Callback});
uimenu(MFile,'Label','Load Project','Tag','load_m','Enable','on','Callback',{@load_project_Callback});
uimenu(MFile,'Label','Add Data','Tag','add_m','Enable','off','Callback',{@add_data_Callback});
% uimenu(MFile,'Label','Fetch New Data','Tag','add_m','Enable','off','Callback',{@fetch_new_data_Callback});
uimenu(MFile,'Label','FuncLab Preferences','Tag','param_m','Separator','on','Enable','on','Callback',{@fl_pref_Callback});
uimenu(MFile,'Label','Log File','Tag','log_m','Enable','off','Callback',{@log_Callback});
uimenu(MFile,'Label','Exit FuncLab','Tag','close_m','Separator','on','Callback',{@close_project_Callback});
MCompute = uimenu(MainGui,'Label','Compute');
uimenu(MCompute,'Label','Compute new RFs','tag','compute_new_rfs_m','Enable','on','Callback',{@Compute_new_RFs_Callback});
uimenu(MCompute,'Label','Recompute ray parameters','tag','recompute_rayp_m','Enable','off','Callback',{@compute_rayp_Callback});
% uimenu(MCompute,'Label','Empirical Source Function','Tag','esf_m','Enable','off','Callback',{@esf_Callback});
uimenu(MCompute,'Label','PRF to depth','Tag','PRF_to_depth_m','Enable','off','Callback',{@PRF_to_depth_Callback});
MEditing = uimenu(MainGui,'Label','Editing');
uimenu(MEditing,'Label','Manual Trace Edit','Tag','manual_m','Enable','off','Callback',{@te_manual_Callback});
uimenu(MEditing,'Label','Auto Trace Edit - Selected','Tag','autoselect_m','Enable','off','Callback',{@te_auto_table_Callback});
uimenu(MEditing,'Label','Auto Trace Edit - ALL','Tag','autoall_m','Enable','off','Callback',{@te_auto_all_Callback});
uimenu(MEditing,'Label','Auto Trace Edit RMS only - Selected','Tag','autoselect_rms_m','Enable','off','Callback',{@te_auto_rms_table_Callback});
uimenu(MEditing,'Label','Auto Trace Edit RMS only - ALL','Tag','autoselect_rms_all_m','Enable','off','Callback',{@te_auto_rms_all_Callback});
uimenu(MEditing,'Label','Auto Trace Edit - VR and Coherence - Selected','Tag','autoselect_vr_coh_m','Enable','off','Callback',{@te_auto_vr_coh_table_Callback});
uimenu(MEditing,'Label','Auto Trace Edit - VR and Coherence - ALL','Tag','autoselect_vr_coh_all_m','Enable','off','Callback',{@te_auto_vr_coh_all_Callback});
uimenu(MEditing,'Label','Turn off dead traces','Tag','off_dead_m','Enable','off','Callback',{@te_turn_off_dead_traces_Callback});
uimenu(MEditing,'Label','Trace Edit Import','Tag','im_te_m','Enable','off','Callback',{@im_te_Callback});
uimenu(MEditing,'Label','Trace Editing Preferences','Tag','tepref_m','Separator','on','Enable','off','Callback',{@te_pref_Callback});
MView = uimenu(MainGui,'Label','View');
uimenu(MView,'Label','Seismograms','Tag','seis_m','Enable','off','Callback',{@view_record_Callback});
uimenu(MView,'Label','Record Section','Tag','record_m','Enable','off','Callback',{@view_record_section_Callback});
uimenu(MView,'Label','Stacked Records','Tag','stacked_record_m','Enable','off','Callback',{@view_stacked_records_Callback});
uimenu(MView,'Label','RF Moveout Record Section','Tag','moveout_m','Enable','off','Separator','on','Callback',{@view_moveout_Callback});
uimenu(MView,'Label','RF Moveout Image','Tag','moveout_image_m','Enable','off','Callback',{@view_moveout_image_Callback});
%uimenu(MView,'Label','RF OriginTime Record Section','Tag','origintime_wiggles_m','Enable','off','Callback',{@view_origintime_wiggles_Callback});
%uimenu(MView,'Label','RF OriginTime Image','Tag','origintime_image_m','Enable','off','Callback',{@view_origintime_image_Callback});
uimenu(MView,'Label','RF Backazimuth Record Section','Tag','baz_m','Enable','off','Callback',{@view_baz_Callback});
uimenu(MView,'Label','RF Backazimuth Image','Tag','baz_image_m','Enable','off','Callback',{@view_baz_image_Callback});
uimenu(MView,'Label','RF Time Domain Cross Section','Tag','rf_cross_section_time_m','Enable','off','Separator','on','Callback',{@view_rf_cross_section_time_Callback});
uimenu(MView,'Label','RF Depth Stack Cross Section','Tag','rf_cross_section_depth_stack_m','Enable','off','Callback',{@view_rf_cross_section_depth_stack_Callback});
uimenu(MView,'Label','RF Depth Cross Section','Tag','rf_cross_section_depth_m','Enable','off','Callback',{@view_rf_cross_section_depth_Callback});
uimenu(MView,'Label','2D CCP Cross Section','Tag','rf_cross_section_2d_ccp_m','Enable','off','Callback',{@view_rf_cross_section_2d_ccp_Callback});
uimenu(MView,'Label','RF Ray Diagram','Tag','ray_diagram_m','Enable','off','Callback',{@view_ray_diagram_Callback});
uimenu(MView,'Label','RF Ray Diagram - all','Tag','ray_diagram_all_m','Enable','off','Callback',{@view_ray_diagram_all_Callback});
uimenu(MView,'Label','Dataset Statistics','Tag','datastats_m','Enable','off','Separator','on','Callback',{@datastats_Callback});
uimenu(MView,'Label','Station Map','Tag','stamap_m','Enable','off','Callback',{@view_station_map_Callback});
uimenu(MView,'Label','Global Event Map','Tag','evtmap_m','Enable','off','Callback',{@view_event_map_Callback});
uimenu(MView,'Label','Current Set Ray Parameter/Backazimuth Diagram','Tag','datadiagram_m','Enable','off','Callback',{@view_data_coverage_current_set_Callback});
uimenu(MView,'Label','Base Set Ray Parameter/Backazimuth Diagram','Tag','datadiagram_m','Enable','off','Callback',{@view_data_coverage_Callback});
MSubset = uimenu(MainGui,'Label','Subsets');
uimenu(MSubset,'Label','Create New Subset','Tag','create_new_subset_m','Enable','off','Separator','off','Callback',{@create_new_subset_Callback});
uimenu(MSubset,'Label','Delete Subset','Tag','delete_subset_m','Enable','off','Separator','off','Callback',{@delete_subset_Callback});
uimenu(MSubset,'Label','Choose Subset','Tag','choose_subset_m','Enable','off','Separator','off','Callback',{@choose_subset_Callback});
MExport = uimenu(MainGui,'Label','Export');
uimenu(MExport,'Label','Station List','Tag','ex_stations_m','Enable','off','Callback',{@ex_stations_Callback});
uimenu(MExport,'Label','Event List','Tag','ex_events_m','Enable','off','Callback',{@ex_events_Callback});
uimenu(MExport,'Label','Trace Edits','Tag','ex_te_m','Enable','off','Callback',{@ex_te_Callback});
uimenu(MExport,'Label','Receiver Functions','Tag','ex_rfs_m','Enable','off','Callback',{@ex_rfs_Callback});
uimenu(MExport,'Label','H-k results','Tag','ex_hk_res_m','Enable','off','Callback',{@ex_hk_res_Callback});
MCitation = uimenu(MainGui,'Label','Citations');
uimenu(MCitation,'Label','Funclab general','Tag','citation_funclab_m','Enable','on','Callback',{@citation_funclab_Callback});
uimenu(MCitation,'Label','Receiver Functions','Tag','citation_rf_m','Enable','on','Callback',{@citation_rf_Callback});
uimenu(MCitation,'Label','H-k stacking','Tag','citation_hk_m','Enable','on','Callback',{@citation_hk_Callback});
uimenu(MCitation,'Label','CCP stacking','Tag','citation_ccp_m','Enable','on','Callback',{@citation_ccp_Callback});
uimenu(MCitation,'Label','Other','Tag','citation_other_m','Enable','on','Separator','on','Callback',{@citation_other_Callback});

%--------------------------------------------------------------------------
% Welcome Message
%--------------------------------------------------------------------------
uicontrol ('Parent',MainGui,'Style','text','Units','characters','Tag','welcome1_t','String','Welcome to FuncLab!',...
    'Position',WelcomePos1,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.9,'FontWeight','bold',...
    'FontAngle','italic','BackgroundColor',BackColor,'HorizontalAlignment','center','Visible','on');
uicontrol ('Parent',MainGui,'Style','text','Units','characters','Tag','welcome2_t','String',...
    'Start a new project (File > New Project from existing RFs) or load an existing project (File > Load Project)',...
    'Position',WelcomePos2,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.8,'FontWeight','bold',...
    'FontAngle','italic','BackgroundColor',BackColor,'HorizontalAlignment','left','Visible','on');
uicontrol ('Parent',MainGui,'Style','text','Units','characters','Tag','welcome3_t','String',...
    'To setup a project and obtain data from webservices, use File > New Project via irisFetch',...
    'Position',WelcomePos3,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.8,'FontWeight','bold',...
    'FontAngle','italic','BackgroundColor',BackColor,'HorizontalAlignment','left','Visible','on');
uicontrol ('Parent',MainGui,'Style','text','Units','characters','Tag','welcome4_t','String',...
    'To create a new project and compute RFs from raw waveforms, use Compute > Compute new RFs',...
    'Position',WelcomePos4,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.8,'FontWeight','bold',...
    'FontAngle','italic','BackgroundColor',BackColor,'HorizontalAlignment','left','Visible','on');



%--------------------------------------------------------------------------
% This is a code snippet to catch any installed add-on packages to be added
% to the FuncLab Add-on menu.  Any add-ons should be added IF the
% directories that contain the functions are added to the search path.
% Otherwise, there will be no add-ons.
%--------------------------------------------------------------------------
MAddons = uimenu(MainGui,'Label','Add-ons');
%[FuncLabPath,junk,junk,junk] = fileparts(mfilename('fullpath'));
%added to test for version 10/02/2012 MJF
v = version;
if str2double(v(1:4)) < 7.12
    [FuncLabPath,junk,junk,junk] = fileparts(mfilename('fullpath'));
else
    [FuncLabPath,junk,junk] = fileparts(mfilename('fullpath'));
end

AddonPaths = dir([FuncLabPath '/addons']);
AddonNames = sortrows({AddonPaths(3:end).name}');
AddonNames(strmatch('.DS_Store',AddonNames,'exact')) = []; % THIS IS A FIX FOR MAC SYSTEMS
clear AddonPaths
if isempty(AddonNames)
    uimenu(MAddons,'Label','No Current Add-ons','Enable','off');
    clear AddonNames
else
    for n = 1:length(AddonNames)
        eval(['init_' AddonNames{n}])
    end
end
%--------------------------------------------------------------------------
% uicontrol features below are originally hidden. When a new project is
% started, these are flipped on while the welcome screen is flipped off
%--------------------------------------------------------------------------
% New project setup
%--------------------------------------------------------------------------
uicontrol ('Parent',MainGui,'Style','text','Units','characters','Tag','new_title_t','String','New FuncLab Project Setup',...
    'Position',NewTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.9,'FontWeight','bold',...
    'BackgroundColor',BackColor,'HorizontalAlignment','center','Visible','off');
InfoText = 'Please type the full pathname for your NEW project top directory. (NOTE: This directory must not already exist.)';
uicontrol ('Parent',MainGui,'Style','text','Units','characters','Tag','new_projdir_t','String',InfoText,...
    'BackgroundColor',BackColor,'Position',NewProjTextPos,'FontUnits','normalized','FontSize',0.9,'HorizontalAlignment','left','Visible','off');
uicontrol ('Parent',MainGui,'Style','edit','Units','characters','Tag','new_projdir_e','String',pwd,...
    'Position',NewProjPos,'BackgroundColor',EditColor,'FontUnits','normalized','HorizontalAlignment','left','Visible','off');
uicontrol ('Parent',MainGui,'Style','text','Units','characters','Tag','new_adddata_t','String','Please select up to 10 datasets to add to this new project.',...
    'BackgroundColor',BackColor,'Position',NewDirTextPos,'FontUnits','normalized','FontSize',0.9,'HorizontalAlignment','left','Visible','off');
for n = 1:10
    Range = MainPos(4)-20;
    Inc = Range/10;
    YPos = MainPos(4) - 11 - (n*Inc);
    NewBrowsePos(2) = YPos;
    NewPathPos(2) = YPos;
    uicontrol ('Parent',MainGui,'Style','pushbutton','Units','characters','Tag',['new_browse' sprintf('%02.0f',n) '_pb'],'String','Browse',...
        'Position',NewBrowsePos,'FontUnits','normalized','Callback',{@new_data_browse_Callback},'Visible','off');
    uicontrol ('Parent',MainGui,'Style','edit','Units','characters','Tag',['new_dataset' sprintf('%02.0f',n) '_e'],...
        'Position',NewPathPos,'BackgroundColor',EditColor,'FontUnits','normalized','HorizontalAlignment','left',...
        'Visible','off');
end
uicontrol ('Parent',MainGui,'Style','pushbutton','Units','characters','Tag','new_start_pb','String','Start',...
    'Position',StartButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.25,'FontWeight','bold',...
    'Visible','off','Callback',{@new_project_setup_Callback});

%--------------------------------------------------------------------------
% New project setup, but using irisFetch.m to obtain waveforms. These
% waveforms are rotated into RTZ or P-SV-SH as the user chooses and then
% PRFs are computed with user params
%--------------------------------------------------------------------------
uicontrol ('Parent',MainGui,'Style','text','Units','characters','Tag','new_fetch_title_t','String','New FuncLab Project Setup',...
    'Position',NewTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.9,'FontWeight','bold',...
    'BackgroundColor',BackColor,'HorizontalAlignment','center','Visible','off');
InfoText = 'Please type the full pathname for your NEW project top directory. (NOTE: This directory must not already exist.)';
uicontrol ('Parent',MainGui,'Style','text','Units','characters','Tag','new_fetch_projdir_t','String',InfoText,...
    'BackgroundColor',BackColor,'Position',NewProjTextPos,'FontUnits','normalized','FontSize',0.9,'HorizontalAlignment','left','Visible','off');
uicontrol ('Parent',MainGui,'Style','edit','Units','characters','Tag','new_fetch_projdir_e','String',pwd,...
    'Position',NewFetchProjPos,'BackgroundColor',BackColor,'FontUnits','normalized','HorizontalAlignment','left','Visible','off');

% Creates a panel to group together the station info
uipanel ('Parent',MainGui,'BorderType','etchedin','Units','characters','Tag','new_fetch_station_panel','Title','Stations info:',...
    'BackgroundColor',BackColor,'Position',NewFetchStationPanelPosition,'Visible','off');

% Button to make a map for user to drag a rectangle for study area
uicontrol ('Parent',MainGui,'Style','pushbutton','Units','characters','Tag','new_fetch_get_map_coords_pb','String','Choose station box from map',...
    'Position',GetCoordsButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.25,'FontWeight','bold',...
    'Visible','off','Callback','FL_new_fetch_get_map_coords_Callback');
% 4 edit boxes for entering lat/long limits manually
editPos = [ 8+(MainPos(3)-10)/16 37 (MainPos(3)-10)/10 3 ];
uicontrol ('Parent',MainGui,'Style','edit','Units','Characters','Tag','new_fetch_lat_max_e','String','North Latitude',...
    'BackgroundColor',BackColor,'Position',editPos,'FontUnits','normalized','HorizontalAlignment','left','Visible','off',...
    'Userdata','50.0','Callback','hdl = findobj(''Tag'',''new_fetch_lat_max_e''); val=get(hdl,''String'');set(hdl,''Userdata'',val);');
editPos = [ 9 34 (MainPos(3)-10)/10 3 ];
uicontrol ('Parent',MainGui,'Style','edit','Units','Characters','Tag','new_fetch_lon_min_e','String','West Longitude',...
    'BackgroundColor',BackColor,'Position',editPos,'FontUnits','normalized','HorizontalAlignment','left','Visible','off',...
    'Userdata','50.0','Callback','hdl = findobj(''Tag'',''new_fetch_lon_min_e''); val=get(hdl,''String'');set(hdl,''Userdata'',val);');
editPos = [ 9+(MainPos(3)-10)/10 34 (MainPos(3)-10)/10 3 ];
uicontrol ('Parent',MainGui,'Style','edit','Units','Characters','Tag','new_fetch_lon_max_e','String','East Longitude',...
    'BackgroundColor',BackColor,'Position',editPos,'FontUnits','normalized','HorizontalAlignment','left','Visible','off',...
    'Userdata','50.0','Callback','hdl = findobj(''Tag'',''new_fetch_lon_max_e''); val=get(hdl,''String'');set(hdl,''Userdata'',val);');
editPos = [ 8+(MainPos(3)-10)/16 31 (MainPos(3)-10)/10 3 ];
uicontrol ('Parent',MainGui,'Style','edit','Units','Characters','Tag','new_fetch_lat_min_e','String','South Latitude',...
    'BackgroundColor',BackColor,'Position',editPos,'FontUnits','normalized','HorizontalAlignment','left','Visible','off',...
    'Userdata','50.0','Callback','hdl = findobj(''Tag'',''new_fetch_lat_min_e''); val=get(hdl,''String'');set(hdl,''Userdata'',val);');
% A button to fetch stations
uicontrol ('Parent',MainGui,'Style','pushbutton','Units','characters','Tag','new_fetch_get_stations_pb','String','Find Stations',...
    'Position',[GetCoordsButtonPos(1) 28 GetCoordsButtonPos(3) GetCoordsButtonPos(4)],'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',...
    0.25,'FontWeight','bold','Visible','off','Callback','FL_new_fetch_get_stations_table_Callback');


% Event info
eventsPanelHandle = uipanel ('Parent',MainGui,'BorderType','etchedin','Units','characters','Tag','new_fetch_events_panel','Title','Events info:',...
    'BackgroundColor',BackColor,'Position',NewFetchEventPanelPosition,'Visible','off');
% start time:
textPosition = [NewFetchEventPanelPosition(1)+1, NewFetchEventPanelPosition(2)+NewFetchEventPanelPosition(4)*3/4, NewFetchEventPanelPosition(3)/3, GetCoordsButtonPos(4) ];
uicontrol ('Parent',MainGui,'Units','characters','Style','Text','String','Search start time:','visible','off','Position',textPosition,...
    'Tag','new_fetch_search_start_time_text','BackgroundColor',BackColor);
% popup menus for year, month, day - euro style
% tmpdate = datevec(today);
% thisyear = tmpdate(1);
% thismonth = tmpdate(2);
% thisday = tmpdate(3);
c=clock();
thisyear=c(1);
thismonth=c(2);
thisday=c(3);
popupPosition = [textPosition(1)+textPosition(3)+1, textPosition(2), textPosition(3)/1.8,textPosition(4)];
uicontrol ('Parent',MainGui,'Units','Characters','Style','Popup','Position',popupPosition,'Visible','off',...
    'String',{num2str((1976:thisyear)')},'Tag','new_fetch_start_year_pu');
popupPosition = [popupPosition(1)+popupPosition(3)+1, textPosition(2), textPosition(3)/1.8,textPosition(4)];
uicontrol ('Parent',MainGui,'Units','Characters','Style','Popup','Position',popupPosition,'Visible','off',...
    'String',{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'},'Tag','new_fetch_start_month_pu');
popupPosition = [popupPosition(1)+popupPosition(3)+1, textPosition(2), textPosition(3)/1.8,textPosition(4)];
uicontrol ('Parent',MainGui,'Units','Characters','Style','Popup','Position',popupPosition,'Visible','off',...
    'String',{num2str((1:31)')},'Tag','new_fetch_start_day_pu');


% end time:
textPosition = [textPosition(1) textPosition(2)-GetCoordsButtonPos(4) textPosition(3) textPosition(4)];
uicontrol ('Parent',MainGui,'Units','characters','Style','Text','String','Search end time:','visible','off','Position',textPosition,...
    'Tag','new_fetch_search_end_time_text','BackgroundColor',BackColor);
popupPosition = [textPosition(1)+textPosition(3)+1, textPosition(2), textPosition(3)/1.8,textPosition(4)];
nearpos_x = popupPosition(1);
uicontrol ('Parent',MainGui,'Units','Characters','Style','Popup','Position',popupPosition,'Visible','off',...
    'String',{num2str((1976:thisyear)')},'Tag','new_fetch_end_year_pu','Value',thisyear-1975);
popupPosition = [popupPosition(1)+popupPosition(3)+1, textPosition(2), textPosition(3)/1.8,textPosition(4)];
centerpos_x = popupPosition(1);
uicontrol ('Parent',MainGui,'Units','Characters','Style','Popup','Position',popupPosition,'Visible','off',...
    'String',{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'},'Tag','new_fetch_end_month_pu','Value',thismonth);
popupPosition = [popupPosition(1)+popupPosition(3)+1, textPosition(2), textPosition(3)/1.8,textPosition(4)];
farpos_x = popupPosition(1);
uicontrol ('Parent',MainGui,'Units','Characters','Style','Popup','Position',popupPosition,'Visible','off',...
    'String',{num2str((1:31)')},'Tag','new_fetch_end_day_pu','Value',thisday);

% magnitude window - following Splitlab's example, using a popup menu to
% avoid wild inputs
textPosition = [textPosition(1) textPosition(2)-GetCoordsButtonPos(4) textPosition(3) textPosition(4)];
uicontrol ('Parent',MainGui,'Units','characters','Style','Text','String','Magnitude window:','visible','off','Position',textPosition,...
    'Tag','new_fetch_search_magnitude_text','BackgroundColor',BackColor);
mag = 5.5:0.25:10;
popupPosition = [textPosition(1)+textPosition(3)+1, textPosition(2), textPosition(3)/1.8,textPosition(4)];
uicontrol ('Parent',MainGui,'Units','Characters','Style','Popup','Position',popupPosition,'Visible','off',...
    'String',{num2str(mag','%4.2f')},'Tag','new_fetch_min_mag_pu','Value',1);
textPosition2 = [centerpos_x textPosition(2) textPosition(3)/1.8 textPosition(4)];
uicontrol ('Parent', MainGui,'Units','Characters','Style','Text','String','<-->','Visible','off','Tag','new_fetch_event_mag_divider_t',...
    'Position',textPosition2,'BackgroundColor',BackColor);
popupPosition = [farpos_x, textPosition(2), textPosition(3)/1.8,textPosition(4)];
uicontrol ('Parent',MainGui,'Units','Characters','Style','Popup','Position',popupPosition,'Visible','off',...
    'String',{num2str(mag','%4.2f')},'Tag','new_fetch_max_mag_pu','Value',length(mag));


% distance window
textPosition = [textPosition(1) textPosition(2)-GetCoordsButtonPos(4) textPosition(3) textPosition(4)];
uicontrol ('Parent',MainGui,'Units','characters','Style','Text','String','Distance window (degrees):','visible','off','Position',textPosition,...
    'Tag','new_fetch_search_distance_text','BackgroundColor',BackColor);
editPosition = [nearpos_x, textPosition(2)+textPosition(4)/2, textPosition(3)/1.8,textPosition(4)/2];
uicontrol ('Parent',MainGui,'Units','Characters','Style','Edit','Position',editPosition,'Visible','off',...
    'String','30','Tag','new_fetch_min_dist_e','BackgroundColor',BackColor);
textPosition2 = [centerpos_x textPosition(2) textPosition(3)/1.8 textPosition(4)];
uicontrol ('Parent', MainGui,'Units','Characters','Style','Text','String','<-->','Visible','off','Tag','new_fetch_event_distance_divider_t',...
    'Position',textPosition2,'BackgroundColor',BackColor);
editPosition = [farpos_x, textPosition(2)+textPosition(4)/2, textPosition(3)/1.8,textPosition(4)/2];
uicontrol ('Parent',MainGui,'Units','Characters','Style','Edit','Position',editPosition,'Visible','off',...
    'String','100','Tag','new_fetch_max_dist_e','BackgroundColor',BackColor);

% Depth window
textPosition = [textPosition(1) textPosition(2)-GetCoordsButtonPos(4) textPosition(3) textPosition(4)];
uicontrol ('Parent',MainGui,'Units','characters','Style','Text','String','Depth window (km):','visible','off','Position',textPosition,...
    'Tag','new_fetch_search_depth_text','BackgroundColor',BackColor);
editPosition = [nearpos_x, textPosition(2)+textPosition(4)/2, textPosition(3)/1.8,textPosition(4)/2];
uicontrol ('Parent',MainGui,'Units','Characters','Style','Edit','Position',editPosition,'Visible','off',...
    'String','0','Tag','new_fetch_min_depth_e','BackgroundColor',BackColor);
textPosition2 = [centerpos_x textPosition(2) textPosition(3)/1.8 textPosition(4)];
uicontrol ('Parent', MainGui,'Units','Characters','Style','Text','String','<-->','Visible','off','Tag','new_fetch_event_depth_divider_t',...
    'Position',textPosition2,'BackgroundColor',BackColor);
editPosition = [farpos_x, textPosition(2)+textPosition(4)/2, textPosition(3)/1.8,textPosition(4)/2];
uicontrol ('Parent',MainGui,'Units','Characters','Style','Edit','Position',editPosition,'Visible','off',...
    'String','700','Tag','new_fetch_max_depth_e','BackgroundColor',BackColor);

% Button to go get events
eventFetchButtonPosition = [NewFetchEventPanelPosition(1)+1, NewFetchEventPanelPosition(2)+1, NewFetchEventPanelPosition(3)-2, NewFetchEventPanelPosition(4)/8];
uicontrol('Parent',MainGui,'Units','Characters','Style','PushButton','Position',eventFetchButtonPosition,...
    'Tag','new_fetch_find_events_pb','String','Find Events','ForegroundColor',AccentColor, 'FontUnits','normalized','FontSize',0.25',...
    'FontWeight','bold','Visible','off','Callback','FL_fetchEvents');

% Trace info panel
traceInfoPanel = uipanel('Parent',MainGui,'BorderType','etchedin','Units','characters','Tag','new_fetch_traces_panel','Title','Trace info:',...
    'BackgroundColor',BackColor,'Position',NewFetchTracePanelPosition,'Visible','off',...
    'UserData',{'30','Before','P','180','After','P','20','No Removal'});

% Need to know: time relative to phase for start and end
% also need sampling rate
textPos = [NewFetchTracePanelPosition(1)+1 NewFetchTracePanelPosition(2)+NewFetchTracePanelPosition(4)*0.82 10 NewFetchTracePanelPosition(4)/10];
startTimeText = uicontrol('Parent',MainGui,'Style','Text','String','Start Time:','Tag','new_fetch_traces_start_time_text',...
    'Units','Characters','Position',textPos,'Visible','Off','BackgroundColor',BackColor);
editPos = [textPos(1)+3 textPos(2)-1 textPos(3) textPos(4)];
startTimePriorSecondsEdit = uicontrol('Parent',MainGui,'Style','Edit','String','30','Units','Characters',...
    'BackgroundColor',BackColor,'Position',editPos,'Tag','new_fetch_traces_prior_seconds_edit','Visible','off',...
    'Callback','hdls=findobj(''Tag'',''new_fetch_traces_prior_seconds_edit'');v=get(hdls,''String'');outhdls = findobj(''Tag'',''new_fetch_traces_panel'');tmp=get(outhdls,''UserData'');tmp{1}=v;set(outhdls,''UserData'',tmp)');
textPos = [editPos(1)+editPos(3)+1 editPos(2)-.3 8 editPos(4)];
startTimeSecondsLabelText = uicontrol('Parent',MainGui,'Style','Text','String','seconds','Tag','new_fetch_traces_start_seconds_label',...
    'Units','Characters','Position',textPos,'Visible','Off','BackgroundColor',BackColor);
popupPos = [textPos(1)+textPos(3)+1 editPos(2) 15 textPos(4)];
startTimeBeforeOrAfterPopup = uicontrol('Parent',MainGui,'Style','PopupMenu','String',{'Before', 'After'},'Value',1,...
    'Units','Characters','Position',popupPos,'Visible','off','BackgroundColor',BackColor,'Tag','new_fetch_traces_start_before_or_after_popup',...
    'Callback','hdls=findobj(''Tag'',''new_fetch_traces_start_before_or_after_popup'');t=get(hdls,''String'');tt=get(hdls,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_traces_panel'');tmp=get(outhdls,''UserData'');tmp{2}=v;set(outhdls,''UserData'',tmp)');
popupPos = [popupPos(1)+popupPos(3)+1 editPos(2) 15 textPos(4)];
startTimePhasePopup = uicontrol('Parent',MainGui,'Style','PopupMenu','String',{'Origin', 'P','PKP','S','SKS'},'Value',2,...
    'Units','Characters','Position',popupPos,'Visible','off','BackgroundColor',BackColor,'Tag','new_fetch_traces_start_phase_popup',...
    'Callback','hdls=findobj(''Tag'',''new_fetch_traces_start_phase_popup'');t=get(hdls,''String'');tt=get(hdls,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_traces_panel'');tmp=get(outhdls,''UserData'');tmp{3}=v;set(outhdls,''UserData'',tmp)');

textPos = [NewFetchTracePanelPosition(1)+1 NewFetchTracePanelPosition(2)+NewFetchTracePanelPosition(4)*0.6 10 NewFetchTracePanelPosition(4)/10];
endTimeText = uicontrol('Parent',MainGui,'Style','Text','String','End Time:','Tag','new_fetch_traces_end_time_text',...
    'Units','Characters','Position',textPos,'Visible','Off','BackgroundColor',BackColor);
editPos = [textPos(1)+3 textPos(2)-1 textPos(3) textPos(4)];
endTimePriorSecondsEdit = uicontrol('Parent',MainGui,'Style','Edit','String','180','Units','Characters',...
    'BackgroundColor',BackColor,'Position',editPos,'Tag','new_fetch_traces_after_seconds_edit','Visible','off',...
    'Callback','hdls=findobj(''Tag'',''new_fetch_traces_after_seconds_edit'');v=get(hdls,''String'');outhdls = findobj(''Tag'',''new_fetch_traces_panel'');tmp=get(outhdls,''UserData'');tmp{4}=v;set(outhdls,''UserData'',tmp)');
textPos = [editPos(1)+editPos(3)+1 editPos(2)-.3 8 editPos(4)];
endTimeSecondsLabelText = uicontrol('Parent',MainGui,'Style','Text','String','seconds','Tag','new_fetch_traces_end_seconds_label',...
    'Units','Characters','Position',textPos,'Visible','Off','BackgroundColor',BackColor);
popupPos = [textPos(1)+textPos(3)+1 editPos(2) 15 textPos(4)];
endTimeBeforeOrAfterPopup = uicontrol('Parent',MainGui,'Style','PopupMenu','String',{'Before', 'After'},'Value',2,...
    'Units','Characters','Position',popupPos,'Visible','off','BackgroundColor',BackColor,'Tag','new_fetch_traces_end_before_or_after_popup',...
    'Callback','hdls=findobj(''Tag'',''new_fetch_traces_end_before_or_after_popup'');t=get(hdls,''String'');tt=get(hdls,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_traces_panel'');tmp=get(outhdls,''UserData'');tmp{5}=v;set(outhdls,''UserData'',tmp)');
popupPos = [popupPos(1)+popupPos(3)+1 editPos(2) 15 textPos(4)];
endTimePhasePopup = uicontrol('Parent',MainGui,'Style','PopupMenu','String',{'Origin', 'P','PKP','S','SKS'},'Value',2,...
    'Units','Characters','Position',popupPos,'Visible','off','BackgroundColor',BackColor,'Tag','new_fetch_traces_end_phase_popup',...
    'Callback','hdls=findobj(''Tag'',''new_fetch_traces_end_phase_popup'');t=get(hdls,''String'');tt=get(hdls,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_traces_panel'');tmp=get(outhdls,''UserData'');tmp{6}=v;set(outhdls,''UserData'',tmp)');

% output sampling
textPos = [NewFetchTracePanelPosition(1)+1 NewFetchTracePanelPosition(2)+NewFetchTracePanelPosition(4)*0.35 20 NewFetchTracePanelPosition(4)/9];
sampleRateText = uicontrol('Parent',MainGui,'Style','Text','String','Desired Sample Rate:','Tag','new_fetch_traces_sample_rate_text',...
    'Units','Characters','Position',textPos,'Visible','Off','BackgroundColor',BackColor);
popupPos = [textPos(1)+textPos(3)+3 textPos(2)+0.2 15 textPos(4)];
endTimeBeforeOrAfterPopup = uicontrol('Parent',MainGui,'Style','PopupMenu','String',{'1', '10', '20','40','100'},'Value',3,...
    'Units','Characters','Position',popupPos,'Visible','off','BackgroundColor',BackColor,'Tag','new_fetch_traces_sample_rate_popup',...
    'Callback','hdls=findobj(''Tag'',''new_fetch_traces_sample_rate_popup'');t=get(hdls,''String'');tt=get(hdls,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_traces_panel'');tmp=get(outhdls,''UserData'');tmp{7}=v;set(outhdls,''UserData'',tmp)');
textPos = [popupPos(1)+popupPos(3) textPos(2) 17 textPos(4)];
sampleRateLabel = uicontrol('Parent',MainGui,'Style','Text','String','Samples per second','Tag','new_fetch_traces_sample_rate_label',...
    'Units','Characters','Position',textPos,'Visible','Off','BackgroundColor',BackColor);
% simple push button to view to command line for debug
buttonPos = [NewFetchTracePanelPosition(1)+10 textPos(2)-3 30  NewFetchTracePanelPosition(4)/9];
debugButton = uicontrol('Parent',MainGui,'Style','PushButton','String','Debug','Tag','new_fetch_traces_debug_button',...
    'Units','Characters','Position',buttonPos,'ForegroundColor',AccentColor,'Visible','off',...
    'Callback','hdls=findobj(''Tag'',''new_fetch_traces_panel'');userdata=get(hdls,''UserData'');userdata{:}');
responseChoiceTextPosition = [NewFetchTracePanelPosition(1)+1 NewFetchTracePanelPosition(2)+NewFetchTracePanelPosition(4)*0.15 24 NewFetchTracePanelPosition(4)/9];
responseChoiceText = uicontrol('Tag','new_fetch_traces_response_text','Units','Characters',...
    'Position',responseChoiceTextPosition,'String','Response removal:','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
responseChoicePopupPosition = [NewFetchTracePanelPosition(1)+1+24 NewFetchTracePanelPosition(2)+NewFetchTracePanelPosition(4)*0.15 30 NewFetchTracePanelPosition(4)/9];
responseChoicePopup = uicontrol('Tag','new_fetch_traces_response_popup','Units','Characters',...
    'Position',responseChoicePopupPosition,'String',{'No Removal','Scalar Only','Pole-Zero to Displacement','Pole-Zero to Velocity', 'Pole-Zero to Acceleration'},...
    'Value',1,'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_traces_panel'');tmp=get(outhdls,''UserData'');tmp{8}=v;set(outhdls,''UserData'',tmp)');


% RF processing panel
% pre-processing
% Response deconvolution: popup
% Taper: editbox or popup
% Filter high pass: editbox  (0 for no high pass)
% filter low pass: editbox   (0 for no low pass)
% filter order: editbox or popup
% pre-phase cut? (editbox) ie -10
% post-phase cut? (editbox) ie 100
% RF
% numerator:  popup for component
% denominator: popup for componnet
% denominator by:
%     popup between station-specific or event-wide
% deconvolution type:
%     popup between waterlevel and iterative
% waterlevel: editbox 
% maxiterations: editbox 
% gaussian: editbox 
% filter minerror: editbox

% Really need to make better use of this space!

RFProcessingPanel = uipanel('Tag','new_fetch_rfprocessing_params_panel','Units','Characters','Position',NewFetchRFProcessingPanelPosition,...
    'Parent',MainGui,'BorderType','etchedin','BackgroundColor',BackColor,'Visible','off','Title','RF Params:',...
    'UserData',{' 5% Hann','0.02','2.0','3','10','100','Radial','Vertical','Single station','2.5','Iterative','1e-2','200','1e-5',' 5% Hann','0.02','2.0','3','10','100','Tangential/SH','Vertical','Single station','2.5','Iterative','1e-2','200','1e-5','P','P'});

taperChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 39.5 30 1.5];
taperChoiceText = uicontrol('Tag','new_fetch_rfprocessing_taper_text','Units','Characters',...
    'Position',taperChoiceTextPosition,'String','Taper:','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
taperChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 39.5 12 1.5];
taperChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_taper_popup','Units','Characters',...
    'Position',taperChoicePopupPosition,'String',{'No Taper',' 5% Hann','10% Hann',' 5% Hamming', '10% Hamming'},...
    'Value',2,'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{1}=v;set(outhdls,''UserData'',tmp)');

primaryChoiceTextPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 42 12 1];
primaryChoiceText = uicontrol('Tag','new_fetch_rfprocessing_primary_choice_text','Parent',MainGui,'Style','Text',...
    'String','Primary RF:','Visible','off','BackgroundColor',BackColor,'Units','Characters','Position',primaryChoiceTextPosition);
secondaryChoiceTextPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1+12 42 12 1];
secondaryChoiceText = uicontrol('Tag','new_fetch_rfprocessing_secondary_choice_text','Parent',MainGui,'Style','Text',...
    'String','Secondary RF:','Visible','off','BackgroundColor',BackColor,'Units','Characters','Position',secondaryChoiceTextPosition);

filterHighPassChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 37.5 30 1.5];
filterHighPassChoiceText = uicontrol('Tag','new_fetch_rfprocessing_filter_high_pass_text','Units','Characters',...
    'Position',filterHighPassChoiceTextPosition,'String','Filter high pass (Hz):','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
filterHighPassChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 37.5 12 1.5];
filterHighPassChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_high_pass_edit','Units','Characters',...
    'Position',filterHighPassChoiceEditPosition,'String','0.02',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{2}=t;set(outhdls,''UserData'',tmp)');

filterLowPassChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 35.75 30 1.5];
filterLowPassChoiceText = uicontrol('Tag','new_fetch_rfprocessing_filter_low_pass_text','Units','Characters',...
    'Position',filterLowPassChoiceTextPosition,'String','Filter low pass (Hz):','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
filterLowPassChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 35.75 12 1.5];
filterLowPassChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_low_pass_edit','Units','Characters',...
    'Position',filterLowPassChoiceEditPosition,'String','2.0',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{3}=t;set(outhdls,''UserData'',tmp)');

filterOrderChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 33.8 30 1.5];
filterOrderChoiceText = uicontrol('Tag','new_fetch_rfprocessing_filter_order_text','Units','Characters',...
    'Position',filterOrderChoiceTextPosition,'String','Filter order:','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
filterOrderChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 33.8 12 1.5];
filterOrderChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_order_popup','Units','Characters',...
    'Position',filterOrderChoicePopupPosition,'String',{'2','3','4','5','6','7','8','9','10'},'Value',2,...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{4}=v;set(outhdls,''UserData'',tmp)');

cutBeforePhaseChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 31.6 30 1.5];
cutBeforePhaseChoiceText = uicontrol('Tag','new_fetch_rfprocessing_cut_before_phase_text','Units','Characters',...
    'Position',cutBeforePhaseChoiceTextPosition,'String','Time before phase to keep (sec):','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
cutBeforePhaseChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 31.6 12 1.5];
cutBeforePhaseChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_cut_before_phase_edit','Units','Characters',...
    'Position',cutBeforePhaseChoiceEditPosition,'String','10',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{5}=t;set(outhdls,''UserData'',tmp)');

cutAfterPhaseChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 29 30 2];
cutAfterPhaseChoiceText = uicontrol('Tag','new_fetch_rfprocessing_cut_after_phase_text','Units','Characters',...
    'Position',cutAfterPhaseChoiceTextPosition,'String','Time after phase to keep (sec):','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
cutAfterPhaseChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 29.4 12 1.5];
cutAfterPhaseChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_cut_after_phase_edit','Units','Characters',...
    'Position',cutAfterPhaseChoiceEditPosition,'String','100',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{6}=t;set(outhdls,''UserData'',tmp)');


numeratorChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 27.2 30 1.5];
numeratorChoiceText = uicontrol('Tag','new_fetch_rfprocessing_numerator_text','Units','Characters',...
    'Position',numeratorChoiceTextPosition,'String','Numerator:','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
numeratorChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 27.2 12 1.5];
numeratorChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_numerator_popup','Units','Characters',...
    'Position',numeratorChoicePopupPosition,'String',{'Vertical','P','Radial','SV','Tangential/SH'},'Value',3,...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{7}=v;set(outhdls,''UserData'',tmp)');

denominatorChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 24.5 30 2];
denominatorChoiceText = uicontrol('Tag','new_fetch_rfprocessing_denominator_text','Units','Characters',...
    'Position',denominatorChoiceTextPosition,'String','Denominator:','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
denominatorChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 25 12 1.5];
denominatorChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_denominator_popup','Units','Characters',...
    'Position',denominatorChoicePopupPosition,'String',{'Vertical','P','Radial','SV','Tangential/SH'},'Value',1,...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{8}=v;set(outhdls,''UserData'',tmp)');

denominatorMethodChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 22.8 30 1.5];
denominatorMethodChoiceText = uicontrol('Tag','new_fetch_rfprocessing_denominator_method_text','Units','Characters',...
    'Position',denominatorMethodChoiceTextPosition,'String','Source Method:','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
denominatorMethodChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 22.8 12 1.5];
denominatorMethodChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_denominator_method_popup','Units','Characters',...
    'Position',denominatorMethodChoicePopupPosition,'String',{'Single station', 'Array based by event'},'Value',1,...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{9}=v;set(outhdls,''UserData'',tmp)');

gaussianChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 20.6 30 1.5];
gaussianChoiceText = uicontrol('Tag','new_fetch_rfprocessing_gaussian_text','Units','Characters',...
    'Position',gaussianChoiceTextPosition,'String','Gaussian:','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
gaussianChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 20.6 12 1.5];
gaussianChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_gaussian_edit','Units','Characters',...
    'Position',gaussianChoiceEditPosition,'String','2.5',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{10}=t;set(outhdls,''UserData'',tmp)');

deconvolutionMethodChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 18.4 30 1.5];
deconvolutionMethodChoiceText = uicontrol('Tag','new_fetch_rfprocessing_deconvolution_method_text','Units','Characters',...
    'Position',deconvolutionMethodChoiceTextPosition,'String','Deconvolution Method:','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
deconvolutionMethodChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 18.4 12 1.5];
deconvolutionMethodChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_deconvolution_method_popup','Units','Characters',...
    'Position',deconvolutionMethodChoicePopupPosition,'String',{'Iterative', 'Waterlevel'},'Value',1,...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{11}=v;set(outhdls,''UserData'',tmp)');
waterlevelChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 16.2 30 1.5];
waterlevelChoiceText = uicontrol('Tag','new_fetch_rfprocessing_waterlevel_text','Units','Characters',...
    'Position',waterlevelChoiceTextPosition,'String','Waterlevel:','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
waterlevelChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 16.2 12 1.5];
waterlevelChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_waterlevel_edit','Units','Characters',...
    'Position',waterlevelChoiceEditPosition,'String','1e-2',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{12}=t;set(outhdls,''UserData'',tmp)');
maxIterationsChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 14 30 1.5];
maxIterationsChoiceText = uicontrol('Tag','new_fetch_rfprocessing_max_iterations_text','Units','Characters',...
    'Position',maxIterationsChoiceTextPosition,'String','Max Iterations:','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
maxIterationsChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 14 12 1.5];
maxIterationsChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_max_iterations_edit','Units','Characters',...
    'Position',maxIterationsChoiceEditPosition,'String','200',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{13}=t;set(outhdls,''UserData'',tmp)');

minErrorChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 11.8 30 1.5];
minErrorChoiceText = uicontrol('Tag','new_fetch_rfprocessing_min_error_text','Units','Characters',...
    'Position',minErrorChoiceTextPosition,'String','Min Error:','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
minErrorChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 11.8 12 1.5];
minErrorChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_min_error_edit','Units','Characters',...
    'Position',minErrorChoiceEditPosition,'String','1e-5',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{14}=t;set(outhdls,''UserData'',tmp)');

%%%%%%%%%%%%%%%% repeat for secondary choice:


taperChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 39.5 12 1.5];
taperChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_taper_2_popup','Units','Characters',...
    'Position',taperChoicePopupPosition,'String',{'No Taper',' 5% Hann','10% Hann',' 5% Hamming', '10% Hamming'},...
    'Value',2,'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{15}=v;set(outhdls,''UserData'',tmp)');
filterHighPassChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 37.5 12 1.5];
filterHighPassChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_high_pass_2_edit','Units','Characters',...
    'Position',filterHighPassChoiceEditPosition,'String','0.02',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{16}=t;set(outhdls,''UserData'',tmp)');
filterLowPassChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 35.75 12 1.5];
filterLowPassChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_low_pass_2_edit','Units','Characters',...
    'Position',filterLowPassChoiceEditPosition,'String','2.0',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{17}=t;set(outhdls,''UserData'',tmp)');
filterOrderChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 33.8 12 1.5];
filterOrderChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_order_2_popup','Units','Characters',...
    'Position',filterOrderChoicePopupPosition,'String',{'2','3','4','5','6','7','8','9','10'},'Value',2,...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{18}=v;set(outhdls,''UserData'',tmp)');
cutBeforePhaseChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 31.6 12 1.5];
cutBeforePhaseChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_cut_before_phase_2_edit','Units','Characters',...
    'Position',cutBeforePhaseChoiceEditPosition,'String','10',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{19}=t;set(outhdls,''UserData'',tmp)');
cutAfterPhaseChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 29.4 12 1.5];
cutAfterPhaseChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_cut_after_phase_2_edit','Units','Characters',...
    'Position',cutAfterPhaseChoiceEditPosition,'String','100',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{20}=t;set(outhdls,''UserData'',tmp)');


numeratorChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 27.2 12 1.5];
numeratorChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_numerator_2_popup','Units','Characters',...
    'Position',numeratorChoicePopupPosition,'String',{'Vertical','P','Radial','SV','Tangential/SH'},'Value',5,...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{21}=v;set(outhdls,''UserData'',tmp)');
denominatorChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 25 12 1.5];
denominatorChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_denominator_2_popup','Units','Characters',...
    'Position',denominatorChoicePopupPosition,'String',{'Vertical','P','Radial','SV','Tangential/SH'},'Value',1,...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{22}=v;set(outhdls,''UserData'',tmp)');
denominatorMethodChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 22.8 12 1.5];
denominatorMethodChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_denominator_method_2_popup','Units','Characters',...
    'Position',denominatorMethodChoicePopupPosition,'String',{'Single station', 'Array based by event'},'Value',1,...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{23}=v;set(outhdls,''UserData'',tmp)');

gaussianChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 20.6 12 1.5];
gaussianChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_gaussian_2_edit','Units','Characters',...
    'Position',gaussianChoiceEditPosition,'String','2.5',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{24}=t;set(outhdls,''UserData'',tmp)');

deconvolutionMethodChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 18.4 12 1.5];
deconvolutionMethodChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_deconvolution_method_2_popup','Units','Characters',...
    'Position',deconvolutionMethodChoicePopupPosition,'String',{'Iterative', 'Waterlevel'},'Value',1,...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','PopupMenu',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{25}=v;set(outhdls,''UserData'',tmp)');
waterlevelChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 16.2 12 1.5];
waterlevelChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_waterlevel_2_edit','Units','Characters',...
    'Position',waterlevelChoiceEditPosition,'String','1e-2',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{26}=t;set(outhdls,''UserData'',tmp)');
maxIterationsChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 14 12 1.5];
maxIterationsChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_max_iterations_2_edit','Units','Characters',...
    'Position',maxIterationsChoiceEditPosition,'String','200',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{27}=t;set(outhdls,''UserData'',tmp)');

minErrorChoiceEditPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 11.8 12 1.5];
minErrorChoiceEdit = uicontrol('Tag','new_fetch_rfprocessing_min_error_2_edit','Units','Characters',...
    'Position',minErrorChoiceEditPosition,'String','1e-5',...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Edit',...
    'Callback','t=get(gcbo,''String'');outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{28}=t;set(outhdls,''UserData'',tmp)');

% Incident phase: both primary and secondary put at the end as this is
% added as an afterthough :-/
incidentPhaseChoiceTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 9.6 30 1.5];
incidentPhaseChoiceText = uicontrol('Tag','new_fetch_rfprocessing_incident_phase_text','Units','Characters',...
    'Position',incidentPhaseChoiceTextPosition,'String','Incident Phase:','Visible','Off','BackgroundColor',BackColor,...
    'Parent',MainGui,'Style','Text');
incidentPhaseChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+1 9.6 12 1.5];
incidentPhaseChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_incident_phase_popup','Units','Characters',...
    'Position',incidentPhaseChoicePopupPosition,'String',{'P','PKP','S','SKS'},...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Popup',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{29}=v;set(outhdls,''UserData'',tmp)');
incidentPhaseChoicePopupPosition = [taperChoiceTextPosition(1)+taperChoiceTextPosition(3)+13.5 9.6 12 1.5];
incidentPhaseChoicePopup = uicontrol('Tag','new_fetch_rfprocessing_incident_phase_2_popup','Units','Characters',...
    'Position',incidentPhaseChoicePopupPosition,'String',{'P','PKP','S','SKS'},...
    'Visible','off','BackgroundColor',BackColor,'Parent',MainGui,'Style','Popup',...
    'Callback','t=get(gcbo,''String'');tt=get(gcbo,''Value'');v=t{tt};outhdls = findobj(''Tag'',''new_fetch_rfprocessing_params_panel'');tmp=get(outhdls,''UserData'');tmp{30}=v;set(outhdls,''UserData'',tmp)');


% Warning message before fetching
%warningTextPosition = [NewFetchRFProcessingPanelPosition(1)+1 9 50 3];
%warningText = uicontrol('Tag','new_fetch_rfprocessing_warning_text','Units','Characters',...
%    'Position',warningTextPosition,'String','Warning: fetching and processing may take a considerable time.','Visible','Off','BackgroundColor',BackColor,...
%    'Parent',MainGui,'Style','Text','ForegroundColor',AccentColor,'FontAngle','Italic','FontSize',14);

% box to allow username and password
encryptedPanel = uipanel('Tag','encryptedInfoPanel','Units','Characters','Position',NewFetchEncryptedPanelPosition,...
    'Parent',MainGui,'BorderType','etchedin','BackgroundColor',BackColor,'Visible','off',...
    'Title','Encrypted Access:','UserData',{[],[]});
encryptedButtonPosition = [NewFetchEncryptedPanelPosition(1)+1 NewFetchEncryptedPanelPosition(2)+1, NewFetchEncryptedPanelPosition(3)-2, NewFetchEncryptedPanelPosition(4)-2];
encryptedButtonHandles = uicontrol('Style','Pushbutton','Tag','encrypted_button','Visible','off',...
    'Parent',MainGui,'Units','Characters','String','Encrypted data access','ForegroundColor',[0.6 0 0.2],...
    'Position',encryptedButtonPosition,'FontUnits','normalized','FontSize',0.25,'Callback','FL_addRestrictedDataParams');



%easter egg
easterPanel = uipanel('Tag','easterEggPanel','Units','Characters','Position',[4+(MainPos(3)-10)/2.2+1, 8,27.5,18.5],...
    'Parent',MainGui,'BorderType','etchedin','BackgroundColor',BackColor,'Visible','off');
pfunk = imread('george-clinton-729-420x0.jpg');
pfunkAxis = subplot(1,1,1,'Parent',easterPanel);
                      % alternative web link: https://www.youtube.com/watch?v=l4nOHdUntyM  or   https://www.youtube.com/watch?v=LuyS9M8T03A
pfunkImage = image(pfunk,'Parent',pfunkAxis,'ButtonDownFcn','web(''https://www.youtube.com/watch?v=l4nOHdUntyM'',''-browser'')');
axis(pfunkAxis,'off');
    



% Note on fetching:
% two methods - either fetch one station at a time and then process it or
% fetch all stations at once and cut them once they are fetched.

FetchStartButtonPos = [StartButtonPos(1)/4 StartButtonPos(2) StartButtonPos(3)*4 StartButtonPos(4)];
% Go button
uicontrol ('Parent',MainGui,'Style','pushbutton','Units','characters','Tag','new_fetch_start_pb','String','Fetch traces and create project (warning, this may take a considerable length of time!)',...
    'Position',FetchStartButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.25,'FontWeight','bold',...
    'Visible','off','Callback',@FL_new_fetch_project_setup_Callback);



%--------------------------------------------------------------------------
% Main Project GUI
%--------------------------------------------------------------------------
% Data Exploring Windows
%--------------------------------------------------------------------------
uicontrol('Parent',MainGui,'Style','frame','Units','characters','Tag','explorer_fm',...
    'Position',DataPos,'BackgroundColor',AccentColor,'ForegroundColor',AccentColor2,'Visible','off');
uicontrol('Parent',MainGui,'Style','text','Units','characters','Tag','project_t',...
    'Position',[0 0 1 1],'BackgroundColor',AccentColor,'ForegroundColor',[1 1 1],'FontUnits','normalized','FontSize',0.9,...
    'FontWeight','bold','HorizontalAlignment','left','Visible','off');
TableNames = {'Station Tables','Event Tables'};
uicontrol('Parent',MainGui,'Style','popupmenu','Units','characters','Tag','tablemenu_pu','String',TableNames,...
    'Position',PopupPos,'BackgroundColor',EditColor,'FontUnits','normalized','FontSize',0.75,'HorizontalAlignment','left','Visible','off',...
    'Callback',{@tablemenu_Callback});

tmenu = uicontextmenu('Parent',MainGui);
uimenu(tmenu,'Label','Turn ''On"','Callback',{@turnon_table_Callback});
uimenu(tmenu,'Label','Turn ''Off"','Callback',{@turnoff_table_Callback});
uicontrol('Parent',MainGui,'Style','listbox','Units','characters','Tag','tables_ls',...
    'Position',TablesPos,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',0.025,'HorizontalAlignment','left','Visible','off',...
    'UIContextmenu',tmenu,'Callback',{@tables_Callback});

uicontrol('Parent',MainGui,'Style','text','Units','characters','Tag','tablesinfo_t',...
    'Position',TableInfoPos,'BackgroundColor',AccentColor,'ForegroundColor',[1 1 1],'FontUnits','normalized','FontSize',0.4,...
    'HorizontalAlignment','left','Visible','off');
uicontrol('Parent',MainGui,'Style','text','Units','characters','Tag','records_t','String','Records',...
    'Position',RecordsTitlePos,'BackgroundColor',AccentColor,'ForegroundColor',[1 1 1],'FontUnits','normalized','FontSize',0.9,...
    'HorizontalAlignment','left','Visible','off');

rmenu = uicontextmenu('Parent',MainGui);
uimenu(rmenu,'Label','Turn ''On"','Callback',{@turnon_record_Callback});
uimenu(rmenu,'Label','Turn ''Off"','Callback',{@turnoff_record_Callback});
uicontrol('Parent',MainGui,'Style','listbox','Units','characters','Tag','records_ls',...
    'Position',RecordsPos,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',0.025,'HorizontalAlignment','left','Visible','off',...
    'UIContextmenu',rmenu,'Callback',{@records_Callback});

uicontrol('Parent',MainGui,'Style','text','Units','characters','Tag','recordsinfo_t',...
    'Position',RecordInfoPos,'BackgroundColor',AccentColor,'ForegroundColor',[1 1 1],'FontUnits','normalized','FontSize',0.4,...
    'HorizontalAlignment','left','Visible','off');
uicontrol('Parent',MainGui,'Style','text','Units','characters','Tag','info_t','String','Record Information',...
    'Position',InfoTitlePos,'BackgroundColor',AccentColor,'ForegroundColor',[1 1 1],'FontUnits','normalized','FontSize',0.9,...
    'HorizontalAlignment','left','Visible','off');
uicontrol('Parent',MainGui,'Style','listbox','Units','characters','Tag','info_ls',...
    'Position',InfoPos,'FontUnits','normalized','FontName','FixedWidth','FontSize',0.0225,'HorizontalAlignment','left',...
    'Visible','off');

%Message
%--------------------------------------------------------------------------
uicontrol ('Parent',MainGui,'Style','text','Units','characters','Tag','message_t','String','Message:',...
    'Position',MessagePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.75,'HorizontalAlignment','left',...
    'BackgroundColor',BackColor,'Visible','off');

% Collect GUI Handles
%--------------------------------------------------------------------------
handles = guihandles(MainGui);
if exist('AddonNames','var')
    handles.addons = AddonNames;
end
guidata(MainGui,handles);


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Subfunction Callbacks
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Citation menu
% citation_funclab_Callback
%--------------------------------------------------------------------------
function citation_funclab_Callback(cbo, eventdata)
    str = 'Eagar, K. C., & Fouch, M. J. (2012). FuncLab: A MATLAB interactive toolbox for handling receiver function datasets. Seismological Research Letters, 83(3), 596-603.';
    MainPos = [0 0 75 30];
    ProcButtonPos = [30 1 25 2];

    CitationDlg = dialog('Name','Funclab Citation','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
            'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    CitationText = uicontrol('Parent',CitationDlg,'Style','Edit','String',str,'Units','Characters',...
            'Position',[5 4 65 25],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.04,'HorizontalAlignment','left',...
            'Max',100,'Min',1);

    OkButton = uicontrol('Parent',CitationDlg,'Style','Pushbutton','String','OK','Units','Characters',...
            'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
            'Callback','close');
 
function citation_rf_Callback(cbo, eventdata)
    str1 = 'Langston, C. A. (1977). Corvallis, Oregon, crustal and upper mantle receiver structure from teleseismic P and S waves. Bulletin of the Seismological Society of America, 67(3), 713-724.';
    str2 = 'Vinnik, L. P. (1977). Detection of waves converted from P to SV in the mantle. Physics of the Earth and planetary interiors, 15(1), 39-45.';
    str = {str1, '', str2};

    MainPos = [0 0 75 30];
    ProcButtonPos = [30 1 25 2];

    CitationDlg = dialog('Name','Funclab Citation','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
            'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    CitationText = uicontrol('Parent',CitationDlg,'Style','Edit','String',str,'Units','Characters',...
            'Position',[5 4 65 25],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.04,'HorizontalAlignment','left',...
            'Max',100,'Min',1);

    OkButton = uicontrol('Parent',CitationDlg,'Style','Pushbutton','String','OK','Units','Characters',...
            'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
            'Callback','close');
        
function citation_hk_Callback(cbo, eventdata)
    str1 = 'Zhu, L., & Kanamori, H. (2000). Moho depth variation in southern California from teleseismic receiver functions. Journal of Geophysical Research: Solid Earth, 105(B2), 2969-2980.';
    str2 = 'William L. Yeck, Anne F. Sheehan and Vera Schulte-Pelkum, Sequential H-k stacking to obtain accurate crustal thicknesses beneath sedimentary basins, Bulletin of the Seismological Society of America(June 2013) 103 (3): 2142-2150';
    str3 = 'Wang, Weilai, et al. "Sedimentary and crustal thicknesses and Poissons ratios for the NE Tibetan Plateau and its adjacent regions based on dense seismic arrays." Earth and Planetary Science Letters 462 (2017): 76-85.';
    str = {str1, '', str2, '',str3};
    
    MainPos = [0 0 75 30];
    ProcButtonPos = [30 1 25 2];

    CitationDlg = dialog('Name','Funclab Citation','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
            'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    CitationText = uicontrol('Parent',CitationDlg,'Style','Edit','String',str,'Units','Characters',...
            'Position',[5 4 65 25],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.04,'HorizontalAlignment','left',...
            'Max',100,'Min',1);

    OkButton = uicontrol('Parent',CitationDlg,'Style','Pushbutton','String','OK','Units','Characters',...
            'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
            'Callback','close');

function citation_ccp_Callback(cbo, eventdata)
    str = 'Dueker, K. G., & Sheehan, A. F. (1998). Mantle discontinuity structure beneath the Colorado rocky mountains and high plains. Journal of Geophysical Research: Solid Earth, 103(B4), 7153-7169.';

    MainPos = [0 0 75 30];
    ProcButtonPos = [30 1 25 2];

    CitationDlg = dialog('Name','Funclab Citation','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
            'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    CitationText = uicontrol('Parent',CitationDlg,'Style','Edit','String',str,'Units','Characters',...
            'Position',[5 4 65 25],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.04,'HorizontalAlignment','left',...
            'Max',100,'Min',1);

    OkButton = uicontrol('Parent',CitationDlg,'Style','Pushbutton','String','OK','Units','Characters',...
            'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
            'Callback','close');        

function citation_other_Callback(cbo, eventdata)
    str1H = 'Transition Zone PRF by FL author (RWP)';
    str1B = 'Porritt, R. W., & Yoshioka, S. (2016). Slab pileup in the mantle transition zone and the 30 May 2015 Chichijima earthquake. Geophysical Research Letters.';
    
    str2H = 'Joint PRF + surface wave and SRF by FL author (RWP)';
    str2B = 'Porritt, Robert W., Meghan S. Miller, and Fiona A. Darbyshire. "Lithospheric architecture beneath Hudson Bay." Geochemistry, Geophysics, Geosystems 16.7 (2015): 2262-2275.';
    
    str3H = 'Joint PRF + surface wave in Puna Plateau';
    str3B = 'Delph, J. R., Ward, K. M., Zandt, G., Ducea, M. N., & Beck, S. L. (2017). Imaging a magma plumbing system from MASH zone to magma reservoir. Earth and Planetary Science Letters, 457, 313-324.';
    
    str4H = 'Colorado Plateau PRF + gravity';
    str4B = 'Bailey, I. W., Miller, M. S., Liu, K., & Levander, A. (2012). VS and density structure beneath the Colorado Plateau constrained by gravity anomalies and joint inversions of receiver function and phase velocity data. Journal of Geophysical Research: Solid Earth, 117(B2).';
    
    str5H = 'PRF and SRF in western north america';
    str5B = 'Levander, A., and M. S. Miller (2012), Evolutionary aspects of lithosphere discontinuity structure in the western U.S., Geochem. Geophys. Geosyst., 13, Q0AK07, doi:10.1029/2012GC004056.';
    
    str6H = 'PRF in southern alaska';
    str6B = 'Brennan, P. R., Gilbert, H., & Ridgway, K. D. (2011). Crustal structure across the central Alaska Range: Anatomy of a Mesozoic collisional zone. Geochemistry, Geophysics, Geosystems, 12(4).';
    
    str7H = 'PRF in Idaho';
    str7B = 'Stanciu, A. C., R. M. Russo, V. I. Mocanu, P. M. Bremner, S. Hongsresawat, M. E. Torpey, J. C. VanDecar, D. A. Foster, and J. A. Hole (2016), Crustal structure beneath the Blue Mountains terranes and cratonic North America, eastern Oregon, and Idaho, from teleseismic receiver functions, J. Geophys. Res. Solid Earth, 121, 5049?5067, doi:10.1002/2016JB012989.';
    
    str8H = 'PRF in Sierra Nevada';
    str8B = 'Frassetto, A. M., Zandt, G., Gilbert, H., Owens, T. J., & Jones, C. H. (2011). Structure of the Sierra Nevada from receiver functions and implications for lithospheric foundering. Geosphere, 7(4), 898-921.';
    
    str9H = 'PRF in the Bighorns';
    str9B = 'Yeck, W. L., A. F. Sheehan, M. L. Anderson, E. A. Erslev, K. C. Miller, and C. S. Siddoway (2014), Structure of the Bighorn Mountain region, Wyoming, from teleseismic receiver function analysis: Implications for the kinematics of Laramide shortening, J. Geophys. Res. Solid Earth, 119, 7028?7042, doi:10.1002/2013JB010769.';
    
    str = {'Please send newly published articles using FuncLab to rwporritt@gmail.com','',str1H,str1B,'',str2H,str2B,'',str3H,str3B,'',str4H,str4B,'',...
        str5H,str5B,'',str6H,str6B,'',str7H,str7B,'',str8H,str8B,'',str9H,str9B};
    
    MainPos = [0 0 75 30];
    ProcButtonPos = [30 1 25 2];

    CitationDlg = dialog('Name','Funclab Citation','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
            'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

    CitationText = uicontrol('Parent',CitationDlg,'Style','Edit','String',str,'Units','Characters',...
            'Position',[5 4 65 25],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.04,'HorizontalAlignment','left',...
            'Max',1000,'Min',1);

    OkButton = uicontrol('Parent',CitationDlg,'Style','Pushbutton','String','OK','Units','Characters',...
            'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
            'Callback','close');        
                
%--------------------------------------------------------------------------
% te_turn_off_dead_traces_Callback
% if a trace contains a nan or inf as the first data point, it turns the
% status to off
%--------------------------------------------------------------------------
function te_turn_off_dead_traces_Callback(cbo, eventdata)
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
nrecords = size(RecordMetadataDoubles,1);
if nrecords > 5000 
    wb=waitbar(0,'Please wait...','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
    setappdata(wb,'canceling',0);
end
for idx=1:nrecords
    % Note - this requires both eqr and eqt to be non-nan. This may not
    % always be desireable depending on project. It is significantly better
    % practice to just kill bad data before it becomes a part of the
    % project.
    tmp = fl_readseismograms([ProjectDirectory RecordMetadataStrings{idx,1} 'eqr']);
    if isnan(tmp(1)) || isinf(tmp(1))
        RecordMetadataDoubles(idx, 2) = 0;
    end
    tmp = fl_readseismograms([ProjectDirectory RecordMetadataStrings{idx,1} 'eqt']);
    if isnan(tmp(1)) || isinf(tmp(1))
        RecordMetadataDoubles(idx, 2) = 0;
    end
    if mod(idx, 1000) == 0
        waitbar(idx/nrecords,wb);
    end
    if nrecords > 5000
        if getappdata(wb,'canceling')
            disp('Turn off dead traces canceled');
            break
        end
    end
end
SetManagementCell{CurrentSubsetIndex,3} = RecordMetadataDoubles;
assignin('base','SetManagementCell',SetManagementCell);
assignin('base','RecordMetadataDoubles',RecordMetadataDoubles);
save([ProjectDirectory ProjectFile],'SetManagementCell','RecordMetadataDoubles','-append');
if nrecords > 5000
    delete(wb);
end

%--------------------------------------------------------------------------
% choose_subset_Callback
% Allows the user to choose a different set to be active
%--------------------------------------------------------------------------
function choose_subset_Callback(cbo, eventdata)
h=guidata(gcbf);
fl_choose_subset(h);


%--------------------------------------------------------------------------
% delete_subset_Callback
% Removes a row from the SetManagementCell corresponding to a no longer
% wanted subset
%--------------------------------------------------------------------------
function delete_subset_Callback(cbo, eventdata)
h=guidata(gcbf);
fl_delete_subset(h);

%--------------------------------------------------------------------------
% create_new_subset_Callback
%
% This callback function starts a new gui which will allow the user to
% create a subset project from the main project. Subset projects can be
% operated on in much the same way as the main project, but allow you to
% select data with a variety of parameters.
%--------------------------------------------------------------------------
function create_new_subset_Callback(cbo, eventdata)
h=guidata(gcbf);
fl_create_new_subset(h);

%--------------------------------------------------------------------------
% about_Callback
%
% This callback function displays the "About" screen for FuncLab
%--------------------------------------------------------------------------
function about_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
AboutGui = dialog('Name','About FuncLab','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 40 9],'CreateFcn',{@movegui_kce,'center'});
uicontrol ('Parent',AboutGui,'Style','text','Units','characters','String','FuncLab',...
    'Position',[3 6.5 34 2],'FontWeight','bold','FontSize',14);
uicontrol ('Parent',AboutGui,'Style','text','Units','characters',...
    'String','Version 1.8.2',...
    'Position',[3 5.75 34 1.5],'FontSize',8);
uicontrol ('Parent',AboutGui,'Style','text','Units','characters',...
    'String',{'Email: rwporritt@gmail.com';'Home Page: http://robporritt.wordpress.com/software'},...
    'Position',[3 2.5 34 3],'FontSize',8);
uicontrol ('Parent',AboutGui,'Style','text','Units','characters',...
    'String',{'This code has been updated by Rob Porritt, but is not regularily maintained.'},...
    'Position',[3 0.5 34 1.5],'FontSize',8);
drawnow

%--------------------------------------------------------------------------
% compute_rayp_Callback
%
% This callback recomputes the ray parameters for a direct P wave based on
% event depth and distance.
% Enters updated information in the Project File
%--------------------------------------------------------------------------
function compute_rayp_Callback(cbo, eventdata, handles)
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
h=guidata(gcbf);
%load([ProjectDirectory ProjectFile],'RecordMetadataDoubles')
load([ProjectDirectory ProjectFile],'SetManagementCell')
RecordMetadataDoubles = SetManagementCell{1,3};
RecordMetadataStrings = SetManagementCell{1,2};
nrecords = size(RecordMetadataDoubles,1);
if nrecords > 5000 
    wb=waitbar(0,'Please wait...','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
    setappdata(wb,'canceling',0);
end
%WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
%    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
%uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
%    'String','Please wait...',...
%    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
%drawnow
tokm = pi/180/111.19;
saveFlag = 1;
for idx=1:nrecords
    tt = taupTime([],RecordMetadataDoubles(idx,15),'P','deg',RecordMetadataDoubles(idx,17));
    if ~isempty(tt)
        RecordMetadataDoubles(idx,18) = tt(1).rayParam * tokm;
    else
        fprintf('Warning, record %d not in P wave range.\n',idx);
        RecordMetadataDoubles(idx,18) = 0.001;
    end
    if nrecords > 5000
        if getappdata(wb,'canceling')
            saveFlag = 0;
            break
        end
        if mod(idx,1000) == 0
            waitbar(idx/nrecords,wb);
        end
    end
end
if nrecords > 5000
    delete(wb);
end
if saveFlag == 1
    SetManagementCell{1,3} = RecordMetadataDoubles;
    save([ProjectDirectory ProjectFile],'RecordMetadataDoubles','SetManagementCell','-append')
    assignin('base','RecordMetadataDoubles',RecordMetadataDoubles)
    assignin('base','RecordMetadataStrings',RecordMetadataStrings)
    assignin('base','SetManagementCell',SetManagementCell);
    set(h.message_t,'String','Message: Done recomputing Ray Parameters');
else
    set(h.message_t,'String','Message: Ray parameter computation canceled.');
end
%close(WaitGui)

%--------------------------------------------------------------------------
% Compute_new_RFs_Callback
% 
% Launches a new gui to allow user to set parameters and compute a new set
% of receiver functions. 
% Clears the project variables and creates a new project. Can be called
% before a project is loaded/created or after.
%--------------------------------------------------------------------------
function Compute_new_RFs_Callback(cbo, eventdata, handles)
h = guidata(gcbf);
WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String','Please wait, loading in datasets and creating station and event tables',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow

FL_call_new_RF_computation_gui(h, WaitGui);

waitfor(WaitGui)

% For now, if no project is loaded and user cancels, throws an error, but
% it doesn't really matter for usage. 
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
load([ProjectDirectory ProjectFile]);

tables_Callback


%--------------------------------------------------------------------------
% PRF_to_depth_Callback
%
% Starts a new gui to get 1D depth inversion parameters. Writes a set of
% sac files in the new ProjectDirectory/DepthTraces which are PRF amplitude
% vrs. depth rather than time. Also writes a matfile with the full 3D ray
% info.
%--------------------------------------------------------------------------
function PRF_to_depth_Callback(cbo, eventdata, handles)
FL_call_PRF_to_depth_gui;
% ProjectFile and the base level workspace now contains ThreeDRayInfoFile, 
% which is the file name of a mat file with all the latitude, longitude, 
% radius, eqr, and eqt data in a structure called RayInfo{}.
% Set a depth based map plot option on.
h=guidata(gcbf);
set(h.ray_diagram_m,'Enable','on')
set(h.ray_diagram_all_m,'Enable','on')
set(h.rf_cross_section_depth_m,'Enable','on')
set(h.rf_cross_section_2d_ccp_m,'Enable','on')


%--------------------------------------------------------------------------
% new_project_window_Callback
%
% This callback function turns off the "Startup" GUI and turns on the "New
% Project" GUI
%--------------------------------------------------------------------------
function new_project_window_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
set(h.welcome1_t,'visible','off')
set(h.welcome2_t,'visible','off')
set(h.welcome3_t,'visible','off')
set(h.welcome4_t,'visible','off')
set(h.new_title_t,'visible','on')
set(h.new_projdir_t,'visible','on')
set(h.new_projdir_e,'visible','on')
set(h.new_adddata_t,'visible','on')
for n = 1:10
    eval(['set(h.new_browse' sprintf('%02.0f',n) '_pb,''visible'',''on'')'])
    eval(['set(h.new_dataset' sprintf('%02.0f',n) '_e,''visible'',''on'')'])
end
set(h.new_start_pb,'visible','on')
set(h.new_fetch_title_t,'visible','off')
set(h.new_fetch_projdir_t,'visible','off')
set(h.new_fetch_projdir_e,'visible','off')
set(h.new_fetch_start_pb,'visible','off')
set(h.new_fetch_get_map_coords_pb,'visible','off')
set(h.new_fetch_lat_max_e,'visible','off');
set(h.new_fetch_lat_min_e,'visible','off');
set(h.new_fetch_lon_max_e,'visible','off');
set(h.new_fetch_lon_min_e,'visible','off');
set(h.new_fetch_get_stations_pb,'visible','off');
set(h.new_fetch_station_panel,'visible','off');
set(h.new_fetch_events_panel,'Visible','off');
set(h.new_fetch_search_start_time_text,'Visible','off');
set(h.new_fetch_search_end_time_text,'Visible','off');
set(h.new_fetch_start_year_pu,'visible','off');
set(h.new_fetch_start_month_pu,'visible','off');
set(h.new_fetch_start_day_pu,'visible','off');
set(h.new_fetch_end_year_pu,'visible','off');
set(h.new_fetch_end_month_pu,'visible','off');
set(h.new_fetch_end_day_pu,'visible','off');
set(h.new_fetch_search_magnitude_text,'visible','off');
set(h.new_fetch_min_mag_pu,'visible','off');
set(h.new_fetch_max_mag_pu,'visible','off');
set(h.new_fetch_event_mag_divider_t,'Visible','off');
set(h.new_fetch_search_distance_text,'Visible','off');
set(h.new_fetch_max_dist_e,'Visible','off');
set(h.new_fetch_min_dist_e,'Visible','off');
set(h.new_fetch_event_distance_divider_t,'Visible','off');
set(h.new_fetch_find_events_pb,'Visible','off');
set(h.new_fetch_max_depth_e,'Visible','off');
set(h.new_fetch_min_depth_e,'Visible','off');
set(h.new_fetch_search_depth_text,'Visible','off');
set(h.new_fetch_event_depth_divider_t,'Visible','off');
set(h.new_fetch_search_depth_text,'visible','off');
set(h.new_fetch_traces_panel,'visible','off');
%set(h.new_fetch_traces_timing_text,'Visible','off');
%set(h.new_fetch_traces_seconds_before_edit,'Visible','off');
%set(h.new_fetch_traces_phase_popup,'Visible','off');
set(h.new_fetch_traces_start_phase_popup,'Visible','off');
set(h.new_fetch_traces_start_time_text,'Visible','off');
set(h.new_fetch_traces_prior_seconds_edit,'Visible','off');
set(h.new_fetch_traces_start_seconds_label,'Visible','off');
set(h.new_fetch_traces_start_before_or_after_popup,'Visible','off');
set(h.new_fetch_traces_end_phase_popup,'Visible','off');
set(h.new_fetch_traces_end_time_text,'Visible','off');
set(h.new_fetch_traces_after_seconds_edit,'Visible','off');
set(h.new_fetch_traces_end_seconds_label,'Visible','off');
set(h.new_fetch_traces_end_before_or_after_popup,'Visible','off');
set(h.new_fetch_traces_end_phase_popup,'Visible','off');
set(h.new_fetch_traces_sample_rate_text,'Visible','off');
set(h.new_fetch_traces_sample_rate_popup,'Visible','off');
set(h.new_fetch_traces_sample_rate_label,'Visible','off');
set(h.new_fetch_traces_debug_button,'Visible','off');
set(h.easterEggPanel,'Visible','off');
set(h.new_fetch_rfprocessing_params_panel,'Visible','off');
set(h.new_fetch_traces_response_text,'Visible','off');
set(h.new_fetch_traces_response_popup,'Visible','off');
set(h.new_fetch_rfprocessing_taper_popup,'Visible','off');
set(h.new_fetch_rfprocessing_taper_text,'Visible','off');
set(h.new_fetch_rfprocessing_high_pass_edit,'Visible','off');
set(h.new_fetch_rfprocessing_filter_high_pass_text,'Visible','off');
set(h.new_fetch_rfprocessing_low_pass_edit,'Visible','off');
set(h.new_fetch_rfprocessing_filter_low_pass_text,'Visible','off');
set(h.new_fetch_rfprocessing_filter_order_text,'Visible','off');
set(h.new_fetch_rfprocessing_order_popup,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_edit,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_edit,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_text,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_text,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_text,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_popup,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_text,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_popup,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_edit,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_text,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_text,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_text,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_text,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_edit,'Visible','off');
set(h.new_fetch_rfprocessing_primary_choice_text,'Visible','off');
set(h.new_fetch_rfprocessing_secondary_choice_text,'Visible','off');
set(h.new_fetch_rfprocessing_taper_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_high_pass_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_low_pass_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_order_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_popup,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_2_popup,'Visible','off');
set(h.encryptedInfoPanel,'Visible','off');
set(h.encrypted_button,'Visible','off');

%--------------------------------------------------------------------------
% new_fetch_project_window_Callback
%
% This callback function turns off the "Startup" GUI and turns on the "New
% Project" GUI
%--------------------------------------------------------------------------
function new_project_fetch_window_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
% wane welcome off
set(h.welcome1_t,'visible','off')
set(h.welcome2_t,'visible','off')
set(h.welcome3_t,'visible','off')
set(h.welcome4_t,'visible','off')

% wax fetch objects on
set(h.new_fetch_title_t,'visible','on')
set(h.new_fetch_projdir_t,'visible','on')
set(h.new_fetch_projdir_e,'visible','on')
set(h.new_fetch_start_pb,'visible','on')
set(h.new_fetch_get_map_coords_pb,'visible','on')
set(h.new_fetch_lat_max_e,'visible','on');
set(h.new_fetch_lat_min_e,'visible','on');
set(h.new_fetch_lon_max_e,'visible','on');
set(h.new_fetch_lon_min_e,'visible','on');
set(h.new_fetch_get_stations_pb,'visible','on');
set(h.new_fetch_station_panel,'visible','on');
set(h.new_fetch_events_panel,'visible','on');
set(h.new_fetch_search_start_time_text,'visible','on');
set(h.new_fetch_search_end_time_text,'Visible','on');
set(h.new_fetch_start_year_pu,'Visible','on');
set(h.new_fetch_start_month_pu,'Visible','on');
set(h.new_fetch_start_day_pu,'Visible','on');
set(h.new_fetch_end_year_pu,'Visible','on');
set(h.new_fetch_end_month_pu,'Visible','on');
set(h.new_fetch_end_day_pu,'Visible','on');
set(h.new_fetch_search_magnitude_text,'visible','on');
set(h.new_fetch_min_mag_pu,'visible','on');
set(h.new_fetch_max_mag_pu,'visible','on');
set(h.new_fetch_event_mag_divider_t,'Visible','on');
set(h.new_fetch_search_distance_text,'Visible','on');
set(h.new_fetch_max_dist_e,'Visible','on');
set(h.new_fetch_min_dist_e,'Visible','on');
set(h.new_fetch_event_distance_divider_t,'Visible','on');
set(h.new_fetch_find_events_pb,'Visible','on');
set(h.new_fetch_max_depth_e,'Visible','on');
set(h.new_fetch_min_depth_e,'Visible','on');
set(h.new_fetch_search_depth_text,'Visible','on');
set(h.new_fetch_event_depth_divider_t,'Visible','on');
set(h.new_fetch_search_depth_text,'visible','on');
set(h.new_fetch_traces_panel,'visible','on');
%set(h.new_fetch_traces_timing_text,'Visible','On');
%set(h.new_fetch_traces_seconds_before_edit,'Visible','On');
%set(h.new_fetch_traces_phase_popup,'Visible','On');
set(h.new_fetch_traces_start_time_text,'Visible','On');
set(h.new_fetch_traces_prior_seconds_edit,'Visible','On');
set(h.new_fetch_traces_start_seconds_label,'Visible','On');
set(h.new_fetch_traces_start_before_or_after_popup,'Visible','on');
set(h.new_fetch_traces_start_phase_popup,'Visible','on');
set(h.new_fetch_traces_end_phase_popup,'Visible','on');
set(h.new_fetch_traces_end_time_text,'Visible','on');
set(h.new_fetch_traces_after_seconds_edit,'Visible','on');
set(h.new_fetch_traces_end_seconds_label,'Visible','on');
set(h.new_fetch_traces_end_before_or_after_popup,'Visible','on');
set(h.new_fetch_traces_end_phase_popup,'Visible','on');
set(h.new_fetch_traces_sample_rate_text,'Visible','on');
set(h.new_fetch_traces_sample_rate_popup,'Visible','on');
set(h.new_fetch_traces_sample_rate_label,'Visible','on');
set(h.new_fetch_traces_debug_button,'Visible','off');
set(h.easterEggPanel,'Visible','on');
set(h.new_fetch_rfprocessing_params_panel,'Visible','on');
set(h.new_fetch_traces_response_text,'Visible','on');
set(h.new_fetch_traces_response_popup,'Visible','on');
set(h.new_fetch_rfprocessing_taper_popup,'Visible','on');
set(h.new_fetch_rfprocessing_taper_text,'Visible','on');
set(h.new_fetch_rfprocessing_high_pass_edit,'Visible','on');
set(h.new_fetch_rfprocessing_filter_high_pass_text,'Visible','on');
set(h.new_fetch_rfprocessing_low_pass_edit,'Visible','on');
set(h.new_fetch_rfprocessing_filter_low_pass_text,'Visible','on');
set(h.new_fetch_rfprocessing_filter_order_text,'Visible','on');
set(h.new_fetch_rfprocessing_order_popup,'Visible','on');
set(h.new_fetch_rfprocessing_cut_before_phase_text,'Visible','on');
set(h.new_fetch_rfprocessing_cut_after_phase_text,'Visible','on');
set(h.new_fetch_rfprocessing_cut_after_phase_edit,'Visible','on');
set(h.new_fetch_rfprocessing_cut_before_phase_edit,'Visible','on');
set(h.new_fetch_rfprocessing_numerator_text,'Visible','on');
set(h.new_fetch_rfprocessing_numerator_popup,'Visible','on');
set(h.new_fetch_rfprocessing_denominator_text,'Visible','on');
set(h.new_fetch_rfprocessing_denominator_popup,'Visible','on');
set(h.new_fetch_rfprocessing_denominator_method_text,'Visible','on');
set(h.new_fetch_rfprocessing_denominator_method_popup,'Visible','on');
set(h.new_fetch_rfprocessing_deconvolution_method_text,'Visible','on');
set(h.new_fetch_rfprocessing_deconvolution_method_popup,'Visible','on');
set(h.new_fetch_rfprocessing_waterlevel_edit,'Visible','on');
set(h.new_fetch_rfprocessing_waterlevel_text,'Visible','on');
set(h.new_fetch_rfprocessing_max_iterations_text,'Visible','on');
set(h.new_fetch_rfprocessing_max_iterations_edit,'Visible','on');
set(h.new_fetch_rfprocessing_gaussian_edit,'Visible','on');
set(h.new_fetch_rfprocessing_gaussian_text,'Visible','on');
set(h.new_fetch_rfprocessing_min_error_text,'Visible','on');
set(h.new_fetch_rfprocessing_min_error_edit,'Visible','on');
set(h.new_fetch_rfprocessing_primary_choice_text,'Visible','on');
set(h.new_fetch_rfprocessing_secondary_choice_text,'Visible','on');
set(h.new_fetch_rfprocessing_taper_2_popup,'Visible','on');
set(h.new_fetch_rfprocessing_high_pass_2_edit,'Visible','on');
set(h.new_fetch_rfprocessing_low_pass_2_edit,'Visible','on');
set(h.new_fetch_rfprocessing_order_2_popup,'Visible','on');
set(h.new_fetch_rfprocessing_cut_after_phase_2_edit,'Visible','on');
set(h.new_fetch_rfprocessing_cut_before_phase_2_edit,'Visible','on');
set(h.new_fetch_rfprocessing_numerator_2_popup,'Visible','on');
set(h.new_fetch_rfprocessing_denominator_2_popup,'Visible','on');
set(h.new_fetch_rfprocessing_denominator_method_2_popup,'Visible','on');
set(h.new_fetch_rfprocessing_deconvolution_method_2_popup,'Visible','on');
set(h.new_fetch_rfprocessing_waterlevel_2_edit,'Visible','on');
set(h.new_fetch_rfprocessing_max_iterations_2_edit,'Visible','on');
set(h.new_fetch_rfprocessing_gaussian_2_edit,'Visible','on');
set(h.new_fetch_rfprocessing_min_error_2_edit,'Visible','on');
set(h.new_fetch_rfprocessing_incident_phase_text,'Visible','on');
set(h.new_fetch_rfprocessing_incident_phase_popup,'Visible','on');
set(h.new_fetch_rfprocessing_incident_phase_2_popup,'Visible','on');
set(h.encryptedInfoPanel,'Visible','on');
set(h.encrypted_button,'Visible','on');



% wane regular start off
set(h.new_title_t,'visible','off')
set(h.new_projdir_t,'visible','off')
set(h.new_projdir_e,'visible','off')
set(h.new_adddata_t,'visible','off')
for n = 1:10
    eval(['set(h.new_browse' sprintf('%02.0f',n) '_pb,''visible'',''off'')'])
    eval(['set(h.new_dataset' sprintf('%02.0f',n) '_e,''visible'',''off'')'])
end
set(h.new_start_pb,'visible','off')



%--------------------------------------------------------------------------
% new_project_setup_Callback
%
% This callback function runs the setup for a new project.  Then it turns
% off the "New Project" GUI and turns on the "FuncLab Command" GUI.
%--------------------------------------------------------------------------
function new_project_setup_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String','Please wait, loading in datasets and creating station and event tables',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow
ProjectDirectory = get(h.new_projdir_e,'String');
if ~strcmp(filesep,ProjectDirectory(end))
    ProjectDirectory = [ProjectDirectory, filesep];
end
assignin('base','ProjectDirectory',ProjectDirectory)
assignin('base','ProjectFile','Project.mat')
if isempty(ProjectDirectory)
    errordlg('Must type a full pathname for the project directory.') % 11/12/2011: DELETED ERRORDLG_KCE 
    return
end
if exist(ProjectDirectory,'dir')
    errordlg('Project directory already exists.  We do not want to overwrite this project, or any other information.') % 11/12/2011: DELETED ERRORDLG_KCE
    close(WaitGui)
    return
end
Trigger = 0;
for n = 1:10
    StrCheck = eval(['get(h.new_dataset' sprintf('%02.0f',n) '_e,''String'')']);
    if ~isempty(StrCheck)
        Trigger = 1;
    end
end
if Trigger == 0
    errordlg('You must specify at least one data directory to copy to a newly created project.') % 11/12/2011: DELETED ERRORDLG_KCE
    close(WaitGui)
    return
end
mkdir(ProjectDirectory)
mkdir([ProjectDirectory 'RAWDATA'])
Count = 0;
for n = 1:10
    Command = ['~isempty(get(h.new_dataset' sprintf('%02.0f',n) '_e,''String''))'];
    if eval(Command)
        Count = Count + 1;
        Command = ['get(h.new_dataset' sprintf('%02.0f',n) '_e,''String'')'];
        DataDirectory = eval(Command);
        DataDir{Count} = DataDirectory;
        DirName = strread(DataDirectory,'%s','delimiter',filesep);
        DirName = DirName{end};
        if ~exist([ProjectDirectory, 'RAWDATA', filesep, DirName],'dir')
            copyfile(DataDirectory,[ProjectDirectory, 'RAWDATA', filesep, DirName])
            [RecordMetadataStrings,RecordMetadataDoubles] = fl_add_new_data(ProjectDirectory,'Project.mat',DirName);
        else
            if Count > 1
                display('Directory ''DirName'' already exists in the project directory.')
                display('Cannot continue adding data, but will allow setup of previous directories.')
                DataDir(Count) = [];
                break
            else
                error('Directory ''DirName'' already exists in the project directory.  Cannot continue project setup.')
            end
        end
    end
end
if evalin('base','~exist(''FuncLabPreferences'',''var'')')
    FuncLabPreferences = fl_default_prefs(RecordMetadataDoubles);
else
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    if length(FuncLabPreferences) == 18
        FuncLabPreferences{19} = 'parula.cpt';
        FuncLabPreferences{20} = false;
        FuncLabPreferences{21} = '1.8.2';
    elseif length(FuncLabPreferences) == 19
        FuncLabPreferences{20} = false;
        FuncLabPreferences{21} = '1.8.2';
    elseif length(FuncLabPreferences) == 20
        FuncLabPreferences{21} = '1.8.2';
    end
end
if evalin('base','~exist(''TraceEditPreferences'',''var'')')
    te_default_prefs;
else
    TraceEditPreferences = evalin('base','TraceEditPreferences');
end
Tablemenu = {'Station Tables','RecordMetadata',2,3,'Stations: ','Records (Listed by Event)','Events: ','fl_record_fields','string';
    'Event Tables','RecordMetadata',3,2,'Events: ','Records (Listed by Station)','Stations: ','fl_record_fields','string'};
if exist([ProjectDirectory 'Project.mat'],'file')
	save([ProjectDirectory 'Project.mat'],'TraceEditPreferences','FuncLabPreferences','Tablemenu','-append')
else
	save([ProjectDirectory 'Project.mat'],'TraceEditPreferences','FuncLabPreferences','Tablemenu')
end

SetManagementCell = cell(1,6);
SetManagementCell{1,1} = 1:size(RecordMetadataDoubles,1);
SetManagementCell{1,2} = RecordMetadataStrings;
SetManagementCell{1,3} = RecordMetadataDoubles;
SetManagementCell{1,4} = Tablemenu;
SetManagementCell{1,5} = 'Base';
SetManagementCell{1,6} = [0.6 0 0];
assignin('base','SetManagementCell',SetManagementCell);
save([ProjectDirectory 'Project.mat'],'SetManagementCell','-append');
assignin('base','CurrentSubsetIndex',1);

fl_init_logfile([ProjectDirectory 'Logfile.txt'],DataDir)
fl_datainfo(ProjectDirectory,'Project.mat',RecordMetadataStrings,RecordMetadataDoubles)
set(h.project_t,'string',ProjectDirectory)
set(h.new_title_t,'visible','off')
set(h.new_projdir_t,'visible','off')
set(h.new_projdir_e,'visible','off')
set(h.new_adddata_t,'visible','off')
for n = 1:10
    eval(['set(h.new_browse' sprintf('%02.0f',n) '_pb,''visible'',''off'')'])
    eval(['set(h.new_dataset' sprintf('%02.0f',n) '_e,''visible'',''off'')'])
end
set(h.new_start_pb,'visible','off')
set(h.explorer_fm,'visible','on')
set(h.tablemenu_pu,'visible','on')
set(h.tablesinfo_t,'visible','on')
set(h.tables_ls,'visible','on')
set(h.records_t,'visible','on')
set(h.recordsinfo_t,'visible','on')
set(h.records_ls,'visible','on')
set(h.info_t,'visible','on')
set(h.info_ls,'visible','on')
set(h.new_m,'Enable','off')
set(h.new_fetch_m,'Enable','off')
set(h.load_m,'Enable','off')
set(h.add_m,'Enable','on')
set(h.param_m,'Enable','on')
set(h.log_m,'Enable','on')
set(h.close_m,'Enable','on')
set(h.manual_m,'Enable','on')
set(h.autoselect_m,'Enable','on')
set(h.autoall_m,'Enable','on')
set(h.im_te_m,'Enable','on')
set(h.tepref_m,'Enable','on')
set(h.recompute_rayp_m,'Enable','on')
set(h.seis_m,'Enable','on')
set(h.record_m,'Enable','on')
set(h.stacked_record_m,'Enable','on')
set(h.moveout_m,'Enable','on')
set(h.moveout_image_m,'Enable','on')
%set(h.origintime_image_m,'Enable','on')
%set(h.origintime_wiggles_m,'Enable','on')
set(h.rf_cross_section_time_m,'Enable','on');
set(h.rf_cross_section_depth_stack_m,'Enable','on');
set(h.baz_m,'Enable','on')
set(h.baz_image_m,'Enable','on')
set(h.datastats_m,'Enable','on')
set(h.stamap_m,'Enable','on')
set(h.evtmap_m,'Enable','on')
set(h.datadiagram_m,'Enable','on')
set(h.ex_stations_m,'Enable','on')
set(h.ex_events_m,'Enable','on')
set(h.ex_te_m,'Enable','on')
set(h.ex_rfs_m,'Enable','on')
set(h.PRF_to_depth_m,'Enable','on')
set(h.create_new_subset_m,'Enable','on')
set(h.off_dead_m,'Enable','on')
set(h.autoselect_rms_m,'Enable','on')
set(h.autoselect_rms_all_m,'Enable','on')
set(h.autoselect_vr_coh_m,'Enable','on')
set(h.autoselect_vr_coh_all_m,'Enable','on')

if isfield(h,'addons')
    addons = h.addons;
    for n = 1:length(addons)
        eval(['set(h.' addons{n} '_m,''Enable'',''on'')'])
    end
end
set(h.message_t,'visible','on')

assignin('base','RecordMetadataStrings',RecordMetadataStrings)
assignin('base','RecordMetadataDoubles',RecordMetadataDoubles)
assignin('base','Tablemenu',Tablemenu)
set(h.tablemenu_pu,'String',Tablemenu(:,1))
TableValue = 1;
set(h.tablemenu_pu,'Value',TableValue)
Tables = sort(unique(RecordMetadataStrings(:,2)));
set(h.tables_ls,'String',Tables)
set(h.tablesinfo_t,'String',[Tablemenu{TableValue,5} num2str(length(Tables))])
set(h.records_t,'String',Tablemenu{TableValue,6})
set(h.message_t,'String','Message:')
close(WaitGui)
tables_Callback

%--------------------------------------------------------------------------
% new_data_browse_Callback
%
% This callback function picks the dataset directories using a GUI to
% browse the directory structure.
%--------------------------------------------------------------------------
function new_data_browse_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
DataDirectory = uigetdir (pwd,'Select the Data Directory'); % 11/12/2011: DELETED UIGETDIR_KCE
Name = get(gcbo,'Tag');
n = str2num(Name(11:12));
if DataDirectory ~= 0
    eval(['set(h.new_dataset' sprintf('%02.0f',n) '_e,''String'',DataDirectory)'])
end



%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% load_project_Callback
%
% This callback function turns off the "Startup" GUI, brings up the "load
% file" GUI, and then starts the "FuncLab Command" GUI.
%--------------------------------------------------------------------------
function load_project_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
set(h.welcome1_t,'visible','off')
set(h.welcome2_t,'visible','off')
set(h.welcome3_t,'visible','off')
set(h.welcome4_t,'visible','off')
set(h.new_title_t,'visible','off')
set(h.new_projdir_t,'visible','off')
set(h.new_projdir_e,'visible','off')
set(h.new_adddata_t,'visible','off')
for n = 1:10
    eval(['set(h.new_browse' sprintf('%02.0f',n) '_pb,''visible'',''off'')'])
    eval(['set(h.new_dataset' sprintf('%02.0f',n) '_e,''visible'',''off'')'])
end
set(h.new_start_pb,'visible','off')
[Filename,DataDirectory] = uigetfile({'*.mat','MAT-files (*.mat)'},'Select Your Project File');  % 11/12/2011: DELETED UIGETFILE_KCE
if isnumeric(Filename)
    return
end

set(h.new_fetch_title_t,'visible','off')
set(h.new_fetch_projdir_t,'visible','off')
set(h.new_fetch_projdir_e,'visible','off')
set(h.new_fetch_start_pb,'visible','off')
set(h.new_fetch_get_map_coords_pb,'visible','off')
set(h.new_fetch_lat_max_e,'visible','off');
set(h.new_fetch_lat_min_e,'visible','off');
set(h.new_fetch_lon_max_e,'visible','off');
set(h.new_fetch_lon_min_e,'visible','off');
set(h.new_fetch_get_stations_pb,'visible','off');
set(h.new_fetch_station_panel,'visible','off');
set(h.new_fetch_events_panel,'Visible','off');
set(h.new_fetch_search_start_time_text,'Visible','off');
set(h.new_fetch_search_end_time_text,'Visible','off');
set(h.new_fetch_start_year_pu,'visible','off');
set(h.new_fetch_start_month_pu,'visible','off');
set(h.new_fetch_start_day_pu,'visible','off');
set(h.new_fetch_end_year_pu,'visible','off');
set(h.new_fetch_end_month_pu,'visible','off');
set(h.new_fetch_end_day_pu,'visible','off');
set(h.new_fetch_search_magnitude_text,'visible','off');
set(h.new_fetch_min_mag_pu,'visible','off');
set(h.new_fetch_max_mag_pu,'visible','off');
set(h.new_fetch_event_mag_divider_t,'Visible','off');
set(h.new_fetch_search_distance_text,'Visible','off');
set(h.new_fetch_max_dist_e,'Visible','off');
set(h.new_fetch_min_dist_e,'Visible','off');
set(h.new_fetch_event_distance_divider_t,'Visible','off');
set(h.new_fetch_find_events_pb,'Visible','off');
set(h.new_fetch_max_depth_e,'Visible','off');
set(h.new_fetch_min_depth_e,'Visible','off');
set(h.new_fetch_search_depth_text,'Visible','off');
set(h.new_fetch_event_depth_divider_t,'Visible','off');
set(h.new_fetch_search_depth_text,'visible','off');
set(h.new_fetch_traces_panel,'visible','off');
%set(h.new_fetch_traces_timing_text,'Visible','off');
%set(h.new_fetch_traces_seconds_before_edit,'Visible','off');
%set(h.new_fetch_traces_phase_popup,'Visible','off');
set(h.new_fetch_traces_start_phase_popup,'Visible','off');
set(h.new_fetch_traces_start_time_text,'Visible','off');
set(h.new_fetch_traces_prior_seconds_edit,'Visible','off');
set(h.new_fetch_traces_start_seconds_label,'Visible','off');
set(h.new_fetch_traces_start_before_or_after_popup,'Visible','off');
set(h.new_fetch_traces_end_phase_popup,'Visible','off');
set(h.new_fetch_traces_end_time_text,'Visible','off');
set(h.new_fetch_traces_after_seconds_edit,'Visible','off');
set(h.new_fetch_traces_end_seconds_label,'Visible','off');
set(h.new_fetch_traces_end_before_or_after_popup,'Visible','off');
set(h.new_fetch_traces_end_phase_popup,'Visible','off');
set(h.new_fetch_traces_sample_rate_text,'Visible','off');
set(h.new_fetch_traces_sample_rate_popup,'Visible','off');
set(h.new_fetch_traces_sample_rate_label,'Visible','off');
set(h.new_fetch_traces_debug_button,'Visible','off');
set(h.easterEggPanel,'Visible','off');
set(h.new_fetch_rfprocessing_params_panel,'Visible','off');
set(h.new_fetch_traces_response_text,'Visible','off');
set(h.new_fetch_traces_response_popup,'Visible','off');
set(h.new_fetch_rfprocessing_taper_popup,'Visible','off');
set(h.new_fetch_rfprocessing_taper_text,'Visible','off');
set(h.new_fetch_rfprocessing_high_pass_edit,'Visible','off');
set(h.new_fetch_rfprocessing_filter_high_pass_text,'Visible','off');
set(h.new_fetch_rfprocessing_low_pass_edit,'Visible','off');
set(h.new_fetch_rfprocessing_filter_low_pass_text,'Visible','off');
set(h.new_fetch_rfprocessing_filter_order_text,'Visible','off');
set(h.new_fetch_rfprocessing_order_popup,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_edit,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_edit,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_text,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_text,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_text,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_popup,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_text,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_popup,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_edit,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_text,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_text,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_text,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_text,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_edit,'Visible','off');
set(h.new_fetch_rfprocessing_primary_choice_text,'Visible','off');
set(h.new_fetch_rfprocessing_secondary_choice_text,'Visible','off');
set(h.new_fetch_rfprocessing_taper_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_high_pass_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_low_pass_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_order_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_popup,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_2_popup,'Visible','off');
set(h.encryptedInfoPanel,'Visible','off');
set(h.encrypted_button,'Visible','off');

set(h.project_t,'string',DataDirectory)
assignin('base','ProjectDirectory',DataDirectory)
assignin('base','ProjectFile',Filename)
set(h.welcome1_t,'visible','off')
set(h.welcome2_t,'visible','off')
set(h.welcome3_t,'visible','off')
set(h.welcome4_t,'visible','off')
set(h.explorer_fm,'visible','on')
set(h.tablemenu_pu,'visible','on')
set(h.tablesinfo_t,'visible','on')
set(h.tables_ls,'visible','on')
set(h.records_t,'visible','on')
set(h.recordsinfo_t,'visible','on') 
set(h.records_ls,'visible','on')
set(h.info_t,'visible','on')
set(h.info_ls,'visible','on')
set(h.new_m,'Enable','off')
set(h.new_fetch_m,'Enable','off')
set(h.load_m,'Enable','off')
set(h.add_m,'Enable','on')
set(h.param_m,'Enable','on')
set(h.log_m,'Enable','on')
set(h.close_m,'Enable','on')
set(h.manual_m,'Enable','on')
set(h.autoselect_m,'Enable','on')
set(h.autoall_m,'Enable','on')
set(h.im_te_m,'Enable','on')
set(h.tepref_m,'Enable','on')
set(h.recompute_rayp_m,'Enable','on')
set(h.seis_m,'Enable','on')
set(h.record_m,'Enable','on')
set(h.stacked_record_m,'Enable','on')
set(h.moveout_m,'Enable','on')
set(h.moveout_image_m,'Enable','on')
%set(h.origintime_image_m,'Enable','on')
%set(h.origintime_wiggles_m,'Enable','on')
set(h.rf_cross_section_time_m,'Enable','on');
set(h.rf_cross_section_depth_stack_m,'Enable','on');
set(h.baz_m,'Enable','on')
set(h.baz_image_m,'Enable','on')
set(h.datastats_m,'Enable','on')
set(h.stamap_m,'Enable','on')
set(h.evtmap_m,'Enable','on')
set(h.datadiagram_m,'Enable','on')
set(h.ex_stations_m,'Enable','on')
set(h.ex_events_m,'Enable','on')
set(h.ex_te_m,'Enable','on')
set(h.ex_rfs_m,'Enable','on')
set(h.PRF_to_depth_m,'Enable','on')
set(h.create_new_subset_m,'Enable','on')
set(h.off_dead_m,'Enable','on')
set(h.autoselect_rms_m,'Enable','on')
set(h.autoselect_rms_all_m,'Enable','on')
set(h.autoselect_vr_coh_m,'Enable','on')
set(h.autoselect_vr_coh_all_m,'Enable','on')
if isfield(h,'addons')
    addons = h.addons;
    for n = 1:length(addons)
        eval(['set(h.' addons{n} '_m,''Enable'',''on'')'])
    end
end
set(h.message_t,'visible','on')
set(h.message_t,'String','Message: Loading Station Tables, please wait ...')
drawnow
%load([DataDirectory Filename],'RecordMetadataStrings','RecordMetadataDoubles','Tablemenu')
load([DataDirectory Filename]);
ProjectVariables = whos('-file',[DataDirectory Filename]);
for idx=1:size(ProjectVariables,1)
    assignin('base',ProjectVariables(idx).name,eval(ProjectVariables(idx).name));
end
if exist('SetManagementCell','var')
    RecordMetadataStrings = SetManagementCell{1,2};
    RecordMetadataDoubles = SetManagementCell{1,3};
    Tablemenu = SetManagementCell{1,4};
end
assignin('base','RecordMetadataStrings',RecordMetadataStrings)
assignin('base','RecordMetadataDoubles',RecordMetadataDoubles)
assignin('base','Tablemenu',Tablemenu)
set(h.tablemenu_pu,'String',Tablemenu(:,1))
TableValue = 1;
set(h.tablemenu_pu,'Value',TableValue)
drawnow
if ~strcmp(Tablemenu{TableValue,2},'RecordMetadata')
    load([DataDirectory Filename],[Tablemenu{TableValue,2} 'Strings'],[Tablemenu{TableValue,2} 'Doubles'])
    Tables = eval(Tablemenu{TableValue,2});
else
    switch TableValue
        case 1
            Tables = sort(unique(RecordMetadataStrings(:,2)));
        case 2
            Tables = sort(unique(RecordMetadataStrings(:,3)));
    end 
end
set(h.tables_ls,'String',Tables)
set(h.tablesinfo_t,'String',[Tablemenu{TableValue,5} num2str(length(Tables))])
set(h.records_t,'String',Tablemenu{TableValue,6})
set(h.message_t,'String','Message:')
load([DataDirectory Filename])
if exist('ThreeDRayInfoFile','var')
    set(h.ray_diagram_m,'Enable','on')
    set(h.ray_diagram_all_m,'Enable','on')
    set(h.rf_cross_section_depth_m,'Enable','on')
    set(h.rf_cross_section_2d_ccp_m,'Enable','on');
end
if exist('HkMetadataStrings','var')
    set(h.ex_hk_res_m,'Enable','on')
end
if ~exist('SetManagementCell','var')
    SetManagementCell = cell(1,6);
    SetManagementCell{1,1} = 1:size(RecordMetadataDoubles,1);
    SetManagementCell{1,2} = RecordMetadataStrings;
    SetManagementCell{1,3} = RecordMetadataDoubles;
    SetManagementCell{1,4} = Tablemenu;
    SetManagementCell{1,5} = 'Base';
    SetManagementCell{1,6} = [0.6 0 0];
end
assignin('base','SetManagementCell',SetManagementCell);
assignin('base','CurrentSubsetIndex',1);
save([DataDirectory Filename],'SetManagementCell','-append');
if size(SetManagementCell,1) > 1;
    set(h.delete_subset_m,'Enable','on')
    set(h.choose_subset_m,'Enable','on')
end
for iset = 1:size(SetManagementCell,1)
    fl_datainfo(DataDirectory,Filename,SetManagementCell{iset,2}, SetManagementCell{iset,3}, iset);
end


tables_Callback

%--------------------------------------------------------------------------
% tablemenu_Callback
%
% This callback function displays the chosen tables in the left-most
% listbox of the GUI.
%--------------------------------------------------------------------------
function tablemenu_Callback (cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
SetManagementCell  = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
Value = get(h.tablemenu_pu,'Value');
Choice = get(h.tablemenu_pu,'String');
Choice = Choice{Value};
Tablemenu = evalin('base','Tablemenu');
if strcmp(Tablemenu{Value,2},'RecordMetadata')
    MetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
    MetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
else
    MetadataCell = evalin('base',[Tablemenu{Value,2} 'Cell']);
    MetadataStrings = MetadataCell{CurrentSubsetIndex,1};
    MetadataDoubles = MetadataCell{CurrentSubsetIndex,2};  
    assignin('base',[Tablemenu{Value,2} 'Strings'],MetadataStrings);
    assignin('base',[Tablemenu{Value,2} 'Doubles'],MetadataDoubles);
end
Tables = sort(unique(MetadataStrings(:,Tablemenu{Value,3})));
set(h.tables_ls,'String','');
set(h.tables_ls,'Value',1);
set(h.records_ls,'String','');
set(h.records_ls,'Value',1)
set(h.info_ls,'String','');
set(h.info_ls,'Value',1)
set(h.tables_ls,'String',Tables)
set(h.tablesinfo_t,'String',[Tablemenu{Value,5} num2str(length(Tables))])
set(h.records_t,'String',Tablemenu{Value,6})
set(h.record_m ,'Enable','on')
set(h.stacked_record_m,'Enable','on')
set(h.message_t,'String',['Message: Loading ' Choice ', please wait ...'])
drawnow
tables_Callback
set(h.message_t,'String',['Message: ' Choice ' loaded into workspace.'])

%--------------------------------------------------------------------------
% tables_Callback
%
% This callback function controls the display of records in the middle
% listbox for the selected table in the "Tables" listbox.
%--------------------------------------------------------------------------
function tables_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
set(h.records_ls,'String','');
set(h.records_ls,'Value',1)
Value = get(h.tablemenu_pu,'Value');
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
Tablemenu = SetManagementCell{CurrentSubsetIndex, 4};
assignin('base','Tablemenu',Tablemenu);
% Available tables based on pre-processing
AvailableTables = cell(size(Tablemenu,1),1);
for idx=1:size(Tablemenu,1)
    AvailableTables{idx} = Tablemenu{idx};
end
%Tablemenu = evalin('base','Tablemenu');
TableIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
Table = TableList{TableIndex};
if strcmp(Tablemenu{Value,2},'RecordMetadata')
    MetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
    MetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
else
    MetadataCell = evalin('base',[Tablemenu{Value,2} 'Cell']);
    MetadataStrings = MetadataCell{CurrentSubsetIndex,1};
    MetadataDoubles = MetadataCell{CurrentSubsetIndex,2};
end
%MetadataStrings = evalin('base',[Tablemenu{Value,2} 'Strings']);
%MetadataDoubles = evalin('base',[Tablemenu{Value,2} 'Doubles']);
Tablemenu = evalin('base','Tablemenu');
in = strmatch(Table,MetadataStrings(:,Tablemenu{Value,3}),'exact');
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
set(h.recordsinfo_t,'String',{[Tablemenu{Value,7} num2str(length(RecordList))],['Active: ' num2str(Active)]})
records_Callback

%--------------------------------------------------------------------------
% records_Callback
%
% This callback function controls the display of information, shown on the
% right, for selected record in the "Records" listbox.
%--------------------------------------------------------------------------
function records_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
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

%--------------------------------------------------------------------------
% turnon_table_Callback
%
% This callback function sets the "Status" field to "On" using the context
% menu.
%--------------------------------------------------------------------------
function turnon_table_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
CurrentIndices = evalin('base','CurrentIndices');
Value = get(h.tablemenu_pu,'Value');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
Table = TableList{SelectedIndex};
if Value == 1 || Value == 2
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    for n = 1:size(CurrentRecords,1)
        CurrentRecords{n,4} = 1;
        CurrentRecords{n,5} = 1;
        RecordMetadataDoubles(CurrentIndices(n),1) = 1;
        RecordMetadataDoubles(CurrentIndices(n),2) = 1;
    end
    assignin('base','CurrentRecords',CurrentRecords);
    assignin('base','RecordMetadataDoubles',RecordMetadataDoubles);
    save([ProjectDirectory ProjectFile],'RecordMetadataDoubles','-append')
    fl_datainfo(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles)
    LogFile = [ProjectDirectory 'Logfile.txt'];
    CTime = clock;
    NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Trace Editing: Turned on all records for station/event %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6),Table);
    fl_edit_logfile(LogFile,NewLog)
    Message = ['Message: Turned on all records for station/event ' Table '.'];
    set(h.message_t,'String',Message);
    set(h.tables_ls,'Value',SelectedIndex)
    set(h.records_ls,'Value',1)
    tables_Callback
else
    Message = ['Message: Cannot trace edit ' Table '.'];
    set(h.message_t,'String',Message);
end

%--------------------------------------------------------------------------
% turnoff_table_Callback
%
% This callback function sets the "Status" field to "Off" using the context
% menu.
%--------------------------------------------------------------------------
function turnoff_table_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
CurrentIndices = evalin('base','CurrentIndices');
Value = get(h.tablemenu_pu,'Value');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
Table = TableList{SelectedIndex};
if Value == 1 || Value == 2
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    for n = 1:size(CurrentRecords,1)
        CurrentRecords{n,4} = 1;
        CurrentRecords{n,5} = 0;
        RecordMetadataDoubles(CurrentIndices(n),1) = 1;
        RecordMetadataDoubles(CurrentIndices(n),2) = 0;
    end
    assignin('base','CurrentRecords',CurrentRecords);
    assignin('base','RecordMetadataDoubles',RecordMetadataDoubles);
    save([ProjectDirectory ProjectFile],'RecordMetadataDoubles','-append')
    fl_datainfo(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles)
    LogFile = [ProjectDirectory 'Logfile.txt'];
    CTime = clock;
    NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Trace Editing: Turned off all records for station/event %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6),Table);
    fl_edit_logfile(LogFile,NewLog)
    Message = ['Message: Turned off all records for station/event ' Table '.'];
    set(h.message_t,'String',Message);
    set(h.tables_ls,'Value',SelectedIndex)
    set(h.records_ls,'Value',1)
    tables_Callback
else
    Message = ['Message: Cannot trace edit ' Table '.'];
    set(h.message_t,'String',Message);
end

%--------------------------------------------------------------------------
% turnon_record_Callback
%
% This callback function sets the "Status" field to "On" using the context
% menu.
%--------------------------------------------------------------------------
function turnon_record_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
CurrentIndices = evalin('base','CurrentIndices');
Value = get(h.tablemenu_pu,'Value');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
Table = TableList{SelectedIndex};
RecordIn = get(h.records_ls,'Value');
RecordList = get(h.records_ls,'String');
Record = RecordList{RecordIn};
if Value == 1 || Value == 2
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    CurrentRecords{RecordIn,4} = 1;
    CurrentRecords{RecordIn,5} = 1;
    RecordMetadataDoubles(CurrentIndices(RecordIn),1) = 1;
    RecordMetadataDoubles(CurrentIndices(RecordIn),2) = 1;
    assignin('base','CurrentRecords',CurrentRecords);
    assignin('base','RecordMetadataDoubles',RecordMetadataDoubles);
    save([ProjectDirectory ProjectFile],'RecordMetadataDoubles','-append')
    fl_datainfo(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles)
    LogFile = [ProjectDirectory 'Logfile.txt'];
    CTime = clock;
    NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Trace Editing: Turned on record %s - %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6),Table,Record);
    fl_edit_logfile(LogFile,NewLog)
    Message = ['Message: Turned on record ' Table ' - ' Record '.'];
    set(h.message_t,'String',Message);
    set(h.tables_ls,'Value',SelectedIndex)
    set(h.records_ls,'Value',1)
    tables_Callback
else
    Message = ['Message: Cannot trace edit ' Table '/' Record '.'];
    set(h.message_t,'String',Message);
end

%--------------------------------------------------------------------------
% turnoff_record_Callback
%
% This callback function sets the "Status" field to "Off" using the context
% menu.
%--------------------------------------------------------------------------
function turnoff_record_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
CurrentIndices = evalin('base','CurrentIndices');
Value = get(h.tablemenu_pu,'Value');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
Table = TableList{SelectedIndex};
RecordIn = get(h.records_ls,'Value');
RecordList = get(h.records_ls,'String');
Record = RecordList{RecordIn};
if Value == 1 || Value == 2
    RecordMetadataStrings = evalin('base','RecordMetadataStrings');
    RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
    CurrentRecords{RecordIn,4} = 1;
    CurrentRecords{RecordIn,5} = 1;
    RecordMetadataDoubles(CurrentIndices(RecordIn),1) = 1;
    RecordMetadataDoubles(CurrentIndices(RecordIn),2) = 1;
    assignin('base','CurrentRecords',CurrentRecords);
    assignin('base','RecordMetadataDoubles',RecordMetadataDoubles);
    save([ProjectDirectory ProjectFile],'RecordMetadataDoubles','-append')
    fl_datainfo(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles)
    LogFile = [ProjectDirectory 'Logfile.txt'];
    CTime = clock;
    NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Trace Editing: Turned off record %s - %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6),Table,Record);
    fl_edit_logfile(LogFile,NewLog)
    Message = ['Message: Turned off record ' Table ' - ' Record '.'];
    set(h.message_t,'String',Message);
    set(h.tables_ls,'Value',SelectedIndex)
    set(h.records_ls,'Value',1)
    tables_Callback
else
    Message = ['Message: Cannot trace edit ' Table '/' Record '.'];
    set(h.message_t,'String',Message);
end

%--------------------------------------------------------------------------
% fl_pref_Callback
%
% This callback function opens the FuncLab Parameter File for viewing and
% editing.
%--------------------------------------------------------------------------
function fl_pref_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
Choice = get(h.project_t,'string');
if strcmp(Choice,'')
        FuncLabPreferences = fl_default_prefs(RecordMetadataDoubles);
    fl_preferences_gui('','',FuncLabPreferences);
else
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    load([ProjectDirectory ProjectFile],'FuncLabPreferences')
    H = fl_preferences_gui(ProjectDirectory,ProjectFile,FuncLabPreferences);
    evalin('base','clear FuncLabPreferences')
    uiwait(H.dialogbox)
    Message = get(0,'userdata');
    if ~strcmp(Message,'Cancelled');
        set(h.message_t,'String',Message);
    end
end

%--------------------------------------------------------------------------
% te_pref_Callback
%
% This callback function opens the trace editing preferences
%--------------------------------------------------------------------------
function te_pref_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
Choice = get(h.project_t,'string');
if strcmp(Choice,'')
    te_default_prefs;
    te_preferences_gui('','',TraceEditPreferences);
else
    ProjectDirectory = evalin('base','ProjectDirectory');
    ProjectFile = evalin('base','ProjectFile');
    load([ProjectDirectory ProjectFile],'TraceEditPreferences')
    H = te_preferences_gui(ProjectDirectory,ProjectFile,TraceEditPreferences);
    evalin('base','clear TraceEditPreferences')
    uiwait(H.dialogbox)
    Message = get(0,'userdata');
    if ~strcmp(Message,'Cancelled');
        set(h.message_t,'String',Message);
    end
end

%--------------------------------------------------------------------------
% log_Callback
%
% This callback function opens the log text file for viewing.
%--------------------------------------------------------------------------
function log_Callback(cbo,eventdata,handles)
ProjectDirectory = evalin('base','ProjectDirectory');
LogFile = [ProjectDirectory 'Logfile.txt'];
fl_log_gui(LogFile);

%--------------------------------------------------------------------------
% add_data_Callback
%
% This callback function opens a GUI to add new data to the dataset.
%--------------------------------------------------------------------------
function add_data_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
H = fl_add_data_gui(ProjectDirectory,ProjectFile);
uiwait(H.dialogbox)
Message = get(0,'userdata');
if strcmp(Message,'Cancelled');
    return;
end
set(h.tablemenu_pu,'Value',1)
set(h.tables_ls,'Value',1)
set(h.records_ls,'Value',1)
tablemenu_Callback
set(h.message_t,'String',Message)

%--------------------------------------------------------------------------
% datastats_Callback
%
% This callback function lists the dataset statistical information in a
% GUI.
%--------------------------------------------------------------------------
function datastats_Callback(cbo,eventdata,handles)
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
load([ProjectDirectory ProjectFile],'Datastats')
Datastats = Datastats{CurrentSubsetIndex};
for n = 1:size(Datastats,1)
    L(n) = length(Datastats{n,1});
end
MaxL = max(L) + 2;
for n = 1:size(Datastats,1)
    DataField = blanks(MaxL);
    DataField(1:length(Datastats{n,1})+1) = [Datastats{n,1} ':'];
    DataString{n} = [DataField num2str(Datastats{n,2})];
end
fl_datastats_gui(DataString);

%--------------------------------------------------------------------------
% te_manual_Callback
%
% This callback function brings up the manual trace editing GUI.
%--------------------------------------------------------------------------
function te_manual_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
CurrentIndices = evalin('base','CurrentIndices');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
Table = TableList{SelectedIndex};
%H = struct('figure',[],'cmenu',[],'plot',[],'turnon',[],'turnoff',[],'mag',[],'dist',[],'baz',[],'rayp',[],'radfit',[],'transfit',[],'phandle',[],'nhandle',[],'lhandle',[],...
%    'checkhandles',[],'sliderhandle',[],'closebutton',[],'cancelbutton',[],'sortbytext',[],'sortbypopup',[],'reversesorttext',[],'reversesortcheckbox',[],'sortbutton',[],...
%    'deselectAllButton',[],'selectAllButton',[]);
H.figure = figure('Name','Receiver Function Trace Editing GUI','NumberTitle','off','Units','pixels','WindowStyle','normal','Tag','TraceEditGui',...
    'Position',[0 0 1024 720],'Renderer','painters','BackingStore','off','MenuBar','none','Doublebuffer','on','CreateFcn',{@movegui_kce,'center'});
fl_traceedit_gui(ProjectDirectory,ProjectFile,CurrentRecords,CurrentIndices,Table,H);
uiwait(H.figure)
Message = get(0,'userdata');
if ~strcmp(Message,'Cancelled'); set(h.message_t,'String',Message); end
set(h.tables_ls,'Value',SelectedIndex)
set(h.records_ls,'Value',1)
tables_Callback

%--------------------------------------------------------------------------
% te_auto_table_Callback
%
% This callback function performs automated trace editing on the selected
% table (either a station or an event table).
%--------------------------------------------------------------------------
function te_auto_table_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
Answer = questdlg('Auto trace editing will erase any previous edits.  Are you sure you want to continue?','','Yes','No','Yes'); % 11/12/2011: DELETED QUESTDLG_KCE
if strcmp(Answer,'No'); return; end
tic
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
% 05/01/2011: MAJOR CODE FIX TO PROPERLY CALL THE NEWLY ADDED AUTO TRACE
% EDITING SCRIPT
CurrentRecords = evalin('base','CurrentRecords');
CurrentIndices = evalin('base','CurrentIndices');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
Table = TableList{SelectedIndex};
fl_traceedit_auto(ProjectDirectory,ProjectFile,CurrentRecords,CurrentIndices,Table);
t_temp = toc;
SecTime = num2str((t_temp),'%.2f');
MinTime = num2str((t_temp)/60,'%.2f');
set(h.message_t,'String',['Message: Auto trace edited ' Table '.  Automatic edits took ' SecTime ' seconds (or ' MinTime ' minutes).'])
set(h.tables_ls,'Value',SelectedIndex) % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
set(h.records_ls,'Value',1) % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
tables_Callback % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES

%--------------------------------------------------------------------------
% te_auto_all_Callback
%
% This callback function performs automated trace editing on all the tables
% in the dataset.
%--------------------------------------------------------------------------
function te_auto_all_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
Answer = questdlg('Auto trace editing will erase any previous edits.  Are you sure you want to continue?','','Yes','No','Yes'); % 11/12/2011: DELETED QUESTDLG_KCE
if strcmp(Answer,'No'); return; end
tic
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
SelectedIndex = get(h.tables_ls,'Value'); % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_traceedit_auto(ProjectDirectory,ProjectFile); % 11/18/2011: CALLS THE INPUTS PROJECT DIRECTORY AND PROJECT FILE
t_temp = toc;
SecTime = num2str((t_temp),'%.2f');
MinTime = num2str((t_temp)/60,'%.2f');
set(h.message_t,'String',['Message: Auto trace edited ALL TABLES.  Automatic edits took ' SecTime ' seconds (or ' MinTime ' minutes).'])
set(h.tables_ls,'Value',SelectedIndex) % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
set(h.records_ls,'Value',1) % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
tables_Callback % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES


%--------------------------------------------------------------------------
% te_auto_rms_table_Callback
%
% This callback function performs automated trace editing on the selected
% table (either a station or an event table).
%--------------------------------------------------------------------------
function te_auto_rms_table_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
% This version does not overwrite previous edits.
Answer = questdlg('This version does not overwrite previous edits. Are you sure you want to continue?','','Yes','No','Yes'); % 11/12/2011: DELETED QUESTDLG_KCE
if strcmp(Answer,'No'); return; end
tic
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
% 05/01/2011: MAJOR CODE FIX TO PROPERLY CALL THE NEWLY ADDED AUTO TRACE
% EDITING SCRIPT
CurrentRecords = evalin('base','CurrentRecords');
CurrentIndices = evalin('base','CurrentIndices');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
Table = TableList{SelectedIndex};
fl_traceedit_auto_rms(ProjectDirectory,ProjectFile,CurrentRecords,CurrentIndices,Table);
t_temp = toc;
SecTime = num2str((t_temp),'%.2f');
MinTime = num2str((t_temp)/60,'%.2f');
set(h.message_t,'String',['Message: Auto trace edited ' Table '.  Automatic edits took ' SecTime ' seconds (or ' MinTime ' minutes).'])
set(h.tables_ls,'Value',SelectedIndex) % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
set(h.records_ls,'Value',1) % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
tables_Callback % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES

%--------------------------------------------------------------------------
% te_auto_rms_all_Callback
%
% This callback function performs automated trace editing on all the tables
% in the dataset.
%--------------------------------------------------------------------------
function te_auto_rms_all_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
% This version does not overwrite previous edits.
Answer = questdlg('This version does not overwrite previous edits. Are you sure you want to continue?','','Yes','No','Yes'); % 11/12/2011: DELETED QUESTDLG_KCE
if strcmp(Answer,'No'); return; end
tic
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
SelectedIndex = get(h.tables_ls,'Value'); % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_traceedit_auto_rms(ProjectDirectory,ProjectFile); % 11/18/2011: CALLS THE INPUTS PROJECT DIRECTORY AND PROJECT FILE
t_temp = toc;
SecTime = num2str((t_temp),'%.2f');
MinTime = num2str((t_temp)/60,'%.2f');
set(h.message_t,'String',['Message: Auto trace edited ALL TABLES.  Automatic edits took ' SecTime ' seconds (or ' MinTime ' minutes).'])
set(h.tables_ls,'Value',SelectedIndex) % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
set(h.records_ls,'Value',1) % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
tables_Callback % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES


%--------------------------------------------------------------------------
% te_auto_vr_coh_table_Callback
%
% This callback function performs automated trace editing on the selected
% table (either a station or an event table).
%--------------------------------------------------------------------------
function te_auto_vr_coh_table_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
% This version does not overwrite previous edits.
Answer = questdlg('This will overwrite previous edits. Are you sure you want to continue?','','Yes','No','Yes'); % 11/12/2011: DELETED QUESTDLG_KCE
if strcmp(Answer,'No'); return; end
tic
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
% 05/01/2011: MAJOR CODE FIX TO PROPERLY CALL THE NEWLY ADDED AUTO TRACE
% EDITING SCRIPT
CurrentRecords = evalin('base','CurrentRecords');
CurrentIndices = evalin('base','CurrentIndices');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
Table = TableList{SelectedIndex};
fl_traceedit_auto_vr_coh(ProjectDirectory,ProjectFile,CurrentRecords,CurrentIndices,Table);
t_temp = toc;
SecTime = num2str((t_temp),'%.2f');
MinTime = num2str((t_temp)/60,'%.2f');
set(h.message_t,'String',['Message: Auto trace edited ' Table '.  Automatic edits took ' SecTime ' seconds (or ' MinTime ' minutes).'])
set(h.tables_ls,'Value',SelectedIndex) % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
set(h.records_ls,'Value',1) % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
tables_Callback % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES

%--------------------------------------------------------------------------
% te_auto_rms_all_Callback
%
% This callback function performs automated trace editing on all the tables
% in the dataset.
%--------------------------------------------------------------------------
function te_auto_vr_coh_all_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
% This version does not overwrite previous edits.
Answer = questdlg('This will overwrite previous edits. Are you sure you want to continue?','','Yes','No','Yes'); % 11/12/2011: DELETED QUESTDLG_KCE
if strcmp(Answer,'No'); return; end
tic
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
SelectedIndex = get(h.tables_ls,'Value'); % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_traceedit_auto_vr_coh(ProjectDirectory,ProjectFile); % 11/18/2011: CALLS THE INPUTS PROJECT DIRECTORY AND PROJECT FILE
t_temp = toc;
SecTime = num2str((t_temp),'%.2f');
MinTime = num2str((t_temp)/60,'%.2f');
set(h.message_t,'String',['Message: Auto trace edited ALL TABLES.  Automatic edits took ' SecTime ' seconds (or ' MinTime ' minutes).'])
set(h.tables_ls,'Value',SelectedIndex) % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
set(h.records_ls,'Value',1) % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES
tables_Callback % 11/18/2011: ADDED THIS LINE TO REFRESH TABLES



%--------------------------------------------------------------------------
% view_record_Callback
%
% This callback function is for plotting the radial, transverse, and
% vertical seismograms, as well as the radial and transverse receiver
% functions for the selected record in the selected table.
%--------------------------------------------------------------------------
function view_record_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
SelectedIndex = get(h.records_ls,'Value');
Record = CurrentRecords(SelectedIndex,:)';
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_view_record(ProjectDirectory,Record,FuncLabPreferences);

%--------------------------------------------------------------------------
% view_record_section_Callback
%
% This callback function is for plotting the record section (time vs.
% distance) with radial, transverse, and vertical seismograms, as well as
% the radial and transverse receiver functions for the selected event
% table.
%--------------------------------------------------------------------------
function view_record_section_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
TableName = TableList{SelectedIndex};
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_view_record_section(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences);

%--------------------------------------------------------------------------
% view_stacked_records_Callback
%
% This callback function is for plotting the stacked records of the radial,
% transverse, and vertical seismograms, as well as the radial and
% transverse receiver functions for the selected event table.
%--------------------------------------------------------------------------
function view_stacked_records_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
TableName = TableList{SelectedIndex};
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_view_stacked_records(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences);

%--------------------------------------------------------------------------
% view_moveout_Callback
%
% This callback function is for plotting the radial and transverse
% receiver functions as a function of ray parameter.
%--------------------------------------------------------------------------
function view_moveout_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
TableName = TableList{SelectedIndex};
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_view_moveout(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences);

%--------------------------------------------------------------------------
% view_moveout_image_Callback
%
% This callback function is for plotting the the stacked receiver function
% image based on ray parameter binning.
%--------------------------------------------------------------------------
function view_moveout_image_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
TableName = TableList{SelectedIndex};
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_view_moveout_image(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences);


%--------------------------------------------------------------------------
% view_origintime_image_Callback
%
% This callback function is for plotting the stacked receiver function
% image based on origin time binning.
%--------------------------------------------------------------------------
function view_origintime_image_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
TableName = TableList{SelectedIndex};
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_view_origintime_image(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences);


%--------------------------------------------------------------------------
% view_origintime_wiggles_Callback
%
% This callback function is for plotting the receiver function
% image based on origin time binning.
%--------------------------------------------------------------------------
function view_origintime_wiggles_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
TableName = TableList{SelectedIndex};
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_view_origintime_wiggles(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences);


%--------------------------------------------------------------------------
% view_baz_Callback
%
% This callback function is for plotting the radial and transverse
% receiver functions as a function of backazimuth.
%--------------------------------------------------------------------------
function view_baz_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
TableName = TableList{SelectedIndex};
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_view_baz(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences);

%--------------------------------------------------------------------------
% view_baz_image_Callback
%
% This callback function is for plotting the stacked receiver function
% image based on backazimuthal binning.
%--------------------------------------------------------------------------
function view_baz_image_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
TableName = TableList{SelectedIndex};
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_view_baz_image(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences);


%--------------------------------------------------------------------------
% view_rf_cross_section_time_Callback
%
% This function creates an image of receiver functions projected along some
% line. Allows user to select line visually and then selects receiver
% functions to show along the profile. This version is to plot the vertical
% axis in time and a separate function can be used if they've been depth
% mapped.
%--------------------------------------------------------------------------
function view_rf_cross_section_time_Callback(cbo, eventdata, handles)
h=guidata(gcbf);
ProjectDirectory =  evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
%RecordMetadataStrings =  evalin('base','RecordMetadataStrings');
%RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
%FuncLabPreferences = evalin('base','FuncLabPreferences');
fl_view_rf_cross_section(ProjectDirectory,ProjectFile,FuncLabPreferences)

%--------------------------------------------------------------------------
% view_rf_cross_section_2d_ccp_Callback
%
% This function creates an image of receiver functions projected along some
% line. Allows user to select line visually and then selects receiver
% functions to show along the profile. This version is to plot the vertical
% axis in time and a separate function can be used if they've been depth
% mapped.
%--------------------------------------------------------------------------
function view_rf_cross_section_2d_ccp_Callback(cbo, eventdata, handles)
h=guidata(gcbf);
ProjectDirectory =  evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
%RecordMetadataStrings =  evalin('base','RecordMetadataStrings');
%RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
%FuncLabPreferences = evalin('base','FuncLabPreferences');
fl_view_rf_cross_section_2D_ccp(ProjectDirectory,ProjectFile,FuncLabPreferences)



%--------------------------------------------------------------------------
% view_rf_cross_section_depth_stack_Callback
%
% This function creates an image of receiver functions projected along some
% line. Allows user to select line visually and then selects receiver
% functions to show along the profile. This version is to plot the vertical
% axis in depth
%--------------------------------------------------------------------------
function view_rf_cross_section_depth_stack_Callback(cbo, eventdata, handles)
h=guidata(gcbf);
ProjectDirectory =  evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
%RecordMetadataStrings =  evalin('base','RecordMetadataStrings');
%RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
%FuncLabPreferences = evalin('base','FuncLabPreferences');
fl_view_rf_cross_section_depth_stack(ProjectDirectory,ProjectFile,FuncLabPreferences)

%--------------------------------------------------------------------------
% view_rf_cross_section_depth_Callback
%
% This function creates an image of receiver functions projected along some
% line. Allows user to select line visually and then selects receiver
% functions to show along the profile. This version is to plot the vertical
% axis in depth and is only available if the user has already run the depth
% mapping. 
%--------------------------------------------------------------------------
function view_rf_cross_section_depth_Callback(cbo, eventdata, handles)
h=guidata(gcbf);
ProjectDirectory =  evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
%RecordMetadataStrings =  evalin('base','RecordMetadataStrings');
%RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
%FuncLabPreferences = evalin('base','FuncLabPreferences');
fl_view_rf_cross_section_depth(ProjectDirectory,ProjectFile,FuncLabPreferences)


%--------------------------------------------------------------------------
% view_ray_diagram_Callback
%
% Plots a 3D View of the active RFs observed by the station or the Event.
% Only active if depth mapping has been performed. Figure design is
% interactive allowing the user to zoom, scroll, pan, etc... with the
% normal matlab interface. This call back only needs to get the funclab preferences and
% location of the RayInfo file.
%--------------------------------------------------------------------------
function view_ray_diagram_Callback(cbo, eventdata, handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentRecords = evalin('base','CurrentRecords');
CurrentIndices = evalin('base','CurrentIndices');
SelectedIndex = get(h.tables_ls,'Value');
TableList = get(h.tables_ls,'String');
TableName = TableList{SelectedIndex};
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_view_ray_diagram(ProjectDirectory,CurrentIndices,TableName,FuncLabPreferences);


%--------------------------------------------------------------------------
% view_ray_diagram_all_Callback
%
% Plots a 3D View of the active RFs observed by the station or the Event.
% Only active if depth mapping has been performed. Figure design is
% interactive allowing the user to zoom, scroll, pan, etc... with the
% normal matlab interface. This call back only needs to get the funclab preferences and
% location of the RayInfo file.
%--------------------------------------------------------------------------
function view_ray_diagram_all_Callback(cbo, eventdata, handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
fl_view_ray_diagram_all(ProjectDirectory,FuncLabPreferences);

%--------------------------------------------------------------------------
% view_station_map_Callback
%
% This callback function is for plotting a regional map of the stations
% within a dataset.  Note that the boundaries for this map should be set in
% the FuncLab Parameters.
%--------------------------------------------------------------------------
function view_station_map_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
CurrentRecords = evalin('base','CurrentRecords');
SelectedIndex = get(h.records_ls,'Value');
Record = CurrentRecords(SelectedIndex,:)';
if license('test','map_toolbox')
    fl_view_station_map(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles,Record)
else
    fl_view_station_map(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles,Record)
    set(h.message_t,'String','Message: Using m_map for mapping.');
    %    set(h.message_t,'String','Message: You need the MATLAB Mapping Toolbox to view station map.');
end

%--------------------------------------------------------------------------
% view_event_map_Callback
%
% This callback function is for plotting a map of the events within the
% dataset.
%--------------------------------------------------------------------------
function view_event_map_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
CurrentRecords = evalin('base','CurrentRecords');
SelectedIndex = get(h.records_ls,'Value');
Record = CurrentRecords(SelectedIndex,:)';
if license('test','map_toolbox')
    fl_view_event_map(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles,Record)
else
    fl_view_event_map(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles,Record)
    set(h.message_t,'String','Message: Using m_map for mapping.');
    %set(h.message_t,'String','Message: You need the MATLAB Mapping Toolbox to view event map.');
end

%--------------------------------------------------------------------------
% view_data_coverage_current_set_Callback
%
% This callback function is for plotting the data coverage in terms of ray
% parameter vs. backazimuth of the receiver functions in the dataset.  This
% plot shows only the active RFs within a dataset.
%--------------------------------------------------------------------------
function view_data_coverage_current_set_Callback(cbo,eventdata,handles)
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
fl_view_data_coverage_currentset(RecordMetadataDoubles)

%--------------------------------------------------------------------------
% view_data_coverage_Callback
%
% This callback function is for plotting the data coverage in terms of ray
% parameter vs. backazimuth of the receiver functions in the dataset.  This
% plot shows only the active RFs within a dataset.
%--------------------------------------------------------------------------
function view_data_coverage_Callback(cbo,eventdata,handles)
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
fl_view_data_coverage(RecordMetadataDoubles)

%--------------------------------------------------------------------------
% ex_stations_Callback
%
% This callback function is for exporting the list of stations in the
% dataset into a text file for GMT plotting or other purposes.  The columns
% are in the following format:
%
%   "Lon" "Lat" "Elevation" "Station Name" "Status"
%--------------------------------------------------------------------------
function ex_stations_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
ActiveIn = find(RecordMetadataDoubles(:,2));
ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
ActiveStrings = RecordMetadataStrings(ActiveIn,:);
[junk,indices,junk] = unique(ActiveStrings(:,2));
ActiveLatitudes = ActiveDoubles(indices,10);
ActiveLongitudes = ActiveDoubles(indices,11);
ActiveElevations = ActiveDoubles(indices,12);
ActiveNames = ActiveStrings(indices,2);
ActiveStatus = ActiveDoubles(indices,2);
[junk,allindices,junk] = unique(RecordMetadataStrings(:,2));
AllLatitudes = RecordMetadataDoubles(allindices,10);
AllLongitudes = RecordMetadataDoubles(allindices,11);
AllElevations = RecordMetadataDoubles(allindices,12);
AllNames = RecordMetadataStrings(allindices,2);
AllStatus = RecordMetadataDoubles(allindices,2);
[InactiveNames,InactiveIn] = setdiff(AllNames,ActiveNames);
if ~isempty(InactiveIn)
    InactiveLatitudes = AllLatitudes(InactiveIn);
    InactiveLongitudes = AllLongitudes(InactiveIn);
    InactiveElevations = AllElevations(InactiveIn);
    InactiveStatus = AllStatus(InactiveIn);
end
[FileName,Pathname] = uiputfile('station_list.txt','Save Station List to File');
if FileName ~= 0
    WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting station information to a text file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    fid = fopen([Pathname FileName],'w+');
    for n = 1:size(ActiveLatitudes,1)
        fprintf(fid,'%.3f %.3f %.0f %s %.0f\n',ActiveLongitudes(n),ActiveLatitudes(n),ActiveElevations(n)*1000,ActiveNames{n},ActiveStatus(n));
    end
    if ~isempty(InactiveIn)
        for n = 1:size(InactiveLatitudes,1)
            fprintf(fid,'%.3f %.3f %.0f %s %.0f\n',InactiveLongitudes(n),InactiveLatitudes(n),InactiveElevations(n)*1000,InactiveNames{n},InactiveStatus(n));
        end
    end
    fclose(fid);
    close(WaitGui)
end

%--------------------------------------------------------------------------
% ex_events_Callback
%
% This callback function is for exporting the list of eveints in the
% dataset into a text file for GMT plotting or other purposes.  The columns
% are in the following format:
%
%   "Lon" "Lat" "Depth" "Magnitude" "Origin Day" "Origin Time" "Status"
%--------------------------------------------------------------------------
function ex_events_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
ActiveIn = find(RecordMetadataDoubles(:,2));
ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
ActiveStrings = RecordMetadataStrings(ActiveIn,:);
[junk,indices,junk] = unique(ActiveStrings(:,3));
ActiveLatitudes = ActiveDoubles(indices,13);
ActiveLongitudes = ActiveDoubles(indices,14);
ActiveDepths = ActiveDoubles(indices,15);
ActiveMagnitudes = ActiveDoubles(indices,16);
ActiveNames = ActiveStrings(indices,3);
ActiveStatus = ActiveDoubles(indices,2);
[junk,allindices,junk] = unique(RecordMetadataStrings(:,3));
AllLatitudes = RecordMetadataDoubles(allindices,13);
AllLongitudes = RecordMetadataDoubles(allindices,14);
AllDepths = RecordMetadataDoubles(allindices,15);
AllMagnitudes = RecordMetadataDoubles(allindices,16);
AllNames = RecordMetadataStrings(allindices,3);
AllStatus = RecordMetadataDoubles(allindices,2);
[InactiveNames,InactiveIn] = setdiff(AllNames,ActiveNames);
if ~isempty(InactiveIn)
    InactiveLatitudes = AllLatitudes(InactiveIn);
    InactiveLongitudes = AllLongitudes(InactiveIn);
    InactiveDepths = AllDepths(InactiveIn);
    InactiveMagnitudes = AllMagnitudes(InactiveIn);
    InactiveStatus = AllStatus(InactiveIn);
end
for n=1:length(ActiveNames)
    [Month,Day] = jul2cal(str2double(ActiveNames{n}(1:4)),str2double(ActiveNames{n}(6:8)));
    ActiveDays{n} = sprintf('%04.0f/%02.0f/%02.0f',str2double(ActiveNames{n}(1:4)),Month,Day);
    ActiveTimes{n} = ActiveNames{n}(10:17);
end
for n=1:length(InactiveNames)
    [Month,Day] = jul2cal(str2double(InactiveNames{n}(1:4)),str2double(InactiveNames{n}(6:8)));
    InactiveDays{n} = sprintf('%04.0f/%02.0f/%02.0f',str2double(InactiveNames{n}(1:4)),Month,Day);
    InactiveTimes{n} = InactiveNames{n}(10:17);
end
[FileName,Pathname] = uiputfile('event_list.txt','Save Event List to File');
if FileName ~= 0
    WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting event information to a text file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    fid = fopen([Pathname FileName],'w+');
    for n = 1:size(ActiveLatitudes,1)
        fprintf(fid,'%.3f %.3f %.1f %.1f %s %s %.0f\n',ActiveLongitudes(n),ActiveLatitudes(n),ActiveDepths(n),ActiveMagnitudes(n),ActiveDays{n},ActiveTimes{n},ActiveStatus(n));
    end
    if ~isempty(InactiveIn)
        for n = 1:size(InactiveLatitudes,1)
            fprintf(fid,'%.3f %.3f %.1f %.1f %s %s %.0f\n',InactiveLongitudes(n),InactiveLatitudes(n),InactiveDepths(n),InactiveMagnitudes(n),InactiveDays{n},InactiveTimes{n},InactiveStatus(n));
        end
    end
    fclose(fid);
    close(WaitGui)
end

%--------------------------------------------------------------------------
% ex_te_Callback
%
% This callback function is for exporting the trace edits for each record
% into a text file, where columns are given as "Edited", "Status",
% "Filename", "Station Name", and "Event Name", respectively.
% Edit by RWP, Oct 2014: added columns for rayparameter and back azimuth
%--------------------------------------------------------------------------
function ex_te_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
[FileName,Pathname] = uiputfile('trace_edits.txt','Save Trace Edits to File');
if FileName ~= 0
    WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting the trace edits for each record to a text file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    fid = fopen([Pathname FileName],'w+');
    for n = 1:size(RecordMetadataDoubles,1)
        fprintf(fid,'%.0f %.0f %s %s %s %3.5f %3.5f\n',RecordMetadataDoubles(n,1),RecordMetadataDoubles(n,2),RecordMetadataStrings{n,1},RecordMetadataStrings{n,2},RecordMetadataStrings{n,3},RecordMetadataDoubles(n,18),RecordMetadataDoubles(n,19));
    end
    fclose(fid);
    close(WaitGui)
end

%--------------------------------------------------------------------------
% ex_rfs_Callback
%
% This callback function is for exporting all the active receiver function
% traces to a text file.  The RFs are separated by a header row followed by
% rows for the time and amplitude information with columns in the following
% format:
%
%   > "Station Name" "Station Lon" "Station Lat" "Distance (deg)" Ray Parameter" "Backazimuth" "Status"
%   "Time" "Radial Amps" "Transverse Amps"
%--------------------------------------------------------------------------
function ex_rfs_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
[FileName,Pathname] = uiputfile('all_rf_traces.txt','Save Receiver Function Records to File');
if FileName ~= 0
    WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting active receiver functions to text file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    fid = fopen([Pathname FileName],'w+');
    for n = 1:size(RecordMetadataDoubles,1)
        if RecordMetadataDoubles(n,2) == 1
            fprintf(fid,'> %s %.3f %.3f %.2f %.3f %.2f %.0f\n',RecordMetadataStrings{n,2},RecordMetadataDoubles(n,11),RecordMetadataDoubles(n,10),RecordMetadataDoubles(n,17),RecordMetadataDoubles(n,18),RecordMetadataDoubles(n,19),RecordMetadataDoubles(n,2));
            [RadialAmps,~] = fl_readseismograms([ProjectDirectory filesep RecordMetadataStrings{n,1} 'eqr']);
            [TransverseAmps,Time] = fl_readseismograms([ProjectDirectory filesep RecordMetadataStrings{n,1} 'eqt']);
            for m=1:size(Time)
                fprintf(fid,'%.3f %.3f %.3f\n',Time(m),RadialAmps(m),TransverseAmps(m));
            end
        end
    end
    fclose(fid);
    close(WaitGui)
end

%--------------------------------------------------------------------------
% ex_hk_res_Callback
%
% This callback function is for exporting all the hk results
% to a text file. Format is: 
%       "Station Longitude" "Station Latitude" "Station Elevation" "Station Name" "Moho Depth" "Moho Depth Error" "Vp/Vs" "Vp/Vs Error" "Poisson Ratio" "Poisson Ratio Error" "Number of RFs" "Assumed Vp" "Ps Weight" "PpPs Weight" "PsPs Weight" "Backazimuth Range" "Ray Parameter Range"
%--------------------------------------------------------------------------
function ex_hk_res_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
load([ProjectDirectory filesep ProjectFile],'HkMetadataStrings')
load([ProjectDirectory filesep ProjectFile],'HkMetadataDoubles')
% Open the text files (overwrite if it exists)
%--------------------------------------------------------------------------
[FileName,Pathname] = uiputfile('hk_solutions.txt','Save H-k Solutions to File');
if FileName ~= 0
    WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting H-k stacking solutions to text file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    fid = fopen([Pathname FileName],'w+');
    
    for n = 1:size(HkMetadataStrings,1)
        % Load H-k Table from the Project Directory
        %----------------------------------------------------------------------
        load([ProjectDirectory,filesep,HkMetadataStrings{n,1}])
        Indices = strmatch(HkMetadataStrings{n,2},RecordMetadataStrings(:,2));
        Index = Indices(1);
        StationLongitude = RecordMetadataDoubles(Index,11);
        StationLatitude = RecordMetadataDoubles(Index,10);
        StationElevation = RecordMetadataDoubles(Index,12);
        fprintf(fid,'%.3f %.3f %.0f %s %.3f %.3f %.4f %.4f %.4f %.4f %.0f %.3f %.2f %.2f %.2f %.0f-%.0f %.3f-%.3f\n',...
            StationLongitude,StationLatitude,StationElevation*1000,HkMetadataStrings{n,2},HkMetadataDoubles(n,15),HkMetadataDoubles(n,16),HkMetadataDoubles(n,17),...
            HkMetadataDoubles(n,18),HkMetadataDoubles(n,19),HkMetadataDoubles(n,20),HkMetadataDoubles(n,1),HkMetadataDoubles(n,14),HkMetadataDoubles(n,11),...
            HkMetadataDoubles(n,12),HkMetadataDoubles(n,13),HkMetadataDoubles(n,7),HkMetadataDoubles(n,8),HkMetadataDoubles(n,9),HkMetadataDoubles(n,10));
    end
    fclose(fid);
    close(WaitGui)
end



%--------------------------------------------------------------------------
% im_te_Callback
%
% This callback function is for importing trace edits from a text file,
% where columns are given as "Edited", "Status", "Filename", "Station
% Name", and "Event Name", respectively.  This is the same format for text
% files created when you export trace edits.
%--------------------------------------------------------------------------
function im_te_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
SelectedIndex = get(h.tables_ls,'Value');
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
%RecordMetadataStrings = evalin('base','RecordMetadataStrings');
%RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
try
    [Filename,DataDirectory] = uigetfile_kce('*','Select the Trace Edit Text File');
catch
    [Filename,DataDirectory] = uigetfile('*','Select the Trace Edit Text File');
end
if Filename ~= 0
    tic
    fid = fopen([DataDirectory Filename],'r');
    while 1
        if feof(fid); break; end
        TextLine = fgetl(fid);
        [Edited,TextLine] = strtok(TextLine,' ');
        Edited = str2double(Edited);
        [Status,TextLine] = strtok(TextLine,' ');
        Status = str2double(Status);
        [File,TextLine] = strtok(TextLine,' ');
        [Station,TextLine] = strtok(TextLine,' ');
        [Event,TextLine] = strtok(TextLine,' ');
        Row = find(strcmp(File,RecordMetadataStrings(:,1)));
        if isempty(Row); continue; end
        RecordMetadataDoubles(Row,1) = Edited;
        RecordMetadataDoubles(Row,2) = Status;
    end
    % Now save the metadata and write it to current metadata
    assignin('base','RecordMetadataStrings',RecordMetadataStrings)
    assignin('base','RecordMetadataDoubles',RecordMetadataDoubles)
    SetManagementCell{CurrentSubsetIndex, 2} = RecordMetadataStrings;
    SetManagementCell{CurrentSubsetIndex, 3} = RecordMetadataDoubles;
    assignin('base','SetManagementCell',SetManagementCell);
    save([ProjectDirectory ProjectFile],'RecordMetadataDoubles','RecordMetadataStrings','SetManagementCell','-append')
    fclose(fid);
    t_temp = toc;
    SecTime = num2str((t_temp),'%.2f');
    MinTime = num2str((t_temp)/60,'%.2f');
    set(h.message_t,'String',['Message: Trace edits imported to project.  Import took ' SecTime ' seconds (or ' MinTime ' minutes).'])
    set(h.tables_ls,'Value',SelectedIndex)
    set(h.records_ls,'Value',1)
    tables_Callback
end

%--------------------------------------------------------------------------
% close_project_Callback
%
% This callback function closes the project and removes variables from the
% workspace.
%--------------------------------------------------------------------------
function close_project_Callback(cbo,eventdata,handles)
evalin('base','clear'); close(gcf)

%--------------------------------------------------------------------------
% FL_new_fetch_project_setup_Callback
%
% This callback function fetch's waveform data from iris to create the data
% for a project.
%--------------------------------------------------------------------------
function FL_new_fetch_project_setup_Callback(cbo,eventdata,handles)
%% FL_new_fetch_project_setup_Callback
%  acquires the parameters from the panels
%  Calls iris fetch to find some last minute parameters
%  Then calls iris fetch to obtain waveform data
%  data is then preprocessed and raw traces are written into event
%  directories
%  RFs are computed with the params chosen by user

% Wait dialog is annoying. Off for debugging
% WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
%     'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
% uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
%     'String','Please wait, Fetching data, computing RFs, and loading in datasets and creating station and event tables',...
%     'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
% drawnow

%% Get the directory to put the project
h = guidata(gcbf);
%ProjectDirectoryHdls = findobj('Tag','new_fetch_projdir_e');
ProjectDirectory = get(h.new_fetch_projdir_e,'String');
if ~strcmp(filesep,ProjectDirectory(end))
    ProjectDirectory = [ProjectDirectory, filesep];
end
assignin('base','ProjectDirectory',ProjectDirectory)
assignin('base','ProjectFile','Project.mat')
if isempty(ProjectDirectory)
    errordlg('Must type a full pathname for the project directory.') % 11/12/2011: DELETED ERRORDLG_KCE 
    return
end
if exist(ProjectDirectory,'dir')
    errordlg('Project directory already exists.  We do not want to overwrite this project, or any other information.') % 11/12/2011: DELETED ERRORDLG_KCE
    return
end
mkdir(ProjectDirectory)
mkdir([ProjectDirectory 'RAWDATA'])
mkdir([ProjectDirectory 'RAWTRACES'])
mkdir([ProjectDirectory 'FIGURES'])
mkdir([ProjectDirectory 'SACGARDEN'])
TracesWriteString = sprintf('WRITESAC:%sSACGARDEN',ProjectDirectory);


%% get the user input data
stationPanelHandles = findobj('Tag','new_fetch_station_panel');
eventPanelHandles = findobj('Tag','new_fetch_events_panel');
tracePanelHandles = findobj('Tag','new_fetch_traces_panel');
rfProcessingPanelHandles = findobj('Tag','new_fetch_rfprocessing_params_panel');
encryptedPanelHandles = findobj('Tag','encryptedInfoPanel');

stationInfo = get(stationPanelHandles,'UserData');
%.stations: cell array
%.networks: cell array
%.latitudes: double array
%.longitudes: double array
eventInfo = get(eventPanelHandles,'UserData');
% all cell arrays:
%.OriginName
%.OriginTime
%.OriginLatitude
%.OriginLongitude
%.OriginDepth (km)
%.OriginMagnitude 
% And just values
%.minDistance
%.maxDistance
traceInfo = get(tracePanelHandles,'UserData');
%{trace start, before or after, phase or origin, trace end, before or after, phase or origin, sample rate, response}
rfProcessingInfo = get(rfProcessingPanelHandles,'UserData');
%{taper1, filter_hp1, filter_lp1, filter_order1, pre-phase cut1, post-phase cut1, numerator1, denominator1,
%  array or single1, gaussian1, decontype1, waterlevel1, maxiterations1,
%  minerror1, taper2, filter_hp2, filter_lp2, filter_order2, pre_phase
%  cut2, post_phase cut2, numerator2, denominator2, array or single2,
%  gaussian2, decontype2, waterlevel2, maxiteration2, minerror2,
%  incidentphase1, incidentphase2
encryptedInfo = get(encryptedPanelHandles,'UserData');
save('junk.mat','encryptedInfo')


%% Station info has been found to have numerous duplicates, so use unique to
% get only the necessary stations
uniqueStations = unique(stationInfo.stations);
cleanStationInfo.stations = cell(1,length(uniqueStations));
cleanStationInfo.networks = cell(1,length(uniqueStations));
cleanStationInfo.latitudes = zeros(1,length(uniqueStations));
cleanStationInfo.longitudes = zeros(1,length(uniqueStations));
for istation = 1:length(uniqueStations)
    for jstation = 1:length(stationInfo.stations)
        if strcmp(uniqueStations{istation},stationInfo.stations{jstation})
           cleanStationInfo.stations{istation} = stationInfo.stations{jstation};
           cleanStationInfo.networks{istation} = stationInfo.networks{jstation};
           cleanStationInfo.latitudes(istation) = stationInfo.latitudes{jstation};
           cleanStationInfo.longitudes(istation) = stationInfo.longitudes{jstation};
           break
        end
    end
end

%% Get the number of events and stations for the loops
nevents = length(eventInfo.OriginLatitude);
nstations = length(cleanStationInfo.stations); 

%% Break these cell arrays into easier to use variables (structures will be
% parsed in loops below)
% Trace Info
if strcmp(traceInfo{2},'Before')
    traceStartSecondsOffset = -1 * str2double(traceInfo{1});
else
    traceStartSecondsOffset = str2double(traceInfo{1});
end
if strcmp(traceInfo{5},'Before')
    traceEndSecondsOffset = -1 * str2double(traceInfo{4});
else
    traceEndSecondsOffset = str2double(traceInfo{4});
end
traceStartPhase = sprintf('%s',traceInfo{3});
traceEndPhase = sprintf('%s',traceInfo{6});
traceSampleRate = str2double(traceInfo{7});
traceResponseSelection = sprintf('%s',traceInfo{8});

%% RF processing info
FL_rfOpt(1).processingTaper = sprintf('%s',rfProcessingInfo{1});
FL_rfOpt(2).processingTaper = sprintf('%s',rfProcessingInfo{15});
FL_rfOpt(1).processingFilterHp = str2double(rfProcessingInfo{2});
FL_rfOpt(2).processingFilterHp = str2double(rfProcessingInfo{16});
FL_rfOpt(1).processingFilterLp = str2double(rfProcessingInfo{3});
FL_rfOpt(2).processingFilterLp = str2double(rfProcessingInfo{17});
FL_rfOpt(1).processingFilterOrder = str2double(rfProcessingInfo{4});
FL_rfOpt(2).processingFilterOrder = str2double(rfProcessingInfo{18});
FL_rfOpt(1).processingPrePhaseCut = str2double(rfProcessingInfo{5});
FL_rfOpt(2).processingPrePhaseCut = str2double(rfProcessingInfo{19});
FL_rfOpt(1).processingPostPhaseCut = str2double(rfProcessingInfo{6});
FL_rfOpt(2).processingPostPhaseCut = str2double(rfProcessingInfo{20});
FL_rfOpt(1).processingNumerator = sprintf('%s',rfProcessingInfo{7});
FL_rfOpt(2).processingNumerator = sprintf('%s',rfProcessingInfo{21});
FL_rfOpt(1).processingDenominator = sprintf('%s',rfProcessingInfo{8});
FL_rfOpt(2).processingDenominator = sprintf('%s',rfProcessingInfo{22});
FL_rfOpt(1).processingDenominatorMethod = sprintf('%s',rfProcessingInfo{9});
FL_rfOpt(2).processingDenominatorMethod = sprintf('%s',rfProcessingInfo{23});
FL_rfOpt(1).processingGaussian = str2double(rfProcessingInfo{10});
FL_rfOpt(2).processingGaussian = str2double(rfProcessingInfo{24});
FL_rfOpt(1).processingDeconvolution = sprintf('%s',rfProcessingInfo{11});
FL_rfOpt(2).processingDeconvolution = sprintf('%s',rfProcessingInfo{25});
FL_rfOpt(1).processingWaterlevel = str2double(rfProcessingInfo{12});
FL_rfOpt(2).processingWaterlevel = str2double(rfProcessingInfo{26});
FL_rfOpt(1).processingMaxIterations = str2double(rfProcessingInfo{13});
FL_rfOpt(2).processingMaxIterations = str2double(rfProcessingInfo{27});
FL_rfOpt(1).processingMinError = str2double(rfProcessingInfo{14});
FL_rfOpt(2).processingMinError = str2double(rfProcessingInfo{28});
FL_rfOpt(1).processingIncidentPhase = sprintf('%s',rfProcessingInfo{29});
FL_rfOpt(2).processingIncidentPhase = sprintf('%s',rfProcessingInfo{30});
FL_rfOpt(1).sampleRate = 1 / traceSampleRate;
FL_rfOpt(2).sampleRate = 1 / traceSampleRate;


%% A cell variable to hold the raw trace file names as they are written.
%  This is to allow re-upping the file names quickly between writing the
%  raw files and beginning the RF processing
rawTracesFileNames = cell(nevents,nstations*2); % allows for 2 location codes per station


%% At this point RWP would like to query the data center to determine the
% proper location codes and network codes for the set of stations. However,
% stations can change metadata and thus its best just to decide location
% code and channel codes for the time frame requested. :(

%% Loop through each event
for ievent = 1:nevents
    eventLatitude = eventInfo.OriginLatitude{ievent};
    eventLongitude = eventInfo.OriginLongitude{ievent};
    eventDepth = eventInfo.OriginDepth{ievent};
    eventTime = irisTimeStringToEpoch(eventInfo.OriginTime{ievent});
    
    fprintf('***      Requesting event %s     ***\n',eventInfo.OriginTime{ievent});
    
    
    %% Loop through stations...debateable whether it would be better to
    % request all stations at once, or request stations one at a time.
    % Going with one station at a time as its easiest to deal with, but
    % going for all at once may be faster
    iistation = 0;
    for istation = 1:nstations
        % Init the start and end times for debug
        eventTime = irisTimeStringToEpoch(eventInfo.OriginTime{ievent});
        startTimeString = epochTimeToIrisString(eventTime+(traceStartSecondsOffset/24/60/60));
        endTimeString = epochTimeToIrisString(eventTime+(traceEndSecondsOffset/24/60/60));
        startTimeFlag = 0;
        endTimeFlag = 0;
        kmdist = 0;
        azi = 0;
        gcarc = 0;
        startPhaseArrivalTime = 0;
        startPhaseRayParam = 0;
        endPhaseArrivalTime = 0;
        endPhaseRayParam = 0;
        clear tt;
        
        % Determine if this station is within the distance window
        [kmdist, azi, gcarc] = distaz(eventLatitude,eventLongitude,cleanStationInfo.latitudes(istation),cleanStationInfo.longitudes(istation));
        if gcarc <= eventInfo.maxDistance && gcarc >= eventInfo.minDistance
            % determine time to start trace request
            if ~strcmp(traceStartPhase,'Origin')
                tt = taupTime('iasp91',eventDepth,traceStartPhase,'deg',gcarc);
                if ~isempty(tt) % avoid searching when phase is not available at distance
                    startPhaseArrivalTime = tt(1).time; % time in seconds relative to origin
                    startPhaseRayParam = tt(1).rayParam; % ray parameter in (I think) seconds per radian 
                    startTimeString = epochTimeToIrisString(eventTime+((startPhaseArrivalTime+traceStartSecondsOffset)/24/60/60));
                    startTimeFlag = 1;
                else
                    clear startTimeString;
                end
                
            else
                startTimeString = epochTimeToIrisString(eventTime+(traceStartSecondsOffset/24/60/60));
                startTimeFlag = 1;
            end
                                                         
            clear tt;
            %% determine time to end trace request
            if ~strcmp(traceEndPhase,'Origin')
                tt = taupTime('iasp91',eventDepth,traceEndPhase,'deg',gcarc);
                if ~isempty(tt) % avoid searching when phase is not available at distance
                    endPhaseArrivalTime = tt(1).time; % time in seconds relative to origin
                    endPhaseRayParam = tt(1).rayParam; % ray parameter in (I think) seconds per radian 
                    endTimeString = epochTimeToIrisString(eventTime+((endPhaseArrivalTime+traceEndSecondsOffset)/24/60/60));
                    endTimeFlag = 1;
                else
                    clear endTimeString
                end
                                                         
            else
                endTimeString = epochTimeToIrisString(eventTime+(traceEndSecondsOffset/24/60/60));
                endTimeFlag = 1;
            end
            
            
            %% Now get traces for this station. This will include all
            % locations and broadband channels
%             if ~strcmp(cleanStationInfo.networks{istation},'BK')
%                 serviceDataCenter = 'http://service.iris.edu/';
%             else
%                 serviceDataCenter = 'http://service.ncedc.org/';
%             end
            serviceDataCenter = 'http://service.iris.edu';
            if strcmp(cleanStationInfo.networks{istation},'BK')
                serviceDataCenter = 'http://service.ncedc.org/';
            end
             if exist('startTimeString','var') && exist('endTimeString','var') && startTimeFlag == 1 && endTimeFlag == 1
                fprintf('Fetching data for station %s\n',cleanStationInfo.stations{istation});
                load('junk.mat');

                %% Switches for encrypted data access
                %if ievent == 1
                    if isempty(encryptedInfo{1}) || isempty(encryptedInfo{2})
                        dataTraces = irisFetch.Traces(cleanStationInfo.networks{istation},cleanStationInfo.stations{istation},'*','?H?',startTimeString, endTimeString, serviceDataCenter,'includePZ','verbose',TracesWriteString);
                    else
                        %fprintf('%s %s\n',encryptedInfo{1}, encryptedInfo{2});
                        %fprintf('%s %s %s %s %s\n',cleanStationInfo.networks{istation},cleanStationInfo.stations{istation}, startTimeString, endTimeString, serviceDataCenter);
                        dataTraces = irisFetch.Traces(cleanStationInfo.networks{istation},cleanStationInfo.stations{istation},'*','?H?',startTimeString, endTimeString, serviceDataCenter,'includePZ','verbose',TracesWriteString,encryptedInfo);
                    end
                %else
                %    dataTraces = irisFetch.Traces(cleanStationInfo.networks{istation},cleanStationInfo.stations{istation},'*','?H?',startTimeString, endTimeString, serviceDataCenter,'includePZ','verbose');
                %end
                %dataTraces = irisFetch.Traces(cleanStationInfo.networks{istation},stationInfo.stations{istation},'*','?H?',startTimeString, endTimeString,'includePZ');

                %% Find number of traces obtained
                ntraces = length(dataTraces);

                %% Check empty return or lack of 3 component data
                if ntraces < 3
                    fprintf('No data found for station %s!\n',cleanStationInfo.stations{istation});
                    interpedMergedData = cell(1,3);
                    rotatedInterpedMergedData = cell(1,3);
                    continue  % no traces, so go on to next station
                end

                %% Init flags for rotation and interpolation
                rotateFlag = 0;
                interpFlag = 0;

                %% prepare interpolation array
                startTimeEpoch = irisTimeStringToEpoch(startTimeString);
                endTimeEpoch = irisTimeStringToEpoch(endTimeString);
                outputTimeArray = startTimeEpoch:1/traceSampleRate/24/60/60:endTimeEpoch;

                %% init for interpolation and rotation
                interpedMergedData = cell(1,3);
                rotatedInterpedMergedData = cell(1,3);

                %% Check for the ideal, but almost never real case of only 3
                % traces (one per channel)
                if ntraces == 3
                    for itrace=1:ntraces
                        if strcmp(dataTraces(itrace).channel(3),'2') || strcmp(dataTraces(itrace).channel(3),'E') || strcmp(dataTraces(itrace).channel(3),'5')
                           jtrace = 1;
                        elseif strcmp(dataTraces(itrace).channel(3),'1') || strcmp(dataTraces(itrace).channel(3),'N') || strcmp(dataTraces(itrace).channel(3),'4')
                           jtrace = 2;
                        else
                           jtrace = 3;
                        end
                        interpedMergedData{jtrace} = dataTraces(itrace);
                    end
                    %% Check to interpolate to output time array
                    for itrace = 1:ntraces
                       obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                       interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                       if strcmp(dataTraces(itrace).channel(3),'2') || strcmp(dataTraces(itrace).channel(3),'E') || strcmp(dataTraces(itrace).channel(3),'5')
                           jtrace = 1;
                       elseif strcmp(dataTraces(itrace).channel(3),'1') || strcmp(dataTraces(itrace).channel(3),'N') || strcmp(dataTraces(itrace).channel(3),'4')
                           jtrace = 2;
                       else
                           jtrace = 3;
                       end
                           
                       interpedMergedData{jtrace}.data = interpolatedAmplitude;
                       interpedMergedData{jtrace}.sampleRate = traceSampleRate;
                       interpedMergedData{jtrace}.sampleCount = length(interpolatedAmplitude);
                       interpedMergedData{jtrace}.startTime = startTimeEpoch;
                       interpedMergedData{jtrace}.endTime = endTimeEpoch;
                       
                    end
                    %% rotate if necessary
                    ierr = 0;
                    [rotatedInterpedMergedData, ierr] = FL_rotateCellTripleToENZ(interpedMergedData);

                    %% response removal if requested
                    % Note that this really should be a selection between
                    % primary and secondary so the user can compare response
                    % deconvolved and non-response deconvolved data.
                    if ierr == 0
                        [DeconnedData, ierr] = FL_responseRemoval( rotatedInterpedMergedData, 0.002, traceResponseSelection );
                    end
                    %% Split at this point.
                    % 1. If we are using the traditional single station
                    % deconvolution method, then we can compute that here and
                    % write files.
                    % 2. If we are using the array based source method of
                    % deconvolution, then we'll need to start computing the
                    % source function and write three component data files
                    %
                    % Let's proceed by creating a 'RAWTRACES' directory in the
                    % project folder. We can then compute the RFs once the
                    % RAWTRACES are ready. 

                    %% Write E,N,Z sac files in RAWTRACES
                    if ierr == 0
                        [writtenTraces, ierr] = FL_writeFetchedTraces(DeconnedData, ProjectDirectory, 'RAWTRACES', traceResponseSelection, eventInfo, ievent);
                    end

                    % WrittenTraces now have the file name in: writtenTraces{itrace}.fullSacFileName
                    % Rejoining thread with case of multiple channels for a
                    % given station
                    if ierr == 0
                        iistation = iistation + 1;
                        rawTracesFileNames{ievent,iistation} = sprintf('%s %s %s',writtenTraces{1}.fullSacFileName, writtenTraces{2}.fullSacFileName, writtenTraces{3}.fullSacFileName);
                    end

                else

                    %% must have more than 3 traces. May be multiple location
                    % codes, multiple sets of channel codes, or gappy data
                    locs = cell(1,length(dataTraces));
                    for i=1:length(dataTraces)
                        locs{i} = sprintf('%s',dataTraces(i).location);
                    end
                    uniqueLocs = unique(locs);
                    nlocs = length(uniqueLocs);
                    
                    %% In the case that we have multiple instruments under the same location code - such as DBIC
                    instruments = cell(1,length(dataTraces));
                    for i=1:length(dataTraces)
                        instruments{i} = sprintf('%s',dataTraces(i).instrument);
                    end
                    uniqueInstruments = unique(instruments);
                    ninstruments = length(uniqueInstruments);
                    if ninstruments > nlocs
                        for i=1:ninstruments
                            tmpLoc = sprintf('%02d',(i-1)*10);
                            for j=1:length(dataTraces)
                                if strcmp(dataTraces(j).instrument,uniqueInstruments{i})
                                    dataTraces(j).location = tmpLoc;
                                end
                            end
                        end
                    end

                    %% Rerun finding location codes
                    locs = cell(1,length(dataTraces));
                    for i=1:length(dataTraces)
                        locs{i} = sprintf('%s',dataTraces(i).location);
                    end
                    uniqueLocs = unique(locs);
                    nlocs = length(uniqueLocs);

                    %% The most correct thing to do is to treat each location
                    % code as its own "station"
                    for iloc = 1:nlocs
                        %% Find the number of traces under this location code
                        jchan = 0;
                        jhorizontal1 = 0;
                        jhorizontal2 = 0;
                        % TODO - add channels 5 and 6
                        jhorizontale = 0;
                        jhorizontaln = 0;
                        jvertical3 = 0;
                        jverticalz = 0;
                        jhorizontal5 = 0;
                        jhorizontal6 = 0;
                        for jloc = 1:length(dataTraces)
                            if strcmp(sprintf('%s',dataTraces(jloc).location),uniqueLocs{iloc})
                                jchan = jchan + 1;
                                if strcmp(dataTraces(jloc).channel(3),'1')
                                    jhorizontal1 = jhorizontal1 + 1;
                                elseif strcmp(dataTraces(jloc).channel(3),'2')
                                    jhorizontal2 = jhorizontal2 + 1;
                                elseif strcmp(dataTraces(jloc).channel(3),'3')
                                    jvertical3 = jvertical3 + 1;
                                elseif strcmp(dataTraces(jloc).channel(3),'E')
                                    jhorizontale = jhorizontale + 1;
                                elseif strcmp(dataTraces(jloc).channel(3),'N')
                                    jhorizontaln = jhorizontaln + 1;
                                elseif strcmp(dataTraces(jloc).channel(3),'Z')
                                    jverticalz = jverticalz + 1;
                                elseif strcmp(dataTraces(jloc).channel(3),'5')
                                    jhorizontal5 = jhorizontal5 + 1;
                                elseif strcmp(dataTraces(jloc).channel(3),'6')
                                    jhorizontal6 = jhorizontal6 + 1;                                    
                                else
                                    fprintf('Unknown component: %s\n',dataTraces(jloc).channel(3));
                                end

                            end
                        end
                        % init the kept channels vectors
                        keptchans1=[];
                        keptchans2=[];
                        keptchanse=[];
                        keptchansn=[];
                        keptchansz=[];
                        keptchans3=[];
                        keptchans5=[];
                        keptchans6=[];

                        %% So the number of channels under this location code is
                        % now jchan
                        % and the number of traces in each of the 1, 2, e, n,
                        % and z directions is set in jhorizontal{1,2,e,n} and
                        % jverticalz. This should cover most common
                        % conventions, but may need an adjustment in the future
                        % if other naming conventions become popular
                        if jhorizontal1 > 0
                            jhorizontal1Indices = zeros(1,jhorizontal1);
                            kchan = 0;
                            for jloc=1:length(dataTraces)
                                if strcmp(sprintf('%s',dataTraces(jloc).location),uniqueLocs{iloc})
                                    if strcmp(dataTraces(jloc).channel(3),'1') 
                                        kchan = kchan + 1;
                                        jhorizontal1Indices(kchan) = jloc;
                                    end
                                end
                            end

                            keptchans1 = zeros(1,length(jhorizontal1Indices));
                            mchans = 0;
                            keptSampleRate = 1000;
                            for lchan = 1:length(jhorizontal1Indices)
                                if dataTraces(jhorizontal1Indices(lchan)).sampleRate >= traceSampleRate && dataTraces(jhorizontal1Indices(lchan)).sampleRate <= keptSampleRate
                                    keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                    %mchans = mchans+1;
                                    %keptchans1(mchans) = jhorizontal1Indices(lchan);
                                end
                            end
                            for lchan = 1:length(jhorizontal1Indices)
                                if dataTraces(jhorizontal1Indices(lchan)).sampleRate == keptSampleRate
                                    %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                    mchans = mchans+1;
                                    keptchans1(mchans) = jhorizontal1Indices(lchan);
                                end
                            end
                            keptchans1(keptchans1==0) = [];
                        end
                        % Repeat for ?H2
                        if jhorizontal2 > 0
                            jhorizontal2Indices = zeros(1,jhorizontal2);
                            kchan = 0;
                            for jloc=1:length(dataTraces)
                                if strcmp(sprintf('%s',dataTraces(jloc).location),uniqueLocs{iloc})
                                    if strcmp(dataTraces(jloc).channel(3),'2') 
                                        kchan = kchan + 1;
                                        jhorizontal2Indices(kchan) = jloc;
                                    end
                                end
                            end
                            keptchans2 = zeros(1,length(jhorizontal2Indices));
                            mchans = 0;
                            keptSampleRate = 1000;
                            for lchan = 1:length(jhorizontal2Indices)
                                if dataTraces(jhorizontal2Indices(lchan)).sampleRate >= traceSampleRate && dataTraces(jhorizontal2Indices(lchan)).sampleRate <= keptSampleRate
                                    keptSampleRate = dataTraces(jhorizontal2Indices(lchan)).sampleRate;
                                    %mchans = mchans+1;
                                    %keptchans2(mchans) = jhorizontal2Indices(lchan);
                                end
                            end
                            for lchan = 1:length(jhorizontal2Indices)
                                if dataTraces(jhorizontal2Indices(lchan)).sampleRate == keptSampleRate
                                    %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                    mchans = mchans+1;
                                    keptchans2(mchans) = jhorizontal2Indices(lchan);
                                end
                            end
                            keptchans2(keptchans2==0) = [];
                        end
                        % Repeat for ?H3
                        if jvertical3 > 0
                            jvertical3Indices = zeros(1,jvertical3);
                            kchan = 0;
                            for jloc=1:length(dataTraces)
                                if strcmp(sprintf('%s',dataTraces(jloc).location),uniqueLocs{iloc})
                                    if strcmp(dataTraces(jloc).channel(3),'3') 
                                        kchan = kchan + 1;
                                        jvertical3Indices(kchan) = jloc;
                                    end
                                end
                            end
                            keptchans3 = zeros(1,length(jvertical3Indices));
                            mchans = 0;
                            keptSampleRate = 1000;
                            for lchan = 1:length(jvertical3Indices)
                                if dataTraces(jvertical3Indices(lchan)).sampleRate >= traceSampleRate && dataTraces(jvertical3Indices(lchan)).sampleRate <= keptSampleRate
                                    keptSampleRate = dataTraces(jvertical3Indices(lchan)).sampleRate;
                                    %mchans = mchans+1;
                                    %keptchans2(mchans) = jhorizontal2Indices(lchan);
                                end
                            end
                            for lchan = 1:length(jvertical3Indices)
                                if dataTraces(jvertical3Indices(lchan)).sampleRate == keptSampleRate
                                    %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                    mchans = mchans+1;
                                    keptchans3(mchans) = jvertical3Indices(lchan);
                                end
                            end
                            keptchans3(keptchans3==0) = [];
                        end
                        % Repeat for ?HE
                        if jhorizontale > 0
                            jhorizontaleIndices = zeros(1,jhorizontale);
                            kchan = 0;
                            for jloc=1:length(dataTraces)
                                if strcmp(sprintf('%s',dataTraces(jloc).location),uniqueLocs{iloc})
                                    if strcmp(dataTraces(jloc).channel(3),'E') 
                                        kchan = kchan + 1;
                                        jhorizontaleIndices(kchan) = jloc;
                                    end
                                end
                            end
                            keptchanse = zeros(1,length(jhorizontaleIndices));
                            mchans = 0;
                            keptSampleRate = 1000;
                            for lchan = 1:length(jhorizontaleIndices)
                                if dataTraces(jhorizontaleIndices(lchan)).sampleRate >= traceSampleRate && dataTraces(jhorizontaleIndices(lchan)).sampleRate <= keptSampleRate
                                    keptSampleRate = dataTraces(jhorizontaleIndices(lchan)).sampleRate;
                                    %mchans = mchans+1;
                                    %keptchanse(mchans) = jhorizontaleIndices(lchan);
                                end
                            end
                            for lchan = 1:length(jhorizontaleIndices)
                                if dataTraces(jhorizontaleIndices(lchan)).sampleRate == keptSampleRate
                                    %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                    mchans = mchans+1;
                                    keptchanse(mchans) = jhorizontaleIndices(lchan);
                                end
                            end
                            keptchanse(keptchanse==0) = [];
                        end
                        % Repeat for ?HN
                        if jhorizontaln > 0
                            jhorizontalnIndices = zeros(1,jhorizontaln);
                            kchan = 0;
                            for jloc=1:length(dataTraces)
                                if strcmp(sprintf('%s',dataTraces(jloc).location),uniqueLocs{iloc})
                                    if strcmp(dataTraces(jloc).channel(3),'N') 
                                        kchan = kchan + 1;
                                        jhorizontalnIndices(kchan) = jloc;
                                    end 
                                end
                            end
                            keptchansn= zeros(1,length(jhorizontalnIndices));
                            mchans = 0;
                            keptSampleRate = 1000;
                            for lchan = 1:length(jhorizontalnIndices)
                                if dataTraces(jhorizontalnIndices(lchan)).sampleRate >= traceSampleRate && dataTraces(jhorizontalnIndices(lchan)).sampleRate <= keptSampleRate
                                    keptSampleRate = dataTraces(jhorizontalnIndices(lchan)).sampleRate;
                                    %mchans = mchans+1;
                                    %keptchansn(mchans) = jhorizontalnIndices(lchan);
                                end
                            end
                            for lchan = 1:length(jhorizontalnIndices)
                                if dataTraces(jhorizontalnIndices(lchan)).sampleRate == keptSampleRate
                                    %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                    mchans = mchans+1;
                                    keptchansn(mchans) = jhorizontalnIndices(lchan);
                                end
                            end
                            keptchansn(keptchansn==0) = [];
                        end
                        % Repeat for ?HZ
                        if jverticalz > 0
                            jverticalzIndices = zeros(1,jverticalz);
                            kchan = 0;
                            for jloc=1:length(dataTraces)
                                if strcmp(sprintf('%s',dataTraces(jloc).location),uniqueLocs{iloc})
                                    if strcmp(dataTraces(jloc).channel(3),'Z')
                                        kchan = kchan + 1;
                                        jverticalzIndices(kchan) = jloc;
                                    end
                                end
                            end
                            keptchansz = zeros(1,length(jverticalzIndices));
                            mchans = 0;
                            keptSampleRate = 1000;
                            for lchan = 1:length(jverticalzIndices)
                                if dataTraces(jverticalzIndices(lchan)).sampleRate >= traceSampleRate && dataTraces(jverticalzIndices(lchan)).sampleRate <= keptSampleRate
                                    keptSampleRate = dataTraces(jverticalzIndices(lchan)).sampleRate;
                                    %mchans = mchans+1;
                                    %keptchansz(mchans) = jverticalzIndices(lchan);
                                end
                            end
                            for lchan = 1:length(jverticalzIndices)
                                if dataTraces(jverticalzIndices(lchan)).sampleRate == keptSampleRate
                                    %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                    mchans = mchans+1;
                                    keptchansz(mchans) = jverticalzIndices(lchan);
                                end
                            end
                            keptchansz(keptchansz==0) = [];
                        end
                        
                        %channel 5...
                        if jhorizontal5 > 0
                            jhorizontal5Indices = zeros(1,jhorizontal5);
                            kchan = 0;
                            for jloc=1:length(dataTraces)
                                if strcmp(sprintf('%s',dataTraces(jloc).location),uniqueLocs{iloc})
                                    if strcmp(dataTraces(jloc).channel(3),'5') 
                                        kchan = kchan + 1;
                                        jhorizontal5Indices(kchan) = jloc;
                                    end
                                end
                            end

                            keptchans5 = zeros(1,length(jhorizontal5Indices));
                            mchans = 0;
                            keptSampleRate = 1000;
                            for lchan = 1:length(jhorizontal5Indices)
                                if dataTraces(jhorizontal5Indices(lchan)).sampleRate >= traceSampleRate && dataTraces(jhorizontal5Indices(lchan)).sampleRate <= keptSampleRate
                                    keptSampleRate = dataTraces(jhorizontal5Indices(lchan)).sampleRate;
                                    %mchans = mchans+1;
                                    %keptchans1(mchans) = jhorizontal1Indices(lchan);
                                end
                            end
                            for lchan = 1:length(jhorizontal5Indices)
                                if dataTraces(jhorizontal5Indices(lchan)).sampleRate == keptSampleRate
                                    %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                    mchans = mchans+1;
                                    keptchans5(mchans) = jhorizontal5Indices(lchan);
                                end
                            end
                            keptchans5(keptchans5==0) = [];
                        end
                        
                        % Channel 6...
                        if jhorizontal6 > 0
                            jhorizontal6Indices = zeros(1,jhorizontal6);
                            kchan = 0;
                            for jloc=1:length(dataTraces)
                                if strcmp(sprintf('%s',dataTraces(jloc).location),uniqueLocs{iloc})
                                    if strcmp(dataTraces(jloc).channel(3),'6') 
                                        kchan = kchan + 1;
                                        jhorizontal6Indices(kchan) = jloc;
                                    end
                                end
                            end

                            keptchans6 = zeros(1,length(jhorizontal6Indices));
                            mchans = 0;
                            keptSampleRate = 1000;
                            for lchan = 1:length(jhorizontal6Indices)
                                if dataTraces(jhorizontal6Indices(lchan)).sampleRate >= traceSampleRate && dataTraces(jhorizontal6Indices(lchan)).sampleRate <= keptSampleRate
                                    keptSampleRate = dataTraces(jhorizontal6Indices(lchan)).sampleRate;
                                    %mchans = mchans+1;
                                    %keptchans1(mchans) = jhorizontal1Indices(lchan);
                                end
                            end
                            for lchan = 1:length(jhorizontal6Indices)
                                if dataTraces(jhorizontal6Indices(lchan)).sampleRate == keptSampleRate
                                    %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                    mchans = mchans+1;
                                    keptchans6(mchans) = jhorizontal6Indices(lchan);
                                end
                            end
                            keptchans6(keptchans6==0) = [];
                        end

                        %% merge traces and interp
                        if ~isempty(keptchans1)
                            if length(keptchans1) > 1
                                nptsObtained = 0;
                                for itrace=keptchans1
                                    nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                                end
                                % preallocate time and amplitude
                                yMergeArray = zeros(1,nptsObtained);
                                xMergeArray = zeros(1,nptsObtained);

                                % Create x and y arrays of time and amplitudes
                                jtrace = 1;
                                for itrace=keptchans1
                                    yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                    % find time offset between this trace and the origin
                                    % populate the xMergeArray with the time (in seconds)
                                    % since the origin
                                    traceStartOffsetSeconds = dataTraces(itrace).startTime;

                                    % This method of determining the timing of fetch may
                                    % have problems when the sample rate and requested
                                    % origin are slightly off.
                                    % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                    % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                    % More robust for interpolation, but *probably* slower
                                    xMergeArray(jtrace) = traceStartOffsetSeconds;
                                    for ii=1:dataTraces(itrace).sampleCount-1
                                        xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                    end

                                    % update the jtrace - index used to find location
                                    % within the merge arrays
                                    jtrace = jtrace + dataTraces(itrace).sampleCount;

                                end

                                % interp1
                                interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                                % repack the interpolated array into dataTracesMerged
                                interpedMergedData{2} = dataTraces(keptchans1(1));
                                interpedMergedData{2}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{2}.data = interpolatedAmplitude;
                                interpedMergedData{2}.sampleCount = length(interpedMergedData{2}.data);
                                interpedMergedData{2}.sampleRate = traceSampleRate;
                                interpedMergedData{2}.endTime = endTimeEpoch;
                                interpedMergedData{2}.startTime = startTimeEpoch;

                            else
                                itrace = keptchans1(1);
                                obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                                interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                                interpedMergedData{2} = dataTraces(keptchans1(1));
                                interpedMergedData{2}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{2}.data = interpolatedAmplitude;
                                interpedMergedData{2}.sampleRate = traceSampleRate;
                                interpedMergedData{2}.sampleCount = length(interpedMergedData{2}.data);
                                interpedMergedData{2}.startTime = startTimeEpoch;
                                interpedMergedData{2}.endTime = endTimeEpoch;
                            end

                        end
                        % Repeat merge for ?H2
                        if ~isempty(keptchans2)
                            if length(keptchans2) > 1
                                nptsObtained = 0;
                                for itrace=keptchans2
                                    nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                                end
                                % preallocate time and amplitude
                                yMergeArray = zeros(1,nptsObtained);
                                xMergeArray = zeros(1,nptsObtained);

                                % Create x and y arrays of time and amplitudes
                                jtrace = 1;
                                for itrace=keptchans2
                                    yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                    % find time offset between this trace and the origin
                                    % populate the xMergeArray with the time (in seconds)
                                    % since the origin
                                    traceStartOffsetSeconds = (dataTraces(itrace).startTime - startTimeEpoch) * 24 * 60 * 60;

                                    % This method of determining the timing of fetch may
                                    % have problems when the sample rate and requested
                                    % origin are slightly off.
                                    % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                    % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                    % More robust for interpolation, but *probably* slower
                                    xMergeArray(jtrace) = traceStartOffsetSeconds;
                                    for ii=1:dataTraces(itrace).sampleCount-1
                                        xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                    end

                                    % update the jtrace - index used to find location
                                    % within the merge arrays
                                    jtrace = jtrace + dataTraces(itrace).sampleCount;

                                end

                                % interp1
                                interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                                % repack the interpolated array into dataTracesMerged
                                interpedMergedData{1} = dataTraces(keptchans2(1));
                                interpedMergedData{1}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{1}.data = interpolatedAmplitude;
                                interpedMergedData{1}.sampleCount = length(interpedMergedData{1}.data);
                                interpedMergedData{1}.sampleRate = traceSampleRate;
                                interpedMergedData{1}.endTime = endTimeEpoch;
                                interpedMergedData{1}.startTime = startTimeEpoch;

                            else
                                itrace = keptchans2(1);
                                obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                                interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                                interpedMergedData{1} = dataTraces(keptchans2(1));
                                interpedMergedData{1}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{1}.data = interpolatedAmplitude;
                                interpedMergedData{1}.sampleRate = traceSampleRate;
                                interpedMergedData{1}.sampleCount = length(interpedMergedData{1}.data);
                                interpedMergedData{1}.startTime = startTimeEpoch;
                                interpedMergedData{1}.endTime = endTimeEpoch;
                            end

                        end

                        % Repeat merge for ?H3
                        if ~isempty(keptchans3)
                            if length(keptchans3) > 1
                                nptsObtained = 0;
                                for itrace=keptchans3
                                    nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                                end
                                % preallocate time and amplitude
                                yMergeArray = zeros(1,nptsObtained);
                                xMergeArray = zeros(1,nptsObtained);

                                % Create x and y arrays of time and amplitudes
                                jtrace = 1;
                                for itrace=keptchans3
                                    yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                    % find time offset between this trace and the origin
                                    % populate the xMergeArray with the time (in seconds)
                                    % since the origin
                                    traceStartOffsetSeconds = (dataTraces(itrace).startTime - startTimeEpoch) * 24 * 60 * 60;

                                    % This method of determining the timing of fetch may
                                    % have problems when the sample rate and requested
                                    % origin are slightly off.
                                    % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                    % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                    % More robust for interpolation, but *probably* slower
                                    xMergeArray(jtrace) = traceStartOffsetSeconds;
                                    for ii=1:dataTraces(itrace).sampleCount-1
                                        xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                    end

                                    % update the jtrace - index used to find location
                                    % within the merge arrays
                                    jtrace = jtrace + dataTraces(itrace).sampleCount;

                                end

                                % interp1
                                interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                                % repack the interpolated array into dataTracesMerged
                                interpedMergedData{3} = dataTraces(keptchans3(1));
                                interpedMergedData{3}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{3}.data = interpolatedAmplitude;
                                interpedMergedData{3}.sampleCount = length(interpedMergedData{3}.data);
                                interpedMergedData{3}.sampleRate = traceSampleRate;
                                interpedMergedData{3}.endTime = endTimeEpoch;
                                interpedMergedData{3}.startTime = startTimeEpoch;

                            else
                                itrace = keptchans3(1);
                                obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                                interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                                interpedMergedData{3} = dataTraces(keptchans3(1));
                                interpedMergedData{3}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{3}.data = interpolatedAmplitude;
                                interpedMergedData{3}.sampleRate = traceSampleRate;
                                interpedMergedData{3}.sampleCount = length(interpedMergedData{3}.data);
                                interpedMergedData{3}.startTime = startTimeEpoch;
                                interpedMergedData{3}.endTime = endTimeEpoch;
                            end

                        end

                        % Repeat merge for ?HE
                        if ~isempty(keptchanse)
                            if length(keptchanse) > 1
                                nptsObtained = 0;
                                for itrace=keptchanse
                                    nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                                end
                                % preallocate time and amplitude
                                yMergeArray = zeros(1,nptsObtained);
                                xMergeArray = zeros(1,nptsObtained);

                                % Create x and y arrays of time and amplitudes
                                jtrace = 1;
                                for itrace=keptchanse
                                    yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                    % find time offset between this trace and the origin
                                    % populate the xMergeArray with the time (in seconds)
                                    % since the origin
                                    traceStartOffsetSeconds = (dataTraces(itrace).startTime - startTimeEpoch) * 24 * 60 * 60;

                                    % This method of determining the timing of fetch may
                                    % have problems when the sample rate and requested
                                    % origin are slightly off.
                                    % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                    % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                    % More robust for interpolation, but *probably* slower
                                    xMergeArray(jtrace) = traceStartOffsetSeconds;
                                    for ii=1:dataTraces(itrace).sampleCount-1
                                        xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                    end

                                    % update the jtrace - index used to find location
                                    % within the merge arrays
                                    jtrace = jtrace + dataTraces(itrace).sampleCount;

                                end

                                % interp1
                                interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                                % repack the interpolated array into dataTracesMerged
                                interpedMergedData{1} = dataTraces(keptchanse(1));
                                interpedMergedData{1}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{1}.data = interpolatedAmplitude;
                                interpedMergedData{1}.sampleCount = length(interpedMergedData{1}.data);
                                interpedMergedData{1}.sampleRate = traceSampleRate;
                                interpedMergedData{1}.endTime = endTimeEpoch;
                                interpedMergedData{1}.startTime = startTimeEpoch;

                            else
                                itrace = keptchanse(1);
                                obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                                interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                                interpedMergedData{1} = dataTraces(keptchanse(1));
                                interpedMergedData{1}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{1}.data = interpolatedAmplitude;
                                interpedMergedData{1}.sampleRate = traceSampleRate;
                                interpedMergedData{1}.sampleCount = length(interpedMergedData{1}.data);
                                interpedMergedData{1}.startTime = startTimeEpoch;
                                interpedMergedData{1}.endTime = endTimeEpoch;
                            end

                        end
                        % Repeat merge for ?HN
                        if ~isempty(keptchansn)
                            if length(keptchansn) > 1
                                nptsObtained = 0;
                                for itrace=keptchansn
                                    nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                                end
                                % preallocate time and amplitude
                                yMergeArray = zeros(1,nptsObtained);
                                xMergeArray = zeros(1,nptsObtained);

                                % Create x and y arrays of time and amplitudes
                                jtrace = 1;
                                for itrace=keptchansn
                                    yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                    % find time offset between this trace and the origin
                                    % populate the xMergeArray with the time (in seconds)
                                    % since the origin
                                    traceStartOffsetSeconds = (dataTraces(itrace).startTime - startTimeEpoch) * 24 * 60 * 60;

                                    % This method of determining the timing of fetch may
                                    % have problems when the sample rate and requested
                                    % origin are slightly off.
                                    % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                    % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                    % More robust for interpolation, but *probably* slower
                                    xMergeArray(jtrace) = traceStartOffsetSeconds;
                                    for ii=1:dataTraces(itrace).sampleCount-1
                                        xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                    end

                                    % update the jtrace - index used to find location
                                    % within the merge arrays
                                    jtrace = jtrace + dataTraces(itrace).sampleCount;

                                end

                                % interp1
                                interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                                % repack the interpolated array into dataTracesMerged
                                interpedMergedData{2} = dataTraces(keptchansn(1));
                                interpedMergedData{2}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{2}.data = interpolatedAmplitude;
                                interpedMergedData{2}.sampleCount = length(interpedMergedData{2}.data);
                                interpedMergedData{2}.sampleRate = traceSampleRate;
                                interpedMergedData{2}.endTime = endTimeEpoch;
                                interpedMergedData{2}.startTime = startTimeEpoch;

                            else
                                itrace = keptchansn(1);
                                obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                                interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                                interpedMergedData{2} = dataTraces(keptchansn(1));
                                interpedMergedData{2}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{2}.data = interpolatedAmplitude;
                                interpedMergedData{2}.sampleRate = traceSampleRate;
                                interpedMergedData{2}.sampleCount = length(interpedMergedData{2}.data);
                                interpedMergedData{2}.startTime = startTimeEpoch;
                                interpedMergedData{2}.endTime = endTimeEpoch;
                            end

                        end
                        % Repeat merge for ?HZ
                        if ~isempty(keptchansz)
                            if length(keptchansz) > 1
                                nptsObtained = 0;
                                for itrace=keptchansz
                                    nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                                end
                                % preallocate time and amplitude
                                yMergeArray = zeros(1,nptsObtained);
                                xMergeArray = zeros(1,nptsObtained);

                                % Create x and y arrays of time and amplitudes
                                jtrace = 1;
                                for itrace=keptchansz
                                    yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                    % find time offset between this trace and the origin
                                    % populate the xMergeArray with the time (in seconds)
                                    % since the origin
                                    traceStartOffsetSeconds = (dataTraces(itrace).startTime - startTimeEpoch) * 24 * 60 * 60;

                                    % This method of determining the timing of fetch may
                                    % have problems when the sample rate and requested
                                    % origin are slightly off.
                                    % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                    % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                    % More robust for interpolation, but *probably* slower
                                    xMergeArray(jtrace) = traceStartOffsetSeconds;
                                    for ii=1:dataTraces(itrace).sampleCount-1
                                        xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                    end

                                    % update the jtrace - index used to find location
                                    % within the merge arrays
                                    jtrace = jtrace + dataTraces(itrace).sampleCount;

                                end

                                % interp1
                                interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                                % repack the interpolated array into dataTracesMerged
                                interpedMergedData{3} = dataTraces(keptchansz(1));
                                interpedMergedData{3}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{3}.data = interpolatedAmplitude;
                                interpedMergedData{3}.sampleCount = length(interpedMergedData{3}.data);
                                interpedMergedData{3}.sampleRate = traceSampleRate;
                                interpedMergedData{3}.endTime = endTimeEpoch;
                                interpedMergedData{3}.startTime = startTimeEpoch;

                            else
                                itrace = keptchansz(1);
                                obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                                interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                                interpedMergedData{3} = dataTraces(keptchansz(1));
                                interpedMergedData{3}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{3}.data = interpolatedAmplitude;
                                interpedMergedData{3}.sampleRate = traceSampleRate;
                                interpedMergedData{3}.sampleCount = length(interpedMergedData{3}.data);
                                interpedMergedData{3}.startTime = startTimeEpoch;
                                interpedMergedData{3}.endTime = endTimeEpoch;
                            end

                        end
                        
                        % Repeat merge for ?H5
                        if ~isempty(keptchans5)
                            if length(keptchans5) > 1
                                nptsObtained = 0;
                                for itrace=keptchans5
                                    nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                                end
                                % preallocate time and amplitude
                                yMergeArray = zeros(1,nptsObtained);
                                xMergeArray = zeros(1,nptsObtained);

                                % Create x and y arrays of time and amplitudes
                                jtrace = 1;
                                for itrace=keptchans5
                                    yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                    % find time offset between this trace and the origin
                                    % populate the xMergeArray with the time (in seconds)
                                    % since the origin
                                    traceStartOffsetSeconds = (dataTraces(itrace).startTime - startTimeEpoch) * 24 * 60 * 60;

                                    % This method of determining the timing of fetch may
                                    % have problems when the sample rate and requested
                                    % origin are slightly off.
                                    % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                    % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                    % More robust for interpolation, but *probably* slower
                                    xMergeArray(jtrace) = traceStartOffsetSeconds;
                                    for ii=1:dataTraces(itrace).sampleCount-1
                                        xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                    end

                                    % update the jtrace - index used to find location
                                    % within the merge arrays
                                    jtrace = jtrace + dataTraces(itrace).sampleCount;

                                end

                                % interp1
                                interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                                % repack the interpolated array into dataTracesMerged
                                interpedMergedData{1} = dataTraces(keptchans5(1));
                                interpedMergedData{1}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{1}.data = interpolatedAmplitude;
                                interpedMergedData{1}.sampleCount = length(interpedMergedData{1}.data);
                                interpedMergedData{1}.sampleRate = traceSampleRate;
                                interpedMergedData{1}.endTime = endTimeEpoch;
                                interpedMergedData{1}.startTime = startTimeEpoch;

                            else
                                itrace = keptchans5(1);
                                obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                                interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                                interpedMergedData{1} = dataTraces(keptchans5(1));
                                interpedMergedData{1}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{1}.data = interpolatedAmplitude;
                                interpedMergedData{1}.sampleRate = traceSampleRate;
                                interpedMergedData{1}.sampleCount = length(interpedMergedData{1}.data);
                                interpedMergedData{1}.startTime = startTimeEpoch;
                                interpedMergedData{1}.endTime = endTimeEpoch;
                            end

                        end

                        % Repeat merge for ?H6
                        if ~isempty(keptchans6)
                            if length(keptchans6) > 1
                                nptsObtained = 0;
                                for itrace=keptchans6
                                    nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                                end
                                % preallocate time and amplitude
                                yMergeArray = zeros(1,nptsObtained);
                                xMergeArray = zeros(1,nptsObtained);

                                % Create x and y arrays of time and amplitudes
                                jtrace = 1;
                                for itrace=keptchans6
                                    yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                    % find time offset between this trace and the origin
                                    % populate the xMergeArray with the time (in seconds)
                                    % since the origin
                                    traceStartOffsetSeconds = (dataTraces(itrace).startTime - startTimeEpoch) * 24 * 60 * 60;

                                    % This method of determining the timing of fetch may
                                    % have problems when the sample rate and requested
                                    % origin are slightly off.
                                    % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                    % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                    % More robust for interpolation, but *probably* slower
                                    xMergeArray(jtrace) = traceStartOffsetSeconds;
                                    for ii=1:dataTraces(itrace).sampleCount-1
                                        xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                    end

                                    % update the jtrace - index used to find location
                                    % within the merge arrays
                                    jtrace = jtrace + dataTraces(itrace).sampleCount;

                                end

                                % interp1
                                interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                                % repack the interpolated array into dataTracesMerged
                                interpedMergedData{2} = dataTraces(keptchans6(1));
                                interpedMergedData{2}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{2}.data = interpolatedAmplitude;
                                interpedMergedData{2}.sampleCount = length(interpedMergedData{2}.data);
                                interpedMergedData{2}.sampleRate = traceSampleRate;
                                interpedMergedData{2}.endTime = endTimeEpoch;
                                interpedMergedData{2}.startTime = startTimeEpoch;

                            else
                                itrace = keptchans6(1);
                                obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                                interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                                interpedMergedData{2} = dataTraces(keptchans6(1));
                                interpedMergedData{2}.data = zeros(1,length(interpolatedAmplitude));
                                interpedMergedData{2}.data = interpolatedAmplitude;
                                interpedMergedData{2}.sampleRate = traceSampleRate;
                                interpedMergedData{2}.sampleCount = length(interpedMergedData{2}.data);
                                interpedMergedData{2}.startTime = startTimeEpoch;
                                interpedMergedData{2}.endTime = endTimeEpoch;
                            end

                        end

                        
                        
                        %% So now for this combination of station and location
                        % code, we have a triple cell array interpedMergedData
                        ierr = 0;
                        % Check for common instrument and location code
                        if isempty(interpedMergedData{1}) || isempty(interpedMergedData{2}) || isempty(interpedMergedData{3})
                            ierr = 1;
                        end
                        if ierr == 0
                            if ~strcmp(interpedMergedData{1}.location, interpedMergedData{2}.location) || ~strcmp(interpedMergedData{1}.location,interpedMergedData{3}.location) || ~strcmp(interpedMergedData{2}.location,interpedMergedData{3}.location)
                                ierr = 1;
                            end
                        end
                        if ierr == 0
                            if ~strcmp(interpedMergedData{1}.instrument, interpedMergedData{2}.instrument) || ~strcmp(interpedMergedData{1}.instrument,interpedMergedData{3}.instrument) || ~strcmp(interpedMergedData{2}.instrument,interpedMergedData{3}.instrument)
                                ierr = 1;
                        	end
                        end
                                
                        % Rotate
                        if ierr == 0
                            [rotatedInterpedMergedData, ierr] = FL_rotateCellTripleToENZ(interpedMergedData);
                        end
                        
                        % remove response:
                        if ierr == 0
                            [DeconnedData, ierr] = FL_responseRemoval( rotatedInterpedMergedData, 0.002, traceResponseSelection );
                        end


                        %% Split at this point.
                        % 1. If we are using the traditional single station
                        % deconvolution method, then we can compute that here and
                        % write files.
                        % 2. If we are using the array based source method of
                        % deconvolution, then we'll need to start computing the
                        % source function and write three component data files
                        % Write E,N,Z sac files in RAWTRACES
                        if ierr == 0
                            [writtenTraces, ierr] = FL_writeFetchedTraces(DeconnedData, ProjectDirectory, 'RAWTRACES', traceResponseSelection, eventInfo, ievent);
                        end

                        % keep track of files written
                        if ierr == 0
                            iistation = iistation + 1;
                            rawTracesFileNames{ievent,iistation} = sprintf('%s %s %s',writtenTraces{1}.fullSacFileName, writtenTraces{2}.fullSacFileName, writtenTraces{3}.fullSacFileName);
                        end
    %                     figure(2)
    %                     subplot(3,1,1)
    %                     plot(outputTimeArray,DeconnedData{1}.data,'k-');
    %                     subplot(3,1,2)
    %                     plot(outputTimeArray,DeconnedData{2}.data,'k-');
    %                     subplot(3,1,3)
    %                     plot(outputTimeArray,DeconnedData{3}.data,'k-');
                    end  % loop for each unique location code
                end  % if there are three channels exactly
            end % if start and end time are able to be computed
        else
            fprintf('Skipping station %s %d %f\n',cleanStationInfo.stations{istation},istation, gcarc);
        end  % if station is in distance window
    end  % station loop
    
    %% RF processing now
    %  Split between deconvolution based on the station or on the array
    %  Deal with it in another subroutine and write the files into the
    %  rawtraces directory. We will then copy them into rawdata later
    if iistation >= 1 
        FL_processAndWriteRFS(FL_rfOpt(1), rawTracesFileNames, ievent, nstations, ProjectDirectory, 'eqr',1,FL_rfOpt(2));
        FL_processAndWriteRFS(FL_rfOpt(2), rawTracesFileNames, ievent, nstations, ProjectDirectory, 'eqt',2,FL_rfOpt(1));
    else
        fprintf('No stations for event %s\n',eventInfo.OriginTime{ievent});
    end
    
end   % event loop

%% set data directory
DataDirectory = fullfile(ProjectDirectory, 'RAWTRACES');
DataDir{1} = DataDirectory;
DirName = strread(DataDirectory,'%s','delimiter',filesep);
DirName = DirName{end};
if ~exist([ProjectDirectory, 'RAWDATA', filesep, DirName],'dir')
    copyfile(DataDirectory,[ProjectDirectory, 'RAWDATA', filesep, DirName])
    [RecordMetadataStrings,RecordMetadataDoubles] = fl_add_new_data(ProjectDirectory,'Project.mat',DirName);
end

% Prepare project wide data
if evalin('base','~exist(''FuncLabPreferences'',''var'')')
    FuncLabPreferences = fl_default_prefs(RecordMetadataDoubles);
else
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    if length(FuncLabPreferences) < 21
        FuncLabPreferences{19} = 'parula.cpt';
        FuncLabPreferences{20} = false;
        FuncLabPreferences{21} = '1.8.2';
    end
end

% Put in limits to station map preference
FuncLabPreferences{13} = sprintf('%f',max(cleanStationInfo.latitudes));
FuncLabPreferences{14} = sprintf('%f',min(cleanStationInfo.latitudes));
FuncLabPreferences{15} = sprintf('%f',min(cleanStationInfo.longitudes));
FuncLabPreferences{16} = sprintf('%f',max(cleanStationInfo.longitudes));

if evalin('base','~exist(''TraceEditPreferences'',''var'')')
    te_default_prefs;
else
    TraceEditPreferences = evalin('base','TraceEditPreferences');
end
Tablemenu = {'Station Tables','RecordMetadata',2,3,'Stations: ','Records (Listed by Event)','Events: ','fl_record_fields','string';
    'Event Tables','RecordMetadata',3,2,'Events: ','Records (Listed by Station)','Stations: ','fl_record_fields','string'};
save([ProjectDirectory 'Project.mat'],'TraceEditPreferences','FuncLabPreferences','Tablemenu','-append')

SetManagementCell = cell(1,6);
SetManagementCell{1,1} = 1:size(RecordMetadataDoubles,1);
SetManagementCell{1,2} = RecordMetadataStrings;
SetManagementCell{1,3} = RecordMetadataDoubles;
SetManagementCell{1,4} = Tablemenu;
SetManagementCell{1,5} = 'Base';
SetManagementCell{1,6} = [0.6 0 0];
assignin('base','SetManagementCell',SetManagementCell);
assignin('base','CurrentSubsetIndex',1);
save([ProjectDirectory 'Project.mat'],'SetManagementCell','-append');

fl_init_logfile([ProjectDirectory 'Logfile.txt'],DataDir)
fl_datainfo(ProjectDirectory,'Project.mat',RecordMetadataStrings,RecordMetadataDoubles)
set(h.project_t,'string',ProjectDirectory)
set(h.new_title_t,'visible','off')
set(h.new_projdir_t,'visible','off')
set(h.new_projdir_e,'visible','off')
set(h.new_adddata_t,'visible','off')
set(h.new_start_pb,'visible','off')
set(h.explorer_fm,'visible','on')
set(h.tablemenu_pu,'visible','on')
set(h.tablesinfo_t,'visible','on')
set(h.tables_ls,'visible','on')
set(h.records_t,'visible','on')
set(h.recordsinfo_t,'visible','on')
set(h.records_ls,'visible','on')
set(h.info_t,'visible','on')
set(h.info_ls,'visible','on')
set(h.new_m,'Enable','off')
set(h.new_fetch_m,'Enable','off')
set(h.load_m,'Enable','off')
set(h.add_m,'Enable','on')
set(h.param_m,'Enable','on')
set(h.log_m,'Enable','on')
set(h.close_m,'Enable','on')
set(h.manual_m,'Enable','on')
set(h.autoselect_m,'Enable','on')
set(h.autoall_m,'Enable','on')
set(h.im_te_m,'Enable','on')
set(h.tepref_m,'Enable','on')
set(h.recompute_rayp_m,'Enable','on')
set(h.seis_m,'Enable','on')
set(h.record_m,'Enable','on')
set(h.stacked_record_m,'Enable','on')
set(h.moveout_m,'Enable','on')
set(h.moveout_image_m,'Enable','on')
%set(h.origintime_image_m,'Enable','on')
%set(h.origintime_wiggles_m,'Enable','on')
set(h.rf_cross_section_time_m,'Enable','on');
set(h.rf_cross_section_depth_stack_m,'Enable','on');
set(h.baz_m,'Enable','on')
set(h.baz_image_m,'Enable','on')
set(h.datastats_m,'Enable','on')
set(h.stamap_m,'Enable','on')
set(h.evtmap_m,'Enable','on')
set(h.datadiagram_m,'Enable','on')
set(h.ex_stations_m,'Enable','on')
set(h.ex_events_m,'Enable','on')
set(h.ex_te_m,'Enable','on')
set(h.ex_rfs_m,'Enable','on')
set(h.PRF_to_depth_m,'Enable','on')
set(h.create_new_subset_m,'Enable','on')
if isfield(h,'addons')
    addons = h.addons;
    for n = 1:length(addons)
        eval(['set(h.' addons{n} '_m,''Enable'',''on'')'])
    end
end

% Turn off all the fetch buttons
set(h.new_fetch_title_t,'visible','off')
set(h.new_fetch_projdir_t,'visible','off')
set(h.new_fetch_projdir_e,'visible','off')
set(h.new_fetch_start_pb,'visible','off')
set(h.new_fetch_get_map_coords_pb,'visible','off')
set(h.new_fetch_lat_max_e,'visible','off');
set(h.new_fetch_lat_min_e,'visible','off');
set(h.new_fetch_lon_max_e,'visible','off');
set(h.new_fetch_lon_min_e,'visible','off');
set(h.new_fetch_get_stations_pb,'visible','off');
set(h.new_fetch_station_panel,'visible','off');
set(h.new_fetch_events_panel,'Visible','off');
set(h.new_fetch_search_start_time_text,'Visible','off');
set(h.new_fetch_search_end_time_text,'Visible','off');
set(h.new_fetch_start_year_pu,'visible','off');
set(h.new_fetch_start_month_pu,'visible','off');
set(h.new_fetch_start_day_pu,'visible','off');
set(h.new_fetch_end_year_pu,'visible','off');
set(h.new_fetch_end_month_pu,'visible','off');
set(h.new_fetch_end_day_pu,'visible','off');
set(h.new_fetch_search_magnitude_text,'visible','off');
set(h.new_fetch_min_mag_pu,'visible','off');
set(h.new_fetch_max_mag_pu,'visible','off');
set(h.new_fetch_event_mag_divider_t,'Visible','off');
set(h.new_fetch_search_distance_text,'Visible','off');
set(h.new_fetch_max_dist_e,'Visible','off');
set(h.new_fetch_min_dist_e,'Visible','off');
set(h.new_fetch_event_distance_divider_t,'Visible','off');
set(h.new_fetch_find_events_pb,'Visible','off');
set(h.new_fetch_max_depth_e,'Visible','off');
set(h.new_fetch_min_depth_e,'Visible','off');
set(h.new_fetch_search_depth_text,'Visible','off');
set(h.new_fetch_event_depth_divider_t,'Visible','off');
set(h.new_fetch_search_depth_text,'visible','off');
set(h.new_fetch_traces_panel,'visible','off');
%set(h.new_fetch_traces_timing_text,'Visible','off');
%set(h.new_fetch_traces_seconds_before_edit,'Visible','off');
%set(h.new_fetch_traces_phase_popup,'Visible','off');
set(h.new_fetch_traces_start_phase_popup,'Visible','off');
set(h.new_fetch_traces_start_time_text,'Visible','off');
set(h.new_fetch_traces_prior_seconds_edit,'Visible','off');
set(h.new_fetch_traces_start_seconds_label,'Visible','off');
set(h.new_fetch_traces_start_before_or_after_popup,'Visible','off');
set(h.new_fetch_traces_end_phase_popup,'Visible','off');
set(h.new_fetch_traces_end_time_text,'Visible','off');
set(h.new_fetch_traces_after_seconds_edit,'Visible','off');
set(h.new_fetch_traces_end_seconds_label,'Visible','off');
set(h.new_fetch_traces_end_before_or_after_popup,'Visible','off');
set(h.new_fetch_traces_end_phase_popup,'Visible','off');
set(h.new_fetch_traces_sample_rate_text,'Visible','off');
set(h.new_fetch_traces_sample_rate_popup,'Visible','off');
set(h.new_fetch_traces_sample_rate_label,'Visible','off');
set(h.new_fetch_traces_debug_button,'Visible','off');
set(h.easterEggPanel,'Visible','off');
set(h.new_fetch_rfprocessing_params_panel,'Visible','off');
set(h.new_fetch_traces_response_text,'Visible','off');
set(h.new_fetch_traces_response_popup,'Visible','off');
set(h.new_fetch_rfprocessing_taper_popup,'Visible','off');
set(h.new_fetch_rfprocessing_taper_text,'Visible','off');
set(h.new_fetch_rfprocessing_high_pass_edit,'Visible','off');
set(h.new_fetch_rfprocessing_filter_high_pass_text,'Visible','off');
set(h.new_fetch_rfprocessing_low_pass_edit,'Visible','off');
set(h.new_fetch_rfprocessing_filter_low_pass_text,'Visible','off');
set(h.new_fetch_rfprocessing_filter_order_text,'Visible','off');
set(h.new_fetch_rfprocessing_order_popup,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_edit,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_edit,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_text,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_text,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_text,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_popup,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_text,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_popup,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_edit,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_text,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_text,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_text,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_text,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_edit,'Visible','off');
set(h.new_fetch_rfprocessing_primary_choice_text,'Visible','off');
set(h.new_fetch_rfprocessing_secondary_choice_text,'Visible','off');
set(h.new_fetch_rfprocessing_taper_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_high_pass_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_low_pass_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_order_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_popup,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_2_popup,'Visible','off');


assignin('base','RecordMetadataStrings',RecordMetadataStrings)
assignin('base','RecordMetadataDoubles',RecordMetadataDoubles)
assignin('base','Tablemenu',Tablemenu)
set(h.tablemenu_pu,'String',Tablemenu(:,1))
TableValue = 1;
set(h.tablemenu_pu,'Value',TableValue)
Tables = sort(unique(RecordMetadataStrings(:,2)));
set(h.tables_ls,'String',Tables)
set(h.tablesinfo_t,'String',[Tablemenu{TableValue,5} num2str(length(Tables))])
set(h.records_t,'String',Tablemenu{TableValue,6})
set(h.message_t,'String','Message:')
%close(WaitGui)
tables_Callback



