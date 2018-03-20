function hk(MainGui)
%HK Start the H-k GUI
%   HK initiates the H-k stacking analysis GUI.  The user is able to run
%   all of the FuncLab commands from this interface with a push of a
%   button.

%   Author: Kevin C. Eagar
%   Date Created: 01/09/2009
%   Last Updated: 04/24/2011

%  Edit Robert Porritt
%  Nov 2014
%  Added option to save H-k parameters which are then reloaded on next
%  calling
%  May 2015
%  Added option to manually determine Ps conversion
%  Adjust to work with multiple subsets. Updates the SetManagementCell's
%  table menu for the current set. The HkMetadata is now contained in a
%  management cell with the set index.

ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

% Sets the name of the set. Removes white spaces and capitalizes between
% words
if CurrentSubsetIndex ~= 1
    SetName = SetManagementCell{CurrentSubsetIndex,5};
    % Remove spaces because they make filesystems go a little haywire
    % sometimes
    SpaceIDX = isspace(SetName);
    for idx=2:length(SetName)
        if isspace(SetName(idx-1))
            SetName(idx) = upper(SetName(idx));
        end
    end
    SetName = SetName(~SpaceIDX);
else
    SetName = 'Base';
end

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% GUI initiation
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Setup dimensions of the GUI
%--------------------------------------------------------------------------
MainPos = [0 0 130 34];
ParamTitlePos = [0 MainPos(4)-2 80 1.25];
ParamTextPos1 = [1 0 31 1.75];
ParamOptionPos1 = [32 0 7 1.75];
ParamTextPos2 = [41 0 30 1.75];
ParamOptionPos2 = [72 0 7 1.75];
ProcTitlePos = [80 MainPos(4)-2 50 1.25];
ProcButtonPos = [82 0 46 3];
CloseButtonPos = [90 3 30 3];
AccentColor = [.6 0 0];

%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
HKGui = dialog('Name','H-k Stacking Analysis','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'});

%--------------------------------------------------------------------------
% H-k Top Menu Items (for plotting)
%--------------------------------------------------------------------------
MExport = uimenu(HKGui,'Label','Export');
uimenu(MExport,'Label','H-k Grids','Tag','ex_grids_m','Enable','off','Callback',{@hk_ex_grids});
uimenu(MExport,'Label','H-k Solutions','Tag','ex_solutions_m','Enable','off','Callback',{@hk_ex_solutions});
MPlotting = uimenu(HKGui,'Label','Plotting');
uimenu(MPlotting,'Label','Station Moveout Image','Tag','moveoutimage_m','Enable','off','Callback',{@hk_view_moveout_image});
uimenu(MPlotting,'Label','Station Backazimuth Image','Tag','bazimage_m','Enable','off','Callback',{@hk_view_baz_image});
uimenu(MPlotting,'Label','Station Receiver Function Stack','Tag','stationstack_m','Enable','off','Callback',{@hk_view_stacked_records});
uimenu(MPlotting,'Label','H-k Grid','Tag','hkgrid_m','Enable','off','Callback',{@hk_view_hkgrid});


% Default parameters - load if possible, else use reasonable defaults
%--------------------------------------------------------------------------
load([ProjectDirectory ProjectFile]);
if exist('HKParams','var')   % If the structure has been saved to the project file
    ResampleNumber = HKParams.ResampleNumber;
    RandomSelectionCount = HKParams.RandomSelectionCount * 100;  % note this is in percent
    RayParameterMin = HKParams.RayParameterMin;
    RayParameterMax = HKParams.RayParameterMax;
    BackAzimuthMin = HKParams.BackazimuthMin;
    BackAzimuthMax = HKParams.BackazimuthMax;
    TimeMin = HKParams.TimeMin;
    TimeMax = HKParams.TimeMax;
    TimeDelta = HKParams.TimeDelta;
    AssumedVp = HKParams.AssumedVp;
    HMin = HKParams.HMin;
    HMax = HKParams.HMax;
    HDelta = HKParams.HDelta;
    kMin = HKParams.kMin;
    kMax = HKParams.kMax;
    kDelta = HKParams.kDelta;
    w1 = HKParams.w1;
    w2 = HKParams.w2;
    w3 = HKParams.w3;
    Error = HKParams.Error;
else
    ResampleNumber = 50;
    RandomSelectionCount = 150;
    RayParameterMin = 0.04;
    RayParameterMax = 0.08;
    BackAzimuthMin = 0;
    BackAzimuthMax = 360;
    TimeMin = 0;
    TimeMax = 35;
    TimeDelta = 0.025;
    AssumedVp = 6.1;
    HMin = 20;
    HMax = 60;
    HDelta = 0.5;
    kMin = 1.6;
    kMax = 2.1;
    kDelta = 0.01;
    w1 = 0.7;
    w2 = 0.2;
    w3 = 0.1;
    Error = 1;
end
% Convert to strings as necessary
ResampleNumber_s =sprintf('%3.0f',ResampleNumber);
RandomSelectionCount_s = sprintf('%3.0f',RandomSelectionCount);
RayParameterMin_s = sprintf('%3.2f',RayParameterMin);
RayParameterMax_s = sprintf('%3.2f',RayParameterMax);
BackAzimuthMin_s = sprintf('%3.0f',BackAzimuthMin);
BackAzimuthMax_s = sprintf('%3.0f',BackAzimuthMax);
TimeMin_s = sprintf('%3.0f',TimeMin);
TimeMax_s = sprintf('%3.0f',TimeMax);
TimeDelta_s = sprintf('%3.3f',TimeDelta);
AssumedVp_s = sprintf('%3.1f',AssumedVp);
HMin_s = sprintf('%3.0f',HMin);
HMax_s = sprintf('%3.0f',HMax);
HDelta_s = sprintf('%3.1f',HDelta);
kMin_s = sprintf('%3.1f',kMin);
kMax_s = sprintf('%3.1f',kMax);
kDelta_s = sprintf('%3.2f',kDelta);
w1_s = sprintf('%3.1f',w1);
w2_s = sprintf('%3.1f',w2);
w3_s = sprintf('%3.1f',w3);



%--------------------------------------------------------------------------
% H-k Parameters
%--------------------------------------------------------------------------
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;

uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','title_t','String','H-k Parameters',...
    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',1,'HorizontalAlignment','center');
ParamTextPos1(2) = 29;
ParamOptionPos1(2) = 29;
ParamTextPos2(2) = 29;
ParamOptionPos2(2) = 29;
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','bootresamples_t','String','Bootstrap Resamples',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','bootresamples_e','String',ResampleNumber_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','bootpercent_t','String','Bootstrap Percentage',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','bootpercent_e','String',RandomSelectionCount_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 26;
ParamOptionPos1(2) = 26;
ParamTextPos2(2) = 26;
ParamOptionPos2(2) = 26;
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','hmax_t','String','H (depth) Max.',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','hmax_e','String',HMax_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','kmax_t','String','k (Vp/Vs) Max.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','kmax_e','String',kMax_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 23;
ParamOptionPos1(2) = 23;
ParamTextPos2(2) = 23;
ParamOptionPos2(2) = 23;
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','hmin_t','String','H (depth) Min.',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','hmin_e','String',HMin_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','kmin_t','String','k (Vp/Vs) Min.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','kmin_e','String',kMin_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 20;
ParamOptionPos1(2) = 20;
ParamTextPos2(2) = 20;
ParamOptionPos2(2) = 20;
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','hdelta_t','String','H (depth) Delta',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','hdelta_e','String',HDelta_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','kdelta_t','String','k (Vp/Vs) Delta',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','kdelta_e','String',kDelta_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left');
ParamTextPos1(2) = 17;
ParamOptionPos1(2) = 17;
ParamTextPos2(2) = 17;
ParamOptionPos2(2) = 17;
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','w1_t','String','Weight 1 (Ps)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','w1_e','String',w1_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','timemax_t','String','Time Axis Max.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','timemax_e','String',TimeMax_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 14;
ParamOptionPos1(2) = 14;
ParamTextPos2(2) = 14;
ParamOptionPos2(2) = 14;
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','w2_t','String','Weight 2 (PpPs)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','w2_e','String',w2_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','timemin_t','String','Time Axis Min.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','timemin_e','String',TimeMin_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 11;
ParamOptionPos1(2) = 11;
ParamTextPos2(2) = 11;
ParamOptionPos2(2) = 11;
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','w3_t','String','Weight 3 (PpSs+PsPs)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','w3_e','String',w3_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','timedelta_t','String','Time Axis Delta',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','timedelta_e','String',TimeDelta_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 8;
ParamOptionPos1(2) = 8;
ParamTextPos2(2) = 8;
ParamOptionPos2(2) = 8;
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','raypmax_t','String','Ray Parameter Max. (s/km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','raypmax_e','String',RayParameterMax_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','bazmax_t','String','Backazimuth Max.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','bazmax_e','String',BackAzimuthMax_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 5;
ParamOptionPos1(2) = 5;
ParamTextPos2(2) = 5;
ParamOptionPos2(2) = 5;
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','raypmin_t','String','Ray Parameter Min. (s/km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','raypmin_e','String',RayParameterMin_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','bazmin_t','String','Backazimuth Min.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','bazmin_e','String',BackAzimuthMin_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 2;
ParamOptionPos1(2) = 2;
ParamTextPos2(2) = 2;
ParamOptionPos2(2) = 2;
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','vp_t','String','Assumed Vp',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','edit','Units','characters','Tag','vp_e','String',AssumedVp_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamOptionPos2(1) = 52;
ParamOptionPos2(3) = 27;
Comps = {'Bootstrap','Standard Error'};
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','error_t','String','Error',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',HKGui,'Style','popupmenu','Units','characters','Tag','error_p','String',Comps,'Value',Error,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');

%--------------------------------------------------------------------------
% H-k Processing
%--------------------------------------------------------------------------
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','title_t','String','H-k Processes',...
    'Position',ProcTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',1,'HorizontalAlignment','center');
ProcButtonPos(2) = 28;
uicontrol ('Parent',HKGui,'Style','pushbutton','Units','characters','Tag','singlestack_b','String','H-k Stack (Single Station)',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@hk_singlestack});
ProcButtonPos(2) = 24;
uicontrol ('Parent',HKGui,'Style','pushbutton','Units','characters','Tag','allstacks_b','String','H-k Stacks (All Stations)',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold','Enable','off',...
    'Callback',{@hk_allstack});
ProcButtonPos(2) = 20;
uicontrol ('Parent',HKGui,'Style','pushbutton','Units','characters','Tag','saveparams_b','String','Save H-k Parameters',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold','Enable','off',...
    'Callback',{@hk_saveparams});
% update for 1.7.6 - allows user to select time limits for Ps conversion
% graphically
ProcButtonPos(2) = 16;
uicontrol ('Parent',HKGui,'Style','pushbutton','Units','characters','Tag','manual_set_time_b','String','Manually set time window',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold','Enable','off',...
    'Callback',{@hk_manual_set_time});

% Update for 1.7.6 - allows the user to manually choose time windows for
% the all stack. Bad for bulk processing, but good for QC and improved
% estimates
ProcTextPos = ParamTextPos1;
ProcTextPos(1) = ProcButtonPos(1);
ProcTextPos(2) = 12;
ProcTextPos(4) = 2.5;
TextFontSize = 0.45;
uicontrol ('Parent',HKGui,'Style','text','Units','characters','Tag','manual_time_all_text','String','Manually set time windows (All Stations)',...
    'Position',ProcTextPos,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
CheckBoxPos = ProcTextPos;
CheckBoxPos(1) = ProcTextPos(1)+ProcTextPos(3)+3;
uicontrol('Parent',HKGui,'Style','Checkbox','Units','Characters','Tag','manual_time_all_cb','Value',0,...
    'Position',CheckBoxPos);


CloseButtonPos(2) = 2;
uicontrol ('Parent',HKGui,'Style','pushbutton','Units','characters','Tag','hkclose_b','String','Close',...
    'Position',CloseButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@closehk_Callback});

handles = guihandles(HKGui);
handles.MainGui = MainGui;
guidata(HKGui,handles);

set(handles.manual_set_time_b,'Enable','on')
set(handles.singlestack_b,'Enable','on')
set(handles.allstacks_b,'Enable','on')
set(handles.saveparams_b,'Enable','on')
set(handles.bootresamples_e,'Enable','on')
set(handles.bootpercent_e,'Enable','on')
set(handles.hmax_e,'Enable','on')
set(handles.hmin_e,'Enable','on')
set(handles.hdelta_e,'Enable','on')
set(handles.kmax_e,'Enable','on')
set(handles.kmin_e,'Enable','on')
set(handles.kdelta_e,'Enable','on')
set(handles.w1_e,'Enable','on')
set(handles.w2_e,'Enable','on')
set(handles.w3_e,'Enable','on')
set(handles.timemax_e,'Enable','on')
set(handles.timemin_e,'Enable','on')
set(handles.timedelta_e,'Enable','on')
set(handles.raypmin_e,'Enable','on')
set(handles.raypmax_e,'Enable','on')
set(handles.bazmin_e,'Enable','on')
set(handles.bazmax_e,'Enable','on')
set(handles.vp_e,'Enable','on')
set(handles.error_p,'Enable','on')
set(handles.stationstack_m,'Enable','on')
set(handles.moveoutimage_m,'Enable','on')
set(handles.bazimage_m,'Enable','on')

if CurrentSubsetIndex == 1
    if exist([ProjectDirectory 'HKDATA'],'file')
        set(handles.hkgrid_m,'Enable','on')
        set(handles.ex_grids_m,'Enable','on')
        set(handles.ex_solutions_m,'Enable','on')
    end
else
    if exist([ProjectDirectory 'HKDATA' filesep SetName],'file')
        set(handles.hkgrid_m,'Enable','on')
        set(handles.ex_grids_m,'Enable','on')
        set(handles.ex_solutions_m,'Enable','on')
    end
end

Variables = who('-file',[ProjectDirectory ProjectFile]);
if ~isempty(strmatch('HkMetadataCell',Variables,'exact'))
    load([ProjectDirectory ProjectFile],'HkMetadataCell');
    if size(HkMetadataCell,1) < size(SetManagementCell,1)
        tmp = cell(size(SetManagementCell,1),2);
        for idx=1:size(HkMetadataCell,1)
            tmp{idx,1} = HkMetadataCell{idx,1};
            tmp{idx,2} = HkMetadataCell{idx,2};
        end
        HkMetadataCell = tmp;
    end
    if ~isempty(HkMetadataCell{CurrentSubsetIndex,1})
        HkMetadataStrings = HkMetadataCell{CurrentSubsetIndex,1};
        HkMetadataDoubles = HkMetadataCell{CurrentSubsetIndex,2};
        assignin('base','HkMetadataStrings',HkMetadataStrings)
        assignin('base','HkMetadataDoubles',HkMetadataDoubles)
        assignin('base','HkMetadataCell',HkMetadataCell);
    else
        assignin('base','HkMetadataCell',HkMetadataCell);
    end
elseif ~isempty(strmatch('HkMetadataStrings',Variables,'exact'))
    load([ProjectDirectory ProjectFile],'HkMetadataStrings','HkMetadataDoubles')
    assignin('base','HkMetadataStrings',HkMetadataStrings)
    assignin('base','HkMetadataDoubles',HkMetadataDoubles)
    HkMetadataCell = cell(size(SetManagementCell,1),2);
    HkMetadataCell{1,1} = HkMetadataStrings;
    HkMetadataCell{1,2} = HkMetadataDoubles;
    assignin('base','HkMetadataCell',HkMetadataCell);
else
    HkMetadataCell = cell(size(SetManagementCell,1),2);
    assignin('base','HkMetadataCell',HkMetadataCell);
end


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Subfunction Callbacks
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% hk_manual_set_time
% Sets up a call to:
% [TimeMin TimeMax] = hk_stacked_records_get_time(cbo,eventdata,handles)
% sets the edit boxes in hk stack window based on rounded values the user
% clicks on
% Updates
%   timemax_e.String
%   timemin_e.String
%--------------------------------------------------------------------------
function hk_manual_set_time(cbo, eventdata, handles)
h=guidata(gcf);
[TimeMin, TimeMax] = hk_stacked_records_get_time_single;
set(h.timemax_e,'String',sprintf('%1.1f',TimeMax*4));
set(h.timemin_e,'String',sprintf('%1.1f',TimeMin));
% Test - also setting min/max crustal thickness based on min/max time.
% Rough rule of thumb is 10 km ~ 1 second. The relationship below should
% give us a little buffer space
MinThickness = 9 * TimeMin;
MaxThickness = 11 * TimeMax;
set(h.hmax_e,'String',sprintf('%1.1f',MaxThickness));
set(h.hmin_e,'String',sprintf('%1.1f',MinThickness));


%--------------------------------------------------------------------------
% hkclose_Callback
%
% This callback function closes the project and removes variables from the
% workspace. Edit 05/16/2015 - RWP decided not to clear variables on cancel
%--------------------------------------------------------------------------
function closehk_Callback(cbo,eventdata,handles)
% if evalin('base','exist(''HkMetadataStrings'',''var'')')
%     evalin('base','clear(''HkMetadataStrings'',''HkMetadataDoubles'')')
% end
close(gcf)