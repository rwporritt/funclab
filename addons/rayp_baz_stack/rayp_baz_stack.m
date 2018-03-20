function rayp_baz_stack(MainGui)
% RAYP_BAZ Start the RAYP_BAZ stacking GUI
%   This addon allows the user to set bin windows to stack over a
%   2-dimensional set of ray parameter and back azimuth.
%   The stacks are output as SAC files in a new directory called
%   RAYP_BAZ_STACKS in the project directory.
%   Mean and 1 sigma standard deviations are output
%
%   Closely based on hk.m
%
%   Author: Robert W. Porritt
%   Created: Oct. 7th, 2014
%

ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% GUI initiation
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Setup dimensions of the GUI
%--------------------------------------------------------------------------
MainPos = [0 0 130 26];
ParamTitlePos = [0 MainPos(4)-2 80 1.25];
ParamTextPos1 = [1 0 31 1.75];
ParamOptionPos1 = [32 0 7 1.75];
ParamTextPos2 = [41 0 30 1.75];
ParamOptionPos2 = [72 0 7 1.75];
ProcTitlePos = [80 MainPos(4)-2 50 1.25];
ProcButtonPos = [82 0 46 3];
CloseButtonPos = [90 3 30 3];

%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
RAYP_BAZ_Gui = dialog('Name','RayP and Baz Stacking Export','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'});



%--------------------------------------------------------------------------
% RAYP_BAZ Top Menu Items
%--------------------------------------------------------------------------
MPlotting = uimenu(RAYP_BAZ_Gui,'Label','Plotting');
% Creates a polar plot with the station in the center, back azimuth around
% the edges, and distance is the ray parameter
uimenu(MPlotting,'Label','Station Hit Chart','Tag','station_hit_chart_rayp_baz_m','Enable','Off','Callback',{@rayp_baz_view_hit_chart});
% Consider also a plot of all the stacks in a pseudo arrangement around
% the station and buttons to activate or de-activate




%--------------------------------------------------------------------------
% Rayp_Baz Parameters
%--------------------------------------------------------------------------
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];

% Parameters we need:
% min, max, inc RayP   - textboxes
% min, max, inc Baz    - text boxes
% single station or all stations - pull-down
% min hits in bin?     - text box
% active records or all records  - pull-down

% Set default parameters - consider building a GUI to set these, or a
% button to save them
minRayP = 0.04;
maxRayP = 0.08;
incRayP = 0.01;
minBaz = 0;
maxBaz = 360;
incBaz = 45;
minHitsPerBin = 1;
outputStartTime = -5;
outputEndTime = 40;
outputSampleRate = 0.1;
stationsToStack = sprintf('All Stations');  % note that to change these, change the "value" option
activeOrAllRecords = sprintf('Active Only');



% convert the numeric parameters to strings for view
DefaultMinRayP_s = sprintf('%03.3f',minRayP);
DefaultMaxRayP_s = sprintf('%03.3f',maxRayP);
DefaultIncRayP_s = sprintf('%03.3f',incRayP);
DefaultMinBaz_s = sprintf('%03.0f',minBaz);
DefaultMaxBaz_s = sprintf('%03.0f',maxBaz);
DefaultIncBaz_s = sprintf('%03.0f',incBaz);
DefaultOutputStartTime_s = sprintf('%03.0f',outputStartTime);
DefaultOutputEndTime_s = sprintf('%03.0f',outputEndTime);
DefaultOutputSampleRate_s = sprintf('%03.3f',outputSampleRate);
DefaultMinHitsPerBin_s = sprintf('%2.0f',minHitsPerBin);


uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','title_t','String','RayP-BAZ Parameters',...
    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',1,'HorizontalAlignment','center');
ParamTextPos1(2) = 21;
ParamOptionPos1(2) = 21;
ParamTextPos2(2) = 21;
ParamOptionPos2(2) = 21;
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','min_rayp_t','String','Ray Parameter Min. (s/km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','edit','Units','characters','Tag','min_rayp_e','String',DefaultMinRayP_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','min_baz_t','String','Backazimuth Min.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','edit','Units','characters','Tag','min_baz_e','String',DefaultMinBaz_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 18;
ParamOptionPos1(2) = 18;
ParamTextPos2(2) = 18;
ParamOptionPos2(2) = 18;
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','max_rayp_t','String','Ray Parameter Max. (s/km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','edit','Units','characters','Tag','max_rayp_e','String',DefaultMaxRayP_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','max_baz_t','String','Backazimuth Max.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','edit','Units','characters','Tag','max_baz_e','String',DefaultMaxBaz_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 15;
ParamOptionPos1(2) = 15;
ParamTextPos2(2) = 15;
ParamOptionPos2(2) = 15;
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','inc_rayp_t','String','Ray Parameter Inc. (s/km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','edit','Units','characters','Tag','inc_rayp_e','String',DefaultIncRayP_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','inc_baz_t','String','Backazimuth Inc.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','edit','Units','characters','Tag','inc_baz_e','String',DefaultIncBaz_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 12;
ParamOptionPos1(2) = 12;
ParamTextPos2(2) = 12;
ParamOptionPos2(2) = 12;
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','min_hits_t','String','Min Hits Per Bin',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','edit','Units','characters','Tag','min_hits_e','String',DefaultMinHitsPerBin_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','unused_min_hits_t','String','(Currently unused)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
ParamTextPos1(2) = 9;
ParamOptionPos1(2) = 9;
ParamTextPos2(2) = 9;
ParamOptionPos2(2) = 9;
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','output_start_time_t','String','Output Start Time (sec)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','edit','Units','characters','Tag','output_start_time_e','String',DefaultOutputStartTime_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','output_end_time_t','String','Output End Time (sec)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','edit','Units','characters','Tag','output_end_time_e','String',DefaultOutputEndTime_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 6;
ParamOptionPos1(2) = 6;
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','output_sample_rate_t','String','Output Sample Rate (sec)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','edit','Units','characters','Tag','output_sample_rate_e','String',DefaultOutputSampleRate_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 3;
ParamOptionPos1(2) = 3;
ParamOptionPos1(3) = 30;
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','stations_to_stack_t','String','Stations to Stack',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','popupmenu','Units','characters','Tag','stations_to_stack_pd','String',{'Active Station Only','All Stations'},...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'Value',1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left');
ParamTextPos1(2) = 1;
ParamOptionPos1(2) = 1;
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','active_or_all_records_t','String','Active or all records',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','popupmenu','Units','characters','Tag','active_or_all_records_pd','String',{'Active Only','All Records'},...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'Value',1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');


%--------------------------------------------------------------------------
% Stack Processing
%--------------------------------------------------------------------------
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','text','Units','characters','Tag','title_t','String','RayP-Baz Stacking',...
    'Position',ProcTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',1,'HorizontalAlignment','center');
ProcButtonPos(2) = 20;
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','pushbutton','Units','characters','Tag','primary_stack_b','String','Stack Primary RFs',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@rayp_baz_primary_stack});
ProcButtonPos(2) = 16;
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','pushbutton','Units','characters','Tag','secondary_stack_b','String','Stack Secondary RFs',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold','Enable','off',...
    'Callback',{@rayp_baz_secondary_stack});
CloseButtonPos(2) = 2;
uicontrol ('Parent',RAYP_BAZ_Gui,'Style','pushbutton','Units','characters','Tag','rayp_baz_close_b','String','Close',...
    'Position',CloseButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@close_rayp_baz_Callback});


handles = guihandles(RAYP_BAZ_Gui);
handles.MainGui = MainGui;
guidata(RAYP_BAZ_Gui,handles);


set(handles.primary_stack_b,'Enable','on')
set(handles.secondary_stack_b,'Enable','on')
set(handles.active_or_all_records_pd,'Enable','on')
set(handles.stations_to_stack_pd,'Enable','on')
set(handles.min_hits_e,'Enable','on')
set(handles.inc_baz_e,'Enable','on')
set(handles.inc_rayp_e,'Enable','on')
set(handles.max_baz_e,'Enable','on')
set(handles.max_rayp_e,'Enable','on')
set(handles.min_baz_e,'Enable','on')
set(handles.min_rayp_e,'Enable','on')
set(handles.output_start_time_e,'Enable','on')
set(handles.output_end_time_e,'Enable','on')
set(handles.output_sample_rate_e,'Enable','on')
set(handles.station_hit_chart_rayp_baz_m,'Enable','on')





%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Subfunction Callbacks
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% hkclose_Callback
%
% This callback function closes the project and removes variables from the
% workspace.
%--------------------------------------------------------------------------
function close_rayp_baz_Callback(cbo,eventdata,handles)
close(gcf)
