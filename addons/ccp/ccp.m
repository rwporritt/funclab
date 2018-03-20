function ccp(MainGui)
%CCP Start the CCP GUI
%   CCP initiates the common conversion point stacking GUI.  The user is
%   able to run all of the FuncLab commands from this interface with a
%   push of a button.

%   Author: Kevin C. Eagar
%   Date Created: 05/08/2008
%   Last Updated: 04/24/2010

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
CCPGui = dialog('Name','CCP Stacking','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'});

%--------------------------------------------------------------------------
% CCP Top Menu Items (for plotting)
%--------------------------------------------------------------------------
MExport = uimenu(CCPGui,'Label','Export');
uimenu(MExport,'Label','Piercing Points','Tag','ex_pp_m','Enable','off','Callback',{@ccp_ex_pp}); % EXPORT PIERCING POINTS
uimenu(MExport,'Label','CCP Stacks','Tag','ex_stacks_m','Enable','off','Callback',{@ccp_ex_stacks}); % EXPORT CCP STACKS
MPlotting = uimenu(CCPGui,'Label','Plotting');
uimenu(MPlotting,'Label','Bin Map','Tag','binmap_m','Enable','off','Callback',{@ccp_binmap}); % MAP BIN LOCATIONS
uimenu(MPlotting,'Label','Bin Stack','Tag','binstack_m','Enable','off','Callback',{@ccp_binstack}); % PLOT CCP STACK

%--------------------------------------------------------------------------
% CCP Parameters
%--------------------------------------------------------------------------
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;

uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','title_t','String','CCP Parameters',...
    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',1,'HorizontalAlignment','center');
ParamTextPos1(2) = 29;
ParamOptionPos1(2) = 29;
ParamTextPos2(2) = 29;
ParamOptionPos2(2) = 29;
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','bootresamples_t','String','Bootstrap Resamples',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','bootresamples_e','String','200',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','bootpercent_t','String','Bootstrap Percentage',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','bootpercent_e','String','150',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 26;
ParamOptionPos1(2) = 26;
ParamTextPos2(2) = 26;
ParamOptionPos2(2) = 26;
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','latmax_t','String','Latitude Max.',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','latmax_e','String','48',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','latmin_t','String','Latitude Min.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','latmin_e','String','40',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 23;
ParamOptionPos1(2) = 23;
ParamTextPos2(2) = 23;
ParamOptionPos2(2) = 23;
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','lonmax_t','String','Longitude Max.',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','lonmax_e','String','-110',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','lonmin_t','String','Longitude Min.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','lonmin_e','String','-128',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 20;
ParamOptionPos1(2) = 20;
ParamTextPos2(2) = 20;
ParamOptionPos2(2) = 20;
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','depthmax_t','String','Depth Max. (km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','depthmax_e','String','800',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','depthinc_t','String','Depth Inc. (km)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','depthinc_e','String','2',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left');
ParamTextPos1(2) = 17;
ParamOptionPos1(2) = 17;
ParamTextPos2(2) = 17;
ParamOptionPos2(2) = 17;
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','minbinwidth_t','String','Minimum Bin Width (degs)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','minbinwidth_e','String','0.5',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','binspacing_t','String','Bin Spacing (degs)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','binspacing_e','String','50',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 14;
ParamOptionPos1(2) = 14;
ParamTextPos2(2) = 14;
ParamOptionPos2(2) = 14;
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','bazmin_t','String','Backazimuth Min.',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','bazmin_e','String','0',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','bazmax_t','String','Backazimuth Max.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','bazmax_e','String','360',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 11;
ParamOptionPos1(2) = 11;
ParamTextPos2(2) = 11;
ParamOptionPos2(2) = 11;
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','raypmin_t','String','Ray Parameter Min. (s/km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','raypmin_e','String','0.04',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','raypmax_t','String','Ray Parameter Max. (s/km)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','raypmax_e','String','0.08',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 8;
ParamOptionPos1(2) = 8;
ParamTextPos2(2) = 8;
ParamOptionPos2(2) = 8;
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','vertoverlap_t','String','Vertical Overlap (bins)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','vertoverlap_e','String','2',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','hitsmin_t','String','Min. Hits Per Bin',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','hitsmin_e','String','10',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 5;
ParamOptionPos1(2) = 5;
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','maxbinwidth_t','String','Max Bin Width (degs)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','edit','Units','characters','Tag','maxbinwidth_e','String','2.0',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 3;
ParamOptionPos1(2) = 3;
ParamOptionPos1(3) = 30;
VelocityModelPath = regexprep(which('funclab'),'funclab.m','VELMODELS/');
Comps = dir([VelocityModelPath '*.vel']);
Comps = sortrows({Comps.name}');
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','velocity_t','String','1D Velocity Model',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','popupmenu','Units','characters','Tag','velocity_p','String',Comps,'Value',1,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','right');
ParamTextPos1(2) = 1;
ParamOptionPos1(2) = 1;
TomographyModelPath = regexprep(which('funclab'),'funclab.m','TOMOMODELS/');
Comps = dir([TomographyModelPath '*.mat']);
Comps = sortrows({Comps.name}');
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','tomo_t','String','Tomography Model',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',CCPGui,'Style','popupmenu','Units','characters','Tag','tomo_p','String',Comps,'Value',1,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','right','Enable','off');

%--------------------------------------------------------------------------
% CCP Processing
%--------------------------------------------------------------------------
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','title_t','String','CCP Processes',...
    'Position',ProcTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',1,'HorizontalAlignment','center');
ProcButtonPos(2) = 28;
uicontrol ('Parent',CCPGui,'Style','pushbutton','Units','characters','Tag','raytrace_b','String','1D Ray Tracing',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@ccp_1D_raytracing});
ProcButtonPos(2) = 24;
uicontrol ('Parent',CCPGui,'Style','pushbutton','Units','characters','Tag','corrections_b','String','3D Heterogeneity Corrections',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold','Enable','off',...
    'Callback',{@ccp_corrections});
ProcButtonPos(2) = 20;
uicontrol ('Parent',CCPGui,'Style','pushbutton','Units','characters','Tag','migration_b','String','Time-to-Depth Migration',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold','Enable','off',...
    'Callback',{@ccp_migration});
ProcButtonPos(2) = 16;
uicontrol ('Parent',CCPGui,'Style','pushbutton','Units','characters','Tag','assignment_b','String','CCP Assignment',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold','Enable','off',...
    'Callback',{@ccp_assign});
ProcButtonPos(2) = 8;
uicontrol ('Parent',CCPGui,'Style','pushbutton','Units','characters','Tag','ccpstacking_b','String','CCP Stacking',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold','Enable','off',...
    'Callback',{@ccp_stacking});
CloseButtonPos(2) = 2;
uicontrol ('Parent',CCPGui,'Style','pushbutton','Units','characters','Tag','ccpclose_b','String','Close',...
    'Position',CloseButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@closeccp_Callback});
handles = guihandles(CCPGui);
handles.MainGui = MainGui;
guidata(CCPGui,handles);

if CurrentSubsetIndex == 1
    CCPDataDir = fullfile(ProjectDirectory, 'CCPData');
    CCPMatFile = fullfile(ProjectDirectory, 'CCPData', 'CCPData.mat');
else
    CCPDataDir = fullfile(ProjectDirectory, 'CCPData', SetName);
    CCPMatFile = fullfile(ProjectDirectory, 'CCPData', SetName, 'CCPData.mat');
end
    
% Check if the CCPMetadataCell exists in the project file. If it does, then
% check it is long enough for all sets. If not, expand it. If the variable
% does not exist, but CCPMetadataStrings does exist, then set the first
% CCPMetadataCell with the CCPMetadataStrings and Doubles (ie account for
% pre-subset projects.) If no CCP metadata exists, just create the cell the
% length needed for all current subsets
ProjectVariables = whos('-file',[ProjectDirectory ProjectFile]);
if ~isempty(strmatch('CCPMetadataCell',ProjectVariables,'exact'))
    if size(CCPMetadataCell,1) < size(SetManagementCell,1)
        tmp = cell(size(SetManagementCell,1),2);
        for idx=1:size(CCPMetadataCell,1)
            tmp{idx,1} = CCPMetadataCell{idx,1};
            tmp{idx,2} = CCPMetadataCell{idx,2};
        end
        CCPMetadataCell = tmp;
    end
else
    CCPMetadataCell = cell(size(SetManagementCell,1),2);
    if ~isempty(strmatch('CCPMetadataStrings',ProjectVariables,'exact'))
        load([ProjectDirectory ProjectFile],'CCPMetadataStrings','CCPMetadataDoubles')
        CCPMetadataCell{1,1} = CCPMetadataStrings;
        CCPMetadataCell{1,2} = CCPMetadataDoubles;
    end
end
assignin('base','CCPMetadataCell',CCPMetadataCell);
save([ProjectDirectory ProjectFile],'CCPMetadataCell','-append');


    
if exist(CCPDataDir,'dir')
    set(handles.corrections_b,'Enable','on')
    set(handles.migration_b,'Enable','on')
    set(handles.tomo_p,'Enable','on')

    if ~isempty(who('-file',CCPMatFile,'DepthAxis'))
        set(handles.assignment_b,'enable','on')
        set(handles.latmax_e,'Enable','on')
        set(handles.latmin_e,'Enable','on')
        set(handles.lonmax_e,'Enable','on')
        set(handles.lonmin_e,'Enable','on')
        set(handles.minbinwidth_e,'Enable','on')
        set(handles.binspacing_e,'Enable','on')
        set(handles.maxbinwidth_e,'Enable','on')
        set(handles.ex_pp_m,'Enable','on')
        if ~isempty(who('-file',CCPMatFile,'CCPGrid'))
            set(handles.bootresamples_e,'Enable','on')
            set(handles.bootpercent_e,'Enable','on')
            set(handles.raypmin_e,'Enable','on')
            set(handles.raypmax_e,'Enable','on')
            set(handles.bazmin_e,'Enable','on')
            set(handles.bazmax_e,'Enable','on')
            set(handles.vertoverlap_e,'Enable','off')
            set(handles.hitsmin_e,'Enable','on')
            set(handles.ccpstacking_b,'Enable','on')
            set(handles.binmap_m,'Enable','on')
            if ~isempty(who('-file',[ProjectDirectory ProjectFile],'CCPMetadataCell'))
                set(handles.binstack_m,'Enable','on')
                set(handles.ex_stacks_m,'Enable','on')
                load([ProjectDirectory ProjectFile],'CCPMetadataCell')
                CCPMetadataStrings = CCPMetadataCell{CurrentSubsetIndex,1};
                CCPMetadataDoubles = CCPMetadataCell{CurrentSubsetIndex,2};
                assignin('base','CCPMetadataStrings',CCPMetadataStrings)
                assignin('base','CCPMetadataDoubles',CCPMetadataDoubles)
            elseif ~isempty(who('-file',[ProjectDirectory ProjectFile],'CCPMetadataStrings'))
                set(handles.binstack_m,'Enable','on')
                set(handles.ex_stacks_m,'Enable','on')
                load([ProjectDirectory ProjectFile],'CCPMetadataStrings','CCPMetadataDoubles')
                assignin('base','CCPMetadataStrings',CCPMetadataStrings)
                assignin('base','CCPMetadataDoubles',CCPMetadataDoubles)
            end
        end
    end
    if ~isempty(who('-file',CCPMatFile,'CCPGrid'))
        set(handles.bootresamples_e,'Enable','on')
        set(handles.bootpercent_e,'Enable','on')
        set(handles.raypmin_e,'Enable','on')
        set(handles.raypmax_e,'Enable','on')
        set(handles.bazmin_e,'Enable','on')
        set(handles.bazmax_e,'Enable','on')
        set(handles.vertoverlap_e,'Enable','off')
        set(handles.hitsmin_e,'Enable','on')
        set(handles.ccpstacking_b,'Enable','on')
        set(handles.binmap_m,'Enable','on')
        set(handles.assignment_b,'enable','on')
        set(handles.latmax_e,'Enable','on')
        set(handles.latmin_e,'Enable','on')
        set(handles.lonmax_e,'Enable','on')
        set(handles.lonmin_e,'Enable','on')
        set(handles.minbinwidth_e,'Enable','on')
        set(handles.binspacing_e,'Enable','on')
        if ~isempty(who('-file',[ProjectDirectory ProjectFile],'CCPMetadataCell'))
            set(handles.binstack_m,'Enable','on')
            set(handles.ex_stacks_m,'Enable','on')
            load([ProjectDirectory ProjectFile],'CCPMetadataCell')
            CCPMetadataStrings = CCPMetadataCell{CurrentSubsetIndex,1};
            CCPMetadataDoubles = CCPMetadataCell{CurrentSubsetIndex,2};
            assignin('base','CCPMetadataStrings',CCPMetadataStrings)
            assignin('base','CCPMetadataDoubles',CCPMetadataDoubles)
        elseif ~isempty(who('-file',[ProjectDirectory ProjectFile],'CCPMetadataStrings'))
            set(handles.binstack_m,'Enable','on')
            set(handles.ex_stacks_m,'Enable','on')
            load([ProjectDirectory ProjectFile],'CCPMetadataStrings','CCPMetadataDoubles')
            assignin('base','CCPMetadataStrings',CCPMetadataStrings)
            assignin('base','CCPMetadataDoubles',CCPMetadataDoubles)
        end
    end
end


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Subfunction Callbacks
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% closeccp_Callback
%
% This callback function closes the project and removes variables from the
% workspace.
%--------------------------------------------------------------------------
function closeccp_Callback(cbo,eventdata,handles)
% if evalin('base','exist(''CCPMetadataStrings'',''var'')')
%     evalin('base','clear(''CCPMetadataStrings'',''CCPMetadataDoubles'')')
% end
close(gcf)