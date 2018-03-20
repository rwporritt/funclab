function gccp(MainGui)
%GCCP Start the GCCP GUI
%   GCCP initiates the common conversion point stacking GUI.  The user is
%   able to run all of the FuncLab commands from this interface with a
%   push of a button.

%   Author: Kevin C. Eagar
%   Date Created: 05/08/2008
%   Last Updated: 11/21/2011

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
MainPos = [0 0 130 37];
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
GCCPGui = dialog('Name','GCCP Stacking','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'});

%--------------------------------------------------------------------------
% GCCP Top Menu Items (for plotting)
%--------------------------------------------------------------------------
MExport = uimenu(GCCPGui,'Label','Export');
uimenu(MExport,'Label','Piercing Points','Tag','ex_pp_m','Enable','off','Callback',{@gccp_ex_pp});
uimenu(MExport,'Label','GCCP Volume','Tag','ex_volume_m','Enable','off','Callback',{@gccp_ex_volume});
MPlotting = uimenu(GCCPGui,'Label','Plotting');
uimenu(MPlotting,'Label','Bin Map','Tag','binmap_m','Enable','off','Callback',{@gccp_binmap});
uimenu(MPlotting,'Label','Bin Stack','Tag','binstack_m','Enable','off','Callback',{@gccp_binstack});

%--------------------------------------------------------------------------
% GCCP Parameters
%--------------------------------------------------------------------------
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];


uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','title_t','String','GCCP Parameters',...
    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',1,'HorizontalAlignment','center');
ParamTextPos1(2) = 29;
ParamOptionPos1(2) = 29;
ParamTextPos2(2) = 29;
ParamOptionPos2(2) = 29;
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','bootresamples_t','String','Bootstrap Resamples',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','bootresamples_e','String','1',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off'); % 11/21/2011: CHANGED THE DEFAULT TO 1 RESAMPLE
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','bootpercent_t','String','Bootstrap Percentage',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','bootpercent_e','String','150',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 26;
ParamOptionPos1(2) = 26;
ParamTextPos2(2) = 26;
ParamOptionPos2(2) = 26;
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','latmax_t','String','Latitude Max.',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','latmax_e','String','48',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','latmin_t','String','Latitude Min.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','latmin_e','String','40',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 23;
ParamOptionPos1(2) = 23;
ParamTextPos2(2) = 23;
ParamOptionPos2(2) = 23;
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','lonmax_t','String','Longitude Max.',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','lonmax_e','String','-110',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','lonmin_t','String','Longitude Min.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','lonmin_e','String','-128',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 20;
ParamOptionPos1(2) = 20;
ParamTextPos2(2) = 20;
ParamOptionPos2(2) = 20;
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','depthmax_t','String','Depth Max. (km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left'); % 11/9/2011: Changed the ?edit box? label from ?Bin Width (km)? to ?Weighting Function Width (km)?
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','depthmax_e','String','800',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','depthinc_t','String','Depth Inc. (km)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','depthinc_e','String','2',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left');
ParamTextPos1(2) = 17;
ParamOptionPos1(2) = 17;
ParamTextPos2(2) = 17;
ParamOptionPos2(2) = 17;
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','binwidth_t','String','Weighting Function Width (km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','binwidth_e','String','50',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','binspacing_t','String','Bin Spacing (km)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','binspacing_e','String','50',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 14;
ParamOptionPos1(2) = 14;
ParamTextPos2(2) = 14;
ParamOptionPos2(2) = 14;
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','bazmin_t','String','Backazimuth Min.',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','bazmin_e','String','0',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','bazmax_t','String','Backazimuth Max.',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','bazmax_e','String','360',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 11;
ParamOptionPos1(2) = 11;
ParamTextPos2(2) = 11;
ParamOptionPos2(2) = 11;
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','raypmin_t','String','Ray Parameter Min. (s/km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','raypmin_e','String','0.04',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','raypmax_t','String','Ray Parameter Max. (s/km)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','raypmax_e','String','0.08',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 8;
ParamOptionPos1(2) = 8;
ParamTextPos2(2) = 8;
ParamOptionPos2(2) = 8;
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','vertoverlap_t','String','Vertical Overlap (bins)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','vertoverlap_e','String','2',...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','hitsmin_t','String','Min. Hits Per Bin',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','edit','Units','characters','Tag','hitsmin_e','String','10',...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
ParamTextPos1(2) = 5;
ParamOptionPos1(2) = 5;
ParamOptionPos1(3) = 30;
VelocityModelPath = regexprep(which('funclab'),'funclab.m','VELMODELS/');
Comps = dir([VelocityModelPath '*.vel']);
Comps = sortrows({Comps.name}');
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','velocity_t','String','1D Velocity Model',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','popupmenu','Units','characters','Tag','velocity_p','String',Comps,'Value',1,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left');
ParamTextPos1(2) = 2;
ParamOptionPos1(2) = 2;
TomographyModelPath = regexprep(which('funclab'),'funclab.m','TOMOMODELS/');
Comps = dir([TomographyModelPath '*.mat']);
Comps = sortrows({Comps.name}');
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','tomo_t','String','Tomography Model',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','popupmenu','Units','characters','Tag','tomo_p','String',Comps,'Value',1,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');
% 11/21/2011: ADDED OPTION TO STACK TRANSVERSE RECEIVER FUNCTIONS
ParamTextPos1(2) = 32;
ParamOptionPos1(2) = 32;
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','trf_t','String','Stack Transverse RFs',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
uicontrol ('Parent',GCCPGui,'Style','popupmenu','Units','characters','Tag','trf_p','String',{'On','Off'},'Value',2,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','off');



%--------------------------------------------------------------------------
% GCCP Processing
%--------------------------------------------------------------------------
uicontrol ('Parent',GCCPGui,'Style','text','Units','characters','Tag','title_t','String','GCCP Processes',...
    'Position',ProcTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',1,'HorizontalAlignment','center');
ProcButtonPos(2) = 28;
uicontrol ('Parent',GCCPGui,'Style','pushbutton','Units','characters','Tag','raytrace_b','String','1D Ray Tracing',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@gccp_1D_raytracing});
ProcButtonPos(2) = 24;
uicontrol ('Parent',GCCPGui,'Style','pushbutton','Units','characters','Tag','corrections_b','String','3D Heterogeneity Corrections',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold','Enable','off',...
    'Callback',{@gccp_corrections});
ProcButtonPos(2) = 20;
uicontrol ('Parent',GCCPGui,'Style','pushbutton','Units','characters','Tag','migration_b','String','Time-to-Depth Conversion',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold','Enable','off',...
    'Callback',{@gccp_migration}); % 11/21/2011: CHANGED "MIGRATION" TO "CONVERSION"
ProcButtonPos(2) = 16;
uicontrol ('Parent',GCCPGui,'Style','pushbutton','Units','characters','Tag','assignment_b','String','GCCP Grid Construction',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold','Enable','off',...
    'Callback',{@gccp_assign}); % 11/21/2011: CHANGED "ASSIGNMENT" TO "GRID CONSTRUCTION"
ProcButtonPos(2) = 8;
uicontrol ('Parent',GCCPGui,'Style','pushbutton','Units','characters','Tag','gccpstacking_b','String','GCCP Stacking',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold','Enable','off',...
    'Callback',{@gccp_stacking});
CloseButtonPos(2) = 2;
uicontrol ('Parent',GCCPGui,'Style','pushbutton','Units','characters','Tag','gccpclose_b','String','Close',...
    'Position',CloseButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@closegccp_Callback});
handles = guihandles(GCCPGui);
handles.MainGui = MainGui;
guidata(GCCPGui,handles);

if CurrentSubsetIndex == 1
    GCCPDataDir = fullfile(ProjectDirectory, 'GCCPData');
    GCCPMatFile = fullfile(ProjectDirectory, 'GCCPData', 'GCCPData.mat');
else
    GCCPDataDir = fullfile(ProjectDirectory, 'GCCPData', SetName);
    GCCPMatFile = fullfile(ProjectDirectory, 'GCCPData', SetName, 'GCCPData.mat');
end

% Check if the GCCPMetadataCell exists in the project file. If it does, then
% check it is long enough for all sets. If not, expand it. If the variable
% does not exist, but GCCPMetadataStrings does exist, then set the first
% GCCPMetadataCell with the GCCPMetadataStrings and Doubles (ie account for
% pre-subset projects.) If no GCCP metadata exists, just create the cell the
% length needed for all current subsets
ProjectVariables = whos('-file',[ProjectDirectory ProjectFile]);
if ~isempty(strmatch('GCCPMetadataCell',ProjectVariables,'exact'))
    if size(GCCPMetadataCell,1) < size(SetManagementCell,1)
        tmp = cell(size(SetManagementCell,1),2);
        for idx=1:size(GCCPMetadataCell,1)
            tmp{idx,1} = GCCPMetadataCell{idx,1};
            tmp{idx,2} = GCCPMetadataCell{idx,2};
        end
        GCCPMetadataCell = tmp;
    end
else
    GCCPMetadataCell = cell(size(SetManagementCell,1),2);
    if ~isempty(strmatch('GCCPMetadataStrings',ProjectVariables,'exact'))
        load([ProjectDirectory ProjectFile],'GCCPMetadataStrings','GCCPMetadataDoubles')
        CCPMetadataCell{1,1} = GCCPMetadataStrings;
        CCPMetadataCell{1,2} = GCCPMetadataDoubles;
    end
end
assignin('base','GCCPMetadataCell',GCCPMetadataCell);
save([ProjectDirectory ProjectFile],'GCCPMetadataCell','-append');

if exist(GCCPDataDir,'dir')
    set(handles.corrections_b,'Enable','on')
    set(handles.migration_b,'Enable','on')
    set(handles.tomo_p,'Enable','on')

    if ~isempty(who('-file',GCCPMatFile,'DepthAxis'))
        set(handles.assignment_b,'enable','on')
        set(handles.latmax_e,'Enable','on')
        set(handles.latmin_e,'Enable','on')
        set(handles.lonmax_e,'Enable','on')
        set(handles.lonmin_e,'Enable','on')
        set(handles.binwidth_e,'Enable','on')
        set(handles.binspacing_e,'Enable','on')
        set(handles.ex_pp_m,'Enable','on')
        if ~isempty(who('-file',GCCPMatFile,'GCCPGrid'))
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
            if ~isempty(who('-file',[ProjectDirectory ProjectFile],'GCCPMetadataCell'))
                set(handles.binstack_m,'Enable','on')
                set(handles.ex_stacks_m,'Enable','on')
                load([ProjectDirectory ProjectFile],'GCCPMetadataCell')
                GCCPMetadataStrings = GCCPMetadataCell{CurrentSubsetIndex,1};
                GCCPMetadataDoubles = GCCPMetadataCell{CurrentSubsetIndex,2};
                assignin('base','GCCPMetadataStrings',GCCPMetadataStrings)
                assignin('base','GCCPMetadataDoubles',GCCPMetadataDoubles)
            elseif ~isempty(who('-file',[ProjectDirectory ProjectFile],'GCCPMetadataStrings'))
                set(handles.binstack_m,'Enable','on')
                set(handles.ex_stacks_m,'Enable','on')
                load([ProjectDirectory ProjectFile],'GCCPMetadataStrings','GCCPMetadataDoubles')
                assignin('base','GCCPMetadataStrings',GCCPMetadataStrings)
                assignin('base','GCCPMetadataDoubles',GCCPMetadataDoubles)
            end
        end
    end
    if ~isempty(who('-file',GCCPMatFile,'GCCPGrid'))
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
        set(handles.binwidth_e,'Enable','on')
        set(handles.binspacing_e,'Enable','on')
        if ~isempty(who('-file',[ProjectDirectory ProjectFile],'GCCPMetadataCell'))
            set(handles.binstack_m,'Enable','on')
            set(handles.ex_stacks_m,'Enable','on')
            load([ProjectDirectory ProjectFile],'GCCPMetadataCell')
            GCCPMetadataStrings = GCCPMetadataCell{CurrentSubsetIndex,1};
            GCCPMetadataDoubles = GCCPMetadataCell{CurrentSubsetIndex,2};
            assignin('base','GCCPMetadataStrings',GCCPMetadataStrings)
            assignin('base','GCCPMetadataDoubles',GCCPMetadataDoubles)
        elseif ~isempty(who('-file',[ProjectDirectory ProjectFile],'GCCPMetadataStrings'))
            set(handles.binstack_m,'Enable','on')
            set(handles.ex_stacks_m,'Enable','on')
            load([ProjectDirectory ProjectFile],'GCCPMetadataStrings','GCCPMetadataDoubles')
            assignin('base','GCCPMetadataStrings',GCCPMetadataStrings)
            assignin('base','GCCPMetadataDoubles',GCCPMetadataDoubles)
        end
    end
end


% if exist(GCCPDataDir,'dir')
%     set(handles.corrections_b,'Enable','on')
%     set(handles.migration_b,'Enable','on')
%     set(handles.tomo_p,'Enable','on')
%     set(handles.trf_p,'Enable','on')
% 
%     if ~isempty(who('-file',GCCPMatFile,'DepthAxis'))
%         set(handles.assignment_b,'enable','on')
%         set(handles.latmax_e,'Enable','on')
%         set(handles.latmin_e,'Enable','on')
%         set(handles.lonmax_e,'Enable','on')
%         set(handles.lonmin_e,'Enable','on')
%         set(handles.binwidth_e,'Enable','on')
%         set(handles.binspacing_e,'Enable','on')
%         set(handles.ex_pp_m,'Enable','on')
%         if ~isempty(who('-file',GCCPMatFile,'GCCPGrid'))
%             set(handles.bootresamples_e,'Enable','on')
%             set(handles.bootpercent_e,'Enable','on')
%             set(handles.raypmin_e,'Enable','on')
%             set(handles.raypmax_e,'Enable','on')
%             set(handles.bazmin_e,'Enable','on')
%             set(handles.bazmax_e,'Enable','on')
%             set(handles.vertoverlap_e,'Enable','off')
%             set(handles.hitsmin_e,'Enable','on')
%             set(handles.gccpstacking_b,'Enable','on')
%             set(handles.binmap_m,'Enable','on')
%             if ~isempty(who('-file',[ProjectDirectory ProjectFile],'GCCPMetadataStrings'))
%                 set(handles.ex_volume_m,'Enable','on')
%                 set(handles.binstack_m,'Enable','on')
%                 load([ProjectDirectory ProjectFile],'GCCPMetadataStrings','GCCPMetadataDoubles')
%                 assignin('base','GCCPMetadataStrings',GCCPMetadataStrings)
%                 assignin('base','GCCPMetadataDoubles',GCCPMetadataDoubles)
%             end
%         end
%     end
%     if ~isempty(who('-file',GCCPMatFile,'GCCPGrid'))
%         set(handles.bootresamples_e,'Enable','on')
%         set(handles.bootpercent_e,'Enable','on')
%         set(handles.raypmin_e,'Enable','on')
%         set(handles.raypmax_e,'Enable','on')
%         set(handles.bazmin_e,'Enable','on')
%         set(handles.bazmax_e,'Enable','on')
%         set(handles.vertoverlap_e,'Enable','off')
%         set(handles.hitsmin_e,'Enable','on')
%         set(handles.gccpstacking_b,'Enable','on')
%         set(handles.binmap_m,'Enable','on')
%         set(handles.assignment_b,'enable','on')
%         set(handles.latmax_e,'Enable','on')
%         set(handles.latmin_e,'Enable','on')
%         set(handles.lonmax_e,'Enable','on')
%         set(handles.lonmin_e,'Enable','on')
%         set(handles.binwidth_e,'Enable','on')
%         set(handles.binspacing_e,'Enable','on')
%         set(handles.ex_pp_m,'Enable','on')
%         if ~isempty(who('-file',[ProjectDirectory ProjectFile],'GCCPMetadataStrings'))
%             set(handles.ex_volume_m,'Enable','on')
%             set(handles.binstack_m,'Enable','on')
%             load([ProjectDirectory ProjectFile],'GCCPMetadataStrings','GCCPMetadataDoubles')
%             assignin('base','GCCPMetadataStrings',GCCPMetadataStrings)
%             assignin('base','GCCPMetadataDoubles',GCCPMetadataDoubles)
%         end
%     end
% end


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Subfunction Callbacks
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% closegccp_Callback
%
% This callback function closes the project and removes variables from the
% workspace.
%--------------------------------------------------------------------------
function closegccp_Callback(cbo,eventdata,handles)
% if evalin('base','exist(''GCCPMetadataStrings'',''var'')')
%     evalin('base','clear(''GCCPMetadataStrings'',''GCCPMetadataDoubles'')')
% end
close(gcf)