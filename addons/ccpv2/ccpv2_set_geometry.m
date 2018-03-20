function ccpv2_set_geometry(cbo,eventdata)
%% CCPV2_SET_GEOMETRY
%   Pops up a new figure window for the user to set the geometric
%   parameters for ccp stacking
%   Need latitude (min/max/step), longitude (min/max/step), depth
%   (min/max/step), and dominant period (which we use to set the guassian
%   pulse width)

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
ProcButtonPos = [80 2 35 3];
CloseButtonPos = [90 3 30 3];

% Set default geometry from the station map limits
NorthLat = FuncLabPreferences{13};
SouthLat = FuncLabPreferences{14};
WestLon = FuncLabPreferences{15};
EastLon = FuncLabPreferences{16};

% Setting font sizes
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];

% Setup new figure for entering data.
GeometryFigure = figure('Name','Enter Geometry','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white','DockControls','off','MenuBar','none','NumberTitle','off');

% Init the geometry parameters
GeometryFigure.UserData.latmax = str2double(NorthLat);
GeometryFigure.UserData.latmin = str2double(SouthLat);
GeometryFigure.UserData.lonmax = str2double(EastLon);
GeometryFigure.UserData.lonmin = str2double(WestLon);
GeometryFigure.UserData.latinc = 1.0;
GeometryFigure.UserData.loninc = 1.0;
GeometryFigure.UserData.depthmin = 0.0;
GeometryFigure.UserData.depthmax = 800.0;
GeometryFigure.UserData.depthinc = 10.0;
GeometryFigure.UserData.period = 0.0;

% If the user has previously setup the geometry, load them to set the
% initial values
%CCPMat = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2.mat');
if CurrentSubsetIndex == 1
    CCPMat = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2.mat');
else
    CCPMat = fullfile(ProjectDirectory, 'CCPV2', SetName, 'CCPV2.mat');
end
if exist(CCPMat,'file')
    load(CCPMat)
    if exist('CCPV2Geometry','var')
        
        GeometryFigure.UserData.latmin = CCPV2Geometry.LatitudeMinimum;
        GeometryFigure.UserData.latmax = CCPV2Geometry.LatitudeMaximum;
        GeometryFigure.UserData.latinc = CCPV2Geometry.LatitudeIncrement;
    
        GeometryFigure.UserData.lonmin = CCPV2Geometry.LongitudeMinimum;
        GeometryFigure.UserData.lonmax = CCPV2Geometry.LongitudeMaximum;
        GeometryFigure.UserData.loninc = CCPV2Geometry.LongitudeIncrement;
    
        GeometryFigure.UserData.depthmin = CCPV2Geometry.DepthMinimum;
        GeometryFigure.UserData.depthmax = CCPV2Geometry.DepthMaximum;
        GeometryFigure.UserData.depthinc = CCPV2Geometry.DepthIncrement;
    
        GeometryFigure.UserData.period = CCPV2Geometry.Period;
        
        NorthLat = sprintf('%3.1f',GeometryFigure.UserData.latmax);
        SouthLat = sprintf('%3.1f',GeometryFigure.UserData.latmin);
        WestLon = sprintf('%3.1f',GeometryFigure.UserData.lonmin);
        EastLon = sprintf('%3.1f',GeometryFigure.UserData.lonmax);

    end
end

% Set the increments, depth, and period to strings
LatIncString = sprintf('%3.1f',GeometryFigure.UserData.latinc);
LonIncString = sprintf('%3.1f',GeometryFigure.UserData.loninc);
DepthMinString = sprintf('%3.1f',GeometryFigure.UserData.depthmin);
DepthMaxString = sprintf('%3.1f',GeometryFigure.UserData.depthmax);
DepthIncString = sprintf('%3.1f',GeometryFigure.UserData.depthinc);
PeriodString = sprintf('%3.1f',GeometryFigure.UserData.period);


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
uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','latmin_e','String',SouthLat,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.latmin = v; set(gcf,''UserData'',vec);');

uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latmax_t','String','Latitude Max. (deg)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','latmax_e','String',NorthLat,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.latmax = v; set(gcf,''UserData'',vec);');

uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','latinc_t','String','Latitude Inc. (deg)',...
    'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','latinc_e','String',LatIncString,...
    'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.latinc = v; set(gcf,''UserData'',vec);');

ParamTextPos1(2) = 9;
ParamOptionPos1(2) = 9;
ParamTextPos2(2) = 9;
ParamOptionPos2(2) = 9;
ParamTextPos3(2) = 9;
ParamOptionPos3(2) = 9;
uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','lonmin_t','String','Longitude Min. (deg)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','lonmin_e','String',WestLon,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.lonmin = v; set(gcf,''UserData'',vec);');

uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','lonmax_t','String','Longitude Max. (deg)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','lonmax_e','String',EastLon,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.lonmax = v; set(gcf,''UserData'',vec);');

uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','loninc_t','String','Longitude Inc. (deg)',...
    'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','loninc_e','String',LonIncString,...
    'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.loninc = v; set(gcf,''UserData'',vec);');

ParamTextPos1(2) = 6;
ParamOptionPos1(2) = 6;
ParamTextPos2(2) = 6;
ParamOptionPos2(2) = 6;
ParamTextPos3(2) = 6;
ParamOptionPos3(2) = 6;
uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depthmin_t','String','Depth Min. (km)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','depthmin_e','String',DepthMinString,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.depthmin = v; set(gcf,''UserData'',vec);');

uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depthmax_t','String','Depth Max. (km)',...
    'Position',ParamTextPos2,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','depthmax_e','String',DepthMaxString,...
    'Position',ParamOptionPos2,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.depthmax = v; set(gcf,''UserData'',vec);');

uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','depthinc_t','String','Depth Inc. (km)',...
    'Position',ParamTextPos3,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','depthinc_e','String',DepthIncString,...
    'Position',ParamOptionPos3,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.depthinc = v; set(gcf,''UserData'',vec);');

ParamTextPos1(2) = 3;
ParamOptionPos1(2) = 3;
uicontrol ('Parent',GeometryFigure,'Style','text','Units','characters','Tag','period_t','String','Period (s)',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',GeometryFigure,'Style','edit','Units','characters','Tag','period_e','String',PeriodString,...
    'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','v = str2double(get(gcbo,''String''));vec = get(gcf,''UserData'');vec.period = v; set(gcf,''UserData'',vec);');

% Add buttons for "Save Geometry" and "Cancel"
uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','savegeometry_pb','String','Save Geometry',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@savegeometry_Callback,ProjectDirectory,GeometryFigure});

ProcButtonPos(1) = 41;
uicontrol('Parent',GeometryFigure,'Style','Pushbutton','Units','characters','Tag','cancel_pb','String','Cancel',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@cancelgeometry_Callback});

end

function cancelgeometry_Callback(cbo, eventdata)
    close(gcbf);
end

function savegeometry_Callback(cbo, eventdata,ProjectDirectory,hdls)

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
% on save...
% Checks for the setup of the output directory and mat file
    [~, ~, ~] = mkdir(ProjectDirectory,'CCPV2');
    CCPV2Geometry.LatitudeMinimum = hdls.UserData.latmin;
    CCPV2Geometry.LatitudeMaximum = hdls.UserData.latmax;
    CCPV2Geometry.LatitudeIncrement = hdls.UserData.latinc;
    
    CCPV2Geometry.LongitudeMinimum = hdls.UserData.lonmin;
    CCPV2Geometry.LongitudeMaximum = hdls.UserData.lonmax;
    CCPV2Geometry.LongitudeIncrement = hdls.UserData.loninc;
    
    CCPV2Geometry.DepthMinimum = hdls.UserData.depthmin;
    CCPV2Geometry.DepthMaximum = hdls.UserData.depthmax;
    CCPV2Geometry.DepthIncrement = hdls.UserData.depthinc;
    
    CCPV2Geometry.Period = hdls.UserData.period;
    
    %outputFile = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2.mat');
    % Save the rays to the matrix
    if CurrentSubsetIndex == 1
        outputFile = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2.mat');
    else
        outputFile = fullfile(ProjectDirectory, 'CCPV2', SetName, 'CCPV2.mat');
    end
    if exist(outputFile,'file')
        save(outputFile,'CCPV2Geometry','-append');
    else
        save(outputFile,'CCPV2Geometry')
    end
    
% Sets CCPV2GeometryStructure and puts into project file
%   CCPV2GeometryStructure
    close(gcbf)

    % Load up the output file. Check if both geometry and ray paths are
    % there
    load(outputFile)
    if exist('CCPV2RayTraceParams','var') && exist('RayInfo','var')
        stackbuttonhdls = findobj('Tag','ccpv2_stacking_button');
        set(stackbuttonhdls,'Enable','on');
    end
    
    
end

