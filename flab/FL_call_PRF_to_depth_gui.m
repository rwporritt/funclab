function FL_call_PRF_to_depth_gui
%% Function FL_call_PRF_to_depth_gui
%  launches a new figure gui to enter parameters for 1D spatial mapping of
%  the PRF data
%
%  Once the data are mapped to depth, adds new tables into the main figure
%  for Event (depth) and Station (depth)
%
%  Not entirely sure how to give the user an efficient choice of subsetting
%  stations and events, so just going to comment out the preliminary work
%  designed to provide those options.
%
%  Depth mapping actually done in FL_run_depth_map.m based on the method
%  used in CCPV2.
%
%  Created: 05/04/2015. Rob Porritt



% Get the handles of the FuncLab GUI
%--------------------------------------------------------------------------
%h = guidata(gcbf);

% Get project info
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');

%Value = get(h.tablemenu_pu,'Value');
%CurrentRecords = evalin('base','CurrentRecords');
%CurrentIndices = evalin('base','CurrentIndices');
%RecordMetadataStrings = evalin('base','RecordMetadataStrings');
%RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
% if Value == 1 || Value == 2
%     Station = CurrentRecords{1,2};
%     Event = CurrentRecords{1,3};
% else    
%     Tablemenu = evalin('base','Tablemenu');
%     if Value == 1 && strmatch('DepthMapMetadataStations',Tablemenu{Value,2})
%         RecordIndex = get(h.records_ls,'Value');
%         Station = CurrentRecords{RecordIndex,2};
%         % Get all records for this selected station and redo
%         % CurrentRecords and CurrentIndices
%         in = strmatch(Station,RecordMetadataStrings(:,2),'exact');
%         CurrentRecords = [RecordMetadataStrings(in,:) num2cell(RecordMetadataDoubles(in,:))];
%         [CurrentRecords,ind] = sortrows(CurrentRecords,Tablemenu{Value,4});
%         CurrentIndices = in(ind);
%     elseif Value == 2 && strmatch('DepthMapMetadataEvent',Tablemenu{Value,2})
%         RecordIndex = get(h.records_ls,'Value');
%         Event = CurrentRecords{RecordIndex,3};
%         % Get all records for this selected station and redo
%         % CurrentRecords and CurrentIndices
%         in = strmatch(Event,RecordMetadataStrings(:,3),'exact');
%         CurrentRecords = [RecordMetadataStrings(in,:) num2cell(RecordMetadataDoubles(in,:))];
%         [CurrentRecords,ind] = sortrows(CurrentRecords,Tablemenu{Value,4});
%         CurrentIndices = in(ind);
%     else
%         TableIndex = get(h.tables_ls,'Value');
%         TableList = get(h.tables_ls,'String');
%         TableName = TableList{TableIndex};
%         disp(['Not the right table: ' TableName])
%         return
%     end
% end

load([ProjectDirectory ProjectFile],'FuncLabPreferences')

MainPos = [0 0 90 18];
ParamTitlePos = [2 MainPos(4)-2 80 1.5];
ParamTextPos1 = [1 0 31 1.75];
ParamOptionPos1 = [32 0 15 1.75];
ParamTextPos2 = [50 0 20 1.75];
ParamOptionPos2 = [72 0 15 1.75];
%ParamTextPos3 = [90 0 20 1.75];
%ParamOptionPos3 = [113 0 15 1.75];
%ProcTitlePos = [80 MainPos(4)-2 50 1.25];
ProcButtonPos = [71 2 18 3];
%CloseButtonPos = [90 3 30 3];

% Setting font sizes
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];

OneDFigure = figure('Name','Depth mapping','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white','DockControls','off','MenuBar','none','NumberTitle','off');

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

% set default ray tracing parameters into handles - whole point is to
% overwrite these
OneDFigure.UserData.depthinc = defaultDepthIncrement;
OneDFigure.UserData.depthmax = defaultDepthMax;
TomoModID = 1;
NIterations = 0;
OneDFigure.UserData.oneDModel = FuncLabPreferences{8};
OneDFigure.UserData.threeDModel = TomoModelList{TomoModID};
OneDFigure.UserData.NIterations = NIterations; % Each iteration is to use the three D model. Setting to 0 is 1D mapping
%OneDFigure.UserData.CurrentOrAllChoice = 'Current';
OneDFigure.UserData.ActiveOrAllChoice = 'All';
% if Value == 1
%     OneDFigure.UserData.StationsOrEvents = 'Stations';
% else
%     OneDFigure.UserData.StationsOrEvents = 'Events';
% end
% OneDFigure.UserData.Station = Station;
% OneDFigure.UserData.Event = Event;
% OneDFigure.UserData.CurrentRecords = CurrentRecords;
% OneDFigure.UserData.CurrentIndices = CurrentIndices;


%Title
uicontrol ('Parent',OneDFigure,'Style','text','Units','characters','Tag','title_t','String','Depth mapping',...
    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.85,'HorizontalAlignment','left','BackgroundColor','white');

ParamTextPos1(2) = 12;
ParamOptionPos1(2) = 12;
ParamTextPos2(2) = 12;
ParamOptionPos2(2) = 12;

% set depth increment as edit box
uicontrol ('Parent',OneDFigure,'Style','text','Units','characters','Tag','depthinc_t','String','Depth Increment (km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',OneDFigure,'Style','edit','Units','characters','Tag','depthinc_e','String',defaultDepthIncrement_s,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.depthinc = v; set(gcf,''UserData'',vec);');

% set max depth as edit box
uicontrol ('Parent',OneDFigure,'Style','text','Units','characters','Tag','depthmax_t','String','Depth Max. (km)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',OneDFigure,'Style','edit','Units','characters','Tag','depthmax_e','String',defaultDepthMax_s,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.depthmax = v; set(gcf,''UserData'',vec);');

% Decide the initial 1D model
ParamTextPos1(2) = 9;
ParamOptionPos1(2) = 9;
ParamOptionPos1(3) = 15;
ParamTextPos2(2) = 9;
ParamOptionPos2(2) = 9;
ParamOptionPos2(3) = 15;

uicontrol ('Parent',OneDFigure,'Style','text','Units','characters','Tag','onedvel_t','String','1D Model:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',OneDFigure,'Style','Popupmenu','Units','characters','Tag','onedvel_pu','String',VelModelList,...
    'Value',velModID,'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','vec = get(gcf,''UserData''); v = get(gcbo,''Value''); models = get(gcbo,''String''); vec.oneDModel = models{v}; set(gcf,''UserData'',vec);')

% Decide the 3D tomography model
uicontrol ('Parent',OneDFigure,'Style','text','Units','characters','Tag','threedvel_t','String','3D Model:',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',OneDFigure,'Style','Popupmenu','Units','characters','Tag','threedvel_pu','String',TomoModelList,...
    'Value',TomoModID,'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','vec = get(gcf,''UserData''); v = get(gcbo,''Value''); models = get(gcbo,''String''); vec.threeDModel = models{v}; set(gcf,''UserData'',vec);')

ParamTextPos1(2) = 6;
ParamOptionPos1(2) = 6;
ParamTextPos2(2) = 6;
ParamOptionPos2(2) = 6;

% set iterations for 3D ray tracing with popup menu to restrict choice
IterationOptions = {'0','1','2'}; % Tests found this to converge very quickly, so a couple iterations should be sufficient.
%IterationOptions = {'0'}; % Initial tests found unreliable results, so turning off for now
uicontrol ('Parent',OneDFigure,'Style','text','Units','characters','Tag','n_iterations_t','String','3D Model Iterations:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',OneDFigure,'Style','Popupmenu','Units','characters','Tag','iterations_pu','String',IterationOptions,...
    'Value',NIterations+1,'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','vec = get(gcf,''UserData''); v = get(gcbo,''Value''); opts = get(gcbo,''String''); vec.NIterations = str2double(opts{v}); set(gcf,''UserData'',vec);')


% This station or all
% if Value == 1
%     str = 'Stations:';
% elseif Value == 2
%     str = 'Events:';
% end
% uicontrol ('Parent',OneDFigure,'Style','text','Units','characters','Tag','one_station_or_all_t','String',str,...
%     'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
% uicontrol ('Parent',OneDFigure,'Style','Popupmenu','Units','characters','Tag','one_station_or_all_pu','String',{'Current', 'All'},...
%     'Value',1,'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
%     'Callback','vec = get(gcf,''UserData''); v = get(gcbo,''Value''); opt = get(gcbo,''String''); vec.CurrentOrAllChoice = opt{v}; set(gcf,''UserData'',vec);')

%ParamTextPos1(2) = 2.5;
%ParamOptionPos1(2) = 2.5;
% Swap active or all
uicontrol ('Parent',OneDFigure,'Style','text','Units','characters','Tag','records_t','String','Records:',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
%ActiveOrAllChoiceString = {'Active','All'}; % Initially, this gave the
%user the option to only map the active records to save time. That is a
%nightmare for the subsetting, so turned that option off
ActiveOrAllChoiceString = {'All'};
uicontrol ('Parent',OneDFigure,'Style','Popupmenu','Units','characters','Tag','records_pu','String',ActiveOrAllChoiceString,...
    'Value',1,'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','vec = get(gcf,''UserData''); v = get(gcbo,''Value''); opts = get(gcbo,''String''); vec.ActiveOrAllChoice = opts{v}; set(gcf,''UserData'',vec);')


% Add buttons for "Do ray tracing" and "Cancel"
uicontrol('Parent',OneDFigure,'Style','Pushbutton','Units','characters','Tag','save_and_do_raytrace_pb','String','Confirm',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@saveoned_params_and_go_Callback,OneDFigure});

ProcButtonPos(1) = 51;
uicontrol('Parent',OneDFigure,'Style','Pushbutton','Units','characters','Tag','cancel_pb','String','Cancel',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@canceloned_Callback});

end


function canceloned_Callback(cbo, eventdata)
    close(gcbf);
end


function saveoned_params_and_go_Callback(cbo, eventdata, hdls)
    % User has set the parameters and now its time to go
    % First we make a directory for the output sac vs. depth files
    % Use the active set name 
    ProjectDirectory = evalin('base','ProjectDirectory');
    
    [~, ~, ~] = mkdir(ProjectDirectory,'DepthTraces');
    
    % If oprating on a subset, use the subset name to create a sub
    % directory within DepthTraces
    SetManagementCell = evalin('base','SetManagementCell');
    CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
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
        [~, ~, ~] = mkdir([ProjectDirectory 'DepthTraces'],SetName);
    end
    
    OneDParams.DepthIncrement = hdls.UserData.depthinc;
    OneDParams.DepthMaximum = hdls.UserData.depthmax;
    OneDParams.oneDModel = hdls.UserData.oneDModel;
    OneDParams.threeDModel = hdls.UserData.threeDModel;
    OneDParams.NIterations = hdls.UserData.NIterations; 
    %OneDParams.CurrentOrAllChoice = hdls.UserData.CurrentOrAllChoice;
    OneDParams.ActiveOrAllChoice = hdls.UserData.ActiveOrAllChoice;
    %OneDParams.StationsOrEvents = hdls.UserData.StationsOrEvents;
    %OneDParams.CurrentRecords = hdls.UserData.CurrentRecords;
    %OneDParams.CurrentIndices = hdls.UserData.CurrentIndices;
    %OneDParams.Station = hdls.UserData.Station;
    %OneDParams.Event = hdls.UserData.Event;
    
    % Save to a parameter file
    if CurrentSubsetIndex == 1
        save([ProjectDirectory 'DepthTraces' filesep 'DepthTracesParams.mat'],'OneDParams')
    else
        save([ProjectDirectory 'DepthTraces' filesep SetName filesep 'DepthTracesParams.mat'],'OneDParams')
    end
    % Run the depth mapping
    FL_run_depth_map(OneDParams);

    % Need to update the tables and plotting options

    close(hdls)
end







