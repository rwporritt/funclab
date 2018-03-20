function ccpv2_raytrace(cbo,eventdata)
%% CCPV2_raytrace
%   Pops up a new figure window for the user to set the depth mapping
%   parameters and then calculate the raypaths for active records
%   Set:
%     1D model
%     inc depth
%     max depth
%     N iterations of 3D ray tracing
%     Matlab pool for parfor

% How to do the iterative 3D ray tracing:
%   1. Do the standard 1D ray tracing to get an initial ray path
%   2. Calculate the velocity along that initial ray with interp3
%   3. Re-calculate the raypath with the new velocity function
%   4. iterate

%   Author: Rob Porritt
%   Date Created: 04/29/2015
%   Last Updated: 04/29/2015

h = guidata(gcbf);

ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
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


MainPos = [0 0 90 18];
ParamTitlePos = [2 MainPos(4)-2 80 1.5];
ParamTextPos1 = [1 0 31 1.75];
ParamOptionPos1 = [32 0 15 1.75];
ParamTextPos2 = [50 0 20 1.75];
ParamOptionPos2 = [72 0 15 1.75];
ParamTextPos3 = [90 0 20 1.75];
ParamOptionPos3 = [113 0 15 1.75];
ProcTitlePos = [80 MainPos(4)-2 50 1.25];
ProcButtonPos = [71 2 18 3];
CloseButtonPos = [90 3 30 3];

% Setting font sizes
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];

RayTraceFigure = figure('Name','Ray Tracing','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white','DockControls','off','MenuBar','none','NumberTitle','off');

% Set depth defaults
defaultDepthIncrement = 10;
defaultDepthIncrement_s = sprintf('%3.0f',defaultDepthIncrement);
defaultDepthMax = 800;
defaultDepthMax_s = sprintf('%3.0f',defaultDepthMax);

% get available models from the velmodels dir
% setup a popupmenu list chooser
VelocityModelPath = regexprep(which('funclab'),'funclab.m','TOMOMODELS/');
List = dir([VelocityModelPath '*.mat']);
TomoModelList = sortrows({List.name}');

% get available models from the velmodels dir
% setup a popup menu list chooser
VelocityModelPath = regexprep(which('funclab'),'funclab.m','VELMODELS/');
List = dir([VelocityModelPath '*.vel']);
VelModelList = sortrows({List.name}');
velModID = strmatch(FuncLabPreferences{8},VelModelList,'exact');
% If the user has previously setup the ray tracing params, load them to set the
% initial values
hasDefaultValuesFlag = 0;

if CurrentSubsetIndex == 1
    CCPMat = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2.mat');
else
    CCPMat = fullfile(ProjectDirectory, 'CCPV2', SetName, 'CCPV2.mat');
end
if exist(CCPMat,'file')
    load(CCPMat)
    if exist('CCPV2RayTraceParams','var')
        defaultDepthIncrement = CCPV2RayTraceParams.DepthIncrement;
        defaultDepthIncrement_s = sprintf('%3.0f',defaultDepthIncrement);
        defaultDepthMax = CCPV2RayTraceParams.DepthMaximum;
        defaultDepthMax_s = sprintf('%3.0f',defaultDepthMax);
        VelModID = strmatch(CCPV2RayTraceParams.oneDModel,VelModelList,'exact');
        TomoModID = strmatch(CCPV2RayTraceParams.threeDModel,TomoModelList,'exact');
        NIterations = CCPV2RayTraceParams.NIterations;
        NWorkers = CCPV2RayTraceParams.NWorkers;
        IncidentPhase = CCPV2RayTraceParams.IncidentPhase;
        hasDefaultValuesFlag = 1;
    end
end

% Check against missing values for IDs
if exist('VelModID','var')
    if isempty(VelModID)
        VelModID = 1;
    end
end

if exist('TomoModID','var')
    if isempty(TomoModID)
        TomoModID = 1;
    end
end


% set default ray tracing parameters into handles - whole point is to
% overwrite these
RayTraceFigure.UserData.depthinc = defaultDepthIncrement;
RayTraceFigure.UserData.depthmax = defaultDepthMax;
%TomoModelList{TomoModID}
if hasDefaultValuesFlag == 1
    RayTraceFigure.UserData.oneDModel = VelModelList{VelModID};
    RayTraceFigure.UserData.threeDModel = TomoModelList{TomoModID};
    RayTraceFigure.UserData.NIterations = NIterations;
    RayTraceFigure.UserData.NWorkers = NWorkers;
    RayTraceFigure.UserData.IncidentPhase = IncidentPhase;
else
    TomoModID = 1;
    NIterations = 0;
    NWorkers = 1;
    IncidentPhase = 'P';
    RayTraceFigure.UserData.oneDModel = FuncLabPreferences{8};
    RayTraceFigure.UserData.threeDModel = TomoModelList{TomoModID};
    RayTraceFigure.UserData.NIterations = NIterations; % Each iteration is to use the three D model. Setting to 0 is 1D mapping
    RayTraceFigure.UserData.NWorkers = NWorkers; % Be careful with the parallel option!
    RayTraceFigure.UserData.IncidentPhase = IncidentPhase;
end

%Title
uicontrol ('Parent',RayTraceFigure,'Style','text','Units','characters','Tag','title_t','String','Ray Tracing',...
    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.85,'HorizontalAlignment','left','BackgroundColor','white');

ParamTextPos1(2) = 12;
ParamOptionPos1(2) = 12;
ParamTextPos2(2) = 12;
ParamOptionPos2(2) = 12;

% set depth increment as edit box
uicontrol ('Parent',RayTraceFigure,'Style','text','Units','characters','Tag','depthinc_t','String','Depth Increment (km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',RayTraceFigure,'Style','edit','Units','characters','Tag','depthinc_e','String',defaultDepthIncrement_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.depthinc = v; set(gcf,''UserData'',vec);');

% set max depth as edit box
uicontrol ('Parent',RayTraceFigure,'Style','text','Units','characters','Tag','depthmax_t','String','Depth Max. (km)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',RayTraceFigure,'Style','edit','Units','characters','Tag','depthmax_e','String',defaultDepthMax_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.depthmax = v; set(gcf,''UserData'',vec);');

% Decide the initial 1D model
ParamTextPos1(2) = 9;
ParamOptionPos1(2) = 9;
ParamOptionPos1(3) = 15;
ParamTextPos2(2) = 9;
ParamOptionPos2(2) = 9;
ParamOptionPos2(3) = 15;

uicontrol ('Parent',RayTraceFigure,'Style','text','Units','characters','Tag','onedvel_t','String','1D Model:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',RayTraceFigure,'Style','Popupmenu','Units','characters','Tag','onedvel_pu','String',VelModelList,...
    'Value',velModID,'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','vec = get(gcf,''UserData''); v = get(gcbo,''Value''); models = get(gcbo,''String''); vec.oneDModel = models{v}; set(gcf,''UserData'',vec);')

% Decide the 3D tomography model
uicontrol ('Parent',RayTraceFigure,'Style','text','Units','characters','Tag','threedvel_t','String','3D Model:',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',RayTraceFigure,'Style','Popupmenu','Units','characters','Tag','threedvel_pu','String',TomoModelList,...
    'Value',TomoModID,'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','vec = get(gcf,''UserData''); v = get(gcbo,''Value''); models = get(gcbo,''String''); vec.threeDModel = models{v}; set(gcf,''UserData'',vec);')

ParamTextPos1(2) = 6;
ParamOptionPos1(2) = 6;
ParamTextPos2(2) = 6;
ParamOptionPos2(2) = 6;

% set iterations for 3D ray tracing with popup menu to restrict choice
IterationOptions = {'0','1','2'}; % Tests found this to converge very quickly, so a couple iterations should be sufficient.
%IterationOptions = {'0'}; % Initial tests found unreliable results, so turning off for now
uicontrol ('Parent',RayTraceFigure,'Style','text','Units','characters','Tag','n_iterations_t','String','3D Model Iterations:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',RayTraceFigure,'Style','Popupmenu','Units','characters','Tag','iterations_pu','String',IterationOptions,...
    'Value',NIterations+1,'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','vec = get(gcf,''UserData''); v = get(gcbo,''Value''); opts = get(gcbo,''String''); vec.NIterations = str2double(opts{v}); set(gcf,''UserData'',vec);')

% set available matlab pool workers with popup
% ParallelComputingToolboxFlag = license('test','distrib_computing_toolbox');
% if ParallelComputingToolboxFlag == 1
%     MatlabPoolOptions = {'1', '2','3','4','5','6','7','8'};
% else
%     MatlabPoolOptions = {'1'};
% end
% Don't feel like working out the parallel computing just yet...
MatlabPoolOptions = {'1'};

uicontrol ('Parent',RayTraceFigure,'Style','text','Units','characters','Tag','parallel_t','String','N threads:',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',RayTraceFigure,'Style','Popupmenu','Units','characters','Tag','parallel_pu','String',MatlabPoolOptions,...
    'Value',NWorkers,'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','vec = get(gcf,''UserData''); v = get(gcbo,''Value''); nworkers = get(gcbo,''String''); vec.NWorkers = str2double(nworkers{v}); set(gcf,''UserData'',vec);')

ParamTextPos1(2) = 2.5;
ParamOptionPos1(2) = 2.5;
% Swap for incident phase
uicontrol ('Parent',RayTraceFigure,'Style','text','Units','characters','Tag','incident_phase_t','String','Incident Phase:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',RayTraceFigure,'Style','Popupmenu','Units','characters','Tag','incident_phase_pu','String',{'P','PKP','S','SKS'},...
    'Value',1,'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','vec = get(gcf,''UserData''); v = get(gcbo,''Value''); opts = get(gcbo,''String''); vec.IncidentPhase = opts{v}; set(gcf,''UserData'',vec);')

% Add buttons for "Do ray tracing" and "Cancel"
uicontrol('Parent',RayTraceFigure,'Style','Pushbutton','Units','characters','Tag','save_and_do_raytrace_pb','String','Confirm',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@saveraytrace_params_and_go_Callback,ProjectDirectory,RayTraceFigure});

ProcButtonPos(1) = 51;
uicontrol('Parent',RayTraceFigure,'Style','Pushbutton','Units','characters','Tag','cancel_pb','String','Cancel',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@cancelraytrace_Callback});

end


function cancelraytrace_Callback(cbo, eventdata)
    close(gcbf);
end

function saveraytrace_params_and_go_Callback(cbo, eventdata,ProjectDirectory,hdls)

% on save...
% Checks for the setup of the output directory and mat file
    [~, ~, ~] = mkdir(ProjectDirectory,'CCPV2');

    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
    RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
    RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
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
    
    % Get ray tracing parameters from handles
    CCPV2RayTraceParams.DepthIncrement = hdls.UserData.depthinc;
    CCPV2RayTraceParams.DepthMaximum = hdls.UserData.depthmax;
    CCPV2RayTraceParams.oneDModel = hdls.UserData.oneDModel;
    CCPV2RayTraceParams.threeDModel = hdls.UserData.threeDModel;
    CCPV2RayTraceParams.NIterations = hdls.UserData.NIterations; 
    CCPV2RayTraceParams.NWorkers = hdls.UserData.NWorkers;
    CCPV2RayTraceParams.IncidentPhase = hdls.UserData.IncidentPhase;
    
    %outputFile = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2.mat');
    % Save the rays to the matrix
    if CurrentSubsetIndex == 1
        outputFile = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2.mat');
    else
        outputFile = fullfile(ProjectDirectory, 'CCPV2', SetName, 'CCPV2.mat');
    end
    if exist(outputFile,'file')
        save(outputFile,'CCPV2RayTraceParams','-append');
    else
        save(outputFile,'CCPV2RayTraceParams')
    end
    
    % Do ray tracing...
    % Send this to one of two subroutines based on use of NWorkers - ie
    % whether or not to use a parfor!
    if CCPV2RayTraceParams.NWorkers == 1 && (strcmp(CCPV2RayTraceParams.IncidentPhase,'P') || strcmp(CCPV2RayTraceParams.IncidentPhase,'PKP')) 
        %ccpv2_do_ray_tracing_serial_PtoS(CCPV2RayTraceParams);
        ccpv2_do_ray_tracing_serial_PtoS(CCPV2RayTraceParams);
    elseif CCPV2RayTraceParams.NWorkers > 1 && (strcmp(CCPV2RayTraceParams.IncidentPhase,'P') || strcmp(CCPV2RayTraceParams.IncidentPhase,'PKP'))
        ccpv2_do_ray_tracing_parallel_PtoS(CCPV2RayTraceParams);
    elseif CCPV2RayTraceParams.NWorkers == 1 && (strcmp(CCPV2RayTraceParams.IncidentPhase,'S') || strcmp(CCPV2RayTraceParams.IncidentPhase,'SKS')) 
        ccpv2_do_ray_tracing_serial_StoP(CCPV2RayTraceParams);
    elseif CCPV2RayTraceParams.NWorkers > 1 && (strcmp(CCPV2RayTraceParams.IncidentPhase,'S') || strcmp(CCPV2RayTraceParams.IncidentPhase,'SKS'))
        ccpv2_do_ray_tracing_parallel_StoP(CCPV2RayTraceParams);
    else
        disp('Error with number of workers or incident phase')
    end
        
    close(gcbf)

    % check if geometry exists and if so turn on stacking
    load(outputFile)
    if exist('CCPV2Geometry','var')
        stackbuttonhdls = findobj('Tag','ccpv2_stacking_button');
        set(stackbuttonhdls,'Enable','on');
    end
    
end

